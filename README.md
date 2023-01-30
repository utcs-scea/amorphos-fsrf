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
 - `mv Downloads/eval_key.pem ~/.ssh/eval_key.pem`
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

- `ssh -i .ssh/eval_key.pem centos@<IP/DNS>`
- `sudo yum -y update`
- `sudo reboot now`
- `git clone https://github.com/utcs-scea/amorphos-fsrf.git /home/centos/src/project_data/fsrf`
- `cd /home/centos/src/project_data/fsrf`
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

- SSH into F1 instance
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
| tri       | 13        |
| [mixed]   | 14        |
