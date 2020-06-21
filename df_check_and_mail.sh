#!/bin/sh
email="xxxx@xxxx.com"     #收件箱
df -Ph | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5,$1 }' | while read output;
do
  echo $output
  used=$(echo $output | awk '{print $1}' | sed s/%//g)
  partition=$(echo $output | awk '{print $2}')
  if [ $used -ge 90 ]; then            #预警界限，使用的百分比
  echo "$(hostname) 上的分区：\"$partition\" 已使用 $used%  $(date)" | mail -s "磁盘空间警报: $(hostname) 已使用 $used% " $email      #echo后边为正文，mail -s后边为主题
  fi
done