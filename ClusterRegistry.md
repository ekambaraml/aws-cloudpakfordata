# Cluster Registry Setup

1. Internal cluster registry setup using s3 storage

```
oc edit configs.imageregistry.operator.openshift.io/cluster

storage:
    managementState: Managed
    s3:
      bucket: cxcbsa-dd9zx-image-registry-ca-central-1-nhuhgqldbjseudwkfxdme
      encrypt: true
      region: ca-central-1
      virtualHostedStyle: false
```


2. How to creat external route to the internal registry

```
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
```

3. Validate the Registry access

```
podman login -u $(oc whoami) -p $(oc whoami -t) $(oc registry info) --tls-verify=false
```
