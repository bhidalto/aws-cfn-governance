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

In order to successfully deploy the stack, the following command can be used:

```
aws cloudformation create-stack --stack-name elb-ec2 --template-body file://aws-cf.json --capabilities CAPABILITY_IAM
```

## Outcomes

## Improvements

In order to improve the architecture from a cost and performance point of view, the following points are valuable and worth exploring as these will impact the whole architecture either in cost or performance.

- **AutoScaling Group custom scaling metric:** As of now, the scaling option chosen is a Target tracking policy that takes into consideration the average CPU utilization of the AutoScaling group. However, this metric is not so flexible at all and could spin up unnecessary instances while the backend is still capable of handling the load, thus leading to an increase of unnecessary costs or not properly scaling when needed. An example would be having a 50% average CPU usage in the ASG but the load distributed as 90%/10% between 2 instances, which is not good. Adding [custom metrics](https://docs.aws.amazon.com/autoscaling/plans/userguide/gs-specify-custom-settings.html#gs-customized-metric-specification) with CloudWatch, the application can be scaled with finer granularity as multiple alarms could be set up, with the benefit of being capable of defining both the lower and higher boundary that the autoscaler should be using to scale-out or in respectively. Ultimately, the [predictive scaling](https://docs.aws.amazon.com/autoscaling/plans/userguide/gs-specify-custom-settings.html#gs-customize-predictive-scaling) could be used in conjunction to Dynamic Scaling and configured to Balance cost and availability.
- **Spot EC2 instances:** In regards to cost control, making use of Spot EC2 instances for the application will help lowering the billing costs of the application. Configuring the ASG with a [pool](https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-purchase-options.html#create-asg-multiple-purchase-options-console) for EC2 instances and Spot instances will benefit of the lower prices for the running spot instances.
- **Instance rightsizing:** AWS provides a perfect feature under their Billing and Cost management products, which is focused on optimizing the costs. [Costs Explorer](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-rightsizing.html) provides recommendations mainly focused on costs based on usage. It can provide suggestions to either terminate unused or unnecessary instances or to modify the size of certain instances based on usage.
- **Instance reservation:** Also related to cost optimization, the capability of EC2 instance reservation can help reducing costs in the long term. This feature coupled with a good usage plan driven by load tests being run beforehand, can help reduce the costs vastly.
