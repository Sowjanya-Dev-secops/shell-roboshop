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
starttime=$(date +%s)
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

cp $script_dir/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "adding rabbitmq repo"

dnf install rabbitmq-server -y &>>$log_file
VALIDATE $? "installing rabbitmq server"

systemctl enable rabbitmq-server &>>$log_file
VALIDATE $? "enabling rabbitmq server"
systemctl start rabbitmq-server &>>$log_file
VALIDATE $? "starting rabbitmq server"

id roboshop &>>$log_file
if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123
    VALIDATE $? " add userrabbitmq server"
else
    echo -e "user already created ...$Y skipp$N"
fi


rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "setting permissions rabbitmq server"

endtime=$(date +%s)
total_time=$(( $endtime - $starttime ))
