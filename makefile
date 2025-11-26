
CC=gcc
CFLAGS= -Wall -Wextra -DNDEBUG -O3

all: extern/libpicosat.so

extern/picosat.o: extern/picosat.c extern/picosat.h 
	$(CC) $(CFLAGS) -c $<

extern/libpicosat.so: extern/picosat.o 
	$(CC) $(CFLAGS) -shared -o $@ extern/picosat.o
