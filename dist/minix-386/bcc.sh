#/bin/sh
set -x

N='bin32'

tar cv /tmp/$N.tar \
  /usr/src/commands/Makefile.bcc \
  /usr/src/commands/bawk/Makefile.bcc \
  /usr/src/commands/dis88/Makefile.bcc \
  /usr/src/commands/de/Makefile.bcc \
  /usr/src/commands/elvis/Makefile.bcc \
  /usr/src/commands/ibm/Makefile.bcc \
  /usr/src/commands/ic/Makefile.bcc \
  /usr/src/commands/indent/Makefile.bcc \
  /usr/src/commands/kermit/Makefile.bcc \
  /usr/src/commands/kermit/ckcpro.c \
  /usr/src/commands/m4/Makefile.bcc \
  /usr/src/commands/sh/Makefile.bcc \
  /usr/src/commands/make/Makefile.bcc \
  /usr/src/commands/mined/Makefile.bcc \
  /usr/src/commands/nroff/Makefile.bcc \
  /usr/src/commands/patch/Makefile.bcc \
  /usr/src/commands/zmodem/Makefile.bcc \
  /usr/src/amoeba/util/Makefile.bcc \
  /tmp/check_cpu.c \
  /tmp/bin32.sh

rm -fr /tmp/$N.tar.Z
compress /tmp/$N.tar

cp /tmp/$N.tar.Z /user
sync

