
GEM_NAME = sengi
ALL_TARGETS_EXT = tmp run init

include Makefile.common

dev:
	RUBYOPT=-w $(BUNDLER) exec ./bin/crawler -q http://dev.fox21.at/sengi/

run:
	$(MKDIR) $@

.PHONY: reset
reset:
	RUBYOPT=-w $(BUNDLER) exec ./bin/config --reset

.PHONY: init
init:
	RUBYOPT=-w $(BUNDLER) exec ./bin/config --init

.PHONY: test
test:
	RUBYOPT=-w $(BUNDLER) exec ./test/suite_all.rb
