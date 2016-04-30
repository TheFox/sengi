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

Start [Resque](https://github.com/resque/resque) -- Scheduler and Worker:

	./bin/resque_scheduler_start
	./bin/resque_crawler_start

To get a Resque web dashboard at <http://localhost:8282>, run:

	./bin/resque_server

Init Sengi. This sets default variables to Redis and a blacklist of the deepweb.

	RUBYOPT=-rbundler/setup ruby ./bin/config --init

## Usage

### Queue

To queue a URL to be crawled, run:

	RUBYOPT=-rbundler/setup ruby ./bin/crawler -q http://example.com

### Relative Links Only

To crawl only relative links on `example.com`:

	RUBYOPT=-rbundler/setup ruby ./bin/crawler -r http://example.com

### Serial

Crawl only one URL at a time. The latest datetime will be stored into Redis key `urls:schedule:last`. A new URL to crawl will be scheduled for a new datetime calculated by `urls:schedule:last + url_delay`. Where `url_delay` is the number of seconds between the scheduled URLs.

	RUBYOPT=-rbundler/setup ruby ./bin/crawler -s http://example.com

## License

Copyright (C) 2016 Christian Mayer <http://fox21.at>

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
