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
#include <sys/shm.h>
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
    SET_MODE_RESPONSE,
    STREAM_OPEN_REQUEST,
    STREAM_OPEN_RESPONSE,
    STREAM_CLOSE_REQUEST,
    STREAM_CLOSE_RESPONSE,
    STREAM_READ_REQUEST,
    STREAM_READ_RESPONSE,
    STREAM_WRITE_REQUEST,
    STREAM_WRITE_RESPONSE1,
    STREAM_WRITE_RESPONSE2
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

struct aos_stream_open_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    bool read;
    bool write;
};

struct aos_stream_open_response_packet {
    int sd;
    int meta_shmid;
    int read_shmid;
    int write_shmid;
};

struct aos_stream_close_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    int sd;
};

struct aos_stream_read_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    uint64_t meta_credits;
    uint64_t data_credits;
};

struct aos_stream_write_request_packet {
    uint64_t slot_id;
    uint64_t app_id;
    uint64_t len;
    bool last;
    bool credit_req;
};

struct aos_stream_write_response_packet {
    uint64_t meta_credits;
    uint64_t data_credits;
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
    
    aos_errcode aos_stream_open(bool read, bool write, int &sd) {
        assert(connectionOpen);
        assert(read || write);
        // Create the packet
        aos_stream_open_request_packet cmd_pckt;
        cmd_pckt.slot_id = slot_id;
        cmd_pckt.app_id = app_id;
        cmd_pckt.read = read;
        cmd_pckt.write = write;
        // Send over the request
        writeCommandPacket(aos_socket_command::STREAM_OPEN_REQUEST, cmd_pckt);
        // read the error code
        aos_errcode errco = readErrco();
        // read the response packet
        aos_stream_open_response_packet resp_pckt;
        readResponsePacket(resp_pckt);
        // attach shared memory
        if (resp_pckt.read_shmid != -1) {
            uint8_t *shmaddr;
            // map metadata
            shmaddr = (uint8_t*)shmat(resp_pckt.meta_shmid, nullptr, 0);
            assert(shmaddr != (void *)-1);
            stream_meta_base = shmaddr;
            stream_meta_addr = shmaddr;
            // map data
            shmaddr = (uint8_t*)shmat(resp_pckt.read_shmid, nullptr, 0);
            assert(shmaddr != (void *)-1);
            stream_read_base = shmaddr;
            stream_read_addr = shmaddr;
            // map data again to hide page boundary
            shmaddr += stream_read_size;
            shmaddr = (uint8_t*)shmat(resp_pckt.read_shmid, shmaddr, 0);
            assert(shmaddr != (void *)-1);
            // initialize other variables
            stream_meta_flag = 1;
            stream_read_meta_credits = stream_meta_size / 4;
            stream_read_data_credits = stream_read_size / 64;
        }
        if (resp_pckt.write_shmid != -1) {
            uint8_t *shmaddr;
            // map data
            shmaddr = (uint8_t*)shmat(resp_pckt.write_shmid, nullptr, 0);
            assert(shmaddr != (void *)-1);
            stream_write_base = shmaddr;
            stream_write_addr = shmaddr;
            // map data again to hide page boundary
            shmaddr += stream_write_size;
            shmaddr = (uint8_t*)shmat(resp_pckt.write_shmid, shmaddr, 0);
            assert(shmaddr != (void *)-1);
            // initialize credits
            stream_write_data_credits = stream_write_size / 64;
            stream_write_meta_credits = 32;
        }
        // copy over the data
        sd = resp_pckt.sd;
        return errco;
    }
    
    aos_errcode aos_stream_close(int sd) {
        assert(connectionOpen);
        // Create the packet
        aos_stream_close_request_packet cmd_pckt;
        cmd_pckt.slot_id = slot_id;
        cmd_pckt.app_id = app_id;
        cmd_pckt.sd = sd;
        // Send over the request
        writeCommandPacket(aos_socket_command::STREAM_CLOSE_REQUEST, cmd_pckt);
        // read the error code
        aos_errcode errco = readErrco();
        // detatch shared memory
        if (stream_read_base != nullptr) {
            assert(shmdt(stream_read_base) == 0);
            assert(shmdt(stream_read_base + (1<<21)) == 0);
            stream_read_base = nullptr;
            stream_read_addr = nullptr;
        }
        if (stream_write_base != nullptr) {
            assert(shmdt(stream_write_base) == 0);
            assert(shmdt(stream_write_base + (1<<21)) == 0);
            stream_write_base = nullptr;
            stream_write_addr = nullptr;
            assert(shmdt(stream_meta_base) == 0);
            stream_meta_base = nullptr;
            stream_meta_addr = nullptr;
        }
        return errco;
    }
    
    aos_errcode aos_stream_read(void* &dst, uint64_t &bytes, bool &end) {
        assert(connectionOpen);
        assert(stream_read_addr != nullptr);
        // process metadata entries
        uint64_t len = 0;
        const bool check_last = end;
        if (check_last) end = false;
        while (true) {
            // check for valid metadata entry
            const uint8_t val = *stream_meta_addr;
            if ((val >> 7) != stream_meta_flag) break;
            // update length
            len += ((val >> 1) & 0x3F) + 1;
            // increment metadata pointer
            stream_meta_addr += 4;
            const uint64_t meta_off = stream_meta_addr - stream_meta_base;
            if (meta_off >= stream_meta_size) {
                stream_meta_addr -= stream_meta_size;
                stream_meta_flag ^= 1;
            }
            stream_read_meta_credits += 1;
            // return immediately if end of packet
            const bool last = val & 0x1;
            if (check_last && last) {
                end = true;
                break;
            }
        }
        // transfer data to app
        const uint64_t len_bytes = len * 64;
        dst = stream_read_addr;
        bytes = len_bytes;
        // increment data pointer
        stream_read_addr += bytes;
        const uint64_t read_off = stream_read_addr - stream_read_base;
        if (read_off >= stream_read_size) {
            stream_read_addr -= stream_read_size;
        }
        return aos_stream_read_return();
    }
    
