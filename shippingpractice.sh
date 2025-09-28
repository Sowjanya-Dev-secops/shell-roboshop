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
script_dir=$PWD

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
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
mkdir /app
cd /app
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip
cd /app
unzip /tmp/shipping.zip
mvn clean package
mv target/shipping-1.0.jar shipping.jar
cp script_dir/shippingpractice.service /etc/systemd/system/shipping.service
systemctl daemon-reload
systemctl enable shipping 
dnf install mysql -y 
mysql -h mysql.msdevsecops.fun -uroot -pRoboShop@1 < /app/db/schema.sql
mysql -h mysql.msdevsecops.fun -uroot -pRoboShop@1 < /app/db/app-user.sql
mysql -h mysql.msdevsecops.fun -uroot -pRoboShop@1 < /app/db/master-data.sql
systemctl restart shipping
