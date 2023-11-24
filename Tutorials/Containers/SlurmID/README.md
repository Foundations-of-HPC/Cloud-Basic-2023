# Slurm-in-Docker (SlurmID)

A Slurm cluster in a set of Docker containers. Requires Docker, Docker Compose and Bash.

## Quickstart
 
Build

    $ slurmid/build

Run

	$ slurmid/run

List running services

    $ slurmid/ps

Check status

    $ slurmid/ps
    
Execute demo job

    $ slurmid/shell slurmclustermaster
    $ sudo su -l testuser
    $ sinfo  # Check cluster status
    $ sbatch -p partition1 /examples/test_job.sh
    $ squeue  # Check queue status
    $ cat results.txt

Clean

	$ slurmid/clean

## Configuration

Bu default, the `/shared` folder is shared between all services, and the `/home/testuser` folder as well. They are both persistent and stored locally in the data folder in the project's root directory (where this file is located).

## Logs

Check out logs for Docker containers (including entrypoints):


    $ slurmid/logs slurmclustermaster

    $ slurmid/logs slurmclusterworker-one


Check out logs for supervisord services:

    $ slurmid/logs slurmclustermaster slurmctld
    
    $ slurmid/logs slurmclusterworker-one munged
    
    $ slurmid/logs slurmclusterworker-one slurmd

## Building errors

It is common for the build process to fail with a "404 not found" error on an apt-get instructions, as apt repositories often change their IP addresses. In such case, try:

    $ slurmid/build nocache
  