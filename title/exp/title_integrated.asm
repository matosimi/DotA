/***************************************/
/*  Use MADS http://mads.atari8.info/  */
/*  Mode: DLI (char mode)              */
/***************************************/

	icl "title.h"
entry
	org $f0

fcnt	.ds 2
fadr	.ds 2
fhlp	.ds 2
cloc	.ds 1
regA	.ds 1
regX	.ds 1
regY	.ds 1

WIDTH	= 32
HEIGHT	= 30

	org entry

; ---	BASIC switch OFF
	;org $2000\ mva #$ff portb\ rts\ ini $2000

; ---	MAIN PROGRAM
	;org $2000
ant	dta $70
	dta $70,$70,$F0,$C2,a(scr),$02,$02,$02,$02,$02,$82,$02,$82,$02,$02,$82,$02
	dta $02,$70,$70
	dta $42,a(lines)
	dta $70,$70,2,$70,$70,$70,2
	dta $41,a(ant)

scr	ins "title.scr"
lines	dta d'       BY MARTIN SIMECEK        '
	dta d'  ABBUC SOFTWARE CONTEST 2023   '
	dta d'                           REV41'
;	.ds 16*40
;.local	ntsc_color_convert
	.use DLI,NMI
coloramount	equ 24
clrtab	
:coloramount	dta a(c:1)
coloramount2	equ 7
	dta a(gamedli.colgtia0-1,gamedli.colgtia1-1,gamedli.colgtia2-1,gameDli.colplayer-1,gameDli.coldot-1,gamedli.colstatus-1,gameVbi.accent-1)
;.endl

	.ALIGN $0400
fnt	ins "title.fnt"

	ift USESPRITES
	.ALIGN $0800
pmg	.ds $0300
	ift FADECHR = 0
	SPRITES
	els
	.ds $500
	eif
	eif

main
; ---	init PMG

	ift USESPRITES
	mva >pmg pmbase		;missiles and players data address
	mva #$03 pmcntl		;enable players and missiles
	eif

	;convert colors to NTSC if ntsc detected
.local	ntsc_color_convert
	ldx #coloramount+coloramount2
	mwa #clrtab w1
@	txa
	asl @
	tay
	mwa (w1),y w2
	ldy #1
	lda (w2),y
	jsr getcolor.pptr 
	sta (w2),y
	dex
	bpl @-
.endl

	lda:cmp:req $14		;wait 1 frame

	sei			;stop IRQ interrupts
	mva #$00 nmien		;stop NMI interrupts
	sta dmactl
	mva #$fe portb		;switch off ROM to get 16k more ram

	mwa #NMI $fffa		;new NMI handler

	mva #$c0 nmien		;switch on NMI+DLI again

	ift CHANGES		;if label CHANGES defined

_lp	lda trig0		; FIRE #0
	beq stop

	lda trig1		; FIRE #1
	beq stop

	lda consol		; START
	and #1
	beq stop

	lda skctl
	and #$04
	bne _lp			;wait to press any key; here you can put any own routine

	els

null	jmp DLI.dli1		;CPU is busy here, so no more routines allowed

	eif


stop
	.ifdef FADE_CHARS\ lda #0\ jsr fade_chars\ eif

	mva #$00 pmcntl		;PMG disabled
	tax
	sta:rne hposp0,x+

	mva #$ff portb		;ROM switch on
	mva #$40 nmien		;only NMI interrupts, DLI disabled
	cli			;IRQ enabled

	rts			;return to ... DOS

; ---	DLI PROGRAM

.local	DLI

	?old_dli = *

	ift !CHANGES

dli1	lda trig0		; FIRE #0
	beq stop

	lda trig1		; FIRE #1
	beq stop

	lda consol		; START
	and #1
	beq stop

	lda skctl
	and #$04
	beq stop

	lda vcount
	cmp #$02
	bne dli1

	:3 sta wsync

	DLINEW dli4

	eif

dli_start

dli4
	sta regA

	sta wsync		;line=32
c8	lda #$02
	sta wsync		;line=33
	sta color1
c9	lda #$08
	sta wsync		;line=34
	sta color1
c10	lda #$06
	sta wsync		;line=35
	sta color1
c11	lda #$0A
	sta wsync		;line=36
	sta color1
c12	lda #$0C
	sta wsync		;line=37
	sta color1
	DLINEW dli5 1 0 0

dli5
	sta regA
	stx regX
	sty regY

	sta wsync		;line=40
	lda #$00
	sta wsync		;line=41
	sta gtictl
c13	lda #$26
	sta wsync		;line=42
	sta colpm0
x5	lda #$7E
	sta wsync		;line=43
	sta hposp1
s3	lda #$03
x6	ldx #$82
x7	ldy #$7E
	sta wsync		;line=44
	sta sizep2
	sta sizep3
	stx hposp2
	sty hposp3
	DLINEW dli6 1 1 1

dli6
	sta regA

	sta wsync		;line=88
	sta wsync		;line=89
	sta wsync		;line=90
x8	lda #$7A
	sta wsync		;line=91
	sta hposp1
	sta wsync		;line=92
x9	lda #$82
	sta wsync		;line=93
	sta hposp3
	DLINEW dli7 1 0 0

dli7
	sta regA
	stx regX
	sty regY

	sta wsync		;line=104
x10	lda #$86
	sta wsync		;line=105
	sta hposp3
	sta wsync		;line=106
x11	lda #$76
	sta wsync		;line=107
	sta hposp1
	sta wsync		;line=108
	sta wsync		;line=109
	sta wsync		;line=110
