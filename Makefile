
GEM_NAME = sengi
ALL_TARGETS_EXT = tmp run init

include Makefile.common

dev:
	RUBYOPT=-rbundler/setup ruby ./bin/crawler -q http://dev.fox21.at/sengi/

run:
	$(MKDIR) $@

.PHONY: reset
reset:
	RUBYOPT=-rbundler/setup ruby ./bin/config --reset

.PHONY: init
init:
	RUBYOPT=-rbundler/setup ruby ./bin/config --init

.PHONY: test
test:
	RUBYOPT=-w $(BUNDLER) exec ./tests/ts_all.rb
