# Create admin user for the OpenShift Cluster

```
#!/bin/bash
# Install htpasswd

yum install -y httpd-tools

# Create a password
htpasswd -cBb htpasswd.txt ocadmin ocadmin

# Create a secret with htpassword
export KUBECONFIG=~/installocp/auth/kubeconfig
oc create secret generic htpass-secret  --from-file=htpasswd=htpasswd.txt -n openshift-config

# Create OAuth object
cat > htpasswd.yaml << EOF
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: local
    mappingMethod: claim
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret
EOF

# Create the object
oc apply -f htpasswd.yaml

# Add admin as cluster-admin
oc adm policy add-cluster-role-to-user cluster-admin ocadmin

```