x12	lda #$72
x13	ldx #$8A
c14	ldy #$28
	sta wsync		;line=111
	sta hposp2
	stx hposp3
	sty colpm3
	sta wsync		;line=112
	sta wsync		;line=113
	sta wsync		;line=114
x14	lda #$72
	sta wsync		;line=115
	sta hposp1
	sta wsync		;line=116
x15	lda #$8E
c15	ldx #$26
	sta wsync		;line=117
	sta hposp0
	stx colpm2
	DLINEW dli8 1 1 1

dli8
	sta regA
	stx regX

	sta wsync		;line=128
	sta wsync		;line=129
	sta wsync		;line=130
	sta wsync		;line=131
	sta wsync		;line=132
s4	lda #$01
x16	ldx #$92
	sta wsync		;line=133
	sta sizep3
	stx hposp3
c16	lda #$C4
	sta wsync		;line=134
	sta colpm2
	sta wsync		;line=135
c17	lda #$20
	ldx #$01
	sta wsync		;line=136
	sta color2
	stx gtictl
c18	lda #$22
	sta wsync		;line=137
	sta color2
	sta wsync		;line=138
c19	lda #$0A
	sta wsync		;line=139
	sta color1
c20	lda #$06
	sta wsync		;line=140
	sta color1
c21	lda #$08
	sta wsync		;line=141
	sta color1
c22	lda #$02
	sta wsync		;line=142
	sta color1
c23	lda #$06
	sta wsync		;line=143
	sta color1
;added:
	mva #$0c color1
	mva #$00 color2
	mva >txtfnt chbase
	
	lda regA
	ldx regX
	rti


.endl

; ---

CHANGES = 1
FADECHR	= 0

SCHR	= 127

; ---

.proc	NMI

	bit nmist
	bpl VBL

	jmp DLI.dli_start
dliv	equ *-2

VBL
	sta regA
	stx regX
	sty regY

	sta nmist		;reset NMI flag

	mwa #ant dlptr		;ANTIC address program

	;mva #@dmactl(narrow|dma|lineX1|players|missiles) dmactl	;set new screen width
	mva #scr32 dmactl 
	inc cloc		;little timer

; Initial values

	lda >fnt+$400*$00
	sta chbase
c0	lda #$00
	sta colbak
	lda #$02
	sta chrctl
	lda #$01
	sta gtictl
c1	lda #$06
	sta color1
c2	lda #$22
	sta color2
c3	lda #$00
	sta color3
s0	lda #$03
	sta sizep0
	sta sizep1
s1	lda #$00
	sta sizep2
s2	lda #$01
	sta sizep3
x0	lda #$57
	sta hposp0
x1	lda #$73
	sta hposp1
x2	lda #$9D
	sta hposp2
x3	lda #$92
	sta hposp3
c4	lda #$2E
	sta colpm0
c5	lda #$28
	sta colpm1
c6	lda #$24
	sta colpm2
c7	lda #$2C
	sta colpm3
x4	lda #$00
	sta hposm0
	sta hposm1
	sta hposm2
	sta hposm3
	sta sizem
	sta color0

	mwa #DLI.dli_start dliv	;set the first address of DLI interrupt

;this area is for yours routines

quit
	lda regA
	ldx regX
	ldy regY
	rti

.endp

; ---
	;run main
; ---

	opt l-

.MACRO	SPRITES
missiles
	.ds $100
player0
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF
	.he FF FF FF FF FF FF FF FF FF FF 00 00 00 40 40 40
	.he 40 40 40 0A 0A 0A 0A 0A 0A 10 10 10 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player1
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 FF FF FF FF FF DF D7 D7 D7 D7 AB AB AB AB AB
	.he AB D3 D3 D1 D1 D1 D1 8B 8B 8B 8B 8B 8B D5 D5 D5
	.he D5 D5 D5 AA AA AA AA AA AA 55 55 55 55 55 55 BA
	.he BA BA BA DD DD AA AA AA AA AA AA 55 55 55 55 55
	.he 55 AA AA D5 D5 D5 D5 AA AE AE AE D7 D7 AF AF AF
	.he AF AF AF 56 56 56 56 56 56 AF AF AF FF FF FF FF
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player2
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 FF FF FF FF FF FF FF FF FF FF DF DF DF DF DF
	.he DF F7 F7 F7 F7 F7 F7 BF BF BF BF BF BF BF BF BF
	.he BF BF BF F7 F7 F7 F7 F7 F7 EF EF EF EF EF EF FF
	.he FF FF FF FF FF ED ED ED ED ED ED DA DA DA DA DA
	.he DA BD BD BD BD BD BD FF FF FF FF FF FF EF EF EF
	.he EF EF EF 77 77 77 77 77 77 BF BF BF FF FF FF FF
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
player3
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 FF FF FF FF FF FF FF FF FF FF EF EF EF EF EF
	.he EF FB FB FB FB FB FB FF FF FF FF FF FF DF DF DF
	.he DF DF DF FF FF FF FF FF FF F7 F7 F7 F7 F7 F7 FF
	.he FF FF FF FF FF FD FD FD FD FD FD DF DF DF DF DF
	.he DF FB FB FB FB FB FB EB EB EB EB EB EB D5 D5 D5
	.he D5 D5 D5 CA EA CA EA EA EA D5 D5 D5 D5 FF FF FF
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	.he 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
.ENDM

USESPRITES = 1

.MACRO	DLINEW
	mva <:1 NMI.dliv
	ift [>?old_dli]<>[>:1]
	mva >:1 NMI.dliv+1
	eif

	ift :2
	lda regA
	eif

	ift :3
	ldx regX
	eif

	ift :4
	ldy regY
	eif

	rti

	.def ?old_dli = *
.ENDM

