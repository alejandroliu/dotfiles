#
DESTDIR	= /usr/local
BINDIR	= /bin
MANDIR	= /man

ifneq ($(wildcard tlframe.mk),)
 include tlframe.mk
endif

all:

$(DESTDIR)$(BINDIR)/pwcrypt: pwcrypt
	install -m 755 $< $@

$(DESTDIR)$(BINDIR)/lnpkg: lnpkg
	install -m 755 $< $@

$(DESTDIR)$(BINDIR)/manify: manify
	install -m 755 $< $@

$(DESTDIR)$(BINDIR)/perlmods: perlmods
	install -m 755 $< $@

subdirs:
	mkdir -p $(DESTDIR)$(BINDIR)

manpages:
	mkdir -p $(DESTDIR)$(MANDIR)
	perl manify --outdir=$(DESTDIR)$(MANDIR) --genman .

install: subdirs manpages \
	$(DESTDIR)$(BINDIR)/pwcrypt \
	$(DESTDIR)$(BINDIR)/lnpkg \
	$(DESTDIR)$(BINDIR)/manify \
	$(DESTDIR)$(BINDIR)/perlmods

clean:
	find . -name '*~' | xargs -r rm -v
