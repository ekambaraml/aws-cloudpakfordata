# Deploying AWS OpenShift private cluster

OpenShift 4.6, private cluster can be installed into an existing VPC on Amazon Web Services (AWS). The installation program provisions the rest of the required infrastructure, which you can further customize. To customize the installation, you modify parameters in the install-config.yaml file before you install the cluster.

- Private cluster that does not expose external endpoints
- Private clusters are accessible from only internal network and are not visible to the Internet.
- Private cluster sets the DNS, Ingress Controller, and API server to private when you deploy your cluster. This means that the cluster resources are only accessible from your internal network and are not visible to the internet.
- To deploy a private cluster, you must use existing networking that meets your requirements. 

  **Bastion Host**

  Private cluster must be deployed from a machine that has access 
  - the API services for the cloud you provision to, 
  - Hosts on the network that you provision
  - Internet to obtain installation media or Mirror Registry

## 1.0 Networking Requirements

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

## 2.0 OpenShift Cluster

AWS credentials that you use when you create your cluster do not need the networking permissions that are required to make VPCs and core networking components within the VPC, such as subnets, routing tables, Internet gateways, NAT, and VPN. 

**You still need permission to make the application resources that the machines within the cluster require, such as ELBs, security groups, S3 buckets, and nodes**.

## 3.0 Deploying the cluster

### 3.1 Generating an SSH private key and adding it to the agent

Key to SSH into the master nodes as the user core. When you deploy the cluster, the key is added to the core user’s ~/.ssh/authorized_keys list

```
ssh-keygen
eval "$(ssh-agent -s)"
ssh-add
```

### 3.2 Downloading openshift install files

### 3.3 Creating the installation configuration file


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

## Create Manifest

copy install-config.yaml tp clusterconfig directory and run the command
```
openshift-install create manifests --dir clusterconfig
```

## Create Cluster
```
 ./openshift-install create manifests --dir clusterconfig --log-level=debug
```

