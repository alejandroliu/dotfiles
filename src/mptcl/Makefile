#
# Build script
#
DESTDIR	= /usr/local
BINDIR	= /bin
MANDIR	= /man
LIBDIR  = /lib/mptcl

#PWD=$(shell pwd)
#ASHCC=$(PWD)/../php-lib/myphp $(PWD)/../../lib/ashcc.php

all:

$(DESTDIR)$(BINDIR)/mptcl: mptcl.sh
	install -m755 $< $@

$(DESTDIR)$(BINDIR)/edled: edled.sh
	install -m755 $< $@

$(DESTDIR)$(LIBDIR)/editor.tcl: d_edl.tcl
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/mptcl.tcl: d_mplayer.tcl
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/mplayer.tcl: mplayer.tcl
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/zoekbar.tcl: zoekbar.tcl
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/edled.tcl: edled.tcl
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/mbrowse.tcl: mbrowse.tcl
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/tk_getString.tcl: tk_getString.tcl
	install -m644 $< $@

$(DESTDIR)$(LIBDIR)/seekbar.tcl: seekbar.tcl
	install -m644 $< $@

subdirs:
	mkdir -p \
	    $(DESTDIR)$(BINDIR) \
	    $(DESTDIR)/$(LIBDIR)

install: subdirs \
	$(DESTDIR)$(BINDIR)/mptcl \
	$(DESTDIR)$(BINDIR)/edled \
	$(DESTDIR)$(LIBDIR)/editor.tcl \
	$(DESTDIR)$(LIBDIR)/mptcl.tcl \
	$(DESTDIR)$(LIBDIR)/mplayer.tcl \
	$(DESTDIR)$(LIBDIR)/zoekbar.tcl \
	$(DESTDIR)$(LIBDIR)/edled.tcl \
	$(DESTDIR)$(LIBDIR)/mbrowse.tcl \
	$(DESTDIR)$(LIBDIR)/tk_getString.tcl \
	$(DESTDIR)$(LIBDIR)/seekbar.tcl

clean:
	find . -name '*~' | xargs -r rm -v
