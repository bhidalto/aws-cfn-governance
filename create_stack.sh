#!/bin/sh

STACK_NAME=adevinta-aws-test
TEMPLATE_FILE=file://aws-cf.json
REGION=eu-west-1
VPC=$(aws ec2 describe-vpcs --region ${REGION} --filters Name=isDefault,Values=true --query 'Vpcs[*].VpcId' --output text)
SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=${VPC} --query 'Subnets[*].SubnetId' | tr "[]" " " | sed 's/\"//g')
INSTANCE_TYPE=t2.micro
KEYNAME=my-key-pair-test
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
echo "Creating JSON that contains the needed parameters...."
JSON_STRING=$(printf "$PARAMS_TEMPLATE" "$VPC" "$SUBNETS" "$INSTANCE_TYPE" "$KEYNAME" "$SSHLOCATION" "$TCPUDPLOCATION" "$PRIVATEACCESSIP")
echo "JSON correctly created."
echo "Copying JSON data to ${PARAMETERS_FILE}"
echo $JSON_STRING > $PARAMETERS_FILE
echo "Done. Successfuly created ${PARAMETERS_FILE}"
echo "Attempting to create new EC2 key-pair with the provided keyname: ${KEYNAME}"
aws ec2 create-key-pair --key-name $KEYNAME
if [ $? -eq 0 ]; then
    echo "Successfully created new AWS EC2 key-pair with keyname: ${KEYNAME}"
elif [ $? -eq 254 ]; then
    echo "The keypair already exists, will be using it in the stack."
else
    echo "There was an error attempting to create the key-pair, stopping the script."
    exit
fi
echo "Proceeding to create the stack ${STACK_NAME} using ${TEMPLATE_FILE} as template."
aws cloudformation create-stack --stack-name $STACK_NAME --template-body $TEMPLATE_FILE --parameters file://${PARAMETERS_FILE} --capabilities CAPABILITY_IAM
if [ $? -eq 0 ]; then
    echo "Success! Stack ${STACK_NAME} has been created."
else
    echo "Something went wrong, the create stack operation failed."
fi
