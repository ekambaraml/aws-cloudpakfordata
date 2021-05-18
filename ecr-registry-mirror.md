
##  Setup Registry mirror using AWS ECR 



1. Create ECR registry

```
# aws ecr create-repository --repository-name <cxregistry>
```

2. Prepare your credential to access the ECR repository (ie the credential only valid for 12 hrs)

    ```
    aws ecr get-login
    ```

    Put that into your pull secret:
    
    ```
    podman login –u AWS –p <ecr token> 545108014977.dkr.ecr.ca-central-1.amazonaws.com --authfile=redhat-pullsecret.json
    ```
    
 3. Mirror quay.io and other OpenShift source into your repository

    ```
    export OCP_RELEASE="4.6.27-x86_64"
    export LOCAL_REGISTRY='545108014977.dkr.ecr.ca-central-1.amazonaws.com'
    export LOCAL_REPOSITORY='cxregistry'
    export PRODUCT_REPO='openshift-release-dev'
    export LOCAL_SECRET_JSON='/data/redhat_pull_secret.json'
    export RELEASE_NAME="ocp-release"

    oc adm -a ${LOCAL_SECRET_JSON} release mirror --max-per-registry=1 \
       --from=quay.io/${PRODUCT_REPO}/${RELEASE_NAME}:${OCP_RELEASE} \
       --to=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY} \
       --to-release-image=${LOCAL_REGISTRY}/${LOCAL_REPOSITORY}:${OCP_RELEASE}
    ```
    
 4. To use the new mirrored repository to install, add the following section to the install-config.yaml:
```
imageContentSources:
- mirrors:
  - 545108014977.dkr.ecr.ca-central-1.amazonaws.com/cxregistry
  source: quay.io/openshift-release-dev/ocp-release
- mirrors:
  - 545108014977.dkr.ecr.ca-central-1.amazonaws.com/cxregistry
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
  
 ```

5. To use the new mirrored repository for upgrades, use the following to create an ImageContentSourcePolicy:
 
```
 apiVersion: operator.openshift.io/v1alpha1
kind: ImageContentSourcePolicy
metadata:
  name: example
spec:
  repositoryDigestMirrors:
  - mirrors:
    - 545108014977.dkr.ecr.ca-central-1.amazonaws.com/cxregistry
    source: quay.io/openshift-release-dev/ocp-release
  - mirrors:
    - 545108014977.dkr.ecr.ca-central-1.amazonaws.com/cxregistry
    source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
```
