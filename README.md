# aws-cfn-governance

## Summary

This repository demonstrates the usage of a simple `helloWorld` Node.js application running in AWS' EC2 behind a Load Balancer. The application will be accessible using a friendly DNS from the `example.com` domain and accepting requests through port 80, hence no HTTPS is being used as of now (port 443 is not allowed). In order to set up the DNS, AWS Route 53 will be used to attach it to the application's Load Balancer.

All of the EC2 logs will be forwarded in a timely manner every 5 minutes to an AWS S3 bucket. This pipeline will involve the usage of CloudWatch and a Lambda function subscribed to it, which will be the one in charge of forwarding the produced logs to the S3 bucket.

The above setup, is going to be created with a CloudFormation stack which will be in charge of creating and deploying all of the products needed for the above scenario to function.

## Architecture/Application considerations

- Be able to scale from 1QPS to 20.000 QPS.
  - As of now, the initial setup deploys 2 EC2 instances at minimum and the desired capacity is 2, just in order to be available in more than one zone within the region. However, it will be needed to perform load tests in order to fine-tune these parameters and also the instance type.
- System should be resilient to failures, thus being available in more than one zone within the region.
  - On deployment time, all of the subnets within the region are fetched, therefore any of these will be used by the EC2 instances and as we're defining a minimum of 2 EC2 instances, the application will be available in more than one zone within the specified region.
- Application should be publicly available through port 80.
  - The Load Balancer has public access on the port 80, and it forwards the requests to the application that is running on port 8080.
- Application private port 8080 only accessible through a parametizable IP and from default VPC.
  - The `PrivateAccessIP` parameter allows access for the defined IP to the EC2 instance using the port 8080.
- EC2 can be accessed for management (3389 / 22) through a parametizable IP.
  - The parameters in control of such access are `TCPUDPLocation` and `SSHLocation` respectively.

## AWS products involved

- CloudFormation
- AutoScaling Group
- Elastic Computing Cloud(EC2)
- Elastic Load Balancer(ELB)
- EventBridge
- CloudWatch
- Lambda
- Systems Manager Agent(SSM)
- Route 53

## Parameters

The list of accepted parameters by CloudFormation upon creating the stack are described here:

| Variable | Description |
| --- | ---
| VpcId | VpcId of the default existing Virtual Private Cloud (VPC)
| Subnets | The list of SubnetIds in the default Virtual Private Cloud (VPC) |
| InstanceType | WebServer EC2 instance type |
| KeyName | Name of an existing EC2 KeyPair to enable SSH access to the instances |
| SSHLocation | The IP address range that can be used to SSH to the EC2 instances, using port `22`. |
| TCPUDPLocation | The IP address range that can be used to access to the EC2 instances using port `3389`. |
| PrivateAccessIP | The IP address range that can be used to access to the EC2 instances using port `8080`. |

## Outputs

Upon successfully creating the CloudFormation stack, the following outputs will be displayed:

| Variable | Description |
| --- | --- |
| URL | Load Balancer URL from which the application is publicly accesible. |



## Outcomes

- All the necessary files needed to deploy the application using one command:

The stack can be deployed using the following executing the bash script as follows:

```
./create_stack.sh
```
Besides deploying the stack, the script dynamically generates the `parameters.json` file that is used to create the stack and fetches the ids of the Default VPC and Subnets in the specified region. There are some shell variables used in the process which are described here:

