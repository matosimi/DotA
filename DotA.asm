;DotA by matosimi 2023

;todo: funny stuff: level 10, arrow on the left, third from top changes its angle
;                   as the fast orbiter reaches top/bottom position

debug_skip_title = 1
debug_level = 0	;1 uses levxx.dat
debug_visible_dot = 1
debug_music_off = 1

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


zpshift		equ $20 ;$20 bytes (till $3f)
shcount		equ $41	;shift count

unzx7.token	equ $6e
unzx7.lenL	equ $6f	
octant		equ $70	;tmp var for atan2
ntsccolor		equ $71	;tmp for getcolor
level		equ $72	;level
stick		equ $73	;joy
xpos		equ $74	;pmg cursor position
ypos		equ $75
dotx		equ $76	;currently tracked dot coords
doty		equ $77
hit		equ $78	;0=dot hit
levaccent		equ $79
dli_ptr		equ $80
vbi_ptr		equ $82
w1		equ $84
w2		equ $86
stereo		equ $c6 ;0=stereo detected
ntsc		equ $c7
ntsctimer		equ $c8
;$cb -> RMT zero page

mypmbase	equ $1400
code	equ $2000
vram	equ $e000	;to $f7ff
leveldata	equ $fd00 ;to $ff80

	run start
	
	org code
	
	icl "matosimi_macros.asx"
.local	init
	mwa #idl $230
	mva #33 559	;narrow screen
	mva #$78 $2c4 
	pause 0
	mva #$ff portb ;turn on osrom a load next block
	/*mva #1 init
	ldx >ivbi
	ldy <ivbi
	lda #6
	jsr $e45c*/
	rts
idl	
:10	dta $70
	dta $49,a(inivram)
:7	dta $9
	dta $70
	;dta 2
	dta $41,a(idl)

inivram	
:8*8	dta 0

/*ivbi	dec init
	bne ivbiout
	mva #4 init
	inc init+1
	lda init+1
	and #$07
:3	asl @
	tax
	ldy #0
@	mva iniani,x inivram+3,y
	tya
	add #8
	tay
	inx
	cpy #8*8
	bne @-
ivbiout	jmp $e45f 

iniani	  
	dta $ff, $c3, $c3, $c3, $cf, $f3, $c3, $ff
	dta $ff, $c3, $cf, $c3, $f3, $c3, $c3, $ff
	dta $ff, $c3, $cf, $f3, $c3, $c3, $c3, $ff
	dta $ff, $c3, $ff, $c3, $c3, $c3, $c3, $ff
	dta $ff, $c3, $f3, $cf, $c3, $c3, $c3, $ff
	dta $ff, $c3, $c3, $f3, $c3, $cf, $c3, $ff
	dta $ff, $c3, $c3, $c3, $f3, $cf, $c3, $ff
	dta $ff, $c3, $c3, $c3, $c3, $ff, $c3, $ff	
*/	
last

copy_to_c000
	pause 0
	mva #$0 nmien 	;disable interrupts
	mva #$fe portb	;turn off osrom and basic rom
	ldy #0
@
:16	mva $4000+$100*#,y $c000+$100*#,y
	dey
	bne @-
	mva #$ff portb	;turn on os rom and load
	mva #$40 nmien	;enable vbi
	rts
.endl
	ini init
	
	org $4000
	ins 'dota_c000.rmt',6
	
	ini init.copy_to_c000 
	
	org init.last
start
	pause 0
	sei
	detect_stereo
	detect_video_system
	;todo: modify dli colors with getcolor
	mva #1 580	;boot on reset
	
	ift debug_skip_title == 0
	jsr g2f.main
	eif
	
	mva #$0 nmien 
	mva #$fe portb	;turn off osrom and basicrom
	mwa #NMI $fffa
	
	mwa #ingame_dl dlistl
	mwa #gameDli.dli dli_ptr ;vdslst
	mwa #gameVbi.vbi vbi_ptr
	mva #1+12+16+32 dmactl ;d400 = 559
	mva #$c0 nmien ;c0

	lda #0 ;songline	
	ldx #$00
	ldy #$c0	;song is always depacked to $c000
	jsr rmt.rmt_init
	

	mva #200 atan2.x2
	mva #20 atan2.y2
	;mva #0 draw_shifted_arrow.angle
	
	pmg.init
/*
;some pmg shit
:4	mva #$18+#*$30 colpm0+#

	mva #$78 colpm0	;blue cursor

:4	mva #65+9*# hposp0+#
.rept 4,#
?x = #
:16	mva #$ff mypmbase+$100*?x+#+50
.endr
	*/
	mva #13 level

levelinit
	ldx #0
	txa
