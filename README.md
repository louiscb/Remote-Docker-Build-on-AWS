# Remote Docker EC2 Builder

This repo contains a Terraform plan that will create an EC2 instance on AWS with the intention of using it to remotely build and run Docker containers.

## Requirements

- Terraform
- Docker CLI
- AWS CLI 
- SSH

## Setting up the Terraform plan

You will probably need to change some of the values in the `main.tf` file. 

1. The SSH public and private key will need to point to your specific SSH keys
2. The AWS region should be changed to your preferred region.
3. The EC2 instance size could be changed to your preference. 

## Running the plan

First you need to ensure you are logged into your AWS account.

```
aws configure
```

Once that is configured and logged in, run:

```
terraform init
```

If that is successful you can apply your Terraform plan which should produce the EC2 instance.

```
terraform apply
```

Once that step is concluded it will output an environment variable for you to use, something like `export DOCKER_HOST=ssh://ec2-user@83.4.56.101`. Run that export command in your terminal, then navigate to your Docker project and run `docker build`. It will now be building your Docker image inside of the remote instance, you can double check this by running `docker info` and looking at the "Name" field.
