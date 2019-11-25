#!/bin/bash
echo "updating and installing packages"
sudo yum update -y
sudo yum install curl libaio ncurses numactl tar tzdata unzip -y
echo "updating firewall ports"
sudo firewall-cmd --zone=public --add-port=9191/tcp --permanent
sudo firewall-cmd --zone=public --add-port=8090/tcp --permanent
sudo firewall-cmd --zone=public --add-port=8181/tcp --permanent
sudo firewall-cmd --zone=public --add-port=7001/tcp --permanent
sudo firewall-cmd --zone=public --add-port=7002/tcp --permanent
sudo firewall-cmd --zone=public --add-port=9080/tcp --permanent
sudo firewall-cmd --zone=public --add-port=9081/tcp --permanent
sudo firewall-cmd --zone=public --add-port=9300-9400/tcp --permanent
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --reload
echo "completed firewall ports update"


SELINUX_FILE=/etc/selinux/config
if [ -f $SELINUX_FILE ]; then
	sudo setenforce 0
	sed -i s/SELINUX=.*/SELINUX=disabled/ $SELINUX_FILE
fi

sudo yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io

sudo systemctl start docker
sudo systemctl enable docker

sudo curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo usermod -aG docker $USER

echo "--- host os preparation complete, you can now perform docker-compose (if you aren't root, you will need to logout and back in for group settings to take effect)---"