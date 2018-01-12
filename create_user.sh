#!/bin/bash
# 
# 脚本需要两个参数
#
# 第一个是 用户名， 
# 第二个参数是用户的密码，用户的密码是可选的
#
#set -x

# 检查 mkpasswd  命令是否存在
type mkpasswd &> /dev/null ||  yum -y install expect

# 保证有且仅有只有一个参数
if [ $# -eq 0 ]; then
    echo "必须加上用户名字, 用户第一个必须是字母和数字组成，第一个字符不能是数字,长度不能超过20个字符";
    exit -2;
fi

# U 用户名
U=$1

# P password
P=$2

# 用户必须有数字和字幕组成，第一个必须是字幕
echo $U | grep -E "^[a-zA-Z][a-zA-Z0-9]{1,19}" &> /dev/null
if [ 0 -ne $? ]; then
    echo "用户第一必须是字母，长度不能超过20";
    exit -1;
fi

P='' # 禁止用户自定义密码，随机生成更安全

# 密码 如果创建的时候， 没有指定密码，就生成一个密码
if [ -z "$P" ]; then
    # 密码的长度是 12， 保证至少两个数字，两个小写字母，两个大写字母， 两个特殊符号
    P=`mkpasswd -l 12 -d 2 -c 2 -C 2 -s 2`
fi

# 添加 用户名和密码
echo $U >>  /etc/vsftpd/vftpuser.txt
echo $P >>  /etc/vsftpd/vftpuser.txt 
# 生成数据文件
db_load -T -t hash -f /etc/vsftpd/vftpuser.txt /etc/vsftpd/vftpuser.db

# 生成用户的工作目录
BASEDIR=`cat /etc/passwd  | grep vftpuser | awk -F ":" '{print $(NF-1)}'`

mkdir -p  $BASEDIR/$U/webroot
mkdir -p  $BASEDIR/$U/backup
mkdir -p  $BASEDIR/$U/myfolder

chown -R  vftpuser:vftpuser  $BASEDIR/$U
chmod 500 $BASEDIR/$U

cat >> $BASEDIR/$U/info.txt << EOT
创建的日期是: `date "+%Y-%m-%d %H:%M:%S"`
用户名: $U
密  码: $P
EOT

# 创建信息，虚拟用户不可读
chmod 600 $BASEDIR/$U/info.txt


# 默认的用户权限
cat >> /etc/vsftpd/vsftpd_user_conf/$U <<EOT
#虚拟用户的根目录，需要预先建立并赋予相应权限
local_root=/home/vftpuser/$U

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

## 显示用的创建的信息

IP=`ifconfig | grep inet | grep -v "inet 127" | grep -v "inet 10\." | awk '{ print $2}'`

echo "############# ftp 信息 ################"
echo "IP地址: $IP"
echo "用户名: $U"
echo "密　码: $P"
echo "#######################################"

# 关闭调试
#set +x 
return 0
