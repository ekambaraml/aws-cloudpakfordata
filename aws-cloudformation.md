# Deploying OpenShift on user-provisioned infrastructure using AWS Cloudformation templates




### 2.0 Creating OpenShift Install configurations

#### 2.1 Creating the installation files for AWS

```
mkdir clusterconfig
./openshift-install create manifests --dir clusterconfig

openshift-install create ignition-configs --dir clusterconfig
ls clusterconfig
auth bootstrap.ign master.ign metadata.json worker.ign
```

#### 2.2 Creating the installation configuration file

mkdir clusterinstall
./openshift-install create install-config --dir=clusterinstall

; provide input for the prompts

mkdir backup
cp clusterinstall/install-config.yaml backup

#### 2.3 Creating the Kubernetes manifest and Ignition config files
./openshift-install create manifests --dir=clusterinstall

```
By removing these files, you prevent the cluster from automatically generating control plane
machines and workers. We will be using cloudformation template to create them

Re(move) the files
mv clusterinstall/openshift/99_openshift-cluster-api_master-machines-*.yaml backup
mv clusterinstall/openshift/99_openshift-cluster-api_worker-machineset-*.yaml backup
mv clusterinstall/openshift/99_openshift-cluster-api_worker-machineset-*.yaml backup
```

#### 2.4 Check that the mastersSchedulable

In the <installation_directory>/manifests/cluster-scheduler-02-config.yml mastersSchedulable parameter and ensure that it is set to false.

#### 2.5 DNS records

If you remove the file, then you must add ingress DNS records manually in a later step.
```
mv <installation_directory>/manifests/cluster-dns-02-config.yml backup
```

#### 2.6 Create Ignition files
 ./openshift-install create ignition-configs --dir=clusterinstall 
 ```
 The following files are generated in the directory:
.
├── auth
│ ├── kubeadmin-password
│ └── kubeconfig
├── bootstrap.ign
├── master.ign
├── metadata.json
└── worker.ign
```
#### 2.7 Extract Infrastructure name

```
 jq -r .infraID <installation_directory>/metadata.json 
```
 openshift-vw9j6
 
 
 ### 3.0 User created Infrastructures
 
 
#### 3.1 Creating VPC

- [ ] update the vpc.param.json with cidr, number availability zones, subnet size
- [ ] Run the cloudformation template
```
aws cloudformation create-stack --stack-name cluster-vpc --template-body  file://vpc.template.yaml --parameters file://vpc.param.json
aws cloudformation describe-stacks --stack-name cluster-vpc
```

#### 3.2 Creating networking and load balancing components in AWS

- [ ] Obtain hosted zone id
```
aws route53 list-hosted-zones-by-name --dns-name 
```


```
aws cloudformation create-stack --stack-name 





