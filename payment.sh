#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[37m"

log_folder="/var/log/roboshop-script"

user=$(id -u)
script_name=$( echo $0 | cut -d "." -f1 )
mkdir -p $log_folder
log_file="$log_folder/$script_name.log"
echo "script started excuted at: $(date)"| tee -a $log_file
script_dir=$PWD
mysql_host=mysql.msdevsecops.fun

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

dnf install python3 gcc python3-devel -y &>>$log_file
VALIDATE $? "installing python "

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    VALIDATE $? "creating system user"
else
    echo -e "user already created ...$Y skipp$N"
fi

mkdir -p /app
VALIDATE $? "make directory"
curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$log_file
VALIDATE $? "Downloading the paymentapplication"
cd /app 
VALIDATE $?  "change directory"

rm -rf /app/*
VALIDATE $?  "removing existing code"

unzip /tmp/payment.zip &>>$log_file
VALIDATE $?  "unzip payment"

cd /app 
pip3 install -r requirements.txt &>>$log_file

cp $script_dir/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload &>>$log_file
systemctl enable payment &>>$log_file
VALIDATE $? "enabling payment" 
systemctl start payment &>>$log_file
VALIDATE $? "start payment"

systemctl restart payment &>>$log_file
VALIDATE $? "restart payment"
