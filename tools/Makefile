
CC = cc
FPC = fpc -Sh -S2
CFLAGS =
MCP_OBJECTS = mcp.o utils.o input.o
ALL_MCP_OBJECTS = $(MCP_OBJECTS) hashtable/hash_32.o hashtable/hashtable_itr.o hashtable/hashtable_utility.o hashtable/hashtable.o

all: mktempl mcp mkdeps

mktempl : mktempl.c
	$(CC) $(CFLAGS) -o mktempl mktempl.c

mcp: $(MCP_OBJECTS) hash_table
	$(CC) $(CFLAGS) -lm -o mcp $(ALL_MCP_OBJECTS)

mkdeps : mkdeps.pas
	$(FPC) -omkdeps mkdeps.pas

hash_table:
	cd hashtable; $(MAKE)

mcp.o: mcp.c input.h utils.h
	$(CC) $(CFLAGS) -c -o mcp.o mcp.c

utils.o: utils.c utils.h
	$(CC) $(CFLAGS) -c -o utils.o utils.c

input.o: input.c input.h 
	$(CC) $(CFLAGS) -c -o input.o input.c

clean:
	-cd hashtable; make clean
	-rm *.o *~ mcp mktempl mkdeps
