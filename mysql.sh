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

dnf install mysql-server -y
VALIDATE $? "Installing mysql server"
systemctl enable mysqld
VALIDATE $? "enabling mysql server"
systemctl start mysqld  
VALIDATE $? "start mysql server"
mysql_secure_installation --set-root-pass RoboShop@1
VALIDATE $? "setting up root password "