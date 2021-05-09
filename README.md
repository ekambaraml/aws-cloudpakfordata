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

  

     

  

  
