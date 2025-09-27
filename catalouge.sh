#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"s

log_folder="/var/log/roboshop-script"
MONGODB_HOST="mongodb.msdevsecops.fun"
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
id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    VALIDATE $? "creating system user"
else
    echo -e "user already created ...$Y skipp$N"
fi
mkdir -p /app 
VALIDATE $? "creating App directotry"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$log_file
VALIDATE $? "downloading catalouge application"
cd /app 
VALIDATE $? "changing  to app directory"
unzip /tmp/catalogue.zip &>>$log_file
VALIDATE $? "unzip catalouge" 
npm install &>>$log_file
VALIDATE $? "Installing dependencies"
cp $SCRIPT_DIR/catalouge.setvice /etc/systemd/system/catalogue.service
VALIDATE $? "copy systemctl sevice "
systemctl daemon-reload
systemctl enable catalogue &>>$log_file
VALIDATE $? "enable catalouge"
systemctl start catalogue
VALIDATE $? "start catalouge"
cp $SCRIPT_DIR/mongodb.repo vim /etc/yum.repos.d/mongo.repo
VALIDATE $? "copy mongodb repo"
dnf install mongodb-mongosh -y &>>$log_file
VALIDATE $? "Installing mongodb client"
mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$log_file
VALIDATE $? "load catalouge products"
systemctl restart catalogue
VALIDATE $? "restart catalouge"
