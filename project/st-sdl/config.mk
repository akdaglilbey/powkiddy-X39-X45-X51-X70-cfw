# st version
VERSION = 0.3

# Customize below to fit your system

# includes and libs
INCS = -I. -I${SYSROOT}/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT
LIBS = -lc -L${SYSROOT}/usr/lib -lSDL -lpthread -lutil
LIBS += -lasound

# flags
CPPFLAGS = -DVERSION=\"${VERSION}\"
CFLAGS += ${INCS} ${CPPFLAGS} -DPOWKIDDY -std=gnu11
CFLAGS += -fPIC -ffunction-sections -fdata-sections -Wall
LDFLAGS = ${LIBS}
