
GEM_NAME = sengi
ALL_TARGETS_EXT = tmp run

include Makefile.common

dev:
	RUBYOPT=-rbundler/setup ruby ./bin/crawler -q http://dev.fox21.at/sengi/

run:
	$(MKDIR) $@

.PHONY: import_domain_ignores
import_domain_ignores:
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add 4chan.org
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add about.me
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add amazon
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add ask.fm
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add bitbucket.org
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add bit.ly bitly.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add bbc.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add blockchain.info
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add blogger.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add blogspot
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add cnet.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add cnn.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add delicious.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add digg.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add disqus.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add doodle.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add dropbox.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add droplr.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add duckduckgo.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add ebay.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add facebook.com fb.com fb.me
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add flickr.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add getpocket.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add github.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add google
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add gravatar.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add imdb.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add imgur.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add instagram.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add jsbin.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add jsfiddle.net
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add keybase.io
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add kickstarter.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add linkedin.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add localhost
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add myspace.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add npmjs.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add openstreetmap.org osm.org
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add packagist.org
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add pastebin.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add paypal.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add reddit.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add skype.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add slack.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add slashdot.org
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add soundcloud.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add thepiratebay
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add tumblr.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add twitpic.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add twitter.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add vimeo.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add wikipedia.org
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add willhaben.at
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add ycombinator.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add xing.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add yahoo.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add youtube

.PHONY: reset
reset:
	echo 'FLUSHALL' | redis-cli --pipe -p 7000
	$(MAKE) import_domain_ignores

.PHONY: test
test:
	RUBYOPT=-w $(BUNDLER) exec ./tests/ts_all.rb
