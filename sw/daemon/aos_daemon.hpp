#ifndef AOS_DAEMON_
#define AOS_DAEMON_

#include <sys/select.h>
#include <unordered_set>
#include <map>
#include "aos.hpp"
#include "aos_fpga.hpp"
#include "aos_fio.hpp"
#include "aos_stream.hpp"

void printError(std::string errStr) {
    printf("%s\n", errStr.c_str());
    //std::cout << errStr << std::endl;
}

class aos_host {
public:
    const bool error_codes = false;

    aos_host() {
        fpga[0] = new aos_fpga(0);
        
        socket_initialized = false;
    }

    int init_socket() {
        if (socket_initialized) {
            printf("Socket already intialied");
        }
        remove(SOCKET_NAME);
        passive_socket = socket(SOCKET_FAMILY, SOCKET_TYPE, 0);
        if (passive_socket == -1) {
           perror("socket");
           exit(EXIT_FAILURE);
        }
        
        int one = 1;
        int ret = setsockopt(passive_socket, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(int));
        if (ret == -1) {
           perror("setsockopt SO_REUSEADDR");
           exit(EXIT_FAILURE);
        }
    #ifdef SO_REUSEPORT
        ret = setsockopt(passive_socket, SOL_SOCKET, SO_REUSEPORT, &one, sizeof(int));
        if (ret == -1) {
           perror("setsockopt SO_REUSEPORT");
           exit(EXIT_FAILURE);
        }
    #endif
        linger ling;
        ling.l_onoff = 0;
        ling.l_linger = 0;
        ret = setsockopt(passive_socket, SOL_SOCKET, SO_LINGER, &ling, sizeof(linger));
        if (ret == -1) {
           perror("setsockopt SO_LINGER");
           exit(EXIT_FAILURE);
        }
        
        sockaddr_un socket_name;
        memset(&socket_name, 0, sizeof(sockaddr_un));
        socket_name.sun_family = AF_UNIX;
        strncpy(socket_name.sun_path, SOCKET_NAME, sizeof(socket_name.sun_path) - 1);
        ret = bind(passive_socket, (const sockaddr *) &socket_name, sizeof(sockaddr_un));
        if (ret == -1) {
           perror("bind");
           exit(EXIT_FAILURE);
        }

        ret = listen(passive_socket, BACKLOG);
        if (ret == -1) {
            perror("listen");
            exit(EXIT_FAILURE);
        }

        FD_ZERO(&read_set);
        FD_SET(passive_socket, &read_set);
        maxFd = passive_socket;
        socket_initialized = true;
        return 0;
    }

    void startTransaction(int & cfd) {
restartTransaction:
        fd_set temp_set = read_set; 

        // Select fd with data
        if (select(maxFd+1, &temp_set, nullptr, nullptr, nullptr) < 1) {
            perror("select error");
            goto restartTransaction;
        }

        // Add new connections to read set
        if (FD_ISSET(passive_socket, &temp_set)) {
            cfd = accept(passive_socket, NULL, NULL);
            if (cfd == -1) {
                perror("accept error");
            }
            FD_SET(cfd, &read_set);
            if (cfd > maxFd) maxFd = cfd;
            open_fds.insert(cfd);
            goto restartTransaction;
        }

        // Identify source of command
        cfd = -1;
        for (int fd : open_fds) {
            if (FD_ISSET(fd, &temp_set)) cfd = fd;
        }
        if (cfd == -1) {
            perror("selected fd not found\n");
            goto restartTransaction;
        }
    }

    int readCommand(int cfd, aos_socket_command* cmd) {
        if (read(cfd, cmd, sizeof(aos_socket_command)) < (int)sizeof(aos_socket_command)) {
            //perror("Unable to read cmd");
            close(cfd);
            FD_CLR(cfd, &read_set);
            open_fds.erase(cfd);
            return 1;
        }
        
        int numBytes;
        switch(*cmd) {
            case aos_socket_command::CNTRLREG_READ_REQUEST:
                numBytes = sizeof(aos_cntrlreg_read_request_packet);
                break;
            case aos_socket_command::CNTRLREG_WRITE_REQUEST:
                numBytes = sizeof(aos_cntrlreg_write_request_packet);
                break;
            case aos_socket_command::FILE_OPEN_REQUEST:
                numBytes = sizeof(aos_file_open_request_packet);
                break;
            case aos_socket_command::FILE_CLOSE_REQUEST:
                numBytes = sizeof(aos_file_close_request_packet);
                break;
            case aos_socket_command::MMAP_REQUEST:
                numBytes = sizeof(aos_mmap_request_packet);
                break;
            case aos_socket_command::MUNMAP_REQUEST:
                numBytes = sizeof(aos_munmap_request_packet);
                break;
            case aos_socket_command::MSYNC_REQUEST:
                numBytes = sizeof(aos_msync_request_packet);
                break;
            case aos_socket_command::SET_MODE_REQUEST:
                numBytes = sizeof(aos_set_mode_request_packet);
                break;
            default:
                printf("Error: not a request\n");
                numBytes = -1;
        }
        if (numBytes == -1) return 1;
        
        if (read(cfd, &aos_pkt, numBytes) < numBytes) {
            perror("Unable to read cmd data");
            close(cfd);
            FD_CLR(cfd, &read_set);
            open_fds.erase(cfd);
            return 1;
        }

        return 0;
    }

