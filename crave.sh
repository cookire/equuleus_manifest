#!/bin/bash
# crave run --no-patch -- "curl https://raw.githubusercontent.com/cookire/equuleus_manifest/refs/heads/main/crave.sh | bash"

rm -rf .repo/local_manifests/
rm -rf prebuilts/clang/host/linux-x86
rm -rf external/chromium-webview/

# Repo Init
repo init -u https://github.com/crdroidandroid/android.git -b 15.0 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

# Clone local_manifests repository
curl -L --create-dirs https://raw.githubusercontent.com/cookire/equuleus_manifest/refs/heads/main/local_manifest.xml -o .repo/local_manifests/local_manifest.xml
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Sync the repositories
/opt/crave/resync.sh
echo "============="
echo "Sync success"
echo "============="


# Export
export BUILD_USERNAME=j7ohn
export BUILD_HOSTNAME=crave
export TZ="Europe/London"
export TARGET_RELEASE=bp1a
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

# Brunch
brunch equuleus userdebug
echo "============="

cd out/target/product/equuleus/
curl bashupload.com -T *.zip
