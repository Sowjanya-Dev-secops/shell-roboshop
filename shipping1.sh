#!/bin/bash

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

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$R Error:: $N $2  failure" | tee -a $log_file
        exit 1
    else
        echo -e "$G Success:: $N $2 successful" | tee -a $log_file
    fi
}

dnf install maven -y

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    VALIDATE $? "creating system user"
else
    echo -e "user already created ...$Y skipp$N"
fi
mkdir -p /app 
VALIDATE $? "creating App directotry"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$log_file
VALIDATE $? "downloading catalouge application"
cd /app 
VALIDATE $? "changing  to app directory"

rm -rf /app/*
VALIDATE $? "removing existing code"

unzip /tmp/shipping.zip &>>$log_file
VALIDATE $? "unzip catalouge"  

mvn clean package

mv target/shipping-1.0.jar shipping.jar

cp $SCRIPT_DIR/shipping1.service /etc/systemd/system/shipping.service

systemctl daemon-reload
systemctl enable shipping