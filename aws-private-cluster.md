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

### Prerequisites