    int writeResponse(int cfd, aos_errcode errco, aos_socket_command cmd) {
        if (!socket_initialized) {
            printError("Can't write response packet without an open socket");
        }
        
        if (error_codes && write(cfd, &errco, sizeof(aos_errcode)) < (int)sizeof(aos_errcode)) {
            printError("Unable to write response error code");
            close(cfd);
            FD_CLR(cfd, &read_set);
            open_fds.erase(cfd);
        }
        
        int numBytes;
        switch(cmd) {
            case aos_socket_command::CNTRLREG_READ_RESPONSE:
                numBytes = sizeof(aos_cntrlreg_read_response_packet);
                break;
            case aos_socket_command::FILE_OPEN_RESPONSE:
                numBytes = sizeof(aos_file_open_response_packet);
                break;
            case aos_socket_command::FILE_CLOSE_RESPONSE:
		// block so all data is flushed	out
		numBytes = sizeof(aos_file_open_response_packet);
                break;
            case aos_socket_command::MMAP_RESPONSE:
                numBytes = sizeof(aos_mmap_response_packet);
                break;
            default:
                numBytes = 0;
        }
        if (numBytes == 0) return 0;
        
        if (write(cfd, &aos_pkt, numBytes) < numBytes) {
            printError("Unable to write response data");
            close(cfd);
            FD_CLR(cfd, &read_set);
            open_fds.erase(cfd);
        }
        return 0;
    }

    void listen_loop() {
        int cfd;
        aos_socket_command cmd;

        while (1) {
            startTransaction(cfd);
            if (readCommand(cfd, &cmd)) continue;
            handleTransaction(cfd, cmd);
            //closeTransaction(cfd);
        }
    }

    int handleTransaction(int cfd, aos_socket_command cmd) {
        switch(cmd) {
            case aos_socket_command::CNTRLREG_READ_REQUEST : {
                return handleCntrlReqReadRequest(cfd);
            }
            break;
            case aos_socket_command::CNTRLREG_WRITE_REQUEST : {
                return handleCntrlRegWriteRequest(cfd);
            }
            break;
            case aos_socket_command::FILE_OPEN_REQUEST : {
                return handleFileOpenRequest(cfd);
            }
            break;
            case aos_socket_command::FILE_CLOSE_REQUEST : {
                return handleFileCloseRequest(cfd);
            }
            break;
            /*
            case aos_socket_command::MMAP_REQUEST : {
                return handleMmapRequest(cfd);
            }
            break;
            case aos_socket_command::MUNMAP_REQUEST : {
                return handleMunmapRequest(cfd);
            }
            break;
            case aos_socket_command::MSYNC_REQUEST : {
                return handleMsyncRequest(cfd);
            }
            */
            break;
            case aos_socket_command::SET_MODE_REQUEST : {
                return handleSetModeRequest(cfd);
            }
            break;
            default: {
                perror("Received bad command");
            }
            break;
        }
        return 0;
    }
    
    int handleCntrlReqReadRequest(int cfd) {
        uint64_t slot_id_ = aos_pkt.cntrl_read_req.slot_id;
        uint64_t app_id_ = aos_pkt.cntrl_read_req.app_id;
        uint64_t addr64_ = aos_pkt.cntrl_read_req.addr64;
        uint64_t data64_ = 0;
        aos_errcode errco = aos_errcode::SUCCESS;
        
        if (fpga[slot_id_] == nullptr) {
            fpga[slot_id_] = new aos_fpga(slot_id_);
        }
        
        int success = fpga[slot_id_]->read_app_reg(app_id_, addr64_, data64_);
        if (success != 0) {
            errco = aos_errcode::UNKNOWN_FAILURE;
            perror("Read pci bar failed");
        }
        //printf("(%lu,%lu) read %lu at %lu\n", slot_id_, app_id_, data64_, addr64_);
        
        aos_pkt.cntrl_read_resp.data64 = data64_;
        writeResponse(cfd, errco, aos_socket_command::CNTRLREG_READ_RESPONSE);
        
        return (errco != aos_errcode::SUCCESS);
    }

