#ifndef AOS_H_
#define AOS_H_

// Normal includes
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>
#include <syslog.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/un.h>
#include <unistd.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <assert.h>
#include <limits.h>
#include <sys/mman.h>
#include <string>

// namespace cascade::aos {

#define SOCKET_NAME "/tmp/aos_daemon.socket"
#define SOCKET_FAMILY AF_UNIX
#define SOCKET_TYPE SOCK_STREAM

#define BACKLOG 128

enum class aos_socket_command {
    CNTRLREG_READ_REQUEST,
    CNTRLREG_READ_RESPONSE,
    CNTRLREG_WRITE_REQUEST,
    CNTRLREG_WRITE_RESPONSE,
    FILE_OPEN_REQUEST,
    FILE_OPEN_RESPONSE,
    FILE_CLOSE_REQUEST,
    FILE_CLOSE_RESPONSE,
    MMAP_REQUEST,
    MMAP_RESPONSE,
    MUNMAP_REQUEST,
    MUNMAP_RESPONSE,
    MSYNC_REQUEST,
    MSYNC_RESPONSE,
    SET_MODE_REQUEST,
    SET_MODE_RESPONSE
};

enum class aos_errcode {
    SUCCESS = 0,
    RETRY, // for reads
    ALIGNMENT_FAILURE,
    PROTECTION_FAILURE,
    APP_DOES_NOT_EXIST,
    TIMEOUT,
    UNKNOWN_FAILURE
};

struct aos_cntrlreg_read_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    uint64_t addr64;
};

struct aos_cntrlreg_read_response_packet {
    uint64_t data64;
};

struct aos_cntrlreg_write_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    uint64_t addr64;
    uint64_t data64; 
};

struct aos_file_open_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    char file_path[PATH_MAX];
};

struct aos_file_open_response_packet {
    int fd;
};

struct aos_file_close_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    int fd;
};

struct aos_mmap_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    void *addr;
    uint64_t length;
    int prot;
    int flags;
    int fd;
    uint64_t offset;
};

struct aos_mmap_response_packet {
    void *addr;
};

struct aos_munmap_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    void *addr;
    uint64_t length;
};

struct aos_msync_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    void *addr;
    uint64_t length;
    int flags;
};

struct aos_set_mode_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    uint64_t mode;
    uint64_t data;
};

class aos_client {
public:

    aos_client() :
        slot_id(0),
        app_id(0),
        cfd(-1),
        connectionOpen(false),
        intialized(true)
    {
        // Setup the struct needed to connect the aos daemon
        memset(&socket_name, 0, sizeof(struct sockaddr_un));
        socket_name.sun_family = SOCKET_FAMILY;
        strncpy(socket_name.sun_path, SOCKET_NAME, sizeof(socket_name.sun_path) - 1);
    }

    void set_slot_id(uint64_t new_slot_id) {
        slot_id = new_slot_id;
    }

    void set_app_id(uint64_t new_app_id) {
        app_id = new_app_id;
    }

    bool connect() {
        return openSocket();
    }
    
    bool connected() {
        return connectionOpen;
    }

    void disconnect() {
        if (connectionOpen) closeSocket();
    }
    
    aos_errcode aos_cntrlreg_read(uint64_t addr, uint64_t & value) const {
        assert(connectionOpen);
        // Create the packet
        aos_cntrlreg_read_request_packet cmd_pckt;
        cmd_pckt.slot_id = slot_id;
        cmd_pckt.app_id = app_id;
        cmd_pckt.addr64 = addr;
        // Send over the request
        writeCommandPacket(aos_socket_command::CNTRLREG_READ_REQUEST, cmd_pckt);
        // read the error code
        aos_errcode errco = readErrco();
        // read the response packet
        aos_cntrlreg_read_response_packet resp_pckt;
        readResponsePacket(resp_pckt);
        // copy over the data
        value = resp_pckt.data64;
        return errco;
    }
    
    aos_errcode aos_cntrlreg_write(uint64_t addr, uint64_t value) const {
        assert(connectionOpen);
        // Create the packet
        aos_cntrlreg_write_request_packet cmd_pckt;
        cmd_pckt.slot_id = slot_id;
        cmd_pckt.app_id = app_id;
        cmd_pckt.addr64 = addr;
        cmd_pckt.data64 = value;
        // Send over the request
        writeCommandPacket(aos_socket_command::CNTRLREG_WRITE_REQUEST, cmd_pckt);
        // Return success/error condition
        return readErrco();
    }
    
    aos_errcode aos_file_open(std::string path, int & fd) const {
        assert(connectionOpen);
        // Create the packet
        aos_file_open_request_packet cmd_pckt;
        cmd_pckt.slot_id = slot_id;
        cmd_pckt.app_id = app_id;
        realpath(path.c_str(), cmd_pckt.file_path);
        // Send over the request
        writeCommandPacket(aos_socket_command::FILE_OPEN_REQUEST, cmd_pckt);
        // read the error code
        aos_errcode errco = readErrco();
        // read the response packet
        aos_file_open_response_packet resp_pckt;
        readResponsePacket(resp_pckt);
        // copy over the data
        fd = resp_pckt.fd;
        return errco;
    }
    