@
:24	sta vram+#*$100,x
	dex
	bne @-
	
	print_level	
	
	getcolor #$b0
	sta levaccent ;green
	load_level
	process_leveldata
	nextdot.init
	mva #-1 hit
	pmg.draw_gtia_overlay
	fadein
	mva #176 animate_hit.anix
	dynamics.update
	
loop
	control
	pmg.draw_player
	environment
	draw_level
	pause 0
	jmp loop
/*	
@	lda vcount
	cmp #20
	bne @-
	mva #$04 colpf0+2 */
	
;demo
/*
	mva atan2.y2 draw_shifted_arrow.y
	mva atan2.x2 draw_shifted_arrow.x
	draw_shifted_arrow

	mva #1 draw_arrow.y
	sta draw_arrow.xch
	mva #25 count
	
loop2	lda #16 
	add draw_arrow.y
	a_lt #160 nores2
	lda #0	
nores2	sta draw_arrow.y
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
	draw_arrow	

	lda draw_arrow.xch
	a_lt #28 nores 
	mva #0 draw_arrow.xch
nores
	dec count
	bne loop2
	
	mva #$54 colpf0+2
	inc atan2.y2
	dec atan2.x2
	inc draw_shifted_arrow.angle
	lda atan2.y2
	a_lt #160 loop
	mva #20 atan2.y2
	jmp loop
	
count	dta 20	
	
	*/
	
.proc	fadein
	ldx #$00
@	txa
	ora levaccent
	sta gameVbi.accent
	txa
	sub #$8
	bpl nozero
	lda #0
nozero	sta gameVbi.darkone
	
	pause 1
	inx
	cpx #$10
	bne @-
	rts
.endp	

.proc	fadeout
	ldx #$0f
@	txa
	ora levaccent
	sta gameVbi.accent
/*	txa
	sub #$8
	bpl nozero
	lda #0
nozero	sta gameVbi.darkone
*/
	pause 1
	dex
	cpx #6
	bne @-
	rts
.endp	
	
.proc	environment
	dynamics
	update_dot_coords
	
	ift debug_visible_dot == 1
	lda dotx
	add #64
	sta hposp0+2
	ldx #0
	txa
@	sta mypmbase+$200,x
	dex
	bne @-
	lda doty
	add #pmg.draw_player.topshift+2+5
	tax
	lda #%00011000
:3	sta mypmbase+$200+:1,x
	mva #$1a colpm0+2
	eif
	
	lda hit
	bmi @+
	animate_hit
	rts
@	animate_hit.orbiting
	rts
.endp

.proc	animate_hit
	;clean up whole player lines $20-$c4
	ldx #$c4-$20
	lda #0
@	sta mypmbase+$100+$20,x
	dex
	bne @-
	;boom - 5 frames, pause 4, spawn 5 frames pause 4,pause 50, spawn reversed 5 frames, pause 4
	mvx #0 phase
x1	ldy bspframes,x
	
	lda bspxposes,x
	add dotx 
	sta gamedli.dotxpos
	
	lda doty
	add #pmg.draw_player.topshift+2
	tax	
	
/*	mva #11 rpt
@	mva boom.SPR_1_FRM_1,y mypmbase+$100,x
	inx
	iny
	dec rpt
	bpl @-*/
:12	mva boom+#,y mypmbase+$100+#,x

	
	inc phase
	pause 3
	ldx phase
	cpx #15
	beq done
	cpx #10
	bne x1
	pause 100
	lda nextdot.current
	beq nextlevel
	jmp x1
	
nextlevel	fadeout
	inc level
	pla
	pla
	pla
	pla
	jmp levelinit
	
done	mva #-1 hit
	mva #0 phase
	;orbit animation can start asynchronously
	nextdot	
x0	rts
phase	dta -1
tmp	dta 0
rpt	dta 0
anix	dta 0
aniy	dta 0

.proc	orbiting
	ldx phase
	ldy s12,x
	
	lda #64
	add anix 
	sta gamedli.dotxpos
	
	lda aniy
	add #pmg.draw_player.topshift+2
	tax
	lda #0	;cleanup up/down 2px
	sta mypmbase+$100-2,x
	sta mypmbase+$100-1,x
	sta mypmbase+$100+12,x
	sta mypmbase+$100+13,x
:12	mva orbit+#,y mypmbase+$100+#,x	;draw
	inc flip
	lda flip
	lsr @
	bcc x0
	inc phase
	lda phase
	a_ge #12 zero
x0	rts
zero	mva #0 phase
	rts
flip	dta 0
.endp

;dot type taken from nextdot
.proc	init
	;delete orbit anim
	lda aniy
	add #pmg.draw_player.topshift+2
	tax
	ldy #12
	lda #0
