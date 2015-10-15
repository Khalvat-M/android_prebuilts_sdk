#
# Copyright (C) 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

LOCAL_PATH:= $(call my-dir)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := jack-admin
LOCAL_SRC_FILES := jack-admin
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(HOST_EXECUTABLE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := jack-admin$(HOST_EXECUTABLE_SUFFIX)
LOCAL_IS_HOST_MODULE := true

include $(BUILD_PREBUILT)
jack_admin_script := $(LOCAL_INSTALLED_MODULE)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := jack-launcher
LOCAL_SRC_FILES := jack-launcher.jar
LOCAL_MODULE_CLASS := JAVA_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := jack-launcher$(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_IS_HOST_MODULE := true

include $(BUILD_PREBUILT)
jack_launcher_jar := $(LOCAL_INSTALLED_MODULE)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := jack-server
jack_server_version := 4.1.ALPHA
LOCAL_SRC_FILES := jack-server-$(jack_server_version).jar
LOCAL_MODULE_CLASS := JAVA_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := jack-launcher$(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_IS_HOST_MODULE := true

include $(BUILD_PREBUILT)
jack_server_jar := $(LOCAL_INSTALLED_MODULE)

##################################
include $(CLEAR_VARS)

#
# This is only for jack used as a library, this is not involved in the normal
# dex build targets.
#
LOCAL_MODULE := jack
LOCAL_SRC_FILES := jacks/jack-$(JACK_STABLE_VERSION).jar
LOCAL_MODULE_CLASS := JAVA_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := jack$(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_IS_HOST_MODULE := true

include $(BUILD_PREBUILT)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := jack
LOCAL_SRC_FILES := jack
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(HOST_EXECUTABLE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := jack$(HOST_EXECUTABLE_SUFFIX)
LOCAL_IS_HOST_MODULE := true

available_jack_jars := $(wildcard $(LOCAL_PATH)/jacks/jack-*.jar)

include $(BUILD_SYSTEM)/base_rules.mk

ifneq ($(ANDROID_JACK_VM_ARGS),)
jack_vm_args := $(ANDROID_JACK_VM_ARGS)
else
jack_vm_args := -Dfile.encoding=UTF-8 -XX:+TieredCompilation
endif

$(LOCAL_BUILT_MODULE): $(LOCAL_PATH)/jack $(jack_launcher_jar) $(jack_server_jar) $(jack_admin_script) $(available_jack_jars) | $(ACP)
	@echo "Build: $@"
	$(hide) $(jack_admin_script) stop-server 2>&1 || (exit 0)
	$(hide) sleep 10
ifneq ($(dist_goal),)
	$(hide) $(jack_admin_script) uninstall-server 2>&1 || (exit 0)
endif
	$(hide) $(jack_admin_script) install-server $(jack_launcher_jar) $(jack_server_jar)  2>&1 || (exit 0)
ifneq ($(dist_goal),)
	mkdir -p "$(DIST_DIR)/logs/jack/"
	$(hide) JACK_SERVER_VM_ARGUMENTS="$(jack_vm_args) -Dcom.android.jack.server.log.file=$(abspath $(DIST_DIR))/logs/jack/jack-server-%u-%g.log" $(jack_admin_script) start-server 2>&1 || exit 0
else
	$(hide) JACK_SERVER_VM_ARGUMENTS="$(jack_vm_args)" $(jack_admin_script) start-server 2>&1 || exit 0
endif
	$(hide) $(jack_admin_script) update server $(jack_server_jar) $(jack_server_version) 2>&1 || exit 0
	$(hide) $(foreach jack_jar,$(available_jack_jars),$(jack_admin_script) update jack $(jack_jar) $(patsubst $(PRIVATE_PATH)/jacks/jack-%.jar,%,$(jack_jar)) || exit 47;)
	$(copy-file-to-target)

##################################
include $(CLEAR_VARS)
LOCAL_MODULE := jill
LOCAL_SRC_FILES := jill.jar
LOCAL_MODULE_CLASS := JAVA_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := jill$(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_IS_HOST_MODULE := true

include $(BUILD_PREBUILT)

ifneq (,$(TARGET_BUILD_APPS)$(filter true,$(TARGET_BUILD_PDK)))

##################################
include $(CLEAR_VARS)

# We can't simple call $(BUILD_PREBUILT) here, because $(ACP) is not
# available yet..

LOCAL_MODULE := acp
LOCAL_IS_HOST_MODULE := true
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional

$(ACP): $(LOCAL_PATH)/$(HOST_OS)/bin/acp$(HOST_EXECUTABLE_SUFFIX)
	@echo "Copy: acp ($@)"
	$(copy-file-to-target-with-cp)
	$(hide) chmod 755 $@

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := aidl
LOCAL_SRC_FILES := $(HOST_OS)/bin/aidl$(HOST_EXECUTABLE_SUFFIX)
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(HOST_EXECUTABLE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := aidl$(HOST_EXECUTABLE_SUFFIX)
LOCAL_IS_HOST_MODULE := true
LOCAL_SHARED_LIBRARIES := libc++
LOCAL_MULTILIB := 32

include $(BUILD_PREBUILT)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := aapt
LOCAL_SRC_FILES := $(HOST_OS)/bin/aapt$(HOST_EXECUTABLE_SUFFIX)
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(HOST_EXECUTABLE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := aapt$(HOST_EXECUTABLE_SUFFIX)
LOCAL_IS_HOST_MODULE := true
LOCAL_SHARED_LIBRARIES := libc++
LOCAL_MULTILIB := 32

include $(BUILD_PREBUILT)

##################################

include $(CLEAR_VARS)

LOCAL_MODULE := zipalign
LOCAL_SRC_FILES := $(HOST_OS)/bin/zipalign$(HOST_EXECUTABLE_SUFFIX)
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(HOST_EXECUTABLE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := zipalign$(HOST_EXECUTABLE_SUFFIX)
LOCAL_IS_HOST_MODULE := true
LOCAL_SHARED_LIBRARIES := libc++
LOCAL_MULTILIB := 32

include $(BUILD_PREBUILT)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := signapk
LOCAL_SRC_FILES := lib/signapk.jar
LOCAL_MODULE_CLASS := JAVA_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := signapk$(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_IS_HOST_MODULE := true

include $(BUILD_PREBUILT)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := dx
LOCAL_SRC_FILES := lib/dx.jar
LOCAL_MODULE_CLASS := JAVA_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := dx$(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_IS_HOST_MODULE := true

include $(BUILD_PREBUILT)

##################################
include $(CLEAR_VARS)

# We have to call copy-file-to-new-target instead of simply including
# $(BUILD_PREBUILT) here, because we must put dx.jar as dependecy of dx.

LOCAL_MODULE := dx
LOCAL_IS_HOST_MODULE := true
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional

include $(BUILD_SYSTEM)/base_rules.mk

$(LOCAL_BUILT_MODULE): $(HOST_OUT_JAVA_LIBRARIES)/dx$(COMMON_JAVA_PACKAGE_SUFFIX)
$(LOCAL_BUILT_MODULE): $(LOCAL_PATH)/dx | $(ACP)
	@echo "Copy: $(PRIVATE_MODULE) ($@)"
	$(copy-file-to-new-target)
	$(hide) chmod 755 $@

##################################
include $(CLEAR_VARS)

# We have to call copy-file-to-new-target instead of simply including
# $(BUILD_PREBUILT) here, because we must put dx.jar, shrinkedAndroid.jar and mainDexClasses.rules
# as dependecy of mainDexClasses.

LOCAL_MODULE := mainDexClasses
LOCAL_IS_HOST_MODULE := true
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional

include $(BUILD_SYSTEM)/base_rules.mk

$(LOCAL_BUILT_MODULE): $(HOST_OUT_JAVA_LIBRARIES)/dx$(COMMON_JAVA_PACKAGE_SUFFIX)
$(LOCAL_BUILT_MODULE): $(HOST_OUT_JAVA_LIBRARIES)/shrinkedAndroid$(COMMON_JAVA_PACKAGE_SUFFIX)
$(LOCAL_BUILT_MODULE): $(HOST_OUT_EXECUTABLES)/mainDexClasses.rules
$(LOCAL_BUILT_MODULE): $(LOCAL_PATH)/mainDexClasses | $(ACP)
	@echo "Copy: $(PRIVATE_MODULE) ($@)"
	$(copy-file-to-new-target)
	$(hide) chmod 755 $@

##################################

include $(CLEAR_VARS)

LOCAL_MODULE := mainDexClasses.rules
LOCAL_SRC_FILES := mainDexClasses.rules
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX :=
LOCAL_BUILT_MODULE_STEM := mainDexClasses.rules
LOCAL_IS_HOST_MODULE := true

include $(BUILD_PREBUILT)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := shrinkedAndroid
LOCAL_SRC_FILES := lib/shrinkedAndroid.jar
LOCAL_MODULE_CLASS := JAVA_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := dx$(COMMON_JAVA_PACKAGE_SUFFIX)
LOCAL_IS_HOST_MODULE := true

include $(BUILD_PREBUILT)

##################################

endif # TARGET_BUILD_APPS or TARGET_BUILD_PDK

# Only use these prebuilts in unbundled branches
# Don't use prebuilts in PDK

ifneq (,$(TARGET_BUILD_APPS))

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := llvm-rs-cc
LOCAL_SRC_FILES := $(HOST_OS)/bin/llvm-rs-cc$(HOST_EXECUTABLE_SUFFIX)
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional
LOCAL_SHARED_LIBRARIES := libLLVM libclang libc++
LOCAL_MODULE_SUFFIX := $(HOST_EXECUTABLE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := llvm-rs-cc$(HOST_EXECUTABLE_SUFFIX)
LOCAL_IS_HOST_MODULE := true
LOCAL_MULTILIB := 64

include $(BUILD_PREBUILT)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := bcc_compat
LOCAL_SRC_FILES := $(HOST_OS)/bin/$(LOCAL_MODULE)$(HOST_EXECUTABLE_SUFFIX)
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_MODULE_TAGS := optional
LOCAL_SHARED_LIBRARIES := libbcc libbcinfo
LOCAL_MODULE_SUFFIX := $(HOST_EXECUTABLE_SUFFIX)
LOCAL_BUILT_MODULE_STEM := $(LOCAL_MODULE)$(HOST_EXECUTABLE_SUFFIX)
LOCAL_IS_HOST_MODULE := true
LOCAL_MULTILIB := 64

include $(BUILD_PREBUILT)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := libbcc
LOCAL_SRC_FILES := $(HOST_OS)/lib64/$(LOCAL_MODULE)$(HOST_SHLIB_SUFFIX)
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(HOST_SHLIB_SUFFIX)
LOCAL_IS_HOST_MODULE := true
LOCAL_MULTILIB := 64

include $(BUILD_PREBUILT)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := libbcinfo
LOCAL_SRC_FILES := $(HOST_OS)/lib64/$(LOCAL_MODULE)$(HOST_SHLIB_SUFFIX)
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(HOST_SHLIB_SUFFIX)
LOCAL_IS_HOST_MODULE := true
LOCAL_MULTILIB := 64

include $(BUILD_PREBUILT)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := libc++
LOCAL_SRC_FILES_64 := $(HOST_OS)/lib64/$(LOCAL_MODULE)$(HOST_SHLIB_SUFFIX)
LOCAL_SRC_FILES_32 := $(HOST_OS)/lib/$(LOCAL_MODULE)$(HOST_SHLIB_SUFFIX)
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(HOST_SHLIB_SUFFIX)
LOCAL_IS_HOST_MODULE := true
LOCAL_MULTILIB := both

include $(BUILD_PREBUILT)

##################################

endif # TARGET_BUILD_APPS only

# Only build Clang/LLVM components when forced to.
ifneq (true,$(FORCE_BUILD_LLVM_COMPONENTS))

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := libLLVM
LOCAL_SRC_FILES := $(HOST_OS)/lib64/$(LOCAL_MODULE)$(HOST_SHLIB_SUFFIX)
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(HOST_SHLIB_SUFFIX)
LOCAL_IS_HOST_MODULE := true
LOCAL_MULTILIB := 64

include $(BUILD_PREBUILT)

##################################
include $(CLEAR_VARS)

LOCAL_MODULE := libclang
LOCAL_SRC_FILES := $(HOST_OS)/lib64/$(LOCAL_MODULE)$(HOST_SHLIB_SUFFIX)
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_SUFFIX := $(HOST_SHLIB_SUFFIX)
LOCAL_IS_HOST_MODULE := true
LOCAL_MULTILIB := 64

include $(BUILD_PREBUILT)

endif #!FORCE_BUILD_LLVM_COMPONENTS
