
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

.PHONY: cov
cov:
	RUBYOPT=-w COVERAGE=1 $(BUNDLER) exec ./test/suite_all.rb -v

.PHONY: cov_local
cov_local:
	RUBYOPT=-w SIMPLECOV_PHPUNIT_LOAD_PATH=../simplecov-phpunit COVERAGE=1 $(BUNDLER) exec ./test/suite_all.rb -v
