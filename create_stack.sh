#!/bin/sh

STACK_NAME=adevinta-aws-test
TEMPLATE_FILE=file://aws-cf.json
REGION=eu-west-1
VPC=$(aws ec2 describe-vpcs --region ${REGION} --filters Name=isDefault,Values=true --query 'Vpcs[*].VpcId' --output text)
SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${VPC} --query 'Subnets[*].SubnetId' | tr "[]" " " | sed 's/\"//g')
INSTANCE_TYPE=t2.micro
KEYNAME=ssh-ec2
SSHLOCATION=0.0.0.0/0
TCPUDPLOCATION=0.0.0.0/0
PRIVATEACCESSIP=0.0.0.0/0
PARAMETERS_FILE=parameters.json

PARAMS_TEMPLATE='[
        {
            "ParameterKey": "VpcId",
            "ParameterValue": "%s"
        },
        {
            "ParameterKey": "Subnets",
            "ParameterValue": "%s"
        },
        {
            "ParameterKey": "InstanceType",
            "ParameterValue": "%s"
        },
        {
            "ParameterKey": "KeyName",
            "ParameterValue": "%s"
        },
        {
            "ParameterKey": "SSHLocation",
            "ParameterValue": "%s"
        },
        {
            "ParameterKey": "TCPUDPLocation",
            "ParameterValue": "%s"
        },
        {
            "ParameterKey": "PrivateAccessIP",
            "ParameterValue": "%s"
        }
    ]'

JSON_STRING=$(printf "$PARAMS_TEMPLATE" "$VPC" "$SUBNETS" "$INSTANCE_TYPE" "$KEYNAME" "$SSHLOCATION" "$TCPUDPLOCATION" "$PRIVATEACCESSIP")

echo $JSON_STRING > $PARAMETERS_FILE

aws cloudformation create-stack --stack-name $STACK_NAME --template-body $TEMPLATE_FILE --parameters file://${PARAMETERS_FILE} --capabilities CAPABILITY_IAM