    aos_errcode aos_stream_free(uint64_t bytes) {
        assert(connectionOpen);
        assert(stream_read_addr != nullptr);
        // update credits
        const uint64_t len = bytes / 64;
        stream_read_data_credits += len;
        return aos_stream_read_return();
    }
    
    aos_errcode aos_stream_alloc(void* &src, uint64_t &bytes) {
        assert(connectionOpen);
        assert(stream_write_addr != nullptr);
        // calculate length
        const bool have_credits = stream_write_meta_credits > 0;
        const uint64_t len_credits = have_credits ? stream_write_data_credits : 0;
        const uint64_t len = std::min(bytes / 64, len_credits);
        const uint64_t len_bytes = len * 64;
        src = stream_write_addr;
        bytes = len_bytes;
        // update metadata
        stream_write_addr += len_bytes;
        const uint64_t write_off = stream_write_addr - stream_write_base;
        if (write_off >= stream_write_size) {
            stream_write_addr -= stream_write_size;
        }
        stream_write_data_credits -= len;
        if (len > 0) {
            stream_write_meta_credits -= 1;
        }
        return aos_stream_write_return(0, false);
    }
    
    aos_errcode aos_stream_write(uint64_t bytes, bool last) {
        assert(connectionOpen);
        assert(stream_write_addr != nullptr);
        const uint64_t len = bytes / 64;
        return aos_stream_write_return(len, last);
    }

private:
    const bool error_codes = false;
    
    sockaddr_un socket_name;
    uint64_t slot_id;
    uint64_t app_id;
    int cfd;
    bool connectionOpen;
    bool intialized;
    
    uint8_t stream_meta_flag;
    uint8_t *stream_meta_base = nullptr;
    uint8_t *stream_read_base = nullptr;
    uint8_t *stream_write_base = nullptr;
    volatile uint8_t *stream_meta_addr;
    uint8_t *stream_read_addr;
    uint8_t *stream_write_addr;
    uint64_t stream_meta_size = 1<<12;
    uint64_t stream_read_size = 1<<21;
    uint64_t stream_write_size = 1<<21;
    
    uint64_t stream_read_meta_credits;
    uint64_t stream_read_data_credits;
    uint64_t stream_write_meta_credits;
    uint64_t stream_write_data_credits;
    
    aos_errcode aos_stream_read_return() {
        // return credits?
        bool req = false;
        req |= stream_read_meta_credits >= (stream_meta_size / 4 / 8);
        req |= stream_read_data_credits >= (stream_read_size / 64 / 8);
        if (req) {
            // create the packet
            aos_stream_read_request_packet cmd_pckt;
            cmd_pckt.slot_id = slot_id;
            cmd_pckt.app_id = app_id;
            cmd_pckt.meta_credits = stream_read_meta_credits;
            cmd_pckt.data_credits = stream_read_data_credits;
            // send over the request
            writeCommandPacket(aos_socket_command::STREAM_READ_REQUEST, cmd_pckt);
            // read the error code
            aos_errcode errco = readErrco();
            // reset credits
            stream_read_meta_credits = 0;
            stream_read_data_credits = 0;
            return errco;
        }
        return aos_errcode::SUCCESS;
    }
    
    aos_errcode aos_stream_write_return(uint64_t len, bool last) {
        // request credits?
        bool req = false;
        req |= stream_write_meta_credits <= (32 / 8);
        req |= stream_write_data_credits <= (stream_write_size / 64 / 8);
        // create the packet
        if ((len == 0) && !req) return aos_errcode::SUCCESS;
        aos_stream_write_request_packet cmd_pckt;
        cmd_pckt.slot_id = slot_id;
        cmd_pckt.app_id = app_id;
        cmd_pckt.len = len;
        cmd_pckt.last = last;
        cmd_pckt.credit_req = req;
        // send over the request
        writeCommandPacket(aos_socket_command::STREAM_WRITE_REQUEST, cmd_pckt);
        // read the error code
        aos_errcode errco = readErrco();
        // read the response packet
        if (req) {
            aos_stream_write_response_packet resp_pckt;
            readResponsePacket(resp_pckt);
            stream_write_meta_credits += resp_pckt.meta_credits;
            stream_write_data_credits += resp_pckt.data_credits;
        }
        return errco;
    }
    
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
        if (1) {
            const int full_size = sizeof(aos_socket_command) + sizeof(T);
            uint8_t data[full_size];
            
            memcpy(data, &cmd, sizeof(aos_socket_command));
            memcpy(data + sizeof(aos_socket_command), &cmd_pckt, sizeof(T));
            
            if (write(cfd, data, full_size) < full_size) {
                printf("Unable to write command\n");
                perror("Client write");
            }
        } else {
            const int sizeof_cmd = sizeof(aos_socket_command);
            if (write(cfd, &cmd, sizeof_cmd) < sizeof_cmd) {
                printf("Unable to write command\n");
                perror("Client write");
            }
            
            if (write(cfd, &cmd_pckt, sizeof(T)) < (int)sizeof(T)) {
                printf("Unable to write command packet\n");
                perror("Client write");
            }
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
