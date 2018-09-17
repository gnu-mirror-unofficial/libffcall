/**
  Copyright 1993 Bill Triggs <Bill.Triggs@inrialpes.fr>
  Copyright 1995-2017 Bruno Haible <bruno@clisp.org>

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation; either version 2 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <https://www.gnu.org/licenses/>.
**/
/*----------------------------------------------------------------------
  !!! THIS ROUTINE MUST BE COMPILED gcc -O !!!

  Foreign function interface for a Intel IA-64 in little-endian mode with gcc.

  This calls a C function with an argument list built up using macros
  defined in avcall.h.

  IA-64 64-bit Argument Passing Conventions:

  The argument sequence is mapped linearly on the registers r32,...,r39,
  and continued on the stack, in [r12+16], [r12+24], ...
  Items in this sequence are word-aligned. In gcc < 3.0, structures larger
  than a single word are even two-word-aligned.
  Integer/pointer arguments are passed in the allocated slots (registers
  or stack slots). The first 8 float/double arguments are passed in
  registers f8,...,f15 instead, but their slots are kept allocated.
  Structure args are passed like multiple integer arguments; except that
  structures consisting only of floats or only of doubles are passed like
  multiple float arguments or multiple double arguments, respectively.

  Integers and pointers are returned in r8, floats and doubles in f8.
  Structures consisting only of at most 8 floats or only of at most 8 doubles
  are returned in f8,...,f15. Other than that, structures of size <= 32 bytes
  are returned in r8,...,r11, as if these were 4 contiguous words in memory.
  Larger structures are returned in memory; the caller passes the address
  of the target memory area in r8, and it is returned unmodified in r8.
  ----------------------------------------------------------------------*/
#include "avcall-internal.h"

#define RETURN(TYPE,VAL)	(*(TYPE*)l->raddr = (TYPE)(VAL))

register __avword*	sret	__asm__("r8");  /* structure return pointer */
/*register __avword	iret	__asm__("r8");*/
register __avword	iret2	__asm__("r9");
register __avword	iret3	__asm__("r10");
register __avword	iret4	__asm__("r11");
/*register float	fret	__asm__("f8");*/
/*register double	dret	__asm__("f8");*/
register double		farg1	__asm__("f8");
register double		farg2	__asm__("f9");
register double		farg3	__asm__("f10");
register double		farg4	__asm__("f11");
register double		farg5	__asm__("f12");
register double		farg6	__asm__("f13");
register double		farg7	__asm__("f14");
register double		farg8	__asm__("f15");

