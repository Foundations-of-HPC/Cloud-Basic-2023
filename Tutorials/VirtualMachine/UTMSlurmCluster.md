# UTM based Slurm Cluster  Tutorial

In this tutorial, we will learn how to build a cluster of Linux machines on our local environment using UTM virtualization system. 
Each machine will have only one NIC to connect to WAN and between cluster nodes.
We will connect to them from our host windows machine via SSH.

This configuration is useful to try out a clustered application which requires multiple Linux machines like kubernetes or an HPC cluster on your local environment.
The primary goal will be to test the guest virtual machine performances using standard benckmaks as HPL, STREAM or iozone and compare with the host performances.

Then we will installa a slurm based cluster to test parallel applications

## GOALs
In this tutorial, we are going to create a cluster of four Linux virtual machines.

* Each machine is capable of connecting to the internet and able to connect with each other privately as well as can be reached from the host machine.
* Our machines will be named login, cluster0X, ..., cluster0X.
* The first machine: login will act as a master node and will have 1vCPUs, 2GB of RAM and 25 GB hard disk.
* The other machines will act as worker nodes will have 1vCPUs, 1GB of RAM and 10 GB hard disk.

## Prerequisite

* UTM installed in your Apple machine
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
192.168.64.8
```

This is the default IP address assigned by your network DHCP. Note that this IP address is dynamic and can change or worst still, get assigned to another machine. But for now, you can connect to this IP from your host machine via SSH.

Now install some useful additional packages:

```
$ sudo apt install net-tools
```

Edit the hosts file to assign names to the cluster that should include names for each node as follows:

```
127.0.0.1 localhost
127.0.1.1 localhost

192.168.64.2 cluster02
192.168.64.3 cluster03
192.168.64.4 cluster04
192.168.64.5 cluster05
192.168.64.6 cluster06
192.168.64.7 cluster07
192.168.64.8 cluster08
192.168.64.9 cluster09
192.168.64.10 cluster10
192.168.64.11 cluster11
192.168.64.12 cluster12
192.168.64.13 cluster13
192.168.64.14 cluster14
192.168.64.15 cluster15
192.168.64.16 cluster16
192.168.64.17 cluster17
192.168.64.18 cluster18
192.168.64.19 cluster19
192.168.64.20 cluster20
192.168.64.21 cluster21
192.168.64.22 cluster22
192.168.64.23 cluster23
192.168.64.24 cluster24
192.168.64.25 cluster25
192.168.64.26 cluster26
192.168.64.27 cluster27
192.168.64.28 cluster28
192.168.64.29 cluster29
192.168.64.30 cluster30
192.168.64.31 cluster31
192.168.64.32 cluster32
192.168.64.33 cluster33
192.168.64.34 cluster34
192.168.64.35 cluster35
192.168.64.36 cluster36
192.168.64.37 cluster37
192.168.64.38 cluster38
192.168.64.39 cluster39
192.168.64.40 cluster40
192.168.64.41 cluster41
192.168.64.42 cluster42
192.168.64.43 cluster43
192.168.64.44 cluster44
192.168.64.45 cluster45
192.168.64.46 cluster46
192.168.64.47 cluster47
192.168.64.48 cluster48
192.168.64.49 cluster49
192.168.64.50 cluster50
192.168.64.51 cluster51
192.168.64.52 cluster52
192.168.64.53 cluster53
192.168.64.54 cluster54
192.168.64.55 cluster55
192.168.64.56 cluster56
192.168.64.57 cluster57
192.168.64.58 cluster58
192.168.64.59 cluster59
192.168.64.60 cluster60
192.168.64.61 cluster61
192.168.64.62 cluster62
192.168.64.63 cluster63
192.168.64.64 cluster64
192.168.64.65 cluster65
192.168.64.66 cluster66
192.168.64.67 cluster67
192.168.64.68 cluster68
192.168.64.69 cluster69
192.168.64.70 cluster70
192.168.64.71 cluster71
192.168.64.72 cluster72
192.168.64.73 cluster73
192.168.64.74 cluster74
192.168.64.75 cluster75
192.168.64.76 cluster76
192.168.64.77 cluster77
192.168.64.78 cluster78
192.168.64.79 cluster79
192.168.64.80 cluster80
192.168.64.81 cluster81
192.168.64.82 cluster82
192.168.64.83 cluster83
192.168.64.84 cluster84
192.168.64.85 cluster85
192.168.64.86 cluster86
192.168.64.87 cluster87
192.168.64.88 cluster88
192.168.64.89 cluster89
192.168.64.90 cluster90
192.168.64.91 cluster91
192.168.64.92 cluster92
192.168.64.93 cluster93
192.168.64.94 cluster94
192.168.64.95 cluster95
192.168.64.96 cluster96
192.168.64.97 cluster97
192.168.64.98 cluster98
192.168.64.99 cluster99

# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters

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

Bootstrap the VM.

In the example below the interface is enp0s1, to find your own one:

```
$ ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: enp0s1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 0e:2d:57:48:8b:90 brd ff:ff:ff:ff:ff:ff
```

You are interested to link 2. Link 2 is the NAT device with IP assigned dynamucally by the UTM server.

Now we configure the adapter. 

```
$ hostname -I
192.168.64.8 fdc4:f46c:bb17:931b:c2d:57ff:fe48:8b90
```

Edit the /etc/hosts files to assign the machine with this IP address the name login
```
$vim /etc/hosts

127.0.0.1 localhost
127.0.1.1 localhost

192.168.64.2 cluster02
192.168.64.3 cluster03
192.168.64.4 cluster04
192.168.64.5 cluster05
192.168.64.6 cluster06
192.168.64.7 cluster07
192.168.64.8 login
192.168.64.9 cluster09
192.168.64.10 cluster10
```



We change the hostname:
```
$ sudo vim /etc/hostname

login
```

Shutdown  the VM.

### Accessing the login/master node
UTM allows to access the VM from the host directly. 
A bridged interface is created on the Host at the UTM installation time. For example on the host machine:

```
HOSTMACHINE_NAME ~ % ifconfig
bridge100: flags=8a63<UP,BROADCAST,SMART,RUNNING,ALLMULTI,SIMPLEX,MULTICAST> mtu 1500
    options=3<RXCSUM,TXCSUM>
    ether 6e:7e:67:eb:5b:64
    inet 192.168.64.1 netmask 0xffffff00 broadcast 192.168.64.255
    inet6 fe80::6c7e:67ff:feeb:5b64%bridge100 prefixlen 64 scopeid 0x16
    inet6 fdc4:f46c:bb17:931b:1099:c71:e430:9090 prefixlen 64 autoconf secured
    Configuration:
        id 0:0:0:0:0:0 priority 0 hellotime 0 fwddelay 0
        maxage 0 holdcnt 0 proto stp maxaddr 100 timeout 1200
        root id 0:0:0:0:0:0 priority 0 ifcost 0 port 0
        ipfilter disabled flags 0x0
    member: vmenet0 flags=3<LEARNING,DISCOVER>
            ifmaxaddr 0 port 21 priority 0 path cost 0
    member: vmenet1 flags=3<LEARNING,DISCOVER>
            ifmaxaddr 0 port 26 priority 0 path cost 0
    nd6 options=201<PERFORMNUD,DAD>
    media: autoselect
    status: active
```

To enable ssh from host to guest VM you need to use ssh  from the host machine directly 

```
ssh user01@192.168.64.8
```

but you will have to enter the password. 
If you want a passwordless access you need to generate a ssh key or use an ssh key if you already have it.

If you don’t have public/private key pair already, run ssh-keygen and agree to all defaults. 
This will create id_rsa (private key) and id_rsa.pub (public key) in ~/.ssh directory.

Copy host public key to your VM (adapt the ip address to the ip address of the virtual machine):

```
scp  ~/.ssh/id_rsa.pub user01@192.168.64.8:~
```

Connect to the VM and add host public key to ~/.ssh/authorized_keys:

