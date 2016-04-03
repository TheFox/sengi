
require 'uri'
require 'net/http'
require 'hiredis'
require 'nokogiri'
require 'time'
require 'digest'
require 'openssl'
require 'thefox-ext'

require 'pp'

module TheFox
	module Sengi
		
		class Find
			@queue = :find
			@redis = nil
			
			def initialize
				puts 'initialize'
			end
			
			def self.uri_worth(uri, original_uri = nil)
				c = uri.class
				
				is_subdomain = false
				if !uri.host.nil? && !original_uri.nil? && !original_uri.host.nil?
					a_ss = nil
					a_ss = uri.host[original_uri.host]
					#puts "#{a_ss}"
					if a_ss.nil?
						b_ss = nil
						b_ss = original_uri.host[uri.host]
						if !b_ss.nil?
							is_subdomain = true
						end
					else
						is_subdomain = true
					end
				end
				
				if false
				elsif c == URI::Generic then return 100
				elsif c == URI::HTTP
					if is_subdomain
						return 200
					end
					return 250
				elsif c == URI::HTTPS then return 290
				end
				return 999
			end
			
			def self.perform(url, parent_id = 0, level = 0)
				if @redis.nil?
					@redis = Hiredis::Connection.new
					@redis.connect('127.0.0.1', 7000)
					@redis.write(['SELECT', 1])
					@redis.read
				end
				
				now = Time.now
				
				puts "#{now.strftime('%F %T %z')} perform: #{parent_id}, #{level} - #{url}"
				
				uri = URI(url)
				uri.host = uri.host.downcase
				if uri.request_uri == '/' && url[-1] != '/'
					uri = URI("#{url}/")
				end
				url = uri.to_s
				url_hash = Digest::SHA256.hexdigest(url)
				url_host_topparts = uri.host.split('.')[-2..-1].join('.')
				
				@redis.write(['SMEMBERS', 'domains:ignore'])
				domains_ignore = @redis.read
				
				url_ignore = false
				if domains_ignore.include?(url_host_topparts)
					url_ignore = true
				else
					url_ignore = domains_ignore.grep(Regexp.new(url_host_topparts)).count > 0
				end
				
				url_id = nil
				url_key_name = nil
				url_make_request = false
				
				url_id_key_name = "urls:id:#{url_hash}"
				@redis.write(['EXISTS', url_id_key_name])
				if @redis.read.to_b
					@redis.write(['GET', url_id_key_name])
					url_id = @redis.read
					url_key_name = "urls:#{url_id}"
					
					@redis.write(['HINCRBY', url_key_name, 'request_attempts', 1])
					@redis.read
					
					@redis.write(['HSET', url_key_name, 'request_attempt_last', Time.now.strftime('%F %T %z')])
					@redis.read
				else
					@redis.write(['INCR', 'urls:id'])
					url_id = @redis.read
					url_key_name = "urls:#{url_id}"
					
					now_s = Time.now.strftime('%F %T %z')
					@redis.write(['HMSET', url_key_name,
						'url', url,
						'hash', url_hash,
						'request_attempts', 1,
						'request_attempt_last', now_s,
						'parent_id', parent_id,
						'level', level,
						'ignore', url_ignore.to_i,
						'created', now_s,
						])
					@redis.read
					
					@redis.write(['SET', url_id_key_name, url_id])
					@redis.read
					
					if !url_ignore
						url_make_request = true
					end
				end
				
				if url_make_request
					@redis.write(['INCR', 'requests:id'])
					request_id = @redis.read
					
					puts "get u='#{url_id}' r='#{request_id}' '#{uri}' #{url_hash}"
					
					@redis.write(['SADD', "urls:#{url_id}:requests", request_id])
					@redis.read
					
					request_key_name = "requests:#{request_id}"
					@redis.write(['HMSET', request_key_name,
						'url_id', url_id,
						'user_agent', HTTP_USER_AGENT,
						'error', 0,
						'error_msg', '',
						'created', Time.now.strftime('%F %T %z'),
						])
					@redis.read
					
					http = Net::HTTP.new(uri.host, uri.port)
					if uri.scheme.to_s == 'https'
						http.use_ssl = true
						http.verify_mode = OpenSSL::SSL::VERIFY_NONE
					end
					
					request = Net::HTTP::Get.new(uri.request_uri)
					request['User-Agent'] = HTTP_USER_AGENT
					request['Referer'] = HTTP_REFERER
					request['Connection'] = 'close'
					request['Accept'] = 'text/html'
					request['Accept-Encoding'] = ''
					request['Accept-Language'] = 'en,en-US;q=0.8'
					
					response = nil
					begin
						response = http.request(request)
					rescue Exception => e
						puts "ERROR: #{e}"
						@redis.write(['HMSET', request_key_name,
							'error', 1,
							'error_msg', e.to_s,
							])
						@redis.read
						
						@redis.write(['HSET', url_key_name, 'ignore', 1])
						@redis.read
					end
					
					if !response.nil?
						@redis.write(['INCR', 'responses:id'])
						response_id = @redis.read
						response_code = response.code.to_i
						response_content_type = response['Content-Type']
						
						@redis.write(['SADD', "urls:#{url_id}:responses", response_id])
						@redis.read
						
						@redis.write(['HMSET', "responses:#{response_id}",
							'code', response_code,
							'content_type', response_content_type,
							'request_id', request_id,
							'created', Time.now.strftime('%F %T %z'),
							])
						@redis.read
						
						@redis.write(['SADD', "responses:code:#{response_code}", response_id])
						@redis.read
						
						html_doc = nil
						if response_code == 200
							if response_content_type[0..8] == 'text/html'
								puts 'ok'
								
								html_doc = Nokogiri::HTML(response.body)
								html_doc.remove_namespaces!
							else
								puts "wrong Content-Type: #{response_content_type}"
								
								@redis.write(['HSET', url_key_name, 'ignore', 1])
								@redis.read
							end
						else
							puts "wrong http status code: #{response_code}"
						end
						
						if !html_doc.nil?
							html_doc
								.xpath('//a')
								.map{ |link| URI(link['href']) }
								.sort{ |uri_a, uri_b|
									sw = uri_worth(uri_a, uri) <=> uri_worth(uri_b, uri)
								}
								.each{ |new_uri|
									add_to_queue = URI_CLASSES.include?(new_uri.class)
									
									if new_uri.class == URI::Generic
										new_uri = URI.join(uri, new_uri)
									end
									
									if add_to_queue
										new_uri_s = new_uri.to_s
										#puts "link: #{new_uri_s}"
										Resque.enqueue(TheFox::Sengi::Find, new_uri_s, url_id, level + 1)
									end
								}
							
						end
					end
					
				end
				
				puts
			end
		end
		
	end
end
