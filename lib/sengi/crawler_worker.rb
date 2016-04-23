
module TheFox
	module Sengi
		
		class CrawlerWorker
			@queue = :crawler
			
			def self.perform(url, parent_id = 0, level = 0)
				crawler = Crawler.new(url, parent_id, level)
				crawler.go
			end
			
		end
		
	end
end
