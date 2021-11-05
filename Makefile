PREFIX    ?= /usr/local
BINDIR    ?= $(PREFIX)/bin
LIBDIR    ?= $(PREFIX)/lib/lxd-nixpkgs-test

all:

install:
	sed "s|SELF=.*|SELF=$(LIBDIR)|g" -i lxd-nixpkgs-test.sh
	install -D lxd-nixpkgs-test.sh $(BINDIR)/lxd-nixpkgs-test
	ln -s $(BINDIR)/lxd-nixpkgs-test $(BINDIR)/lnt
	mkdir -p $(LIBDIR)
	cp -r shared inside help.txt $(LIBDIR)
