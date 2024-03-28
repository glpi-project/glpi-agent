
# DLL versioning to be defined on gmake commandline
MAJOR = 0
MINOR = 0
REV   = 0

SHAREDLIB = ca.dll

PREFIX =
CC = $(PREFIX)gcc
CFLAGS = -O3 -Wall -D__STRSAFE__NO_INLINE

LD = $(CC)
LDFLAGS = -static -Wl,--subsystem,windows -lmsi -lstdc++

RC = $(PREFIX)windres
RCFLAGS = --define MAJOR=$(MAJOR) --define MINOR=$(MINOR) --define REVISION=$(REV)

STRIP = $(PREFIX)strip

RM = rm -f

OBJS = dllmain.o log.o customaction.o

all: $(SHAREDLIB)

$(SHAREDLIB): dll/ca.def $(OBJS) ca.rc.o
	$(LD) -shared -o $@ dll/ca.def $(OBJS) ca.rc.o $(LDFLAGS)
	$(STRIP) $@

ca.rc.o: dll/ca.rc dll/$(SHAREDLIB).manifest
	$(RC) $(RCFLAGS) -o $@ dll/ca.rc

$(OBJS): %.o:dll/%.cpp dll/customaction.h
	$(CC) $(CFLAGS) -c -o $@ $<

.PHONY: clean

clean:
	-$(RM) $(SHAREDLIB)
	-$(RM) *.o
