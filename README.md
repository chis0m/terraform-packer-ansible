### Script to Generate a self signed certificate
```bash
# Generates Certificate Authority (CA) private key and Certificate files
openssl req -x509 -newkey rsa:4096 -days 365 -nodes -keyout ca-key.pem -out ca-cert.pem \
 -subj "/C=NG/ST=Lagos/L=Lagos/O=acellware/OU=devops/CN=*.chisomejim.link/emailAddress=ejimchisom@gmail.com"
 
 # Generates the webservers private key and Certificate Signing Request (CSR)
 openssl req -newkey rsa:4096 -nodes -keyout server-key.pem -out server-req.pem -subj \
"/C=NG/ST=Lagos/L=Lagos/O=acellware/OU=devops/CN=*.chisomejim.click/emailAddress=devops.chisom@gmail.com"

# Use CA's private key and cert to sign the webservers CSR
 openssl x509 -req -in server-req.pem -days 365 -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem
```

#### To verify the webserver certificate
```bash
openssl verify -CAfile ca-cert.pem server-cert.pem
```

### Finding AMIs
Redhat: `https://access.redhat.com/solutions/15356#us_east_1_rhel8`
Ubuntu: `http://cloud-images.ubuntu.com/locator/ec2/`

#### Process fo Implementation
1. Use Packer to build the AMI images and replace in your terraform vars
2. Comment-out the `ALB Listeners`, `ASG attachments to Target groups` for Proxy and Web Servers
    - Why this is done is so that when configuring the instances with ansible, the ASG will not terminate these instances because of health check failure. Since nginx has not been configured on these servers
3. ssh (ForwardAgent yes) into the bastion host and clone the ansible repository. Run `sudo yum update`.
   - You might also have to upgrade python and boto3. Run `sudo yum install python3.8` and `sudo pip3.8 install boto3`
4. Run AWS configure `aws configure` and add the keys
    - check if ansible can connect by running `ansible-inventory -i inventory/aws_ec2.yml --graph`
5. Updating Credentials in Ansible
    - update the internal ALB for the proxy server proxies to. Goto `roles -> nginx -> templates -> nginx.conf.j2`. Update `proxy_pass`
    - Goto `roles -> tooling -> tasks -> main.yml` and update the `mount -> opts,  mount -> src`. update the strings `fsap-xxxxxxxxxxxxx` and `fs-xxxxxxxxxxxxxx` respectively
        - To get this `fsap-xx` and `fs-xx` string, go to `AWS EFS -> Access Points` and click on the `Access Point ID` for tooling, then click on `Attach`. Copy the values from the popup window
    - Goto `roles -> tooling -> tasks -> setup-db.yml` and update the database credentials `login_host`, `login_user`, `login_password`. Also update the tooling app credentials accordingly
    - Goto `roles -> tooling -> tasks -> setup-site.yml` and update as necessary
    - Do the same for wordpress at `roles -> wordpress -> tasks` and `roles -> tooling -> tasks -> main.yml`
    - Update the role_path in `ansible.cfg` by getting the absolute path to `roles` directory  and also run `export ANSIBLE_CONFIG=/path/to/ansible.cfg` to tell the server where ansible config is.
    - Run the ansible `ansible-playbook -i inventory/aws_ec2.yml playbooks/site.yml`. This uses concept of `DYNAMIC INVENTORY` to perform the expected actions by filtering with instances tags and states. 
    
6. Check the status of the installation
    - with ssh agent, access the bastion. `ssh -A user@public-ip`
    - ssh into proxy server and cat `/etc/nginx/nginx.conf` to confirm the `proxy_pass` value
    - ssh into tooling and woodpress server and run `df -h` to confirm efs mounting, run `curl localhost` to confirm the website
    - check as many files as possible to confirm everything is working

7. Goto the terraform, uncomment the commented out target groups attachments and listeners and push



### Errors
Ansible
`fatal: [10.0.3.27]: FAILED! => {"changed": false, "msg": "Unable to start service nginx: Job for nginx.service failed because the control process exited with error code.\nSee \"systemctl status nginx.service\" and \"journalctl -xe\" for details.\n"}`

ProxyServer
