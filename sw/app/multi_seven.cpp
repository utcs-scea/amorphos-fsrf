#include <pthread.h>
#include <atomic>
#include <chrono>
#include <thread>
#include <numeric>
#include "aos.hpp"
#include "utils.hpp"

using namespace std::chrono;

// hetero pipeline code
// apps: aes, md5, conv, dnn ; hll, sha, aes

struct aes_config {
    uint64_t key[4];
    uint64_t out_words;
    uint64_t in_words;
    uint64_t out_cyc;
    uint64_t in_cyc;
    uint64_t out_rnv;
    uint64_t in_rnv;
    uint64_t out_vnr;
    uint64_t in_nr;	
} aes_config;

struct md5_config {
    uint32_t md5[4];
    uint64_t md5_words;
    uint64_t reserved;
    uint64_t out_words;
    uint64_t in_words;
    uint64_t out_cyc;
    uint64_t in_cyc;
    uint64_t out_rnv;
    uint64_t in_rnv;
    uint64_t out_vnr;
    uint64_t in_vnr;
} md5_config;

struct conv_config {
    uint32_t dest;
    uint32_t batch_size;
} conv_config;

struct dnn_config {
    uint64_t dest;
    uint64_t nimages;
} dnn_config;

struct hll_config {
    float f;
    uint64_t dest;
    uint64_t N;
} hll_config;

struct sha_config {
    uint32_t abcdefgh[8];
    uint64_t num_words;
} sha_config;

// config configs[32];
aos_client *aos[32];

struct thread_config {
    uint64_t app;
    uint64_t length;
    uint64_t send_size;

    bool read;
    bool write;
};

void host_thread(thread_config tc) {
    const uint64_t words = uint64_t{1} << tc.length;
    
    const int num_threads = sysconf(_SC_NPROCESSORS_ONLN);
    cpu_set_t cpu_set;
    pthread_getaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpu_set);
    CPU_CLR(0, &cpu_set);
    CPU_CLR(num_threads, &cpu_set);
    pthread_setaffinity_np(pthread_self(), sizeof(cpu_set_t), &cpu_set);
    
    uint64_t read_left = tc.read ? (words * 64) : 0;
    uint64_t write_left = tc.write ? (words * 64) : 0;
    uint64_t write_bytes = tc.send_size * 64;
    uint64_t bytes;
    bool end;
    while (read_left || write_left) {
        if (read_left) {
            void *read_buf;
            end = true;
            aos[tc.app]->aos_stream_read(read_buf, bytes, end);
            (void)read_buf;
            read_left -= bytes;
            aos[tc.app]->aos_stream_free(bytes);
        }
        if (write_left) {
            void *write_buf;
            bytes = std::min(write_bytes, write_left);
            aos[tc.app]->aos_stream_alloc(write_buf, bytes);
            (void)write_buf;
            end = bytes == write_left;
            aos[tc.app]->aos_stream_write(bytes, end);
            write_left -= bytes;
        }
    }
}