| Variable | Description |
| --- | --- |
| STACK_NAME | Name of stack that will be created.|
| TEMPLATE_FILE | File containing the CloudFormation stack template that is in charge of defining all the resources. |
| REGION | Region to be used in the deployment of the resources. |
| VPC | Computed using the AWS CLI. Uses the `$REGION` variable to fetch the id of the specific VPC. |
| SUBNETS | Computed using the AWS CLI. Fetches all the subnets from the `$VPC` |
| INSTANCE_TYPE | Instance type that will be used in the EC2 deployment. |
| KEYNAME | Name of an existing key pair which will be used to SSH into EC2 instances. |
| SSHLOCATION | IP range whitelisted to be able to SSH into EC2 instances. |
| TCPUDPLOCATION | IP range whitelisted to be able to access EC2 instances making use of port `3389` |
| PRIVATEACCESSIP | IP range whitelisted to be able to access EC2 instances using port `8080` |
| PARAMETERS_FILE | Name of the file that will be created and used to pass the needed parameters to the AWS CLI create stack command. |
| PARAMS_TEMPLATE | String containing the definition of the parameters that are needed for the Stack creation to properly function. |
| JSON_STRING | Temporal variable used to host the JSON that will be printed into the `$PARAMETERS_FILE- |

The bash script will be running the following AWS CLI command:

```
aws cloudformation create-stack --stack-name $STACK_NAME --template-body $TEMPLATE_FILE --parameters file://${PARAMETERS_FILE} --capabilities CAPABILITY_IAM
```

All the necessary files are located in the repository so these can be used directly upon deployment. A description for each of them can be seen in the following table:

| File | Description |
| --- | --- |
| create_stack.sh | Bash script used to launch the AWS CLI command that will be creating the stack. This is where the `parameters.json` file is created dynamically as well. In order to modify the parameters to pass to the AWS CLI command, just modify the value for the shell variables. |
| aws-cf.json | Contains the CloudFormation template that is used to define all the resources to be deployed. |
| parameters.json | All the needed parameters for the `create-stack` command are passed by making use of this JSON file. |
| lambda_function.py | Code which will be executed by the Lambda function. Although it's not used directly by the template, it is included in the repository for better readability. |

- Ability to deploy a different version of the application with only changing a deployment parameter:

Making use of the [`update-stack`](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/update-stack.html) AWS CLI command, another version of the application can be deployed. It is also possible to achieve the same behaviour by using a [change set](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-updating-stacks-changesets-create.html). When doing any of the above options, the `cfn-auto-reloader.conf` hook alongside the `cfn-hup` helper daemon will come into play, as it's listening for changes on the EC2 instances which happen through the UpdateStack API action. ˚

- Servers must be configured and provisioned at their first boot:

Making use of the helper CFN script `cfn-init`, the EC2 instances are set up with all the needed settings upon deployment. This can be seen in the resource `LaunchConfig` which creates an `AWS::AutoScaling::LaunchConfiguration`. The `cfn-init` script, makes use of the aforementioned resource in order to generate and install all the specified settings to each of the EC2 instances.  The user data script that is set in that resource also installs needed dependencies. In this case, the SSM and CloudWatch agents get installed there and afterwards the Node.js helloworld code gets dowloaded from the provided GitHub repository (only the needed files are downloaded making use of `wget` instead of using git clone, as it will make the EC2 launch time faster and consume less disk space) and the server starts listening on port 8080 before returning a success signal to CloudFormation.

- Base Image must be the default provided by amazon in the chosen zone:

The base image is automatically chosen in the stack. Both the region and the instance type are taken into consideration to correctly select the AMI id. The `Mappings` defined in the stack template are the ones responsible of it.

- Everything should be repeatable on the same or another account for creating multiple environments.

With the provided script, the same setup can be created on any other account or in the same one to create multiple environemnts. With only chhanging the shell variables described above, new environments can be easily deployed as new CloudFormation stacks.

### Bonus Tracks

#### Memory Usage metric

A custom CloudWatch metric has been included on the AutoScaling EC2 instances which serve the application. The CloudWatch agent is installed and started upon instance creation and afterwards the metrics `mem_used_percent` and `swap_used_percent` which are visible under the CloudWatch metrics dashboard, as a custom namespace named `CWAgent`. The metrics to be exported by the agent are defined in the `amazon-cloudwatch-agent.json` file defined in the `AWS::AutoScaling::LaunchConfiguration` resource, and if in the future further [metrics](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html#CloudWatch-Agent-Linux-section) should be added or even custom [logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html#CloudWatch-Agent-Configuration-File-Logssection), these can be appended there to update the Stack afterwards.

#### Cost/Performance Improvements

In order to improve the architecture from a cost and performance point of view, the following points are valuable and worth exploring as these will impact the whole architecture either in cost or performance.

- **AutoScaling Group custom scaling metric:** As of now, the scaling option chosen is a Target tracking policy that takes into consideration the average CPU utilization of the AutoScaling group. However, this metric is not so flexible at all and could spin up unnecessary instances while the backend is still capable of handling the load, thus leading to an increase of unnecessary costs or not properly scaling when needed. An example would be having a 50% average CPU usage in the ASG but the load distributed as 90%/10% between 2 instances, which is not good. Adding [custom metrics](https://docs.aws.amazon.com/autoscaling/plans/userguide/gs-specify-custom-settings.html#gs-customized-metric-specification) with CloudWatch, the application can be scaled with finer granularity as multiple alarms could be set up, with the benefit of being capable of defining both the lower and higher boundary that the autoscaler should be using to scale-out or in respectively. Ultimately, the [predictive scaling](https://docs.aws.amazon.com/autoscaling/plans/userguide/gs-specify-custom-settings.html#gs-customize-predictive-scaling) could be used in conjunction to Dynamic Scaling and configured to Balance cost and availability.
- **Spot EC2 instances:** In regards to cost control, making use of Spot EC2 instances for the application will help lowering the billing costs of the application. Configuring the ASG with a [pool](https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-purchase-options.html#create-asg-multiple-purchase-options-console) for EC2 instances and Spot instances will benefit of the lower prices for the running spot instances.
- **Instance rightsizing:** AWS provides a perfect feature under their Billing and Cost management products, which is focused on optimizing the costs. [Costs Explorer](https://docs.aws.amazon.com/awsaccountbilling/latest/aboutv2/ce-rightsizing.html) provides recommendations mainly focused on costs based on usage. It can provide suggestions to either terminate unused or unnecessary instances or to modify the size of certain instances based on usage.
- **Instance reservation:** Also related to cost optimization, the capability of EC2 instance reservation can help reducing costs in the long term. This feature coupled with a good usage plan driven by load tests being run beforehand, can help reduce the costs vastly.
