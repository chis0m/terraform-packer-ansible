 #!/bin/bash
sudo apt update

sudo apt install -y default-jre

sudo apt install -y default-jdk

sudo apt install -y  git mysql-client wget vim telnet htop python3 chrony net-tools

# ssh connection timeout
sudo sh -c "echo 'ClientAliveInterval 50' >> /etc/ssh/sshd_config"
#sudo service sshd restart
