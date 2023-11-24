FROM slurmid/slurmcluster
MAINTAINER Stefano Alberto Russo <stefano.russo@gmail.com>

# Configure supervisord to run SLURM
COPY supervisord_slurm* /etc/supervisor/conf.d/

# Add sample job script
RUN mkdir /examples
COPY test_job.sh /examples/test_job.sh

# Add prestartup
COPY prestartup_slurmclustermaster.sh /prestartup/
RUN touch -m /prestartup/prestartup_slurmclustermaster.sh
