# aws-cfn-governance

## Summary

This repository demonstrates the usage of a simple `helloWorld` Node.js application running in AWS' EC2 behind a Load Balancer. The application will be accessible using a friendly DNS from the `example.com` domain and accepting requests through port 80, hence no HTTPS is being used as of now (port 443 is not allowed).

All of the EC2 logs will be forwarded in a timely manner every 5 minutes to an AWS S3 bucket. This pipeline will involve the usage of CloudWatch and a Lambda function subscribed to it, which will be the one in charge of forwarding the produced logs to the S3 bucket.

The above setup, is going to be created with a CloudFormation stack which will be in charge of creating and deploying all of the products needed for the above scenario to function.

## Architecture/Application considerations

- Be able to scale from 1QPS to 20.000 QPS.
- System should be resilient to failures, thus being available in more than one zone within the region.
- Application should be publicly available through port 80.
- Application private port 8080 only accessible through a parametizable IP and from default VPC.
- EC2 can be accessed for management (3389 / 22) through a parametizable IP.

## AWS products involved

- CloudFormation
- AutoScaling Group
- Elastic Computing Cloud(EC2)
- Elastic Load Balancer(ELB)
- EventBridge
- CloudWatch
- Lambda
- Systems Manager Agent(SSM)

## Parameters

The list of accepted parameters by CloudFormation upon creating the stack are described here:

| Variable | Description | Default value |
| --- | --- | -- |
| VpcId | VpcId of the default existing Virtual Private Cloud (VPC) | -- |
| Subnets | The list of SubnetIds in the default Virtual Private Cloud (VPC) | -- |
| InstanceType | WebServer EC2 instance type | t2.micro |
| KeyName | Name of an existing EC2 KeyPair to enable SSH access to the instances | -- |
| SSHLocation | The IP address range that can be used to SSH to the EC2 instances, using port `22`. | -- |
| TCPUDPLocation | The IP address range that can be used to access to the EC2 instances using port `3389`. | -- |
| PrivateAccessIP | The IP address range that can be used to access to the EC2 instances using port `8080`. | -- |

## Outputs

Upon successfully creating the CloudFormation stack, the following outputs will be displayed:

| Variable | Description |
| --- | --- |
| URL | Load Balancer URL from which the application is publicly accesible. |

## Usage

## Improvements

In order to improve the architecture from a cost and performance point of view, the following points are valuable and worth exploring as these will impact the whole architecture either in cost or performance.

- ASG custom scaling metric
- Spot EC2 instances
- Instance rightsizing
- Instance reservation
