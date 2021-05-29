!/bin/bash


set -e
PORTABLE_REGISTRY_USER=admin
PORTABLE_REGISTRY_PASS=admin
PORTABLE_REGISTRY_URL='localhost:5000'

# Get all images
images=`curl -k -u $PORTABLE_REGISTRY_USER:$PORTABLE_REGISTRY_PASS https://${PORTABLE_REGISTRY_URL}/v2/_catalog?n=10000 | jq .repositories[]`


for image in $images; do
    echo "DELETING: " $image

    # get tag list of image
    tags=$(curl --user $PORTABLE_REGISTRY_USER:$PORTABLE_REGISTRY_PASS "https://${registry}/v2/${image}/tags/list" | jq -r '.tags // [] | .[]' | tr '\n' ' ')

    # check for empty tag list
    if [[ -n $tags ]]
    then
        for tag in $tags; do
            curl --user $PORTABLE_REGISTRY_USER:$PORTABLE_REGISTRY_PASS -X DELETE "https://${PORTABLE_REGISTRY_URL}/v2/${image}/manifests/$(
                curl --user $PORTABLE_REGISTRY_USER:$PORTABLE_REGISTRY_PASS -I \
                    -H "Accept: application/vnd.docker.distribution.manifest.v2+json" \
                    "https://${PORTABLE_REGISTRY_URL}/v2/${image}/manifests/${tag}" \
                | awk '$1 == "docker-content-digest:" { print $2 }' \
                | tr -d $'\r' \
            )"
        done

        echo "DONE:" $image
    else
        echo "SKIP:" $image
    fi
done
