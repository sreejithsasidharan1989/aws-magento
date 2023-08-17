#!/bin/bash

##check if Terraform and Ansible are installed
function __verify() {

        if ! command -v $command &> /dev/null
        then
                return 0
        fi
        }

function __aws_cli() {

	echo "============= Install & Configure AWS-CLI ==============="
        echo ""
        echo ""
        echo ""
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" -s
        unzip -qq awscliv2.zip
	sudo ./aws/install

	if __verify "aws-cli"
	then
		aws configure
		echo "============= AWS CLI Installation Complete! =============="
	fi
}
function __ansible_vault() {
	touch aws_creds.yml
	echo "---" >> aws_creds.yml
	echo "Enter your AWS Access Key & Secret Key when prompted"
	sleep 2
	read -rs -p "Enter your AWS Access Key:" access
	echo ""
	read -rs -p "Enter your AWS Secret Key:" secret
	echo ""
	echo "access_key: \"${access}\"" >> aws_creds.yml
	echo "secret_key: \"${secret}\"" >> aws_creds.yml
	echo "============= Encrypting aws_creds.yml using Ansible vault ============="
	echo "Keep a password ready for encryption"
	sleep 3
	ansible-vault encrypt aws_creds.yml
}
function __install() {
        VERSION=$(cat /etc/os-release | grep -oP '^NAME\=.+' | tr -d '""' | cut -d '=' -f 2)
        case $VERSION in
                "Ubuntu")
                        RELEASE=""
                        deb_install
                        ;;
                "Amazon Linux")
                        RELEASE="AmazonLinux"
                        rhel_install
                        ;;
                "Fedora")
                        RELEASE="fedora"
                        rhel_install
                        ;;
                "Red Hat Enterprise Linux")
                        RELEASE="RHEL"
                        rhel_install
                        ;;
                "CentOS")
                        RELEASE="RHEL"
                        rhel_install
                        ;;
                *)
                        echo "OS not recognized"
                        ;;

                esac
		if terraform_variable_overload; then
			echo "Process Completed!"
		fi
        }

function deb_install {
        if __verify "terraform"
        then
                echo "========= Installing terraform ========="
                wget -O - https://apt.releases.hashicorp.com/gpg -nv | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg &> /dev/null
                echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
                sudo apt -qq update && sudo apt -qq install terraform -y 
                if __verify "terraform"
                then
                        echo "======= Terraform Installation Complete! ========"
                fi
        fi
        if __verify "ansible"
        then
                echo "========= Installing Ansible ========="
                sudo apt update
                sudo apt -qq install ansible -y
		pip -qq install boto3 botocore
		__ansible_vault
                if __verify "ansible"
                then
                        echo "========= Ansible Insallation Complete! ==========="
                fi
        fi
}

function rhel_install {
        if __verify "terraform"
        then
                echo "======== Installing terraform ========"
		
                sudo yum install -y yum-utils -q
                sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/$RELEASE/hashicorp.repo
                sudo yum install terraform -y -q
                if __verify "terraform"
                then
                        echo "========== Terraform Installation Complete! =========="
                fi
        fi
        if __verify "ansible"
        then
		sudo yum install python3 python3-pip -y -q && echo "======= Python and PIP installation Completed! ========"
                pip -qq install ansible /tmp/pip.log
		pip -qq install boto3 botocore
		__ansible_vault
                if __verify "ansible"
                then
                        echo "======== Ansible Insallation Completed! ======="
                fi
        fi
}

