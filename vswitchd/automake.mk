sbin_PROGRAMS += vswitchd/ovs-vswitchd
man_MANS += vswitchd/ovs-vswitchd.8
DISTCLEANFILES += \
	vswitchd/ovs-vswitchd.8

vswitchd_ovs_vswitchd_SOURCES = \
	vswitchd/bridge.c \
	vswitchd/bridge.h \
	vswitchd/ovs-vswitchd.c \
	vswitchd/system-stats.c \
	vswitchd/system-stats.h \
	vswitchd/xenserver.c \
	vswitchd/xenserver.h
vswitchd_ovs_vswitchd_LDADD = \
	ofproto/libofproto.la \
	lib/libsflow.la \
	lib/libopenvswitch.la
vswitchd_ovs_vswitchd_LDFLAGS = $(AM_LDFLAGS) $(DPDK_vswitchd_LDFLAGS)
EXTRA_DIST += vswitchd/INTERNALS
MAN_ROOTS += vswitchd/ovs-vswitchd.8.in

# vswitch schema and IDL
EXTRA_DIST += vswitchd/vswitch.ovsschema
pkgdata_DATA += vswitchd/vswitch.ovsschema

# vswitch E-R diagram
#
# If "python" or "dot" or "groff" is not available, then we do not add
# graphical diagram to the documentation.
if HAVE_PYTHON
if HAVE_DOT
if HAVE_GROFF
vswitchd/vswitch.gv: ovsdb/ovsdb-dot.in vswitchd/vswitch.ovsschema
	$(AM_V_GEN)$(OVSDB_DOT) $(srcdir)/vswitchd/vswitch.ovsschema > $@
vswitchd/vswitch.eps: vswitchd/vswitch.gv
	$(AM_V_GEN)(dot -T eps < vswitchd/vswitch.gv) > $@.tmp && \
	mv $@.tmp $@
VSWITCH_PIC = vswitchd/vswitch.eps
# Install eps diagram to the same folder as the documentation
VSWITCH_DOT_DIAGRAM_ARG = --er-diagram=vswitch.eps
man_MANS += $(VSWITCH_PIC)
DISTCLEANFILES += vswitchd/vswitch.gv $(VSWITCH_PIC)
endif
endif
endif

# vswitch schema documentation
EXTRA_DIST += vswitchd/vswitch.xml
DISTCLEANFILES += vswitchd/ovs-vswitchd.conf.db.5
man_MANS += vswitchd/ovs-vswitchd.conf.db.5
vswitchd/ovs-vswitchd.conf.db.5: \
	ovsdb/ovsdb-doc vswitchd/vswitch.xml vswitchd/vswitch.ovsschema \
	$(VSWITCH_PIC)
	$(AM_V_GEN)$(OVSDB_DOC) \
		--title="ovs-vswitchd.conf.db" \
		$(VSWITCH_DOT_DIAGRAM_ARG) \
		--version=$(VERSION) \
		$(srcdir)/vswitchd/vswitch.ovsschema \
		$(srcdir)/vswitchd/vswitch.xml > $@.tmp && \
	mv $@.tmp $@

# Version checking for vswitch.ovsschema.
ALL_LOCAL += vswitchd/vswitch.ovsschema.stamp
vswitchd/vswitch.ovsschema.stamp: vswitchd/vswitch.ovsschema
	@sum=`sed '/cksum/d' $? | cksum`; \
	expected=`sed -n 's/.*"cksum": "\(.*\)".*/\1/p' $?`; \
	if test "X$$sum" = "X$$expected"; then \
	  touch $@; \
	else \
	  ln=`sed -n '/"cksum":/=' $?`; \
	  echo >&2 "$?:$$ln: checksum \"$$sum\" does not match (you should probably update the version number and fix the checksum)"; \
	  exit 1; \
	fi
CLEANFILES += vswitchd/vswitch.ovsschema.stamp

# Clean up generated files from older OVS versions.  (This is important so that
# #include "vswitch-idl.h" doesn't get the wrong copy.)
CLEANFILES += vswitchd/vswitch-idl.c vswitchd/vswitch-idl.h
