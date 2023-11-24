FROM ubuntu:18.04
MAINTAINER Stefano Alberto Russo <stefano.russo@gmail.com>

#----------------------
# Basics
#----------------------

# Set non-interactive
ENV DEBIAN_FRONTEND noninteractive

# Update
RUN apt-get update

# Utilities
RUN apt-get install -y nano telnet unzip wget supervisor openssh-server

# Devel
RUN apt-get install -y build-essential python-dev git-core

# Java
RUN apt-get install -y openjdk-8-jre

# IP utilities (mandatory for DNS!)
RUN apt-get install net-tools iproute2 iputils-ping -y


#------------------------
# SlurmID user
#------------------------

# Add group. We chose GID 65527 to try avoiding conflicts.
RUN groupadd -g 65527 slurmid

# Add user. We chose UID 65527 to try avoiding conflicts.
RUN useradd slurmid -d /slurmid -u 65527 -g 65527 -m -s /bin/bash

# Add slurmid user to sudoers
RUN adduser slurmid sudo

# Keys
RUN mkdir /slurmid/.ssh
COPY keys/authorized_keys /slurmid/.ssh/
COPY keys/id_rsa /slurmid/.ssh/
RUN chmod 0600 /slurmid/.ssh/id_rsa
COPY keys/id_rsa.pub /slurmid/.ssh/
RUN chown -R slurmid:slurmid /slurmid/.ssh

# Install suodo
RUN apt-get install sudo -y

# No pass sudo (for everyone, actually)
COPY sudoers /etc/sudoers

# bash_profile for loading correct env (/env.sh created by entrypoint.sh)
RUN echo "source /env.sh" > /slurmid/.bash_profile
RUN chown slurmid:slurmid /slurmid/.bash_profile

#------------------------
# Data, Logs and opt dirs
#------------------------

# Create dirs
RUN mkdir /data && mkdir /var/log/slurmid 

# Give right permissions
RUN chown -R slurmid:slurmid /data && chown -R slurmid:slurmid /var/log/slurmid


#----------------------
#  Supervisord conf
#----------------------

COPY supervisord.conf /etc/supervisor/


#----------------------
# SSH conf
#----------------------

RUN mkdir /var/run/sshd && chmod 0755 /var/run/sshd
COPY supervisord_sshd.conf /etc/supervisor/conf.d/


#----------------------
# Prestartup scripts
#----------------------

# Create dir for prestartup scripts and copy main script
RUN mkdir /prestartup
COPY prestartup.py /


#----------------------
#  Slurm
#----------------------

# Install Slurm
RUN apt-get -y install slurm-wlm

# Explicitly create /var/run/ dirs
RUN mkdir -p /var/run/munge
RUN mkdir -p /var/run/slurm-wlm

# Add munge key and set permissions
COPY munge.key /etc/munge/munge.key
RUN chown munge:munge /etc/munge/munge.key
RUN chmod 0400 /etc/munge/munge.key

# Add munge daemon supervisord coinf
COPY supervisord_munge.conf /etc/supervisor/conf.d/

# Add Slurm conf
COPY slurm.conf /etc/slurm-llnl/slurm.conf

# TODO: why do we need this?
RUN ln -s /var/lib/slurm-llnl /var/lib/slurm-wlm 
RUN ln -s /var/log/slurm-llnl /var/log/slurm-wlm


#----------------------
#  Test user and
#   prestartup
#----------------------

# Add testuser user
RUN useradd testuser
RUN mkdir -p /home/testuser/.ssh
RUN cat /slurmid/.ssh/id_rsa.pub >> /home/testuser/.ssh/authorized_keys
RUN chown -R testuser:testuser /home/testuser   
RUN usermod -s /bin/bash testuser

# Add prestartup
COPY prestartup_slurmbase.sh /prestartup/
RUN touch -m /prestartup/prestartup_slurmbase.sh


#----------------------
# Entrypoint
#----------------------

# Copy entrypoint
COPY entrypoint.sh /

# Give right permissions
RUN chmod 755 /entrypoint.sh

# Set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

