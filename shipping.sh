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

dnf install maven -y &>>$log_file

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$log_file
    VALIDATE $? "creating system user"
else
    echo -e "user already created ...$Y skipp$N"
fi

mkdir -p /app
VALIDATE $? "make directory"
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$log_file
VALIDATE $? "Downloading the shippingapplication"
cd /app 
VALIDATE $?  "change directory"

rm -rf /app/*
VALIDATE $?  "removing existing code"

unzip /tmp/shipping.zip &>>$log_file
VALIDATE $?  "unzip shipping"

cd /app 
mvn clean package &>>$log_file
mv target/shipping-1.0.jar shipping.jar &>>$log_file

cp $script_dir/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$log_file

systemctl enable shipping &>>$log_file
VALIDATE $? "enabling shipping" 
systemctl start shipping &>>$log_file
VALIDATE $? "start shipping"

dnf install mysql -y &>>$log_file
VALIDATE $? "Installing mysql"
mysql -h mysql.msdevsecops.fun -uroot -pRoboShop@1 -e 'use cities' &>>$log_file
if [ $? -ne 0 ]; then
    mysql -h mysql.msdevsecops.fu -uroot -pRoboShop@1 < /app/db/schema.sql &>>$log_file
    mysql -h mysql.msdevsecops.fu -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$log_file
    mysql -h mysql.msdevsecops.fu -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$log_file
else
    echo "shipping data is already loaded.. $Y Skipp$N"

fi
systemctl restart shipping &>>$log_file
VALIDATE $? "restart shipping"
