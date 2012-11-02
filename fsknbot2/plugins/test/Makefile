DEBUG=0

CC=gcc

FLAGS=-pipe -g
CFLAGS=$(FLAGS) -Wall -g -I./include 
LDFLAGS=$(FLAGS) -L./lib
LIBS= -Wl,-dn -lenet -Wl,-dy

OBJS=test.o

ADD_FLAGS=
ADD_CFLAGS=
ADD_LDFLAGS=
FLAGS+=$(ADD_FLAGS)
CFLAGS+=$(ADD_CFLAGS)
LDFLAGS+=$(ADD_LDFLAGS)

BIN=test

all: $(BIN)

$(BIN): $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $(BIN) $(LIBS)

clean:
	$(RM) $(OBJS) $(BIN)

.PHONY: clean

