SRC := writer.c
TARGET = writer
OBJS := $(SRC:.c=.o)

ifeq ("$(CROSS_COMPILE)","aarch64-none-linux-gnu-")
CC := /home/mtoomey/arm-cross-compiler/arm-gnu-toolchain-13.3.rel1-x86_64-aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-gcc
endif

all: $(TARGET)

$(TARGET) : $(OBJS)
	$(CC) $(INCLUDES) $(OBJS) -o $(TARGET) $(LDFLAGS)

clean:
	-rm -f *.o $(TARGET) *.elf *.map
