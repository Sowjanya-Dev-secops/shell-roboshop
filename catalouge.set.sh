#!/bin/bash

set -euo pipefail
trap 'echo "there is an error in $LINENO , Command is $BASH_COMMAND"' ERR

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"

log_folder="/var/log/roboshop-script"
MONGODB_HOST=mongodb.msdevsecops.fun
SCRIPT_DIR=$PWD

user=$(id -u)
script_name=$( echo $0 | cut -d "." -f1 )
mkdir -p $log_folder
log_file="$log_folder/$script_name.log"

if [ $user -ne 0 ]; then
    echo -e "$R ERROR::$N proceed with root user"
    exit 1
fi


####### NODEJS #####
dnf module disable nodejs -y &>>$log_file


dnf module enable nodejs:20 -y &>>$log_file
echo "Enable nodejs20"

dnf install nodejs -y &>>$log_file
echo "Installing NodeJs"
id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    echo "creating system user"
else
    echo -e "user already created ...$Y skipp$N"
fi
mkdir -p /app 
echo "creating App directotry"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$log_file
echo "downloading catalouge application"
cd /app 
echo "changing  to app directory"

rm -rf /app/*
echo "removing existing code"

unzip /tmp/catalogue.zip &>>$log_file
echo $? "unzip catalouge" 

npm install &>>$log_file
echo $? "Installing dependencies"

cp $SCRIPT_DIR/catalouge.setvice /etc/systemd/system/catalogue.service
echo $? "copy systemctl sevice "

systemctl daemon-reload
systemctl enable catalogue &>>$log_file
echo "enable catalouge"

systemctl start catalogue
echo "start catalouge"

cp $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo
echo "copy mongodb repo"

dnf install mongodb-mongosh -y &>>$log_file
echo "Installing mongodb client"

Index=$(mongosh $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalouge')")

if [ $Index -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$log_file
    echo "load catalouge products"
else 
    echo -e "catalouge products already loaded.. $Y skipp $N"
fi

systemctl restart catalogue
echo "restart catalouge"