int main(int argc, char *argv[]) {
    int argi = 1;
    utils util;

    enum cfg_arch_t {C_LOOP = 0, C_PIPE};

    cfg_arch_t cfg_arch = C_PIPE;
    if (argi < argc) cfg_arch = (cfg_arch_t)atol(argv[argi]);
    assert(cfg_arch <= 1);
    ++argi;
    
    uint64_t num_apps = 7;
    if (argi < argc) num_apps = atol(argv[argi]);
    assert((num_apps >= 1) && (num_apps <= 32));
    ++argi;
    
    uint64_t length = 25;
    if (argi < argc) length = atol(argv[argi]);
    assert(length <= 34);
    ++argi;
    
    uint64_t send_size = 2048;
    if (argi < argc) send_size = atol(argv[argi]);
    ++argi;

    printf("Parameters are: cfg_arch = %d, num_apps = %lu, length = %lu, send_size = %lu\n", cfg_arch, num_apps, length, send_size);

    // configuration
    uint64_t srcs[32];
    uint64_t dests[32];
    bool host_rd[32];
    bool host_wr[32];
    int sd[32];
    
    util.num_apps = num_apps;
    util.setup_aos_client(aos);
    
    for (uint64_t app = 0; app < num_apps; ++app) {
        aos[app]->aos_stream_open(true, true, sd[app]);
    }

    for (uint64_t app = 0; app < num_apps; ++app) {
        if (cfg_arch == C_LOOP) {
            srcs[app] = sd[app];
            dests[app] = sd[app];
            host_rd[app] = true;
            host_wr[app] = true;
        } else if (cfg_arch == C_PIPE) {
            srcs[app] = (app == 0) ? sd[app] : app - 1;
            dests[app] = (app == (num_apps - 1)) ? sd[app] : app + 1;
            host_rd[app] = app == (num_apps - 1);
            host_wr[app] = app == 0;
        }
    }

    high_resolution_clock::time_point start, end[32];
    std::thread threads[32];
    
    // start runs
    start = high_resolution_clock::now();
    for (uint64_t app = 0; app < num_apps; ++app) {
        if (app == 0)
        { // aes config
            const uint64_t addr0 = 0x100 + 0x8 * srcs[app];
            aos[app]->aos_cntrlreg_write(addr0, dests[app]);
            aos[app]->aos_cntrlreg_write(0x20, uint64_t{1}<<length);
            printf("aes config: addr0 = %lu, dests = %lu, length = %lu\n", addr0, dests[app], uint64_t{1}<<length);
        }
        else if (app == 1)
        { // md5 config
            const uint64_t addr1 = 0x100 + 0x8 * srcs[app];
            aos[app]->aos_cntrlreg_write(addr1, dests[app]);
            aos[app]->aos_cntrlreg_write(0x30, 0x1);
            aos[app]->aos_cntrlreg_write(0x20, uint64_t{1}<<length);
            printf("md5 config: addr1 = %lu, dests = %lu, length = %lu\n", addr1, dests[app], uint64_t{1}<<length);
        }
        else if (app == 2)
        { // conv config
            aos[app]->aos_cntrlreg_write(0x30, uint64_t{1}<<(length-8)); // batch size
            aos[app]->aos_cntrlreg_write(0x20, dests[app]);
            aos[app]->aos_cntrlreg_write(0x00, 0x1);
            printf("conv config: dests = %lu, length = %lu\n", dests[app], uint64_t{1}<<(length-8));
        }
        else if (app == 3)
        { // dnn config
            aos[app]->aos_cntrlreg_write(0x20, uint64_t{1}<<(length-8));
            aos[app]->aos_cntrlreg_write(0x30, dests[app]);
            aos[app]->aos_cntrlreg_write(0x00, 0x1);
            printf("dnn config: dests = %lu, length = %lu\n", dests[app], uint64_t{1}<<(length-8));
        }
        else if (app == 4)
        { // hll config
            aos[app]->aos_cntrlreg_write(0x40, uint64_t{1}<<length);
            aos[app]->aos_cntrlreg_write(0x30, dests[app]);
            aos[app]->aos_cntrlreg_write(0x00, 0x1);
            printf("hll config: dests = %lu, length = %lu\n", dests[app], uint64_t{1}<<length);
        }
        else if (app == 5)
        { // sha config
            aos[app]->aos_cntrlreg_write(0x48, uint64_t{1}<<length);
		    aos[app]->aos_cntrlreg_write(0x58, dests[app]);
		    aos[app]->aos_cntrlreg_write(0x00, 0x1);
            printf("sha config: dests = %lu, length = %lu\n", dests[app], uint64_t{1}<<length);
        }
        else
        { // if app == 6 // aes config
            const uint64_t addr2 = 0x100 + 0x8 * srcs[app];
            aos[app]->aos_cntrlreg_write(addr2, dests[app]);
            aos[app]->aos_cntrlreg_write(0x20, uint64_t{1}<<length);
            printf("aes config: addr2 = %lu, dests = %lu, length = %lu\n", addr2, dests[app], uint64_t{1}<<length);
        }
        
        if (host_rd[app] || host_wr[app]) {
            thread_config tc;
            tc.app = app;
            tc.length = length;
            tc.send_size = send_size;
            tc.read = host_rd[app];
            tc.write = host_wr[app];
            printf("Starting thread %lu\n", app);
            threads[app] = std::thread(host_thread, tc);
        }
    }

    // join threads
    for (uint64_t app = 0; app < num_apps; ++app) {
        if (host_rd[app] || host_wr[app]) threads[app].join();
        printf("Joined thread %lu\n", app);
    }

    // end runs
    uint64_t reg_mask = 0xFFFFFFFFFFFFFFFF;
    uint64_t done_val = 0;
    uint64_t done_count = 0;
    bool done;
    uint64_t val;

    // 1. end aes runs
    // aes:  util.finish_runs(aos, end, 0x20, true, 0);
    done = false;
    val = 0;
    aos[0]->aos_cntrlreg_read(0x20, val);
    val &= reg_mask;
    printf("AES: val = %lu, done_val = %lu, reg_mask = %lu, done_count = %lu\n", val, done_val, reg_mask, done_count);
    while (done_count < 1) {
        if (val == done_val) {
            done = true;
            ++done_count;
            end[0] = high_resolution_clock::now();
        } else {
            aos[0]->aos_cntrlreg_read(0x20, val);
            val &= reg_mask;
        }
    }
    printf("AES done %d\n", done);

    // 2. end md5 runs
    // md5:  util.finish_runs(aos, end, 0x20, true, 0);
    done = false;
    val = 0;
    aos[1]->aos_cntrlreg_read(0x20, val);
    val &= reg_mask;
    printf("MD5: val = %lu, done_val = %lu, reg_mask = %lu, done_count = %lu\n", val, done_val, reg_mask, done_count);
    while (done_count < 2) {
        if (val == done_val) {
            done = true;
            ++done_count;
            end[1] = high_resolution_clock::now();
        } else {
            aos[1]->aos_cntrlreg_read(0x20, val);
            val &= reg_mask;
        }
    }
    printf("MD5 done %d\n", done);

    // 3. end conv runs
    // conv: util.finish_runs(aos, end, 0x00, true, 0x2, 0x2);
    done = false;
    val = 0;
    reg_mask = 0x2;
    done_val = 0x2;
    aos[2]->aos_cntrlreg_read(0x00, val);
    val &= reg_mask;
    printf("CONV: val = %lu, done_val = %lu, reg_mask = %lu, done_count = %lu\n", val, done_val, reg_mask, done_count);
    while (done_count < 3) {
        if (val == done_val) {
            done = true;
            ++done_count;
            end[2] = high_resolution_clock::now();
        } else {
            aos[2]->aos_cntrlreg_read(0x00, val);
            val &= reg_mask;
        }
    }
    aos[2]->aos_cntrlreg_write(0x00, 0x10);
    printf("Conv done %d\n", done);

    // 4. end dnn runs 
    // dnn: util.finish_runs(aos, end, 0x00, true, 0x2, 0x2);
    done = false;
    val = 0;
    aos[3]->aos_cntrlreg_read(0x00, val);
    val &= reg_mask;
    printf("DNN: val = %lu, done_val = %lu, reg_mask = %lu, done_count = %lu\n", val, done_val, reg_mask, done_count);
    while (done_count < 4) {
        if (val == done_val) {
            done = true;
            ++done_count;
            end[3] = high_resolution_clock::now();
        } else {
            aos[3]->aos_cntrlreg_read(0x00, val);
            val &= reg_mask;
        }
    }
    aos[3]->aos_cntrlreg_write(0x00, 0x10);
    printf("DNN done %d\n", done);

    // 5. end hll runs
    // hll:  util.finish_runs(aos, end, 0x00, true, 0x2, 0x2);
    done = false;
    val = 0;
    aos[4]->aos_cntrlreg_read(0x00, val);
    val &= reg_mask;
    printf("HLL: val = %lu, done_val = %lu, reg_mask = %lu, done_count = %lu\n", val, done_val, reg_mask, done_count);
    while (done_count < 5) {
        if (val == done_val) {
            done = true;
            ++done_count;
            end[4] = high_resolution_clock::now();
        } else {
            aos[4]->aos_cntrlreg_read(0x00, val);
            val &= reg_mask;
        }
    }
    aos[4]->aos_cntrlreg_write(0x00, 0x10);
    printf("HLL done %d\n", done);

    // 6. end sha runs
    // sha:  util.finish_runs(aos, end, 0x00, true, 0x2, 0x2);
    aos[5]->aos_cntrlreg_write(0x00, 0x10);

    done = false;
    val = 0;
    aos[5]->aos_cntrlreg_read(0x00, val);
    val &= reg_mask;
    printf("SHA: val = %lu, done_val = %lu, reg_mask = %lu, done_count = %lu\n", val, done_val, reg_mask, done_count);
    while (done_count < 6) {
        if (val == done_val) {
            done = true;
            ++done_count;
            end[5] = high_resolution_clock::now();
        } else {
            aos[5]->aos_cntrlreg_read(0x00, val);
            val &= reg_mask;
        }
    }
    // aos[5]->aos_cntrlreg_write(0x00, 0x10);
    printf("SHA done %d\n", done);

    // 7. end aes runs
    // aes:  util.finish_runs(aos, end, 0x20, true, 0);
    done = false;
    val = 0;
    reg_mask = 0xFFFFFFFFFFFFFFFF;
    done_val = 0;
    aos[6]->aos_cntrlreg_read(0x20, val);
    val &= reg_mask;
    printf("AES: val = %lu, done_val = %lu, reg_mask = %lu, done_count = %lu\n", val, done_val, reg_mask, done_count);
    while (done_count < 7) {
        if (val == done_val) {
            done = true;
            ++done_count;
            end[6] = high_resolution_clock::now();
        } else {
            aos[6]->aos_cntrlreg_read(0x20, val);
            val &= reg_mask;
        }
    }
    printf("AES done %d\n", done);

    // print stats
    const uint64_t accl_bytes = (uint64_t{64} << length);
    const uint64_t total_accl_bytes = num_apps * accl_bytes;
    const uint64_t host_bytes = (cfg_arch == C_LOOP) ? total_accl_bytes : accl_bytes;
    const uint64_t total_bytes = total_accl_bytes + host_bytes;
    const uint64_t app_bytes = total_bytes / num_apps;
    util.print_stats("multi_7pipeline", app_bytes, start, end);
    
    // clean up
    for (uint64_t app = 0; app < num_apps; ++app) {
        aos[app]->aos_stream_close(sd[app]);
    }

    return 0;
}