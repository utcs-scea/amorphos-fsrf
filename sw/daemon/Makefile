HOME_DIR = /home/centos/src/project_data
AWS_FPGA = $(HOME_DIR)/aws-fpga
HDK_DIR = $(AWS_FPGA)/hdk/
SDK_DIR = $(AWS_FPGA)/sdk/

VPATH = src:include:$(HDK_DIR)/common/software/src:$(HDK_DIR)/common/software/include

INCLUDES = -I$(SDK_DIR)/userspace/include
INCLUDES += -I $(HDK_DIR)/common/software/include

CC = g++
CFLAGS = -O3 -std=c++11 -fpermissive -DCONFIG_LOGLEVEL=4 -g -Wall $(INCLUDES)

LDLIBS = -lfpga_mgmt -lrt -lpthread

SRC = ${SDK_DIR}/userspace/utils/sh_dpi_tasks.c

all: daemon

daemon: aos_daemon.cpp aos_daemon.hpp aos_fpga.hpp aos_stream.hpp aos_fio.hpp aos.hpp
	$(CC) $(CFLAGS) $(LDFLAGS) $(LDLIBS) $(SRC) aos_daemon.cpp -o daemon

clean:
	rm -f daemon
	sudo rm -f /tmp/aos_daemon.socket