int
avcall_call(av_alist* list)
{
  register __avword*	sp	__asm__("r12"); /* C names for registers */

  __av_alist* l = &AV_LIST_INNER(list);

  __avword* argframe = (sp -= __AV_ALIST_WORDS) + 2; /* make room for argument list */
  int arglen = l->aptr - l->args;
  int farglen = l->faptr - l->fargs;
  __avword iret;

  {
    int i;
    for (i = 8; i < arglen; i++)	/* push function args onto stack */
      argframe[i-8] = l->args[i];
  }

  /* struct return address */
  if (l->rtype == __AVstruct)
    sret = l->raddr;

  /* put max. 8 double args in registers */
  if (farglen > 0) {
    farg1 = l->fargs[0];
    if (farglen > 1) {
      farg2 = l->fargs[1];
      if (farglen > 2) {
        farg3 = l->fargs[2];
        if (farglen > 3) {
          farg4 = l->fargs[3];
          if (farglen > 4) {
            farg5 = l->fargs[4];
            if (farglen > 5) {
              farg6 = l->fargs[5];
              if (farglen > 6) {
                farg7 = l->fargs[6];
                if (farglen > 7)
                  farg8 = l->fargs[7];
              }
            }
          }
        }
      }
    }
  }

  /* call function, pass 8 integer and 8 double args in registers */
  if (l->rtype == __AVfloat) {
    *(float*)l->raddr = (*(float(*)())l->func)(l->args[0], l->args[1],
					       l->args[2], l->args[3],
					       l->args[4], l->args[5],
					       l->args[6], l->args[7]);
  } else
  if (l->rtype == __AVdouble) {
    *(double*)l->raddr = (*(double(*)())l->func)(l->args[0], l->args[1],
						 l->args[2], l->args[3],
						 l->args[4], l->args[5],
						 l->args[6], l->args[7]);
  } else {
    iret = (*l->func)(l->args[0], l->args[1], l->args[2], l->args[3],
		      l->args[4], l->args[5], l->args[6], l->args[7]);

    /* save return value */
    if (l->rtype == __AVvoid) {
    } else
    if (l->rtype == __AVword) {
      RETURN(__avword, iret);
    } else
    if (l->rtype == __AVchar) {
      RETURN(char, iret);
    } else
    if (l->rtype == __AVschar) {
      RETURN(signed char, iret);
    } else
    if (l->rtype == __AVuchar) {
      RETURN(unsigned char, iret);
    } else
    if (l->rtype == __AVshort) {
      RETURN(short, iret);
    } else
    if (l->rtype == __AVushort) {
      RETURN(unsigned short, iret);
    } else
    if (l->rtype == __AVint) {
      RETURN(int, iret);
    } else
    if (l->rtype == __AVuint) {
      RETURN(unsigned int, iret);
    } else
    if (l->rtype == __AVlong || l->rtype == __AVlonglong) {
      RETURN(long, iret);
    } else
    if (l->rtype == __AVulong || l->rtype == __AVulonglong) {
      RETURN(unsigned long, iret);
    } else
  /* see above
    if (l->rtype == __AVfloat) {
    } else
    if (l->rtype == __AVdouble) {
    } else
  */
    if (l->rtype == __AVvoidp) {
      RETURN(void*, iret);
    } else
    if (l->rtype == __AVstruct) {
      if (l->flags & __AV_REGISTER_STRUCT_RETURN) {
        /* Return structs of size <= 32 in registers. */
        if (l->rsize > 0 && l->rsize <= 32) {
          void* raddr = l->raddr;
          #if 0 /* Unoptimized */
          if (l->rsize >= 1)
            ((unsigned char *)raddr)[0] = (unsigned char)(iret);
          if (l->rsize >= 2)
            ((unsigned char *)raddr)[1] = (unsigned char)(iret>>8);
          if (l->rsize >= 3)
            ((unsigned char *)raddr)[2] = (unsigned char)(iret>>16);
          if (l->rsize >= 4)
            ((unsigned char *)raddr)[3] = (unsigned char)(iret>>24);
          if (l->rsize >= 5)
            ((unsigned char *)raddr)[4] = (unsigned char)(iret>>32);
          if (l->rsize >= 6)
            ((unsigned char *)raddr)[5] = (unsigned char)(iret>>40);
          if (l->rsize >= 7)
            ((unsigned char *)raddr)[6] = (unsigned char)(iret>>48);
          if (l->rsize >= 8)
            ((unsigned char *)raddr)[7] = (unsigned char)(iret>>56);
          if (l->rsize >= 9) {
            ((unsigned char *)raddr)[8] = (unsigned char)(iret2);
            if (l->rsize >= 10)
              ((unsigned char *)raddr)[9] = (unsigned char)(iret2>>8);
            if (l->rsize >= 11)
              ((unsigned char *)raddr)[10] = (unsigned char)(iret2>>16);
            if (l->rsize >= 12)
              ((unsigned char *)raddr)[11] = (unsigned char)(iret2>>24);
            if (l->rsize >= 13)
              ((unsigned char *)raddr)[12] = (unsigned char)(iret2>>32);
            if (l->rsize >= 14)
              ((unsigned char *)raddr)[13] = (unsigned char)(iret2>>40);
            if (l->rsize >= 15)
              ((unsigned char *)raddr)[14] = (unsigned char)(iret2>>48);
            if (l->rsize >= 16)
              ((unsigned char *)raddr)[15] = (unsigned char)(iret2>>56);
            if (l->rsize >= 17) {
              ((unsigned char *)raddr)[16] = (unsigned char)(iret3);
              if (l->rsize >= 18)
                ((unsigned char *)raddr)[17] = (unsigned char)(iret3>>8);
              if (l->rsize >= 19)
                ((unsigned char *)raddr)[18] = (unsigned char)(iret3>>16);
              if (l->rsize >= 20)
                ((unsigned char *)raddr)[19] = (unsigned char)(iret3>>24);
              if (l->rsize >= 21)
                ((unsigned char *)raddr)[20] = (unsigned char)(iret3>>32);
              if (l->rsize >= 22)
                ((unsigned char *)raddr)[21] = (unsigned char)(iret3>>40);
              if (l->rsize >= 23)
                ((unsigned char *)raddr)[22] = (unsigned char)(iret3>>48);
              if (l->rsize >= 24)
                ((unsigned char *)raddr)[23] = (unsigned char)(iret3>>56);
              if (l->rsize >= 25) {
                ((unsigned char *)raddr)[24] = (unsigned char)(iret4);
                if (l->rsize >= 26)
                  ((unsigned char *)raddr)[25] = (unsigned char)(iret4>>8);
                if (l->rsize >= 27)
                  ((unsigned char *)raddr)[26] = (unsigned char)(iret4>>16);
                if (l->rsize >= 28)
                  ((unsigned char *)raddr)[27] = (unsigned char)(iret4>>24);
                if (l->rsize >= 29)
                  ((unsigned char *)raddr)[28] = (unsigned char)(iret4>>32);
                if (l->rsize >= 30)
                  ((unsigned char *)raddr)[29] = (unsigned char)(iret4>>40);
                if (l->rsize >= 31)
                  ((unsigned char *)raddr)[30] = (unsigned char)(iret4>>48);
                if (l->rsize >= 32)
                  ((unsigned char *)raddr)[31] = (unsigned char)(iret4>>56);
              }
            }
          }
          #else /* Optimized: fewer conditional jumps, fewer memory accesses */
          uintptr_t count = l->rsize; /* > 0, ≤ 4*sizeof(__avword) */
          __avword* wordaddr = (__avword*)((uintptr_t)raddr & ~(uintptr_t)(sizeof(__avword)-1));
          uintptr_t start_offset = (uintptr_t)raddr & (uintptr_t)(sizeof(__avword)-1); /* ≥ 0, < sizeof(__avword) */
          uintptr_t end_offset = start_offset + count; /* > 0, < 5*sizeof(__avword) */
          if (count <= sizeof(__avword)) {
            /* Use iret. */
            if (end_offset <= sizeof(__avword)) {
              /* 0 < end_offset ≤ sizeof(__avword) */
              __avword mask0 = ((__avword)2 << (end_offset*8-1)) - ((__avword)1 << (start_offset*8));
              wordaddr[0] ^= (wordaddr[0] ^ (iret << (start_offset*8))) & mask0;
            } else {
              /* sizeof(__avword) < end_offset < 2*sizeof(__avword), start_offset > 0 */
              __avword mask0 = - ((__avword)1 << (start_offset*8));
              __avword mask1 = ((__avword)2 << (end_offset*8-sizeof(__avword)*8-1)) - 1;
              wordaddr[0] ^= (wordaddr[0] ^ (iret << (start_offset*8))) & mask0;
              wordaddr[1] ^= (wordaddr[1] ^ (iret >> (sizeof(__avword)*8-start_offset*8))) & mask1;
            }
          } else if (count <= 2*sizeof(__avword)) {
            /* Use iret, iret2. */
            __avword mask0 = - ((__avword)1 << (start_offset*8));
            wordaddr[0] ^= (wordaddr[0] ^ (iret << (start_offset*8))) & mask0;
            if (end_offset <= 2*sizeof(__avword)) {
              /* sizeof(__avword) < end_offset ≤ 2*sizeof(__avword) */
              __avword mask1 = ((__avword)2 << (end_offset*8-sizeof(__avword)*8-1)) - 1;
              wordaddr[1] ^= (wordaddr[1] ^ ((iret >> (sizeof(__avword)*4-start_offset*4) >> (sizeof(__avword)*4-start_offset*4)) | (iret2 << (start_offset*8)))) & mask1;
            } else {
              /* 2*sizeof(__avword) < end_offset < 3*sizeof(__avword), start_offset > 0 */
              __avword mask2 = ((__avword)2 << (end_offset*8-2*sizeof(__avword)*8-1)) - 1;
              wordaddr[1] = (iret >> (sizeof(__avword)*8-start_offset*8)) | (iret2 << (start_offset*8));
              wordaddr[2] ^= (wordaddr[2] ^ (iret2 >> (sizeof(__avword)*8-start_offset*8))) & mask2;
            }
          } else if (count <= 3*sizeof(__avword)) {
            /* Use iret, iret2, iret3. */
            __avword mask0 = - ((__avword)1 << (start_offset*8));
            wordaddr[0] ^= (wordaddr[0] ^ (iret << (start_offset*8))) & mask0;
            if (end_offset <= 3*sizeof(__avword)) {
              /* 2*sizeof(__avword) < end_offset ≤ 3*sizeof(__avword) */
              __avword mask2 = ((__avword)2 << (end_offset*8-sizeof(__avword)*8-1)) - 1;
              wordaddr[1] = (iret >> (sizeof(__avword)*4-start_offset*4) >> (sizeof(__avword)*4-start_offset*4)) | (iret2 << (start_offset*8));
              wordaddr[2] ^= (wordaddr[2] ^ ((iret2 >> (sizeof(__avword)*4-start_offset*4) >> (sizeof(__avword)*4-start_offset*4)) | (iret3 << (start_offset*8)))) & mask2;
            } else {
              /* 3*sizeof(__avword) < end_offset < 4*sizeof(__avword), start_offset > 0 */
              __avword mask3 = ((__avword)2 << (end_offset*8-2*sizeof(__avword)*8-1)) - 1;
              wordaddr[1] = (iret >> (sizeof(__avword)*8-start_offset*8)) | (iret2 << (start_offset*8));
              wordaddr[2] = (iret2 >> (sizeof(__avword)*8-start_offset*8)) | (iret3 << (start_offset*8));
              wordaddr[3] ^= (wordaddr[3] ^ (iret3 >> (sizeof(__avword)*8-start_offset*8))) & mask3;
            }
          } else {
            /* Use iret, iret2, iret3, iret4. */
            __avword mask0 = - ((__avword)1 << (start_offset*8));
            wordaddr[0] ^= (wordaddr[0] ^ (iret << (start_offset*8))) & mask0;
            if (end_offset <= 4*sizeof(__avword)) {
              /* 3*sizeof(__avword) < end_offset ≤ 4*sizeof(__avword) */
              __avword mask3 = ((__avword)2 << (end_offset*8-sizeof(__avword)*8-1)) - 1;
              wordaddr[1] = (iret >> (sizeof(__avword)*4-start_offset*4) >> (sizeof(__avword)*4-start_offset*4)) | (iret2 << (start_offset*8));
              wordaddr[2] = (iret2 >> (sizeof(__avword)*4-start_offset*4) >> (sizeof(__avword)*4-start_offset*4)) | (iret3 << (start_offset*8));
              wordaddr[3] ^= (wordaddr[3] ^ ((iret >> (sizeof(__avword)*4-start_offset*4) >> (sizeof(__avword)*4-start_offset*4)) | (iret2 << (start_offset*8)))) & mask3;
            } else {
              /* 4*sizeof(__avword) < end_offset < 5*sizeof(__avword), start_offset > 0 */
              __avword mask4 = ((__avword)2 << (end_offset*8-2*sizeof(__avword)*8-1)) - 1;
              wordaddr[1] = (iret >> (sizeof(__avword)*8-start_offset*8)) | (iret2 << (start_offset*8));
              wordaddr[2] = (iret2 >> (sizeof(__avword)*8-start_offset*8)) | (iret3 << (start_offset*8));
              wordaddr[3] = (iret3 >> (sizeof(__avword)*8-start_offset*8)) | (iret4 << (start_offset*8));
              wordaddr[4] ^= (wordaddr[4] ^ (iret4 >> (sizeof(__avword)*8-start_offset*8))) & mask4;
            }
          }
          #endif
        }
      }
    }
  }
  return 0;
}
