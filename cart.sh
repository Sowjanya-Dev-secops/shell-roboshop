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
####### NODEJS #####
dnf module disable nodejs -y &>>$log_file
VALIDATE $? "Disable nodejs"

dnf module enable nodejs:20 -y &>>$log_file
VALIDATE $? "Enable nodejs20"

dnf install nodejs -y &>>$log_file
VALIDATE $? "Installing NodeJs"
id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    VALIDATE $? "creating system user"
else
    echo -e "user already created ...$Y skipp$N"
fi
mkdir -p /app 
VALIDATE $? "creating App directotry"
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$log_file
VALIDATE $? "downloading cart application"
cd /app 
VALIDATE $? "changing  to app directory"

rm -rf /app/*
VALIDATE $? "removing existing code"

unzip /tmp/cart.zip &>>$log_file
VALIDATE $? "unzip cart" 

npm install &>>$log_file
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "copy systemctl sevice "

systemctl daemon-reload
systemctl enable cart &>>$log_file
VALIDATE $? "enable cart"

systemctl start cart
VALIDATE $? "start cart"

systemctl restart cart
VALIDATE $? "restart cart"
