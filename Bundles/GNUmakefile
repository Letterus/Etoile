PACKAGE_NAME = Bundles

include $(GNUSTEP_MAKEFILES)/common.make

#
# Variables to turn projects on and off in the build process
# (listed by alphabetical order)
#

-include ../modules.make

export etoilebehavior ?= no
export etoilewildmenus ?= yes
export powermenulet ?= yes
export servicemenulet ?= yes
export volumecontrolmenulet ?= yes

#
# Projects (listed by dependency order, then alphabetical order)
#

ifeq ($(etoilebehavior), yes)
    SUBPROJECTS += EtoileBehavior
endif

ifeq ($(etoilewildmenus), yes)
    SUBPROJECTS += EtoileWildMenus
endif

ifeq ($(powermenulet), yes)
    SUBPROJECTS += PowerMenulet
endif

ifeq ($(servicemenulet), yes)
    SUBPROJECTS += ServiceMenulet
endif

ifeq ($(volumecontrolmenulet), yes)
    SUBPROJECTS += VolumeControlMenulet
endif

include $(GNUSTEP_MAKEFILES)/aggregate.make
