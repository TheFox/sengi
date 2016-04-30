
require 'uri'
require 'digest'

module TheFox
	module Sengi
		
		class Uri
			
			URI_CLASSES = [URI::Generic, URI::HTTP, URI::HTTPS]
			
			def initialize(url)
				@uri = nil
				@hash = nil
				@is_blacklisted = nil
				@is_ignored = nil
				@hash_id_key_name = nil
				@id = nil
				@key_name = nil
				@domain_nowww = nil
				@domain_nowww_hash = nil
				@domain_original_hash = nil
				@domain_hash_id_key_name = nil
				@domain_id = nil
				@domain_key_name = nil
				@request_id = nil
				@request_key_name = nil
				@response_id = nil
				@response_key_name = nil
				@response_content_type = ''
				
				begin
					@uri = URI(url)
				rescue Exception => e
					@uri = nil
				end
				
				validate
				if is_valid?
					append_slash
					host_downcase
					remove_fragment
					domain_setup
					
					@uri_class = @uri.class
					@hash = Digest::SHA256.hexdigest(to_s)
					@hash_id_key_name = "urls:id:#{@hash}"
				end
			end
			
			def is_valid?
				!@uri.nil?
			end
			
			def ruri
				@uri
			end
			
			def is_blacklisted=(is_blacklisted)
				@is_blacklisted = is_blacklisted
			end
			
			def is_blacklisted
				@is_blacklisted
			end
			
			def is_ignored=(is_ignored)
				@is_ignored = is_ignored
			end
			
			def is_ignored
				@is_ignored
			end
			
			def is_ignored_reason=(is_ignored_reason)
				@is_ignored_reason = is_ignored_reason
			end
			
			def is_ignored_reason
				@is_ignored_reason
			end
			
			# def hash_id_key_name=(hash_id_key_name)
			# 	@hash_id_key_name = hash_id_key_name
			# end
			
			def hash_id_key_name
				@hash_id_key_name
			end
			
			def id=(id)
				@id = id
				@key_name = "urls:#{@id}"
			end
			
			def id
				@id
			end
			
			# def key_name=(key_name)
			# 	@key_name = key_name
			# end
			
			def key_name
				@key_name
			end
			
			def domain_nowww
				@domain_nowww
			end
			
			def domain_nowww_hash
				@domain_nowww_hash
			end
			
			def domain_original_hash
				@domain_original_hash
			end
			
			def domain_hash_id_key_name
				@domain_hash_id_key_name
			end
			
			def domain_id=(domain_id)
				@domain_id = domain_id
				@domain_key_name = "domains:#{@domain_id}"
			end
			
			def domain_id
				@domain_id
			end
			
			def domain_key_name
				@domain_key_name
			end
			
			def request_id=(request_id)
				@request_id = request_id
				@request_key_name = "requests:#{@request_id}"
			end
			
			def request_id
				@request_id
			end
			
			def request_key_name
				@request_key_name
			end
			
			def response_id=(response_id)
				@response_id = response_id
				@response_key_name = "responses:#{@response_id}"
			end
			
			def response_id
				@response_id
			end
			
			def response_key_name
				@response_key_name
			end
			
			def response_content_type=(response_content_type)
				@response_content_type = response_content_type.to_s
			end
			
			def response_content_type
				@response_content_type
			end
			
			def to_s
				"#{@uri}"
			end
			
			def to_hash
				@hash
			end
			
			def weight(ref_uri = nil)
				is_subdomain = false
				
				if !@uri.host.nil? && !ref_uri.nil? && !ref_uri.ruri.host.nil?
					#puts "#{@uri.host}"
					#puts "#{ref_uri.ruri.host}"
					
					a_ss = @uri.host[ref_uri.ruri.host]
					#puts "a: '#{a_ss}'"
					
					if a_ss.nil?
						b_ss = ref_uri.ruri.host[@uri.host]
						#puts "b: '#{b_ss}'"
						
						if !b_ss.nil?
							is_subdomain = true
						end
					else
						is_subdomain = true
					end
				end
				
				if false
				elsif @uri_class == URI::Generic then return 100
				elsif @uri_class == URI::HTTP
					if is_subdomain
						return 200
					end
					return 250
				elsif @uri_class == URI::HTTPS then return 290
				end
				return 999
			end
			
			def join(suburi)
				self.class.new(URI.join(@uri, suburi.ruri).to_s)
			end
			
			def is_relative?(uri = nil)
				@uri_class == URI::Generic ||
				(!uri.nil? && uri.ruri.host == @uri.host)
			end
			
			private
			
			def validate
				if is_valid?
					s = to_s.downcase
					#puts "s '#{s[0..3]}'"
					if s[0..10] == 'javascript:' ||
						s[0..3] == 'tel:'
						@uri = nil
					end
				end
				
				if is_valid? && !URI_CLASSES.include?(@uri.class)
					@uri = nil
				end
			end
			
			def append_slash
				url = to_s
				
				#puts "url: '#{@url}'"
				#puts "request uri: '#{@uri.request_uri}'"
				#puts "class: '#{@uri.class}'"
				
				if @uri.class == URI::HTTP && @uri.request_uri == '/' && url[-1] != '/'
					@uri = URI("#{url}/")
				end
			end
			
			def host_downcase
				if @uri.class != URI::Generic
					@uri.host = @uri.host.downcase
				end
			end
			
			def remove_fragment
				@uri.fragment = nil
			end
			
			def domain_setup
				if !@uri.nil? && !@uri.host.nil?
					@domain_nowww = @uri.host.sub(/^www\./, '')
					@domain_nowww_hash = Digest::SHA256.hexdigest(@domain_nowww)
					@domain_original_hash = Digest::SHA256.hexdigest(@uri.host)
					@domain_hash_id_key_name = "domains:id:#{@domain_nowww_hash}"
				end
			end
		end
		
	end
end
