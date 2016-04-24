
module TheFox
	module Sengi
		
		class CrawlerWorker
			@queue = :crawler
			
			def self.perform(url, options)
				crawler = Crawler.new(url, options)
				crawler.go
			end
			
		end
		
	end
end
