CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -fPIC
LDFLAGS ?= -shared -ldl

TARGET = waybar-hypr-ipc.so
SRC = waybar-hypr-ipc.c

DEST_LIB = $(HOME)/.local/lib
DEST_BIN = $(HOME)/.local/bin

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET) $(LDFLAGS)

install: $(TARGET)
	mkdir -p $(DEST_LIB) $(DEST_BIN)
	cp $(TARGET) $(DEST_LIB)/$(TARGET)
	cp waybar-wrapper.sh $(DEST_BIN)/waybar
	chmod +x $(DEST_BIN)/waybar

clean:
	rm -f $(TARGET)

.PHONY: all install clean
