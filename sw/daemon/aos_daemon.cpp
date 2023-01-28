#include "aos_daemon.hpp"

int main(void) {
        //int num_slots = 8;

        /* Our process ID and Session ID */
        pid_t pid, sid;
        
        /* Fork off the parent process */
        pid = fork();
        if (pid < 0) {
            printf("Error - Unable to fork\n");
            exit(EXIT_FAILURE);
        }
        /* If we got a good PID, then
           we can exit the parent process. */
        if (pid > 0) {
            printf("Exiting parent\n");
            printf("Daemon pid is %d\n", pid);
            exit(EXIT_SUCCESS);
        }

        /* Change the file mode mask */
        umask(0);
                
        /* Open any logs here */        
                
        /* Create a new SID for the child process */
        sid = setsid();
        if (sid < 0) {  
            /* Log the failure */
            printf("Error - Unable to setsid\n");
            exit(EXIT_FAILURE);
        }

        /* Change the current working directory */
        if ((chdir("/")) < 0) {
            /* Log the failure */
            printf("Error - Unable to chdir\n");
            exit(EXIT_FAILURE);
        }
        
        /* Close out the standard file descriptors */
        //close(STDIN_FILENO);
        //close(STDOUT_FILENO);
        //close(STDERR_FILENO);

        // Intialize control over the FPGA
        aos_host fpga_handle = aos_host();

        fpga_handle.init_socket();

        // Main loop
        fpga_handle.listen_loop();

        exit(EXIT_SUCCESS);
}
