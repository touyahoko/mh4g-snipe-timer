#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

NAME := mh4g_timer
DESCRIPTION := MH4G Snipe Auto A Timer
APP_TITLE := MH4G SnipeAutoA
APP_DESCRIPTION := Automatic A button press for MH4G talisman sniping
APP_AUTHOR := User

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH := -march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft

CFLAGS := -g -Wall -O2 -mword-relocations -ffunction-sections -fdata-sections \
          $(ARCH) $(INCLUDE) -D__3DS__ -DARM11

CFLAGS += $(LIBCITRO3D_INCLUDE) $(LIBCTRU_INCLUDE)
CXXFLAGS := $(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11

ASFLAGS := -g $(ARCH)

LDFLAGS = -specs=3dsx.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

LIBS := -lctru -lcitro3d -lm

#---------------------------------------------------------------------------------
# list of directories containing libraries
#---------------------------------------------------------------------------------
LIBDIRS := $(CTRULIB) $(LIBCITRO3D)

#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT := $(CURDIR)/$(NAME)
export TOPDIR := $(CURDIR)

export VPATH := $(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
                $(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR := $(CURDIR)/$(BUILD)

CFILES := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
BINFILES := $(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

ifeq ($(strip $(CPPFILES)),)
    export LD := $(CC)
else
    export LD := $(CXX)
endif

export OFILES_BIN := $(addsuffix .o,$(BINFILES))
export OFILES_SRC := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES := $(OFILES_BIN) $(OFILES_SRC)
export HFILES := $(addsuffix .h,$(subst .,_,$(BINFILES)))

export INCLUDE := $(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
                  $(foreach dir,$(LIBDIRS),-I$(dir)/include) \
                  -I$(CURDIR)/$(BUILD)

.PHONY: $(BUILD) clean all

all: $(BUILD)

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).3dsx $(OUTPUT).3dsx $(TARGET).elf $(OUTPUT).elf

else
.PHONY: all

DEPENDS := $(OFILES:.o=.d)

all : $(OUTPUT).3dsx

$(OUTPUT).3dsx : $(OUTPUT).elf
$(OUTPUT).elf : $(OFILES)

$(OFILES_SRC) : $(HFILES)

%.bin.o %_bin.h : %.bin
	@echo $(notdir $<)
	@$(bin2o)

define shader-as
	$(CC) -x assembler-with-cpp -MMD -MP -MF $(DEPSDIR)/$*.d -MT $*.o -I$(CTRULIB)/include -I$(LIBCITRO3D)/include -c -o $*.o $*
endef

%.shbin.o %.shbin.h : %.vsh
	@echo $(notdir $<)
	@python $(SHADER_MINIFIER) $< -o $*.min.vsh
	@$(shader-as)
	@python $(SHADER_MINIFIER) $< -o $*.min.gsh
	@$(shader-as)

-include $(DEPENDS)

endif
#---------------------------------------------------------------------------------
