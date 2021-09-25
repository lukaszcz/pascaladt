
ifneq ($(findstring debug, $(MAKECMDGOALS)),)
DEBUG = true
endif

override OPTS += -Si -S2 -Fl~/lib/ -Fu~/include/

ifdef DEBUG
override OPTS += -Sa -gl -dDEBUG
endif

VPATH = tests:tests/units

obj_suffix := .o
prog_suffix := 

PROGRAM = customer$(prog_suffix)

.PHONY : all clean

all : $(PROGRAM)

$(PROGRAM) : customer.pas

clean :
	-rm $(PROGRAM) customer$(object_suffix) customer.ppu

%$(prog_suffix) : %.pas
	fpc $(OPTS) -o$@ $<

%$(obj_suffix) : %.pas
