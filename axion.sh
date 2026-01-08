#!/bin/bash

#script by https://github.com/Joe7500/build-scripts/ thanks :)

source /home/admin/.profile
source /home/admin/.bashrc
source /tmp/crave_bashrc



# Template helper variables
PACKAGE_NAME=axion
VARIANT_NAME=user
BUILD_TYPE='gms pico'
REPO_URL="-u https://github.com/AxionAOSP/android.git -b lineage-23.1 --git-lfs"

# Random template helper stuff
export BUILD_USERNAME=user
export BUILD_HOSTNAME=localhost 
export KBUILD_BUILD_USER=user
export KBUILD_BUILD_HOST=localhost
SECONDS=0
TG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"

# Send push notifications
notify_send() {
   local MSG
   MSG="$@"
   curl -s -X POST $TG_URL -d chat_id=$TG_CID -d text="$MSG" > /dev/null 2>&1
}

notify_send "Build $PACKAGE_NAME on crave.io started."

# Always cleanup
cleanup_self () {
   rm -rf vendor/lineage-priv/keys vendor/lineage-priv priv-keys .config/b2/ /home/admin/.config/b2/
   rm -rf /tmp/android-certs* /home/admin/venv/
   rm -rf .repo/local_manifests/
   rm -rf prebuilts/clang/host/linux-x86
   rm -rf external/chromium-webview/
}

# Better than ' || exit 1 '
check_fail () {
   if [ $? -ne 0 ]; then 
       if ls out/target/product/equuleus/$PACKAGE_NAME*.zip; then
          notify_send "Build $PACKAGE_NAME on crave.io softfailed."
          echo weird. build failed but OTA package exists.
          echo softfail > result.txt
          cleanup_self
          exit 1
       else
          notify_send "Build $PACKAGE_NAME on crave.io failed."
          echo "oh no. script failed"
          curl -L -F document=@"out/error.log" -F caption="error log" -F chat_id="$TG_CID" -X POST https://api.telegram.org/bot$TG_TOKEN/sendDocument > /dev/null 2>&1
          cleanup_self
          echo fail > result.txt
          exit 1 
       fi
   fi
}

# repo sync
repo init $REPO_URL  ; check_fail
cleanup_self
curl -L --create-dirs https://raw.githubusercontent.com/cookire/equuleus_manifest/refs/heads/main/local_manifest.xml -o .repo/local_manifests/local_manifest.xml
/opt/crave/resync.sh ; check_fail





# Setup
#echo 'AXION_MAINTAINER := J7ohn' >> lineage_equuleus.mk
#echo 'AXION_PROCESSOR := Snapdragon_845' >> lineage_equuleus.mk
#echo 'AXION_CPU_SMALL_CORES := 0,1,2,3' >> lineage_equuleus.mk
#echo 'AXION_CPU_BIG_CORES := 4,5,6,7' >> lineage_equuleus.mk
#echo 'AXION_CAMERA_REAR_INFO := 48' >> lineage_equuleus.mk
#echo 'AXION_CAMERA_FRONT_INFO := 8' >> lineage_equuleus.mk
#echo 'GPU_FREQS_PATH := /sys/class/devfreq/5900000.qcom,kgsl-3d0/available_frequencies' >> lineage_equuleus.mk
#echo 'GPU_MIN_FREQ_PATH := /sys/class/devfreq/5900000.qcom,kgsl-3d0/min_freq' >> lineage_equuleus.mk
#echo 'PERF_ANIM_OVERRIDE := true' >> lineage_equuleus.mk
#echo 'genfscon proc /sys/vm/dirty_writeback_centisecs     u:object_r:proc_dirty:s0' >> sepolicy/vendor/genfs_contexts
#echo 'genfscon proc /sys/vm/vfs_cache_pressure            u:object_r:proc_drop_caches:s0' >> sepolicy/vendor/genfs_contexts
#echo 'genfscon proc /sys/vm/dirty_ratio u:object_r:proc_dirty:s0' >> sepolicy/vendor/genfs_contexts
#echo 'genfscon proc /sys/kernel/sched_migration_cost_ns u:object_r:proc_sched:s0' >> sepolicy/vendor/genfs_contexts
#cat BoardConfig.mk | grep -v TARGET_KERNEL_CLANG_VERSION > BoardConfig.mk.1
#mv BoardConfig.mk.1 BoardConfig.mk
#echo 'TARGET_KERNEL_CLANG_VERSION := stablekern' >> BoardConfig.mk
#cat lineage_equuleus.mk | grep -v TARGET_ENABLE_BLUR > lineage_equuleus.mk.1
#mv lineage_equuleus.mk.1 lineage_equuleus.mk
#echo 'TARGET_ENABLE_BLUR := true' >> lineage_equuleus.mk

#echo 'TARGET_INCLUDES_LOS_PREBUILTS := true' >> device/xiaomi/equuleus/lineage_equuleus.mk

#echo 'VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)' >> device/xiaomi/equuleus/BoardConfig.mk

#echo 'persist.sys.perf.scroll_opt=true'  >> device/xiaomi/equuleus/configs/props/system.prop
#echo 'persist.sys.perf.scroll_opt.heavy_app=2'  >> device/xiaomi/equuleus/configs/props/system.prop

echo 'TARGET_DISABLE_EPPE := true' >> device/xiaomi/equuleus/device.mk
echo 'TARGET_DISABLE_EPPE := true' >> device/xiaomi/equuleus/BoardConfig.mk



sleep 10


# axion Usage: axion <device_codename> [user|userdebug|eng] [gms [pico|core] | vanilla]
# ax usage: ax [-b|-fb|-br] [-j<num>] [user|eng|userdebug]
# Build Types: -b Bacon -fb Fastboot -br Brunch
source build/envsetup.sh               ; check_fail
axion equuleus user gms pico               ; check_fail
#mka installclean
ax -b user                             ; check_fail


echo success > result.txt
notify_send "Build $PACKAGE_NAME on crave.io succeeded."

# Upload output to pixeldrain
cp out/target/product/equuleus/$PACKAGE_NAME*.zip .
GO_FILE=`ls --color=never -1tr $PACKAGE_NAME*.zip | tail -1`
GO_FILE_MD5=`md5sum "$GO_FILE"`
GO_FILE=`pwd`/$GO_FILE

curl -T "$GO_FILE" -u :$PDAPIKEY https://pixeldrain.com/api/file/ > out.json
PD_ID=`cat out.json | cut -d '"' -f 4`
notify_send "MD5:$GO_FILE_MD5 https://pixeldrain.com/u/$PD_ID"
rm -f out.json



TIME_TAKEN=`printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60))`
notify_send "Build $PACKAGE_NAME on crave.io completed. $TIME_TAKEN."


cleanup_self
exit 0
