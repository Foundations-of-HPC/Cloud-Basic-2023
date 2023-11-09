# Virtualization Tutorial

In this tutorial, we will learn how to build a cluster of Linux machines on our local environment using Virtualbox. 
Each machine will have two NICs one internal and one to connect to WAN .
We will connect to them from our host windows machine via SSH.

This configuration is useful to try out a clustered application which requires multiple Linux machines like kubernetes or an HPC cluster on your local environment.
The primary goal will be to test the guest virtual machine performances using standard benckmaks as HPL, STREAM or iozone and compare with the host performances.

Then we will installa a slurm based cluster to test parallel applications

## GOALs
In this tutorial, we are going to create a cluster of four Linux virtual machines.

* Each machine is capable of connecting to the internet and able to connect with each other privately as well as can be reached from the host machine.
* Our machines will be named cluster01, cluster02, ..., cluster0X.
* The first machine: cluster01 will act as a master node and will have 1vCPUs, 2GB of RAM and 25 GB hard disk.
* The other machines will act as worker nodes will have 1vCPUs, 1GB of RAM and 10 GB hard disk.
* We will assign our machines static IP address in the internal network: 192.168.0.1, 192.168.0.22, 192.168.0.23, .... 192.168.0.XX.

## Prerequisite

* VirtualBOX installed in your linux/windows/Apple (UTM in Arm based Mac)
* ubuntu server 22.04 LTS image to install
* SSH client to connect

## Create virtual machines on Virtualbox
We create one template that we will use then to deply the cluster and to make some performance tests and comparisons

Create the template virtual machine which we will name "template" with 1vCPUs, 1GB of RAM and 25 GB hard disk. 

