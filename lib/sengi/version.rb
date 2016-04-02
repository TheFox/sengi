
require 'uri'

module TheFox
	module Sengi
		VERSION = '0.1.0-dev'
		DATE = '2016-04-02'
		HOMEPAGE = 'https://github.com/TheFox/sengi'
		
		#HTTP_USER_AGENT = "Sengi SearchENGIne/#{VERSION}"
		HTTP_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.108 Safari/537.36'
		
		HTTP_REFERER = 'https://www.google.com/'
		
		URI_CLASSES = [URI::Generic, URI::HTTP, URI::HTTPS]
	end
end
