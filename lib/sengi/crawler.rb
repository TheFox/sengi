
require 'uri'
require 'net/http'
require 'hiredis'
require 'resque'
require 'resque-scheduler'
require 'nokogiri'
require 'time'
require 'digest'
require 'openssl'
require 'zlib'
require 'active_support/time'

require 'thefox-ext'

module TheFox
	module Sengi
		
		class Crawler
			
			def initialize(url, options)
				@url = url
				@options = options
				
				@options['serial'] = false if !@options.has_key?('serial')
				@options['relative'] = false if !@options.has_key?('relative')
				@options['debug'] = false if !@options.has_key?('debug')
				
				@options['parent_id'] = 0 if !@options.has_key?('parent_id')
				@options['level'] = 0 if !@options.has_key?('level')
				#pp @options
				
				@redis = nil
				@uri = nil
				@request = nil
				@response = nil
				@html_doc = nil
				@url_delay = nil
				@url_separate_delay = nil
				@url_reschedule = nil
			end
			
			def go
				redis_setup
				
				uri_setup
				puts "#{Time.now.strftime('%F %T')} perform: #{@options['parent_id']} #{@options['level']} #{@options['relative'] ? 'y' : 'n'} #{@uri}"
				
				check_blacklist
				puts "\t" + "blacklisted: #{@uri.is_blacklisted ? 'YES' : 'no'}"
				return if @uri.is_blacklisted
				
				insert_url
				puts "\t" + "url: #{@uri.id}#{@uri.is_ignored ? ' IGNORED' : ''}"
				return if @uri.is_ignored && !@options['debug']
				
				insert_domain
				puts "\t" + "domain id: #{@uri.domain_id}"
				
				insert_request
				puts "\t" + "request id: #{@uri.request_id}"
				
				make_http_request
				puts "\t" + "http response: #{@response.nil? ? 'FAILED' : 'ok'}"
				return if @response.nil?
				
				insert_response
				puts "\t" + "response: #{@uri.response_id} #{@uri.response_size}"
				
				puts "\t" + 'process http response'
				process_http_response
				puts "\t" + "http response: #{@uri.is_ignored ? 'INVALID' : 'ok'}"
				if @uri.is_ignored
					puts "\t" + "       reason: #{@uri.is_ignored_reason}"
					return
				end
				if @html_doc.nil?
					puts "\t" + '       HTML INVALID'
					return
				end
				
				puts "\t" + 'process html links'
				process_html_links
				
				puts "\t" + 'process html meta'
				process_html_meta
				
				puts "\t" + 'url done'
			end
			
			private
			
			def redis_setup
				# Redis Setup
				if @redis.nil?
					@redis = Hiredis::Connection.new
					@redis.connect('127.0.0.1', 7000)
					@redis.write(['SELECT', 1])
					@redis.read
				end
				
				@redis.write(['GET', 'urls:delay'])
				@url_delay = @redis.read.to_i
				if @url_delay.nil?
					@url_delay = URL_DELAY
				end
				
				@redis.write(['GET', 'urls:separatedelay'])
				@url_separate_delay = @redis.read.to_i
				if @url_separate_delay.nil?
					@url_separate_delay = URL_SEPARATE_DELAY
				end
				
				@redis.write(['GET', 'urls:reschedule'])
				@url_reschedule = @redis.read.to_i
				if @url_reschedule.nil?
					@url_reschedule = URL_RESCHEDULE
				end
			end
			
			def uri_setup
				# URL object
				@uri = Uri.new(@url)
				@url = @uri.to_s
			end
			
			def check_blacklist
				# Check if the current URL domain (second- + top-level) is in the blacklist.
				
				if !@uri.ruri.host.nil?
					# This splits for example the domain 'www.facebook.com' to
					# ['www', 'facebook', 'com'] and then uses the last two parts
					# ['facebook', 'com'] to make the check.
					domain_topparts = @uri.ruri.host.split('.')[-2..-1].join('.')
					
					# Read Domains Blacklist
					@redis.write(['SMEMBERS', 'domains:ignore'])
					domains_ignore = @redis.read
					
					if domains_ignore.include?(domain_topparts)
						@uri.is_blacklisted = true
					else
						# If the domain wasn't found in the blacklist search with regex.
						# For example: if you blacklist 'google' the domain 'google.com'
						# will not be found by the parent if condition. So search also with regex.
						@uri.is_blacklisted = domains_ignore.grep(Regexp.new(domain_topparts)).count > 0
					end
				end
			end
			
			def insert_url
				# Check if a URL already exists.
				@redis.write(['EXISTS', @uri.hash_id_key_name])
				if @redis.read.to_b
					# A URL already exists.
					@redis.write(['GET', @uri.hash_id_key_name])
					@uri.id = @redis.read
					
					@redis.write(['HGETALL', @uri.key_name])
					redis_uri = Hash[*@redis.read]
					#pp redis_uri
					
					@uri.is_ignored = redis_uri['is_ignored'].to_i.to_b
					request_attempts = redis_uri['request_attempts'].to_i
					
					puts "\t" + "request attempts: #{request_attempts}"
					
					if !@uri.is_ignored && request_attempts >= 3
						# Ignore the URL if it has already X attempts.
						
						@uri.is_ignored = true
						
						# Ignore the URL.
						@redis.write(['HMSET', @uri.key_name,
							'is_ignored', 1,
							'ignored_at', Time.now.strftime('%F %T %z'),
							])
						@redis.read
					end
					
					# Increase the URL attempts, even if the URL will be ignored.
					# @redis.write(['HINCRBY', @uri.key_name, 'request_attempts', 1])
					# @redis.read
					@redis.write(['HMSET', @uri.key_name,
						'request_attempts', request_attempts + 1,
						'request_attempt_last_at', Time.now.strftime('%F %T %z'),
						])
					@redis.read
				else
					# New URL. Increase the URLs ID.
					@redis.write(['INCR', 'urls:id'])
					@uri.id = @redis.read
					
					now_s = Time.now.strftime('%F %T %z')
					
					# Insert the new URL.
					@redis.write(['HMSET', @uri.key_name,
						'url', @uri.to_s,
						'hash', @uri.to_hash,
						'request_attempts', 1,
						'request_attempt_last_at', now_s,
						'parent_id', @options['parent_id'],
						'level', @options['level'],
						'is_blacklisted', @uri.is_blacklisted.to_i,
						'is_ignored', 0,
						#'ignored_at', nil,
						'is_redirect', 0,
						'created_at', now_s,
						])
					@redis.read
					
					# Set the URL Hash to URL ID reference.
					@redis.write(['SET', @uri.hash_id_key_name, @uri.id])
					@redis.read
				end
			end
			
			def insert_domain
				# Add Domain to the indexed list.
				@redis.write(['SADD', 'domains:indexed', @uri.domain_nowww])
				@redis.read.to_b
				
				# Check if a Domain already exists.
				@redis.write(['EXISTS', @uri.domain_hash_id_key_name])
				if @redis.read.to_b
					# A Domain already exists.
					@redis.write(['GET', @uri.domain_hash_id_key_name])
					@uri.domain_id = @redis.read
				else
					# New Domain. Increase the Domains ID.
					@redis.write(['INCR', 'domains:id'])
					@uri.domain_id = @redis.read
					
					# Insert the new Domain.
					@redis.write(['HMSET', @uri.domain_key_name,
						'domain_nowww', @uri.domain_nowww,
						'domain_original', @uri.ruri.host,
						'hash_nowww', @uri.domain_nowww_hash,
						'hash_original', @uri.domain_original_hash,
						'created_at', Time.now.strftime('%F %T %z'),
						])
					@redis.read
					
					# Set the Domain Hash to Domain ID reference.
					@redis.write(['SET', @uri.domain_hash_id_key_name, @uri.domain_id])
					@redis.read
				end
				
				# Save the URLs per Domain.
				@redis.write(['SADD', "domains:#{@uri.domain_id}:urls", @uri.id])
				@redis.read
			end
			
			def insert_request
				# Increase the Requests ID.
				@redis.write(['INCR', 'requests:id'])
				@uri.request_id = @redis.read
				
				# Create a new Request.
				@redis.write(['HMSET', @uri.request_key_name,
					'url_id', @uri.id,
					'user_agent', HTTP_USER_AGENT,
					'error', 0,
					#'error_msg', nil,
					'size', 0,
					'created_at', Time.now.strftime('%F %T %z'),
					])
				@redis.read
				
				# Save the Requests per URL.
				@redis.write(['SADD', "urls:#{@uri.id}:requests", @uri.request_id])
				@redis.read
			end
			
			def make_http_request
				# HTTP Request
				http = Net::HTTP.new(@uri.ruri.host, @uri.ruri.port)
				http.keep_alive_timeout = 0
				http.open_timeout = 5
				http.read_timeout = 5
				http.ssl_timeout = 5
				if @uri.ruri.scheme.to_s.downcase == 'https'
					http.use_ssl = true
					http.verify_mode = OpenSSL::SSL::VERIFY_NONE
				end
				
				# Send HTTP Request
				@request = Net::HTTP::Get.new(@uri.ruri.request_uri)
				@request['User-Agent'] = HTTP_USER_AGENT
				@request['Referer'] = HTTP_REFERER
				@request['Connection'] = 'close'
				@request['Accept'] = 'text/html'
				@request['Accept-Encoding'] = 'gzip;q=1.0,identity;q=0.6'
				@request['Accept-Language'] = 'en,en-US;q=0.8'
				
				string_io = StringIO.new
				@request.exec(string_io, Net::HTTP::HTTPVersion, @request.path)
				@redis.write(['HSET', @uri.request_key_name, 'size', string_io.string.length])
				@redis.read
				
				begin
					puts "\t" + 'http request'
					@response = http.request(@request)
					puts "\t" + 'http request ok'
				rescue Exception => e
					puts "\t" + "ERROR: #{e.class} #{e}"
					
					@response = nil
					
					# Save the error and error message to the URL Request.
					@redis.write(['HMSET', @uri.request_key_name,
						'error', 1,
						'error_msg', e.to_s,
						])
					@redis.read
					
					reenqueue
					return
				end
				
				# Ignore the URL for further requests because it was successful.
				@redis.write(['HMSET', @uri.key_name,
					'is_ignored', 1,
					'ignored_at', Time.now.strftime('%F %T %z'),
					])
				@redis.read
			end
			
			def insert_response
				# Increase the Responses ID.
				@redis.write(['INCR', 'responses:id'])
				@uri.response_id = @redis.read
				
				# Add the Response ID to the URL.
				@redis.write(['SADD', "urls:#{@uri.id}:responses", @uri.response_id])
				@redis.read
				
				# This is still too inaccurate.
				response_size = @response.header.to_hash.map{ |k, v|
					vs = ''
					if v.is_a?(Array)
						vs = v.join(' ')
					else
						vs = v
					end
					"#{k}: #{vs}"
				}.join("\r\n").length + 4
				
				response_size += @response.body.length
				
				@uri.response_size = response_size
				@uri.response_content_type = @response['Content-Type']
				
				# Insert the new Response.
				@redis.write(['HMSET', @uri.response_key_name,
					'code', @response.code.to_i,
					'content_type', @uri.response_content_type,
					'request_id', @uri.request_id,
					'size', @uri.response_size,
					'created_at', Time.now.strftime('%F %T %z'),
					])
				@redis.read
				
				# Add the Response to the Response Code.
				@redis.write(['SADD', "responses:code:#{@response.code}", @uri.response_id])
				@redis.read
			end
			
			def process_http_response
				body = ''
				if !@response['Content-Encoding'].nil? && @response['Content-Encoding'].downcase == 'gzip'
					body = Zlib::GzipReader.new(StringIO.new(@response.body)).read
				else
					body = @response.body
				end
				
				code = @response.code.to_i
				puts "\t" + "http response code: #{code}"
				
				if code == 200
					if @uri.response_content_type[0..8] == 'text/html'
						@html_doc = Nokogiri::HTML(body)
						@html_doc.remove_namespaces!
					else
						# Ignore the URL if the response content type isn't HTML.
						@uri.is_ignored = true
						@uri.is_ignored_reason = "wrong content type: #{@uri.response_content_type}"
					end
				elsif code >= 301 && code <= 399
					@redis.write(['HSET', @uri.key_name, 'is_redirect', 1])
					@redis.read
					
					if !@response['Location'].nil?
						# Follow the URL.
						new_uri = Uri.new(@response['Location'])
						
						enqueue(new_uri)
					end
				else
					@uri.is_ignored = true
					@uri.is_ignored_reason = "wrong code: #{code}"
				end
				
				if @uri.is_ignored
					@redis.write(['HSET', @uri.key_name, 'is_ignored', 1])
					@redis.read
				end
			end
			
			def process_html_links
				# Process all <a> tags found on the response page.
				@html_doc
					.xpath('//a')
					.map{ |link|
						
						href = link['href']
						#puts "link #{href}"
						
						if !href.nil?
							#begin
								Uri.new(href)
							# rescue Exception => e
							# 	nil
							# end
						end
					}
					.select{ |link|
						!link.nil? && link.is_valid?
					}
					.sort{ |uri_a, uri_b|
						uri_a.weight(@uri) <=> uri_b.weight(@uri)
					}
					.each_with_index{ |new_uri, index|
						#puts "index #{index} #{new_uri} #{new_uri.is_relative?(@uri)}"
						enqueue(new_uri, index)
					}
			end
			
			def process_html_meta
				# Process all <meta> tags found on the response page.
				
				@html_doc.xpath('//meta').each do |meta|
					meta_name = meta['name']
					if !meta_name.nil?
						meta_name = meta_name.downcase
						
						if meta_name.downcase == 'generator'
							process_html_meta_generator(meta)
						end
					end
				end
			end
			
			def process_html_meta_generator(meta)
				# Process all generator <meta> tags.
				
				generator = meta['content']
				generator_hash = Digest::SHA256.hexdigest(generator)
				
				generator_id = nil
				generator_hash_id_key_name = "generators:id:#{generator_hash}"
				generator_key_name = nil
				
				@redis.write(['EXISTS', generator_hash_id_key_name])
				if @redis.read.to_b
					# Found existing generator.
					
					@redis.write(['GET', generator_hash_id_key_name])
					generator_id = @redis.read
					
					generator_key_name = "generators:#{generator_id}"
				else
					# New generator. Increase the Generators ID.
					@redis.write(['INCR', 'generators:id'])
					generator_id = @redis.read
					
					generator_key_name = "generators:#{generator_id}"
					@redis.write(['HMSET', generator_key_name,
						'name', generator,
						'hash', generator_hash,
						'first_url_id', @uri.id,
						#'last_used_at', Time.now.strftime('%F %T %z'),
						'created_at', Time.now.strftime('%F %T %z'),
						])
					@redis.read
					
					# Set the Generator Hash to Generator ID reference.
					@redis.write(['SET', generator_hash_id_key_name, generator_id])
					@redis.read
				end
				
				# Always overwrite the last used timestamp.
				@redis.write(['HSET', generator_key_name, 'last_used_at', Time.now.strftime('%F %T %z')])
				@redis.read
				
				# Add the URL to the Generator.
				@redis.write(['SADD', "generators:#{generator_id}:urls", @uri.id])
				@redis.read
				
				# Add the Generator to the URL.
				@redis.write(['SADD', "urls:#{@uri.id}:generators", generator_id])
				@redis.read
			end
			
			def enqueue(new_uri, index = 0, debug = false)
				if !@options['relative'] || new_uri.is_relative?(@uri)
					new_uri = @uri.join(new_uri)
					
					if new_uri.is_valid?
						new_uri_s = new_uri.to_s
						
						queued_time = (@url_delay + (@url_separate_delay * index)).seconds.from_now
						
						if @options['serial']
							
							# Check it another process is currently using 'urls:schedule:last'.
							@redis.write(['GET', 'urls:schedule:lock'])
							lock = @redis.read.to_i.to_b
							while lock
								@redis.write(['GET', 'urls:schedule:lock'])
								lock = @redis.read.to_i.to_b
								sleep 0.1
							end
							
							# Lock 'urls:schedule:last' for other processes.
							@redis.write(['INCR', 'urls:schedule:lock'])
							@redis.read
							
							@redis.write(['GET', 'urls:schedule:last'])
							queued_time = @redis.read
							
							if queued_time.nil?
								queued_time = Time.now
							else
								queued_time = Time.parse(queued_time)
								if queued_time < Time.now
									queued_time = Time.now
								end
							end
							queued_time += @url_delay
							
							@redis.write(['SET', 'urls:schedule:last', queued_time.strftime('%F %T %z')])
							@redis.read
							
							# Unlock 'urls:schedule:last' for other processes.
							@redis.write(['DECR', 'urls:schedule:lock'])
							@redis.read
						end
						
						puts "\t" + "enqueue #{@options['level']} #{index} #{queued_time} #{new_uri_s}"
						
						if !debug
							options = {
								'serial' => @options['serial'],
								'relative' => @options['relative'],
								'parent_id' => @uri.id,
								'level' => @options['level'] + 1,
							}
							Resque.enqueue_at(queued_time, TheFox::Sengi::CrawlerWorker, new_uri_s, options)
						end
					end
				end
			end
			
			def reenqueue
				queued_time = @url_reschedule.seconds.from_now
				
				puts "\t" + "re-enqueue #{queued_time}"
				
				options = {
					'serial' => @options['serial'],
					'relative' => @options['relative'],
				}
				Resque.enqueue_at(queued_time, TheFox::Sengi::CrawlerWorker, @uri.to_s, options)
			end
			
		end
		
	end
end
