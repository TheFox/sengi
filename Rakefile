
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'resque'
require 'resque/tasks'
require 'sengi'


task 'resque:setup' do
	puts 'resque:setup'
	Resque.redis = '127.0.0.1:7000'
end

task 'resque:work' do
	puts 'resque:work'
end
