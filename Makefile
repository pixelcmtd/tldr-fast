VER      ?= v0.1

CC       ?= cc
LD       ?= $(CC)
RM       ?= rm -rf
INSTALL  ?= install

CFLAGS ?= -O3 -Wall -Wextra -pedantic
CFLAGS += -DVERSION='"$(VER)"'
CFLAGS += $(shell pkg-config --cflags libzip)
CFLAGS += -I/usr/include
CFLAGS += -I/usr/local/include
CFLAGS += -I/usr/local/opt/curl/include
CFLAGS += -I/usr/local/opt/libzip/include

PREFIX  ?= /usr/local

LDFLAGS += -L/usr/local/lib
LDFLAGS += -L/opt/local/lib
LDFLAGS += -L/opt/homebrew/lib
LDFLAGS += -lc -lm -lcurl -lzip

# Source, Binaries, Dependencies
SRC   := $(wildcard src/*.c)
OBJ   := $(patsubst src/%,obj/%,$(SRC:.c=.o))
DEP   := $(OBJ:.o=.d)
BIN   := tldr
-include $(DEP)

# Man Pages
MANSRC  := man/tldr.1
MANPATH := $(PREFIX)/share/man/man1

REAL_CC  := $(CC)
CC   = @echo "CC $<"; $(REAL_CC)

REAL_LD  := $(LD)
LD   = @echo "LD $@"; $(REAL_LD)

.PHONY: all clean format lint infer
.DEFAULT_GOAL = all

all: dir $(BIN)

dir:
	@mkdir -p obj

$(BIN): $(OBJ)
	$(LD) $(LDFLAGS) $^ -o $@
	strip $@

obj/%.o: src/%.c
	$(CC) $(CFLAGS) -c -MMD -MP -o $@ $<

install: all $(MANSRC)
	$(INSTALL) -d $(PREFIX)/bin
	$(INSTALL) $(BIN) $(PREFIX)/bin
	$(INSTALL) -d $(MANPATH)
	$(INSTALL) $(MANSRC) $(MANPATH)

clean:
	rm -rf obj/ $(DEP) $(BIN)

format:
	astyle --options=.astylerc src/*.c src/*.h

lint:
	oclint -report-type html -o report.html \
		-enable-clang-static-analyzer \
		-enable-global-analysis \
		-disable-rule=GotoStatement \
		-max-priority-1 1000 \
		-max-priority-2 1000 \
		-max-priority-3 1000 \
		src/*.c src/*.h -- $(CFLAGS) -c
	cppcheck --enable=all \
		-I/usr/local/include \
		-I/usr/local/opt/curl/include \
		-I/usr/local/opt/libzip/include \
		--language=c \
		--std=c99 \
		--inconclusive \
		src/*.c src/*.h
	splint +posixlib +gnuextensions \
		-Du_int64_t=unsigned\ long\ long \
		-Du_int32_t=unsigned\ int \
		-D__int64_t=long\ long \
		-D__uint64_t=unsigned\ long\ long \
		-D__int32_t=int \
		-D__uint32_t=unsigned\ int \
		-D__int16_t=short \
		-D__uint16_t=unsigned\ short \
		-D__darwin_natural_t=long \
		-D__darwin_time_t=long \
		-D__darwin_size_t=unsigned\ long \
		-D__darwin_ssize_t=long \
		-D__darwin_intptr_t=unsigned\ long \
		-D__darwin_clock_t=unsigned\ long \
		-I/usr/local/include \
		-I/usr/local/opt/curl/include \
		-I/usr/local/opt/libzip/include \
		-I/usr/local/Cellar/libzip/1.1/lib/libzip/include \
		src/*.c src/*.h

infer: clean
	infer -- make
