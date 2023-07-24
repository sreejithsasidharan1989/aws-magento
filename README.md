### Deploy Magento 2.4.6 on Amazon EC2 Instance
--------

##### Introduction
Magento 2 is an ecommerce platform built on open source technology which provides online merchants with a flexible shopping cart system, as well as control over the look, content, and functionality of their online store. 

###### Magento offers:
- Powerful marketing
- Search engine optimization
- Catalog-management tools

##### Project Description
In this project, the infrastructure is built using Terraform, and the Ec2 instances are managed using Ansible. This project consists of four main components: three t2.micro type Ec2 instances running the Apache Webserver, PHP, and Magento applications; a second Ec2 instance running a MariaDB database; and a third Ec2 instance running an Elasticsearch docker container. A load balancer that supports SSL is the fourth element. The project is deployed using the following technologies:
1. Magento 2.4.6
2. PHP - 8.1
3. Apache - Latest
4. MariaDB - 10.6
5. Elasticsearch Container - 7.17

After interpolating the configuration files like httpd.conf, virtualhost.conf, and www.conf using Jinja, they get copied from the local system to the target server by Ansible. An application load balancer has been positioned in front of the Apache Webserver to handle SSL requests. Ansible will make use of the ssh-key that Terraform generates on its own to connect to instances. variables.tf allow for the management of all variables including the AWS Region, Project & Environment Tags. Ansible will look for a file called "aws_creds.yml" for AWS credentials; however, for Terraform, the AWS credentials must be placed into a file with a '.tf' extension.

##### Future Updates
1. Add support for Auto-scaling
2. Add SNS notification
3. Add Nginx for SSL off-loading in the absense of an ALB 