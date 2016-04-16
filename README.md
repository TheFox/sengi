# Sengi Web Crawler

A web crawler using Ruby and Redis.

## Install

First, run:

	gem install rake bundler nokogiri hiredis
	make

## Setup

[Redis](http://redis.io/) is used to store everything. So it's always be needed to run Sengi.

Start Redis:

	./bin/redis

To ignore the deep web, run:

	make import_domain_ignores

Start [Resque](https://github.com/resque/resque) -- Scheduler and Worker:

	./bin/resque_scheduler_start
	./bin/resque_crawler_start

To get a Resque web dashboard at <http://localhost:8282>, run:

	./bin/resque_server

## Usage

To queue a URL to be crawled, run:

	./bin/crawler -q http://example.com

## License

Copyright (C) 2016 Christian Mayer <http://fox21.at>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
