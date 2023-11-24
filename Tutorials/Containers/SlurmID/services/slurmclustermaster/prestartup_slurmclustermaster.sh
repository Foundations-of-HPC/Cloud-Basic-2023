#!/bin/bash
set -e

# Generic slurmid user shared folder
mkdir -p /shared/slurmid && chown slurmid:slurmid /shared/slurmid

# Shared home for testuser to simulate a shared home folders filesystem
cp -a /home_testuser_vanilla /shared/home_testuser

# Create shared data directories
mkdir -p /shared/scratch
chmod 777 /shared/scratch

mkdir -p /shared/data/shared
chmod 777 /shared/data/shared

mkdir -p /shared/data/users/testuser
chown testuser:testuser /shared/data/users/testuser
