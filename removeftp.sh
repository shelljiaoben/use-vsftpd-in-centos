#!/bin/bash 
service vsftpd stop
yum -y  remove vsftpd 

rm /etc/vsftpd -fr
rm /etc/pam.d/vsftpd.* -fr

userdel -f -r vftpuser


#rm /home/vftpuser -fr
