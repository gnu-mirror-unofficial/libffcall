dnl -*- Autoconf -*-
dnl Copyright (C) 1993-2020 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License as published by the Free Software Foundation;
dnl either version 2 of the License, or (at your option) any later version.
dnl As a special exception to the GNU General Public License, this file
dnl may be distributed as part of a program that contains a configuration
dnl script generated by Autoconf, under the same distribution terms as
dnl the rest of that program.

dnl From Bruno Haible, Marcus Daniels, Sam Steingold.

AC_PREREQ([2.57])

AC_DEFUN([CL_MACH_VM],
[
  AC_CACHE_CHECK([for vm_allocate],
    [cl_cv_func_vm],
    [AC_LINK_IFELSE(
      [AC_LANG_PROGRAM([[]],[[vm_allocate(); task_self();]])],
      [cl_cv_func_vm=yes],
      [cl_cv_func_vm=no])
    ])
  if test $cl_cv_func_vm = yes; then
    AC_DEFINE([HAVE_MACH_VM],[],[have vm_allocate() and task_self() functions])
  fi
])