function terraform_variable_overload() {

#Update Terraform variables to end-user preference

	read -p "Enter desired value for Project Tag:" project
	if [ -z "$project" ]; then
		echo "Error: Value for Project cannot be empty"
		exit 1
	fi
	sed -i "s/\$project/$project/g" variables.tf

	read -p "Enter desired value for Environment Tag:" environment
	if [ -z "$environment" ]; then
                echo "Error: Value for Environment cannot be empty"
                exit 1
	fi
	sed -i "s/\$environment/$environment/g" variables.tf

	echo "!! Make sure you've access-key & secret-key for an IAM user with Ec2FullAccess before answering Yes to next question !!"
	sleep 2
	read -p "Default region is ap-south-1. Would you like to use a different Region [Yes/No]?:" CHOICE
	if [ $CHOICE == "Yes" ]
	then
		read -p "Enter desired value for AWS Region:" region
		if [ -z "$region" ] 
		then
			sed -i "s/\$region/$REGION/g" variables.tf
			sed -i "s/\$ami_id/$AMI_ID/g" variables.tf
		else
			sed -i "s/\$region/$region/g" variables.tf
			unset REGION
			REGION=$region
			__aws_cli
			if __verify "aws"
			then
				ami_id=$(aws ec2 describe-images --region $region --owners amazon --filters 'Name=name,Values=amzn2-ami-kernel-5.10-hvm-2.0.20230119.1-x86_64-gp2' --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)
				sed -i "s/\$ami_id/$ami_id/g" variables.tf
			fi
		fi
	else
		sed -i "s/\$region/$REGION/g" variables.tf
		sed -i "s/\$ami_id/$AMI_ID/g" variables.tf
	fi

	read -p "Enter desired value for VPC_CIDR:" vpc_cidr
	if [ -z "$vpc_cidr" ]; then
                echo "Error: Value for VPC_CIDR cannot be empty"
                exit 1
	fi
	sed -i "s/\$vpc_cidr/${vpc_cidr//\//\\/}/g" variables.tf

	read -p "Enter desired value for Instance Type:" instance_type
	if [ -z "$instance_type" ]; then
                echo "Error: Value for Instance Type cannot be empty"
                exit 1
	fi
        sed -i "s/\$instance_type/$instance_type/g" variables.tf


	read -p "Enter desired value for Private Hosted Zone:" private
	if [ -z "$private" ]; then
                echo "Error: Value for Private Hosted Zone cannot be empty"
                exit 1
	fi
        sed -i "s/\$private/$private/g" variables.tf

	read -p "Enter desired value for Public Hosted Zone:" public
	if [ -z "$public" ]; then
                echo "Error: Value for Public Hosted Zone cannot be empty"
                exit 1
	fi
        sed -i "s/\$public/$public/g" variables.tf

	read -p "Enter desired value for Database server Hostname:" db_server
	if [ -z "$db_server" ]; then
                echo "Error: Value for DB-Server Name cannot be empty"
                exit 1
	fi
        sed -i "s/\$db_server/$db_server/g" variables.tf

	read -p "Enter desired value for Docker server Hostname:" docker_server
	if [ -z "$docker_server" ]; then
                echo "Error: Value for Docker Server Name cannot be empty"
                exit 1
	fi
        sed -i "s/\$docker_server/$docker_server/g" variables.tf

	read -p "Enter desired value for Website name:" website_name
	if [ -z "$website_name" ]; then
                echo "Error: Value for Website Name cannot be empty"
		exit 1
	fi
        sed -i "s/\$website_name/$website_name/g" variables.tf

	read -p "Enter AWS Access Key:" access
	if [ -z "$access" ]; then
		echo "Error: Value of Access Key cannot be empty"
		exit 1
	fi

	sed -i "$/\$access/$access/g" terraform_secret.tf

	read -p "Enter AWS Secret Key:" secret
	if [ -z "$secret" ]; then
		cho "Error: Value of Secret Key cannot be empty"
		exit 1
	fi
	sed -i "$/\$secret/$secret/g" terraform_secret.tf

	echo "Terraform variable update completed!"
	ansible_variable_overload
	return 1
}

function ansible_variable_overload() {

	## Update Frontend-server variables used with Ansible Playbook
	read -p "Enter Magento Admin Firstname:" fname
	if [ -z "$fname" ]; then
		fname='Admin'
	fi
	sed -i "s/\(admin_fname: \"\)[a-zA-Z0-9]*/\1$fname/g" frontend_vars.yml

	read -p "Enter Magento Admin Lastname:" lname
	if [ -z "$lname" ]; then
                lname='User'
	fi
	sed -i "s/\(admin_lname: \"\)[a-zA-Z0-9]*/\1$lname/g" frontend_vars.yml

	read -p "Enter Admin Email address:" email
	if [ -z "$email" ]; then
		email='admin@example.com'
	fi
	sed -i "s/\(admin_email: \"\)[a-zA-Z0-9@.]*/\1$email/g" frontend_vars.yml
	
	read -p "Enter Admin Username:" uname
	if [ -z "$uname" ]; then
		uname='admin'
	fi
	sed -i "s/\(admin_user: \"\)[a-zA-Z0-9]*/\1$uname/g" frontend_vars.yml

	##Update Frontend-server Name using $front_server variable from terraform_variable_overload function
	sed -i "s/\(httpd_domain:  \"\)[a-zA-Z.]*/\1$front_server/g" frontend_vars.yml

	##Update Docker-server Name using $docker_server variable from terraform_variable_overload function
	sed -i "s/\(es_host: \"\)[a-zA-Z.]*/\1$docker_server/g" frontend_vars.yml

	read -p "Enter Magento Admin Password:" pswd
	if [ -z "$pswd" ]; then
		pswd="Password123"
	fi
	sed -i "s/\(admin_pass: \"\)[a-zA-Z0-9]*/\1$pswd/g" frontend_vars.yml

	##Update Backend-server variables
	read -p "Enter MySql Password:" rootpwd
	if [ -z "$rootpwd" ]; then
		rootpwd='root123'
	fi
	sed -i "s/\(mysql_root_passwd: \"\)[a-zA-Z0-9.\@\+\$\#\^\*\(\)\!\_\-]*/\1$mypwd/g" backend_vars.yml
	
	##Update Database-server Name using value of $db_server from terraform_variable_overload function
	sed -i "s/\(mysql_host: \"\)[a-zA-Z.]*/\1$db_server/g" backend_vars.yml

	##Update value of $region in region.yml
	sed -i "s/\$region/$REGION/g" region.yml

	echo "========= Ansible Variable Update completed! ========"
	return 1
}

CHOICE=''
REGION='ap-south-1'
AMI_ID='ami-01a4f99c4ac11b03c'
access=''
secret=''
__install
