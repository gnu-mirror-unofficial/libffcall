	.file	"proto.c"
.toc
.csect .text[PR]
gcc2_compiled.:
__gnu_compiled_c:
	.align 2
	.globl tramp
	.globl .tramp
.csect tramp[DS]
tramp:
	.long .tramp, TOC[tc0], 0
.csect .text[PR]
.tramp:
	.extern __mulh
	.extern __mull
	.extern __divss
	.extern __divus
	.extern __quoss
	.extern __quous
	mflr 0
	stw 0,8(1)
	stwu 1,-56(1)
	lis 11,0x1234
	lis 9,0x7355
	lis 0,0xbabe
	ori 11,11,22136
	ori 9,9,18193
	ori 0,0,48832
	stw 9,0(11)
	mr 8,0
	stw 2,20(1)
	lwz 10,0(8)
	lwz 2,4(8)
	mtlr 10
	lwz 11,8(8)
	blrl
	lwz 2,20(1)
	la 1,56(1)
	lwz 0,8(1)
	mtlr 0
	blr
LT..tramp:
	.long 0
	.byte 0,0,32,65,128,0,0,0
	.long LT..tramp-.tramp
	.short 5
	.byte "tramp"
	.align 2
	.globl jump
	.globl .jump
.csect jump[DS]
jump:
	.long .jump, TOC[tc0], 0
.csect .text[PR]
.jump:
	lis 0,0xbabe
	ori 0,0,48832
	mtctr 0
	bctr
LT..jump:
	.long 0
	.byte 0,0,32,64,0,0,0,0
	.long LT..jump-.jump
	.short 4
	.byte "jump"
_section_.text:
.csect .data[RW]
	.long _section_.text