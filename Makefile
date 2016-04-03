
GEM_NAME = sengi
ALL_TARGETS_EXT = tmp run

include Makefile.common

dev:
	RUBYOPT=-rbundler/setup ruby ./bin/crawler https://fox21.at

tmp run:
	$(MKDIR) $@

.PHONY: import_domain_ignores
import_domain_ignores:
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add bitbucket.org
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add duckduckgo.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add facebook.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add github.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add google
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add twitter.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add wikipedia.org
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add ycombinator.com
	RUBYOPT=-rbundler/setup ruby ./bin/config domain ignore add youtube.com
