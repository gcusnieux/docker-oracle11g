FROM centos:centos6
MAINTAINER Guillaume CUSNIEUX

RUN ls -al /etc/yum.repos.d/

RUN yum upgrade -y

# convert into Oracle Linux 6
RUN curl -O https://linux.oracle.com/switch/centos2ol.sh
RUN sh centos2ol.sh; echo success

RUN mv /etc/yum.repos.d/libselinux.repo /etc/yum.repos.d/libselinux.repo.disabled

RUN cd /etc/yum.repos.d
RUN curl -O http://public-yum.oracle.com/public-yum-ol6.repo
RUN sed -i 's/enabled=0/enabled=1/' public-yum-ol6.repo

# fix locale error
RUN echo LANG=en_US.utf-8 >> /etc/environment \
 && echo LC_ALL=en_US.utf-8 >> /etc/environment

# install UEK kernel
RUN yum install -y elfutils-libs gcc
RUN yum update -y --enablerepo=ol6_UEKR3_latest
RUN yum install -y kernel-uek-devel --enablerepo=ol6_UEKR3_latest

# add extra packages
RUN yum install -y oracle-rdbms-server-11gR2-preinstall

# create directories
RUN mkdir /opt/oracle /opt/oraInventory /opt/datafile \
 && chown oracle:oinstall -R /opt

RUN su - oracle

# set environment variables
RUN echo "export ORACLE_BASE=/opt/oracle" >> /home/oracle/.bash_profile \
 && echo "export ORACLE_HOME=/opt/oracle/product/11.2.0/dbhome_1" >> /home/oracle/.bash_profile \
 && echo "export ORACLE_SID=orcl" >> /home/oracle/.bash_profile \
 && echo "export PATH=\$PATH:\$ORACLE_HOME/bin" >> /home/oracle/.bash_profile

# Install packages and set up sshd
RUN yum -y install openssh-server
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key && sed -i "s/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config && sed -i "s/UsePAM.*/UsePAM no/g" /etc/ssh/sshd_config

# Add scripts
RUN rpm -i http://dl.fedoraproject.org/pub/epel/6/x86_64/pwgen-2.06-5.el6.x86_64.rpm
ADD set_root_pw.sh /set_root_pw.sh
ADD run.sh /run.sh
RUN chmod +x /*.sh

# confirm
RUN cat /etc/oracle-release

EXPOSE 22
CMD ["/run.sh"]