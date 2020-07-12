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

AC_PREREQ([2.63])

AC_DEFUN([FFCALL_CODEEXEC],
[
  AC_REQUIRE([AC_CANONICAL_HOST])
  AC_REQUIRE([gl_HOST_CPU_C_ABI])
  AC_CACHE_CHECK([whether code in malloc()ed memory is executable],
    [ffcall_cv_codeexec],
    [dnl The test below does not work on platforms with the following ABIs:
     dnl - hppa, because function pointers are actually pointers into(!)
     dnl   a two-pointer struct.
     dnl - hppa64, because function pointers are actually pointers to a
     dnl   four-pointer struct.
     dnl - powerpc on AIX, powerpc64, because function pointers are actually
     dnl   pointers to a three-pointer struct.
     dnl - ia64, because function pointers are actually pointers to a
     dnl   two-pointer struct.
     case "$HOST_CPU_C_ABI--$host_os" in
       hppa--* | hppa64--* | powerpc--aix* | powerpc64--* | ia64--*)
         dnl On these platforms, it's irrelevant whether malloc'ed memory is
         dnl executable, because the trampolines are built without executable
         dnl code.
         ffcall_cv_codeexec="irrelevant"
         ;;
       arm64--freebsd*)
         dnl On this platform, malloc()ed memory is not executable, and the
         dnl test program loops endlessly.
         ffcall_cv_codeexec=no
         ;;
       *)
         AC_RUN_IFELSE(
           [AC_LANG_SOURCE([
              GL_NOCRASH
              [#include <sys/types.h>
               /* declare malloc() */
               #include <stdlib.h>
               int fun () { return 31415926; }
               int main ()
               { nocrash_init();
                {long size = (char*)&main - (char*)&fun;
                 char* funcopy = (char*) malloc(size);
                 int i;
                 for (i = 0; i < size; i++) { funcopy[i] = ((char*)&fun)[i]; }
                 return !((*(int(*)())funcopy)() == 31415926);
               }}
              ]])
           ],
           [ffcall_cv_codeexec=yes],
           [ffcall_cv_codeexec=no],
           [dnl When cross-compiling, assume the known behaviour.
            dnl If we don't know, assume the worst.
            case "$host_os" in
              cygwin*)
                case "$HOST_CPU_C_ABI" in
                  i386)
                    ffcall_cv_codeexec="guessing yes" ;;
                  x86_64)
                    ffcall_cv_codeexec="guessing no" ;;
                  *)
                    ffcall_cv_codeexec="guessing no" ;;
                esac
                ;;
              darwin*)
                case "$HOST_CPU_C_ABI" in
                  i386 | powerpc)
                    ffcall_cv_codeexec="guessing yes" ;;
                  x86_64)
                    ffcall_cv_codeexec="guessing no" ;;
                  *)
                    ffcall_cv_codeexec="guessing no" ;;
                esac
                ;;
              irix*)
                ffcall_cv_codeexec="guessing no" ;;
              linux*)
                case "$HOST_CPU_C_ABI" in
                  alpha | ia64)
                    ffcall_cv_codeexec="guessing yes" ;;
                  arm | armhf | arm64 | i386 | mips* | s390 | s390x | sparc | sparc64 | x86_64*)
                    ffcall_cv_codeexec="guessing no" ;;
                  *)
                    ffcall_cv_codeexec="guessing no" ;;
                esac
                ;;
              solaris*)
                case "$HOST_CPU_C_ABI" in
                  i386 | sparc | sparc64)
                    ffcall_cv_codeexec="guessing yes" ;;
                  x86_64)
                    ffcall_cv_codeexec="guessing no" ;;
                  *)
                    ffcall_cv_codeexec="guessing no" ;;
                esac
                ;;
              *)
                ffcall_cv_codeexec="guessing no" ;;
            esac
           ])
         ;;
     esac
    ])
  case "$ffcall_cv_codeexec" in
    *yes | irrelevant)
     AC_DEFINE([CODE_EXECUTABLE], [], [whether code in malloc()ed memory is executable])
     ;;
    *no) ;;
  esac
])