    int handleCntrlRegWriteRequest(int cfd) {
        uint64_t slot_id_ = aos_pkt.cntrl_write_req.slot_id;
        uint64_t app_id_ = aos_pkt.cntrl_write_req.app_id;
        uint64_t addr64_ = aos_pkt.cntrl_write_req.addr64;
        uint64_t data64_ = aos_pkt.cntrl_write_req.data64;
        aos_errcode errco = aos_errcode::SUCCESS;
        
        if (fpga[slot_id_] == nullptr) {
            fpga[slot_id_] = new aos_fpga(slot_id_);
        }
        
        int success = fpga[slot_id_]->write_app_reg(app_id_, addr64_, data64_);
        if (success != 0) {
            errco = aos_errcode::UNKNOWN_FAILURE;
            perror("Write pci bar failed");
        }
        //printf("(%lu,%lu) wrote %lu at %lu\n", slot_id_, app_id_, data64_, addr64_);
        
        writeResponse(cfd, errco, aos_socket_command::CNTRLREG_WRITE_RESPONSE);
        
        return (errco != aos_errcode::SUCCESS);
    }
    
    int handleFileOpenRequest(int cfd) {
        uint64_t slot_id_ = aos_pkt.file_open_req.slot_id;
        uint64_t app_id_ = aos_pkt.file_open_req.app_id;
        const char* file_path = aos_pkt.file_open_req.file_path;
        aos_errcode errco = aos_errcode::SUCCESS;
        
        if (fpga[slot_id_] == nullptr) {
            fpga[slot_id_] = new aos_fpga(slot_id_);
        }
        
        if (file_io[{slot_id_, app_id_}] == nullptr) {
            file_io[{slot_id_, app_id_}] = new aos_stream(fpga[slot_id_], app_id_);
        }
        
        aos_pkt.file_open_resp.fd = file_io[{slot_id_, app_id_}]->file_open(file_path);
        if (aos_pkt.file_open_resp.fd == -1) {
            errco = aos_errcode::UNKNOWN_FAILURE;
        }
        
        writeResponse(cfd, errco, aos_socket_command::FILE_OPEN_RESPONSE);
        
        return (errco != aos_errcode::SUCCESS);
    }
    
    int handleFileCloseRequest(int cfd) {
        uint64_t slot_id_ = aos_pkt.file_close_req.slot_id;
        uint64_t app_id_ = aos_pkt.file_close_req.app_id;
        int app_fd_ = aos_pkt.file_close_req.fd;
        aos_errcode errco = aos_errcode::SUCCESS;
        
        aos_stream *file_io_ptr = file_io[{slot_id_, app_id_}];
        assert(file_io_ptr != nullptr);
        
        int fd = file_io_ptr->file_close(app_fd_);
        if (fd == -1) {
            errco = aos_errcode::UNKNOWN_FAILURE;
        }
        
        writeResponse(cfd, errco, aos_socket_command::FILE_CLOSE_RESPONSE);
        
        return (errco != aos_errcode::SUCCESS);
    }
    
