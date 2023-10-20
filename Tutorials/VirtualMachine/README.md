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
* The first machine: cluster01 will act as a master node and will have 2vCPUs, 2GB of RAM and 10 GB hard disk.
* The other machines will act as worker nodes will have 1vCPUs, 1GB of RAM and 10 GB hard disk.
* We will assign our machines static IP address in the internal network: 10.0.0.1, 10.0.0.2, 10.0.0.3, .... 10.0.0.X.

## Prerequisite

* VirtualBOX installed in your linux/windows/Apple (UTM in Arm based Mac)
* ubuntu server 22.04 LTS image to install
* SSH client to connect

## Create virtual machines on Virtualbox

