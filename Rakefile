
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'resque'
require 'resque/tasks'
require 'resque-scheduler'
require 'resque/scheduler/tasks'

require 'sengi'

namespace :resque do
	task :setup do
		puts 'resque setup'
		#require 'resque'
		Resque.redis = '127.0.0.1:7000'
	end
	
	task :setup_schedule => :setup do
		puts 'schedule setup'
		#require 'resque-scheduler'
	end
	
	task :scheduler => :setup_schedule
end
