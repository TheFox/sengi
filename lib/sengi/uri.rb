
require 'uri'
require 'digest'

module TheFox
	module Sengi
		
		class Uri
			
			URI_CLASSES = [URI::Generic, URI::HTTP, URI::HTTPS]
			
			def initialize(url)
				@uri = nil
				@hash = nil
				
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
					
					@uri_class = @uri.class
					@hash = Digest::SHA256.hexdigest(to_s)
				end
			end
			
			def is_valid?
				!@uri.nil?
			end
			
			def ruri
				@uri
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
		end
		
	end
end
