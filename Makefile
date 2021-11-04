# um di aolhar isso https://titanwolf.org/Network/Articles/Article?AID=07f688c0-a8d7-4c3c-bcf8-2421fe9bd184

CC=gcc
CFLAGS=-lraylib -lGL -lm -lpthread -ldl -lrt -lX11
# DEPS = agent.h linklist.h settings.h
OBJ = slime_naive.o 

obj/%.o: %.c $(DEPS)
	$(CC) -c -o $@ $<

main: $(OBJ)
	$(CC) -o $@ $^  $(CFLAGS)