dnl Test how to use the mprotect function to make memory executable.
dnl Test against the mprotect limitations found in PaX enabled Linux kernels
dnl and HardenedBSD.
AC_DEFUN([FFCALL_CODEEXEC_PAX],
[
  AC_REQUIRE([gl_FUNC_MMAP_ANON])
  AC_REQUIRE([FFCALL_MMAP])
  AC_REQUIRE([FFCALL_MPROTECT])
  AC_REQUIRE([FFCALL_CODEEXEC])
  AC_REQUIRE([AC_CANONICAL_HOST])
  case "$ffcall_cv_codeexec" in
    *yes | irrelevant) ;;
    *)
      case "$ac_cv_func_mprotect--$cl_cv_func_mprotect_works" in
        yes--*yes)
          AC_CACHE_CHECK([whether mprotect can make malloc()ed memory executable],
            [ffcall_cv_malloc_mprotect_can_exec],
            [dnl On RHEL 6 / CentOS 6 with SELinux enabled, the result of
             dnl this test depends on SELinux flags that can be changed at
             dnl runtime: By default, the result is 'no'. However, when the flag
             dnl allow_execheap is turned on, the result is 'yes'. But the flag
             dnl can be turned off again at any moment.
             if test "$cross_compiling" != yes -a -d /etc/selinux; then
               ffcall_cv_malloc_mprotect_can_exec='determined by SELinux at runtime'
             else
               AC_RUN_IFELSE(
                 [AC_LANG_SOURCE([[
                    #include <errno.h>
                    #include <stdlib.h>
                    /* Declare getpagesize().  */
                    #ifdef HAVE_UNISTD_H
                     #include <unistd.h>
                    #endif
                    #ifdef __hpux
                     extern
                     #ifdef __cplusplus
                     "C"
                     #endif
                     int getpagesize (void);
                    #endif
                    #include <fcntl.h>
                    /* Declare mprotect().  */
                    #include <sys/mman.h>
                    int
                    main ()
                    {
                      unsigned int pagesize = getpagesize ();
                      char *p = (char *) malloc (50);
                      int ret;
                      if (p == (char*) -1)
                        /* malloc is not working as expected. */
                        return 1;
                      p[5] = 0x77;
                      ret = mprotect (p - ((unsigned int) p & (pagesize - 1)), pagesize, PROT_READ | PROT_WRITE | PROT_EXEC);
                      if (ret < 0
                          && (errno == EACCES || errno == ENOMEM || errno == ENOTSUP))
                        /* mprotect is forbidden to make malloc()ed pages executable that were writable earlier. */
                        return 2;
                      return 0;
                    }
                    ]])
                 ],
                 [ffcall_cv_malloc_mprotect_can_exec=yes],
                 [ffcall_cv_malloc_mprotect_can_exec=no],
                 [dnl When cross-compiling, assume SELinux on Linux.
                  dnl If we don't know, assume the worst.
                  case "$host_os" in
                    linux*)
                      ffcall_cv_malloc_mprotect_can_exec='determined by SELinux at runtime' ;;
                    aix* | cygwin* | darwin* | irix* | solaris*)
                      ffcall_cv_malloc_mprotect_can_exec="guessing yes" ;;
                    *)
                      ffcall_cv_malloc_mprotect_can_exec="guessing no" ;;
                  esac
                 ])
             fi
            ])
          case "$ffcall_cv_malloc_mprotect_can_exec" in
            *yes)      MPROTECT_AFTER_MALLOC_CAN_EXEC=1 ;;
            *no)       MPROTECT_AFTER_MALLOC_CAN_EXEC=0 ;;
            *runtime*) MPROTECT_AFTER_MALLOC_CAN_EXEC='-1' ;;
          esac
          AC_DEFINE_UNQUOTED([HAVE_MPROTECT_AFTER_MALLOC_CAN_EXEC], [$MPROTECT_AFTER_MALLOC_CAN_EXEC],
            [have an mprotect() function that can make malloc()ed memory pages executable])
          case "$ffcall_cv_malloc_mprotect_can_exec" in
            *yes) ;;
            *)
              AC_CACHE_CHECK([whether mprotect can make mmap()ed memory executable],
                [ffcall_cv_mmap_mprotect_can_exec],
                [dnl On RHEL 6 / CentOS 6 with SELinux enabled, the result of
                 dnl this test depends on SELinux flags that can be changed at
                 dnl runtime: By default, the result is 'yes'. However, when the flags
                 dnl allow_execmem and allow_execstack are turned off, the result is
                 dnl 'no'.
                 if test "$cross_compiling" != yes -a -d /etc/selinux; then
                   ffcall_cv_mmap_mprotect_can_exec='determined by SELinux at runtime'
                 else
                   AC_RUN_IFELSE(
                     [AC_LANG_SOURCE([[
                        #include <errno.h>
                        #include <stdlib.h>
                        /* Declare getpagesize().  */
                        #ifdef HAVE_UNISTD_H
                         #include <unistd.h>
                        #endif
                        #ifdef __hpux
                         extern
                         #ifdef __cplusplus
                         "C"
                         #endif
                         int getpagesize (void);
                        #endif
                        #include <fcntl.h>
                        /* Declare mmap(), mprotect().  */
                        #include <sys/mman.h>
                        #ifndef MAP_FILE
                         #define MAP_FILE 0
                        #endif
                        #ifndef MAP_VARIABLE
                         #define MAP_VARIABLE 0
                        #endif
                        int
                        main ()
                        {
                          unsigned int pagesize = getpagesize ();
                          char *p;
                          int ret;
                        #if HAVE_MMAP_ANONYMOUS
                          p = (char *) mmap (NULL, pagesize, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_VARIABLE, -1, 0);
                        #elif HAVE_MMAP_DEVZERO
                          int zero_fd = open("/dev/zero", O_RDONLY, 0666);
                          if (zero_fd < 0)
                            return 1;
                          p = (char *) mmap (NULL, pagesize, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_FILE | MAP_VARIABLE, zero_fd, 0);
                        #else
                          ??
                        #endif
                          if (p == (char*) -1)
                            /* mmap is not working as expected. */
                            return 1;
                          p[5] = 0x77;
                          ret = mprotect (p, pagesize, PROT_READ | PROT_WRITE | PROT_EXEC);
                          if (ret < 0
                              && (errno == EACCES || errno == ENOMEM || errno == ENOTSUP))
                            /* mprotect is forbidden to make mmap()ed pages executable that were writable earlier. */
                            return 2;
                          return 0;
                        }
                        ]])
                     ],
                     [ffcall_cv_mmap_mprotect_can_exec=yes],
                     [ffcall_cv_mmap_mprotect_can_exec=no],
                     [dnl When cross-compiling, assume SELinux on Linux.
                      dnl If we don't know, assume the worst.
                      case "$host_os" in
                        linux*) ffcall_cv_mmap_mprotect_can_exec='determined by SELinux at runtime' ;;
                        *)      ffcall_cv_mmap_mprotect_can_exec="guessing no" ;;
                      esac
                     ])
                 fi
                ])
              case "$ffcall_cv_mmap_mprotect_can_exec" in
                *yes)      MPROTECT_AFTER_MMAP_CAN_EXEC=1 ;;
                *no)       MPROTECT_AFTER_MMAP_CAN_EXEC=0 ;;
                *runtime*) MPROTECT_AFTER_MMAP_CAN_EXEC='-1' ;;
              esac
              AC_DEFINE_UNQUOTED([HAVE_MPROTECT_AFTER_MMAP_CAN_EXEC], [$MPROTECT_AFTER_MMAP_CAN_EXEC],
                [have an mprotect() function that can make mmap()ed memory pages executable])
              case "$ffcall_cv_mmap_mprotect_can_exec" in
                *yes) ;;
                *)
                  AC_CACHE_CHECK([whether a shared mmap can make memory pages executable],
                    [ffcall_cv_mmap_shared_can_exec],
                    [filename="/tmp/trampdata$$.data"
                     AC_RUN_IFELSE(
                       [AC_LANG_SOURCE([[
                          #include <fcntl.h>
                          #include <stdlib.h>
                          /* Declare getpagesize().  */
                          #ifdef HAVE_UNISTD_H
                           #include <unistd.h>
                          #endif
                          #ifdef __hpux
                           extern
                           #ifdef __cplusplus
                           "C"
                           #endif
                           int getpagesize (void);
                          #endif
                          /* Declare mmap().  */
                          #include <sys/mman.h>
                          #ifndef MAP_FILE
                           #define MAP_FILE 0
                          #endif
                          #ifndef MAP_VARIABLE
                           #define MAP_VARIABLE 0
                          #endif
                          int
                          main ()
                          {
                            unsigned int pagesize = getpagesize ();
                            int fd;
                            char *pw;
                            char *px;
                            fd = open ("$filename", O_CREAT | O_RDWR | O_TRUNC, 0700);
                            if (fd < 0)
                              return 1;
                            if (ftruncate (fd, pagesize) < 0)
                              return 2;
                            pw = (char *) mmap (NULL, pagesize, PROT_READ | PROT_WRITE, MAP_SHARED | MAP_FILE | MAP_VARIABLE, fd, 0);
                            if (pw == (char*) -1)
                              return 3;
                            pw[5] = 0xc3;
                            px = (char *) mmap (NULL, pagesize, PROT_READ | PROT_EXEC, MAP_SHARED | MAP_FILE | MAP_VARIABLE, fd, 0);
                            if (px == (char*) -1)
                              return 4;
                            if ((char)px[5] != (char)0xc3)
                              return 5;
                            /* On i386 and x86_64 this is a 'ret' instruction that we can invoke. */
                          #if (defined __i386 || defined __i386__ || defined _I386 || defined _M_IX86 || defined _X86_) || (defined __x86_64__ || defined __amd64__)
                            ((void (*) (void)) (px + 5)) ();
                          #endif
                            return 0;
                          }
                          ]])
                       ],
                       [ffcall_cv_mmap_shared_can_exec=yes],
                       [ffcall_cv_mmap_shared_can_exec=no],
                       [dnl When cross-compiling, assume yes, since this is the result
                        dnl on all the platforms where we have tested it.
                        ffcall_cv_mmap_shared_can_exec="guessing yes"
                       ])
                     rm -f "$filename"
                    ])
                  case "$ffcall_cv_mmap_shared_can_exec" in
                    *yes)
                      AC_DEFINE([HAVE_MMAP_SHARED_CAN_EXEC], [1],
                        [have an mmap() function that, with MAP_SHARED, can make memory pages executable])
                      ;;
                  esac
                  ;;
              esac
              ;;
          esac
          ;;
      esac
      ;;
  esac
])
