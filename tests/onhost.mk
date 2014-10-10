ifneq (yes,$(shell which grep >/dev/null 2>&1 && echo yes))
$(error No 'grep' tool found)
endif

ifneq (yes,$(shell which awk >/dev/null 2>&1 && echo yes))
$(error No 'awk' tool found)
endif

define compiler-type
$(strip $(if $(strip $(1)),\
    $(if $(shell $(1) --version 2>/dev/null | grep -iq "\(gcc\|Free Software Foundation\)" && echo yes),\
        gcc,\
        $(if $(shell $(1) --version 2>/dev/null | grep -iq "\(clang\|llvm\)" && echo yes),\
            clang,\
            $(error Can not detect compiler type of '$(1)')\
        )\
    ),\
    $(error Usage: call c++-compiler-type,compiler)\
))
endef

define is-cxx-gcc
$(if $(and $(strip $(CXX)),$(filter gcc,$(call compiler-type,$(CXX)))),yes)
endef

define is-cxx-clang
$(if $(and $(strip $(CXX)),$(filter clang,$(call compiler-type,$(CXX)))),yes)
endef

define gcc-major-version
$(strip $(if $(call is-cxx-gcc),\
    $(shell $(CXX) -dumpversion 2>/dev/null | awk -F. '{print $$1}')\
))
endef

define gcc-minor-version
$(strip $(if $(call is-cxx-gcc),\
    $(shell $(CXX) -dumpversion 2>/dev/null | awk -F. '{print $$2}')\
))
endef

define is-gcc-version
$(and $(filter $(1),$(gcc-major-version)),$(filter $(2),$(gcc-minor-version)))
endef

define std-c++11-switch
$(strip \
    $(if \
        $(and \
            $(call is-cxx-gcc),\
            $(filter 4,$(call gcc-major-version)),\
            $(filter 6,$(call gcc-minor-version))\
        ),\
        -std=c++0x,\
        -std=c++11\
    )\
)
endef

define host-os
$(shell uname -s | tr '[A-Z]' '[a-z]')
endef

define is-host-os-linux
$(if $(filter linux,$(call host-os)),yes)
endef

define is-host-os-darwin
$(if $(filter darwin,$(call host-os)),yes)
endef

CC ?= cc
CXX ?= c++
