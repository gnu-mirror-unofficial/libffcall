dnl Copyright (C) 1993-2003 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels.

AC_PREREQ(2.13)

AC_DEFUN([CL_CODEEXEC],
[AC_CACHE_CHECK([whether code in malloc'ed memory is executable], cl_cv_codeexec, [
dnl The test below does not work on host=hppa*-hp-hpux* because on this system
dnl function pointers are actually pointers into(!) a two-pointer struct.
dnl The test below does not work on host=rs6000-*-* because on this system
dnl function pointers are actually pointers to a three-pointer struct.
case "$host_os" in
  hpux*) cl_cv_codeexec="guessing yes" ;;
  *)
case "$host_cpu" in
  # On host=rs6000-*-aix3.2.5 malloc'ed memory is indeed not executable.
  rs6000) cl_cv_codeexec="guessing no" ;;
  *)
AC_TRY_RUN([
#include <sys/types.h>
/* declare malloc() */
#include <stdlib.h>
int fun () { return 31415926; }
int main ()
{ long size = (char*)&main - (char*)&fun;
  char* funcopy = (char*) malloc(size);
  int i;
  for (i = 0; i < size; i++) { funcopy[i] = ((char*)&fun)[i]; }
  exit(!((*(int(*)())funcopy)() == 31415926));
}], cl_cv_codeexec=yes, rm -f core
cl_cv_codeexec=no, cl_cv_codeexec="guessing yes")
  ;;
esac
  ;;
esac
])
case "$cl_cv_codeexec" in
  *yes) AC_DEFINE(CODE_EXECUTABLE) ;;
  *no)  ;;
esac
])