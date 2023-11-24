#!/bin/bash
set -e

# "Deactivate" local testuser home
mv /home/testuser /home_testuser_vanilla

# Link testuser against the home in the shared folder (which will be setup by the master node)
ln -s /shared/home_testuser /home/testuser
