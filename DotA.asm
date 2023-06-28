;DotA by matosimi 2023

color0	equ $2fc
hposp0	equ $d000
hposm0	equ $d004
sizep0	equ $d008
sizem	equ $d00c
trig0	equ $d010
colpm0	equ $d012
colpf0	equ $d016
colbk	equ $d01a
prior	equ $d01b
vdelay	equ $d01c ;shift PM by 1 scanline, first missiles,then players(bits)
gractl	equ $d01d ;BIT1-ACTIV.PMG
consol	equ $d01f
kbcode	equ $d209
random	equ $d20a
skctl	equ $d20f
porta	equ $d300 ;stick 0,1
portb	equ $d301
dmactl	equ $d400
dlistl	equ $d402
hscrol	equ $d404
pmbase	equ $d407
chbase	equ $d409
wsync	equ $d40a
vcount	equ $d40b
nmien	equ $d40e
nmist	equ $d40f

unzx7.token	equ $6e
unzx7.lenL	equ $6f	
octant		equ $70	;tmp var for atan2
ntsccolor		equ $71	;tmp for getcolor
dli_ptr		equ $80
vbi_ptr		equ $82
w1		equ $84
w2		equ $86
stereo		equ $c6 ;0=stereo detected
ntsc		equ $c7
ntsctimer		equ $c8
;$cb -> RMT zero page


code	equ $2000
vram	equ $b000

	run code
	
	org code
	
	icl "matosimi_macros.asx"
start
	pause 0
	sei
	detect_stereo
	detect_video_system
	mva #1 580	;boot on reset
	
	mva #$0 nmien 
	mva #$fe portb	;turn off osrom and basicrom
	mwa #NMI $fffa
	
	mwa #ingame_dl dlistl
	mwa #gameDli.dli dli_ptr ;vdslst
	mwa #gameVbi.vbi vbi_ptr
	mva #1+12+16+32 dmactl ;d400 = 559
	mva #$c0 nmien ;c0
	

	mva #200 atan2.x2
	mva #20 atan2.y2
	
loop
	
@	lda vcount
	cmp #20
	bne @-
	mva #$04 colpf0+2
	
	ldx atan2.y2
	lda atan2.x2
:3	lsr @
	add vramlinel,x
	sta poop
	lda vramlineh,x 
	adc #0
	sta poop+1
	mva random poop:$ffff
	
	mva ang:#30 draw_arrow.angle
	mva #1 draw_arrow.y
	sta draw_arrow.xch
	mva #10 count
	
loop2	draw_arrow
	lda #16 
	add:sta draw_arrow.y
	add #8
	sta atan2.y1
	inc draw_arrow.xch
	lda draw_arrow.xch
	asl @
	asl @
	asl @
	sta atan2.x1
	atan2
	sta draw_arrow.angle
	
	;inc draw_arrow.angle
	dec count
	bne loop2
	
	mva #$54 colpf0+2
	inc atan2.y2
	lda atan2.y2
	a_lt #160 loop
	mva #20 atan2.y2
	jmp loop
	
count	dta 20	
	
.proc	draw_arrow
	ldy y
	lda vramlinel,y
	add xch
	sta w1
	lda vramlineh,y
	adc #0
	sta w1+1	;w1 => arrow origin 
	lda angle
	lsr @
	tay
	mva angletabl,y w2
	mva angletabh,y w2+1
	
	ldx #15
	ldy #0
@	lda (w2),y
	sta (w1),y
	iny
	lda (w2),y
	sta (w1),y
	iny
	add16 #30 w1
	dex
	bpl @-
	rts