```
ssh -p  user01@192.168.64.8
mkdir ~/.ssh
chmod 700 ~/.ssh
cat ~/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 644 ~/.ssh/authorized_keys
exit
```

Now you should be able to ssh to the VM without password.


### Login Node services

We install a DNSMASQ server to dynamically assign the IP and hostname to the other nodes on the internal interface and create a cluster [1].

```
$ sudo systemctl disable systemd-resolved
Removed /etc/systemd/system/multi-user.target.wants/systemd-resolved.service.
Removed /etc/systemd/system/dbus-org.freedesktop.resolve1.service.
$ sudo systemctl stop systemd-resolved
```
Then 

```
$ ls -lh /etc/resolv.conf
lrwxrwxrwx 1 root root 39 Jul 26 2018 /etc/resolv.conf ../run/systemd/resolve/resolv.conf
$ sudo unlink /etc/resolv.conf
```
Create a new resolv.conf file and add public DNS servers you wish. In my case am going to use google DNS. 

```
$ sudo  echo nameserver 192.168.64.1 | sudo tee /etc/resolv.conf
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
```


When done with editing the file, close it and restart Dnsmasq to apply the changes. 
```
$ sudo systemctl restart dnsmasq
```

Add localhost as DNS:
```
$ sudo vim etc/resolv.conf
nameserver 192.168.64.1
nameserver 127.0.0.1
```

Check if it is working

```
$ host cluster88

```

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

/shared/  192.168.64.0/255.255.255.0(rw,sync,no_root_squash,no_subtree_check)

```
Restart the server

```
$ sudo systemctl enable nfs-kernel-server
$ sudo systemctl restart nfs-kernel-server
```

### Computing nodes
Clone the template to create a new VM. Edit the VM and assign a new name (e.g. Cluster02). 
Randomize the mac address of the new machine otherwhise it will be the same of the other VM.
```
Network-> MAC Address -> Random
```
Save.

Bootstrap the machine.

We change the hostname to empty:
```
$ sudo vim /etc/hostname


```

Set the proper dns server (assigned with dhcp):

```
$ sudo rm /etc/resolv.conf
```

then point the DNS to the ip address of the login node (in this case 192.168.64.8)

```
$ sudo vim  /etc/resolv.conf
nameserver 192.168.64.8
```

Configure hostname at boot

```
$ sudo vim /etc/rc.local
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.

IPADDR=`hostname -I | awk '{print$1}'`
HOSTNAME=`dig -x $IPADDR +short | sed 's/.$//'`
/bin/hostname $HOSTNAME

exit 0
```
```
$ sudo chmod +x /etc/rc.local
```


Reboot the machine.
At reboot you will see that the machine will have a new ip address 

```
$ hostname -I
192.168.64.12
```
Install dnsmasq (trick necessary to install the cluster later)
```
$ sudo apt install dnsmasq -y
$ sudo systemctl disable dnsmasq
```

Now, from the cluster01 you will be able to connect to cluster02 machine with ssh.

```
$ ssh user01@cluster12
user01@cluster12:~$

```
To access the new machine without password you can proceed described above. Run ssh-keygen and agree to all defaults. 
This will create id_rsa (private key) and id_rsa.pub (public key) in ~/.ssh directory.

Copy host public key to your VM:

```
scp  ~/.ssh/id_rsa.pub user01@cluster03:~
```

Connect to the VM and add host public key to ~/.ssh/authorized_keys:

```
ssh user01@cluster12
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
$ sudo mount 192.168.64.8:/shared  /shared
$ touch /shared/pippo
```
If everything will be ok you will see the "pippo" file in all the nodes.

To authomatically mount at boot edit the /etc/fstab file:

```
$ sudo vim /etc/fstab

```
 
Append the following line at the end of the file

```
192.168.64.8:/shared               /shared      nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0
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

On login

```
$ sudo systemctl enable slurmctld
$ sudo systemctl start slurmctld

$ sudo systemctl enable slurmd
$ sudo systemctl start slurmd
```

On cluster12
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
debug*       up   infinite      1   idle cluster12
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