    aos_errcode aos_file_close(int fd) const {
        assert(connectionOpen);
        // Create the packet
        aos_file_close_request_packet cmd_pckt;
        cmd_pckt.slot_id = slot_id;
        cmd_pckt.app_id = app_id;
        cmd_pckt.fd = fd;
        // Send over the request
        writeCommandPacket(aos_socket_command::FILE_CLOSE_REQUEST, cmd_pckt);
        // block so all data is flushed out
        // read the response packet
        aos_file_open_response_packet resp_pckt;
        readResponsePacket(resp_pckt);
        // read the error code
        return readErrco();
    }
    
    aos_errcode aos_mmap(void* &addr, uint64_t length, int prot,
                         int flags, int fd, uint64_t offset) const {
        assert(connectionOpen);
        // Create the packet
        aos_mmap_request_packet cmd_pckt;
        cmd_pckt.slot_id = slot_id;
        cmd_pckt.app_id = app_id;
        cmd_pckt.addr = addr;
        cmd_pckt.length = length;
        cmd_pckt.prot = prot;
        cmd_pckt.flags = flags;
        cmd_pckt.fd = fd;
        cmd_pckt.offset = offset;
        // Send over the request
        writeCommandPacket(aos_socket_command::MMAP_REQUEST, cmd_pckt);
        // read the error code
        aos_errcode errco = readErrco();
        // read the response packet
        aos_mmap_response_packet resp_pckt;
        readResponsePacket(resp_pckt);
        // copy over the data
        addr = resp_pckt.addr;
        return errco;
    }
    
    aos_errcode aos_munmap(void* addr, uint64_t length) const {
        assert(connectionOpen);
        // Create the packet
        aos_munmap_request_packet cmd_pckt;
        cmd_pckt.slot_id = slot_id;
        cmd_pckt.app_id = app_id;
        cmd_pckt.addr = addr;
        cmd_pckt.length = length;
        // Send over the request
        writeCommandPacket(aos_socket_command::MUNMAP_REQUEST, cmd_pckt);
        // read the error code
        aos_errcode errco = readErrco();
        return errco;
    }
    
    aos_errcode aos_msync(void* addr, uint64_t length, int flags) const {
        assert(connectionOpen);
        // Create the packet
        aos_msync_request_packet cmd_pckt;
        cmd_pckt.slot_id = slot_id;
        cmd_pckt.app_id = app_id;
        cmd_pckt.addr = addr;
        cmd_pckt.length = length;
        cmd_pckt.flags = flags;
        // Send over the request
        writeCommandPacket(aos_socket_command::MSYNC_REQUEST, cmd_pckt);
        // read the error code
        aos_errcode errco = readErrco();
        return errco;
    }
    
    aos_errcode aos_set_mode(uint64_t mode, uint64_t data) const {
        assert(connectionOpen);
        // Create the packet
        aos_set_mode_request_packet cmd_pckt;
        cmd_pckt.slot_id = slot_id;
        cmd_pckt.app_id = app_id;
        cmd_pckt.mode = mode;
        cmd_pckt.data = data;
        // Send over the request
        writeCommandPacket(aos_socket_command::SET_MODE_REQUEST, cmd_pckt);
        // read the error code
        aos_errcode errco = readErrco();
        return errco;
    }

private:
    sockaddr_un socket_name;
    uint64_t slot_id;
    uint64_t app_id;
    int cfd;
    bool connectionOpen;
    bool intialized;
    const bool error_codes = false;

    bool openSocket() {
        cfd = socket(SOCKET_FAMILY, SOCKET_TYPE, 0);
        if (cfd == -1) {
           perror("client socket");
           return false;
        }

        if (::connect(cfd, (sockaddr *) &socket_name, sizeof(sockaddr_un)) == -1) {
            perror("Daemon connection");
            return false;
        }
        connectionOpen = true;
        return true;
    }

    void closeSocket() {
        if (close(cfd) == -1) {
            perror("close error on client");
        }
        connectionOpen = false;
    }
    
    aos_errcode readErrco() const {
        aos_errcode errco = aos_errcode::SUCCESS;
        if (error_codes && read(cfd, &errco, sizeof(aos_errcode)) < (int)sizeof(aos_errcode)) {
            errco = aos_errcode::UNKNOWN_FAILURE;
        }
        return errco;
    }
    
    template <typename T>
    int writeCommandPacket(aos_socket_command cmd, T & cmd_pckt) const {
        const int sizeof_cmd = sizeof(aos_socket_command);
        if (write(cfd, &cmd, sizeof_cmd) < sizeof_cmd) {
            printf("Unable to write command\n");
            perror("Client write");
        }
        
        if (write(cfd, &cmd_pckt, sizeof(T)) < (int)sizeof(T)) {
            printf("Unable to write command packet\n");
            perror("Client write");
        }
        // return success/error
        return 0;
    }

    template <typename T>
    int readResponsePacket(T & resp_pckt) const {
        if (read(cfd, &resp_pckt, sizeof(T)) < (int)sizeof(T)) {
            perror("Unable to read response packet from daemon");
        }
        return 0;
    }

};

//} // namespace cascade::aos

#endif  // end AOS_H_
