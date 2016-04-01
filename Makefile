
GEM_NAME = sengi
ALL_TARGETS_EXT = tmp

include Makefile.common

dev:
	RUBYOPT=-rbundler/setup ruby ./bin/find http://fox21.at/

tmp:
	$(MKDIR) $@
