#!/usr/bin/env ruby

require 'minitest/autorun'
require 'sengi'

class TestCrawler < MiniTest::Test
	
	def test_base
		crawler = TheFox::Sengi::Crawler.new(nil, Hash.new)
		
		assert_equal('TheFox::Sengi::Crawler', crawler.class.to_s)
	end
	
end
	