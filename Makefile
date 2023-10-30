export TARGET = iphone:clang:16.2:14.0
export ARCHS = arm64

export libcolorpicker_ARCHS = arm64
export libFLEX_ARCHS = arm64
export Alderis_XCODEOPTS = LD_DYLIB_INSTALL_NAME=@rpath/Alderis.framework/Alderis
export ADDITIONAL_CFLAGS = -I$(THEOS_PROJECT_DIR)/Tweaks/RemoteLog

ifneq ($(MAKECMDGOALS),clean)
  ifndef UYOUPLUS_VERSION
    $(error UYOUPLUS_VERSION not set, please set it to the version of uYouPlus)
  endif
  ifneq ($(JAILBROKEN),1)
    ifndef YOUTUBE_VERSION
      $(error YOUTUBE_VERSION not set, please set it to match the version of the YouTube IPA)
    endif
    ifndef UYOU_VERSION
      $(error UYOU_VERSION not set, please set it to the version of uYou to download)
    endif
    MODULES = jailed
    PACKAGE_VERSION = $(YOUTUBE_VERSION)-$(UYOU_VERSION)-$(UYOUPLUS_VERSION)
  else
    PACKAGE_VERSION = $(UYOUPLUS_VERSION)
  endif
endif

INSTALL_TARGET_PROCESSES = YouTube
TWEAK_NAME = uYouPlus

$(TWEAK_NAME)_FILES = uYouPlus.xm Settings.xm $(shell find Source -name '*.xm' -o -name '*.x' -o -name '*.m')
$(TWEAK_NAME)_FRAMEWORKS = UIKit Security
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -DTWEAK_VERSION=\"$(PACKAGE_VERSION)\"
$(TWEAK_NAME)_INJECT_DYLIBS = Tweaks/uYou/Library/MobileSubstrate/DynamicLibraries/uYou.dylib $(THEOS_OBJ_DIR)/libFLEX.dylib $(THEOS_OBJ_DIR)/iSponsorBlock.dylib $(THEOS_OBJ_DIR)/YouPiP.dylib $(THEOS_OBJ_DIR)/YouTubeDislikesReturn.dylib $(THEOS_OBJ_DIR)/YTABConfig.dylib $(THEOS_OBJ_DIR)/YTUHD.dylib $(THEOS_OBJ_DIR)/DontEatMyContent.dylib $(THEOS_OBJ_DIR)/YTVideoOverlay.dylib $(THEOS_OBJ_DIR)/YouMute.dylib $(THEOS_OBJ_DIR)/YouQuality.dylib
$(TWEAK_NAME)_EMBED_LIBRARIES = $(THEOS_OBJ_DIR)/libcolorpicker.dylib
$(TWEAK_NAME)_EMBED_BUNDLES = $(wildcard Bundles/*.bundle)
$(TWEAK_NAME)_EMBED_EXTENSIONS = $(wildcard Extensions/*.appex)

include $(THEOS)/makefiles/common.mk

ifneq ($(_THEOS_PLATFORM_HAS_XCODE),1)
  ifneq ($(JAILBROKEN),1)
    $(error IPAs can only be compiled on macOS with Xcode installed)
  endif
  $(TWEAK_NAME)_FILES += Version.x
else
  _ALDERIS_XCODE_INSTALL_DIR = $(_THEOS_LOCAL_DATA_DIR)/$(THEOS_OBJ_DIR_NAME)/install_Alderis$(if $(_THEOS_FINAL_PACKAGE),.xcarchive)$(if $(_THEOS_FINAL_PACKAGE),/Products)
  export _THEOS_INTERNAL_COLORFLAGS += -L$(THEOS_OBJ_DIR) -F$(_ALDERIS_XCODE_INSTALL_DIR)/Library/Frameworks
  $(TWEAK_NAME)_EMBED_FRAMEWORKS += $(_ALDERIS_XCODE_INSTALL_DIR)/Library/Frameworks/Alderis.framework
endif

ifneq ($(JAILBROKEN),1)
  SUBPROJECTS += Tweaks/Alderis Tweaks/FLEXing/libflex Tweaks/iSponsorBlock Tweaks/Return-YouTube-Dislikes Tweaks/YouPiP Tweaks/YTABConfig Tweaks/YTUHD Tweaks/DontEatMyContent Tweaks/YTVideoOverlay Tweaks/YouMute Tweaks/YouQuality
  include $(THEOS_MAKE_PATH)/aggregate.mk
endif
include $(THEOS_MAKE_PATH)/tweak.mk

REMOVE_EXTENSIONS = 1
CODESIGN_IPA = 0

UYOU_PATH = Tweaks/uYou
UYOU_DEB = $(UYOU_PATH)/com.miro.uyou_$(UYOU_VERSION)_iphoneos-arm.deb
UYOU_DYLIB = $(UYOU_PATH)/Library/MobileSubstrate/DynamicLibraries/uYou.dylib
UYOU_BUNDLE = $(UYOU_PATH)/Library/Application\ Support/uYouBundle.bundle

internal-clean::
	@rm -rf $(UYOU_PATH)/*

ifneq ($(JAILBROKEN),1)
before-all::
	@if [[ ! -f $(UYOU_DEB) ]]; then \
		rm -rf $(UYOU_PATH)/*; \
		$(PRINT_FORMAT_BLUE) "Downloading uYou"; \
	fi
before-all::
	@if [[ ! -f $(UYOU_DEB) ]]; then \
 		curl -s https://miro92.com/repo/debs/com.miro.uyou_$(UYOU_VERSION)_iphoneos-arm.deb -o $(UYOU_DEB); \
 	fi; \
	if [[ ! -f $(UYOU_DYLIB) || ! -d $(UYOU_BUNDLE) ]]; then \
		tar -xf $(UYOU_DEB) -C $(UYOU_PATH); tar -xf $(UYOU_PATH)/data.tar* -C $(UYOU_PATH); \
		if [[ ! -f $(UYOU_DYLIB) || ! -d $(UYOU_BUNDLE) ]]; then \
			$(PRINT_FORMAT_ERROR) "Failed to extract uYou"; exit 1; \
		fi; \
	fi;
else
before-package::
	@mkdir -p $(THEOS_STAGING_DIR)/Library/Application\ Support; cp -r lang/uYouPlus.bundle $(THEOS_STAGING_DIR)/Library/Application\ Support/
endif
