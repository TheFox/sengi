# coding: UTF-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'sengi/version'

Gem::Specification.new do |spec|
	spec.name          = 'sengi'
	spec.version       = TheFox::Sengi::VERSION
	spec.date          = TheFox::Sengi::DATE
	spec.author        = 'Christian Mayer'
	spec.email         = 'christian@fox21.at'
	
	spec.summary       = %q{Sengi Web Crawler}
	spec.description   = %q{A web crawler using Ruby and Redis.}
	spec.homepage      = TheFox::Sengi::HOMEPAGE
	spec.license       = 'GPL-3.0'
	
	spec.files         = `git ls-files -z`.split("\x0").reject{ |f| f.match(%r{^(test|spec|features)/}) }
	spec.bindir        = 'bin'
	spec.executables   = ['config', 'crawler']
	spec.require_paths = ['lib']
	spec.required_ruby_version = '>=2.1.0'
	
	#spec.add_development_dependency 'minitest', '~>5.8'
	
	spec.add_dependency 'activesupport', '~>4.2'
	spec.add_dependency 'redis', '~>3.2'
	spec.add_dependency 'hiredis', '~>0.6'
	spec.add_dependency 'resque', '~>1.26'
	spec.add_dependency 'resque-scheduler', '~>4.1'
	spec.add_dependency 'nokogiri', '~>1.6'
	spec.add_dependency 'cookiejar', '~>0.3'
	
	spec.add_dependency 'thefox-ext', '~>1.4'
end
