ARCHS = armv7 arm64
include theos/makefiles/common.mk

TWEAK_NAME = SortMyNotes
SortMyNotes_FRAMEWORKS = CoreData UIKit QuartzCore CoreGraphics
SortMyNotes_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileNotes SpringBoard"
