#!/usr/bin/env ruby

require 'minitest/autorun'
require 'sengi'


class TestUri < MiniTest::Test
	def test_base
		uri = TheFox::Sengi::Uri.new('http://example.com')
		
		assert_equal('TheFox::Sengi::Uri', uri.class.to_s)
		assert_equal('URI::HTTP', uri.ruri.class.to_s)
	end
	
	def test_string
		uri = TheFox::Sengi::Uri.new('http://example.com')
		assert_equal('http://example.com/', "#{uri}")
		assert_equal('http://example.com/', uri.to_s)
		
		uri = TheFox::Sengi::Uri.new('http://example.com/')
		assert_equal('http://example.com/', uri.to_s)
		
		uri = TheFox::Sengi::Uri.new('http://example.com/subdir1/')
		assert_equal('http://example.com/subdir1/', uri.to_s)
		
		uri = TheFox::Sengi::Uri.new('http://example.com/subdir2')
		assert_equal('http://example.com/subdir2', uri.to_s)
		
		uri = TheFox::Sengi::Uri.new('http://example.com/subdir2.html')
		assert_equal('http://example.com/subdir2.html', uri.to_s)
		
		uri = TheFox::Sengi::Uri.new('/subdir2.html')
		assert_equal('/subdir2.html', uri.to_s)
	end
	
	def test_hash
		uri = TheFox::Sengi::Uri.new('http://www.example.com/index.html')
		
		assert_equal('b1ae8ba07f44d280254af4d1db914de03ce87b027e1c291ffcb9211c7712c9d1', uri.to_hash)
	end
	
	def test_id
		uri = TheFox::Sengi::Uri.new('http://www.example.com/index.html')
		
		uri.id = 21
		assert_equal(21, uri.id)
		assert_equal('urls:21', uri.key_name)
		
		uri.id = 24
		assert_equal(24, uri.id)
		assert_equal('urls:24', uri.key_name)
	end
	
	def test_valid
		uri = TheFox::Sengi::Uri.new('http://example.com')
		assert_equal(true, uri.is_valid?)
		
		uri = TheFox::Sengi::Uri.new('javascript:alert(1);')
		assert_equal(false, uri.is_valid?)
		
		uri = TheFox::Sengi::Uri.new('tel:+43501234567890')
		assert_equal(false, uri.is_valid?)
	end
	
	def test_weight
		uri = TheFox::Sengi::Uri.new('http://www.example1.com/index.html')
		
		suburi = TheFox::Sengi::Uri.new('test.html')
		assert_equal(100, suburi.weight(uri))
		
		suburi = TheFox::Sengi::Uri.new('http://sub.www.example1.com')
		assert_equal(200, suburi.weight(uri))
		
		suburi = TheFox::Sengi::Uri.new('http://sub.example1.com')
		assert_equal(250, suburi.weight(uri))
		
		suburi = TheFox::Sengi::Uri.new('http://www.example2.com')
		assert_equal(250, suburi.weight(uri))
		
		suburi = TheFox::Sengi::Uri.new('https://www.example2.com')
		assert_equal(290, suburi.weight(uri))
	end
	
	def test_join
		uri1 = TheFox::Sengi::Uri.new('http://www.example.com')
		uri2 = TheFox::Sengi::Uri.new('index.html')
		uri3 = uri1.join(uri2)
		assert_equal('http://www.example.com/', uri1.to_s)
		assert_equal('index.html', uri2.to_s)
		assert_equal('http://www.example.com/index.html', uri3.to_s)
		
		uri1 = TheFox::Sengi::Uri.new('http://www.example.com/test1')
		uri2 = TheFox::Sengi::Uri.new('../test2.html')
		uri3 = uri1.join(uri2)
		assert_equal('http://www.example.com/test1', uri1.to_s)
		assert_equal('../test2.html', uri2.to_s)
		assert_equal('http://www.example.com/test2.html', uri3.to_s)
		
		uri1 = TheFox::Sengi::Uri.new('http://www.example1.com/test1.html')
		uri2 = TheFox::Sengi::Uri.new('http://www.example2.com/test2.html')
		uri3 = uri1.join(uri2)
		assert_equal('http://www.example1.com/test1.html', uri1.to_s)
		assert_equal('http://www.example2.com/test2.html', uri2.to_s)
		assert_equal('http://www.example2.com/test2.html', uri3.to_s)
	end
	
	def test_host_downcase
		uri = TheFox::Sengi::Uri.new('http://www.EXAMPLE.com/Index.html')
		
		assert_equal('http://www.example.com/Index.html', uri.to_s)
	end
	
	def test_fragment
		uri = TheFox::Sengi::Uri.new('http://example.com/index.html#test')
		assert_equal('http://example.com/index.html', uri.to_s)
		
		uri = TheFox::Sengi::Uri.new('index.html#test')
		assert_equal('index.html', uri.to_s)
	end
end