You can use Ubuntu 22.04 LTS server (https://ubuntu.com/download/server)

Make sure to set up the network as follows:

 * Attach the downloaded Ubuntu ISO to the "ISO Image".
 * Type: is Lunux
 * Version Ubuntu 22.04 LTS
When you start the virtual machines for the first time you are prompted to instal and setup Ubuntu. 
Follow through with the installation until you get to the “Network Commections”. As the VM network protocol is NAT,  the virtual machine will be assinged to an automatic IP (internal) and it will be able to access internet for software upgrades. 

The VM is now accessing the network to download the software and updates for the LTS. 

When you are prompted for the "Guided storage configuration" panel keep the default installation method: use an entire disk. 

When you are prompted for the Profile setup, you will be requested to define a server name (template) and super user (e.g. user01) and his administrative password.


Also, enable open ssh server in the software selection prompt.

Follow the installation and then shutdown the VM.

Inspect the VM and in particular the Network, you will  find only one adapter attached to NAT. If you look at the advanced tab you will find the Adapter Type (Intel) and the MAC address.

Start the newly created machine and make sure it is running. 

Login and update the software:

```
$ sudo apt update
...

$ sudo apt upgrade
```


When your VM is all set up, log in to the VM and test the network by pinging any public site. e.g `ping google.com`. If all works well, this should be successful.

You can check the DHCP-assigned IP address by entering the following command:

```shell
hostname -I
```

You will get an output similar to this:
```
10.0.2.15
```

This is the default IP address assigned by your network DHCP. Note that this IP address is dynamic and can change or worst still, get assigned to another machine. But for now, you can connect to this IP from your host machine via SSH.

Now install some useful additional packages:

```
$ sudo apt install net-tools
```

If everything is ok, we can proceed cloning this template. We will create 3 clones (you can create more than 3 
according to the amount of RAM and cores available in your laptop).

You must shutdown the node to clone it, using VirtualBox interface (select VM and right click) create 3 new VMs. 

```
$ sudo shutdown -h now
```


Right click on the name of the VM and clone it. The first clone will be the login/master node the other twos will be computing nodes.

## Configure the cluster

Once the 2 machines has been cloned we can bootstrap the login/master node and configure it.
Add a new network adapter on each machine: enable "Adapter 2" "Attached to" internal network and name it "clustervimnet"

### Login/master node

Bootstrap the VM and configure the secondary network adapter with a static IP. 

In the example below the interface is enp0s8, to find your own one:

```
$ ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 08:00:27:2b:e5:36 brd ff:ff:ff:ff:ff:ff
3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 08:00:27:6e:cf:82 brd ff:ff:ff:ff:ff:ff
```

You are interested to link 2 and 3. Link 2 is the NAT device, Link 3 is the internal network device.
You are interested in Link 3.

Now we configure the adapter. To do this we will edit the netplan file:

```
$ sudo vim /etc/netplan/00-installer-config.yaml

# This is the network config written by 'subiquity'
network:
  ethernets:
    enp0s1:
      dhcp4: true
    enp0s8:
     dhcp4: no
     addresses: [192.168.0.1/24]
  version: 2
```

and apply the configuration

```
$ sudo netplan apply
```
We change the hostname:
```
$ sudo vim /etc/hostname

cluster01
```


Edit the hosts file to assign names to the cluster that should include names for each node as follows:

```
$ sudo vim /etc/hosts

127.0.0.1 localhost
192.168.0.1 cluster01

192.168.0.22 cluster02
192.168.0.23 cluster03
192.168.0.24 cluster04
192.168.0.25 cluster05
192.168.0.26 cluster06
192.168.0.27 cluster07
192.168.0.28 cluster08


# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

```


Then we install a DNSMASQ server to dynamically assign the IP and hostname to the other nodes on the internal interface and create a cluster [1].

```
$ sudo systemctl disable systemd-resolved
Removed /etc/systemd/system/multi-user.target.wants/systemd-resolved.service.
Removed /etc/systemd/system/dbus-org.freedesktop.resolve1.service.
$ sudo systemctl stop systemd-resolved
```
Then 

```
$ ls -lh /etc/resolv.conf
lrwxrwxrwx 1 root root 39 Jul 26 2018 /etc/resolv.conf ../run/systemd/resolve/stub-resolv.conf
$ sudo unlink /etc/resolv.conf
```
Create a new resolv.conf file and add public DNS servers you wish. In my case am going to use google DNS. 

```
$ echo nameserver 8.8.8.8 | sudo tee /etc/resolv.conf
```


Install dnsmasq

```
$ sudo apt install dnsmasq -y
```

To find and configuration file for Dnsmasq, navigate to /etc/dnsmasq.conf. Edit the file by modifying it with your desired configs. Below is minimal configurations for it to run and support minimum operations.

```
$ vim /etc/dnsmasq.conf

port=53
bogus-priv
strict-order
expand-hosts
dhcp-range=192.168.0.22,192.168.0.28,255.255.255.0,12h
dhcp-option=option:dns-server,192.168.0.1
dhcp-option=3

```


When done with editing the file, close it and restart Dnsmasq to apply the changes. 
```
$ sudo systemctl restart dnsmasq
```

Check if it is working

```
$ host cluster01

```

Shutdown  the VM.

### Port forwarding on login/master node
To enable ssh from host to guest VM you need to create a port forwarding rule in VirtualBox. 
To do this open 
```
VM settings -> Network -> Advanced -> Port Forwarding 
```

and create a forwarding rule from host to the VM: 
* Name --> ssh 
* Protocol --> TCP
* HostIP --> 127.0.0.1
* Host Port --> 2222
* Guest Port --> 22

Now you should be able to ssh to your VM. Startup the VM, then

```
ssh -p 2222 yury@127.0.0.1
```

but you will have to enter the password. 
If you want a passwordless access you need to generate a ssh key or use an ssh key if you already have it.

If you don’t have public/private key pair already, run ssh-keygen and agree to all defaults. 
This will create id_rsa (private key) and id_rsa.pub (public key) in ~/.ssh directory.

Copy host public key to your VM:

```
scp -P 2222 ~/.ssh/id_rsa.pub user01@127.0.0.1:~
```

Connect to the VM and add host public key to ~/.ssh/authorized_keys:

```
ssh -p 2222 user01@127.0.0.1
mkdir ~/.ssh
chmod 700 ~/.ssh
cat ~/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys
exit
```

Now you should be able to ssh to the VM without password.

To build a cluster we aldo need a distributed filesystem accessible from all nodes. 
We use NFS.

```
$ sudo apt install nfs-kernel-server
$ sudo mkdir /shared
$ sudo chmod 777 /shared
```

Modify the NFS config file:

```
$ sudo vim /etc/exports

/shared/  192.168.0.0/255.255.255.0(rw,sync,no_root_squash,no_subtree_check)

```
Restart the server

```
$ sudo systemctl enable nfs-kernel-server
$ sudo systemctl restart nfs-kernel-server
```

### Computing nodes
Bootstrap the VM  cluster01 and configure the secondary network adapter with a dynamic IP (this should be standard configuration and nothing should me modified, anyway please check with the "ip link show" command to check the name of the adapters). 

To do this we will edit the netplan file:

```
$ sudo vim /etc/netplan/00-installer-config.yaml

# This is the network config written by 'subiquity'
network:
  ethernets:
    enp0s3:
      dhcp4: true
      dhcp4-overrides:
        use-dns: no
    enp0s8:
     dhcp4: true
  version: 2
```

and apply the configuration

```
$ sudo netplan apply
```
We change the hostname to empty:
```
$ sudo vim /etc/hostname


```

Set the proper dns server (assigned with dhcp):

```
$ sudo rm /etc/resolv.conf
```

then

```
$ sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
```

Reboot the machine.
At reboot you will see that the machine will have a new ip address 

```
$ hostname -I
10.0.2.15 192.168.0.23 
```
Install dnsmasq (trick necessary to install the cluster later)
```
$ sudo apt install dnsmasq -y
$ sudo systemctl disable dnsmasq
```

Now, from the cluster01 you will be able to connect to cluster02 machine with ssh.

```
$ ssh user01@cluster03
user01@cluster02:~$

```
To access the new machine without password you can proceed described above. Run ssh-keygen and agree to all defaults. 
This will create id_rsa (private key) and id_rsa.pub (public key) in ~/.ssh directory.

Copy host public key to your VM:

```
scp  ~/.ssh/id_rsa.pub user01@cluster03:~
```

Connect to the VM and add host public key to ~/.ssh/authorized_keys:

```
ssh user01@cluster03
mkdir ~/.ssh
chmod 700 ~/.ssh
cat ~/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys
exit
```

Configure the shared filesystem

```
$ sudo apt install nfs-common
$ sudo mkdir /shared
```

Mount the shared directory adn test it
```
$ sudo mount 192.168.0.1:/shared  /shared
$ touch /shared/pippo
```
If everything will be ok you will see the "pippo" file in all the nodes.

To authomatically mount at boot edit the /etc/fstab file:

```
$ sudo vim /etc/fstab

```
 
Append the following line at the end of the file

```
192.168.0.1:/shared               /shared      nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
``` 



## Install a SLURM based cluster
Here I will describe a simple configuration of the slurm management tool for launching jobs in a really simplistic Virtual cluster. I will assume the following configuration: a main node (cluster01) and 3 compute nodes (cluster03 ... VMs). I also assume there is ping access between the nodes and some sort of mechanism for you to know the IP of each node at all times (most basic should be a local NAT with static IPs)

Slurm management tool work on a set of nodes, one of which is considered the master node, and has the slurmctld daemon running; all other compute nodes have the slurmd daemon. 

All communications are authenticated via the munge service and all nodes need to share the same authentication key. Slurm by default holds a journal of activities in a directory configured in the slurm.conf file, however a Database management system can be set. All in all what we will try to do is:

 * Install munge in all nodes and configure the same authentication key in each of them
 * Install gcc, openmpi and configure them
 * Configure the slurmctld service in the master node
 * Configure the slurmd service in the compute nodes
 * Create a basic file structure for storing jobs and jobs result that is equal in all the nodes of the cluster
 * Manipulate the state of the nodes, and learn to resume them if they are down
 * Run some simple jobs as test
 * Set up MPI task on the cluster

### Install gcc and OpenMPI

```
$ sudo apt install gcc-12 openmpi-bin openmpi-common
```
Configure gcc-12 as default:
```
$ sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-12 100
```
Test the installation:

```
$ gcc --version 
gcc (Ubuntu 12.3.0-1ubuntu1~22.04) 12.3.0
Copyright (C) 2022 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```
and MPI

```
$ mpicc --version
gcc (Ubuntu 12.3.0-1ubuntu1~22.04) 12.3.0
Copyright (C) 2022 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

### Install MUNGE

Lets start installing munge authentication tool using the system package manager, for cluster01 and cluster03:

```
$ sudo apt-get install -y libmunge-dev libmunge2 munge
```

munge requires that we generate a key file for testing authentication, for this we use the dd utility, with the fast pseudo-random device /dev/urandom. At cluster01 node do:
```
$ sudo dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key
$ chown munge:munge /etc/munge/munge.key
$ chmod 400 /etc/munge/munge.key
```

Copy the key on cluster03 with scp and chech also on cluster03 the file permissions and user.

```
scp /etc/munge/munge.key user01@cluster03:/etc/munge/munge.key
```
Test communication with, locally and remotely with these commands respectively:

```
$ munge -n | unmunge
$ munge -n | ssh cluster03 unmunge
```
### Install Slurm

```
$ sudo apt-get install -y slurmd slurmctld
```

Copy the slurm configuration file of GIT repository to '/etc/slurm' directory of in cluster01 and cluster03

On cluster01

```
$ sudo systemctl enable slurmctld
$ sudo systemctl start slurmctld

$ sudo systemctl enable slurmd
$ sudo systemctl start slurmd
```

On cluster03
```
$ sudo systemctl disable slurmctld
$ sudo systemctl stop slurmctld

$ sudo systemctl enable slurmd
$ sudo systemctl start slurmd
```

Now you can test the envoroment:

```
$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
debug*       up   infinite      1   idle cluster03
debug*       up   infinite      2   unk* cluster[04-05]
```

Test a job:

```
$ srun hostname
cluste03
```

### Clone the node

Shutdown cluster03 and clone it to cluster04 and then start the two VMs.

Afther startup you sould find

```
$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
debug*       up   infinite      2   idle cluster[03-04]
debug*       up   infinite      1   unk* cluster05
```


## Testing VMM enviroment

### Test VM performance
We propose 3 different tests to study VMs performances and VMM capabilities.

* Test the network isolation cloning a new VM from template then change the name of the "Internal Netwok" to "testnetwork", then try to access to the new VM from the cluster
* Using HPCC   compare the host and the guest performance in terms of CPU flops and memory bandwidth
* Using iozone compare host IO performance with guest IO performance

For windows based system it may be necessary to install Linux subsystem.



Install and use hpcc:

```
sudo apt install hpcc
```

HPCC is a suite of benchmarks that measure performance of processor,
memory subsytem, and the interconnect. For details refer to the
HPC~Challenge web site (\url{http://icl.cs.utk.edu/hpcc/}.)

In essence, HPC Challenge consists of a number of tests each
of which measures performance of a different aspect of the system: HPL, STREAM, DGEMM, PTRANS, RandomAccess, FFT.

If you are familiar with the High Performance Linpack (HPL) benchmark
code (see the HPL web site: http://www.netlib.org/benchmark/hpl/}) then you can reuse the input
file that you already have for HPL. 
See http://www.netlib.org/benchmark/hpl/tuning.html for a description of this file and its parameters.
You can use the following sites for finding the appropriate values:

 * Tweak HPL parameters: https://www.advancedclustering.com/act_kb/tune-hpl-dat-file/
 * HPL Calculator: https://hpl-calculator.sourceforge.net/

The main parameters to play with for optimizing the HPL runs are:

 * NB: depends on the CPU architecture, use the recommended blocking sizes (NB in HPL.dat) listed after loading the toolchain/intel module under $EBROOTIMKL/compilers_and_libraries/linux/mkl/benchmarks/mp_linpack/readme.txt, i.e
   * NB=192 for the broadwell processors available on iris
   * NB=384 on the skylake processors available on iris
 * P and Q, knowing that the product P x Q SHOULD typically be equal to the number of MPI processes.
 * Of course N the problem size.

To run the HPCC benchmark, first create the HPL input file and then simply exeute the hpcc command from cli.

Install and use IOZONE:

```
$ sudo apt istall iozone
```

IOzone performs the following 13 types of test. If you are executing iozone test on a database server, you can focus on the 1st 6 tests, as they directly impact the database performance.

* Read – Indicates the performance of reading a file that already exists in the filesystem.
* Write – Indicates the performance of writing a new file to the filesystem.
* Re-read – After reading a file, this indicates the performance of reading a file again.
* Re-write – Indicates the performance of writing to an existing file.
* Random Read – Indicates the performance of reading a file by reading random information from the file. i.e this is not a sequential read.
* Random Write – Indicates the performance of writing to a file in various random locations. i.e this is not a sequential write.
* Backward Read
* Record Re-Write
* Stride Read
* Fread
* Fwrite
* Freread
* Frewrite

IOZONE can be run in parallel over multiple threads, and use different output files size to stress performance.

```
$ ./iozone -a -b output.xls
```

Executes all stests and create an XLS output to simplify the analysis of the results.

Here you will find an introduction to IOZONE with some examples: https://www.cyberciti.biz/tips/linux-filesystem-benchmarking-with-iozone.html



### Test slurm cluster

 * Run a simple MPI program on the cluster
 * Run an interactive job
 * Use the OSU ping pong benchmark to test the VM interconnect.
 
Install OSU MPI benchmarks: download the latest tarball from http://mvapich.cse.ohio-state.edu/benchmarks/.


```
$ tar zxvf osu-micro-benchmarks-7.3.tar.gz

$ cd osu-micro-benchmarks-7.3/

$ sudo apt install make g++-12

$ sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-12 100
$ sudo update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-12 100
$ ./configure CC=/usr/bin/mpicc CXX=/usr/bin/mpicxx --prefix=/shared/OSU/
$ make
$ make install
```

## References

[1] Configure DNSMASQ https://computingforgeeks.com/install-and-configure-dnsmasq-on-ubuntu/?expand_article=1
[2] Configure NFS Mounts https://www.howtoforge.com/how-to-install-nfs-server-and-client-on-ubuntu-22-04/
[3] Configure network with netplan https://linuxconfig.org/netplan-network-configuration-tutorial-for-beginners
[4] SLURM Quick Start Administrator Guide https://slurm.schedmd.com/quickstart_admin.html
[5] Simple SLURM configuration on Debian systems: https://gist.github.com/asmateus/301b0cb86700cbe74c269b27f2ecfbef
[6] HPC Challege https://hpcchallenge.org/hpcc/
[7] IO Zone Benchmarks https://www.iozone.org/