    /*
    int handleMmapRequest(int cfd) {
        uint64_t slot_id_ = aos_pkt.mmap_req.slot_id;
        uint64_t app_id_ = aos_pkt.mmap_req.app_id;
        void *addr_ = aos_pkt.mmap_req.addr;
        uint64_t length_ = aos_pkt.mmap_req.length;
        int prot_ = aos_pkt.mmap_req.prot;
        int flags_ = aos_pkt.mmap_req.flags;
        int fd_ = aos_pkt.mmap_req.fd;
        uint64_t offset_ = aos_pkt.mmap_req.offset;
        aos_errcode errco = aos_errcode::SUCCESS;
        
        aos_fio *file_io_ptr = file_io[{slot_id_, app_id_}];
        assert(file_io_ptr != nullptr);
        
        if (offset_ % (4<<10)) {
            errco = aos_errcode::ALIGNMENT_FAILURE;
        } else {
            void *addr = file_io_ptr->mmap(addr_, length_, prot_, flags_, fd_, offset_);
            aos_pkt.mmap_resp.addr = addr;
            if (addr == (void*)-1) errco = aos_errcode::UNKNOWN_FAILURE;
        }
        
        writeResponse(cfd, errco, aos_socket_command::MMAP_RESPONSE);
        
        return (errco != aos_errcode::SUCCESS);
    }
    
    int handleMunmapRequest(int cfd) {
        uint64_t slot_id_ = aos_pkt.munmap_req.slot_id;
        uint64_t app_id_ = aos_pkt.munmap_req.app_id;
        void *addr_ = aos_pkt.munmap_req.addr;
        uint64_t length_ = aos_pkt.munmap_req.length;
        aos_errcode errco = aos_errcode::SUCCESS;
        
        aos_fio *file_io_ptr = file_io[{slot_id_, app_id_}];
        assert(file_io_ptr != nullptr);
        
        int rc = file_io_ptr->munmap(addr_, length_);
        if (rc) errco = aos_errcode::UNKNOWN_FAILURE;
        
        writeResponse(cfd, errco, aos_socket_command::MUNMAP_RESPONSE);
        
        return (errco != aos_errcode::SUCCESS);
    }
    
    int handleMsyncRequest(int cfd) {
        uint64_t slot_id_ = aos_pkt.msync_req.slot_id;
        uint64_t app_id_ = aos_pkt.msync_req.app_id;
        void *addr_ = aos_pkt.msync_req.addr;
        uint64_t length_ = aos_pkt.msync_req.length;
        int flags_ = aos_pkt.msync_req.length;
        aos_errcode errco = aos_errcode::SUCCESS;
        
        aos_fio *file_io_ptr = file_io[{slot_id_, app_id_}];
        assert(file_io_ptr != nullptr);
        
        const bool invalidate = flags_ & MS_INVALIDATE;
        int rc = file_io_ptr->msync(addr_, length_, invalidate);
        if (rc) errco = aos_errcode::UNKNOWN_FAILURE;
        
        writeResponse(cfd, errco, aos_socket_command::MSYNC_RESPONSE);
        
        return (errco != aos_errcode::SUCCESS);
    }*/
    
    int handleSetModeRequest(int cfd) {
        uint64_t slot_id_ = aos_pkt.msync_req.slot_id;
        uint64_t app_id_ = aos_pkt.msync_req.app_id;
        uint64_t mode_ = aos_pkt.set_mode_req.mode;
        uint64_t data_ = aos_pkt.set_mode_req.data;
        aos_errcode errco = aos_errcode::SUCCESS;
        
        if (fpga[slot_id_] == nullptr) {
            fpga[slot_id_] = new aos_fpga(slot_id_);
        }
        
        if (file_io[{slot_id_, app_id_}] == nullptr) {
            file_io[{slot_id_, app_id_}] = new aos_stream(fpga[slot_id_], app_id_);
        }
        
        file_io[{slot_id_, app_id_}]->set_mode(mode_, data_);
        
        writeResponse(cfd, errco, aos_socket_command::SET_MODE_RESPONSE);
        
        return (errco != aos_errcode::SUCCESS);
    }
    
    void closeTransaction(int cfd) {        
        if (close(cfd) == -1) {
            perror("Could not close daemon socket");
        }
    }

private:
    // Socket control
    int passive_socket;
    bool socket_initialized;
    std::unordered_set<int> open_fds;
    fd_set read_set;
    int maxFd;
    
    // Structs
    union aos_packet {
        aos_cntrlreg_read_request_packet cntrl_read_req;
        aos_cntrlreg_read_response_packet cntrl_read_resp;
        aos_cntrlreg_write_request_packet cntrl_write_req;
        aos_file_open_request_packet file_open_req;
        aos_file_open_response_packet file_open_resp;
        aos_file_close_request_packet file_close_req;
        aos_mmap_request_packet mmap_req;
        aos_mmap_response_packet mmap_resp;
        aos_munmap_request_packet munmap_req;
        aos_msync_request_packet msync_req;
        aos_set_mode_request_packet set_mode_req;
    } aos_pkt;
    
    // FPGA management
    aos_fpga *fpga[8];
    
    // File / VM management
    std::map<std::pair<uint64_t,uint64_t>, aos_stream*> file_io;
};

#endif  // AOS_DAEMON_
