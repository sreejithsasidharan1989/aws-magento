### Deploy Magento 2.4.6 on Amazon EC2 Instance
--------

##### Introduction
Magento 2 is an e-commerce platform built on open-source technology which provides online merchants with a flexible shopping cart system, as well as control over the look, content, and functionality of their online store. 

###### Magento offers:
- Powerful marketing
- Search engine optimization
- Catalog-management tools

##### Project Description
In this project, the infrastructure is built using Terraform, and the Ec2 instances are managed using Ansible. This project consists of four main components: three t2.micro type Ec2 instances running the Apache Webserver, PHP, and Magento applications; a second Ec2 instance running a MariaDB database; and a third Ec2 instance running an Elasticsearch docker container. A load balancer that supports SSL is the fourth element. The project is deployed using the following technologies:
1. Magento 2.4.6
2. PHP - 8.1
3. Apache
4. MariaDB - 10.6
5. Elasticsearch Container - 7.17

After interpolating the configuration files like httpd.conf, virtualhost.conf, and www.conf using Jinja, they get copied from the local system to the target server by Ansible. An application load balancer has been positioned in front of the Apache Webserver to handle SSL requests. Ansible will make use of the ssh-key that Terraform generates on its own to connect to instances. variables.tf allow for the management of all variables including the AWS Region, Project & Environment Tags. Ansible will look for a file called "aws_creds.yml" for AWS credentials; however, for Terraform, the AWS credentials must be placed into a file with a '.tf' extension.

##### Features
- setup.sh file will automatically install tools like Ansible, Terraform, and AWS-CLI ( if needed ) based on the Unix-like Operating System that you're in ( Only Support, RHEL/Debian ).
- The script also allows changing the Region and takes care of the AMI_ID based on the chosen region ( Currently this project only works on Amazon Linux 2 ).
- Values for a number of variables are assigned using this script, see "How to run this Project" section for more details.
- This project gives the option to deploy an application load balancer with or without SSL support.

##### How to run this project
###### Prerequisites

In order to successfully complete the deployment, the following details are needed

- Access-key & Secret-key of an IAM user with Ec2FullAccess
- SSL Certificate ARN:
  An SSL certificate ( Single domain or Wild-card ) ARN that correlates with the website name so that it can be attached to the Load Balancer
- In the case of using a different Region:
  Access-key & Secret-key of an IAM user with ReadOnlyAccess, or the same access&secret key can be used which is mentioned in step one of this section
     
1. clone this GitHub project to the system
   - git clone https://github.com/sreejithsasidharan1989/aws-magento.git
     
2. Give execute permission for setup.sh
   - $ chmod u+x setup.sh
     
3. Run the script to install the required tools
   - ./setup.sh
     
4. Once the script execution has begun, it will install a couple of tools and prompt for inputs for the following values
   - Project Tag  ( A Random tag for the project, null value not allowed )
   - Environment Tag ( A Random tag for the environment, null value not allowed )
   - AWS Region ( Allows changing region, null value supported in which case default region ap-south-1 will be used )
   - VPC CIDR ( Network CIDR for the VPC, null value not supported )
   - Instance Type ( Type of instance that must be used, null value not supported )
   - Private Hosted Zone Name ( Name for the private DNS Zone which is used to map Database & Docker server IPs to internal names Ex: my-project.local )
   - Public Hosted Zone ( Name for Public DNS Zone where the live domain is mapped to the frontend server IP )
   - Hostname for Database server ( Name for the database server whose suffix will be the name of private hosted zone Ex: db.my-project.local )
   - Hostname for Docker server ( Name for the elastic search server whose suffix will be the name of private hosted zone Ex: elastic.my-project.local ) 
   - Website Name ( Live website name )
   - Magento Admin Firstname ( First name of Magento Admin )
   - Magento Admin Lastname ( Last name of Magento Admin )
   - Magento Admin Email ( Email address of admin user )
   - Magento Admin Username ( Username for admin user )
   - MySql Root Password ( Root password for MySql )
5. Run 'terraform validate' followed by 'terraform plan' to validate the code and perform a test run.
   
6. If there are no errors, execute 'terraform apply.' It will ask for inputs for the subsequent variables:

   - var.alb_switch
     Enter a value:
     This determines whether or not to enable an Application Load Balancer, valid inputs are 1 or 0
     
   - var.cert_arn
     Enter a value:
     An SSL Certificate ARN is necessary only when the value of var.alb_switch is set to 1.
     
   - var.cert_switch
     Enter a value:
     Valid inputs are 1 & 0 based on which SSL support will be added to the Load balancer. Only important when var.alb_switch is set to 1.

   - var.nat_switch
     Enter a value:
     The infra does not support the use of Nat-Gateway at this point, so it is recommended to set it to 0.
     
7. Expect the infrastructure to be fully operational within 15 to 25 minutes.

##### Future Updates
1. Add support for Auto-scaling
2. Add SNS notification
3. Add Nginx for SSL off-loading in the absence of an ALB
4. End-to-End encryption
5. Improve sensitive data handling
