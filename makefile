CXX = gcc
CXXFLAGS=-O3
LIBS=
DEPS=

BIN=./bin/
SRC=./src/

all: $(BIN)do_join

$(BIN)%: $(SRC)%.c
	$(CXX) $(CXXFLAGS) $< -o $@ $(LIBS)
