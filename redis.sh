#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"s

log_folder="/var/log/roboshop-script"

user=$(id -u)
script_name=$( echo $0 | cut -d "." -f1 )
mkdir -p $log_folder
log_file="$log_folder/$script_name.log"
echo "script started excuted at: $(date)"| tee -a $log_file

if [ $user -ne 0 ]; then
    echo -e "$R ERROR::$N proceed with root user"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$R Error:: $N $2  failure" | tee -a $log_file
        exit 1
    else
        echo -e "$G Success:: $N $2 successful" | tee -a $log_file
    fi
}

dnf module disable redis -y &>>$log_file
VALIDATE $? "Disabling default redis"
dnf module enable redis:7 -y &>>$log_file
VALIDATE $? "enabling redis 7"
dnf install redis -y  &>>$log_file
VALIDATE $? "installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e 's/protected-mode yes/protected-mode no/g' /etc/redis/redis.conf &>>$log_file
VALIDATE $? "allowing remote connections to redis"

systemctl enable redis &>>$log_file
VALIDATE $? "Enabling redis"
systemctl start redis &>>$log_file
VALIDATE $? "strt redis"