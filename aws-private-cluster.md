# Deploying AWS OpenShift private cluster

OpenShift 4.6, private cluster can be installed into an existing VPC on Amazon Web Services (AWS). The installation program provisions the rest of the required infrastructure, which you can further customize. To customize the installation, you modify parameters in the install-config.yaml file before you install the cluster.

- Private cluster that does not expose external endpoints
- Private clusters are accessible from only internal network and are not visible to the Internet.
- Private cluster sets the DNS, Ingress Controller, and API server to private when you deploy your cluster. This means that the cluster resources are only accessible from your internal network and are not visible to the internet.
- To deploy a private cluster, you must use existing networking that meets your requirements. 

## 1.0 Bastion Host

  Private cluster must be deployed from a machine that has access 
  - the API services for the cloud you provision to, 
  - Hosts on the network that you provision
  - Internet to obtain installation media or Mirror Registry

### Bastion Host Setup
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


## 2.0 Networking Requirements

The installation program does use the baseDomain that you specify to create a private Route 53 zone and the required records for the cluster. The cluster is configured so that the Operators do not create public records for the cluster and all cluster machines are placed in the private subnets that you specify.


- **Not Required**
  * Public subnets
  * Public load balancers, which support public ingress
  * A public Route 53 zone that matches the baseDomain for the cluster
  
- **Required**

  The installation program will not create the following components, But it is users responsibility to pre-create them before deploying the cluster.
  * baseDomain (example.com)
  * Internet gateways
  * NAT gateways
  * Subnets
  * Route tables
  * VPCs
  * VPC DHCP options
  * VPC endpoints

- **AirGap/Disconnected network**

  If you are working in a disconnected environment, you are unable to reach the public IP addresses for EC2 and ELB endpoints. To resolve this, you must create a VPC endpoint and attach it to the subnet that the clusters are using. The endpoints should be named as follows:
  * ec2.<region>.amazonaws.com
  * elasticloadbalancing.<region>.amazonaws.com
  * s3.<region>.amazonaws.com

## 3.0 OpenShift Cluster

AWS credentials that you use when you create your cluster do not need the networking permissions that are required to make VPCs and core networking components within the VPC, such as subnets, routing tables, Internet gateways, NAT, and VPN. 

**You still need permission to make the application resources that the machines within the cluster require, such as ELBs, security groups, S3 buckets, and nodes**.

## 4.0 Deploying the cluster

### 4.1 Generating an SSH private key and adding it to the agent

Key to SSH into the master nodes as the user core. When you deploy the cluster, the key is added to the core user’s ~/.ssh/authorized_keys list

```
ssh-keygen
eval "$(ssh-agent -s)"
ssh-add
```

### 4.2 Downloading openshift install files

Refer section 1.0

### 4.3 Creating the installation configuration file


```
./openshift-install create install-config --dir=./ocpconfig
```
Update the install-config with your custom network details

```
apiVersion: v1
baseDomain: ibmcp4d.com
credentialsMode: Mint
imageContentSources:
- mirrors:
  - ip-172-31-31-246.ca-central-1.compute.internal:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ip-172-31-31-246.ca-central-1.compute.internal:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
compute:
- architecture: amd64
  hyperthreading: Enabled
  name: worker
  platform:
    aws:
      rootVolume:
        iops: 2000
        size: 500
        type: io1 
      type: m5.4xlarge
      zones:
      - ca-central-1a
      - ca-central-1b
  replicas: 3
controlPlane:
  architecture: amd64
  hyperthreading: Enabled
  name: master
  platform: 
    aws:
      zones:
      - ca-central-1a
      - ca-central-1b
      rootVolume:
        iops: 4000
        size: 500
        type: io1 
      type: m5.xlarge
  replicas: 3
metadata:
  name: cxcbsa
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14
    hostPrefix: 23
  machineNetwork:
  - cidr: 175.1.1.0/24
  - cidr: 175.1.2.0/24

  networkType: OpenShiftSDN
  serviceNetwork:
  - 172.30.0.0/16
platform:
  aws:
    region: ca-central-1
    userTags:
      adminContact: cx-docker-admins
    subnets:
    - subnet-005e3317a91060135
    - subnet-0f476ff45e891d8c0
    amiID: ami-012518cdbd3057dfd
fips: true
publish: Internal
pullSecret: ''
sshKey: 
```

## 4.4 Create Manifest

copy install-config.yaml tp clusterconfig directory and run the command
```
openshift-install create manifests --dir clusterconfig
```

## 4.5 Create Cluster
```
 ./openshift-install create manifests --dir clusterconfig --log-level=debug
```

