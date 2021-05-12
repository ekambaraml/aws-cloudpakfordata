# OpenShift Registry Mirror Setup

Login to Bastion host where the mirror registry to setup for airgap installation

```
; find current hostname
hostname -f

; Install Podman and httpd tools
yum -y install podman httpd-tools

; Installing jq
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq-linux64
sudo cp jq-linux64 /usr/bin/jq
```

### Create SSL certs for mirror Registry
```
mkdir -p /var/lib/libvirt/images/mirror-registry/{auth,certs,data}
openssl req -newkey rsa:4096 -nodes -sha256   -keyout /var/lib/libvirt/images/mirror-registry/certs/domain.key   -x509 -days 365 -subj "/CN=ip-175-1-1-66.ca-central-1.compute.internal" -out /var/lib/libvirt/images/mirror-registry/certs/domain.crt -addext "subjectAltName = DNS:ip-175-1-1-66.ca-central-1.compute.internal"

cp -v /var/lib/libvirt/images/mirror-registry/certs/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust
```
### Create password for mirror registry
```
htpasswd -bBc /var/lib/libvirt/images/mirror-registry/auth/htpasswd admin r3dh4t\!1
```

### Create internal registry service: 

/etc/systemd/system/mirror-registry.service 
Change REGISTRY_HTTP_ADDR in case you use different network


```
cat - > /etc/systemd/system/mirror-registry.service <<EOF
[Unit]
Description=Mirror registry (mirror-registry)
After=network.target

[Service]
Type=simple
TimeoutStartSec=5m


ExecStartPre=-/usr/bin/podman rm "mirror-registry"
ExecStartPre=/usr/bin/podman pull quay.io/redhat-emea-ssa-team/registry:2
ExecStart=/usr/bin/podman run --name mirror-registry --net host \
  -v /var/lib/libvirt/images/mirror-registry/data:/var/lib/registry:z \  
  -v /var/lib/libvirt/images/mirror-registry/auth:/auth:z \
  -e "REGISTRY_AUTH=htpasswd" \
  -e "REGISTRY_HTTP_ADDR=172.31.14.217:5000" \
  -e "REGISTRY_AUTH_HTPASSWD_REALM=registry-realm" \
  -e "REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd" \
  -e "REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=TRUE" \
  -v /var/lib/libvirt/images/mirror-registry/certs:/certs:z \
  -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
  -e REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true \
  quay.io/redhat-emea-ssa-team/registry:2


ExecReload=-/usr/bin/podman stop "mirror-registry"
ExecReload=-/usr/bin/podman rm "mirror-registry"
ExecStop=-/usr/bin/podman stop "mirror-registry"
Restart=alwaysRestartSec=30

[Install]
WantedBy=multi-user.target
EOF
```


### Enable and start mirror registry
```
systemctl enable --now mirror-registry.service
systemctl status mirror-registry.service
systemctl daemon-reload
```

###  Validate registry

```
; Test by pushing sample image
podman login -u admin -p r3dh4t\!1 ip-172-31-14-217.eu-west-2.compute.internal:5000
podman pull busybox
podman tag docker.io/library/busybox:latest ip-172-31-14-217.eu-west-2.compute.internal:5000/busybox:latest
podman push ip-172-31-14-217.eu-west-2.compute.internal:5000/busybox:latest


curl -u admin:r3dh4t\!1  https://ip-172-31-14-217.eu-west-2.compute.internal:5000/v2/_catalog  

{"repositories":["busybox"]}

```

### Create mirror registry pullsecret

```
podman login --authfile mirror-registry-pullsecret.json ip-172-31-14-217.eu-west-2.compute.internal:5000

;; merge pull-secrets
jq -s '{"auths": ( .[0].auths + .[1].auths ) }' mirror-registry-pullsecret.json redhat-pullsecret.json > pullsecret.json

export OCP_RELEASE=$(oc version -o json  --client | jq -r '.releaseClientVersion')
export LOCAL_REGISTRY='ip-172-31-14-217.eu-west-2.compute.internal:5000'
export LOCAL_REPOSITORY='ocp4/openshift4'
export PRODUCT_REPO='openshift-release-dev'
export LOCAL_SECRET_JSON='pullsecret.json'
export RELEASE_NAME="4.6.27"
export ARCHITECTURE=x86_64
export RELEASE_NAME="ocp-release"
oc version -o json  --client | jq -r '.releaseClientVersion'

oc adm -a ${LOCAL_SECRET_JSON} release mirror --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} --dry-run

oc adm -a ${LOCAL_SECRET_JSON} release mirror --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}

;; For certificate issue
GODEBUG=x509ignoreCN=0 oc adm -a ${LOCAL_SECRET_JSON} release mirror --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE}-${ARCHITECTURE} --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE} 
```

 ### Create Installer for Mirror Registry
 ```
 GODEBUG=x509ignoreCN=0 oc adm release extract -a pullsecret.json --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}"

 ./openshift-install version

 ./openshift-install 4.6.27
 built from commit c47fb1296122a601bc578b9251ba1fb3c7dd4fd1
 ```
 
### save the output
 
 ```
 info: Mirroring completed in 56.69s (117.5MB/s)

Success
Update image:  ip-175-1-1-66.ca-central-1.compute.internal:5000/ocp4/openshift4:4.6.27-x86_64
Mirror prefix: ip-175-1-1-66.ca-central-1.compute.internal:5000/ocp4/openshift4

To use the new mirrored repository to install, add the following section to the install-config.yaml:

imageContentSources:
- mirrors:
  - ip-175-1-1-66.ca-central-1.compute.internal:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - ip-175-1-1-66.ca-central-1.compute.internal:5000/ocp4/openshift4
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev


To use the new mirrored repository for upgrades, use the following to create an ImageContentSourcePolicy:

apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: example
spec:
  repositoryDigestMirrors:
  - mirrors:
    - ip-175-1-1-66.ca-central-1.compute.internal:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-release
  - mirrors:
    - ip-175-1-1-66.ca-central-1.compute.internal:5000/ocp4/openshift4
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev

 ```
### Extract openshift-install command
 ```
 oc adm release extract -a pullsecret.json --command=openshift-install "${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}-${ARCHITECTURE}"
```
### Check openshift-install version:
```
$ ./openshift-install version
./openshift-install 4.6.27
built from commit c47fb1296122a601bc578b9251ba1fb3c7dd4fd1
release image ip-175-1-1-66.ca-central-1.compute.internal:5000/ocp4/openshift4@sha256:63545e67cc2af126e289de269ad59940e072af68f4f0cb9c37734f5374afeb60
```
