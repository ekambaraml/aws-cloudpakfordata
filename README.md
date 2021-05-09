# aws-cloudpakfordata
Deploying Cloud Pak for Data on AWS Cloud


On Bastion Host

## Install Pre-Requisits
- Install OpenShift Client(oc)
- OpenShift Installer
- AWS CLI
- Add endpoints
  - elb
  - ebs
  - s3
  - ec2
  Also add a security group that allow tcp/443 that these endpoints are assigned.


## Setup Registry


## Update Install-config.yaml
  - add ssh key
  - add pull-secret as a 1-liner
  - add registry ca cert
  - imageContentSources: section from above

## Deploying openShift Cluster

####  3.1 Create directory manifest and ingition
     mkdir -p <ocpconfig>

####  3.2 Copy install-config.yaml to ignition directory
     copy install-config.yaml <ignition-directory>
  
####  3.3 Create the manifests
     openshift-install create manifests --dir=<ignitiondir>

####  3.4 Remove master and worker manifests, we will be creating them with cloudformation
  rm -f <ignitiondir>/openshift/99_openshift-cluster-api_master-machines-*.yaml
  rm -f <ignitiondir>/openshift/99_openshift-cluster-api_worker-machineset-*.yaml

#### 3.5 Remove privateZone and publicZone infos
     <ignitiondir>/manifests/cluster-dns-02-config.yaml
  
#### 3.6 Create Ignition files
     openshift-install create ignition-configs --dir=<ignitiondir>
  
#### 3.7 Harvest infraID from the metadata.json
  - if you have jq installed, run: jq -r .infraID <ignitiondir>/metadata.json
  - else, if not, examine <ingitiondir>/metadata.json to get infraID (should be <clustername>-<randomnumber>)
  - save infraID for later use

#### 3.8 Create/Identify VPC and Subnets
  
  - VPC should have "EnableDnsSupport=true, EnableDnsHostnames=true"
  - Need 1 'public' and 1 'private' subnet for each AZ desired.  Note that the check for 'private' subnet is if route table for subnet has an internet gateway.
  
#### 3.9 Create the following endpoints in private subnets
  - s3 gateway (add to private subnet route table)
  - elb endpoint
  - ebs endpoint
  - lambda endpoint
  - ec2 endpoint
  - create a security group that allows 443 from subnets inbound and assign to all endpoints

#### 3.10 Create route53 and load balancer resources in VPC
  Create a base domain in route53 to use the following cloudformation template.  Use domain configured for cluster to create a private route 53 domain, no content needed
- I also found that I needed to use a bastion that had access to external apis in GovCloud (not all endpoint available in my config to private bastion).  In customer's environment, this may need to be handled

#### 3.11 Create Network Stack
  - Update the network.param.json
  - Create network stack by running the command:
    aws cloudformation create-stack --stack-name <clustername>-network --template-body file://network.template  --parameters file://network.param.json  --capabilities CAPABILITY_NAMED_IAM
  
  - Monitor for completion
    aws cloudformation describe-stacks --stack-name <clustername>-network
  
  





  

     

  

  
