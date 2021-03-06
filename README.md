# aws-cloudpakfordata
Deploying Cloud Pak for Data on AWS Cloud


## Bastion Host Setup
clone this git repository before starting deploy openshift on a custom priviate AWS environment
```
   git clone https://github.com/ekambaraml/aws-cloudpakfordata
```
- Install AWS Cli
  https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html
  https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-linux.html#cliv2-linux-install
  ```
    yum install -y unzip
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
  ```
  add /usr/local/bin into the PATH.
  
- Configure AWS client
  
  ```
  aws configure
    AWS Access Key ID [None]: <aws-access-key-id>
    AWS Secret Access Key [None]: <aws-secret-access-key>
    Default region name [None]: <ca-central-1>
    Default output format [None]: json
  ```
- OpenShift Client/Installer
  ```
  ; if wget is not installed already
  yum install -y wget
  
  ; Download OCP 4.6.27 installer and cli
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.6.27/openshift-client-linux.tar.gz
    wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/4.6.27/openshift-install-linux.tar.gz

    tar xvf openshift-client-linux.tar.gz
    cp oc /usr/bin
    oc version
    cp kubectl /usr/bin
    kubectl  version
 
    tar xvf openshift-install-linux.tar.gz
    ./openshift-install  version
  ```
  
- Download the OCP pull secrets

  Login to your redhat subscription account and Download or copy your pull secret into bastion host. It is required for setting up registry mirror and Installations.

  https://cloud.redhat.com/openshift/install/aws/installer-provisioned
  
  ![ScreenShot](https://github.com/ekambaraml/IBM-Cloud-Pak-for-Data/raw/main/images/ocp-pullsecret.png)
  
  Create redhat-pullsecret.json

## Registry mirror for AirGap Install

If you need to use mirror registry for the airgap install, follow this instruction https://github.com/ekambaraml/aws-cloudpakfordata/blob/main/registry-mirror.md



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

#### Prepare the DNS

OpenShift requires a valid DNS domain, you can get one from AWS Route53 or using existing domain and registrar. The DNS must be registered as a Public Hosted Zone in Route53. (Even if you plan to use an airgapped environment)

#### Configuring AWS Account 

- Configuring Route 53
  https://docs.openshift.com/container-platform/4.6/installing/installing_aws/installing-aws-account.html#installing-aws-account

  To install OpenShift Container Platform, the Amazon Web Services (AWS) account you use must have a dedicated public hosted zone in your Route 53 service. This  zone must be authoritative for the domain. The Route 53 service provides cluster DNS resolution and name lookup for external connections to the cluster.
  
  Create a public hosted zone for your domain or subdomain. See Creating a Public Hosted Zone in the AWS documentation.
  ```
  <cluster>.<ibmcp4d.com>
  ```
  
  

Please reference the Required AWS Infrastructure components to setup your AWS account before installing OpenShift 4.

We suggest to create an AWS IAM user dedicated for OpenShift installation with permissions documented above. On the bastion host, configure your AWS user credential as environment variables:

export AWS_ACCESS_KEY_ID=RKXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=LXXXXXXXXXXXXXXXXXX/ng
export AWS_DEFAULT_REGION=us-east-2



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
  
  - Check status
    aws cloudformation describe-stacks --stack-name <clustername>-network
  

#### 3.12 Create Security Group and Roles
  - update the sec_group_roles.param.json with validate values
  - Create Security groups
  
    aws cloudformation create-stack --stack-name <clustername>-secgrouproles --template-body file://sec_group_roles.template  --parameters file://sec_group_roles.param.json  --capabilities CAPABILITY_NAMED_IAM
  
   - Check status
    aws cloudformation describe-stacks --stack-name <clustername>-secgrouproles
  
  
#### 3.13 Create OpenShift Bootstrap node

  - Create S3 bucket for bootstrap node's ignition file
    Create s3://<clustername>-infra
  
  - Copy bootstrap ignition file to S3
    aws s3 cp <ignitiondir>/bootstrap.ign s3://<cluster-name>-infra/bootstrap.ign
  
  - Create bootstrap machine
    * Update bootstrap.param.json parameters. Note public subnet is where bootstrap node will be created
    aws cloudformation create-stack --stack-name <clustername>-bootstrap --template-body file://bootstrap.template --parameters file://bootstrap.param.json  --capabilities CAPABILITY_NAMED_IAM
  
    aws cloudformation describe-stacks --stack-name <clustername>-bootstrap
  
  
  

#### 3.13 Create OpenShift master nodes

IMPORTANT SAFETY TIP: for certificate authorities, you'll want a pem file of both the CA certificate for the local registry (created above) and the root-ca of the openshift installation (this can be found in the bootstrap.ign file (look for /opt/openshift/tls/root-ca.crt to get the base64 encoded certificate).  Once you've created the PEM file, base64 encode it and use the result as the value for certificateauthority (after the "data:text/plain;charset=utf-8;base64," preable).  This applies to the workers also.


   aws cloudformation create-stack --stack-name <clustername>-control --template-body file://control.template --parameters file://control.param.json

   aws cloudformation describe-stacks --stack-name <clustername>-control
  
  
 #### 3.14 Create OpenShift Worker nodes
 
   - Create parameter file for each worker (worker<n>.param.json) by copying the template file into separate file
   - Update the worker-param.json with valid values
   
   - cp worker.param.json  worker1.param.json 
     update the new file with correct values 
     
     aws cloudformation create-stack --stack-name <clustername>-worker<n> --template-body file://worker.template --parameters file://worke<n>.param.json
  
  
### 4.0 OpenShift Cluster building

#### 4.1 Wait for bootstrap to complete
   ./openshift-install wait-for bootstrap-complete --dir=<ignitiondir> --log-level=info
  
#### 4.2 Check cluster status

  export KUBECONFIG=<ignitiondir>/auth/kubeconfig
  oc get nodes
  
  Look for pending csr and approve it
  oc get csr
  oc get csr -o go-template='{{range .items}}{{if not .status}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}' | xargs --no-run-if-empty oc adm certificate approve
  
  
### 5.0 Post Install tasks



#### 5.1 DNS record for applications (*.apps.<clustername>.<domain>)
  - add CNAME record for ingress loadbalancer(classic) created by the installation in to the internal route53 hosted domain


#### 5.2 Create openshift admin user (ocadmin)
  mkdir -p <workingdir>/security/openshift
  cd <workingdir>/security/openshift
  htpasswd -c -B -b htpasswd <username> <password>
  oc create secret generic htpass-secret --from-file=htpasswd -n openshift-config
  oc apply -f ocp_oauth.yaml
  
  * cluster-admin role to this new user
  oc adm policy add-cluster-role-to-user cluster-admin <ocadmin>
  
  unset KUBECONFIG
  oc login https://api.<clustername>.<domain> -u <new-cluster-admin>
  

### 5.3 Set up EFS storage
  get efs provisioner images
  podman pull pull quay.io/external_storage/efs-provisioner:latest
  podman tag efs-provisioner:latest <ipaddress>:<port>/efs-provisioner:latest
  podman login <ipaddress>:<port> -u <username> -p <password>
  podman push <ipaddress>:<port>/efs-provisioner:lastest


### 5.4 Setup Internal registry and registry storage using EFS

# Cloud Pak for Data Deployment













  



  





  

     

  

  
