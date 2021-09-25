
CFLAGS = -O2

all: hashtable.o hashtable_itr.o hashtable_utility.o hash_32.o

hashtable.o: hashtable.c
	cc $(CFLAGS) -c hashtable.c -o hashtable.o

hashtable_itr.o: hashtable_itr.c
	cc $(CFLAGS) -c hashtable_itr.c -o hashtable_itr.o

hashtable_utility.o: hashtable_utility.c
	cc $(CFLAGS) -c hashtable_utility.c -o hashtable_utility.o

hash_32.o : hash_32.c
	cc $(CFLAGS) -c hash_32.c -o hash_32.o

clean:
	-rm *.o *~

