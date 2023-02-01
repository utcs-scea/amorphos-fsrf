# File System for Reconfigurable Fabrics (FSRF) on AmorphOS (AOS)

## Description

FSRF enables users to map host files into an FPGA virtual memory space.
Mapping and syncrhonization are handled through AOS daemon RPCs.
FPGA virtual memory is accessed via a virtually-addressed AXI4 bus.
This prototype supports AWS F1 instances with 4 AOS Morphlets per FPGA.

## Key Locations

`sw/`: host software

`sw/app/`: application code and scripts

`sw/app/inputs/`: PageRank inputs

`sw/daemon/`: system code

`hw/`: FPGA files

`hw/compile.sh`: main build script

`hw/build/scripts/`: Vivado scripts

`hw/design/cl_aos.sv`: top-level HDL file

`hw/design/UserParams.sv`: design parameterization

`hw/design/aos/`: system HDL

`hw/design/*/`: application HDL

## Getting Started

### Requirements

Users will need access to Amazon AWS EC2 and S3.

### S3 Bucket setup

Create an S3 Bucket for FPGA builds:

- Go to the [AWS S3 website](https://s3.console.aws.amazon.com/s3/buckets).
- Create a Bucket.
 - Use the Bucket name: `cldesigns`
 - Select Region: `us-east-1` or appropriate alternative.
 - Create Bucket.
- Enter the `cldesigns` Bucket.
- Create a Folder with name: `cascade`
- Alternatively, update `hw/compile.sh` lines 71-72 with the appropriate Bucket and Region names.

### Creating an instance

Set up an F1 EC2 instance:

- Go to the [AWS FPGA Developer AMI](https://aws.amazon.com/marketplace/pp/Amazon-Web-Services-FPGA-Developer-AMI/B06VVYBLZZ).
- Continue to Subscribe.
- Continue to Configuration.
- Select Software Version 1.10.3, newer versions may not work properly.
- Select a Region containing F1 instances. We use US East (N. Virginia).
- Continue to Launch.
- Launch through EC2.
- Add a Name and Tags.
- Choose an Instance Type: f1.4xlarge (or f1.2xlarge if the additional RAM is not needed).
- Select or Create New Key Pair.
 - Download Key Pair (if creating a new one). We assume the key is named eval_key(.pem).
 - `mv ~/Downloads/eval_key.pem ~/.ssh/eval_key.pem`
 - `chmod 600 ~/.ssh/eval_key.pem`
- Edit Network Settings
 - Select a Subnet containing F1 instances. We use us-east-1c.
 - Create or Select a Security Group that allows all inbound SSH traffic. This should be fine since you can only authenticate via private key by default.
- Configure your Storage. The default setup splits data across a Root / OS volume and an EBS / project volume.
 - Unless you plan to install a GUI, 75GB should be sufficient for the Root volume.
 - We recommend expanding the project volume to 125GB to store the PageRank input files and FPGA build data.
 - Alternatively, you can delete the second volume and use a single 200GB Root volume for OS and project files.
- Launch Instance.
- Your instance should now be running, and you should be ready to connect to it.

### First-time instance setup

- `ssh -i ~/.ssh/eval_key.pem centos@<IP/DNS>`
- `sudo yum -y update`
- `sudo reboot now`
- SSH back into instance
- `cd /home/centos/src/project_data/`
- `git clone https://github.com/utcs-scea/amorphos-fsrf.git fsrf`
- `cd fsrf`
- Run `first-setup.sh`:
 - Installs AWS python library
 - Clones AWS FPGA repo in expected location
 - Sets up AWS FPGA SDK and HDK
 - Makes FSRF binaries
 - Sets up PageRank input files
 - Enables FPGA DMA
- `aws configure`
 - Enter the Access Key ID and Secret Access Key associated with your account.
 - Default region name: `us-east-1` (or appropriate region if not using N. Virginia).
 - Default output format: `text`
- You should now be able to see this folder from your AWS instance with: `aws s3 ls cldesigns`

## Building FSRF

- Copy entire `hw/` folder to a build directory to isolate generated files
- Set `CONFIG_APPS` in `design/UserParams.sv` according to the table below
- Start a session with `screen` (or equivalent) to protect against SSH disconnects
- `cd` into copy of `hw/`
- Run `compile.sh`
- Build process should be completely automated and store logs in `build/scripts/`

| Benchmark | Config ID |
|-----------|-----------|
| aes       | 1         |
| conv      | 2         |
| dnn       | 3         |
| flow      | 4         |
| gups      | 5         |
| hll       | 6         |
| md5       | 7         |
| nw        | 8         |
| pgrnk     | 9         |
| rng       | 10        |
| sha       | 11        |
| sha hls   | 12        |
| hls tri   | 13        |
| [mixed]   | 14        |

## Running FSRF

### Preparing inputs

Format the NVME SSD and populate it with binary data:

- `cd fsrf/sw/app`
- `./setup_nvme.sh`
- `./setup_main.sh`
- `./setup_hls_pgrnk.sh`
- `./setup_hls_tri.sh`

### Starting the daemon

Start up the daemon to manage the FPGA in the background:

- `cd fsrf/sw/daemon`
- `sudo fpga-load-local-image -S0 -I <agfi>`
- `sudo ./daemon > out.txt`

An FPGA image needs to be loaded prior to starting the daemon so it can attach to the PCIe BARs. If an image is not present, the daemon will crash when it attempt to access them.

Errors and metadata will be logged to a file in this example. The daemon can also be run in a dedicated terminal session to prevent issues with outputs not being flushed.

### Running FPGA applications

Each application can be run individually from its binary or automatically from a script.
Binaries and scripts are located in `sw/app/`.
We recommend starting with the main script.

#### Main script

The main script runs each application script and also handled reconfiguring the FPGA before application script runs.
Like the application scripts, the main script take 5 (optional) arguments to select what conditions applications are run under, with `1` enabling a condition and `0` disabling it.
The first four arguments control whether the script runs the application with FSRF, Coyote emulation, AOS emulation, or in physical access mode.
The final argument selects whether to run with just the standard in-memory input sizes (usually 32MiB and 2GiB per application) or also the "big" oversubscription dataset (usually 32GiB per application).

For each dataset and for each of the modes selected, a set of 4 applications will be run concurrently three times.
The page cache will be flushed to test cold data performance.
Then the applicaion will be rerun to test warm data performance.
Finally, the applications will be run with `MAP_POPULATE` to test hot data performance.
The scripts will then iterate through each of the systems: FSRF with DRAM TLB, FSRF with SRAM TLB, Coyote with 4K paging, Coyote with 2M paging, AOS segmentation (with striping), AOS segments without striping, and physical addressing.

As batches of runs complete, a condensed output will be printed to the console, with one line per run.
The output looks something like this:

`134217728 0.072835 0.0734741 0.0622697 0.0635712 1881.32 1742.11`

The first number, 134217728, indicates the total data accessed accross all applications, in bytes.
The next four numbers, 0.072835 0.0734741 0.0622697 0.0635712, record the individual run time of each application run concurrently.
The last two numbers, 1881.32 1742.11, report throughput in MiB/s based on the average and longest (end-to-end) runtime.

Run data is also logged to files in `sw/apps/logs/<script>_#.log`.
These logs include the results of reconfiguring the FPGA, the commands used to run each binary, and outputs from the binaries, including a superset of the information earlier.
The binaries also report the number of concurrent runs, the workload name, and how the workload was timed (`e2e` uses timers on the host).
Some may also include information such as cycle counts for FPGA-side runtimes (e.g. the `raw` results from RNG).

#### Application scripts

Each benchmark has a corresponding script in `sw/app/script_<bench>.sh`.
The application scripts work similarly to the main script but do not handle FPGA configuration or perform certain safety checks.
They also work differently in that their final argument selects between the standard and oversubscription datasets, with only one being run per script exectution.
Note that the RNG script additionally loops over both read and write mode before swtiching between each dataset.

#### Other scripts

Two other scripts are provided for evaluating a heterogeneous FPGA configuration (`script_multi.sh`) and for testing the impact of access size on performance (`script_access.sh`).

#### Binary execution

Application binaries will perform one run of the workload under specific conditions.
Each application takes command line arguments to control how it executes, but should use defaults for anything not explicitly specified.
The first few arguments are specific to the application, often specifying the input size, file names, read vs. write, and other information.
The final arguments for applications are standardized and consist of:

- The number of simultaneous applications to run (1-4)
- Whether to map data with `MAP_POPULATE` (1 or 0)
- FPGA management system:
 - 0: FSRF with DRAM TLB
 - 1: SRAM TLB
 - 2: physical addressing
 - 4: AOS segmented memory
- Additional system parameters:
 - SRAM TLB:
  - 0: Coyote with 4K paging and striping
  - 1: Coyote with 2M paging and striping
  - 2: FSRF with hybrid paging
 - AOS segments:
  - 0: Memory striping enabled
  - 1: Memory striping disabled
- Custom FSRF (pre)fetch block size
  - Limits how many 4K pages can be moved together
  - Should be a power of 2 from 1 (4KiB) to 512 (2MiB)
  - Usually not set by application scripts

#### Recovering from an error

If an application or the daemon crashes or refuses to run, it can be due a number of issues:

 - The input data could not be found
 - The daemon wasn't running
 - The daemon wasn't running as root
 - The FPGA's PCIe BusMaster access was disabled
 - Something was configured incorrectly, leading to the daemon terminating

To recover from such an issue:

 - Terminate any scripts running commands
 - Terminate the daemon:
  - `sudo killall daemon`
 - Configure the FPGA with a fresh image:
  - `sudo fpga-load-local-image -S0 -I <agfi> -F`
  - This may return: `Error: (19) hardware-busy`
  - In that case, try again and it should work
 - Enable FPGA BusMaster access:
  - f1.2xlarge: `sudo setpci -v -s 0000:00:1d.0 COMMAND=06`
  - f1.4xlarge: `sudo setpci -v -s 0000:00:1b.0 COMMAND=06`
 - Restart the daemon

It is important to perform these operations in the provided order to prevent causing further issues.