xch	dta 0
y	dta 0
angle	dta 0
angletabl	
.rept	128,#
	dta l(arrow+#*32)
.endr
angletabh
.rept	128,#
	dta h(arrow+#*32)
.endr
.endp	

vramlinel
.rept	160,#
	dta l(vram+#*32)
.endr

vramlineh
.rept	160,#
	dta h(vram+#*32)
.endr
	
.local 	gameVbi
vbi	inc 20
	rti
.endl	

.local	gameDli
dli	rti
.endl
	
NMI	bit nmist
	bpl nmi_vbi	;vbi
	jmp (dli_ptr)	;dli
nmi_vbi	jmp (vbi_ptr)
	
;returns ntsc color in A based on input pal color (in case ntsc is used)
.proc	getcolor (.byte a) .reg
pptr	lsr @
	stx ntsccolor	;save X-register for DLI calls
	tax
	lda ntsccolors128,x
	ldx ntsccolor
	rts

.proc	setpal
	mva #{rts} pptr
	rts	
.endp

;128 color table that matches PAL colors to NTSC
ntsccolors128
:8	dta #*2
:8	dta #*2+$20	;$10
:8	dta #*2+$30
:8	dta #*2+$40
:8	dta #*2+$50
:8	dta #*2+$60
:8	dta #*2+$70
:8	dta #*2+$80
:8	dta #*2+$90	;$80
:8	dta #*2+$a0	;$90 pal
:8	dta #*2+$b0	;$a0 pal
:5	dta #*2+$d0+2	;$b0 pal
:3	dta #*2+$d0+$a	;$b0 pal second part
:4	dta #*2+$e0+2	;$c0 pal
:4	dta #*2+$e0+8	;$c0 pal second part
:4	dta #*2+$12	;$d0 pal
	dta $e8,$1a,$1c,$1e	;$d0 pal second part 
:8	dta #*2+$f0	;$e0 pal
:8	dta #*2+$20	;$f0 pal	
.endp	
	
.proc	detect_stereo
	; By Draco
	; http://drac030.krap.pl/en-si-info.php
	sei
	mvx #0 SKCTL
	stx SKCTL+$10
	mvy #3 SKCTL+$10
	:2 sta WSYNC
	lda RANDOM
detect_loop
	and RANDOM
	inx
	bne detect_loop
	sty SKCTL
	cmp #$FF
	beq stereo_detected
	mva #1 stereo
	rts
stereo_detected
	mva #0 stereo
	rts
.endp
	
.proc	detect_video_system
	;detect video system
	mva #0 ntsc
	sta ntsctimer
	ldx 20
	inx
	inx
x1	lda vcount
	a_lt ntsc x2
	sta ntsc
x2	cpx 20
	bne x1
	lda ntsc
	a_lt #140 sys_ntsc
	mva #1 ntsc
	getcolor.setpal	;set getcolor to PAL (default is ntsc)
	rts
sys_ntsc	mva #0 ntsc
	;mva #2 titlergb.DLI.ntscadd	;set title screen green fade for NTSC
	rts
.endp

;compressor: https://github.com/antoniovillena/zx7mini
;http://xxl.atari.pl/zx7-decompressor/
.proc	unzx7
	lda #$80
	sta token
copyby	jsr GET_BYTE
	jsr PUT_BYTE
mainlo	jsr getbits
	bcc copyby
	lda #$01
	sta lenL
lenval	jsr getbits
	rol lenL
	bcs _ret	; koniec
	jsr getbits
	bcc lenval
	jsr GET_BYTE
	sta offsL
	lda ZX7_OUTPUT
	clc ; !!!! C=0
	sbc offsL:#$ff
	sta copysrc
	lda ZX7_OUTPUT+1
	sbc #$00
	sta copysrc+1
cop0	lda copysrc:$ffff
	inw copysrc
	jsr PUT_BYTE
	dec lenL
	bne cop0
	jmp mainlo

getbits	asl token	; bez c
	bne _ret
	jsr GET_BYTE
	rol @	; c
	sta token
_ret	rts

;token	dta 0	;moved to zero page
;lenL	dta 0

GET_BYTE	lda ZX7_INPUT:$ffff
	inw ZX7_INPUT
	rts

PUT_BYTE	sta ZX7_OUTPUT:$ffff
	inw ZX7_OUTPUT
	rts
.print "unzx7 length: ",*-unzx7
.endp	


;https://codebase64.org/doku.php?id=base:8bit_atan2_8-bit_angle

;; Calculate the angle, in a 256-degree circle, between two points.
;; The trick is to use logarithmic division to get the y/x ratio and
;; integrate the power function into the atan table. Some branching is
;; avoided by using a table to adjust for the octants.
;; In otherwords nothing new or particularily clever but nevertheless
;; quite useful.
;;
;; by Johan Forslöf (doynax)
.proc	atan2

	lda x1
	sbc x2
	bcs *+4
	eor #$ff
	tax
	rol octant

	lda y1
	sbc y2
	bcs *+4
	eor #$ff
	tay
	rol octant

	lda log2_tab,x
	sbc log2_tab,y
	bcc *+4
	eor #$ff
	tax

	lda octant
	rol
	and #%111
	tay

	lda atan_tab,x
	eor octant_adjust,y
	rts

x1	dta 0
x2	dta 0
y1	dta 0
y2	dta 0

octant_adjust	
	.byte %00111111		;; x+,y+,|x|>|y|
	.byte %00000000		;; x+,y+,|x|<|y|
	.byte %11000000		;; x+,y-,|x|>|y|
	.byte %11111111		;; x+,y-,|x|<|y|
	.byte %01000000		;; x-,y+,|x|>|y|
	.byte %01111111		;; x-,y+,|x|<|y|
	.byte %10111111		;; x-,y-,|x|>|y|
	.byte %10000000		;; x-,y-,|x|<|y|


	;;;;;;;; atan(2^(x/32))*128/pi ;;;;;;;;

atan_tab	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
	.byte $00,$00,$00,$00,$00,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$01,$01,$01
	.byte $01,$01,$01,$01,$01,$02,$02,$02
	.byte $02,$02,$02,$02,$02,$02,$02,$02
	.byte $02,$02,$02,$02,$02,$02,$02,$02
	.byte $03,$03,$03,$03,$03,$03,$03,$03
	.byte $03,$03,$03,$03,$03,$04,$04,$04
	.byte $04,$04,$04,$04,$04,$04,$04,$04
	.byte $05,$05,$05,$05,$05,$05,$05,$05
	.byte $06,$06,$06,$06,$06,$06,$06,$06
	.byte $07,$07,$07,$07,$07,$07,$08,$08
	.byte $08,$08,$08,$08,$09,$09,$09,$09
	.byte $09,$0a,$0a,$0a,$0a,$0b,$0b,$0b
	.byte $0b,$0c,$0c,$0c,$0c,$0d,$0d,$0d
	.byte $0d,$0e,$0e,$0e,$0e,$0f,$0f,$0f
	.byte $10,$10,$10,$11,$11,$11,$12,$12
	.byte $12,$13,$13,$13,$14,$14,$15,$15
	.byte $15,$16,$16,$17,$17,$17,$18,$18
	.byte $19,$19,$19,$1a,$1a,$1b,$1b,$1c
	.byte $1c,$1c,$1d,$1d,$1e,$1e,$1f,$1f


	;;;;;;;; log2(x)*32 ;;;;;;;;

log2_tab	.byte $00,$00,$20,$32,$40,$4a,$52,$59
	.byte $60,$65,$6a,$6e,$72,$76,$79,$7d
	.byte $80,$82,$85,$87,$8a,$8c,$8e,$90
	.byte $92,$94,$96,$98,$99,$9b,$9d,$9e
	.byte $a0,$a1,$a2,$a4,$a5,$a6,$a7,$a9
	.byte $aa,$ab,$ac,$ad,$ae,$af,$b0,$b1
	.byte $b2,$b3,$b4,$b5,$b6,$b7,$b8,$b9
	.byte $b9,$ba,$bb,$bc,$bd,$bd,$be,$bf
	.byte $c0,$c0,$c1,$c2,$c2,$c3,$c4,$c4
	.byte $c5,$c6,$c6,$c7,$c7,$c8,$c9,$c9
	.byte $ca,$ca,$cb,$cc,$cc,$cd,$cd,$ce
	.byte $ce,$cf,$cf,$d0,$d0,$d1,$d1,$d2
	.byte $d2,$d3,$d3,$d4,$d4,$d5,$d5,$d5
	.byte $d6,$d6,$d7,$d7,$d8,$d8,$d9,$d9
	.byte $d9,$da,$da,$db,$db,$db,$dc,$dc
	.byte $dd,$dd,$dd,$de,$de,$de,$df,$df
	.byte $df,$e0,$e0,$e1,$e1,$e1,$e2,$e2
	.byte $e2,$e3,$e3,$e3,$e4,$e4,$e4,$e5
	.byte $e5,$e5,$e6,$e6,$e6,$e7,$e7,$e7
	.byte $e7,$e8,$e8,$e8,$e9,$e9,$e9,$ea
	.byte $ea,$ea,$ea,$eb,$eb,$eb,$ec,$ec
	.byte $ec,$ec,$ed,$ed,$ed,$ed,$ee,$ee
	.byte $ee,$ee,$ef,$ef,$ef,$ef,$f0,$f0
	.byte $f0,$f1,$f1,$f1,$f1,$f1,$f2,$f2
	.byte $f2,$f2,$f3,$f3,$f3,$f3,$f4,$f4
	.byte $f4,$f4,$f5,$f5,$f5,$f5,$f5,$f6
	.byte $f6,$f6,$f6,$f7,$f7,$f7,$f7,$f7
	.byte $f8,$f8,$f8,$f8,$f9,$f9,$f9,$f9
	.byte $f9,$fa,$fa,$fa,$fa,$fa,$fb,$fb
	.byte $fb,$fb,$fb,$fc,$fc,$fc,$fc,$fc
	.byte $fd,$fd,$fd,$fd,$fd,$fd,$fe,$fe
	.byte $fe,$fe,$fe,$ff,$ff,$ff,$ff,$ff
	
.endp

arrow	ins "all_rem2.mic"


	.align $100
ingame_dl
	dta $70,$70,$70
	dta $4f,a(vram)
:127	dta $f
	dta $4f,a(vram+$1000)
:63	dta $f
	dta $41,a(ingame_dl)	

	guard vram