@	sta mypmbase+$100,x
	inx
	dey
	bne @-
	
	;select proper letter animation
	ldx nextdot.current
	ldy s24,x
	ldx #23
@	mva spawn.leta,y spawn.SPR_1_FRM_0,x
	dey
	dex
	bpl @- 
	mva #0 phase
	sta hit
	mva dotx animate_hit.anix
	mva doty animate_hit.aniy
	rts
.endp

s24	;last item of 24s in row
:6	dta #*24+23
s12	;first item of 12s in row
:12	dta #*12
bspframes	;boom+spawn+spawn reversed frames
:5	dta #*12		;boom
:5	dta [9-#]*12	;spawn 
:5	dta [5+#]*12	;spawn reversed
bspxposes	
:5	dta 64
:10	dta 64+3
;animation: boom -> spawn reversed, pause, spawn -> orbit

.local	boom
SPR_1_FRM_1	dta $00, $00, $00, $18, $3c, $3c, $3c, $3c, $3c, $18, $00, $00 
SPR_1_FRM_2	dta $00, $00, $18, $24, $5a, $5a, $5a, $5a, $5a, $24, $18, $00 
SPR_1_FRM_3	dta $00, $18, $24, $42, $91, $99, $99, $99, $89, $42, $24, $18 
SPR_1_FRM_4	dta $00, $08, $20, $02, $80, $19, $18, $98, $01, $40, $04, $10 
SPR_1_FRM_5	dta $00, $00, $00, $00, $00, $18, $18, $18, $00, $00, $00, $00
.endl

;letter reversed spawn
.local 	spawn
SPR_1_FRM_0 	dta $00, $00, $04, $0e, $0e, $db, $db, $df, $1f, $1b, $00, $00
SPR_1_FRM_1	dta $00, $00, $00, $04, $0e, $df, $db, $df, $0e, $00, $00, $00
SPR_1_FRM_2	dta $00, $00, $00, $08, $1c, $dc, $dc, $dc, $1c, $00, $00, $00
SPR_1_FRM_3	dta $00, $00, $00, $00, $00, $d8, $d8, $d8, $00, $00, $00, $00
SPR_1_FRM_4	dta $00, $00, $00, $00, $00, $c0, $d0, $d0, $00, $00, $00, $00

leta	dta $00, $00, $04, $0e, $0e, $db, $db, $df, $1f, $1b, $00, $00
	dta $00, $00, $00, $04, $0e, $df, $db, $df, $0e, $00, $00, $00

letb	dta $00, $00, $1e, $1f, $1b, $de, $db, $db, $1f, $1e, $00, $00
	dta $00, $00, $00, $1e, $1e, $df, $db, $df, $1e, $00, $00, $00
	
letc	dta $00, $00, $0e, $1f, $1b, $d8, $d8, $db, $1f, $0e, $00, $00
	dta $00, $00, $00, $0e, $1f, $df, $d8, $df, $0e, $00, $00, $00

letd	dta $00, $00, $1e, $1f, $1b, $db, $db, $db, $1f, $1e, $00, $00
	dta $00, $00, $00, $1e, $1f, $df, $db, $df, $1e, $00, $00, $00
	
lete	dta $00, $00, $1f, $1f, $18, $de, $de, $d8, $1f, $1f, $00, $00
	dta $00, $00, $00, $1f, $1f, $df, $dc, $df, $1f, $00, $00, $00
	
letf	dta $00, $00, $1f, $1f, $18, $dc, $dc, $d8, $18, $18, $00, $00
	dta $00, $00, $00, $1f, $1f, $df, $dc, $d8, $18, $00, $00, $00

letg	dta $00, $00, $0e, $1f, $1b, $d8, $db, $db, $1f, $0f, $00, $00
	dta $00, $00, $00, $0e, $1f, $df, $dc, $df, $0f, $00, $00, $00

leth	dta $00, $00, $1b, $1b, $1b, $df, $df, $db, $1b, $1b, $00, $00
	dta $00, $00, $00, $1e, $1e, $de, $de, $de, $1e, $00, $00, $00
.endl
.local	orbit
SPR_1_FRM_0	dta $00, $00, $00, $00, $00, $18, $1a, $1a, $00, $00, $00, $00
SPR_1_FRM_1	dta $00, $00, $00, $02, $02, $18, $18, $18, $00, $00, $00, $00
SPR_1_FRM_2	dta $00, $04, $04, $00, $00, $18, $18, $18, $00, $00, $00, $00
SPR_1_FRM_3	dta $00, $08, $08, $00, $00, $18, $18, $18, $00, $00, $00, $00
SPR_1_FRM_4	dta $00, $20, $20, $00, $00, $18, $18, $18, $00, $00, $00, $00
SPR_1_FRM_5	dta $00, $00, $00, $40, $40, $18, $18, $18, $00, $00, $00, $00
SPR_1_FRM_6	dta $00, $00, $00, $00, $00, $58, $58, $18, $00, $00, $00, $00
SPR_1_FRM_7	dta $00, $00, $00, $00, $00, $18, $18, $58, $40, $00, $00, $00
SPR_1_FRM_8	dta $00, $00, $00, $00, $00, $18, $18, $18, $00, $00, $20, $20
SPR_1_FRM_9	dta $00, $00, $00, $00, $00, $18, $18, $18, $00, $00, $08, $08
SPR_1_FRM_10	dta $00, $00, $00, $00, $00, $18, $18, $18, $00, $00, $04, $04
SPR_1_FRM_11	dta $00, $00, $00, $00, $00, $18, $18, $18, $02, $02, $00, $00
.endl


.endp

	
.proc	control
	lda trig0
	jeq hitbox
	
joy	lda porta
	sta stick
	
	lda #8
	bit stick
	jeq right
	lda #4
	bit stick
	jeq left
ud	lda #2
	bit stick
	jeq down
	lda #1
	bit stick
	jeq up
	rts
	
right	inc xpos
	lda xpos
	a_ge #$7a left
	jmp ud	
left	dec xpos
	beq right
	jmp ud
up	dec ypos
	beq down
	rts
down	inc ypos
	lda ypos
	a_ge #$95 up
	rts
		
hitbox	lda xpos
	add #2-1
	sbc dotx
	cmp #2+2-1	;w1+w2-1
	bcs joy ;none
	
	lda doty
	add #2+4-1
	sbc ypos
	cmp #3+2-2	;h1+h2-1
	bcs joy ;none
	
	
	animate_hit.init
	
	;mva #4 animate_hit.phase
	;mva #$02 gameVbi.levaccent
	rts
		
none	;mva #$be gameVbi.levaccent
	rts 
.endp

.proc	update_dot_coords
	ldx nextdot.index
	lda dots_array.x,x 
	lsr @	;half the x-resolution
	sta dotx
	mva dots_array.y,x doty
	ldx nextdot.previndex
	bmi x0
	lda dots_array.x,x 
	lsr @	;half the x-resolution
	sta animate_hit.anix
	mva dots_array.y,x animate_hit.aniy	
x0	rts
.endp

.proc	nextdot
	mva index previndex
	dec current
	bmi leveldone
	ldx process_leveldata.dots	;number of dots in the level
@	dex
	bmi leveldone
	lda dots_array.number,x
	cmp current
	bne @-
	stx index
	lda dots_array.x,x 
	lsr @	;half the x-resolution
	sta dotx
	mva dots_array.y,x doty
	
	ift debug_visible_dot == 1
	lda dotx
	add #64
	sta hposp0+2
	ldx #0
	txa
@	sta mypmbase+$200,x
	dex
	bne @-
	lda doty
	add #pmg.draw_player.topshift+2+5
	tax
	lda #%00011000
:3	sta mypmbase+$200+:1,x
	mva #$1a colpm0+2
	eif	
	rts
leveldone	;mva #$00 colpf0+2
	fadeout
	inc current ;debug
	ldx process_leveldata.arrows
	dex
@	lda arrows_array.angle,x
	eor #$80
	sta arrows_array.angle,x
	dex
	bpl @-
	rts
	
.proc	init
	mva process_leveldata.dots current
	mva #-1 previndex
	sta index
	jmp nextdot
.endp	
current	dta 0
index	dta 0
previndex	dta 0
.endp
	
.proc	load_level
	ift debug_level == 0
	
	mwa #leveldata unzx7.ZX7_OUTPUT
	ldx level
	mva levels.low,x unzx7.ZX7_INPUT
	mva levels.high,x unzx7.ZX7_INPUT+1
	unzx7
	rts
	
	els
	
	mwa #leveldata ptr
	;ldx level
	;mva levels.low,x w1
	;mva levels.high,x w1+1
	mwa #levels.levelxx w1
	
	ldx #2	;levelsize $280
	ldy #0
@	lda (w1),y
	sta ptr:leveldata,y
	dey
	bne @-
	inc ptr+1
	inc w1+1
	dex
	bmi out
	bne @-
	ldy #$7f	;half page
	jmp @-
	
out	mva (w1),y leveldata+$200	;last byte
	rts
	eif
.endp
	
.proc	draw_level
	;count the arrows and draw only as many as fits into frame
	;next frame: continue
	ldx process_leveldata.arrows
	dex
	stx count
	ldx nextdot.index 
	
	lda dots_array.x,x
	sta atan2.x2
	lda dots_array.y,x
	sta atan2.y2
	
loop	ldx count
	lda arrows_array.x,x
	sta atan2.x1
	sta draw_shifted_arrow.x
:3	lsr @
	sta draw_arrow.xch
	lda arrows_array.y,x
	sta atan2.y1
	sta draw_arrow.y
	
	;lda arrows_array.special,x
	;bmi @+
	;inc draw_arrow.noclear	;set above+below cleaning for moving arrows
		
@	mva arrows_array.angle,x draw_arrow.angle
	lda arrows_array.type,x
	tax
	mva arrowtype,x draw_arrow.type
	draw_shifted_arrow
	
	atan2
	
	;calculates difference between target and current angle of arrow
	;then takes quarter of the difference and add/subtract from current
	;a contains target angle
	ldx count
	sub draw_arrow.angle
	beq next
	a_lt #127 half
	eor #$ff
	lsr @
	lsr @
	bne @+
	lda #1	;if quarter=0 then make it 1 so it can finetune
		
@	ldx count
	sta tmp
	lda arrows_array.angle,x 
	sub tmp
	sta arrows_array.angle,x
	jmp next 
	
half	lsr @
	lsr @
	bne @+
	lda #1	;if quarter=0 then make it 1 so it can finetune
@	ldx count
	add:sta arrows_array.angle,x	
	
next	dec count
	bpl loop
	
	rts
count	dta 0
tmp	dta 0
;curdot	dta 0
.endp
	
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
	lda angletabh,y 
	add type
	sta w2+1
	
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
	/*
	lda noclear
	beq x0
	;clear 1 line below
	lda #$ff
	sta (w1),y
	iny
	sta (w1),y
	;sub1616 #32*18+30 w1	;clear 1 line above
	sbw w1 #32*18+1
	lda #$ff
	sta (w1),y
	iny
	sta (w1),y
	lda #0
	sta noclear */
x0	rts
xch	dta 0
y	dta 0
type	dta 0
angle	dta 0
noclear	dta 0 


.endp

.proc	draw_shifted_arrow
	lda x
	and #$07
	jeq noshift
	;perform shifting
	sta shcount
	tax
	mva mask_le,x mask1
	sta mask12
	mva mask_ri,x mask2
	sta mask22
	lda draw_arrow.angle
	lsr @
	tay
	mva angletabl,y w2
	lda angletabh,y 
	add draw_arrow.type
	sta w2+1
		
	lda shcount
	a_ge #5 shift_left
	
	;initial shift right from arrowtable to zp	
	ldy #31
	lda (w2),y
	lsr @
	
	ldy #0
.rept 32,#
	lda (w2),y
	ror @
	sta zpshift+:1
	iny
.endr
	dec shcount
	beq draw
	;repeated shifts right
@
:32	ror zpshift+#
	dec shcount
	bne @-
	
	;draw
draw	lda x
:3	lsr @
	ldy draw_arrow.y
	add vramlinel,y
	sta w1
	lda vramlineh,y
	adc #0
	sta w1+1
	
	ldx #15
	ldy #0
@	lda zpshift,y 
	and mask1:#$ff
	sta (w1),y
	iny
	mva zpshift,y (w1),y
	iny 
	lda zpshift,y 
	and mask2:#$ff
	sta(w1),y
	add16 #30 w1
	dex
	bpl @-
	;clear 1 line below
	/*
	lda #0
	sta (w1),y
	iny
	sta (w1),y
	iny
	sta (w1),y
	add16 #30 w1
	lda #$00
	sta (w1),y
	iny
	sta (w1),y
	iny
	sta (w1),y */
	rts	

		
shift_left
	lda #8
	sub shcount
	sta shcount
	;initial shift left from arrowtable to zp	
	ldy #0
	lda (w2),y
	asl @
	
	ldy #31
.rept 32,#
	lda (w2),y
	rol @
	sta zpshift+31-:1
	dey
.endr
	dec shcount
	jeq draw2
	;repeated shifts left
@
:32	rol zpshift+31-#
	dec shcount
	bne @-

	;draw2 - for left shifted
draw2	lda x
:3	lsr @
	ldy draw_arrow.y
	add vramlinel,y
	sta w1
	lda vramlineh,y
	adc draw_arrow.type
	sta w1+1
	
	ldx #15
	ldy #0
	lda zpshift+31
	jmp skipfirst
@	lda zpshift-1,y 
skipfirst	and mask12:#$ff
	sta (w1),y
	iny
	mva zpshift-1,y (w1),y
	iny 
	lda zpshift-1,y 
	and mask22:#$ff
	sta(w1),y
	add16 #30 w1
	dex
	bpl @-
	;clear 1 line below
	/*lda #$00
	sta (w1),y
	iny
	sta (w1),y
	iny
	sta (w1),y
	add16 #30 w1
	lda #$00
	sta (w1),y
	iny
	sta (w1),y
	iny
	sta (w1),y */
	rts	
	
noshift	;mva y draw_arrow.y
	;mva angle draw_arrow.angle
	;mva type draw_arrow.type
	lda x
:3	lsr @
	sta draw_arrow.xch
	jmp draw_arrow
	
x	dta 0
;y	dta 0
;type	dta 0
;angle	dta 0
mask_le	dta 0,%01111111,%00111111,%00011111,%00001111,%00000111,%00000011,%00000001
mask_ri	dta 0,%10000000,%11000000,%11100000,%11110000,%11111000,%11111100,%11111110
.endp

arrowtype	dta -1,0,16,32,48,64
	
angletabl	
.rept	128,#
	dta l(arrow+#*32)
.endr
angletabh
.rept	128,#
	dta h(arrow+#*32)
.endr

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
	pha
	mva accent:#$be colpf0+2	;color accent can vary
	mva darkone:#$08 colpf0+1
	mva #1 prior
	mva >txtfnt chbase
	mwa #gameDli.dli dli_ptr
	
	lda ntsc
	bne vbpal
	inc ntsctimer
	lda ntsctimer
	cmp #6
	bne vbpal
	mva #255 ntsctimer
	jmp vbskip
;pal
vbpal
vbskip
	pla
	rti
.endl	

.local	gameDli
;gtia line + playfield 
dli	pha
	sta wsync
	mva #$03 sizep0
	sta sizep0+1
	mva #$20 hposp0
	mva #$c0 hposp0+1
	mva #0 colpm0
	sta colpm0+1
	sta wsync
	mva colgtia0:#$40 colpf0+4
	mva #$41 prior
	sta wsync
	mva #1 prior
	mva #$00 colpf0+4
	sta sizep0
	sta sizep0+1
	mva playerxpos:#1 hposp0
	mva dotxpos:#1 hposp0+1
	mva colplayer:#$78 colpm0
	mva coldot:#$38 colpm0+1
	mwa #dli2 dli_ptr
	pla
	rti
	
;gtia line + status 	
dli2	pha
	sta wsync
	mva #$03 sizep0
	sta sizep0+1
	mva #$20 hposp0
	mva #$c0 hposp0+1
	mva #0 colpm0
	sta colpm0+1
	sta wsync
	mva colgtia1:#$40 colpf0+4
	mva #$41 prior
	mva #$06 colpf0+1
	mva colstatus:#$2c colpf0+2	;color of statusbar
	sta wsync
	mva #1 prior
	mva #$00 colpf0+4
	sta sizep0
	sta sizep0+1
	mwa #dli3 dli_ptr
	pla
	rti

;gtia line	
dli3	phr
	sta wsync
	mva #$03 sizep0
	sta sizep0+1
	mva #$20 hposp0
	mva #$c0 hposp0+1
	mva #0 colpm0
	sta colpm0+1
	sta wsync
	mva colgtia2:#$40 colpf0+4
	mva #$41 prior
	sta wsync
	mva #1 prior
	mva #$00 colpf0+4

	;music
	lda ntsc
	bne pal
	lda ntsctimer
	bmi frameskip
pal
	ift debug_music_off == 0 
;		ift debug_vbi_meter == 1
;		mva #$6a colpf0+4
;		eif
	;lda unpack_music_init.silence
	;beq @+
	jsr rmt.rmt_play
	;jmp @+1
;@	jsr rmt.rmt_silence
;@	
;		ift debug_vbi_meter == 1
;		mva #$00 colpf0+4
;		eif
	eif
frameskip	plr	
	rti
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
;.print "unzx7 length: ",*-unzx7
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

.local 	pmg
.proc	init
	mva >mypmbase pmbase
	mva #$03 gractl
	clean_all
	mva #1 xpos
	sta ypos
	rts
.endp

;clean up the PMGs
.proc	clean_all
	lda #0
	tax
@
:5	sta mypmbase-$100+$100*#,x
	dex
	bne @-
	rts
.endp

.proc	draw_player
topshift	equ 35
	lda #0
	ldy ypos
	sta mypmbase+topshift-1,y
	sta mypmbase+topshift+11,y
	ldx #10
@	mva pldata,x mypmbase+topshift,y
	iny
	dex
	bpl @-
	lda hit
	beq @+
	lda xpos 
	add #63
@	sta gameDli.playerxpos
	rts
pldata	dta $24, $66, $42, $00, $00, $00, $00, $00, $42, $66, $24
.endp

.proc	draw_gtia_overlay
	lda #255
:2	sta mypmbase+$20+#*$100
:2	sta mypmbase+$c5+#*$100
:2	sta mypmbase+$d2+#*$100
	rts
.endp
.endl

.proc	print_level
	ldx #0
	lda level
@	a_lt #10 x1
	sub #10
	inx
	bne @-
	
x1	ora #$10
	sta infobar+9
	txa
	ora #$10
	sta infobar+8
	rts
.endp

.proc	process_leveldata
	mwa #leveldata w1
	mva #2 page
	ldy #0
	sty dots
	sty arrows
	sty x
	sty y
@	lda (w1),y
	beq next
	a_lt #6 setarrow
	beq setdot
next	inc x
	lda x
	a_lt #32 noincy
	inc y	
	mva #0 x
noincy	iny
	bne @-
	inc w1+1
	dec page
	bne @-
;half of 3rd page
@	lda (w1),y
	beq next2
	a_lt #6 setarrow
	beq setdot
next2	inc x
	lda x
	a_lt #32 noincy2
	inc y
	mva #0 x	
noincy2	iny
	bpl @-		
	rts
	
;set dot
setdot	ldx dots
	lda x
:3	asl @
	sta dots_array.x,x
	lda y
:3	asl @
	sub #1	;small compensation to be in exact position
	sta dots_array.y,x
	iny
	lda (w1),y
	cmp #$0e
	beq notpossible
	a_out2 #$10 #$19 notpossible
	and #$0f
	sta dots_array.number,x
	inc dots
	dey
	lda page
	jeq next2
	jne next
notpossible
	dta 2
;set arrow
.local	setarrow
	ldx arrows
	sta arrows_array.type,x
	lda x
:3	asl @
	sta arrows_array.x,x
	lda y
:3	asl @
	sta arrows_array.y,x
	mva random arrows_array.angle,x
	iny
	lda (w1),y
	cmp #$0e
	beq nospecial
	a_out2 #$10 #$19 nospecial
	and #$0f
	skip2
nospecial	lda #$ff
	sta arrows_array.special,x
	inc arrows
	dey
	lda page
	jeq next2
	jne next
.endl
	
x	dta 0
y	dta 0	
page	dta 2
dots	dta 0
arrows	dta 0
.endp

.local	dots_array
x	;in pixels with origin at top left corner of playfield
:10	dta 0
y	
:10	dta 0
number
:10	dta -1
.endl

.local	arrows_array
x
:40	dta 0
y	
:40	dta 0
special
:40	dta 0
type
:40	dta 0
angle
:40	dta 0
.endl

;level dynamics
.proc	dynamics
	jmp address:l00
	
.proc	update
	lda level
	asl @
	tax
	mwa routtab,x address
	rts
.endp
	
routtab	
.rept 4 ;levels.sets
?i = #
.rept 4,#,?i
	dta a(l:2:1)
.endr
.endr

l00
l01
l02
l03	rts

.local l10	;left/right
	inc phase
	lda phase 
	bmi x1
	ldx nextdot.index 
	dec dots_array.x,x
	rts
	
x1	ldx nextdot.index 
	inc dots_array.x,x
	rts
zero	mva #0 phase
	rts	
	
phase	dta 0
.endl

.local l11	;right/left
	inc phase
	lda phase 
	a_ge #144 zero
	a_ge #72 x1
	ldx #0
	;bne zero
	inc dots_array.x,x
	rts
	
x1	ldx #0 
	;bne zero
	dec dots_array.x,x
	rts
zero	mva #0 phase
	rts	
	
phase	dta 0
.endl
l12	rts

.local	l13	;left/right 2 arrows (0, 7)	
hack	inc phase	;switching $ce,$ee
	lda phase
	a_ge #160 x1
	inc arrows_array.x
	dec arrows_array.x+7
	rts
x1	dec phase
	inc phase2
	lda phase2
	a_ge #160 x2
	dec arrows_array.x
	inc arrows_array.x+7
	rts
x2	mva #0 phase
	sta phase2
	rts
	
phase 	dta 0
phase2	dta 0
.endl

.local	l20	;up,down (4, 5)
	inc phase
	lda phase
	a_ge #112*2 zero
	a_ge #112 down
	;up
	dec arrows_array.y+4
	dec arrows_array.y+5
	rts
down	inc arrows_array.y+4
	inc arrows_array.y+5
	rts
zero	mva #0 phase
	rts
	
phase	dta 0
.endl

.local	l21
	inc phase
	ldx phase
	lda sin64,x
	add #56
	sta dots_array.x
	lda sin64+64,x
	add #8
	sta dots_array.y
	rts
phase	dta 0
.endl

;SIN(centre,amp,size[,first,last])
sin64	dta sin(64,48,255,0,255+64)

.local	l22	;circles (arr 0,4)
	inc phase
	ldx phase
	txa
	and #$01
	bne @+
	inc phase2
@	ldy phase2
	lda sin64,x
	add #56
	sta arrows_array.x
	lda sin64,y
	lsr @
	add #56+32
	sta arrows_array.x+4
	lda sin64+64,x
	add #8
	sta arrows_array.y
	lda sin64+64,y
	lsr @
	add #8+32
	sta arrows_array.y+4
	
	rts
phase	dta 0
phase2	dta 0
.endl
.local	l23	;triangles (0 |\,2 /|) , diag \ 1
	inc phase
	lda phase
	;triangles
	a_ge #170 m3
	a_ge #85 m2
	inc dots_array.x
	inc dots_array.y
	dec dots_array.x+2
	jmp diag
m2	dec dots_array.x
	inc dots_array.x+2
	dec dots_array.y+2
	jmp diag
m3	dec dots_array.y
	inc dots_array.y+2	
	
diag	ldx phase
	lda sin64,x
	add #56
	sta dots_array.x+1
	lda sin64,x
	lsr @
	add #40
	sta dots_array.y+1
	rts
phase	dta 0
.endl

.local	l30	;0,1 - LR, 2-rect
	inc phase
	lda phase
	bmi back
	inc dots_array.x
	dec dots_array.x+1
	jmp rect	
back	dec dots_array.x
	inc dots_array.x+1
rect	ldx rindex
	lda rphase,x
	a_ge bounds,x next
	inc rphase,x
	jmp handler:up
next	mva #0 rphase,x
	inx
	cpx #4
	bne newhandler
	ldx #0 
newhandler
	stx rindex
	txa
	asl @
	tax
	mwa handlers,x handler
	rts		

right	inc dots_array.x+2
	rts
up	dec dots_array.y+2
	rts
left	dec dots_array.x+2
	rts
down	inc dots_array.y+2
	rts
phase	dta 0
rindex	dta 0
rphase	dta 0,0,0,0
bounds	dta 60,160,60,160
handlers	dta a(up,right,down,left)
.endl
.local	l31	;lr 0,1,2
	inc phase
	inc phase2
	inc phase3
	lda phase
	bmi min1
	inc dots_array.x
	jmp two
min1	dec dots_array.x
two	lda phase2
	bmi min2
	inc dots_array.x+1
	jmp three
min2	dec dots_array.x+1
three	lda phase3
	bmi min3
	inc dots_array.x+2
	rts
min3	dec dots_array.x+2
	rts
phase	dta 0
phase2	dta 160
phase3	dta 128
.endl	
l32
l33
	rts

.endp
	.align $100
ingame_dl
	dta $70,$70,$60+$80,$0,$4f,a(dark),0,$4f,a(brdr)
	;dta 0
	dta $4f,a(vram)
:127	dta $f
	dta $4f,a(vram+$1000)
:31	dta $f
	dta $cf,a(brdr)
	dta $0
	dta $4f,a(dark2),0
	dta $4f,a(brdr)
	dta $42,a(infobar) ;,2,2
	dta $cf,a(brdr)
	dta $0
	dta $4f,a(dark)
	dta $41,a(ingame_dl)	

brdr	dta $80
:30	dta 0
	dta $01
	
dark
:8	dta #*$10*2 + #*2+1
:8	dta $ff
dark2
:8	dta $ff
:8	dta [[7-#]*$10]*2+$10 + [7-#]*2
:8	dta #*$10*2 + #*2+1
:8	dta $ff


	.align $100
arrow	ins "arr1_data2.mic",0,$1000
arrow2	ins "arr2_data2.mic",0,$1000
arrow3	ins "arr3_data2.mic",0,$1000
arrow4	ins "arr4_data2.mic",0,$1000
arrow5	ins "arr5_data2.mic",0,$1000

title	dta d'      .A         '
infobar   dta d' LEVEL: 00  TRIES: 00  TIME: 00'
:96	dta 0
	dta d'X'


.local	levels
	ift debug_level == 1
levelxx	ins "levels\levxx.dat"
	eif

sets	equ 5	;5 sets of 4 levels

.rept sets
?i = #
.rept 4,#,?i
l:2:1	ins "levels\zx7\lev:2:1.dat.zx7"
.endr
.endr

high
.rept sets
?i = #
.rept 4,#,?i
	dta h(l:2:1)
.endr
.endr

low
.rept sets
?i = #
.rept 4,#,?i
	dta l(l:2:1)
.endr
.endr

.endl


	.align $400
txtfnt	ins 'text.fnt'

.local	g2f
	icl "title\exp\title_integrated.asm"
.endl

	.align $100
	org *+$400
.local	rmt
PLAYER
	icl "rmtplayr.a65"
.endl	


	
