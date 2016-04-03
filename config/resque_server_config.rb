
require 'resque'
require 'resque-scheduler'
require 'resque/scheduler/server'

Resque.redis = '127.0.0.1:7000:0'
