#!/bin/bash 

# ftp 服务器搭建
# 安装ftp
yum -y install vsftpd

# 创建主用户 vftpuser
FTPUSER=/home/vftpuser

useradd -d $FTPUSER  -s /usr/sbin/nologin vftpuser
chmod 500 $FTPUSER

### 创建测试用户的宿主目录
mkdir -p /home/vftpuser/shelljiaoben/webroot
chmod 500 /home/vftpuser/shelljiaoben
chown -R vftpuser:vftpuser /home/vftpuser

# 禁止匿名用户登陆，匿名用户的用户名  anonymous 
# 修改配置文件

sed -i  '/^anonymous_enable/s/YES/NO/' /etc/vsftpd/vsftpd.conf
sed -i  '/^write_enable/s/YES/NO/' /etc/vsftpd/vsftpd.conf
sed -i '/^#chroot_local_user/achroot_local_user=YES'  /etc/vsftpd/vsftpd.conf
sed -i '/^#chroot_list_enable/achroot_list_enable=NO'  /etc/vsftpd/vsftpd.conf
sed -i '/chroot_list_file/s/#//'  /etc/vsftpd/vsftpd.conf
sed -i '/pam_service_name/d' /etc/vsftpd/vsftpd.conf
sed -i '/userlist_enable/d' /etc/vsftpd/vsftpd.conf
sed -i '$auserlist_enable=NO' /etc/vsftpd/vsftpd.conf
sed -i '$a#userlist_deny=NO' /etc/vsftpd/vsftpd.conf
sed -i '$auser_config_dir=/etc/vsftpd/vsftpd_user_conf' /etc/vsftpd/vsftpd.conf
sed -i '$a# 启用虚拟用户' /etc/vsftpd/vsftpd.conf
sed -i '$aguest_enable=YES' /etc/vsftpd/vsftpd.conf
sed -i '$apam_service_name=vsftpd' /etc/vsftpd/vsftpd.conf
sed -i '$aguest_username=vftpuser' /etc/vsftpd/vsftpd.conf
sed -i '$a# 虚拟用的和宿主用户有同样的权限' /etc/vsftpd/vsftpd.conf
sed -i '$avirtual_use_local_privs=YES' /etc/vsftpd/vsftpd.conf
sed -i '$a# -doc begin -' /etc/vsftpd/vsftpd.conf
sed -i '$a# 当userlist_enable = NO, ftpusers 文件中的用户禁止访问 ftp 服务器' /etc/vsftpd/vsftpd.conf
sed -i '$a# 当userlist_enable = YES , userlist_deny = NO, 仅仅允许  user_list中的用户访问' /etc/vsftpd/vsftpd.conf
sed -i '$a# 当userlist_enable = YES, userlist_deny = YES , ftpuser, user_list 都不能访问ftp 服务器' /etc/vsftpd/vsftpd.conf
sed -i '$a# chroot_local_user = YES && chroot_local_user = YES 出去文件chroot_list 都限制' /etc/vsftpd/vsftpd.conf
sed -i '$a# chroot_local_user = YES && chroot_local_user = NO  全部被限制' /etc/vsftpd/vsftpd.conf
sed -i '$a# chroot_local_user = NO && chroot_local_user = YES  仅仅限制 chroot_list' /etc/vsftpd/vsftpd.conf
sed -i '$a# chroot_local_user = NO && chroot_local_user = NO   全部不限制' /etc/vsftpd/vsftpd.conf
sed -i '$a# -- doc  end --' /etc/vsftpd/vsftpd.conf

# 创建虚拟用户文本文件
cat >> /etc/vsftpd/vftpuser.txt <<EOT
shelljiaoben
123456
EOT


# 生成数据库文件
db_load -T -t hash -f /etc/vsftpd/vftpuser.txt /etc/vsftpd/vftpuser.db

# 修改pam配置文件

mv /etc/pam.d/vsftpd /etc/pam.d/vsftpd.bak.`date "+%Y-%m-%d"`

cat >> /etc/pam.d/vsftpd <<EOT
#auth required /usr/lib64/security/pam_userdb.so db=/etc/vsftpd/vftpuser
#account required /usr/lib64/security/pam_userdb.so db=/etc/vsftpd/vftpuser

auth required pam_userdb.so db=/etc/vsftpd/vftpuser
account required pam_userdb.so db=/etc/vsftpd/vftpuser
EOT


# 填写虚拟用户的权限

mkdir -p /etc/vsftpd/vsftpd_user_conf

cat >> /etc/vsftpd/vsftpd_user_conf/shelljiaoben <<EOT
#虚拟用户的根目录，需要预先建立并赋予相应权限
local_root=/home/vftpuser/shelljiaoben

#开放虚拟用户的写权限
write_enable=YES

#开放虚拟用户的下载权限
anon_world_readable_only=YES

#开放虚拟用户的上传权限
anon_upload_enable=YES

#开放虚拟用户创建目录的权限
anon_mkdir_write_enable=YES

#禁止虚拟用户删除、重命名目录和文件
anon_other_write_enable=NO
EOT

service vsftpd start
