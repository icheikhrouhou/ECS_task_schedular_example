FROM ubuntu:14.04

# AWS CLI in case but normally it's installed by default in amazonlinux
RUN apt-get update &&  apt-get -y install apt-utils
RUN apt-get -y install python2.7 python-pip
RUN pip install --upgrade pip
RUN pip install awscli --upgrade --user

#Add an export command to your profile script
ENV PATH "$PATH:/root/.local/bin/aws:/root/.local/bin"

#Install unzip
RUN apt-get -y install unzip

#Get scripts from S3
#RUN aws s3 cp s3://bucket_name/scripts /tmp/ --recursive
#Or
ADD ./files/scripts/ /tmp/

ENTRYPOINT ["sh", "/tmp/batch_script.sh"]

