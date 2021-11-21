#!/bin/bash

# DEBUG: list the contents for build directory
ls -l "$HOME/vyos-build/build"

TAR_FILE_NAME="VyOS-$(date '+%Y%m%d').tar.gz"
BUCKET_IMAGE_PATH="gs://$TARGET_BUCKET/$IMAGE_NAME.tar.gz"

## Create a new TAR-GZ file
TAR_DISK_PATH="$HOME/vyos-build/build/$TAR_FILE_NAME"

gsutil cp "$TAR_DISK_PATH" "$BUCKET_IMAGE_PATH"

# Create the image
gcloud compute images create "$IMAGE_NAME" \
    --source-uri=$BUCKET_IMAGE_PATH \
    --family=$TARGET_IMAGE_FAMILY \
    --storage-location=$TARGET_IMAGE_REGION

# Delete OLD storage image
gsutil rm "$BUCKET_IMAGE_PATH"
