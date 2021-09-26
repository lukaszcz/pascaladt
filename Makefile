# Note:
#
# unit.i - a template interface of a unit (an mcp include file)
#
# unit_impl.i - a template implementation of a unit (an mcp
# include file)
#
# unit.pas.mcp - the unit template to be processed by
# mcp; it &includes unit.i and unit_impl.i
#
# unit.mac - mcp macros exported from the unit
#
# unit_impl.mac - mcp macros used only in the implementation of the
# unit
#
# unit.mcp - mcp defines automatically generated from unit.i with
# mktempl
#
# unit_impl.mcp - mcp defines automatically generated from unit_impl.i with
# mktempl
#
# unit.defs - mcp defines from interfaces of units used by the unit;
# generated automatically by mkdeps
#
# unit.pas is generated from unit.pas.mcp, but it also depends on
# unit.i and unit_impl.i (which are &included in unit.pas.mcp), and on
# unit.mcp and unit_impl.mcp


ifneq ($(findstring test, $(MAKECMDGOALS)),)
TEST = true
DEBUG = true
endif

ifneq ($(findstring tests, $(MAKECMDGOALS)),)
TEST = true
DEBUG = true
endif

ifneq ($(findstring check, $(MAKECMDGOALS)),)
RELEASE = true
endif

ifneq ($(findstring smart, $(MAKECMDGOALS)),)
SMART = true
endif

ifneq ($(findstring release, $(MAKECMDGOALS)),)
RELEASE = true
endif

ifneq ($(findstring debug, $(MAKECMDGOALS)),)
DEBUG = true
endif

ifneq ($(findstring windows, $(MAKECMDGOALS)),)
WINDOWS = true
endif

ifneq ($(findstring docs, $(MAKECMDGOALS)),)
DOCS = true
endif

override OPTS += -Si -S2 -Sh -Futests/units

ifdef SMART
override OPTS += -CX
endif

ifdef RELEASE
override OPTS += -Ur -O3 -v0
endif

ifdef DEBUG
override OPTS += -vewn -Sa -g -gl -dDEBUG_PASCAL_ADT
endif

ifdef TEST
override OPTS += -dTEST_PASCAL_ADT
endif

ifdef WINDOWS
override OPTS += -dPASCAL_ADT_WINDOWS -Twin32
endif

ifdef DOCS
override MCP_OPTS += -dMCP_SRCDOC
endif

VPATH = tests:tests/units

obj_suffix :=.o
prog_suffix :=
static_lib_suffix :=.a
dynamic_lib_suffix :=.so

FPC := fpc
MCP := tools/mcp
MKTEMPL := tools/mktempl

override MCP_OPTS += --ignore-case
MKTEMPL_OPTS := -f -p _mcp_prefix -p Key:_mcp_key_prefix -p Item:_mcp_item_prefix

PASMCPFILES := $(wildcard *.pas.mcp)
MACFILES := $(wildcard *.mac)
MCPFILES := $(patsubst %.i, %.mcp, $(wildcard *.i))
INTERFACE_I_FILES := $(patsubst %.pas.mcp, %.i, $(wildcard *.pas.mcp))
PASFILES := adtmsg.pas adtexcept.pas
ALLPASFILES := $(patsubst %.pas.mcp, %.pas, $(wildcard *.pas.mcp))
ADTUNITS := $(patsubst %.pas, %$(obj_suffix), $(ALLPASFILES))
TESTPROGS := $(patsubst %.pas, %$(prog_suffix), $(wildcard tests/*.pas))
TESTUNITS := $(patsubst %.pas, %$(obj_suffix), $(wildcard tests/units/*.pas))

TOOLSDEPS := $(wildcard tools/*.pas tools/*.c tools/*.h)

.PHONY : install static dynamic smart all units tests debug windows docs clean cleandocs cleanprogs fastclean tools check

install :
	./install.sh

static : units
	ppumove -s -o pascaladt$(VER)$(static_lib_suffix) *.ppu

dynamic : units
	ppumove -o pascaladt$(VER)$(dynamic_lib_suffix) *.ppu

smart : units
	ppumove -s -o pascaladt$(VER)$(static_lib_suffix) *.ppu

all : units tests

units : $(ADTUNITS)

tests : units $(TESTPROGS) $(TESTUNITS)

debug : units

windows : units

tools : tools.dep

tools.dep : $(TOOLSDEPS)
	cd tools; $(MAKE)
	touch tools.dep

docs : $(ALLPASFILES)
	if [ ! -d docs ]; then mkdir docs; fi
	srcdoc -bd -t "PascalAdt $(VER) documentation" -o ./docs *.pas ./docsrc/*.txt ./docsrc/*.srd

# output from the cleanup script should be ignored - it would produce
# too much grabage
clean :
	-./cleanup.sh noprompt > /dev/null 2>&1
	-cd tools; $(MAKE) clean > /dev/null 2>&1

cleandocs :
	-rm -rf docs

cleanprogs :
	-cd tests; ./rmtestprogs.sh > /dev/null 2>&1

fastclean :
	-./cleanup.sh fast > /dev/null 2>&1

check : tests
	cd tests; ./testall.sh

Makefile : deps.mak

deps.mak : $(PASFILES) $(PASMCPFILES) tools.dep
	tools/mkdeps *.pas.mcp tests/*.pas tests/units/*.pas > deps.mak
	touch Makefile

include deps.mak

adtmap.mcp : adtmap.i
	$(MKTEMPL) -f -p _mcp_map_prefix adtmap.i

adtmap_impl.mcp : adtmap_impl.i
	$(MKTEMPL) -f -p _mcp_map_prefix adtmap_impl.i

%$(prog_suffix) : %.pas
	$(FPC) $(OPTS) -o$@ $<

%$(obj_suffix) : %.pas
	$(FPC) $(OPTS) -o$@ $<

%.pas : %.pas.mcp
	$(MCP) $(MCP_OPTS) $<

%.mcp : %.i
	$(MKTEMPL) $(MKTEMPL_OPTS) $<
