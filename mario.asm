;-------------------------------------------------------------------------------
; mario.nes.original disasembled by DISASM6 v1.5
;-------------------------------------------------------------------------------

	; reverse engineered labels
	.include "labels.i"

;-------------------------------------------------------------------------------
; iNES Header
;-------------------------------------------------------------------------------
            .db "NES", $1A     ; Header
            .db 2              ; 2 x 16k PRG banks
            .db 1              ; 1 x 8k CHR banks
            .db %00000001      ; Mirroring: Vertical
                               ; SRAM: Not used
                               ; 512k Trainer: Not used
                               ; 4 Screen VRAM: Not used
                               ; Mapper: 0
            .db %00000000      ; RomType: NES
            .hex 00 00 00 00   ; iNES Tail 
            .hex 00 00 00 00    

;-------------------------------------------------------------------------------
; Program Origin
;-------------------------------------------------------------------------------
            .org $8000         ; Set program counter

;-------------------------------------------------------------------------------
; ROM Start
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; reset vector
;-------------------------------------------------------------------------------
	; disable irqs
reset:      sei                ; $8000: 78        
	; disable decimal mode
            cld                ; $8001: d8        
	; load the value $10 into a
            lda #$10           ; $8002: a9 10     
	; store the value into PPU_CTRL
	; set background to use 2nd pattern table
            sta $2000          ; $8004: 8d 00 20  
	; load $ff onto x
            ldx #$ff           ; $8007: a2 ff     
	; transfer x to the stack pointer register
	; setting the stack pointer to the top of page $01
            txs                ; $8009: 9a        
	; read the ppu status reg
@vblank_wait:
            lda $2002          ; $800a: ad 02 20  
	; wait for that value to be positive
	; the bit indicating vblank is bit 7, the sign bit
	; 1 = in vblank, therefore NEGATIVE is vblank
	; and POSITIVE, is NOT vblank
	; so, while positive, Until vblank, loop
            bpl @vblank_wait         ; $800d: 10 fb     
	; reading the ppu status also clears that vblank bit
	; so its no longer set
	; now wait for another vblank
@vblank_wait2:
            lda $2002          ; $800f: ad 02 20  
            bpl @vblank_wait2         ; $8012: 10 fb     
	; my question at the moment: why wait 2 vblanks?
	; is it waiting for the ppu to stabilize or somethin?

	; load $fe into y
	; and $05 into x
            ldy #$fe           ; $8014: a0 fe     
            ldx #$05           ; $8016: a2 05     
	; read value at this address, offset by 5
	; which is in ram? near the top
	; skip, if its greater than $0a ?
@loop:      lda addr01,x        ; $8018: bd d7 07  
            cmp #$0a           ; $801b: c9 0a     
            bcs @skip          ; $801d: b0 0c     

	; otherwise, dec x
	; and loop for those 5 times!
            dex                ; $801f: ca        
            bpl @loop          ; $8020: 10 f6     
	; so basically, checks to see if any of those values
	; are greater than 10, and if so, skips this next bit

	; also check this very last byte in ram
	; and also skip unless its $a5
            lda reset_switch   ; $8022: ad ff 07  
            cmp #$a5           ; $8025: c9 a5     
            bne @skip          ; $8027: d0 02     

	; and so in the end,
	; Y is loaded with $fe
	; UNLESS!
	; last byte of ram is $a5
	; and none of those 5 bytes from before
	; are greater than 10

	; so my guess, for now, is that y = $d6 ,
	; indicates some kind of reset?
            ldy #$d6           ; $8029: a0 d6     

; skip here if that value was greater than 10 / $a
; or if last byte of ram isnt $a5
; do this sub routine
; so y = either $d6 or $fe
; and is an argument to this subroutine
@skip:      jsr init_ram       ; $802b: 20 cc 90  
	; after init_ram, a = 0, i beleive
	; so this clears the dmc_raw,
	; i beleive that means it mutes it?
            sta dmc_raw        ; $802e: 8d 11 40  
	; here's a var in ram being cleared
            sta addr03         ; $8031: 8d 70 07  
	; and here the last byte in ram is being set to this!
	; which is what enables the reset code
	; to distinguish power on from reset, i beleive
            lda #$a5           ; $8034: a9 a5     
            sta reset_switch   ; $8036: 8d ff 07  
	; so is this var being set to that value
            sta addr02         ; $8039: 8d a7 07  
	; disable dmc, enable all other channels
            lda #$0f           ; $803c: a9 0f     
            sta apu_status     ; $803e: 8d 15 40  
	; enable show sprites and bg in leftmost pixels of screen
            lda #$06           ; $8041: a9 06     
            sta ppu_mask       ; $8043: 8d 01 20  
	; call these two sub routines
	; hiding all sprites on the screen
	; and clearing the background
	; and resetting the scrolling (as a part of the latter)
            jsr hide_all_sprites         ; $8046: 20 20 82  
            jsr init_bg        ; $8049: 20 19 8e  
	; inc this var
            inc addr10          ; $804c: ee 74 07  
	; and load the ppu_ctrl_mirror ?
            lda ppu_ctrl_mirror; $804f: ad 78 07  
	; oh yes, that way we can keep settings but enable nmi!!!
            ora #$80           ; $8052: 09 80     
            jsr set_ppu_ctrl   ; $8054: 20 ed 8e  

	; and after that.... we halt forever, thats the end of the reset routine!!!
@halt:      jmp @halt          ; $8057: 4c 57 80  

;-------------------------------------------------------------------------------
__805a:     ora ($a4,x)        ; $805a: 01 a4     
            iny                ; $805c: c8        
            .hex ec 10 00      ; $805d: ec 10 00  Bad Addr Mode - CPX $0010
            eor ($41,x)        ; $8060: 41 41     
            jmp $3c34          ; $8062: 4c 34 3c  

;-------------------------------------------------------------------------------
            .hex 44 54         ; $8065: 44 54     Invalid Opcode - NOP $54
            pla                ; $8067: 68        
            .hex 7c a8 bf      ; $8068: 7c a8 bf  Invalid Opcode - NOP __bfa8,x
            .hex de ef         ; $806b: de ef     Suspected data
__806d:     .hex 03 8c         ; $806d: 03 8c     Invalid Opcode - SLO ($8c,x)
            sty __8d8c         ; $806f: 8c 8c 8d  
            .hex 03 03         ; $8072: 03 03     Invalid Opcode - SLO ($03,x)
            .hex 03 8d         ; $8074: 03 8d     Invalid Opcode - SLO ($8d,x)
            sta __8d8d         ; $8076: 8d 8d 8d  
            sta __8d8d         ; $8079: 8d 8d 8d  
            sta __8d8d         ; $807c: 8d 8d 8d  
            .hex 8d            ; $807f: 8d        Suspected data
__8080:     brk                ; $8080: 00        
            rti                ; $8081: 40        

;-------------------------------------------------------------------------------
; nmi vector
;-------------------------------------------------------------------------------
nmi:        lda $0778          ; $8082: ad 78 07  
            and #$7f           ; $8085: 29 7f     
            sta $0778          ; $8087: 8d 78 07  
            and #$7e           ; $808a: 29 7e     
            sta $2000          ; $808c: 8d 00 20  
            lda $0779          ; $808f: ad 79 07  
            and #$e6           ; $8092: 29 e6     
            ldy $0774          ; $8094: ac 74 07  
            bne __809e         ; $8097: d0 05     
            lda $0779          ; $8099: ad 79 07  
            ora #$1e           ; $809c: 09 1e     
__809e:     sta $0779          ; $809e: 8d 79 07  
            and #$e7           ; $80a1: 29 e7     
            sta $2001          ; $80a3: 8d 01 20  
            ldx $2002          ; $80a6: ae 02 20  
__80a9:     lda #$00           ; $80a9: a9 00     
            jsr reset_scroll   ; $80ab: 20 e6 8e  
            sta $2003          ; $80ae: 8d 03 20  
            lda #$02           ; $80b1: a9 02     
            sta $4014          ; $80b3: 8d 14 40  
            ldx $0773          ; $80b6: ae 73 07  
            lda __805a,x       ; $80b9: bd 5a 80  
            sta $00            ; $80bc: 85 00     
            lda __806d,x       ; $80be: bd 6d 80  
            sta $01            ; $80c1: 85 01     
            jsr __8edd         ; $80c3: 20 dd 8e  
            ldy #$00           ; $80c6: a0 00     
            ldx $0773          ; $80c8: ae 73 07  
            cpx #$06           ; $80cb: e0 06     
            bne __80d0         ; $80cd: d0 01     
            iny                ; $80cf: c8        
__80d0:     ldx __8080,y       ; $80d0: be 80 80  
            lda #$00           ; $80d3: a9 00     
            sta $0300,x        ; $80d5: 9d 00 03  
            sta $0301,x        ; $80d8: 9d 01 03  
            sta $0773          ; $80db: 8d 73 07  
            lda $0779          ; $80de: ad 79 07  
            sta $2001          ; $80e1: 8d 01 20  
            jsr __f2d1         ; $80e4: 20 d1 f2  
            jsr __8e5c         ; $80e7: 20 5c 8e  
            jsr __8182         ; $80ea: 20 82 81  
            jsr __8f97         ; $80ed: 20 97 8f  
            lda $0776          ; $80f0: ad 76 07  
            lsr                ; $80f3: 4a        
            bcs __811b         ; $80f4: b0 25     
            lda $0747          ; $80f6: ad 47 07  
            beq __8100         ; $80f9: f0 05     
            dec $0747          ; $80fb: ce 47 07  
            bne __8119         ; $80fe: d0 19     
__8100:     ldx #$14           ; $8100: a2 14     
            dec $077f          ; $8102: ce 7f 07  
            bpl __810e         ; $8105: 10 07     
            lda #$11           ; $8107: a9 11     
            sta $077f          ; $8109: 8d 7f 07  
            ldx #$23           ; $810c: a2 23     
__810e:     lda $0780,x        ; $810e: bd 80 07  
            beq __8116         ; $8111: f0 03     
            dec $0780,x        ; $8113: de 80 07  
__8116:     dex                ; $8116: ca        
            bpl __810e         ; $8117: 10 f5     
__8119:     inc $09            ; $8119: e6 09     
__811b:     ldx #$00           ; $811b: a2 00     
            ldy #$07           ; $811d: a0 07     
            lda $07a7          ; $811f: ad a7 07  
            and #$02           ; $8122: 29 02     
            sta $00            ; $8124: 85 00     
            lda $07a8          ; $8126: ad a8 07  
            and #$02           ; $8129: 29 02     
            eor $00            ; $812b: 45 00     
            clc                ; $812d: 18        
            beq __8131         ; $812e: f0 01     
__8130:     sec                ; $8130: 38        
__8131:     ror $07a7,x        ; $8131: 7e a7 07  
            inx                ; $8134: e8        
            dey                ; $8135: 88        
            bne __8131         ; $8136: d0 f9     
            lda $0722          ; $8138: ad 22 07  
            beq __815c         ; $813b: f0 1f     
__813d:     lda $2002          ; $813d: ad 02 20  
            and #$40           ; $8140: 29 40     
            bne __813d         ; $8142: d0 f9     
            lda $0776          ; $8144: ad 76 07  
            lsr                ; $8147: 4a        
            bcs __8150         ; $8148: b0 06     
;            jsr __8223         ; $814a: 20 23 82  
            jsr $8223          ; $814a: 20 23 82  
            jsr __81c6         ; $814d: 20 c6 81  
__8150:     lda $2002          ; $8150: ad 02 20  
            and #$40           ; $8153: 29 40     
            beq __8150         ; $8155: f0 f9     
            ldy #$14           ; $8157: a0 14     
__8159:     dey                ; $8159: 88        
            bne __8159         ; $815a: d0 fd     
__815c:     lda $073f          ; $815c: ad 3f 07  
            sta $2005          ; $815f: 8d 05 20  
            lda $0740          ; $8162: ad 40 07  
            sta $2005          ; $8165: 8d 05 20  
            lda $0778          ; $8168: ad 78 07  
            pha                ; $816b: 48        
            sta $2000          ; $816c: 8d 00 20  
            lda $0776          ; $816f: ad 76 07  
            lsr                ; $8172: 4a        
            bcs __8178         ; $8173: b0 03     
            jsr __8212         ; $8175: 20 12 82  
__8178:     lda $2002          ; $8178: ad 02 20  
            pla                ; $817b: 68        
            ora #$80           ; $817c: 09 80     
            sta $2000          ; $817e: 8d 00 20  
            rti                ; $8181: 40        

;-------------------------------------------------------------------------------
__8182:     lda $0770          ; $8182: ad 70 07  
            cmp #$02           ; $8185: c9 02     
            beq __8194         ; $8187: f0 0b     
            cmp #$01           ; $8189: c9 01     
            bne __81c5         ; $818b: d0 38     
            lda $0772          ; $818d: ad 72 07  
            cmp #$03           ; $8190: c9 03     
            bne __81c5         ; $8192: d0 31     
__8194:     lda $0777          ; $8194: ad 77 07  
            beq __819d         ; $8197: f0 04     
            dec $0777          ; $8199: ce 77 07  
            rts                ; $819c: 60        

;-------------------------------------------------------------------------------
__819d:     lda $06fc          ; $819d: ad fc 06  
            and #$10           ; $81a0: 29 10     
            beq __81bd         ; $81a2: f0 19     
            lda $0776          ; $81a4: ad 76 07  
            and #$80           ; $81a7: 29 80     
            bne __81c5         ; $81a9: d0 1a     
            lda #$2b           ; $81ab: a9 2b     
            sta $0777          ; $81ad: 8d 77 07  
            lda $0776          ; $81b0: ad 76 07  
            tay                ; $81b3: a8        
            iny                ; $81b4: c8        
            sty $fa            ; $81b5: 84 fa     
            eor #$01           ; $81b7: 49 01     
            ora #$80           ; $81b9: 09 80     
            bne __81c2         ; $81bb: d0 05     
__81bd:     lda $0776          ; $81bd: ad 76 07  
            and #$7f           ; $81c0: 29 7f     
__81c2:     sta $0776          ; $81c2: 8d 76 07  
__81c5:     rts                ; $81c5: 60        

;-------------------------------------------------------------------------------
__81c6:     ldy $074e          ; $81c6: ac 4e 07  
            lda #$28           ; $81c9: a9 28     
            sta $00            ; $81cb: 85 00     
            ldx #$0e           ; $81cd: a2 0e     
__81cf:     lda $06e4,x        ; $81cf: bd e4 06  
            cmp $00            ; $81d2: c5 00     
            bcc __81e5         ; $81d4: 90 0f     
            ldy $06e0          ; $81d6: ac e0 06  
            clc                ; $81d9: 18        
            adc $06e1,y        ; $81da: 79 e1 06  
            bcc __81e2         ; $81dd: 90 03     
            clc                ; $81df: 18        
            adc $00            ; $81e0: 65 00     
__81e2:     sta $06e4,x        ; $81e2: 9d e4 06  
__81e5:     dex                ; $81e5: ca        
            bpl __81cf         ; $81e6: 10 e7     
            ldx $06e0          ; $81e8: ae e0 06  
            inx                ; $81eb: e8        
            cpx #$03           ; $81ec: e0 03     
            bne __81f2         ; $81ee: d0 02     
            ldx #$00           ; $81f0: a2 00     
__81f2:     stx $06e0          ; $81f2: 8e e0 06  
            ldx #$08           ; $81f5: a2 08     
            ldy #$02           ; $81f7: a0 02     
__81f9:     lda $06e9,y        ; $81f9: b9 e9 06  
            sta $06f1,x        ; $81fc: 9d f1 06  
            clc                ; $81ff: 18        
            adc #$08           ; $8200: 69 08     
            sta $06f2,x        ; $8202: 9d f2 06  
            clc                ; $8205: 18        
            adc #$08           ; $8206: 69 08     
            sta $06f3,x        ; $8208: 9d f3 06  
            dex                ; $820b: ca        
            dex                ; $820c: ca        
            dex                ; $820d: ca        
            dey                ; $820e: 88        
            bpl __81f9         ; $820f: 10 e8     
            rts                ; $8211: 60        

;-------------------------------------------------------------------------------
__8212:     lda $0770          ; $8212: ad 70 07  
            jsr __8e04         ; $8215: 20 04 8e  
            and ($82),y        ; $8218: 31 82     
            .hex dc ae 8b      ; $821a: dc ae 8b  Invalid Opcode - NOP __8bae,x
            .hex 83 18         ; $821d: 83 18     Invalid Opcode - SAX ($18,x)
            .hex 92            ; $821f: 92        Invalid Opcode - KIL 

; here's a subroutine
; looks like it initializes oam
; or like, sets sprites off screen
hide_all_sprites:
	; probably 0 aka 256
            ldy #$00           ; $8220: a0 00     
; maybe this is an alternative entry point to this subroutine
; that lets you use y as an argument
; and specify just how much from the top of oam you want to put off screen
; that would make a lot of sense
__8222:
	; although, i'm not sure what bit does?
	; or what its for here?
            bit addr04

; MODIFICATION
;__8222:     .hex 2c            ; $8222: 2c        Suspected data
;__8223:     ldy #$04           ; $8223: a0 04     

; copy this value to every 4 locations starting at $200
; this is probably object attribute memory
; first byte is y, so this is probably putting all sprites offscreen?
            lda #$f8           ; $8225: a9 f8     
@loop:      sta $0200,y        ; $8227: 99 00 02  
            iny                ; $822a: c8        
            iny                ; $822b: c8        
            iny                ; $822c: c8        
            iny                ; $822d: c8        
            bne @loop          ; $822e: d0 f7     
            rts                ; $8230: 60        

;-------------------------------------------------------------------------------
            lda $0772          ; $8231: ad 72 07  
__8234:     jsr __8e04         ; $8234: 20 04 8e  
            .hex cf 8f 67      ; $8237: cf 8f 67  Invalid Opcode - DCP $678f
            sta $61            ; $823a: 85 61     
            bcc __8283         ; $823c: 90 45     
            .hex 82            ; $823e: 82        Suspected data
__823f:     .hex 04 20         ; $823f: 04 20     Invalid Opcode - NOP $20
            .hex 73 01         ; $8241: 73 01     Invalid Opcode - RRA ($01),y
            brk                ; $8243: 00        
            brk                ; $8244: 00        
            ldy #$00           ; $8245: a0 00     
            lda $06fc          ; $8247: ad fc 06  
            ora $06fd          ; $824a: 0d fd 06  
            cmp #$10           ; $824d: c9 10     
            beq __8255         ; $824f: f0 04     
            cmp #$90           ; $8251: c9 90     
            bne __8258         ; $8253: d0 03     
__8255:     jmp __82d8         ; $8255: 4c d8 82  

;-------------------------------------------------------------------------------
__8258:     cmp #$20           ; $8258: c9 20     
            beq __8276         ; $825a: f0 1a     
            ldx $07a2          ; $825c: ae a2 07  
            bne __826c         ; $825f: d0 0b     
            sta $0780          ; $8261: 8d 80 07  
            jsr __836b         ; $8264: 20 6b 83  
            bcs __82c9         ; $8267: b0 60     
            jmp __82c0         ; $8269: 4c c0 82  

;-------------------------------------------------------------------------------
__826c:     ldx $07fc          ; $826c: ae fc 07  
            beq __82bb         ; $826f: f0 4a     
            cmp #$40           ; $8271: c9 40     
            bne __82bb         ; $8273: d0 46     
            iny                ; $8275: c8        
__8276:     lda $07a2          ; $8276: ad a2 07  
            beq __82c9         ; $8279: f0 4e     
            lda #$18           ; $827b: a9 18     
            sta $07a2          ; $827d: 8d a2 07  
            lda $0780          ; $8280: ad 80 07  
__8283:     bne __82bb         ; $8283: d0 36     
            lda #$10           ; $8285: a9 10     
            sta $0780          ; $8287: 8d 80 07  
            cpy #$01           ; $828a: c0 01     
            beq __829c         ; $828c: f0 0e     
            lda $077a          ; $828e: ad 7a 07  
            eor #$01           ; $8291: 49 01     
            sta $077a          ; $8293: 8d 7a 07  
            jsr __8325         ; $8296: 20 25 83  
            jmp __82bb         ; $8299: 4c bb 82  

;-------------------------------------------------------------------------------
__829c:     ldx $076b          ; $829c: ae 6b 07  
            inx                ; $829f: e8        
            txa                ; $82a0: 8a        
            and #$07           ; $82a1: 29 07     
            sta $076b          ; $82a3: 8d 6b 07  
            jsr __830e         ; $82a6: 20 0e 83  
__82a9:     lda __823f,x       ; $82a9: bd 3f 82  
            sta $0300,x        ; $82ac: 9d 00 03  
            inx                ; $82af: e8        
            cpx #$06           ; $82b0: e0 06     
            bmi __82a9         ; $82b2: 30 f5     
            ldy $075f          ; $82b4: ac 5f 07  
            iny                ; $82b7: c8        
            sty $0304          ; $82b8: 8c 04 03  
__82bb:     lda #$00           ; $82bb: a9 00     
            sta $06fc          ; $82bd: 8d fc 06  
__82c0:     jsr __aeea         ; $82c0: 20 ea ae  
            lda $0e            ; $82c3: a5 0e     
            cmp #$06           ; $82c5: c9 06     
            bne __830d         ; $82c7: d0 44     
__82c9:     lda #$00           ; $82c9: a9 00     
            sta $0770          ; $82cb: 8d 70 07  
            sta $0772          ; $82ce: 8d 72 07  
            sta $0722          ; $82d1: 8d 22 07  
            inc $0774          ; $82d4: ee 74 07  
            rts                ; $82d7: 60        

;-------------------------------------------------------------------------------
__82d8:     ldy $07a2          ; $82d8: ac a2 07  
            beq __82c9         ; $82db: f0 ec     
            asl                ; $82dd: 0a        
            bcc __82e6         ; $82de: 90 06     
            lda $07fd          ; $82e0: ad fd 07  
            .hex 20 0e         ; $82e3: 20 0e     Suspected data
__82e5:     .hex 83            ; $82e5: 83        Suspected data
__82e6:     jsr __9c03         ; $82e6: 20 03 9c  
            inc $075d          ; $82e9: ee 5d 07  
            inc $0764          ; $82ec: ee 64 07  
            inc $0757          ; $82ef: ee 57 07  
            inc $0770          ; $82f2: ee 70 07  
            lda $07fc          ; $82f5: ad fc 07  
            sta $076a          ; $82f8: 8d 6a 07  
            lda #$00           ; $82fb: a9 00     
            sta $0772          ; $82fd: 8d 72 07  
            .hex 8d a2         ; $8300: 8d a2     Suspected data
__8302:     .hex 07 a2         ; $8302: 07 a2     Invalid Opcode - SLO $a2
            .hex 17 a9         ; $8304: 17 a9     Invalid Opcode - SLO $a9,x
            brk                ; $8306: 00        
__8307:     sta $07dd,x        ; $8307: 9d dd 07  
            dex                ; $830a: ca        
            bpl __8307         ; $830b: 10 fa     
__830d:     rts                ; $830d: 60        

;-------------------------------------------------------------------------------
__830e:     sta $075f          ; $830e: 8d 5f 07  
            sta $0766          ; $8311: 8d 66 07  
            ldx #$00           ; $8314: a2 00     
            stx $0760          ; $8316: 8e 60 07  
            stx $0767          ; $8319: 8e 67 07  
            rts                ; $831c: 60        

;-------------------------------------------------------------------------------
__831d:     .hex 07 22         ; $831d: 07 22     Invalid Opcode - SLO $22
            eor #$83           ; $831f: 49 83     
            dec $2424          ; $8321: ce 24 24  
            brk                ; $8324: 00        
__8325:     ldy #$07           ; $8325: a0 07     
__8327:     lda __831d,y       ; $8327: b9 1d 83  
            sta $0300,y        ; $832a: 99 00 03  
__832d:     dey                ; $832d: 88        
            bpl __8327         ; $832e: 10 f7     
            lda $077a          ; $8330: ad 7a 07  
            beq __833f         ; $8333: f0 0a     
            lda #$24           ; $8335: a9 24     
            sta $0304          ; $8337: 8d 04 03  
            lda #$ce           ; $833a: a9 ce     
            sta $0306          ; $833c: 8d 06 03  
__833f:     rts                ; $833f: 60        

;-------------------------------------------------------------------------------
            ora ($80,x)        ; $8340: 01 80     
            .hex 02            ; $8342: 02        Invalid Opcode - KIL 
            sta ($41,x)        ; $8343: 81 41     
            .hex 80 01         ; $8345: 80 01     Invalid Opcode - NOP #$01
            .hex 42            ; $8347: 42        Invalid Opcode - KIL 
            .hex c2 02         ; $8348: c2 02     Invalid Opcode - NOP #$02
            .hex 80 41         ; $834a: 80 41     Invalid Opcode - NOP #$41
            cmp ($41,x)        ; $834c: c1 41     
            cmp ($01,x)        ; $834e: c1 01     
            cmp ($01,x)        ; $8350: c1 01     
            .hex 02            ; $8352: 02        Invalid Opcode - KIL 
            .hex 80            ; $8353: 80        Suspected data
__8354:     brk                ; $8354: 00        
            .hex 9b            ; $8355: 9b        Invalid Opcode - TAS 
            bpl __8370         ; $8356: 10 18     
            ora $2c            ; $8358: 05 2c     
            jsr $1524          ; $835a: 20 24 15  
            .hex 5a            ; $835d: 5a        Invalid Opcode - NOP 
            bpl __8380         ; $835e: 10 20     
            plp                ; $8360: 28        
            bmi __8383         ; $8361: 30 20     
            bpl __82e5         ; $8363: 10 80     
            jsr $3030          ; $8365: 20 30 30  
            ora ($ff,x)        ; $8368: 01 ff     
            brk                ; $836a: 00        
__836b:     ldx $0717          ; $836b: ae 17 07  
            .hex ad 18         ; $836e: ad 18     Suspected data
__8370:     .hex 07 d0         ; $8370: 07 d0     Invalid Opcode - SLO $d0
            ora __eee8         ; $8372: 0d e8 ee  
            .hex 17 07         ; $8375: 17 07     Invalid Opcode - SLO $07,x
            sec                ; $8377: 38        
            lda __8354,x       ; $8378: bd 54 83  
            sta $0718          ; $837b: 8d 18 07  
            beq __838a         ; $837e: f0 0a     
__8380:     lda __833f,x       ; $8380: bd 3f 83  
__8383:     sta $06fc          ; $8383: 8d fc 06  
            dec $0718          ; $8386: ce 18 07  
            clc                ; $8389: 18        
__838a:     rts                ; $838a: 60        

;-------------------------------------------------------------------------------
            jsr __83a0         ; $838b: 20 a0 83  
            lda $0772          ; $838e: ad 72 07  
            beq __839a         ; $8391: f0 07     
            ldx #$00           ; $8393: a2 00     
            stx $08            ; $8395: 86 08     
            jsr __c04d         ; $8397: 20 4d c0  
__839a:     jsr __f131         ; $839a: 20 31 f1  
            jmp __eef0         ; $839d: 4c f0 ee  

;-------------------------------------------------------------------------------
__83a0:     lda $0772          ; $83a0: ad 72 07  
            jsr __8e04         ; $83a3: 20 04 8e  
            ldy $cf,x          ; $83a6: b4 cf     
            bcs __832d         ; $83a8: b0 83     
            lda __f683,x       ; $83aa: bd 83 f6  
            .hex 83 61         ; $83ad: 83 61     Invalid Opcode - SAX ($61,x)
            sty $ae            ; $83af: 84 ae     
            .hex 1b 07 e8      ; $83b1: 1b 07 e8  Invalid Opcode - SLO __e807,y
            stx $34            ; $83b4: 86 34     
            lda #$08           ; $83b6: a9 08     
            sta $fc            ; $83b8: 85 fc     
            jmp __874e         ; $83ba: 4c 4e 87  

;-------------------------------------------------------------------------------
            ldy #$00           ; $83bd: a0 00     
            sty $35            ; $83bf: 84 35     
            lda $6d            ; $83c1: a5 6d     
            cmp $34            ; $83c3: c5 34     
            bne __83cd         ; $83c5: d0 06     
            lda $86            ; $83c7: a5 86     
            cmp #$60           ; $83c9: c9 60     
            bcs __83d0         ; $83cb: b0 03     
__83cd:     inc $35            ; $83cd: e6 35     
            iny                ; $83cf: c8        
__83d0:     tya                ; $83d0: 98        
            jsr __b0e6         ; $83d1: 20 e6 b0  
            lda $071a          ; $83d4: ad 1a 07  
            cmp $34            ; $83d7: c5 34     
            beq __83f1         ; $83d9: f0 16     
            lda $0768          ; $83db: ad 68 07  
            clc                ; $83de: 18        
            adc #$80           ; $83df: 69 80     
            sta $0768          ; $83e1: 8d 68 07  
            lda #$01           ; $83e4: a9 01     
            adc #$00           ; $83e6: 69 00     
            tay                ; $83e8: a8        
            jsr __afc4         ; $83e9: 20 c4 af  
            jsr __af6f         ; $83ec: 20 6f af  
            inc $35            ; $83ef: e6 35     
__83f1:     lda $35            ; $83f1: a5 35     
            beq __845d         ; $83f3: f0 68     
            rts                ; $83f5: 60        

;-------------------------------------------------------------------------------
            lda $0749          ; $83f6: ad 49 07  
            bne __8443         ; $83f9: d0 48     
            lda $0719          ; $83fb: ad 19 07  
            beq __8418         ; $83fe: f0 18     
            cmp #$09           ; $8400: c9 09     
            bcs __8443         ; $8402: b0 3f     
            ldy $075f          ; $8404: ac 5f 07  
            cpy #$07           ; $8407: c0 07     
            bne __8414         ; $8409: d0 09     
            cmp #$03           ; $840b: c9 03     
            bcc __8443         ; $840d: 90 34     
            sbc #$01           ; $840f: e9 01     
            jmp __8418         ; $8411: 4c 18 84  

;-------------------------------------------------------------------------------
__8414:     cmp #$02           ; $8414: c9 02     
            bcc __8443         ; $8416: 90 2b     
__8418:     tay                ; $8418: a8        
            .hex d0            ; $8419: d0        Suspected data
__841a:     php                ; $841a: 08        
            lda $0753          ; $841b: ad 53 07  
            beq __8434         ; $841e: f0 14     
            iny                ; $8420: c8        
            bne __8434         ; $8421: d0 11     
__8423:     iny                ; $8423: c8        
            lda $075f          ; $8424: ad 5f 07  
            cmp #$07           ; $8427: c9 07     
            beq __8434         ; $8429: f0 09     
            dey                ; $842b: 88        
__842c:     cpy #$04           ; $842c: c0 04     
            bcs __8456         ; $842e: b0 26     
            cpy #$03           ; $8430: c0 03     
            bcs __8443         ; $8432: b0 0f     
__8434:     cpy #$03           ; $8434: c0 03     
            bne __843c         ; $8436: d0 04     
            lda #$04           ; $8438: a9 04     
            sta $fc            ; $843a: 85 fc     
__843c:     tya                ; $843c: 98        
            clc                ; $843d: 18        
            adc #$0c           ; $843e: 69 0c     
            sta $0773          ; $8440: 8d 73 07  
__8443:     lda $0749          ; $8443: ad 49 07  
            clc                ; $8446: 18        
            adc #$04           ; $8447: 69 04     
            sta $0749          ; $8449: 8d 49 07  
            lda $0719          ; $844c: ad 19 07  
            adc #$00           ; $844f: 69 00     
            sta $0719          ; $8451: 8d 19 07  
            cmp #$07           ; $8454: c9 07     
__8456:     bcc __8460         ; $8456: 90 08     
            lda #$06           ; $8458: a9 06     
            sta $07a1          ; $845a: 8d a1 07  
__845d:     inc $0772          ; $845d: ee 72 07  
__8460:     rts                ; $8460: 60        

;-------------------------------------------------------------------------------
            lda $07a1          ; $8461: ad a1 07  
            bne __8486         ; $8464: d0 20     
            ldy $075f          ; $8466: ac 5f 07  
            cpy #$07           ; $8469: c0 07     
            bcs __8487         ; $846b: b0 1a     
            lda #$00           ; $846d: a9 00     
            sta $0760          ; $846f: 8d 60 07  
            sta $075c          ; $8472: 8d 5c 07  
            sta $0772          ; $8475: 8d 72 07  
            inc $075f          ; $8478: ee 5f 07  
            jsr __9c03         ; $847b: 20 03 9c  
            inc $0757          ; $847e: ee 57 07  
            .hex a9            ; $8481: a9        Suspected data
__8482:     ora ($8d,x)        ; $8482: 01 8d     
            bvs __848d         ; $8484: 70 07     
__8486:     rts                ; $8486: 60        

;-------------------------------------------------------------------------------
__8487:     lda $06fc          ; $8487: ad fc 06  
            ora $06fd          ; $848a: 0d fd 06  
__848d:     and #$40           ; $848d: 29 40     
            beq __849e         ; $848f: f0 0d     
            lda #$01           ; $8491: a9 01     
            sta $07fc          ; $8493: 8d fc 07  
            lda #$ff           ; $8496: a9 ff     
            sta $075a          ; $8498: 8d 5a 07  
            jsr __9248         ; $849b: 20 48 92  
__849e:     rts                ; $849e: 60        

;-------------------------------------------------------------------------------
__849f:     .hex ff            ; $849f: ff        Suspected data
__84a0:     .hex ff f6 fb      ; $84a0: ff f6 fb  Invalid Opcode - ISC __fbf6,x
            .hex f7 fb         ; $84a3: f7 fb     Invalid Opcode - ISC $fb,x
            sed                ; $84a5: f8        
            .hex fb f9         ; $84a6: fb f9     Suspected data
__84a8:     .hex fb fa fb      ; $84a8: fb fa fb  Invalid Opcode - ISC __fbfa,y
__84ab:     inc $50,x          ; $84ab: f6 50     
            .hex f7 50         ; $84ad: f7 50     Invalid Opcode - ISC $50,x
            sed                ; $84af: f8        
            bvc __84ab         ; $84b0: 50 f9     
            .hex 50            ; $84b2: 50        Suspected data
__84b3:     .hex fa            ; $84b3: fa        Invalid Opcode - NOP 
            bvc __84b3         ; $84b4: 50 fd     
            .hex fe            ; $84b6: fe        Suspected data
__84b7:     .hex ff 41 42      ; $84b7: ff 41 42  Invalid Opcode - ISC $4241,x
            .hex 44 45         ; $84ba: 44 45     Invalid Opcode - NOP $45
            pha                ; $84bc: 48        
            and ($32),y        ; $84bd: 31 32     
            .hex 34 35         ; $84bf: 34 35     Invalid Opcode - NOP $35,x
            sec                ; $84c1: 38        
            brk                ; $84c2: 00        
__84c3:     lda $0110,x        ; $84c3: bd 10 01  
            beq __8486         ; $84c6: f0 be     
            cmp #$0b           ; $84c8: c9 0b     
            bcc __84d1         ; $84ca: 90 05     
            lda #$0b           ; $84cc: a9 0b     
            sta $0110,x        ; $84ce: 9d 10 01  
__84d1:     tay                ; $84d1: a8        
            lda $012c,x        ; $84d2: bd 2c 01  
            bne __84db         ; $84d5: d0 04     
            sta $0110,x        ; $84d7: 9d 10 01  
            rts                ; $84da: 60        

;-------------------------------------------------------------------------------
__84db:     dec $012c,x        ; $84db: de 2c 01  
            cmp #$2b           ; $84de: c9 2b     
            bne __8500         ; $84e0: d0 1e     
            cpy #$0b           ; $84e2: c0 0b     
            bne __84ed         ; $84e4: d0 07     
            inc $075a          ; $84e6: ee 5a 07  
            lda #$40           ; $84e9: a9 40     
            sta $fe            ; $84eb: 85 fe     
__84ed:     lda __84b7,y       ; $84ed: b9 b7 84  
            lsr                ; $84f0: 4a        
            lsr                ; $84f1: 4a        
            lsr                ; $84f2: 4a        
            lsr                ; $84f3: 4a        
            tax                ; $84f4: aa        
            lda __84b7,y       ; $84f5: b9 b7 84  
            and #$0f           ; $84f8: 29 0f     
            sta $0134,x        ; $84fa: 9d 34 01  
            jsr __bc2c         ; $84fd: 20 2c bc  
__8500:     ldy $06e5,x        ; $8500: bc e5 06  
            lda $16,x          ; $8503: b5 16     
            cmp #$12           ; $8505: c9 12     
            beq __852b         ; $8507: f0 22     
            cmp #$0d           ; $8509: c9 0d     
            beq __852b         ; $850b: f0 1e     
            cmp #$05           ; $850d: c9 05     
            beq __8523         ; $850f: f0 12     
            cmp #$0a           ; $8511: c9 0a     
            beq __852b         ; $8513: f0 16     
            cmp #$0b           ; $8515: c9 0b     
            beq __852b         ; $8517: f0 12     
            cmp #$09           ; $8519: c9 09     
            bcs __8523         ; $851b: b0 06     
            lda $1e,x          ; $851d: b5 1e     
            cmp #$02           ; $851f: c9 02     
            bcs __852b         ; $8521: b0 08     
__8523:     ldx $03ee          ; $8523: ae ee 03  
            ldy $06ec,x        ; $8526: bc ec 06  
            ldx $08            ; $8529: a6 08     
__852b:     lda $011e,x        ; $852b: bd 1e 01  
            cmp #$18           ; $852e: c9 18     
__8530:     bcc __8537         ; $8530: 90 05     
            sbc #$01           ; $8532: e9 01     
            sta $011e,x        ; $8534: 9d 1e 01  
__8537:     lda $011e,x        ; $8537: bd 1e 01  
            sbc #$08           ; $853a: e9 08     
            jsr __e5c8         ; $853c: 20 c8 e5  
            lda $0117,x        ; $853f: bd 17 01  
            sta $0203,y        ; $8542: 99 03 02  
            clc                ; $8545: 18        
            adc #$08           ; $8546: 69 08     
            sta $0207,y        ; $8548: 99 07 02  
__854b:     lda #$02           ; $854b: a9 02     
            sta $0202,y        ; $854d: 99 02 02  
            sta $0206,y        ; $8550: 99 06 02  
            lda $0110,x        ; $8553: bd 10 01  
            asl                ; $8556: 0a        
            tax                ; $8557: aa        
            lda __849f,x       ; $8558: bd 9f 84  
            sta $0201,y        ; $855b: 99 01 02  
            lda __84a0,x       ; $855e: bd a0 84  
            sta $0205,y        ; $8561: 99 05 02  
            ldx $08            ; $8564: a6 08     
            rts                ; $8566: 60        

;-------------------------------------------------------------------------------
            lda $073c          ; $8567: ad 3c 07  
            jsr __8e04         ; $856a: 20 04 8e  
            .hex 8b 85         ; $856d: 8b 85     Invalid Opcode - XAA #$85
            .hex 9b            ; $856f: 9b        Invalid Opcode - TAS 
            sta $52            ; $8570: 85 52     
            stx $5a            ; $8572: 86 5a     
            stx $93            ; $8574: 86 93     
            stx $9d            ; $8576: 86 9d     
            dey                ; $8578: 88        
            tay                ; $8579: a8        
            stx $9d            ; $857a: 86 9d     
            dey                ; $857c: 88        
            inc $86            ; $857d: e6 86     
            .hex bf 85 e3      ; $857f: bf 85 e3  Invalid Opcode - LAX __e385,y
            sta $43            ; $8582: 85 43     
            stx $ff            ; $8584: 86 ff     
            stx $32            ; $8586: 86 32     
            .hex 87 49         ; $8588: 87 49     Invalid Opcode - SAX $49
            .hex 87 20         ; $858a: 87 20     Invalid Opcode - SAX $20
            jsr $2082          ; $858c: 20 82 20  
            ora __ad8e,y       ; $858f: 19 8e ad  
            bvs __859b         ; $8592: 70 07     
            beq __85c8         ; $8594: f0 32     
            ldx #$03           ; $8596: a2 03     
            jmp __85c5         ; $8598: 4c c5 85  

;-------------------------------------------------------------------------------
__859b:     lda $0744          ; $859b: ad 44 07  
            pha                ; $859e: 48        
__859f:     lda $0756          ; $859f: ad 56 07  
            pha                ; $85a2: 48        
            lda #$00           ; $85a3: a9 00     
            sta $0756          ; $85a5: 8d 56 07  
            lda #$02           ; $85a8: a9 02     
            sta $0744          ; $85aa: 8d 44 07  
            jsr __85f1         ; $85ad: 20 f1 85  
            pla                ; $85b0: 68        
            sta $0756          ; $85b1: 8d 56 07  
            pla                ; $85b4: 68        
            sta $0744          ; $85b5: 8d 44 07  
            jmp __8745         ; $85b8: 4c 45 87  

;-------------------------------------------------------------------------------
__85bb:     ora ($02,x)        ; $85bb: 01 02     
            .hex 03 04         ; $85bd: 03 04     Invalid Opcode - SLO ($04,x)
            ldy $074e          ; $85bf: ac 4e 07  
            ldx __85bb,y       ; $85c2: be bb 85  
__85c5:     .hex 8e 73         ; $85c5: 8e 73     Suspected data
__85c7:     .hex 07            ; $85c7: 07        Suspected data
__85c8:     jmp __8745         ; $85c8: 4c 45 87  

;-------------------------------------------------------------------------------
            brk                ; $85cb: 00        
            ora #$0a           ; $85cc: 09 0a     
            .hex 04            ; $85ce: 04        Suspected data
__85cf:     .hex 22            ; $85cf: 22        Invalid Opcode - KIL 
            .hex 22            ; $85d0: 22        Invalid Opcode - KIL 
            .hex 0f 0f 0f      ; $85d1: 0f 0f 0f  Invalid Opcode - SLO $0f0f
            .hex 22            ; $85d4: 22        Invalid Opcode - KIL 
            .hex 0f 0f         ; $85d5: 0f 0f     Suspected data
__85d7:     .hex 22            ; $85d7: 22        Invalid Opcode - KIL 
            asl $27,x          ; $85d8: 16 27     
            clc                ; $85da: 18        
            .hex 22            ; $85db: 22        Invalid Opcode - KIL 
            bmi __8605         ; $85dc: 30 27     
            ora $3722,y        ; $85de: 19 22 37  
            .hex 27 16         ; $85e1: 27 16     Invalid Opcode - RLA $16
            ldy $0744          ; $85e3: ac 44 07  
            beq __85ee         ; $85e6: f0 06     
            lda __85c7,y       ; $85e8: b9 c7 85  
            sta $0773          ; $85eb: 8d 73 07  
__85ee:     inc $073c          ; $85ee: ee 3c 07  
__85f1:     ldx $0300          ; $85f1: ae 00 03  
            ldy #$00           ; $85f4: a0 00     
            lda $0753          ; $85f6: ad 53 07  
            beq __85fd         ; $85f9: f0 02     
            ldy #$04           ; $85fb: a0 04     
__85fd:     lda $0756          ; $85fd: ad 56 07  
            cmp #$02           ; $8600: c9 02     
            bne __8606         ; $8602: d0 02     
            .hex a0            ; $8604: a0        Suspected data
__8605:     php                ; $8605: 08        
__8606:     lda #$03           ; $8606: a9 03     
            sta $00            ; $8608: 85 00     
__860a:     lda __85d7,y       ; $860a: b9 d7 85  
            sta $0304,x        ; $860d: 9d 04 03  
            iny                ; $8610: c8        
            inx                ; $8611: e8        
            dec $00            ; $8612: c6 00     
            bpl __860a         ; $8614: 10 f4     
            ldx $0300          ; $8616: ae 00 03  
            ldy $0744          ; $8619: ac 44 07  
            bne __8621         ; $861c: d0 03     
            ldy $074e          ; $861e: ac 4e 07  
__8621:     lda __85cf,y       ; $8621: b9 cf 85  
            sta $0304,x        ; $8624: 9d 04 03  
            .hex a9            ; $8627: a9        Suspected data
__8628:     .hex 3f 9d 01      ; $8628: 3f 9d 01  Invalid Opcode - RLA $019d,x
            .hex 03 a9         ; $862b: 03 a9     Invalid Opcode - SLO ($a9,x)
            .hex 10            ; $862d: 10        Suspected data
__862e:     .hex 9d 02         ; $862e: 9d 02     Suspected data
__8630:     .hex 03 a9         ; $8630: 03 a9     Invalid Opcode - SLO ($a9,x)
            .hex 04 9d         ; $8632: 04 9d     Invalid Opcode - NOP $9d
            .hex 03 03         ; $8634: 03 03     Invalid Opcode - SLO ($03,x)
            lda #$00           ; $8636: a9 00     
            sta $0308,x        ; $8638: 9d 08 03  
            txa                ; $863b: 8a        
            clc                ; $863c: 18        
            adc #$07           ; $863d: 69 07     
__863f:     sta $0300          ; $863f: 8d 00 03  
            rts                ; $8642: 60        

;-------------------------------------------------------------------------------
            lda $0733          ; $8643: ad 33 07  
            cmp #$01           ; $8646: c9 01     
            bne __864f         ; $8648: d0 05     
            lda #$0b           ; $864a: a9 0b     
__864c:     sta $0773          ; $864c: 8d 73 07  
__864f:     jmp __8745         ; $864f: 4c 45 87  

;-------------------------------------------------------------------------------
            lda #$00           ; $8652: a9 00     
            jsr __8808         ; $8654: 20 08 88  
            jmp __8745         ; $8657: 4c 45 87  

;-------------------------------------------------------------------------------
            jsr __bc35         ; $865a: 20 35 bc  
            ldx $0300          ; $865d: ae 00 03  
            lda #$20           ; $8660: a9 20     
            sta $0301,x        ; $8662: 9d 01 03  
            lda #$73           ; $8665: a9 73     
            sta $0302,x        ; $8667: 9d 02 03  
            lda #$03           ; $866a: a9 03     
            sta $0303,x        ; $866c: 9d 03 03  
            ldy $075f          ; $866f: ac 5f 07  
            iny                ; $8672: c8        
            tya                ; $8673: 98        
            sta $0304,x        ; $8674: 9d 04 03  
            lda #$28           ; $8677: a9 28     
            sta $0305,x        ; $8679: 9d 05 03  
            .hex ac 5c         ; $867c: ac 5c     Suspected data
__867e:     .hex 07 c8         ; $867e: 07 c8     Invalid Opcode - SLO $c8
            tya                ; $8680: 98        
            sta $0306,x        ; $8681: 9d 06 03  
            lda #$00           ; $8684: a9 00     
            sta $0307,x        ; $8686: 9d 07 03  
            txa                ; $8689: 8a        
            clc                ; $868a: 18        
            adc #$06           ; $868b: 69 06     
            sta $0300          ; $868d: 8d 00 03  
            jmp __8745         ; $8690: 4c 45 87  

;-------------------------------------------------------------------------------
            lda $0759          ; $8693: ad 59 07  
            beq __86a2         ; $8696: f0 0a     
            lda #$00           ; $8698: a9 00     
            sta $0759          ; $869a: 8d 59 07  
            lda #$02           ; $869d: a9 02     
            jmp __86c7         ; $869f: 4c c7 86  

;-------------------------------------------------------------------------------
__86a2:     inc $073c          ; $86a2: ee 3c 07  
            jmp __8745         ; $86a5: 4c 45 87  

;-------------------------------------------------------------------------------
            lda $0770          ; $86a8: ad 70 07  
            beq __86e0         ; $86ab: f0 33     
            cmp #$03           ; $86ad: c9 03     
            beq __86d3         ; $86af: f0 22     
            lda $0752          ; $86b1: ad 52 07  
            bne __86e0         ; $86b4: d0 2a     
            ldy $074e          ; $86b6: ac 4e 07  
            cpy #$03           ; $86b9: c0 03     
            beq __86c2         ; $86bb: f0 05     
            lda $0769          ; $86bd: ad 69 07  
            bne __86e0         ; $86c0: d0 1e     
__86c2:     jsr __efab         ; $86c2: 20 ab ef  
            lda #$01           ; $86c5: a9 01     
__86c7:     jsr __8808         ; $86c7: 20 08 88  
            jsr __88a5         ; $86ca: 20 a5 88  
            lda #$00           ; $86cd: a9 00     
            sta $0774          ; $86cf: 8d 74 07  
            rts                ; $86d2: 60        

;-------------------------------------------------------------------------------
__86d3:     lda #$12           ; $86d3: a9 12     
            sta $07a0          ; $86d5: 8d a0 07  
            lda #$03           ; $86d8: a9 03     
            jsr __8808         ; $86da: 20 08 88  
            jmp __874e         ; $86dd: 4c 4e 87  

;-------------------------------------------------------------------------------
__86e0:     lda #$08           ; $86e0: a9 08     
            sta $073c          ; $86e2: 8d 3c 07  
            rts                ; $86e5: 60        

;-------------------------------------------------------------------------------
            inc $0774          ; $86e6: ee 74 07  
__86e9:     .hex 20            ; $86e9: 20        Suspected data
__86ea:     bcs __867e         ; $86ea: b0 92     
            lda $071f          ; $86ec: ad 1f 07  
            bne __86e9         ; $86ef: d0 f8     
            dec $071e          ; $86f1: ce 1e 07  
            bpl __86f9         ; $86f4: 10 03     
            inc $073c          ; $86f6: ee 3c 07  
__86f9:     lda #$06           ; $86f9: a9 06     
            sta $0773          ; $86fb: 8d 73 07  
            rts                ; $86fe: 60        

;-------------------------------------------------------------------------------
            lda $0770          ; $86ff: ad 70 07  
            bne __874e         ; $8702: d0 4a     
            lda #$1e           ; $8704: a9 1e     
            sta $2006          ; $8706: 8d 06 20  
            lda #$c0           ; $8709: a9 c0     
            sta $2006          ; $870b: 8d 06 20  
            lda #$03           ; $870e: a9 03     
            sta $01            ; $8710: 85 01     
            ldy #$00           ; $8712: a0 00     
            sty $00            ; $8714: 84 00     
            lda $2007          ; $8716: ad 07 20  
__8719:     lda $2007          ; $8719: ad 07 20  
            sta ($00),y        ; $871c: 91 00     
            iny                ; $871e: c8        
            bne __8723         ; $871f: d0 02     
            inc $01            ; $8721: e6 01     
__8723:     .hex a5            ; $8723: a5        Suspected data
__8724:     ora ($c9,x)        ; $8724: 01 c9     
            .hex 04 d0         ; $8726: 04 d0     Invalid Opcode - NOP $d0
            beq __86ea         ; $8728: f0 c0     
            .hex 3a            ; $872a: 3a        Invalid Opcode - NOP 
            bcc __8719         ; $872b: 90 ec     
            lda #$05           ; $872d: a9 05     
            jmp __864c         ; $872f: 4c 4c 86  

;-------------------------------------------------------------------------------
            lda $0770          ; $8732: ad 70 07  
            bne __874e         ; $8735: d0 17     
            ldx #$00           ; $8737: a2 00     
__8739:     sta $0300,x        ; $8739: 9d 00 03  
            sta $0400,x        ; $873c: 9d 00 04  
            dex                ; $873f: ca        
            bne __8739         ; $8740: d0 f7     
            jsr __8325         ; $8742: 20 25 83  
__8745:     inc $073c          ; $8745: ee 3c 07  
            rts                ; $8748: 60        

;-------------------------------------------------------------------------------
            lda #$fa           ; $8749: a9 fa     
            jsr __bc3b         ; $874b: 20 3b bc  
__874e:     inc $0772          ; $874e: ee 72 07  
            rts                ; $8751: 60        

;-------------------------------------------------------------------------------
__8752:     jsr $0543          ; $8752: 20 43 05  
            asl $0a,x          ; $8755: 16 0a     
            .hex 1b 12 18      ; $8757: 1b 12 18  Invalid Opcode - SLO $1812,y
            jsr $0b52          ; $875a: 20 52 0b  
            jsr $1b18          ; $875d: 20 18 1b  
            ora $0d,x          ; $8760: 15 0d     
            bit $24            ; $8762: 24 24     
            ora $1612,x        ; $8764: 1d 12 16  
            asl $6820          ; $8767: 0e 20 68  
            ora $00            ; $876a: 05 00     
            bit $24            ; $876c: 24 24     
            rol $2329          ; $876e: 2e 29 23  
            cpy #$7f           ; $8771: c0 7f     
            tax                ; $8773: aa        
            .hex 23 c2         ; $8774: 23 c2     Invalid Opcode - RLA ($c2,x)
            ora ($ea,x)        ; $8776: 01 ea     
            .hex ff 21 cd      ; $8778: ff 21 cd  Invalid Opcode - ISC __cd21,x
            .hex 07 24         ; $877b: 07 24     Invalid Opcode - SLO $24
            bit $29            ; $877d: 24 29     
            bit $24            ; $877f: 24 24     
            bit $24            ; $8781: 24 24     
            and ($4b,x)        ; $8783: 21 4b     
            ora #$20           ; $8785: 09 20     
            clc                ; $8787: 18        
            .hex 1b 15 0d      ; $8788: 1b 15 0d  Invalid Opcode - SLO $0d15,y
            bit $24            ; $878b: 24 24     
            plp                ; $878d: 28        
            bit $22            ; $878e: 24 22     
            .hex 0c 47 24      ; $8790: 0c 47 24  Invalid Opcode - NOP $2447
            .hex 23 dc         ; $8793: 23 dc     Invalid Opcode - RLA ($dc,x)
            ora ($ba,x)        ; $8795: 01 ba     
            .hex ff 21 cd      ; $8797: ff 21 cd  Invalid Opcode - ISC __cd21,x
            ora $16            ; $879a: 05 16     
            asl                ; $879c: 0a        
            .hex 1b 12 18      ; $879d: 1b 12 18  Invalid Opcode - SLO $1812,y
            .hex 22            ; $87a0: 22        Invalid Opcode - KIL 
            .hex 0c 07 1d      ; $87a1: 0c 07 1d  Invalid Opcode - NOP $1d07
            .hex 12            ; $87a4: 12        Invalid Opcode - KIL 
            asl $0e,x          ; $87a5: 16 0e     
            bit $1e            ; $87a7: 24 1e     
            ora $21ff,y        ; $87a9: 19 ff 21  
            cmp $1605          ; $87ac: cd 05 16  
            asl                ; $87af: 0a        
            .hex 1b 12 18      ; $87b0: 1b 12 18  Invalid Opcode - SLO $1812,y
            .hex 22            ; $87b3: 22        Invalid Opcode - KIL 
            .hex 0b 09         ; $87b4: 0b 09     Invalid Opcode - ANC #$09
            bpl __87c2         ; $87b6: 10 0a     
            .hex 16            ; $87b8: 16        Suspected data
__87b9:     asl $1824          ; $87b9: 0e 24 18  
            .hex 1f 0e 1b      ; $87bc: 1f 0e 1b  Invalid Opcode - SLO $1b0e,x
            .hex ff 25 84      ; $87bf: ff 25 84  Invalid Opcode - ISC __8425,x
__87c2:     .hex 15            ; $87c2: 15        Suspected data
__87c3:     jsr $150e          ; $87c3: 20 0e 15  
            .hex 0c 18 16      ; $87c6: 0c 18 16  Invalid Opcode - NOP $1618
            asl $1d24          ; $87c9: 0e 24 1d  
            clc                ; $87cc: 18        
            bit $20            ; $87cd: 24 20     
            asl                ; $87cf: 0a        
            .hex 1b 19 24      ; $87d0: 1b 19 24  Invalid Opcode - SLO $2419,y
            .hex 23 18         ; $87d3: 23 18     Invalid Opcode - RLA ($18,x)
            .hex 17 0e         ; $87d5: 17 0e     Invalid Opcode - SLO $0e,x
            .hex 2b 26         ; $87d7: 2b 26     Invalid Opcode - ANC #$26
            and $01            ; $87d9: 25 01     
            bit $26            ; $87db: 24 26     
            and $2401          ; $87dd: 2d 01 24  
            rol $35            ; $87e0: 26 35     
            ora ($24,x)        ; $87e2: 01 24     
            .hex 27 d9         ; $87e4: 27 d9     Invalid Opcode - RLA $d9
            lsr $aa            ; $87e6: 46 aa     
            .hex 27 e1         ; $87e8: 27 e1     Invalid Opcode - RLA $e1
            eor $aa            ; $87ea: 45 aa     
            .hex ff            ; $87ec: ff        Suspected data
__87ed:     ora $1e,x          ; $87ed: 15 1e     
            .hex 12            ; $87ef: 12        Invalid Opcode - KIL 
            .hex 10            ; $87f0: 10        Suspected data
__87f1:     .hex 12            ; $87f1: 12        Invalid Opcode - KIL 
__87f2:     .hex 04 03         ; $87f2: 04 03     Invalid Opcode - NOP $03
            .hex 02            ; $87f4: 02        Invalid Opcode - KIL 
            brk                ; $87f5: 00        
            bit $05            ; $87f6: 24 05     
            bit $00            ; $87f8: 24 00     
            php                ; $87fa: 08        
            .hex 07 06         ; $87fb: 07 06     Invalid Opcode - SLO $06
            brk                ; $87fd: 00        
__87fe:     brk                ; $87fe: 00        
            brk                ; $87ff: 00        
            .hex 27 27         ; $8800: 27 27     Invalid Opcode - RLA $27
__8802:     lsr $4e            ; $8802: 46 4e     
            eor $6e61,y        ; $8804: 59 61 6e  
            .hex 6e            ; $8807: 6e        Suspected data
__8808:     pha                ; $8808: 48        
            asl                ; $8809: 0a        
            tay                ; $880a: a8        
            cpy #$04           ; $880b: c0 04     
            .hex 90            ; $880d: 90        Suspected data
__880e:     .hex 0c c0 08      ; $880e: 0c c0 08  Invalid Opcode - NOP $08c0
            bcc __8815         ; $8811: 90 02     
            ldy #$08           ; $8813: a0 08     
__8815:     lda $077a          ; $8815: ad 7a 07  
            bne __881b         ; $8818: d0 01     
            iny                ; $881a: c8        
__881b:     ldx __87fe,y       ; $881b: be fe 87  
            ldy #$00           ; $881e: a0 00     
__8820:     lda __8752,x       ; $8820: bd 52 87  
            cmp #$ff           ; $8823: c9 ff     
            beq __882e         ; $8825: f0 07     
            sta $0301,y        ; $8827: 99 01 03  
            inx                ; $882a: e8        
            iny                ; $882b: c8        
            bne __8820         ; $882c: d0 f2     
__882e:     lda #$00           ; $882e: a9 00     
            .hex 99            ; $8830: 99        Suspected data
__8831:     ora ($03,x)        ; $8831: 01 03     
            pla                ; $8833: 68        
            tax                ; $8834: aa        
            cmp #$04           ; $8835: c9 04     
            bcs __8882         ; $8837: b0 49     
            dex                ; $8839: ca        
            bne __885f         ; $883a: d0 23     
            lda $075a          ; $883c: ad 5a 07  
            clc                ; $883f: 18        
            adc #$01           ; $8840: 69 01     
__8842:     cmp #$0a           ; $8842: c9 0a     
            bcc __884d         ; $8844: 90 07     
            sbc #$0a           ; $8846: e9 0a     
            ldy #$9f           ; $8848: a0 9f     
            sty $0308          ; $884a: 8c 08 03  
__884d:     sta $0309          ; $884d: 8d 09 03  
            ldy $075f          ; $8850: ac 5f 07  
            iny                ; $8853: c8        
            sty $0314          ; $8854: 8c 14 03  
            ldy $075c          ; $8857: ac 5c 07  
            iny                ; $885a: c8        
            sty $0316          ; $885b: 8c 16 03  
            rts                ; $885e: 60        

;-------------------------------------------------------------------------------
__885f:     lda $077a          ; $885f: ad 7a 07  
            beq __8881         ; $8862: f0 1d     
            lda $0753          ; $8864: ad 53 07  
            dex                ; $8867: ca        
            bne __8873         ; $8868: d0 09     
            ldy $0770          ; $886a: ac 70 07  
            cpy #$03           ; $886d: c0 03     
            beq __8873         ; $886f: f0 02     
            eor #$01           ; $8871: 49 01     
__8873:     lsr                ; $8873: 4a        
            bcc __8881         ; $8874: 90 0b     
            ldy #$04           ; $8876: a0 04     
__8878:     lda __87ed,y       ; $8878: b9 ed 87  
            sta $0304,y        ; $887b: 99 04 03  
            dey                ; $887e: 88        
            bpl __8878         ; $887f: 10 f7     
__8881:     rts                ; $8881: 60        

;-------------------------------------------------------------------------------
__8882:     sbc #$04           ; $8882: e9 04     
            asl                ; $8884: 0a        
            asl                ; $8885: 0a        
            tax                ; $8886: aa        
            ldy #$00           ; $8887: a0 00     
__8889:     .hex bd            ; $8889: bd        Suspected data
__888a:     .hex f2            ; $888a: f2        Invalid Opcode - KIL 
            .hex 87 99         ; $888b: 87 99     Invalid Opcode - SAX $99
            .hex 1c 03 e8      ; $888d: 1c 03 e8  Invalid Opcode - NOP __e803,x
            iny                ; $8890: c8        
            iny                ; $8891: c8        
            iny                ; $8892: c8        
            iny                ; $8893: c8        
            cpy #$0c           ; $8894: c0 0c     
            bcc __8889         ; $8896: 90 f1     
            lda #$2c           ; $8898: a9 2c     
            jmp __863f         ; $889a: 4c 3f 86  

;-------------------------------------------------------------------------------
            lda $07a0          ; $889d: ad a0 07  
            bne __88ad         ; $88a0: d0 0b     
            jsr hide_all_sprites         ; $88a2: 20 20 82  
__88a5:     lda #$07           ; $88a5: a9 07     
            sta $07a0          ; $88a7: 8d a0 07  
            inc $073c          ; $88aa: ee 3c 07  
__88ad:     rts                ; $88ad: 60        

;-------------------------------------------------------------------------------
            lda $0726          ; $88ae: ad 26 07  
            and #$01           ; $88b1: 29 01     
            sta $05            ; $88b3: 85 05     
            ldy $0340          ; $88b5: ac 40 03  
            sty $00            ; $88b8: 84 00     
            lda $0721          ; $88ba: ad 21 07  
            sta $0342,y        ; $88bd: 99 42 03  
            lda $0720          ; $88c0: ad 20 07  
            sta $0341,y        ; $88c3: 99 41 03  
            lda #$9a           ; $88c6: a9 9a     
            sta $0343,y        ; $88c8: 99 43 03  
            lda #$00           ; $88cb: a9 00     
            sta $04            ; $88cd: 85 04     
            tax                ; $88cf: aa        
__88d0:     stx $01            ; $88d0: 86 01     
            lda $06a1,x        ; $88d2: bd a1 06  
            and #$c0           ; $88d5: 29 c0     
            sta $03            ; $88d7: 85 03     
            asl                ; $88d9: 0a        
            rol                ; $88da: 2a        
            rol                ; $88db: 2a        
            tay                ; $88dc: a8        
            lda __8b08,y       ; $88dd: b9 08 8b  
            .hex 85            ; $88e0: 85        Suspected data
__88e1:     asl $b9            ; $88e1: 06 b9     
            .hex 0c 8b 85      ; $88e3: 0c 8b 85  Invalid Opcode - NOP __858b
            .hex 07 bd         ; $88e6: 07 bd     Invalid Opcode - SLO $bd
            lda ($06,x)        ; $88e8: a1 06     
            asl                ; $88ea: 0a        
            asl                ; $88eb: 0a        
            sta $02            ; $88ec: 85 02     
            lda $071f          ; $88ee: ad 1f 07  
            and #$01           ; $88f1: 29 01     
            eor #$01           ; $88f3: 49 01     
            asl                ; $88f5: 0a        
            adc $02            ; $88f6: 65 02     
            tay                ; $88f8: a8        
            ldx $00            ; $88f9: a6 00     
            lda ($06),y        ; $88fb: b1 06     
            sta $0344,x        ; $88fd: 9d 44 03  
            iny                ; $8900: c8        
            lda ($06),y        ; $8901: b1 06     
            sta $0345,x        ; $8903: 9d 45 03  
            ldy $04            ; $8906: a4 04     
            lda $05            ; $8908: a5 05     
            bne __891a         ; $890a: d0 0e     
            lda $01            ; $890c: a5 01     
            lsr                ; $890e: 4a        
            bcs __892a         ; $890f: b0 19     
            rol $03            ; $8911: 26 03     
            rol $03            ; $8913: 26 03     
            rol $03            ; $8915: 26 03     
            jmp __8930         ; $8917: 4c 30 89  

;-------------------------------------------------------------------------------
__891a:     lda $01            ; $891a: a5 01     
            lsr                ; $891c: 4a        
            bcs __892e         ; $891d: b0 0f     
            lsr $03            ; $891f: 46 03     
            lsr $03            ; $8921: 46 03     
            lsr $03            ; $8923: 46 03     
            lsr $03            ; $8925: 46 03     
            jmp __8930         ; $8927: 4c 30 89  

;-------------------------------------------------------------------------------
__892a:     lsr $03            ; $892a: 46 03     
            lsr $03            ; $892c: 46 03     
__892e:     inc $04            ; $892e: e6 04     
__8930:     lda $03f9,y        ; $8930: b9 f9 03  
            ora $03            ; $8933: 05 03     
            sta $03f9,y        ; $8935: 99 f9 03  
            inc $00            ; $8938: e6 00     
            inc $00            ; $893a: e6 00     
            ldx $01            ; $893c: a6 01     
            inx                ; $893e: e8        
            cpx #$0d           ; $893f: e0 0d     
            bcc __88d0         ; $8941: 90 8d     
            ldy $00            ; $8943: a4 00     
            iny                ; $8945: c8        
            iny                ; $8946: c8        
            iny                ; $8947: c8        
            lda #$00           ; $8948: a9 00     
            sta $0341,y        ; $894a: 99 41 03  
            sty $0340          ; $894d: 8c 40 03  
            inc $0721          ; $8950: ee 21 07  
            lda $0721          ; $8953: ad 21 07  
            and #$1f           ; $8956: 29 1f     
            bne __8967         ; $8958: d0 0d     
            lda #$80           ; $895a: a9 80     
            sta $0721          ; $895c: 8d 21 07  
            lda $0720          ; $895f: ad 20 07  
            eor #$04           ; $8962: 49 04     
            sta $0720          ; $8964: 8d 20 07  
__8967:     jmp __89bd         ; $8967: 4c bd 89  

;-------------------------------------------------------------------------------
__896a:     lda $0721          ; $896a: ad 21 07  
            and #$1f           ; $896d: 29 1f     
            sec                ; $896f: 38        
            sbc #$04           ; $8970: e9 04     
            and #$1f           ; $8972: 29 1f     
            sta $01            ; $8974: 85 01     
            lda $0720          ; $8976: ad 20 07  
            bcs __897d         ; $8979: b0 02     
            .hex 49            ; $897b: 49        Suspected data
__897c:     .hex 04            ; $897c: 04        Suspected data
__897d:     and #$04           ; $897d: 29 04     
            ora #$23           ; $897f: 09 23     
            sta $00            ; $8981: 85 00     
            lda $01            ; $8983: a5 01     
            lsr                ; $8985: 4a        
            lsr                ; $8986: 4a        
            adc #$c0           ; $8987: 69 c0     
            sta $01            ; $8989: 85 01     
            ldx #$00           ; $898b: a2 00     
            ldy $0340          ; $898d: ac 40 03  
__8990:     lda $00            ; $8990: a5 00     
            sta $0341,y        ; $8992: 99 41 03  
            lda $01            ; $8995: a5 01     
            clc                ; $8997: 18        
            adc #$08           ; $8998: 69 08     
            sta $0342,y        ; $899a: 99 42 03  
            sta $01            ; $899d: 85 01     
            lda $03f9,x        ; $899f: bd f9 03  
            sta $0344,y        ; $89a2: 99 44 03  
            lda #$01           ; $89a5: a9 01     
            sta $0343,y        ; $89a7: 99 43 03  
            lsr                ; $89aa: 4a        
            sta $03f9,x        ; $89ab: 9d f9 03  
            iny                ; $89ae: c8        
            iny                ; $89af: c8        
            iny                ; $89b0: c8        
            iny                ; $89b1: c8        
            inx                ; $89b2: e8        
            cpx #$07           ; $89b3: e0 07     
            bcc __8990         ; $89b5: 90 d9     
            sta $0341,y        ; $89b7: 99 41 03  
            sty $0340          ; $89ba: 8c 40 03  
__89bd:     lda #$06           ; $89bd: a9 06     
            sta $0773          ; $89bf: 8d 73 07  
            rts                ; $89c2: 60        

;-------------------------------------------------------------------------------
__89c3:     .hex 27 27         ; $89c3: 27 27     Invalid Opcode - RLA $27
            .hex 27 17         ; $89c5: 27 17     Invalid Opcode - RLA $17
            .hex 07 17         ; $89c7: 07 17     Invalid Opcode - SLO $17
__89c9:     .hex 3f 0c 04      ; $89c9: 3f 0c 04  Invalid Opcode - RLA $040c,x
            .hex ff ff ff      ; $89cc: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff 00         ; $89cf: ff 00     Suspected data
__89d1:     .hex 0f 07 12      ; $89d1: 0f 07 12  Invalid Opcode - SLO $1207
            .hex 0f 0f 07      ; $89d4: 0f 0f 07  Invalid Opcode - SLO $070f
            .hex 17 0f         ; $89d7: 17 0f     Invalid Opcode - SLO $0f,x
            .hex 0f 07 17      ; $89d9: 0f 07 17  Invalid Opcode - SLO $1707
            .hex 1c 0f 07      ; $89dc: 1c 0f 07  Invalid Opcode - NOP $070f,x
            .hex 17 00         ; $89df: 17 00     Invalid Opcode - SLO $00,x
__89e1:     lda $09            ; $89e1: a5 09     
            and #$07           ; $89e3: 29 07     
            bne __8a38         ; $89e5: d0 51     
            ldx $0300          ; $89e7: ae 00 03  
            cpx #$31           ; $89ea: e0 31     
            bcs __8a38         ; $89ec: b0 4a     
            tay                ; $89ee: a8        
__89ef:     lda __89c9,y       ; $89ef: b9 c9 89  
            sta $0301,x        ; $89f2: 9d 01 03  
            inx                ; $89f5: e8        
            iny                ; $89f6: c8        
            cpy #$08           ; $89f7: c0 08     
            bcc __89ef         ; $89f9: 90 f4     
            ldx $0300          ; $89fb: ae 00 03  
            lda #$03           ; $89fe: a9 03     
            sta $00            ; $8a00: 85 00     
            lda $074e          ; $8a02: ad 4e 07  
            asl                ; $8a05: 0a        
            asl                ; $8a06: 0a        
            tay                ; $8a07: a8        
__8a08:     lda __89d1,y       ; $8a08: b9 d1 89  
            sta $0304,x        ; $8a0b: 9d 04 03  
            iny                ; $8a0e: c8        
            inx                ; $8a0f: e8        
            dec $00            ; $8a10: c6 00     
            bpl __8a08         ; $8a12: 10 f4     
            ldx $0300          ; $8a14: ae 00 03  
            ldy $06d4          ; $8a17: ac d4 06  
            lda __89c3,y       ; $8a1a: b9 c3 89  
            sta $0305,x        ; $8a1d: 9d 05 03  
            lda $0300          ; $8a20: ad 00 03  
            clc                ; $8a23: 18        
            adc #$07           ; $8a24: 69 07     
            sta $0300          ; $8a26: 8d 00 03  
            .hex ee            ; $8a29: ee        Suspected data
__8a2a:     .hex d4 06         ; $8a2a: d4 06     Invalid Opcode - NOP $06,x
            lda $06d4          ; $8a2c: ad d4 06  
            cmp #$06           ; $8a2f: c9 06     
            bcc __8a38         ; $8a31: 90 05     
            lda #$00           ; $8a33: a9 00     
            .hex 8d d4         ; $8a35: 8d d4     Suspected data
__8a37:     .hex 06            ; $8a37: 06        Suspected data
__8a38:     rts                ; $8a38: 60        

;-------------------------------------------------------------------------------
__8a39:     .hex 45            ; $8a39: 45        Suspected data
__8a3a:     .hex 45            ; $8a3a: 45        Suspected data
__8a3b:     .hex 47            ; $8a3b: 47        Suspected data
__8a3c:     .hex 47 47         ; $8a3c: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $8a3e: 47 47     Invalid Opcode - SRE $47
            .hex 47 57         ; $8a40: 47 57     Invalid Opcode - SRE $57
            cli                ; $8a42: 58        
            eor $245a,y        ; $8a43: 59 5a 24  
            bit $24            ; $8a46: 24 24     
            bit $26            ; $8a48: 24 26     
            rol $26            ; $8a4a: 26 26     
            .hex 26            ; $8a4c: 26        Suspected data
__8a4d:     ldy #$41           ; $8a4d: a0 41     
            lda #$03           ; $8a4f: a9 03     
            ldx $074e          ; $8a51: ae 4e 07  
            bne __8a58         ; $8a54: d0 02     
            lda #$04           ; $8a56: a9 04     
__8a58:     jsr __8a97         ; $8a58: 20 97 8a  
            lda #$06           ; $8a5b: a9 06     
            sta $0773          ; $8a5d: 8d 73 07  
            rts                ; $8a60: 60        

;-------------------------------------------------------------------------------
__8a61:     jsr __8a6d         ; $8a61: 20 6d 8a  
            inc $03f0          ; $8a64: ee f0 03  
            dec $03ec,x        ; $8a67: de ec 03  
            rts                ; $8a6a: 60        

;-------------------------------------------------------------------------------
__8a6b:     lda #$00           ; $8a6b: a9 00     
__8a6d:     ldy #$03           ; $8a6d: a0 03     
            cmp #$00           ; $8a6f: c9 00     
            beq __8a87         ; $8a71: f0 14     
            ldy #$00           ; $8a73: a0 00     
            cmp #$58           ; $8a75: c9 58     
            beq __8a87         ; $8a77: f0 0e     
            cmp #$51           ; $8a79: c9 51     
            beq __8a87         ; $8a7b: f0 0a     
            iny                ; $8a7d: c8        
            cmp #$5d           ; $8a7e: c9 5d     
            beq __8a87         ; $8a80: f0 05     
            cmp #$52           ; $8a82: c9 52     
            beq __8a87         ; $8a84: f0 01     
            iny                ; $8a86: c8        
__8a87:     tya                ; $8a87: 98        
            ldy $0300          ; $8a88: ac 00 03  
            iny                ; $8a8b: c8        
            jsr __8a97         ; $8a8c: 20 97 8a  
__8a8f:     dey                ; $8a8f: 88        
            tya                ; $8a90: 98        
            clc                ; $8a91: 18        
            adc #$0a           ; $8a92: 69 0a     
            jmp __863f         ; $8a94: 4c 3f 86  

;-------------------------------------------------------------------------------
__8a97:     stx $00            ; $8a97: 86 00     
            sty $01            ; $8a99: 84 01     
            asl                ; $8a9b: 0a        
            asl                ; $8a9c: 0a        
            tax                ; $8a9d: aa        
            ldy #$20           ; $8a9e: a0 20     
            lda $06            ; $8aa0: a5 06     
            cmp #$d0           ; $8aa2: c9 d0     
            bcc __8aa8         ; $8aa4: 90 02     
            ldy #$24           ; $8aa6: a0 24     
__8aa8:     sty $03            ; $8aa8: 84 03     
            and #$0f           ; $8aaa: 29 0f     
            asl                ; $8aac: 0a        
            sta $04            ; $8aad: 85 04     
            lda #$00           ; $8aaf: a9 00     
            sta $05            ; $8ab1: 85 05     
            lda $02            ; $8ab3: a5 02     
            clc                ; $8ab5: 18        
__8ab6:     adc #$20           ; $8ab6: 69 20     
            asl                ; $8ab8: 0a        
            rol $05            ; $8ab9: 26 05     
            asl                ; $8abb: 0a        
            rol $05            ; $8abc: 26 05     
            adc $04            ; $8abe: 65 04     
            sta $04            ; $8ac0: 85 04     
            lda $05            ; $8ac2: a5 05     
            adc #$00           ; $8ac4: 69 00     
            clc                ; $8ac6: 18        
            adc $03            ; $8ac7: 65 03     
            sta $05            ; $8ac9: 85 05     
            ldy $01            ; $8acb: a4 01     
__8acd:     lda __8a39,x       ; $8acd: bd 39 8a  
__8ad0:     sta $0303,y        ; $8ad0: 99 03 03  
            lda __8a3a,x       ; $8ad3: bd 3a 8a  
            sta $0304,y        ; $8ad6: 99 04 03  
            lda __8a3b,x       ; $8ad9: bd 3b 8a  
            sta $0308,y        ; $8adc: 99 08 03  
            lda __8a3c,x       ; $8adf: bd 3c 8a  
            sta $0309,y        ; $8ae2: 99 09 03  
            lda $04            ; $8ae5: a5 04     
            sta $0301,y        ; $8ae7: 99 01 03  
            clc                ; $8aea: 18        
            adc #$20           ; $8aeb: 69 20     
            sta $0306,y        ; $8aed: 99 06 03  
            lda $05            ; $8af0: a5 05     
            sta $0300,y        ; $8af2: 99 00 03  
            sta $0305,y        ; $8af5: 99 05 03  
            lda #$02           ; $8af8: a9 02     
            sta $0302,y        ; $8afa: 99 02 03  
            sta $0307,y        ; $8afd: 99 07 03  
            lda #$00           ; $8b00: a9 00     
            sta $030a,y        ; $8b02: 99 0a 03  
            ldx $00            ; $8b05: a6 00     
            rts                ; $8b07: 60        

;-------------------------------------------------------------------------------
__8b08:     bpl __8ab6         ; $8b08: 10 ac     
            .hex 64 8c         ; $8b0a: 64 8c     Invalid Opcode - NOP $8c
            .hex 8b 8b         ; $8b0c: 8b 8b     Invalid Opcode - XAA #$8b
            sty $248c          ; $8b0e: 8c 8c 24  
            bit $24            ; $8b11: 24 24     
            bit $27            ; $8b13: 24 27     
            .hex 27 27         ; $8b15: 27 27     Invalid Opcode - RLA $27
            .hex 27 24         ; $8b17: 27 24     Invalid Opcode - RLA $24
            bit $24            ; $8b19: 24 24     
            and $36,x          ; $8b1b: 35 36     
            and $37            ; $8b1d: 25 37     
            and $24            ; $8b1f: 25 24     
            sec                ; $8b21: 38        
            bit $24            ; $8b22: 24 24     
            bit $30            ; $8b24: 24 30     
            bmi __8b4e         ; $8b26: 30 26     
            rol $26            ; $8b28: 26 26     
__8b2a:     .hex 34 26         ; $8b2a: 34 26     Invalid Opcode - NOP $26,x
            bit $31            ; $8b2c: 24 31     
            bit $32            ; $8b2e: 24 32     
            .hex 33 26         ; $8b30: 33 26     Invalid Opcode - RLA ($26),y
            bit $33            ; $8b32: 24 33     
            .hex 34 26         ; $8b34: 34 26     Invalid Opcode - NOP $26,x
            rol $26            ; $8b36: 26 26     
            rol $26            ; $8b38: 26 26     
            rol $26            ; $8b3a: 26 26     
            bit $c0            ; $8b3c: 24 c0     
            bit $c0            ; $8b3e: 24 c0     
            bit $7f            ; $8b40: 24 7f     
            .hex 7f 24 b8      ; $8b42: 7f 24 b8  Invalid Opcode - RRA __b824,x
            tsx                ; $8b45: ba        
            lda __b8bb,y       ; $8b46: b9 bb b8  
            ldy __bdb9,x       ; $8b49: bc b9 bd  
            tsx                ; $8b4c: ba        
            .hex bc            ; $8b4d: bc        Suspected data
__8b4e:     .hex bb bd 60      ; $8b4e: bb bd 60  Invalid Opcode - LAS $60bd,y
            .hex 64 61         ; $8b51: 64 61     Invalid Opcode - NOP $61
            adc $62            ; $8b53: 65 62     
            ror $63            ; $8b55: 66 63     
            .hex 67 60         ; $8b57: 67 60     Invalid Opcode - RRA $60
            .hex 64 61         ; $8b59: 64 61     Invalid Opcode - NOP $61
            adc $62            ; $8b5b: 65 62     
            ror $63            ; $8b5d: 66 63     
            .hex 67 68         ; $8b5f: 67 68     Invalid Opcode - RRA $68
            pla                ; $8b61: 68        
            adc #$69           ; $8b62: 69 69     
            rol $26            ; $8b64: 26 26     
            ror                ; $8b66: 6a        
            ror                ; $8b67: 6a        
            .hex 4b 4c         ; $8b68: 4b 4c     Invalid Opcode - ALR #$4c
            eor $4d4e          ; $8b6a: 4d 4e 4d  
            .hex 4f 4d 4f      ; $8b6d: 4f 4d 4f  Invalid Opcode - SRE $4f4d
            eor $504e          ; $8b70: 4d 4e 50  
            eor ($6b),y        ; $8b73: 51 6b     
            bvs __8ba3         ; $8b75: 70 2c     
            and $716c          ; $8b77: 2d 6c 71  
            adc $6e72          ; $8b7a: 6d 72 6e  
            .hex 73 6f         ; $8b7d: 73 6f     Invalid Opcode - RRA ($6f),y
            .hex 74 86         ; $8b7f: 74 86     Invalid Opcode - NOP $86,x
            txa                ; $8b81: 8a        
            .hex 87 8b         ; $8b82: 87 8b     Invalid Opcode - SAX $8b
            dey                ; $8b84: 88        
            sty __8c88         ; $8b85: 8c 88 8c  
            .hex 89 8d         ; $8b88: 89 8d     Invalid Opcode - NOP #$8d
            adc #$69           ; $8b8a: 69 69     
            stx __8f91         ; $8b8c: 8e 91 8f  
            .hex 92            ; $8b8f: 92        Invalid Opcode - KIL 
            rol $93            ; $8b90: 26 93     
            rol $93            ; $8b92: 26 93     
            bcc __8b2a         ; $8b94: 90 94     
            adc #$69           ; $8b96: 69 69     
            ldy $e9            ; $8b98: a4 e9     
            nop                ; $8b9a: ea        
            .hex eb 24         ; $8b9b: eb 24     Invalid Opcode - SBC #$24
            bit $24            ; $8b9d: 24 24     
            bit $24            ; $8b9f: 24 24     
            .hex 2f 24         ; $8ba1: 2f 24     Suspected data
__8ba3:     and __a2a2,x       ; $8ba3: 3d a2 a2  
            .hex a3 a3         ; $8ba6: a3 a3     Invalid Opcode - LAX ($a3,x)
            bit $24            ; $8ba8: 24 24     
            bit $24            ; $8baa: 24 24     
            ldx #$a2           ; $8bac: a2 a2     
            .hex a3 a3         ; $8bae: a3 a3     Invalid Opcode - LAX ($a3,x)
            sta __9924,y       ; $8bb0: 99 24 99  
            bit $24            ; $8bb3: 24 24     
            ldx #$3e           ; $8bb5: a2 3e     
            .hex 3f 5b 5c      ; $8bb7: 3f 5b 5c  Invalid Opcode - RLA $5c5b,x
            bit $a3            ; $8bba: 24 a3     
            bit $24            ; $8bbc: 24 24     
            bit $24            ; $8bbe: 24 24     
            sta __9e47,x       ; $8bc0: 9d 47 9e  
            .hex 47 47         ; $8bc3: 47 47     Invalid Opcode - SRE $47
            .hex 47 27         ; $8bc5: 47 27     Invalid Opcode - SRE $27
            .hex 27 47         ; $8bc7: 27 47     Invalid Opcode - RLA $47
            .hex 47 47         ; $8bc9: 47 47     Invalid Opcode - SRE $47
            .hex 47 27         ; $8bcb: 47 27     Invalid Opcode - SRE $27
            .hex 27 47         ; $8bcd: 27 47     Invalid Opcode - RLA $47
            .hex 47 a9         ; $8bcf: 47 a9     Invalid Opcode - SRE $a9
            .hex 47 aa         ; $8bd1: 47 aa     Invalid Opcode - SRE $aa
            .hex 47 9b         ; $8bd3: 47 9b     Invalid Opcode - SRE $9b
            .hex 27 9c         ; $8bd5: 27 9c     Invalid Opcode - RLA $9c
            .hex 27 27         ; $8bd7: 27 27     Invalid Opcode - RLA $27
            .hex 27 27         ; $8bd9: 27 27     Invalid Opcode - RLA $27
            .hex 27 52         ; $8bdb: 27 52     Invalid Opcode - RLA $52
            .hex 52            ; $8bdd: 52        Invalid Opcode - KIL 
            .hex 52            ; $8bde: 52        Invalid Opcode - KIL 
            .hex 52            ; $8bdf: 52        Invalid Opcode - KIL 
            .hex 80 a0         ; $8be0: 80 a0     Invalid Opcode - NOP #$a0
            sta ($a1,x)        ; $8be2: 81 a1     
            ldx __bfbe,y       ; $8be4: be be bf  
            .hex bf 75 ba      ; $8be7: bf 75 ba  Invalid Opcode - LAX __ba75,y
            ror $bb,x          ; $8bea: 76 bb     
            tsx                ; $8bec: ba        
            tsx                ; $8bed: ba        
            .hex bb bb 45      ; $8bee: bb bb 45  Invalid Opcode - LAS $45bb,y
            .hex 47 45         ; $8bf1: 47 45     Invalid Opcode - SRE $45
            .hex 47 47         ; $8bf3: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $8bf5: 47 47     Invalid Opcode - SRE $47
            .hex 47 45         ; $8bf7: 47 45     Invalid Opcode - SRE $45
            .hex 47 45         ; $8bf9: 47 45     Invalid Opcode - SRE $45
            .hex 47 b4         ; $8bfb: 47 b4     Invalid Opcode - SRE $b4
            ldx $b5,y          ; $8bfd: b6 b5     
            .hex b7 45         ; $8bff: b7 45     Invalid Opcode - LAX $45,y
            .hex 47            ; $8c01: 47        Suspected data
__8c02:     eor $47            ; $8c02: 45 47     
            eor $47            ; $8c04: 45 47     
            eor $47            ; $8c06: 45 47     
            eor $47            ; $8c08: 45 47     
            eor $47            ; $8c0a: 45 47     
            eor $47            ; $8c0c: 45 47     
            eor $47            ; $8c0e: 45 47     
            eor $47            ; $8c10: 45 47     
            eor $47            ; $8c12: 45 47     
            .hex 47 47         ; $8c14: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $8c16: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $8c18: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $8c1a: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $8c1c: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $8c1e: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $8c20: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $8c22: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $8c24: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $8c26: 47 47     Invalid Opcode - SRE $47
            bit $24            ; $8c28: 24 24     
            bit $24            ; $8c2a: 24 24     
            bit $24            ; $8c2c: 24 24     
            bit $24            ; $8c2e: 24 24     
            .hex ab ac         ; $8c30: ab ac     Invalid Opcode - LAX #$ac
            lda $5dae          ; $8c32: ad ae 5d  
            lsr $5e5d,x        ; $8c35: 5e 5d 5e  
            cmp ($24,x)        ; $8c38: c1 24     
            cmp ($24,x)        ; $8c3a: c1 24     
            dec $c8            ; $8c3c: c6 c8     
            .hex c7 c9         ; $8c3e: c7 c9     Invalid Opcode - DCP $c9
            dex                ; $8c40: ca        
            cpy __cdcb         ; $8c41: cc cb cd  
            rol                ; $8c44: 2a        
            rol                ; $8c45: 2a        
            rti                ; $8c46: 40        

;-------------------------------------------------------------------------------
            rti                ; $8c47: 40        

;-------------------------------------------------------------------------------
            bit $24            ; $8c48: 24 24     
            bit $24            ; $8c4a: 24 24     
            bit $47            ; $8c4c: 24 47     
            bit $47            ; $8c4e: 24 47     
            .hex 82 83         ; $8c50: 82 83     Invalid Opcode - NOP #$83
            sty $85            ; $8c52: 84 85     
            bit $47            ; $8c54: 24 47     
            bit $47            ; $8c56: 24 47     
            stx $8a            ; $8c58: 86 8a     
            .hex 87 8b         ; $8c5a: 87 8b     Invalid Opcode - SAX $8b
            stx __8f91         ; $8c5c: 8e 91 8f  
            .hex 92            ; $8c5f: 92        Invalid Opcode - KIL 
            bit $2f            ; $8c60: 24 2f     
            bit $3d            ; $8c62: 24 3d     
            bit $24            ; $8c64: 24 24     
            bit $35            ; $8c66: 24 35     
            rol $25,x          ; $8c68: 36 25     
            .hex 37 25         ; $8c6a: 37 25     Invalid Opcode - RLA $25,x
            bit $38            ; $8c6c: 24 38     
            bit $24            ; $8c6e: 24 24     
            bit $24            ; $8c70: 24 24     
            and $3a24,y        ; $8c72: 39 24 3a  
            bit $3b            ; $8c75: 24 3b     
            bit $3c            ; $8c77: 24 3c     
            bit $24            ; $8c79: 24 24     
            bit $41            ; $8c7b: 24 41     
            rol $41            ; $8c7d: 26 41     
            rol $26            ; $8c7f: 26 26     
            rol $26            ; $8c81: 26 26     
            rol $b0            ; $8c83: 26 b0     
            lda ($b2),y        ; $8c85: b1 b2     
            .hex b3            ; $8c87: b3        Suspected data
__8c88:     .hex 77 79         ; $8c88: 77 79     Invalid Opcode - RRA $79,x
            .hex 77 79         ; $8c8a: 77 79     Invalid Opcode - RRA $79,x
            .hex 53 55         ; $8c8c: 53 55     Invalid Opcode - SRE ($55),y
            .hex 54 56         ; $8c8e: 54 56     Invalid Opcode - NOP $56,x
            .hex 53 55         ; $8c90: 53 55     Invalid Opcode - SRE ($55),y
            .hex 54 56         ; $8c92: 54 56     Invalid Opcode - NOP $56,x
            lda $a7            ; $8c94: a5 a7     
            ldx $a8            ; $8c96: a6 a8     
            .hex c2 c4         ; $8c98: c2 c4     Invalid Opcode - NOP #$c4
            .hex c3 c5         ; $8c9a: c3 c5     Invalid Opcode - DCP ($c5,x)
            .hex 57 59         ; $8c9c: 57 59     Invalid Opcode - SRE $59,x
            cli                ; $8c9e: 58        
            .hex 5a            ; $8c9f: 5a        Invalid Opcode - NOP 
            .hex 7b 7d 7c      ; $8ca0: 7b 7d 7c  Invalid Opcode - RRA $7c7d,y
            .hex 7e 3f 00      ; $8ca3: 7e 3f 00  Bad Addr Mode - ROR $003f,x
            jsr $150f          ; $8ca6: 20 0f 15  
            .hex 12            ; $8ca9: 12        Invalid Opcode - KIL 
            and $0f            ; $8caa: 25 0f     
            .hex 3a            ; $8cac: 3a        Invalid Opcode - NOP 
            .hex 1a            ; $8cad: 1a        Invalid Opcode - NOP 
            .hex 0f 0f 30      ; $8cae: 0f 0f 30  Invalid Opcode - SLO $300f
            .hex 12            ; $8cb1: 12        Invalid Opcode - KIL 
            .hex 0f 0f 27      ; $8cb2: 0f 0f 27  Invalid Opcode - SLO $270f
            .hex 12            ; $8cb5: 12        Invalid Opcode - KIL 
            .hex 0f 22 16      ; $8cb6: 0f 22 16  Invalid Opcode - SLO $1622
            .hex 27 18         ; $8cb9: 27 18     Invalid Opcode - RLA $18
            .hex 0f 10 30      ; $8cbb: 0f 10 30  Invalid Opcode - SLO $3010
            .hex 27 0f         ; $8cbe: 27 0f     Invalid Opcode - RLA $0f
            asl $30,x          ; $8cc0: 16 30     
            .hex 27 0f         ; $8cc2: 27 0f     Invalid Opcode - RLA $0f
            .hex 0f 30 10      ; $8cc4: 0f 30 10  Invalid Opcode - SLO $1030
            brk                ; $8cc7: 00        
            .hex 3f 00 20      ; $8cc8: 3f 00 20  Invalid Opcode - RLA $2000,x
            .hex 0f 29 1a      ; $8ccb: 0f 29 1a  Invalid Opcode - SLO $1a29
            .hex 0f 0f 36      ; $8cce: 0f 0f 36  Invalid Opcode - SLO $360f
            .hex 17 0f         ; $8cd1: 17 0f     Invalid Opcode - SLO $0f,x
            .hex 0f 30 21      ; $8cd3: 0f 30 21  Invalid Opcode - SLO $2130
            .hex 0f 0f 27      ; $8cd6: 0f 0f 27  Invalid Opcode - SLO $270f
            .hex 17 0f         ; $8cd9: 17 0f     Invalid Opcode - SLO $0f,x
            .hex 0f 16 27      ; $8cdb: 0f 16 27  Invalid Opcode - SLO $2716
            clc                ; $8cde: 18        
            .hex 0f 1a 30      ; $8cdf: 0f 1a 30  Invalid Opcode - SLO $301a
            .hex 27 0f         ; $8ce2: 27 0f     Invalid Opcode - RLA $0f
            asl $30,x          ; $8ce4: 16 30     
            .hex 27 0f         ; $8ce6: 27 0f     Invalid Opcode - RLA $0f
            .hex 0f 36 17      ; $8ce8: 0f 36 17  Invalid Opcode - SLO $1736
            brk                ; $8ceb: 00        
            .hex 3f 00 20      ; $8cec: 3f 00 20  Invalid Opcode - RLA $2000,x
            .hex 0f 29         ; $8cef: 0f 29     Suspected data
__8cf1:     .hex 1a            ; $8cf1: 1a        Invalid Opcode - NOP 
            ora #$0f           ; $8cf2: 09 0f     
            .hex 3c 1c 0f      ; $8cf4: 3c 1c 0f  Invalid Opcode - NOP $0f1c,x
            .hex 0f 30 21      ; $8cf7: 0f 30 21  Invalid Opcode - SLO $2130
            .hex 1c 0f 27      ; $8cfa: 1c 0f 27  Invalid Opcode - NOP $270f,x
            .hex 17 1c         ; $8cfd: 17 1c     Invalid Opcode - SLO $1c,x
            .hex 0f 16 27      ; $8cff: 0f 16 27  Invalid Opcode - SLO $2716
            clc                ; $8d02: 18        
            .hex 0f 1c 36      ; $8d03: 0f 1c 36  Invalid Opcode - SLO $361c
            .hex 17 0f         ; $8d06: 17 0f     Invalid Opcode - SLO $0f,x
            asl $30,x          ; $8d08: 16 30     
            .hex 27 0f         ; $8d0a: 27 0f     Invalid Opcode - RLA $0f
            .hex 0c 3c 1c      ; $8d0c: 0c 3c 1c  Invalid Opcode - NOP $1c3c
            brk                ; $8d0f: 00        
            .hex 3f 00 20      ; $8d10: 3f 00 20  Invalid Opcode - RLA $2000,x
            .hex 0f 30 10      ; $8d13: 0f 30 10  Invalid Opcode - SLO $1030
            brk                ; $8d16: 00        
            .hex 0f 30 10      ; $8d17: 0f 30 10  Invalid Opcode - SLO $1030
            brk                ; $8d1a: 00        
            .hex 0f 30 16      ; $8d1b: 0f 30 16  Invalid Opcode - SLO $1630
            brk                ; $8d1e: 00        
            .hex 0f 27 17      ; $8d1f: 0f 27 17  Invalid Opcode - SLO $1727
            brk                ; $8d22: 00        
            .hex 0f 16 27      ; $8d23: 0f 16 27  Invalid Opcode - SLO $2716
            clc                ; $8d26: 18        
            .hex 0f 1c 36      ; $8d27: 0f 1c 36  Invalid Opcode - SLO $361c
            .hex 17 0f         ; $8d2a: 17 0f     Invalid Opcode - SLO $0f,x
            asl $30,x          ; $8d2c: 16 30     
            .hex 27 0f         ; $8d2e: 27 0f     Invalid Opcode - RLA $0f
            brk                ; $8d30: 00        
            bmi __8d43         ; $8d31: 30 10     
            brk                ; $8d33: 00        
            .hex 3f 00 04      ; $8d34: 3f 00 04  Invalid Opcode - RLA $0400,x
            .hex 22            ; $8d37: 22        Invalid Opcode - KIL 
            bmi __8d3a         ; $8d38: 30 00     
__8d3a:     bpl __8d3c         ; $8d3a: 10 00     
__8d3c:     .hex 3f 00 04      ; $8d3c: 3f 00 04  Invalid Opcode - RLA $0400,x
            .hex 0f 30 00      ; $8d3f: 0f 30 00  Bad Addr Mode - SLO $0030
            .hex 10            ; $8d42: 10        Suspected data
__8d43:     brk                ; $8d43: 00        
            .hex 3f 00 04      ; $8d44: 3f 00 04  Invalid Opcode - RLA $0400,x
            .hex 22            ; $8d47: 22        Invalid Opcode - KIL 
            .hex 27 16         ; $8d48: 27 16     Invalid Opcode - RLA $16
            .hex 0f 00 3f      ; $8d4a: 0f 00 3f  Invalid Opcode - SLO $3f00
            .hex 14 04         ; $8d4d: 14 04     Invalid Opcode - NOP $04,x
            .hex 0f 1a 30      ; $8d4f: 0f 1a 30  Invalid Opcode - SLO $301a
            .hex 27 00         ; $8d52: 27 00     Invalid Opcode - RLA $00
            and $48            ; $8d54: 25 48     
            bpl __8d75         ; $8d56: 10 1d     
            ora ($0a),y        ; $8d58: 11 0a     
            .hex 17 14         ; $8d5a: 17 14     Invalid Opcode - SLO $14,x
            bit $22            ; $8d5c: 24 22     
            clc                ; $8d5e: 18        
            asl $1624,x        ; $8d5f: 1e 24 16  
            asl                ; $8d62: 0a        
            .hex 1b 12 18      ; $8d63: 1b 12 18  Invalid Opcode - SLO $1812,y
            .hex 2b 00         ; $8d66: 2b 00     Invalid Opcode - ANC #$00
            and $48            ; $8d68: 25 48     
            bpl __8d89         ; $8d6a: 10 1d     
            ora ($0a),y        ; $8d6c: 11 0a     
            .hex 17 14         ; $8d6e: 17 14     Invalid Opcode - SLO $14,x
            bit $22            ; $8d70: 24 22     
            clc                ; $8d72: 18        
            .hex 1e 24         ; $8d73: 1e 24     Suspected data
__8d75:     ora $1e,x          ; $8d75: 15 1e     
            .hex 12            ; $8d77: 12        Invalid Opcode - KIL 
            bpl __8d8c         ; $8d78: 10 12     
            .hex 2b 00         ; $8d7a: 2b 00     Invalid Opcode - ANC #$00
            and $c5            ; $8d7c: 25 c5     
            asl $0b,x          ; $8d7e: 16 0b     
            asl $241d,x        ; $8d80: 1e 1d 24  
            clc                ; $8d83: 18        
            asl $241b,x        ; $8d84: 1e 1b 24  
            .hex 19 1b         ; $8d87: 19 1b     Suspected data
__8d89:     .hex 12            ; $8d89: 12        Invalid Opcode - KIL 
            .hex 17 0c         ; $8d8a: 17 0c     Invalid Opcode - SLO $0c,x
__8d8c:     .hex 0e            ; $8d8c: 0e        Suspected data
__8d8d:     .hex 1c 1c 24      ; $8d8d: 1c 1c 24  Invalid Opcode - NOP $241c,x
            .hex 12            ; $8d90: 12        Invalid Opcode - KIL 
            .hex 1c 24 12      ; $8d91: 1c 24 12  Invalid Opcode - NOP $1224,x
            .hex 17 26         ; $8d94: 17 26     Invalid Opcode - SLO $26,x
            ora $0f            ; $8d96: 05 0f     
            asl                ; $8d98: 0a        
            .hex 17 18         ; $8d99: 17 18     Invalid Opcode - SLO $18,x
            ora $0e11,x        ; $8d9b: 1d 11 0e  
            .hex 1b 24 0c      ; $8d9e: 1b 24 0c  Invalid Opcode - SLO $0c24,y
            asl                ; $8da1: 0a        
            .hex 1c 1d 15      ; $8da2: 1c 1d 15  Invalid Opcode - NOP $151d,x
            .hex 0e 2b 00      ; $8da5: 0e 2b 00  Bad Addr Mode - ASL $002b
            and $a7            ; $8da8: 25 a7     
            .hex 13 22         ; $8daa: 13 22     Invalid Opcode - SLO ($22),y
            clc                ; $8dac: 18        
            asl $241b,x        ; $8dad: 1e 1b 24  
            .hex 1a            ; $8db0: 1a        Invalid Opcode - NOP 
            asl $1c0e,x        ; $8db1: 1e 0e 1c  
            ora $1224,x        ; $8db4: 1d 24 12  
            .hex 1c 24 18      ; $8db7: 1c 24 18  Invalid Opcode - NOP $1824,x
            .hex 1f 0e 1b      ; $8dba: 1f 0e 1b  Invalid Opcode - SLO $1b0e,x
            .hex af 00 25      ; $8dbd: af 00 25  Invalid Opcode - LAX $2500
            .hex e3 1b         ; $8dc0: e3 1b     Invalid Opcode - ISC ($1b,x)
            jsr $240e          ; $8dc2: 20 0e 24  
            ora $0e1b,y        ; $8dc5: 19 1b 0e  
            .hex 1c 0e 17      ; $8dc8: 1c 0e 17  Invalid Opcode - NOP $170e,x
            ora $2224,x        ; $8dcb: 1d 24 22  
            clc                ; $8dce: 18        
            asl $0a24,x        ; $8dcf: 1e 24 0a  
            bit $17            ; $8dd2: 24 17     
            asl $2420          ; $8dd4: 0e 20 24  
            .hex 1a            ; $8dd7: 1a        Invalid Opcode - NOP 
            .hex 1e            ; $8dd8: 1e        Suspected data
__8dd9:     asl $1d1c          ; $8dd9: 0e 1c 1d  
            .hex af 00 26      ; $8ddc: af 00 26  Invalid Opcode - LAX $2600
            lsr                ; $8ddf: 4a        
            ora $1e19          ; $8de0: 0d 19 1e  
            .hex 1c 11 24      ; $8de3: 1c 11 24  Invalid Opcode - NOP $2411,x
            .hex 0b 1e         ; $8de6: 0b 1e     Invalid Opcode - ANC #$1e
            ora $181d,x        ; $8de8: 1d 1d 18  
            .hex 17 24         ; $8deb: 17 24     Invalid Opcode - SLO $24,x
            .hex 0b 00         ; $8ded: 0b 00     Invalid Opcode - ANC #$00
            rol $88            ; $8def: 26 88     
            ora ($1d),y        ; $8df1: 11 1d     
            clc                ; $8df3: 18        
            bit $1c            ; $8df4: 24 1c     
            asl $0e15          ; $8df6: 0e 15 0e  
            .hex 0c 1d 24      ; $8df9: 0c 1d 24  Invalid Opcode - NOP $241d
            asl                ; $8dfc: 0a        
            bit $20            ; $8dfd: 24 20     
            clc                ; $8dff: 18        
            .hex 1b 15 0d      ; $8e00: 1b 15 0d  Invalid Opcode - SLO $0d15,y
            brk                ; $8e03: 00        
__8e04:     asl                ; $8e04: 0a        
            tay                ; $8e05: a8        
            pla                ; $8e06: 68        
            sta $04            ; $8e07: 85 04     
            pla                ; $8e09: 68        
            sta $05            ; $8e0a: 85 05     
            iny                ; $8e0c: c8        
            lda ($04),y        ; $8e0d: b1 04     
            sta $06            ; $8e0f: 85 06     
            iny                ; $8e11: c8        
            lda ($04),y        ; $8e12: b1 04     
            sta $07            ; $8e14: 85 07     
            jmp ($0006)        ; $8e16: 6c 06 00  

;-------------------------------------------------------------------------------
; a subroutine
; at first glance it looks like its loading nametables!
; okay, more like clearing them haha
; so it.. RESTORES the ppu_ctrl to something
; then clears nametable A followed by nametable B
; by setting each tile to $2A, which is the empty tile in chr rom for the bg
; which is the second pattern table
; and the attribute tables, it clears them too, setting it all to 0
; redundantly resets the scrolling twice
init_bg:
	; loading ppu status without using the value
	; probably used to reset the ppu address latch!
            lda ppu_status     ; $8e19: ad 02 20  
	; and this is a var in ram
	; that probably determines what data to load
	; like, what map to load, i suppose
	; nah, it looks more like its a mirror of ppu ctrl
            lda ppu_ctrl_mirror         ; $8e1c: ad 78 07  
	; take that value, force the 1st bit of the upper nybble = 1
	; and then mask only the upper nybble
            ora #$10           ; $8e1f: 09 10     
            and #$f0           ; $8e21: 29 f0     
	; and call this sub routine
	; which sets the ppu_ctrl
	; so we're forcing base nametable to be 0
	; forcing bg pattern table to be the second one
	; forcing inc vram horizzantally instead of vertically
	; and forcing sprite patern table to be the first one
	; the variable bits are the top three:
	; sprite size, master/slave, and nmi or not
	; it also mirrors it to addr05
	; which is where the source of this data is from in the first place
	; which means.. we're probably Restoring the bits
	; from some modified state!
            jsr set_ppu_ctrl   ; $8e23: 20 ed 8e  

	; now call this subroutine with this value in A
	; well lol thats right in front of us
	; looks like its just saying, do everything in front
	; once with $24 as a
	; and then secondly with $20 as a!
	; these are the high bytes of the nametable locations
	; so we're just setting up first nametable A
	; then nametable B just the same
            lda #$24           ; $8e26: a9 24     
            jsr __8e2d         ; $8e28: 20 2d 8e  

__8e2b:     lda #$20           ; $8e2b: a9 20     

	; set the high byte of the ppu's address latch
	; this means, first it's dealing with nametable 1
	; and secondly, nametable 0
__8e2d:     sta ppu_addr       ; $8e2d: 8d 06 20  
	; and start at the base of that nametable
            lda #$00           ; $8e30: a9 00     
            sta ppu_addr       ; $8e32: 8d 06 20  

	; set up some loop counters
	; and load tile $24
	; which is the BLANK tile!
	; in the second pattern table anyway
	; but yeah there are 4 sections in a 32x32 grid
	; so we loop 4 times
	; the first section only is set 3/4s
	; which accounts for the final 16th
	; which isnt present
	; because its actually a 32x30 grid
	; so this loop just clears the 32x30 grid of the name table
	; that was selected in the ppu_addr
            ldx #$04           ; $8e35: a2 04     
	; y will reset to $ff after the first of the 4 loops
            ldy #$c0           ; $8e37: a0 c0     
            lda #$24           ; $8e39: a9 24     
@loop:      sta ppu_data       ; $8e3b: 8d 07 20  
            dey                ; $8e3e: 88        
	; aka branch if not 0
            bne @loop          ; $8e3f: d0 fa     
            dex                ; $8e41: ca        
            bne @loop          ; $8e42: d0 f7     
	; done with that loop of clearing the name table

	; set y = $40
	; x is conveniently 0
	; so now we set a = 0
	; and then store 0 in various locations
            ldy #$40           ; $8e44: a0 40     
            txa                ; $8e46: 8a        
            sta addr06         ; $8e47: 8d 00 03  
            sta addr07         ; $8e4a: 8d 01 03  
	; the next ppu data byte overflows into the attribute table
	; so this simply loops for the last $40 bytes (1/16 of 32/32)
	; clearing the attribute table for this nametable
@loop2:     sta ppu_data       ; $8e4d: 8d 07 20  
            dey                ; $8e50: 88        
            bne @loop2         ; $8e51: d0 fa     

	; and then store a (0) in these places
	; unsure what they are
	; but resetting them whatever they are
            sta addr08         ; $8e53: 8d 3f 07  
            sta addr09         ; $8e56: 8d 40 07  

	; and continue the subroutine elsewhere
	; aka, reset the scrolling, and return
	; this is the end of this subroutine
            jmp reset_scroll   ; $8e59: 4c e6 8e  

;-------------------------------------------------------------------------------
__8e5c:     lda #$01           ; $8e5c: a9 01     
            sta $4016          ; $8e5e: 8d 16 40  
            lsr                ; $8e61: 4a        
            tax                ; $8e62: aa        
            sta $4016          ; $8e63: 8d 16 40  
            jsr __8e6a         ; $8e66: 20 6a 8e  
            inx                ; $8e69: e8        
__8e6a:     ldy #$08           ; $8e6a: a0 08     
__8e6c:     pha                ; $8e6c: 48        
            lda $4016,x        ; $8e6d: bd 16 40  
            sta $00            ; $8e70: 85 00     
            lsr                ; $8e72: 4a        
            ora $00            ; $8e73: 05 00     
            lsr                ; $8e75: 4a        
            pla                ; $8e76: 68        
            rol                ; $8e77: 2a        
            dey                ; $8e78: 88        
            bne __8e6c         ; $8e79: d0 f1     
            sta $06fc,x        ; $8e7b: 9d fc 06  
            pha                ; $8e7e: 48        
            and #$30           ; $8e7f: 29 30     
            and $074a,x        ; $8e81: 3d 4a 07  
            beq __8e8d         ; $8e84: f0 07     
            pla                ; $8e86: 68        
            and #$cf           ; $8e87: 29 cf     
            sta $06fc,x        ; $8e89: 9d fc 06  
            rts                ; $8e8c: 60        

;-------------------------------------------------------------------------------
__8e8d:     pla                ; $8e8d: 68        
            sta $074a,x        ; $8e8e: 9d 4a 07  
            rts                ; $8e91: 60        

;-------------------------------------------------------------------------------
__8e92:     sta $2006          ; $8e92: 8d 06 20  
            iny                ; $8e95: c8        
            lda ($00),y        ; $8e96: b1 00     
            sta $2006          ; $8e98: 8d 06 20  
            iny                ; $8e9b: c8        
            lda ($00),y        ; $8e9c: b1 00     
            asl                ; $8e9e: 0a        
            pha                ; $8e9f: 48        
            lda $0778          ; $8ea0: ad 78 07  
            ora #$04           ; $8ea3: 09 04     
            bcs __8ea9         ; $8ea5: b0 02     
            and #$fb           ; $8ea7: 29 fb     
__8ea9:     jsr set_ppu_ctrl   ; $8ea9: 20 ed 8e  
            pla                ; $8eac: 68        
            asl                ; $8ead: 0a        
            bcc __8eb3         ; $8eae: 90 03     
            ora #$02           ; $8eb0: 09 02     
            iny                ; $8eb2: c8        
__8eb3:     lsr                ; $8eb3: 4a        
            lsr                ; $8eb4: 4a        
            tax                ; $8eb5: aa        
__8eb6:     bcs __8eb9         ; $8eb6: b0 01     
            iny                ; $8eb8: c8        
__8eb9:     lda ($00),y        ; $8eb9: b1 00     
__8ebb:     sta $2007          ; $8ebb: 8d 07 20  
            dex                ; $8ebe: ca        
            bne __8eb6         ; $8ebf: d0 f5     
            sec                ; $8ec1: 38        
            tya                ; $8ec2: 98        
            adc $00            ; $8ec3: 65 00     
            sta $00            ; $8ec5: 85 00     
            lda #$00           ; $8ec7: a9 00     
            adc $01            ; $8ec9: 65 01     
            sta $01            ; $8ecb: 85 01     
            lda #$3f           ; $8ecd: a9 3f     
            sta $2006          ; $8ecf: 8d 06 20  
            lda #$00           ; $8ed2: a9 00     
            sta $2006          ; $8ed4: 8d 06 20  
            sta $2006          ; $8ed7: 8d 06 20  
            sta $2006          ; $8eda: 8d 06 20  
__8edd:     ldx $2002          ; $8edd: ae 02 20  
            ldy #$00           ; $8ee0: a0 00     
            lda ($00),y        ; $8ee2: b1 00     
            bne __8e92         ; $8ee4: d0 ac     

; short sub routine
; takes A as argument
; seems like it has to be 0 ?
; but anyway, if it is zero, that means it resets scrolling
reset_scroll:
            sta ppu_scroll     ; $8ee6: 8d 05 20  
            sta ppu_scroll     ; $8ee9: 8d 05 20  
            rts                ; $8eec: 60        

;-------------------------------------------------------------------------------
; here's a very short sub routine
; clearly depends on the contetns of the a register
; perhaps addr05 is just a mirror of ctrl? who knows, not me, not yet
; but if a is 0, itll disable nmi
set_ppu_ctrl:
            sta ppu_ctrl       ; $8eed: 8d 00 20  
            sta ppu_ctrl_mirror; $8ef0: 8d 78 07  
            rts                ; $8ef3: 60        

;-------------------------------------------------------------------------------
__8ef4:     .hex f0            ; $8ef4: f0        Suspected data
__8ef5:     asl $62            ; $8ef5: 06 62     
            asl $62            ; $8ef7: 06 62     
            asl $6d            ; $8ef9: 06 6d     
            .hex 02            ; $8efb: 02        Invalid Opcode - KIL 
            adc $7a02          ; $8efc: 6d 02 7a  
            .hex 03            ; $8eff: 03        Suspected data
__8f00:     asl $0c            ; $8f00: 06 0c     
            .hex 12            ; $8f02: 12        Invalid Opcode - KIL 
            clc                ; $8f03: 18        
            .hex 1e 24         ; $8f04: 1e 24     Suspected data
__8f06:     sta $00            ; $8f06: 85 00     
            jsr __8f11         ; $8f08: 20 11 8f  
            lda $00            ; $8f0b: a5 00     
            lsr                ; $8f0d: 4a        
            lsr                ; $8f0e: 4a        
            lsr                ; $8f0f: 4a        
            lsr                ; $8f10: 4a        
__8f11:     clc                ; $8f11: 18        
            adc #$01           ; $8f12: 69 01     
            and #$0f           ; $8f14: 29 0f     
            cmp #$06           ; $8f16: c9 06     
            bcs __8f5e         ; $8f18: b0 44     
            pha                ; $8f1a: 48        
            asl                ; $8f1b: 0a        
            tay                ; $8f1c: a8        
            ldx $0300          ; $8f1d: ae 00 03  
            lda #$20           ; $8f20: a9 20     
            cpy #$00           ; $8f22: c0 00     
            bne __8f28         ; $8f24: d0 02     
            lda #$22           ; $8f26: a9 22     
__8f28:     sta $0301,x        ; $8f28: 9d 01 03  
            lda __8ef4,y       ; $8f2b: b9 f4 8e  
            sta $0302,x        ; $8f2e: 9d 02 03  
            lda __8ef5,y       ; $8f31: b9 f5 8e  
            sta $0303,x        ; $8f34: 9d 03 03  
            sta $03            ; $8f37: 85 03     
            stx $02            ; $8f39: 86 02     
            pla                ; $8f3b: 68        
            tax                ; $8f3c: aa        
            lda __8f00,x       ; $8f3d: bd 00 8f  
            sec                ; $8f40: 38        
            sbc __8ef5,y       ; $8f41: f9 f5 8e  
            tay                ; $8f44: a8        
            ldx $02            ; $8f45: a6 02     
__8f47:     lda $07d7,y        ; $8f47: b9 d7 07  
            sta $0304,x        ; $8f4a: 9d 04 03  
            inx                ; $8f4d: e8        
            iny                ; $8f4e: c8        
            dec $03            ; $8f4f: c6 03     
            bne __8f47         ; $8f51: d0 f4     
            lda #$00           ; $8f53: a9 00     
            sta $0304,x        ; $8f55: 9d 04 03  
            inx                ; $8f58: e8        
            inx                ; $8f59: e8        
            inx                ; $8f5a: e8        
            stx $0300          ; $8f5b: 8e 00 03  
__8f5e:     rts                ; $8f5e: 60        

;-------------------------------------------------------------------------------
__8f5f:     lda $0770          ; $8f5f: ad 70 07  
            cmp #$00           ; $8f62: c9 00     
            beq __8f7c         ; $8f64: f0 16     
            ldx #$05           ; $8f66: a2 05     
__8f68:     lda $0134,x        ; $8f68: bd 34 01  
__8f6b:     clc                ; $8f6b: 18        
            adc $07d7,y        ; $8f6c: 79 d7 07  
            bmi __8f87         ; $8f6f: 30 16     
            cmp #$0a           ; $8f71: c9 0a     
            bcs __8f8e         ; $8f73: b0 19     
__8f75:     sta $07d7,y        ; $8f75: 99 d7 07  
            dey                ; $8f78: 88        
            dex                ; $8f79: ca        
            bpl __8f68         ; $8f7a: 10 ec     
__8f7c:     lda #$00           ; $8f7c: a9 00     
            ldx #$06           ; $8f7e: a2 06     
__8f80:     sta $0133,x        ; $8f80: 9d 33 01  
            dex                ; $8f83: ca        
            bpl __8f80         ; $8f84: 10 fa     
            rts                ; $8f86: 60        

;-------------------------------------------------------------------------------
__8f87:     dec $0133,x        ; $8f87: de 33 01  
            lda #$09           ; $8f8a: a9 09     
            .hex d0            ; $8f8c: d0        Suspected data
__8f8d:     .hex e7            ; $8f8d: e7        Suspected data
__8f8e:     sec                ; $8f8e: 38        
            sbc #$0a           ; $8f8f: e9 0a     
__8f91:     inc $0133,x        ; $8f91: fe 33 01  
            jmp __8f75         ; $8f94: 4c 75 8f  

;-------------------------------------------------------------------------------
__8f97:     ldx #$05           ; $8f97: a2 05     
            jsr __8f9e         ; $8f99: 20 9e 8f  
            ldx #$0b           ; $8f9c: a2 0b     
__8f9e:     ldy #$05           ; $8f9e: a0 05     
            sec                ; $8fa0: 38        
__8fa1:     lda $07dd,x        ; $8fa1: bd dd 07  
            sbc $07d7,y        ; $8fa4: f9 d7 07  
            dex                ; $8fa7: ca        
            dey                ; $8fa8: 88        
            bpl __8fa1         ; $8fa9: 10 f6     
            bcc __8fbb         ; $8fab: 90 0e     
            inx                ; $8fad: e8        
            iny                ; $8fae: c8        
__8faf:     lda $07dd,x        ; $8faf: bd dd 07  
            sta $07d7,y        ; $8fb2: 99 d7 07  
            inx                ; $8fb5: e8        
            iny                ; $8fb6: c8        
            cpy #$06           ; $8fb7: c0 06     
            bcc __8faf         ; $8fb9: 90 f4     
__8fbb:     rts                ; $8fbb: 60        

;-------------------------------------------------------------------------------
__8fbc:     .hex 04 30         ; $8fbc: 04 30     Invalid Opcode - NOP $30
            pha                ; $8fbe: 48        
            rts                ; $8fbf: 60        

;-------------------------------------------------------------------------------
            sei                ; $8fc0: 78        
            bcc __8f6b         ; $8fc1: 90 a8     
            cpy #$d8           ; $8fc3: c0 d8     
            inx                ; $8fc5: e8        
            bit $f8            ; $8fc6: 24 f8     
            .hex fc 28 2c      ; $8fc8: fc 28 2c  Invalid Opcode - NOP $2c28,x
__8fcb:     clc                ; $8fcb: 18        
            .hex ff 23 58      ; $8fcc: ff 23 58  Invalid Opcode - ISC $5823,x
            ldy #$6f           ; $8fcf: a0 6f     
            jsr init_ram       ; $8fd1: 20 cc 90  
            ldy #$1f           ; $8fd4: a0 1f     
__8fd6:     sta $07b0,y        ; $8fd6: 99 b0 07  
            dey                ; $8fd9: 88        
            bpl __8fd6         ; $8fda: 10 fa     
            lda #$18           ; $8fdc: a9 18     
            sta $07a2          ; $8fde: 8d a2 07  
            jsr __9c03         ; $8fe1: 20 03 9c  
            ldy #$4b           ; $8fe4: a0 4b     
            jsr init_ram       ; $8fe6: 20 cc 90  
            ldx #$21           ; $8fe9: a2 21     
            lda #$00           ; $8feb: a9 00     
__8fed:     sta $0780,x        ; $8fed: 9d 80 07  
            dex                ; $8ff0: ca        
            bpl __8fed         ; $8ff1: 10 fa     
            lda $075b          ; $8ff3: ad 5b 07  
            ldy $0752          ; $8ff6: ac 52 07  
            beq __8ffe         ; $8ff9: f0 03     
            lda $0751          ; $8ffb: ad 51 07  
__8ffe:     sta $071a          ; $8ffe: 8d 1a 07  
            sta $0725          ; $9001: 8d 25 07  
            sta $0728          ; $9004: 8d 28 07  
            jsr __b038         ; $9007: 20 38 b0  
            ldy #$20           ; $900a: a0 20     
            and #$01           ; $900c: 29 01     
            beq __9012         ; $900e: f0 02     
            ldy #$24           ; $9010: a0 24     
__9012:     sty $0720          ; $9012: 8c 20 07  
            ldy #$80           ; $9015: a0 80     
            sty $0721          ; $9017: 8c 21 07  
            asl                ; $901a: 0a        
            asl                ; $901b: 0a        
            asl                ; $901c: 0a        
            asl                ; $901d: 0a        
            sta $06a0          ; $901e: 8d a0 06  
            dec $0730          ; $9021: ce 30 07  
            dec $0731          ; $9024: ce 31 07  
            dec $0732          ; $9027: ce 32 07  
            lda #$0b           ; $902a: a9 0b     
            sta $071e          ; $902c: 8d 1e 07  
            jsr __9c22         ; $902f: 20 22 9c  
            lda $076a          ; $9032: ad 6a 07  
            bne __9047         ; $9035: d0 10     
            lda $075f          ; $9037: ad 5f 07  
            cmp #$04           ; $903a: c9 04     
            bcc __904a         ; $903c: 90 0c     
            bne __9047         ; $903e: d0 07     
            lda $075c          ; $9040: ad 5c 07  
            cmp #$02           ; $9043: c9 02     
            bcc __904a         ; $9045: 90 03     
__9047:     inc $06cc          ; $9047: ee cc 06  
__904a:     lda $075b          ; $904a: ad 5b 07  
            beq __9054         ; $904d: f0 05     
            lda #$02           ; $904f: a9 02     
            sta $0710          ; $9051: 8d 10 07  
__9054:     lda #$80           ; $9054: a9 80     
            sta $fb            ; $9056: 85 fb     
            lda #$01           ; $9058: a9 01     
            sta $0774          ; $905a: 8d 74 07  
            inc $0772          ; $905d: ee 72 07  
            rts                ; $9060: 60        

;-------------------------------------------------------------------------------
            lda #$01           ; $9061: a9 01     
            sta $0757          ; $9063: 8d 57 07  
            sta $0754          ; $9066: 8d 54 07  
            lda #$02           ; $9069: a9 02     
            sta $075a          ; $906b: 8d 5a 07  
            sta $0761          ; $906e: 8d 61 07  
            lda #$00           ; $9071: a9 00     
            sta $0774          ; $9073: 8d 74 07  
            tay                ; $9076: a8        
__9077:     sta $0300,y        ; $9077: 99 00 03  
            iny                ; $907a: c8        
            bne __9077         ; $907b: d0 fa     
            sta $0759          ; $907d: 8d 59 07  
            sta $0769          ; $9080: 8d 69 07  
            sta $0728          ; $9083: 8d 28 07  
            lda #$ff           ; $9086: a9 ff     
            sta $03a0          ; $9088: 8d a0 03  
            lda $071a          ; $908b: ad 1a 07  
            lsr $0778          ; $908e: 4e 78 07  
            and #$01           ; $9091: 29 01     
            ror                ; $9093: 6a        
            rol $0778          ; $9094: 2e 78 07  
            jsr __90ed         ; $9097: 20 ed 90  
            lda #$38           ; $909a: a9 38     
            sta $06e3          ; $909c: 8d e3 06  
            lda #$48           ; $909f: a9 48     
            sta $06e2          ; $90a1: 8d e2 06  
            lda #$58           ; $90a4: a9 58     
            sta $06e1          ; $90a6: 8d e1 06  
            ldx #$0e           ; $90a9: a2 0e     
__90ab:     lda __8fbc,x       ; $90ab: bd bc 8f  
            sta $06e4,x        ; $90ae: 9d e4 06  
            dex                ; $90b1: ca        
            bpl __90ab         ; $90b2: 10 f7     
            ldy #$03           ; $90b4: a0 03     
__90b6:     lda __8fcb,y       ; $90b6: b9 cb 8f  
            sta $0200,y        ; $90b9: 99 00 02  
            dey                ; $90bc: 88        
            bpl __90b6         ; $90bd: 10 f7     
            jsr __92af         ; $90bf: 20 af 92  
            jsr __92aa         ; $90c2: 20 aa 92  
            inc $0722          ; $90c5: ee 22 07  
            inc $0772          ; $90c8: ee 72 07  
            rts                ; $90cb: 60        

;-------------------------------------------------------------------------------
; here's a subroutine
; let's see what it does
; looks like this subroutine takes y as an argument
; on startup: y = either $d6 or $fe
; looks like its used to clear some mememory
; it looks like it writes zeros to different sections of ram
; starting at page $07 it works its way down, clearing it
; oh yes! and on the stack page ($01) it 
; and my guess, is that some of this memory stores high scores!
; near the top of the ram
; i think, this routine clears all ram except for the very top
; specified by the y register
; (and not the stack either)
; and when the game is reset, the high scores are intended to be saved!
; also it looks like this subroutine exits with a = 0
init_ram:
	; do a thing, 8 times?
	; or 7?
	; question: does bpl branch on 0? or 1+?
            ldx #$07           ; $90cc: a2 07     
            lda #$00           ; $90ce: a9 00     
	; set zp01 to 0
	; oh, this is a 16-bit address pair
	; looks like this is just used as an address holder!
	; instead of a 16bit register being used to point somewher,
	; indirect memory is used!
            sta zp01           ; $90d0: 85 06     
@loop1:     stx zp02           ; $90d2: 86 07     
	; check if this is the stack page
@loop2:     cpx #$01           ; $90d4: e0 01     
            bne @skip          ; $90d6: d0 04     

	; when on the stack page,
	; only clear under? $60,
	; so i guses its preserving the first part of the stack
            cpy #$60           ; $90d8: c0 60     
            bcs @skip2         ; $90da: b0 02     

@skip:      sta (zp01),y        ; $90dc: 91 06     
	; keep doing the inner loop until y underflows
@skip2:     dey                ; $90de: 88        
            cpy #$ff           ; $90df: c0 ff     
            bne @loop2         ; $90e1: d0 f1     
	; keep doing the outer loop x times
            dex                ; $90e3: ca        
            bpl @loop1         ; $90e4: 10 ec     
            rts                ; $90e6: 60        

;-------------------------------------------------------------------------------
__90e7:     .hex 02            ; $90e7: 02        Invalid Opcode - KIL 
            ora ($04,x)        ; $90e8: 01 04     
            php                ; $90ea: 08        
            bpl __910d         ; $90eb: 10 20     
__90ed:     lda $0770          ; $90ed: ad 70 07  
            beq __9115         ; $90f0: f0 23     
            lda $0752          ; $90f2: ad 52 07  
            cmp #$02           ; $90f5: c9 02     
            beq __9106         ; $90f7: f0 0d     
            ldy #$05           ; $90f9: a0 05     
            lda $0710          ; $90fb: ad 10 07  
            cmp #$06           ; $90fe: c9 06     
            beq __9110         ; $9100: f0 0e     
            cmp #$07           ; $9102: c9 07     
            beq __9110         ; $9104: f0 0a     
__9106:     ldy $074e          ; $9106: ac 4e 07  
            lda $0743          ; $9109: ad 43 07  
            .hex f0            ; $910c: f0        Suspected data
__910d:     .hex 02            ; $910d: 02        Invalid Opcode - KIL 
            ldy #$04           ; $910e: a0 04     
__9110:     lda __90e7,y       ; $9110: b9 e7 90  
            sta $fb            ; $9113: 85 fb     
__9115:     rts                ; $9115: 60        

;-------------------------------------------------------------------------------
__9116:     plp                ; $9116: 28        
            clc                ; $9117: 18        
__9118:     sec                ; $9118: 38        
            plp                ; $9119: 28        
            php                ; $911a: 08        
            brk                ; $911b: 00        
__911c:     brk                ; $911c: 00        
            jsr $50b0          ; $911d: 20 b0 50  
            brk                ; $9120: 00        
            brk                ; $9121: 00        
;            bcs __90d4         ; $9122: b0 b0     
; MODIFICATION
            .hex b0 b0
            .hex f0            ; $9124: f0        Suspected data
__9125:     brk                ; $9125: 00        
            jsr $0000          ; $9126: 20 00 00  
            brk                ; $9129: 00        
            brk                ; $912a: 00        
            brk                ; $912b: 00        
            brk                ; $912c: 00        
__912d:     jsr $0304          ; $912d: 20 04 03  
            .hex 02            ; $9130: 02        Invalid Opcode - KIL 
            lda $071a          ; $9131: ad 1a 07  
            sta $6d            ; $9134: 85 6d     
            lda #$70           ; $9136: a9 70     
            sta $070a          ; $9138: 8d 0a 07  
            lda #$01           ; $913b: a9 01     
            sta $33            ; $913d: 85 33     
            sta $b5            ; $913f: 85 b5     
            lda #$00           ; $9141: a9 00     
            sta $1d            ; $9143: 85 1d     
            dec $0490          ; $9145: ce 90 04  
            ldy #$00           ; $9148: a0 00     
            sty $075b          ; $914a: 8c 5b 07  
            lda $074e          ; $914d: ad 4e 07  
            bne __9153         ; $9150: d0 01     
            iny                ; $9152: c8        
__9153:     sty $0704          ; $9153: 8c 04 07  
            ldx $0710          ; $9156: ae 10 07  
            ldy $0752          ; $9159: ac 52 07  
            beq __9165         ; $915c: f0 07     
            cpy #$01           ; $915e: c0 01     
            beq __9165         ; $9160: f0 03     
            ldx __9118,y       ; $9162: be 18 91  
__9165:     lda __9116,y       ; $9165: b9 16 91  
            sta $86            ; $9168: 85 86     
            lda __911c,x       ; $916a: bd 1c 91  
            sta $ce            ; $916d: 85 ce     
            lda __9125,x       ; $916f: bd 25 91  
            sta $03c4          ; $9172: 8d c4 03  
            jsr __85f1         ; $9175: 20 f1 85  
            ldy $0715          ; $9178: ac 15 07  
            beq __9197         ; $917b: f0 1a     
            lda $0757          ; $917d: ad 57 07  
            beq __9197         ; $9180: f0 15     
            lda __912d,y       ; $9182: b9 2d 91  
            sta $07f8          ; $9185: 8d f8 07  
            lda #$01           ; $9188: a9 01     
            sta $07fa          ; $918a: 8d fa 07  
            lsr                ; $918d: 4a        
            sta $07f9          ; $918e: 8d f9 07  
            sta $0757          ; $9191: 8d 57 07  
            sta $079f          ; $9194: 8d 9f 07  
__9197:     ldy $0758          ; $9197: ac 58 07  
            beq __91b0         ; $919a: f0 14     
            lda #$03           ; $919c: a9 03     
            sta $1d            ; $919e: 85 1d     
            ldx #$00           ; $91a0: a2 00     
            jsr __bd89         ; $91a2: 20 89 bd  
            lda #$f0           ; $91a5: a9 f0     
            sta $d7            ; $91a7: 85 d7     
            ldx #$05           ; $91a9: a2 05     
            ldy #$00           ; $91ab: a0 00     
            jsr __b923         ; $91ad: 20 23 b9  
__91b0:     ldy $074e          ; $91b0: ac 4e 07  
            bne __91b8         ; $91b3: d0 03     
            jsr __b70b         ; $91b5: 20 0b b7  
__91b8:     lda #$07           ; $91b8: a9 07     
            sta $0e            ; $91ba: 85 0e     
            rts                ; $91bc: 60        

;-------------------------------------------------------------------------------
__91bd:     lsr $40,x          ; $91bd: 56 40     
            adc $70            ; $91bf: 65 70     
            ror $40            ; $91c1: 66 40     
            ror $40            ; $91c3: 66 40     
            ror $40            ; $91c5: 66 40     
            ror $60            ; $91c7: 66 60     
            adc $70            ; $91c9: 65 70     
            brk                ; $91cb: 00        
            brk                ; $91cc: 00        
            inc $0774          ; $91cd: ee 74 07  
            lda #$00           ; $91d0: a9 00     
            sta $0722          ; $91d2: 8d 22 07  
            lda #$80           ; $91d5: a9 80     
            sta $fc            ; $91d7: 85 fc     
            dec $075a          ; $91d9: ce 5a 07  
            bpl __91e9         ; $91dc: 10 0b     
            lda #$00           ; $91de: a9 00     
            sta $0772          ; $91e0: 8d 72 07  
            lda #$03           ; $91e3: a9 03     
            sta $0770          ; $91e5: 8d 70 07  
            rts                ; $91e8: 60        

;-------------------------------------------------------------------------------
__91e9:     lda $075f          ; $91e9: ad 5f 07  
            asl                ; $91ec: 0a        
            tax                ; $91ed: aa        
            lda $075c          ; $91ee: ad 5c 07  
            and #$02           ; $91f1: 29 02     
            beq __91f6         ; $91f3: f0 01     
            inx                ; $91f5: e8        
__91f6:     ldy __91bd,x       ; $91f6: bc bd 91  
            lda $075c          ; $91f9: ad 5c 07  
            lsr                ; $91fc: 4a        
            tya                ; $91fd: 98        
            bcs __9204         ; $91fe: b0 04     
            lsr                ; $9200: 4a        
            lsr                ; $9201: 4a        
            lsr                ; $9202: 4a        
            lsr                ; $9203: 4a        
__9204:     and #$0f           ; $9204: 29 0f     
            cmp $071a          ; $9206: cd 1a 07  
            beq __920f         ; $9209: f0 04     
            bcc __920f         ; $920b: 90 02     
            lda #$00           ; $920d: a9 00     
__920f:     sta $075b          ; $920f: 8d 5b 07  
            jsr __9282         ; $9212: 20 82 92  
            jmp __9264         ; $9215: 4c 64 92  

;-------------------------------------------------------------------------------
            lda $0772          ; $9218: ad 72 07  
            jsr __8e04         ; $921b: 20 04 8e  
            bit $92            ; $921e: 24 92     
            .hex 67 85         ; $9220: 67 85     Invalid Opcode - RRA $85
            .hex 37 92         ; $9222: 37 92     Invalid Opcode - RLA $92,x
            lda #$00           ; $9224: a9 00     
            sta $073c          ; $9226: 8d 3c 07  
            sta $0722          ; $9229: 8d 22 07  
            lda #$02           ; $922c: a9 02     
            sta $fc            ; $922e: 85 fc     
            inc $0774          ; $9230: ee 74 07  
            inc $0772          ; $9233: ee 72 07  
            rts                ; $9236: 60        

;-------------------------------------------------------------------------------
            lda #$00           ; $9237: a9 00     
            sta $0774          ; $9239: 8d 74 07  
            lda $06fc          ; $923c: ad fc 06  
            and #$10           ; $923f: 29 10     
            bne __9248         ; $9241: d0 05     
            lda $07a0          ; $9243: ad a0 07  
            bne __9281         ; $9246: d0 39     
__9248:     lda #$80           ; $9248: a9 80     
            sta $fc            ; $924a: 85 fc     
            jsr __9282         ; $924c: 20 82 92  
            bcc __9264         ; $924f: 90 13     
            lda $075f          ; $9251: ad 5f 07  
            sta $07fd          ; $9254: 8d fd 07  
            lda #$00           ; $9257: a9 00     
            asl                ; $9259: 0a        
            sta $0772          ; $925a: 8d 72 07  
            sta $07a0          ; $925d: 8d a0 07  
            sta $0770          ; $9260: 8d 70 07  
            rts                ; $9263: 60        

;-------------------------------------------------------------------------------
__9264:     jsr __9c03         ; $9264: 20 03 9c  
            lda #$01           ; $9267: a9 01     
            sta $0754          ; $9269: 8d 54 07  
            inc $0757          ; $926c: ee 57 07  
            lda #$00           ; $926f: a9 00     
            sta $0747          ; $9271: 8d 47 07  
            sta $0756          ; $9274: 8d 56 07  
            sta $0e            ; $9277: 85 0e     
            sta $0772          ; $9279: 8d 72 07  
            lda #$01           ; $927c: a9 01     
            sta $0770          ; $927e: 8d 70 07  
__9281:     rts                ; $9281: 60        

;-------------------------------------------------------------------------------
__9282:     sec                ; $9282: 38        
            lda $077a          ; $9283: ad 7a 07  
            beq __92a9         ; $9286: f0 21     
            lda $0761          ; $9288: ad 61 07  
            bmi __92a9         ; $928b: 30 1c     
            lda $0753          ; $928d: ad 53 07  
            eor #$01           ; $9290: 49 01     
            sta $0753          ; $9292: 8d 53 07  
            ldx #$06           ; $9295: a2 06     
__9297:     lda $075a,x        ; $9297: bd 5a 07  
            pha                ; $929a: 48        
            lda $0761,x        ; $929b: bd 61 07  
            sta $075a,x        ; $929e: 9d 5a 07  
            pla                ; $92a1: 68        
            sta $0761,x        ; $92a2: 9d 61 07  
            dex                ; $92a5: ca        
            bpl __9297         ; $92a6: 10 ef     
            clc                ; $92a8: 18        
__92a9:     rts                ; $92a9: 60        

;-------------------------------------------------------------------------------
__92aa:     lda #$ff           ; $92aa: a9 ff     
            sta $06c9          ; $92ac: 8d c9 06  
__92af:     rts                ; $92af: 60        

;-------------------------------------------------------------------------------
__92b0:     ldy $071f          ; $92b0: ac 1f 07  
            bne __92ba         ; $92b3: d0 05     
            ldy #$08           ; $92b5: a0 08     
            sty $071f          ; $92b7: 8c 1f 07  
__92ba:     dey                ; $92ba: 88        
            tya                ; $92bb: 98        
            jsr __92c8         ; $92bc: 20 c8 92  
            dec $071f          ; $92bf: ce 1f 07  
            bne __92c7         ; $92c2: d0 03     
            jsr __896a         ; $92c4: 20 6a 89  
__92c7:     rts                ; $92c7: 60        

;-------------------------------------------------------------------------------
__92c8:     jsr __8e04         ; $92c8: 20 04 8e  
            .hex db 92 ae      ; $92cb: db 92 ae  Invalid Opcode - DCP __ae92,y
            dey                ; $92ce: 88        
            ldx __fc88         ; $92cf: ae 88 fc  
            .hex 93 db         ; $92d2: 93 db     Invalid Opcode - AHX ($db),y
            .hex 92            ; $92d4: 92        Invalid Opcode - KIL 
            ldx __ae88         ; $92d5: ae 88 ae  
            dey                ; $92d8: 88        
            .hex fc 93 ee      ; $92d9: fc 93 ee  Invalid Opcode - NOP __ee93,x
            rol $07            ; $92dc: 26 07     
            lda $0726          ; $92de: ad 26 07  
            and #$0f           ; $92e1: 29 0f     
            bne __92eb         ; $92e3: d0 06     
            sta $0726          ; $92e5: 8d 26 07  
            inc $0725          ; $92e8: ee 25 07  
__92eb:     inc $06a0          ; $92eb: ee a0 06  
            lda $06a0          ; $92ee: ad a0 06  
            and #$1f           ; $92f1: 29 1f     
            sta $06a0          ; $92f3: 8d a0 06  
__92f6:     rts                ; $92f6: 60        

;-------------------------------------------------------------------------------
            brk                ; $92f7: 00        
            bmi __935a         ; $92f8: 30 60     
__92fa:     .hex 93 00         ; $92fa: 93 00     Invalid Opcode - AHX ($00),y
            brk                ; $92fc: 00        
            ora ($12),y        ; $92fd: 11 12     
__92ff:     .hex 12            ; $92ff: 12        Invalid Opcode - KIL 
            .hex 13 00         ; $9300: 13 00     Invalid Opcode - SLO ($00),y
            brk                ; $9302: 00        
            eor ($52),y        ; $9303: 51 52     
            .hex 53 00         ; $9305: 53 00     Invalid Opcode - SRE ($00),y
            brk                ; $9307: 00        
            brk                ; $9308: 00        
            brk                ; $9309: 00        
            brk                ; $930a: 00        
            brk                ; $930b: 00        
            ora ($02,x)        ; $930c: 01 02     
            .hex 02            ; $930e: 02        Invalid Opcode - KIL 
            .hex 03 00         ; $930f: 03 00     Invalid Opcode - SLO ($00,x)
            brk                ; $9311: 00        
            brk                ; $9312: 00        
            brk                ; $9313: 00        
            brk                ; $9314: 00        
            brk                ; $9315: 00        
            sta ($92),y        ; $9316: 91 92     
            .hex 93 00         ; $9318: 93 00     Invalid Opcode - AHX ($00),y
            brk                ; $931a: 00        
            brk                ; $931b: 00        
            brk                ; $931c: 00        
            eor ($52),y        ; $931d: 51 52     
            .hex 53 41         ; $931f: 53 41     Invalid Opcode - SRE ($41),y
            .hex 42            ; $9321: 42        Invalid Opcode - KIL 
            .hex 43 00         ; $9322: 43 00     Invalid Opcode - SRE ($00,x)
            brk                ; $9324: 00        
            brk                ; $9325: 00        
            brk                ; $9326: 00        
            brk                ; $9327: 00        
            sta ($92),y        ; $9328: 91 92     
            .hex 97 87         ; $932a: 97 87     Invalid Opcode - SAX $87,y
            dey                ; $932c: 88        
            .hex 89 99         ; $932d: 89 99     Invalid Opcode - NOP #$99
            brk                ; $932f: 00        
            brk                ; $9330: 00        
            brk                ; $9331: 00        
            ora ($12),y        ; $9332: 11 12     
            .hex 13 a4         ; $9334: 13 a4     Invalid Opcode - SLO ($a4),y
            lda $a5            ; $9336: a5 a5     
            lda $a6            ; $9338: a5 a6     
            .hex 97 98         ; $933a: 97 98     Invalid Opcode - SAX $98,y
            sta $0201,y        ; $933c: 99 01 02  
            .hex 03 00         ; $933f: 03 00     Invalid Opcode - SLO ($00,x)
            ldy $a5            ; $9341: a4 a5     
            ldx $00            ; $9343: a6 00     
            ora ($12),y        ; $9345: 11 12     
            .hex 12            ; $9347: 12        Invalid Opcode - KIL 
            .hex 12            ; $9348: 12        Invalid Opcode - KIL 
            .hex 13 00         ; $9349: 13 00     Invalid Opcode - SLO ($00),y
            brk                ; $934b: 00        
            brk                ; $934c: 00        
            brk                ; $934d: 00        
            ora ($02,x)        ; $934e: 01 02     
            .hex 02            ; $9350: 02        Invalid Opcode - KIL 
            .hex 03 00         ; $9351: 03 00     Invalid Opcode - SLO ($00,x)
            ldy $a5            ; $9353: a4 a5     
            lda $a6            ; $9355: a5 a6     
            brk                ; $9357: 00        
            brk                ; $9358: 00        
            brk                ; $9359: 00        
__935a:     ora ($12),y        ; $935a: 11 12     
            .hex 12            ; $935c: 12        Invalid Opcode - KIL 
            .hex 13 00         ; $935d: 13 00     Invalid Opcode - SLO ($00),y
            brk                ; $935f: 00        
            brk                ; $9360: 00        
            brk                ; $9361: 00        
            brk                ; $9362: 00        
            brk                ; $9363: 00        
            brk                ; $9364: 00        
            .hex 9c 00 8b      ; $9365: 9c 00 8b  Invalid Opcode - SHY __8b00,x
            tax                ; $9368: aa        
            tax                ; $9369: aa        
            tax                ; $936a: aa        
            tax                ; $936b: aa        
            ora ($12),y        ; $936c: 11 12     
            .hex 13 8b         ; $936e: 13 8b     Invalid Opcode - SLO ($8b),y
            brk                ; $9370: 00        
            .hex 9c 9c 00      ; $9371: 9c 9c 00  Bad Addr Mode - SHY $009c,x
            brk                ; $9374: 00        
            ora ($02,x)        ; $9375: 01 02     
            .hex 03 11         ; $9377: 03 11     Invalid Opcode - SLO ($11,x)
            .hex 12            ; $9379: 12        Invalid Opcode - KIL 
            .hex 12            ; $937a: 12        Invalid Opcode - KIL 
            .hex 13 00         ; $937b: 13 00     Invalid Opcode - SLO ($00),y
            brk                ; $937d: 00        
            brk                ; $937e: 00        
            brk                ; $937f: 00        
            tax                ; $9380: aa        
            tax                ; $9381: aa        
            .hex 9c aa 00      ; $9382: 9c aa 00  Bad Addr Mode - SHY $00aa,x
            .hex 8b 00         ; $9385: 8b 00     Invalid Opcode - XAA #$00
            ora ($02,x)        ; $9387: 01 02     
            .hex 03            ; $9389: 03        Suspected data
__938a:     .hex 80 83         ; $938a: 80 83     Invalid Opcode - NOP #$83
            brk                ; $938c: 00        
            sta ($84,x)        ; $938d: 81 84     
            brk                ; $938f: 00        
            .hex 82 85         ; $9390: 82 85     Invalid Opcode - NOP #$85
            brk                ; $9392: 00        
            .hex 02            ; $9393: 02        Invalid Opcode - KIL 
            brk                ; $9394: 00        
            brk                ; $9395: 00        
            .hex 03 00         ; $9396: 03 00     Invalid Opcode - SLO ($00,x)
            brk                ; $9398: 00        
            .hex 04 00         ; $9399: 04 00     Invalid Opcode - NOP $00
            brk                ; $939b: 00        
            brk                ; $939c: 00        
            ora $06            ; $939d: 05 06     
            .hex 07 06         ; $939f: 07 06     Invalid Opcode - SLO $06
            asl                ; $93a1: 0a        
            brk                ; $93a2: 00        
            php                ; $93a3: 08        
            ora #$4d           ; $93a4: 09 4d     
            brk                ; $93a6: 00        
            brk                ; $93a7: 00        
            ora $4e0f          ; $93a8: 0d 0f 4e  
            .hex 0e 4e         ; $93ab: 0e 4e     Suspected data
__93ad:     lsr $0d00          ; $93ad: 4e 00 0d  
            .hex 1a            ; $93b0: 1a        Invalid Opcode - NOP 
__93b1:     stx $87            ; $93b1: 86 87     
            .hex 87 87         ; $93b3: 87 87     Invalid Opcode - SAX $87
            .hex 87 87         ; $93b5: 87 87     Invalid Opcode - SAX $87
            .hex 87 87         ; $93b7: 87 87     Invalid Opcode - SAX $87
            .hex 87 87         ; $93b9: 87 87     Invalid Opcode - SAX $87
            .hex 87 69         ; $93bb: 87 69     Invalid Opcode - SAX $69
            adc #$00           ; $93bd: 69 00     
            brk                ; $93bf: 00        
            brk                ; $93c0: 00        
            brk                ; $93c1: 00        
            brk                ; $93c2: 00        
            eor $47            ; $93c3: 45 47     
            .hex 47 47         ; $93c5: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $93c7: 47 47     Invalid Opcode - SRE $47
            brk                ; $93c9: 00        
            brk                ; $93ca: 00        
            brk                ; $93cb: 00        
            brk                ; $93cc: 00        
            brk                ; $93cd: 00        
            brk                ; $93ce: 00        
            brk                ; $93cf: 00        
            brk                ; $93d0: 00        
            brk                ; $93d1: 00        
            brk                ; $93d2: 00        
            brk                ; $93d3: 00        
            brk                ; $93d4: 00        
            brk                ; $93d5: 00        
            stx $87            ; $93d6: 86 87     
__93d8:     adc #$54           ; $93d8: 69 54     
            .hex 52            ; $93da: 52        Invalid Opcode - KIL 
            .hex 62            ; $93db: 62        Invalid Opcode - KIL 
__93dc:     brk                ; $93dc: 00        
            brk                ; $93dd: 00        
            brk                ; $93de: 00        
            clc                ; $93df: 18        
            ora ($18,x)        ; $93e0: 01 18     
            .hex 07 18         ; $93e2: 07 18     Invalid Opcode - SLO $18
            .hex 0f 18 ff      ; $93e4: 0f 18 ff  Invalid Opcode - SLO __ff18
            clc                ; $93e7: 18        
            ora ($1f,x)        ; $93e8: 01 1f     
            .hex 07 1f         ; $93ea: 07 1f     Invalid Opcode - SLO $1f
            .hex 0f 1f 81      ; $93ec: 0f 1f 81  Invalid Opcode - SLO __811f
            .hex 1f 01 00      ; $93ef: 1f 01 00  Bad Addr Mode - SLO $0001,x
            .hex 8f 1f f1      ; $93f2: 8f 1f f1  Invalid Opcode - SAX __f11f
            .hex 1f f9 18      ; $93f5: 1f f9 18  Invalid Opcode - SLO $18f9,x
            sbc ($18),y        ; $93f8: f1 18     
            .hex ff 1f ad      ; $93fa: ff 1f ad  Invalid Opcode - ISC __ad1f,x
            plp                ; $93fd: 28        
            .hex 07 f0         ; $93fe: 07 f0     Invalid Opcode - SLO $f0
            .hex 03 20         ; $9400: 03 20     Invalid Opcode - SLO ($20,x)
            php                ; $9402: 08        
            sta $a2,x          ; $9403: 95 a2     
            .hex 0c a9 00      ; $9405: 0c a9 00  Bad Addr Mode - NOP $00a9
__9408:     sta $06a1,x        ; $9408: 9d a1 06  
            dex                ; $940b: ca        
            bpl __9408         ; $940c: 10 fa     
            ldy $0742          ; $940e: ac 42 07  
            beq __9455         ; $9411: f0 42     
            lda $0725          ; $9413: ad 25 07  
__9416:     cmp #$03           ; $9416: c9 03     
            bmi __941f         ; $9418: 30 05     
            sec                ; $941a: 38        
            sbc #$03           ; $941b: e9 03     
            bpl __9416         ; $941d: 10 f7     
__941f:     asl                ; $941f: 0a        
            asl                ; $9420: 0a        
            asl                ; $9421: 0a        
            asl                ; $9422: 0a        
            adc __92f6,y       ; $9423: 79 f6 92  
            adc $0726          ; $9426: 6d 26 07  
            tax                ; $9429: aa        
            lda __92fa,x       ; $942a: bd fa 92  
            beq __9455         ; $942d: f0 26     
            pha                ; $942f: 48        
            and #$0f           ; $9430: 29 0f     
            sec                ; $9432: 38        
            sbc #$01           ; $9433: e9 01     
            sta $00            ; $9435: 85 00     
            asl                ; $9437: 0a        
            adc $00            ; $9438: 65 00     
            tax                ; $943a: aa        
            pla                ; $943b: 68        
            lsr                ; $943c: 4a        
            lsr                ; $943d: 4a        
            lsr                ; $943e: 4a        
            lsr                ; $943f: 4a        
            tay                ; $9440: a8        
            lda #$03           ; $9441: a9 03     
            sta $00            ; $9443: 85 00     
__9445:     lda __938a,x       ; $9445: bd 8a 93  
            sta $06a1,y        ; $9448: 99 a1 06  
            inx                ; $944b: e8        
            iny                ; $944c: c8        
            cpy #$0b           ; $944d: c0 0b     
            beq __9455         ; $944f: f0 04     
            dec $00            ; $9451: c6 00     
            bne __9445         ; $9453: d0 f0     
__9455:     ldx $0741          ; $9455: ae 41 07  
            beq __946d         ; $9458: f0 13     
            ldy __93ad,x       ; $945a: bc ad 93  
            ldx #$00           ; $945d: a2 00     
__945f:     lda __93b1,y       ; $945f: b9 b1 93  
            beq __9467         ; $9462: f0 03     
            sta $06a1,x        ; $9464: 9d a1 06  
__9467:     iny                ; $9467: c8        
            inx                ; $9468: e8        
            cpx #$0d           ; $9469: e0 0d     
            bne __945f         ; $946b: d0 f2     
__946d:     ldy $074e          ; $946d: ac 4e 07  
            bne __947e         ; $9470: d0 0c     
            lda $075f          ; $9472: ad 5f 07  
            cmp #$07           ; $9475: c9 07     
            bne __947e         ; $9477: d0 05     
            lda #$62           ; $9479: a9 62     
            jmp __9488         ; $947b: 4c 88 94  

;-------------------------------------------------------------------------------
__947e:     lda __93d8,y       ; $947e: b9 d8 93  
            ldy $0743          ; $9481: ac 43 07  
            beq __9488         ; $9484: f0 02     
            lda #$88           ; $9486: a9 88     
__9488:     sta $07            ; $9488: 85 07     
            ldx #$00           ; $948a: a2 00     
            lda $0727          ; $948c: ad 27 07  
            asl                ; $948f: 0a        
            tay                ; $9490: a8        
__9491:     lda __93dc,y       ; $9491: b9 dc 93  
            sta $00            ; $9494: 85 00     
            iny                ; $9496: c8        
            sty $01            ; $9497: 84 01     
            lda $0743          ; $9499: ad 43 07  
            beq __94a8         ; $949c: f0 0a     
            cpx #$00           ; $949e: e0 00     
            beq __94a8         ; $94a0: f0 06     
            lda $00            ; $94a2: a5 00     
            and #$08           ; $94a4: 29 08     
            sta $00            ; $94a6: 85 00     
__94a8:     ldy #$00           ; $94a8: a0 00     
__94aa:     lda __c690,y       ; $94aa: b9 90 c6  
            bit $00            ; $94ad: 24 00     
            beq __94b6         ; $94af: f0 05     
            lda $07            ; $94b1: a5 07     
            sta $06a1,x        ; $94b3: 9d a1 06  
__94b6:     inx                ; $94b6: e8        
            cpx #$0d           ; $94b7: e0 0d     
            beq __94d3         ; $94b9: f0 18     
            lda $074e          ; $94bb: ad 4e 07  
            cmp #$02           ; $94be: c9 02     
            bne __94ca         ; $94c0: d0 08     
            cpx #$0b           ; $94c2: e0 0b     
            bne __94ca         ; $94c4: d0 04     
            lda #$54           ; $94c6: a9 54     
            sta $07            ; $94c8: 85 07     
__94ca:     iny                ; $94ca: c8        
            cpy #$08           ; $94cb: c0 08     
            bne __94aa         ; $94cd: d0 db     
            ldy $01            ; $94cf: a4 01     
            bne __9491         ; $94d1: d0 be     
__94d3:     jsr __9508         ; $94d3: 20 08 95  
            lda $06a0          ; $94d6: ad a0 06  
            jsr __9be3         ; $94d9: 20 e3 9b  
            ldx #$00           ; $94dc: a2 00     
            ldy #$00           ; $94de: a0 00     
__94e0:     sty $00            ; $94e0: 84 00     
            lda $06a1,x        ; $94e2: bd a1 06  
            and #$c0           ; $94e5: 29 c0     
            asl                ; $94e7: 0a        
            rol                ; $94e8: 2a        
            rol                ; $94e9: 2a        
            tay                ; $94ea: a8        
            lda $06a1,x        ; $94eb: bd a1 06  
            cmp __9504,y       ; $94ee: d9 04 95  
            bcs __94f5         ; $94f1: b0 02     
            lda #$00           ; $94f3: a9 00     
__94f5:     ldy $00            ; $94f5: a4 00     
            sta ($06),y        ; $94f7: 91 06     
            tya                ; $94f9: 98        
            clc                ; $94fa: 18        
            adc #$10           ; $94fb: 69 10     
            tay                ; $94fd: a8        
            inx                ; $94fe: e8        
            .hex e0            ; $94ff: e0        Suspected data
__9500:     ora __dd90         ; $9500: 0d 90 dd  
            rts                ; $9503: 60        

;-------------------------------------------------------------------------------
__9504:     bpl __9557         ; $9504: 10 51     
            dey                ; $9506: 88        
            .hex c0            ; $9507: c0        Suspected data
__9508:     ldx #$02           ; $9508: a2 02     
__950a:     stx $08            ; $950a: 86 08     
            lda #$00           ; $950c: a9 00     
            sta $0729          ; $950e: 8d 29 07  
            ldy $072c          ; $9511: ac 2c 07  
            lda ($e7),y        ; $9514: b1 e7     
            cmp #$fd           ; $9516: c9 fd     
            beq __9565         ; $9518: f0 4b     
            lda $0730,x        ; $951a: bd 30 07  
            bpl __9565         ; $951d: 10 46     
            iny                ; $951f: c8        
            lda ($e7),y        ; $9520: b1 e7     
            asl                ; $9522: 0a        
            bcc __9530         ; $9523: 90 0b     
            lda $072b          ; $9525: ad 2b 07  
            bne __9530         ; $9528: d0 06     
            inc $072b          ; $952a: ee 2b 07  
            inc $072a          ; $952d: ee 2a 07  
__9530:     dey                ; $9530: 88        
            lda ($e7),y        ; $9531: b1 e7     
            and #$0f           ; $9533: 29 0f     
            cmp #$0d           ; $9535: c9 0d     
            bne __9554         ; $9537: d0 1b     
            iny                ; $9539: c8        
            lda ($e7),y        ; $953a: b1 e7     
            dey                ; $953c: 88        
            and #$40           ; $953d: 29 40     
            bne __955d         ; $953f: d0 1c     
            lda $072b          ; $9541: ad 2b 07  
            bne __955d         ; $9544: d0 17     
            iny                ; $9546: c8        
            lda ($e7),y        ; $9547: b1 e7     
            and #$1f           ; $9549: 29 1f     
            sta $072a          ; $954b: 8d 2a 07  
            inc $072b          ; $954e: ee 2b 07  
            jmp __956e         ; $9551: 4c 6e 95  

;-------------------------------------------------------------------------------
__9554:     cmp #$0e           ; $9554: c9 0e     
            .hex d0            ; $9556: d0        Suspected data
__9557:     ora $ad            ; $9557: 05 ad     
            plp                ; $9559: 28        
            .hex 07 d0         ; $955a: 07 d0     Invalid Opcode - SLO $d0
            php                ; $955c: 08        
__955d:     lda $072a          ; $955d: ad 2a 07  
            cmp $0725          ; $9560: cd 25 07  
            bcc __956b         ; $9563: 90 06     
__9565:     jsr __9595         ; $9565: 20 95 95  
            jmp __9571         ; $9568: 4c 71 95  

;-------------------------------------------------------------------------------
__956b:     inc $0729          ; $956b: ee 29 07  
__956e:     jsr __9589         ; $956e: 20 89 95  
__9571:     ldx $08            ; $9571: a6 08     
            lda $0730,x        ; $9573: bd 30 07  
            bmi __957b         ; $9576: 30 03     
            dec $0730,x        ; $9578: de 30 07  
__957b:     dex                ; $957b: ca        
            bpl __950a         ; $957c: 10 8c     
            lda $0729          ; $957e: ad 29 07  
            bne __9508         ; $9581: d0 85     
            lda $0728          ; $9583: ad 28 07  
            bne __9508         ; $9586: d0 80     
__9588:     rts                ; $9588: 60        

;-------------------------------------------------------------------------------
__9589:     inc $072c          ; $9589: ee 2c 07  
            inc $072c          ; $958c: ee 2c 07  
            lda #$00           ; $958f: a9 00     
            sta $072b          ; $9591: 8d 2b 07  
            rts                ; $9594: 60        

;-------------------------------------------------------------------------------
__9595:     lda $0730,x        ; $9595: bd 30 07  
            bmi __959d         ; $9598: 30 03     
            .hex bc 2d         ; $959a: bc 2d     Suspected data
__959c:     .hex 07            ; $959c: 07        Suspected data
__959d:     ldx #$10           ; $959d: a2 10     
            lda ($e7),y        ; $959f: b1 e7     
            cmp #$fd           ; $95a1: c9 fd     
            beq __9588         ; $95a3: f0 e3     
            and #$0f           ; $95a5: 29 0f     
            cmp #$0f           ; $95a7: c9 0f     
            beq __95b3         ; $95a9: f0 08     
            ldx #$08           ; $95ab: a2 08     
            cmp #$0c           ; $95ad: c9 0c     
            beq __95b3         ; $95af: f0 02     
            ldx #$00           ; $95b1: a2 00     
__95b3:     stx $07            ; $95b3: 86 07     
            ldx $08            ; $95b5: a6 08     
            cmp #$0e           ; $95b7: c9 0e     
            bne __95c3         ; $95b9: d0 08     
            lda #$00           ; $95bb: a9 00     
            sta $07            ; $95bd: 85 07     
            lda #$2e           ; $95bf: a9 2e     
            bne __9616         ; $95c1: d0 53     
__95c3:     cmp #$0d           ; $95c3: c9 0d     
            bne __95e2         ; $95c5: d0 1b     
            lda #$22           ; $95c7: a9 22     
            sta $07            ; $95c9: 85 07     
            iny                ; $95cb: c8        
            lda ($e7),y        ; $95cc: b1 e7     
            and #$40           ; $95ce: 29 40     
            beq __9635         ; $95d0: f0 63     
            lda ($e7),y        ; $95d2: b1 e7     
            and #$7f           ; $95d4: 29 7f     
            cmp #$4b           ; $95d6: c9 4b     
            bne __95dd         ; $95d8: d0 03     
            inc $0745          ; $95da: ee 45 07  
__95dd:     and #$3f           ; $95dd: 29 3f     
            jmp __9616         ; $95df: 4c 16 96  

;-------------------------------------------------------------------------------
__95e2:     cmp #$0c           ; $95e2: c9 0c     
            bcs __960d         ; $95e4: b0 27     
            iny                ; $95e6: c8        
            lda ($e7),y        ; $95e7: b1 e7     
            and #$70           ; $95e9: 29 70     
            bne __95f8         ; $95eb: d0 0b     
            lda #$16           ; $95ed: a9 16     
            sta $07            ; $95ef: 85 07     
            lda ($e7),y        ; $95f1: b1 e7     
            and #$0f           ; $95f3: 29 0f     
            jmp __9616         ; $95f5: 4c 16 96  

;-------------------------------------------------------------------------------
__95f8:     sta $00            ; $95f8: 85 00     
            cmp #$70           ; $95fa: c9 70     
            bne __9608         ; $95fc: d0 0a     
            lda ($e7),y        ; $95fe: b1 e7     
            and #$08           ; $9600: 29 08     
            beq __9608         ; $9602: f0 04     
            lda #$00           ; $9604: a9 00     
            sta $00            ; $9606: 85 00     
__9608:     lda $00            ; $9608: a5 00     
            jmp __9612         ; $960a: 4c 12 96  

;-------------------------------------------------------------------------------
__960d:     iny                ; $960d: c8        
            lda ($e7),y        ; $960e: b1 e7     
            and #$70           ; $9610: 29 70     
__9612:     lsr                ; $9612: 4a        
            lsr                ; $9613: 4a        
            lsr                ; $9614: 4a        
            lsr                ; $9615: 4a        
__9616:     sta $00            ; $9616: 85 00     
            lda $0730,x        ; $9618: bd 30 07  
            bpl __965f         ; $961b: 10 42     
            lda $072a          ; $961d: ad 2a 07  
            .hex cd 25         ; $9620: cd 25     Suspected data
__9622:     .hex 07 f0         ; $9622: 07 f0     Invalid Opcode - SLO $f0
            ora ($ac),y        ; $9624: 11 ac     
            bit __b107         ; $9626: 2c 07 b1  
            .hex e7 29         ; $9629: e7 29     Invalid Opcode - ISC $29
            .hex 0f c9 0e      ; $962b: 0f c9 0e  Invalid Opcode - SLO $0ec9
            bne __9635         ; $962e: d0 05     
__9630:     .hex ad 28         ; $9630: ad 28     Suspected data
__9632:     .hex 07 d0         ; $9632: 07 d0     Invalid Opcode - SLO $d0
__9634:     .hex 21            ; $9634: 21        Suspected data
__9635:     rts                ; $9635: 60        

;-------------------------------------------------------------------------------
            lda $0728          ; $9636: ad 28 07  
            beq __9646         ; $9639: f0 0b     
            lda #$00           ; $963b: a9 00     
            sta $0728          ; $963d: 8d 28 07  
            sta $0729          ; $9640: 8d 29 07  
            sta $08            ; $9643: 85 08     
            rts                ; $9645: 60        

;-------------------------------------------------------------------------------
__9646:     ldy $072c          ; $9646: ac 2c 07  
            lda ($e7),y        ; $9649: b1 e7     
            and #$f0           ; $964b: 29 f0     
            lsr                ; $964d: 4a        
            lsr                ; $964e: 4a        
            lsr                ; $964f: 4a        
            lsr                ; $9650: 4a        
            cmp $0726          ; $9651: cd 26 07  
            bne __9635         ; $9654: d0 df     
            lda $072c          ; $9656: ad 2c 07  
            sta $072d,x        ; $9659: 9d 2d 07  
            jsr __9589         ; $965c: 20 89 95  
__965f:     lda $00            ; $965f: a5 00     
            clc                ; $9661: 18        
            adc $07            ; $9662: 65 07     
            jsr __8e04         ; $9664: 20 04 8e  
            sbc $98            ; $9667: e5 98     
            rti                ; $9669: 40        

;-------------------------------------------------------------------------------
            .hex 97 2e         ; $966a: 97 2e     Invalid Opcode - SAX $2e,y
            txs                ; $966c: 9a        
            rol __f29a,x       ; $966d: 3e 9a f2  
            sta __9a50,y       ; $9670: 99 50 9a  
            eor __e59a,y       ; $9673: 59 9a e5  
            tya                ; $9676: 98        
            .hex 43 9b         ; $9677: 43 9b     Invalid Opcode - SRE ($9b,x)
            tsx                ; $9679: ba        
            .hex 97 79         ; $967a: 97 79     Invalid Opcode - SAX $79,y
            sta __997c,y       ; $967c: 99 7c 99  
            .hex 7f 99 57      ; $967f: 7f 99 57  Invalid Opcode - RRA $5799,x
            sta __9968,y       ; $9682: 99 68 99  
            .hex 6b 99         ; $9685: 6b 99     Invalid Opcode - ARR #$99
            bne __9622         ; $9687: d0 99     
            .hex d7 99         ; $9689: d7 99     Invalid Opcode - DCP $99,x
            asl $98            ; $968b: 06 98     
            .hex b7 9a         ; $968d: b7 9a     Invalid Opcode - LAX $9a,y
            .hex ab 98         ; $968f: ab 98     Invalid Opcode - LAX #$98
            sty $99,x          ; $9691: 94 99     
            bpl __9630         ; $9693: 10 9b     
            bpl __9632         ; $9695: 10 9b     
            bpl __9634         ; $9697: 10 9b     
            .hex 03 9b         ; $9699: 03 9b     Invalid Opcode - SLO ($9b,x)
            .hex 1b 9b 1b      ; $969b: 1b 9b 1b  Invalid Opcode - SLO $1b9b,y
            .hex 9b            ; $969e: 9b        Invalid Opcode - TAS 
            .hex 1b 9b 16      ; $969f: 1b 9b 16  Invalid Opcode - SLO $169b,y
            .hex 9b            ; $96a2: 9b        Invalid Opcode - TAS 
            .hex 1b 9b 6f      ; $96a3: 1b 9b 6f  Invalid Opcode - SLO $6f9b,y
            tya                ; $96a6: 98        
            ora __d39a,y       ; $96a7: 19 9a d3  
            txs                ; $96aa: 9a        
            .hex 82 98         ; $96ab: 82 98     Invalid Opcode - NOP #$98
            .hex 9e 99 09      ; $96ad: 9e 99 09  Invalid Opcode - SHX $0999,y
            txs                ; $96b0: 9a        
            asl $019a          ; $96b1: 0e 9a 01  
            txs                ; $96b4: 9a        
            .hex f2            ; $96b5: f2        Invalid Opcode - KIL 
            stx $0d,y          ; $96b6: 96 0d     
            .hex 97 0d         ; $96b8: 97 0d     Invalid Opcode - SAX $0d,y
            .hex 97 2b         ; $96ba: 97 2b     Invalid Opcode - SAX $2b,y
            .hex 97 2b         ; $96bc: 97 2b     Invalid Opcode - SAX $2b,y
            .hex 97 2b         ; $96be: 97 2b     Invalid Opcode - SAX $2b,y
            .hex 97 45         ; $96c0: 97 45     Invalid Opcode - SAX $45,y
            stx $c5,y          ; $96c2: 96 c5     
            stx $bc,y          ; $96c4: 96 bc     
            and __c807         ; $96c6: 2d 07 c8  
            lda ($e7),y        ; $96c9: b1 e7     
            pha                ; $96cb: 48        
            and #$40           ; $96cc: 29 40     
            bne __96e2         ; $96ce: d0 12     
            pla                ; $96d0: 68        
            pha                ; $96d1: 48        
            and #$0f           ; $96d2: 29 0f     
            sta $0727          ; $96d4: 8d 27 07  
            pla                ; $96d7: 68        
            and #$30           ; $96d8: 29 30     
            lsr                ; $96da: 4a        
            lsr                ; $96db: 4a        
            lsr                ; $96dc: 4a        
            lsr                ; $96dd: 4a        
            sta $0742          ; $96de: 8d 42 07  
            rts                ; $96e1: 60        

;-------------------------------------------------------------------------------
__96e2:     pla                ; $96e2: 68        
            and #$07           ; $96e3: 29 07     
            cmp #$04           ; $96e5: c9 04     
            bcc __96ee         ; $96e7: 90 05     
            sta $0744          ; $96e9: 8d 44 07  
            lda #$00           ; $96ec: a9 00     
__96ee:     sta $0741          ; $96ee: 8d 41 07  
            rts                ; $96f1: 60        

;-------------------------------------------------------------------------------
            ldx #$04           ; $96f2: a2 04     
            lda $075f          ; $96f4: ad 5f 07  
            beq __9701         ; $96f7: f0 08     
            inx                ; $96f9: e8        
            ldy $074e          ; $96fa: ac 4e 07  
            dey                ; $96fd: 88        
            bne __9701         ; $96fe: d0 01     
            inx                ; $9700: e8        
__9701:     txa                ; $9701: 8a        
            sta $06d6          ; $9702: 8d d6 06  
__9705:     jsr __8808         ; $9705: 20 08 88  
            lda #$0d           ; $9708: a9 0d     
            jsr __9716         ; $970a: 20 16 97  
            lda $0723          ; $970d: ad 23 07  
            eor #$01           ; $9710: 49 01     
            sta $0723          ; $9712: 8d 23 07  
            rts                ; $9715: 60        

;-------------------------------------------------------------------------------
__9716:     sta $00            ; $9716: 85 00     
            lda #$00           ; $9718: a9 00     
            ldx #$04           ; $971a: a2 04     
__971c:     ldy $16,x          ; $971c: b4 16     
            cpy $00            ; $971e: c4 00     
__9720:     bne __9724         ; $9720: d0 02     
            sta $0f,x          ; $9722: 95 0f     
__9724:     dex                ; $9724: ca        
            bpl __971c         ; $9725: 10 f5     
            rts                ; $9727: 60        

;-------------------------------------------------------------------------------
            .hex 14 17         ; $9728: 14 17     Invalid Opcode - NOP $17,x
            clc                ; $972a: 18        
            ldx $00            ; $972b: a6 00     
            lda __9720,x       ; $972d: bd 20 97  
            ldy #$05           ; $9730: a0 05     
__9732:     dey                ; $9732: 88        
            bmi __973c         ; $9733: 30 07     
            cmp $0016,y        ; $9735: d9 16 00  
            bne __9732         ; $9738: d0 f8     
            lda #$00           ; $973a: a9 00     
__973c:     sta $06cd          ; $973c: 8d cd 06  
            rts                ; $973f: 60        

;-------------------------------------------------------------------------------
            lda $0733          ; $9740: ad 33 07  
            jsr __8e04         ; $9743: 20 04 8e  
            jmp $7897          ; $9746: 4c 97 78  

;-------------------------------------------------------------------------------
            .hex 97 69         ; $9749: 97 69     Invalid Opcode - SAX $69,y
            txs                ; $974b: 9a        
            jsr __9bbd         ; $974c: 20 bd 9b  
            lda $0730,x        ; $974f: bd 30 07  
            beq __9773         ; $9752: f0 1f     
            bpl __9767         ; $9754: 10 11     
            tya                ; $9756: 98        
            sta $0730,x        ; $9757: 9d 30 07  
            lda $0725          ; $975a: ad 25 07  
            ora $0726          ; $975d: 0d 26 07  
            beq __9767         ; $9760: f0 05     
            lda #$16           ; $9762: a9 16     
            jmp __97b0         ; $9764: 4c b0 97  

;-------------------------------------------------------------------------------
__9767:     ldx $07            ; $9767: a6 07     
            lda #$17           ; $9769: a9 17     
            sta $06a1,x        ; $976b: 9d a1 06  
            lda #$4c           ; $976e: a9 4c     
            jmp __97aa         ; $9770: 4c aa 97  

;-------------------------------------------------------------------------------
__9773:     lda #$18           ; $9773: a9 18     
            jmp __97b0         ; $9775: 4c b0 97  

;-------------------------------------------------------------------------------
            jsr __9bae         ; $9778: 20 ae 9b  
            sty $06            ; $977b: 84 06     
            bcc __978b         ; $977d: 90 0c     
            lda $0730,x        ; $977f: bd 30 07  
            lsr                ; $9782: 4a        
            sta $0736,x        ; $9783: 9d 36 07  
            lda #$19           ; $9786: a9 19     
            jmp __97b0         ; $9788: 4c b0 97  

;-------------------------------------------------------------------------------
__978b:     lda #$1b           ; $978b: a9 1b     
            ldy $0730,x        ; $978d: bc 30 07  
            beq __97b0         ; $9790: f0 1e     
            lda $0736,x        ; $9792: bd 36 07  
            sta $06            ; $9795: 85 06     
            ldx $07            ; $9797: a6 07     
            lda #$1a           ; $9799: a9 1a     
            sta $06a1,x        ; $979b: 9d a1 06  
            cpy $06            ; $979e: c4 06     
            bne __97ce         ; $97a0: d0 2c     
            inx                ; $97a2: e8        
            lda #$4f           ; $97a3: a9 4f     
            sta $06a1,x        ; $97a5: 9d a1 06  
            lda #$50           ; $97a8: a9 50     
__97aa:     inx                ; $97aa: e8        
            ldy #$0f           ; $97ab: a0 0f     
            jmp __9b7f         ; $97ad: 4c 7f 9b  

;-------------------------------------------------------------------------------
__97b0:     ldx $07            ; $97b0: a6 07     
            ldy #$00           ; $97b2: a0 00     
            jmp __9b7f         ; $97b4: 4c 7f 9b  

;-------------------------------------------------------------------------------
__97b7:     .hex 42            ; $97b7: 42        Invalid Opcode - KIL 
            eor ($43,x)        ; $97b8: 41 43     
            jsr __9bae         ; $97ba: 20 ae 9b  
            ldy #$00           ; $97bd: a0 00     
            bcs __97c8         ; $97bf: b0 07     
            iny                ; $97c1: c8        
            lda $0730,x        ; $97c2: bd 30 07  
            bne __97c8         ; $97c5: d0 01     
            iny                ; $97c7: c8        
__97c8:     lda __97b7,y       ; $97c8: b9 b7 97  
            sta $06a1          ; $97cb: 8d a1 06  
__97ce:     rts                ; $97ce: 60        

;-------------------------------------------------------------------------------
__97cf:     brk                ; $97cf: 00        
            eor $45            ; $97d0: 45 45     
            eor $00            ; $97d2: 45 00     
            brk                ; $97d4: 00        
            pha                ; $97d5: 48        
            .hex 47 46         ; $97d6: 47 46     Invalid Opcode - SRE $46
            brk                ; $97d8: 00        
            eor $49            ; $97d9: 45 49     
            eor #$49           ; $97db: 49 49     
            eor $47            ; $97dd: 45 47     
            .hex 47 4a         ; $97df: 47 4a     Invalid Opcode - SRE $4a
            .hex 47 47         ; $97e1: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $97e3: 47 47     Invalid Opcode - SRE $47
            .hex 4b 47         ; $97e5: 4b 47     Invalid Opcode - ALR #$47
            .hex 47 49         ; $97e7: 47 49     Invalid Opcode - SRE $49
            eor #$49           ; $97e9: 49 49     
            eor #$49           ; $97eb: 49 49     
            .hex 47 4a         ; $97ed: 47 4a     Invalid Opcode - SRE $4a
            .hex 47 4a         ; $97ef: 47 4a     Invalid Opcode - SRE $4a
            .hex 47 47         ; $97f1: 47 47     Invalid Opcode - SRE $47
            .hex 4b 47         ; $97f3: 4b 47     Invalid Opcode - ALR #$47
            .hex 4b 47         ; $97f5: 4b 47     Invalid Opcode - ALR #$47
            .hex 47 47         ; $97f7: 47 47     Invalid Opcode - SRE $47
            .hex 47 47         ; $97f9: 47 47     Invalid Opcode - SRE $47
            .hex 47 4a         ; $97fb: 47 4a     Invalid Opcode - SRE $4a
            .hex 47 4a         ; $97fd: 47 4a     Invalid Opcode - SRE $4a
            .hex 47            ; $97ff: 47        Suspected data
__9800:     lsr                ; $9800: 4a        
            .hex 4b            ; $9801: 4b        Suspected data
__9802:     .hex 47 4b         ; $9802: 47 4b     Invalid Opcode - SRE $4b
            .hex 47 4b         ; $9804: 47 4b     Invalid Opcode - SRE $4b
            jsr __9bbd         ; $9806: 20 bd 9b  
            sty $07            ; $9809: 84 07     
            ldy #$04           ; $980b: a0 04     
            jsr __9bb1         ; $980d: 20 b1 9b  
            txa                ; $9810: 8a        
            pha                ; $9811: 48        
            ldy $0730,x        ; $9812: bc 30 07  
            ldx $07            ; $9815: a6 07     
            lda #$0b           ; $9817: a9 0b     
            sta $06            ; $9819: 85 06     
__981b:     lda __97cf,y       ; $981b: b9 cf 97  
            sta $06a1,x        ; $981e: 9d a1 06  
            inx                ; $9821: e8        
            lda $06            ; $9822: a5 06     
            beq __982d         ; $9824: f0 07     
            iny                ; $9826: c8        
            iny                ; $9827: c8        
            iny                ; $9828: c8        
            iny                ; $9829: c8        
            iny                ; $982a: c8        
            dec $06            ; $982b: c6 06     
__982d:     cpx #$0b           ; $982d: e0 0b     
            bne __981b         ; $982f: d0 ea     
            pla                ; $9831: 68        
            tax                ; $9832: aa        
            lda $0725          ; $9833: ad 25 07  
            beq __986e         ; $9836: f0 36     
            lda $0730,x        ; $9838: bd 30 07  
            cmp #$01           ; $983b: c9 01     
            beq __9869         ; $983d: f0 2a     
            ldy $07            ; $983f: a4 07     
            bne __9847         ; $9841: d0 04     
            cmp #$03           ; $9843: c9 03     
            beq __9869         ; $9845: f0 22     
__9847:     cmp #$02           ; $9847: c9 02     
            bne __986e         ; $9849: d0 23     
            jsr __9bcd         ; $984b: 20 cd 9b  
            pha                ; $984e: 48        
            jsr __994a         ; $984f: 20 4a 99  
            pla                ; $9852: 68        
            sta $87,x          ; $9853: 95 87     
            lda $0725          ; $9855: ad 25 07  
            sta $6e,x          ; $9858: 95 6e     
            lda #$01           ; $985a: a9 01     
            sta $b6,x          ; $985c: 95 b6     
            sta $0f,x          ; $985e: 95 0f     
            lda #$90           ; $9860: a9 90     
            sta $cf,x          ; $9862: 95 cf     
            lda #$31           ; $9864: a9 31     
            sta $16,x          ; $9866: 95 16     
            rts                ; $9868: 60        

;-------------------------------------------------------------------------------
__9869:     ldy #$52           ; $9869: a0 52     
            sty $06ab          ; $986b: 8c ab 06  
__986e:     rts                ; $986e: 60        

;-------------------------------------------------------------------------------
            jsr __9bbd         ; $986f: 20 bd 9b  
            ldy $0730,x        ; $9872: bc 30 07  
            ldx $07            ; $9875: a6 07     
            lda #$6b           ; $9877: a9 6b     
            sta $06a1,x        ; $9879: 9d a1 06  
            lda #$6c           ; $987c: a9 6c     
            sta $06a2,x        ; $987e: 9d a2 06  
            rts                ; $9881: 60        

;-------------------------------------------------------------------------------
            ldy #$03           ; $9882: a0 03     
            jsr __9bb1         ; $9884: 20 b1 9b  
            ldy #$0a           ; $9887: a0 0a     
            jsr __98b3         ; $9889: 20 b3 98  
            bcs __989e         ; $988c: b0 10     
            ldx #$06           ; $988e: a2 06     
__9890:     lda #$00           ; $9890: a9 00     
            sta $06a1,x        ; $9892: 9d a1 06  
            dex                ; $9895: ca        
            bpl __9890         ; $9896: 10 f8     
            lda __98dd,y       ; $9898: b9 dd 98  
            sta $06a8          ; $989b: 8d a8 06  
__989e:     rts                ; $989e: 60        

;-------------------------------------------------------------------------------
__989f:     ora $14,x          ; $989f: 15 14     
            brk                ; $98a1: 00        
            brk                ; $98a2: 00        
__98a3:     ora $1e,x          ; $98a3: 15 1e     
            .hex 1d 1c         ; $98a5: 1d 1c     Suspected data
__98a7:     ora $21,x          ; $98a7: 15 21     
            jsr __a01f         ; $98a9: 20 1f a0  
            .hex 03 20         ; $98ac: 03 20     Invalid Opcode - SLO ($20,x)
            lda ($9b),y        ; $98ae: b1 9b     
            jsr __9bbd         ; $98b0: 20 bd 9b  
__98b3:     dey                ; $98b3: 88        
            dey                ; $98b4: 88        
            sty $05            ; $98b5: 84 05     
            ldy $0730,x        ; $98b7: bc 30 07  
            sty $06            ; $98ba: 84 06     
            ldx $05            ; $98bc: a6 05     
            inx                ; $98be: e8        
            lda __989f,y       ; $98bf: b9 9f 98  
            cmp #$00           ; $98c2: c9 00     
            beq __98ce         ; $98c4: f0 08     
            ldx #$00           ; $98c6: a2 00     
            ldy $05            ; $98c8: a4 05     
            jsr __9b7f         ; $98ca: 20 7f 9b  
            clc                ; $98cd: 18        
__98ce:     ldy $06            ; $98ce: a4 06     
            lda __98a3,y       ; $98d0: b9 a3 98  
            sta $06a1,x        ; $98d3: 9d a1 06  
            lda __98a7,y       ; $98d6: b9 a7 98  
            sta $06a2,x        ; $98d9: 9d a2 06  
            rts                ; $98dc: 60        

;-------------------------------------------------------------------------------
__98dd:     ora ($10),y        ; $98dd: 11 10     
__98df:     ora $14,x          ; $98df: 15 14     
            .hex 13 12         ; $98e1: 13 12     Invalid Opcode - SLO ($12),y
            ora $14,x          ; $98e3: 15 14     
            jsr __9939         ; $98e5: 20 39 99  
            lda $00            ; $98e8: a5 00     
            beq __98f0         ; $98ea: f0 04     
            iny                ; $98ec: c8        
            iny                ; $98ed: c8        
            iny                ; $98ee: c8        
            iny                ; $98ef: c8        
__98f0:     tya                ; $98f0: 98        
            pha                ; $98f1: 48        
            lda $0760          ; $98f2: ad 60 07  
            ora $075f          ; $98f5: 0d 5f 07  
            beq __9925         ; $98f8: f0 2b     
            ldy $0730,x        ; $98fa: bc 30 07  
            beq __9925         ; $98fd: f0 26     
            jsr __994a         ; $98ff: 20 4a 99  
            bcs __9925         ; $9902: b0 21     
            jsr __9bcd         ; $9904: 20 cd 9b  
            clc                ; $9907: 18        
            adc #$08           ; $9908: 69 08     
            sta $87,x          ; $990a: 95 87     
            lda $0725          ; $990c: ad 25 07  
            adc #$00           ; $990f: 69 00     
            sta $6e,x          ; $9911: 95 6e     
            lda #$01           ; $9913: a9 01     
            sta $b6,x          ; $9915: 95 b6     
            sta $0f,x          ; $9917: 95 0f     
            jsr __9bd5         ; $9919: 20 d5 9b  
            sta $cf,x          ; $991c: 95 cf     
            lda #$0d           ; $991e: a9 0d     
            sta $16,x          ; $9920: 95 16     
            .hex 20 8d         ; $9922: 20 8d     Suspected data
__9924:     .hex c7            ; $9924: c7        Suspected data
__9925:     pla                ; $9925: 68        
            tay                ; $9926: a8        
            ldx $07            ; $9927: a6 07     
            lda __98dd,y       ; $9929: b9 dd 98  
            sta $06a1,x        ; $992c: 9d a1 06  
            inx                ; $992f: e8        
            lda __98df,y       ; $9930: b9 df 98  
            ldy $06            ; $9933: a4 06     
            dey                ; $9935: 88        
            jmp __9b7f         ; $9936: 4c 7f 9b  

;-------------------------------------------------------------------------------
__9939:     ldy #$01           ; $9939: a0 01     
            jsr __9bb1         ; $993b: 20 b1 9b  
            jsr __9bbd         ; $993e: 20 bd 9b  
            tya                ; $9941: 98        
            and #$07           ; $9942: 29 07     
            sta $06            ; $9944: 85 06     
            ldy $0730,x        ; $9946: bc 30 07  
            rts                ; $9949: 60        

;-------------------------------------------------------------------------------
__994a:     ldx #$00           ; $994a: a2 00     
__994c:     clc                ; $994c: 18        
            lda $0f,x          ; $994d: b5 0f     
            beq __9956         ; $994f: f0 05     
            inx                ; $9951: e8        
            cpx #$05           ; $9952: e0 05     
            bne __994c         ; $9954: d0 f6     
__9956:     rts                ; $9956: 60        

;-------------------------------------------------------------------------------
            jsr __9bae         ; $9957: 20 ae 9b  
            lda #$86           ; $995a: a9 86     
            sta $06ab          ; $995c: 8d ab 06  
            ldx #$0b           ; $995f: a2 0b     
            ldy #$01           ; $9961: a0 01     
            lda #$87           ; $9963: a9 87     
            jmp __9b7f         ; $9965: 4c 7f 9b  

;-------------------------------------------------------------------------------
__9968:     lda #$03           ; $9968: a9 03     
            bit $07a9          ; $996a: 2c a9 07  
            pha                ; $996d: 48        
            jsr __9bae         ; $996e: 20 ae 9b  
            pla                ; $9971: 68        
            tax                ; $9972: aa        
            lda #$c0           ; $9973: a9 c0     
            sta $06a1,x        ; $9975: 9d a1 06  
            rts                ; $9978: 60        

;-------------------------------------------------------------------------------
            lda #$06           ; $9979: a9 06     
            .hex 2c            ; $997b: 2c        Suspected data
__997c:     lda #$07           ; $997c: a9 07     
            bit $09a9          ; $997e: 2c a9 09  
            pha                ; $9981: 48        
            jsr __9bae         ; $9982: 20 ae 9b  
            pla                ; $9985: 68        
            tax                ; $9986: aa        
            lda #$0b           ; $9987: a9 0b     
            sta $06a1,x        ; $9989: 9d a1 06  
            inx                ; $998c: e8        
            ldy #$00           ; $998d: a0 00     
            lda #$63           ; $998f: a9 63     
            jmp __9b7f         ; $9991: 4c 7f 9b  

;-------------------------------------------------------------------------------
            jsr __9bbd         ; $9994: 20 bd 9b  
            ldx #$02           ; $9997: a2 02     
            lda #$6d           ; $9999: a9 6d     
            jmp __9b7f         ; $999b: 4c 7f 9b  

;-------------------------------------------------------------------------------
            lda #$24           ; $999e: a9 24     
            sta $06a1          ; $99a0: 8d a1 06  
            ldx #$01           ; $99a3: a2 01     
            ldy #$08           ; $99a5: a0 08     
            lda #$25           ; $99a7: a9 25     
            jsr __9b7f         ; $99a9: 20 7f 9b  
            lda #$61           ; $99ac: a9 61     
            sta $06ab          ; $99ae: 8d ab 06  
            jsr __9bcd         ; $99b1: 20 cd 9b  
            sec                ; $99b4: 38        
            sbc #$08           ; $99b5: e9 08     
            sta $8c            ; $99b7: 85 8c     
            lda $0725          ; $99b9: ad 25 07  
            sbc #$00           ; $99bc: e9 00     
            sta $73            ; $99be: 85 73     
            lda #$30           ; $99c0: a9 30     
            sta $d4            ; $99c2: 85 d4     
            lda #$b0           ; $99c4: a9 b0     
            sta $010d          ; $99c6: 8d 0d 01  
            lda #$30           ; $99c9: a9 30     
            sta $1b            ; $99cb: 85 1b     
            inc $14            ; $99cd: e6 14     
            rts                ; $99cf: 60        

;-------------------------------------------------------------------------------
            ldx #$00           ; $99d0: a2 00     
            ldy #$0f           ; $99d2: a0 0f     
            jmp __99e9         ; $99d4: 4c e9 99  

;-------------------------------------------------------------------------------
            txa                ; $99d7: 8a        
            pha                ; $99d8: 48        
            ldx #$01           ; $99d9: a2 01     
            ldy #$0f           ; $99db: a0 0f     
            lda #$44           ; $99dd: a9 44     
            jsr __9b7f         ; $99df: 20 7f 9b  
            pla                ; $99e2: 68        
            tax                ; $99e3: aa        
            jsr __9bbd         ; $99e4: 20 bd 9b  
            ldx #$01           ; $99e7: a2 01     
__99e9:     lda #$40           ; $99e9: a9 40     
            jmp __9b7f         ; $99eb: 4c 7f 9b  

;-------------------------------------------------------------------------------
__99ee:     .hex c3 c2         ; $99ee: c3 c2     Invalid Opcode - DCP ($c2,x)
            .hex c2 c2         ; $99f0: c2 c2     Invalid Opcode - NOP #$c2
            ldy $074e          ; $99f2: ac 4e 07  
            lda __99ee,y       ; $99f5: b9 ee 99  
            .hex 4c            ; $99f8: 4c        Suspected data
__99f9:     .hex 44 9a         ; $99f9: 44 9a     Invalid Opcode - NOP $9a
            .hex 06            ; $99fb: 06        Suspected data
__99fc:     .hex 07 08         ; $99fc: 07 08     Invalid Opcode - SLO $08
            cmp $0c            ; $99fe: c5 0c     
            .hex 89 a0         ; $9a00: 89 a0     Invalid Opcode - NOP #$a0
            .hex 0c 20 b1      ; $9a02: 0c 20 b1  Invalid Opcode - NOP __b120
            .hex 9b            ; $9a05: 9b        Invalid Opcode - TAS 
            jmp __9a0e         ; $9a06: 4c 0e 9a  

;-------------------------------------------------------------------------------
            lda #$08           ; $9a09: a9 08     
            sta $0773          ; $9a0b: 8d 73 07  
__9a0e:     ldy $00            ; $9a0e: a4 00     
            ldx __99f9,y       ; $9a10: be f9 99  
            lda __99fc,y       ; $9a13: b9 fc 99  
            jmp __9a20         ; $9a16: 4c 20 9a  

;-------------------------------------------------------------------------------
            jsr __9bbd         ; $9a19: 20 bd 9b  
            ldx $07            ; $9a1c: a6 07     
            lda #$c4           ; $9a1e: a9 c4     
__9a20:     ldy #$00           ; $9a20: a0 00     
            jmp __9b7f         ; $9a22: 4c 7f 9b  

;-------------------------------------------------------------------------------
__9a25:     adc #$61           ; $9a25: 69 61     
            adc ($62,x)        ; $9a27: 61 62     
__9a29:     .hex 22            ; $9a29: 22        Invalid Opcode - KIL 
            eor ($52),y        ; $9a2a: 51 52     
            .hex 52            ; $9a2c: 52        Invalid Opcode - KIL 
            dey                ; $9a2d: 88        
            ldy $074e          ; $9a2e: ac 4e 07  
            lda $0743          ; $9a31: ad 43 07  
            beq __9a38         ; $9a34: f0 02     
            ldy #$04           ; $9a36: a0 04     
__9a38:     lda __9a29,y       ; $9a38: b9 29 9a  
            jmp __9a44         ; $9a3b: 4c 44 9a  

;-------------------------------------------------------------------------------
            ldy $074e          ; $9a3e: ac 4e 07  
            lda __9a25,y       ; $9a41: b9 25 9a  
__9a44:     pha                ; $9a44: 48        
            jsr __9bae         ; $9a45: 20 ae 9b  
__9a48:     ldx $07            ; $9a48: a6 07     
            ldy #$00           ; $9a4a: a0 00     
            pla                ; $9a4c: 68        
            jmp __9b7f         ; $9a4d: 4c 7f 9b  

;-------------------------------------------------------------------------------
__9a50:     ldy $074e          ; $9a50: ac 4e 07  
            lda __9a29,y       ; $9a53: b9 29 9a  
            jmp __9a5f         ; $9a56: 4c 5f 9a  

;-------------------------------------------------------------------------------
            ldy $074e          ; $9a59: ac 4e 07  
            lda __9a25,y       ; $9a5c: b9 25 9a  
__9a5f:     pha                ; $9a5f: 48        
            jsr __9bbd         ; $9a60: 20 bd 9b  
            pla                ; $9a63: 68        
            ldx $07            ; $9a64: a6 07     
            jmp __9b7f         ; $9a66: 4c 7f 9b  

;-------------------------------------------------------------------------------
            jsr __9bbd         ; $9a69: 20 bd 9b  
            ldx $07            ; $9a6c: a6 07     
            lda #$64           ; $9a6e: a9 64     
            sta $06a1,x        ; $9a70: 9d a1 06  
            inx                ; $9a73: e8        
            dey                ; $9a74: 88        
            bmi __9a85         ; $9a75: 30 0e     
            lda #$65           ; $9a77: a9 65     
            sta $06a1,x        ; $9a79: 9d a1 06  
            inx                ; $9a7c: e8        
            dey                ; $9a7d: 88        
            bmi __9a85         ; $9a7e: 30 05     
            lda #$66           ; $9a80: a9 66     
            jsr __9b7f         ; $9a82: 20 7f 9b  
__9a85:     ldx $046a          ; $9a85: ae 6a 04  
            jsr __9bd5         ; $9a88: 20 d5 9b  
            sta $0477,x        ; $9a8b: 9d 77 04  
            lda $0725          ; $9a8e: ad 25 07  
            sta $046b,x        ; $9a91: 9d 6b 04  
            jsr __9bcd         ; $9a94: 20 cd 9b  
            sta $0471,x        ; $9a97: 9d 71 04  
            inx                ; $9a9a: e8        
            cpx #$06           ; $9a9b: e0 06     
            bcc __9aa1         ; $9a9d: 90 02     
            ldx #$00           ; $9a9f: a2 00     
__9aa1:     stx $046a          ; $9aa1: 8e 6a 04  
            rts                ; $9aa4: 60        

;-------------------------------------------------------------------------------
__9aa5:     .hex 07 07         ; $9aa5: 07 07     Invalid Opcode - SLO $07
            asl $05            ; $9aa7: 06 05     
            .hex 04 03         ; $9aa9: 04 03     Invalid Opcode - NOP $03
            .hex 02            ; $9aab: 02        Invalid Opcode - KIL 
            ora ($00,x)        ; $9aac: 01 00     
__9aae:     .hex 03 03         ; $9aae: 03 03     Invalid Opcode - SLO ($03,x)
            .hex 04 05         ; $9ab0: 04 05     Invalid Opcode - NOP $05
            asl $07            ; $9ab2: 06 07     
            php                ; $9ab4: 08        
            ora #$0a           ; $9ab5: 09 0a     
            jsr __9bae         ; $9ab7: 20 ae 9b  
            bcc __9ac1         ; $9aba: 90 05     
            lda #$09           ; $9abc: a9 09     
            sta $0734          ; $9abe: 8d 34 07  
__9ac1:     dec $0734          ; $9ac1: ce 34 07  
            ldy $0734          ; $9ac4: ac 34 07  
            ldx __9aae,y       ; $9ac7: be ae 9a  
            lda __9aa5,y       ; $9aca: b9 a5 9a  
            tay                ; $9acd: a8        
            lda #$61           ; $9ace: a9 61     
            jmp __9b7f         ; $9ad0: 4c 7f 9b  

;-------------------------------------------------------------------------------
            jsr __9bbd         ; $9ad3: 20 bd 9b  
            jsr __994a         ; $9ad6: 20 4a 99  
            bcs __9b02         ; $9ad9: b0 27     
            jsr __9bcd         ; $9adb: 20 cd 9b  
            sta $87,x          ; $9ade: 95 87     
            lda $0725          ; $9ae0: ad 25 07  
            sta $6e,x          ; $9ae3: 95 6e     
            jsr __9bd5         ; $9ae5: 20 d5 9b  
            sta $cf,x          ; $9ae8: 95 cf     
            sta $58,x          ; $9aea: 95 58     
            lda #$32           ; $9aec: a9 32     
            sta $16,x          ; $9aee: 95 16     
            ldy #$01           ; $9af0: a0 01     
            sty $b6,x          ; $9af2: 94 b6     
            inc $0f,x          ; $9af4: f6 0f     
            ldx $07            ; $9af6: a6 07     
            lda #$67           ; $9af8: a9 67     
            sta $06a1,x        ; $9afa: 9d a1 06  
            lda #$68           ; $9afd: a9 68     
            sta $06a2,x        ; $9aff: 9d a2 06  
__9b02:     rts                ; $9b02: 60        

;-------------------------------------------------------------------------------
            lda $075d          ; $9b03: ad 5d 07  
            beq __9b3e         ; $9b06: f0 36     
            lda #$00           ; $9b08: a9 00     
            sta $075d          ; $9b0a: 8d 5d 07  
            jmp __9b1b         ; $9b0d: 4c 1b 9b  

;-------------------------------------------------------------------------------
            jsr __9b38         ; $9b10: 20 38 9b  
            jmp __9b2e         ; $9b13: 4c 2e 9b  

;-------------------------------------------------------------------------------
            lda #$00           ; $9b16: a9 00     
            sta $06bc          ; $9b18: 8d bc 06  
__9b1b:     jsr __9b38         ; $9b1b: 20 38 9b  
            sty $07            ; $9b1e: 84 07     
            lda #$00           ; $9b20: a9 00     
            ldy $074e          ; $9b22: ac 4e 07  
            dey                ; $9b25: 88        
            beq __9b2a         ; $9b26: f0 02     
            lda #$05           ; $9b28: a9 05     
__9b2a:     clc                ; $9b2a: 18        
            adc $07            ; $9b2b: 65 07     
            tay                ; $9b2d: a8        
__9b2e:     lda __bded,y       ; $9b2e: b9 ed bd  
            pha                ; $9b31: 48        
            jsr __9bbd         ; $9b32: 20 bd 9b  
            jmp __9a48         ; $9b35: 4c 48 9a  

;-------------------------------------------------------------------------------
__9b38:     lda $00            ; $9b38: a5 00     
            sec                ; $9b3a: 38        
            sbc #$00           ; $9b3b: e9 00     
            tay                ; $9b3d: a8        
__9b3e:     rts                ; $9b3e: 60        

;-------------------------------------------------------------------------------
__9b3f:     .hex 87 00         ; $9b3f: 87 00     Invalid Opcode - SAX $00
            brk                ; $9b41: 00        
            brk                ; $9b42: 00        
            jsr __9bae         ; $9b43: 20 ae 9b  
            bcc __9b75         ; $9b46: 90 2d     
            lda $074e          ; $9b48: ad 4e 07  
            bne __9b75         ; $9b4b: d0 28     
            ldx $046a          ; $9b4d: ae 6a 04  
            jsr __9bcd         ; $9b50: 20 cd 9b  
            sec                ; $9b53: 38        
            sbc #$10           ; $9b54: e9 10     
            sta $0471,x        ; $9b56: 9d 71 04  
            lda $0725          ; $9b59: ad 25 07  
            sbc #$00           ; $9b5c: e9 00     
            sta $046b,x        ; $9b5e: 9d 6b 04  
            iny                ; $9b61: c8        
            iny                ; $9b62: c8        
            tya                ; $9b63: 98        
            asl                ; $9b64: 0a        
            asl                ; $9b65: 0a        
            asl                ; $9b66: 0a        
            asl                ; $9b67: 0a        
            sta $0477,x        ; $9b68: 9d 77 04  
            inx                ; $9b6b: e8        
            cpx #$05           ; $9b6c: e0 05     
            bcc __9b72         ; $9b6e: 90 02     
            ldx #$00           ; $9b70: a2 00     
__9b72:     stx $046a          ; $9b72: 8e 6a 04  
__9b75:     ldx $074e          ; $9b75: ae 4e 07  
            lda __9b3f,x       ; $9b78: bd 3f 9b  
            ldx #$08           ; $9b7b: a2 08     
            ldy #$0f           ; $9b7d: a0 0f     
__9b7f:     sty $0735          ; $9b7f: 8c 35 07  
            ldy $06a1,x        ; $9b82: bc a1 06  
            .hex f0            ; $9b85: f0        Suspected data
__9b86:     clc                ; $9b86: 18        
            cpy #$17           ; $9b87: c0 17     
            beq __9ba2         ; $9b89: f0 17     
            cpy #$1a           ; $9b8b: c0 1a     
            .hex f0            ; $9b8d: f0        Suspected data
__9b8e:     .hex 13 c0         ; $9b8e: 13 c0     Invalid Opcode - SLO ($c0),y
            cpy #$f0           ; $9b90: c0 f0     
            .hex 0c c0 c0      ; $9b92: 0c c0 c0  Invalid Opcode - NOP __c0c0
            bcs __9ba2         ; $9b95: b0 0b     
            cpy #$54           ; $9b97: c0 54     
            .hex d0            ; $9b99: d0        Suspected data
__9b9a:     .hex 04 c9         ; $9b9a: 04 c9     Invalid Opcode - NOP $c9
            bvc __9b8e         ; $9b9c: 50 f0     
            .hex 03            ; $9b9e: 03        Suspected data
__9b9f:     sta $06a1,x        ; $9b9f: 9d a1 06  
__9ba2:     inx                ; $9ba2: e8        
            cpx #$0d           ; $9ba3: e0 0d     
            bcs __9bad         ; $9ba5: b0 06     
            ldy $0735          ; $9ba7: ac 35 07  
            dey                ; $9baa: 88        
            bpl __9b7f         ; $9bab: 10 d2     
__9bad:     rts                ; $9bad: 60        

;-------------------------------------------------------------------------------
__9bae:     jsr __9bbd         ; $9bae: 20 bd 9b  
__9bb1:     lda $0730,x        ; $9bb1: bd 30 07  
            clc                ; $9bb4: 18        
            bpl __9bbc         ; $9bb5: 10 05     
            tya                ; $9bb7: 98        
            sta $0730,x        ; $9bb8: 9d 30 07  
            sec                ; $9bbb: 38        
__9bbc:     rts                ; $9bbc: 60        

;-------------------------------------------------------------------------------
__9bbd:     ldy $072d,x        ; $9bbd: bc 2d 07  
            lda ($e7),y        ; $9bc0: b1 e7     
            and #$0f           ; $9bc2: 29 0f     
            sta $07            ; $9bc4: 85 07     
            iny                ; $9bc6: c8        
            lda ($e7),y        ; $9bc7: b1 e7     
            and #$0f           ; $9bc9: 29 0f     
            tay                ; $9bcb: a8        
            rts                ; $9bcc: 60        

;-------------------------------------------------------------------------------
__9bcd:     lda $0726          ; $9bcd: ad 26 07  
            asl                ; $9bd0: 0a        
            asl                ; $9bd1: 0a        
            asl                ; $9bd2: 0a        
            asl                ; $9bd3: 0a        
            rts                ; $9bd4: 60        

;-------------------------------------------------------------------------------
__9bd5:     lda $07            ; $9bd5: a5 07     
            asl                ; $9bd7: 0a        
            asl                ; $9bd8: 0a        
            asl                ; $9bd9: 0a        
            asl                ; $9bda: 0a        
            clc                ; $9bdb: 18        
            adc #$20           ; $9bdc: 69 20     
            rts                ; $9bde: 60        

;-------------------------------------------------------------------------------
__9bdf:     brk                ; $9bdf: 00        
            .hex d0            ; $9be0: d0        Suspected data
__9be1:     ora $05            ; $9be1: 05 05     
__9be3:     pha                ; $9be3: 48        
            lsr                ; $9be4: 4a        
            lsr                ; $9be5: 4a        
            lsr                ; $9be6: 4a        
            lsr                ; $9be7: 4a        
            tay                ; $9be8: a8        
            lda __9be1,y       ; $9be9: b9 e1 9b  
            sta $07            ; $9bec: 85 07     
            pla                ; $9bee: 68        
            and #$0f           ; $9bef: 29 0f     
            clc                ; $9bf1: 18        
            adc __9bdf,y       ; $9bf2: 79 df 9b  
            sta $06            ; $9bf5: 85 06     
            rts                ; $9bf7: 60        

;-------------------------------------------------------------------------------
__9bf8:     .hex 12            ; $9bf8: 12        Invalid Opcode - KIL 
            rol $0e,x          ; $9bf9: 36 0e     
            asl $320e          ; $9bfb: 0e 0e 32  
            .hex 32            ; $9bfe: 32        Invalid Opcode - KIL 
__9bff:     .hex 32            ; $9bff: 32        Invalid Opcode - KIL 
__9c00:     asl                ; $9c00: 0a        
            rol $40            ; $9c01: 26 40     
__9c03:     jsr __9c13         ; $9c03: 20 13 9c  
            sta $0750          ; $9c06: 8d 50 07  
__9c09:     and #$60           ; $9c09: 29 60     
            asl                ; $9c0b: 0a        
            rol                ; $9c0c: 2a        
            rol                ; $9c0d: 2a        
            rol                ; $9c0e: 2a        
            sta $074e          ; $9c0f: 8d 4e 07  
            rts                ; $9c12: 60        

;-------------------------------------------------------------------------------
__9c13:     ldy $075f          ; $9c13: ac 5f 07  
            lda __9cb4,y       ; $9c16: b9 b4 9c  
            clc                ; $9c19: 18        
            adc $0760          ; $9c1a: 6d 60 07  
            tay                ; $9c1d: a8        
            lda __9cbc,y       ; $9c1e: b9 bc 9c  
            rts                ; $9c21: 60        

;-------------------------------------------------------------------------------
__9c22:     lda $0750          ; $9c22: ad 50 07  
            jsr __9c09         ; $9c25: 20 09 9c  
            tay                ; $9c28: a8        
            lda $0750          ; $9c29: ad 50 07  
            and #$1f           ; $9c2c: 29 1f     
            sta $074f          ; $9c2e: 8d 4f 07  
            lda __9ce0,y       ; $9c31: b9 e0 9c  
            clc                ; $9c34: 18        
            adc $074f          ; $9c35: 6d 4f 07  
            tay                ; $9c38: a8        
            lda __9ce4,y       ; $9c39: b9 e4 9c  
            sta $e9            ; $9c3c: 85 e9     
            lda __9d06,y       ; $9c3e: b9 06 9d  
            sta $ea            ; $9c41: 85 ea     
            ldy $074e          ; $9c43: ac 4e 07  
            lda __9d28,y       ; $9c46: b9 28 9d  
            clc                ; $9c49: 18        
            adc $074f          ; $9c4a: 6d 4f 07  
            tay                ; $9c4d: a8        
            lda __9d2c,y       ; $9c4e: b9 2c 9d  
            sta $e7            ; $9c51: 85 e7     
            lda __9d4e,y       ; $9c53: b9 4e 9d  
            sta $e8            ; $9c56: 85 e8     
            ldy #$00           ; $9c58: a0 00     
            lda ($e7),y        ; $9c5a: b1 e7     
            pha                ; $9c5c: 48        
            and #$07           ; $9c5d: 29 07     
            cmp #$04           ; $9c5f: c9 04     
            bcc __9c68         ; $9c61: 90 05     
            sta $0744          ; $9c63: 8d 44 07  
            lda #$00           ; $9c66: a9 00     
__9c68:     sta $0741          ; $9c68: 8d 41 07  
            pla                ; $9c6b: 68        
            pha                ; $9c6c: 48        
            and #$38           ; $9c6d: 29 38     
            lsr                ; $9c6f: 4a        
            lsr                ; $9c70: 4a        
            lsr                ; $9c71: 4a        
            sta $0710          ; $9c72: 8d 10 07  
            pla                ; $9c75: 68        
            and #$c0           ; $9c76: 29 c0     
            clc                ; $9c78: 18        
            rol                ; $9c79: 2a        
            rol                ; $9c7a: 2a        
            rol                ; $9c7b: 2a        
            .hex 8d            ; $9c7c: 8d        Suspected data
__9c7d:     ora $07,x          ; $9c7d: 15 07     
            iny                ; $9c7f: c8        
            lda ($e7),y        ; $9c80: b1 e7     
            pha                ; $9c82: 48        
            .hex 29            ; $9c83: 29        Suspected data
__9c84:     .hex 0f 8d 27      ; $9c84: 0f 8d 27  Invalid Opcode - SLO $278d
            .hex 07 68         ; $9c87: 07 68     Invalid Opcode - SLO $68
            pha                ; $9c89: 48        
            and #$30           ; $9c8a: 29 30     
            lsr                ; $9c8c: 4a        
            lsr                ; $9c8d: 4a        
            lsr                ; $9c8e: 4a        
            lsr                ; $9c8f: 4a        
            sta $0742          ; $9c90: 8d 42 07  
            pla                ; $9c93: 68        
__9c94:     and #$c0           ; $9c94: 29 c0     
            clc                ; $9c96: 18        
            rol                ; $9c97: 2a        
            rol                ; $9c98: 2a        
            rol                ; $9c99: 2a        
            cmp #$03           ; $9c9a: c9 03     
            bne __9ca3         ; $9c9c: d0 05     
            sta $0743          ; $9c9e: 8d 43 07  
            lda #$00           ; $9ca1: a9 00     
__9ca3:     sta $0733          ; $9ca3: 8d 33 07  
            lda $e7            ; $9ca6: a5 e7     
            clc                ; $9ca8: 18        
            adc #$02           ; $9ca9: 69 02     
            sta $e7            ; $9cab: 85 e7     
            lda $e8            ; $9cad: a5 e8     
            adc #$00           ; $9caf: 69 00     
            sta $e8            ; $9cb1: 85 e8     
            rts                ; $9cb3: 60        

;-------------------------------------------------------------------------------
__9cb4:     brk                ; $9cb4: 00        
            ora $0a            ; $9cb5: 05 0a     
            asl $1713          ; $9cb7: 0e 13 17  
            .hex 1b 20         ; $9cba: 1b 20     Suspected data
__9cbc:     and $29            ; $9cbc: 25 29     
            cpy #$26           ; $9cbe: c0 26     
            rts                ; $9cc0: 60        

;-------------------------------------------------------------------------------
            plp                ; $9cc1: 28        
            and #$01           ; $9cc2: 29 01     
            .hex 27 62         ; $9cc4: 27 62     Invalid Opcode - RLA $62
            .hex 24            ; $9cc6: 24        Suspected data
__9cc7:     and $20,x          ; $9cc7: 35 20     
            .hex 63 22         ; $9cc9: 63 22     Invalid Opcode - RRA ($22,x)
            and #$41           ; $9ccb: 29 41     
            bit $2a61          ; $9ccd: 2c 61 2a  
            and ($26),y        ; $9cd0: 31 26     
            .hex 62            ; $9cd2: 62        Invalid Opcode - KIL 
            rol $2d23          ; $9cd3: 2e 23 2d  
            rts                ; $9cd6: 60        

;-------------------------------------------------------------------------------
            .hex 33 29         ; $9cd7: 33 29     Invalid Opcode - RLA ($29),y
            ora ($27,x)        ; $9cd9: 01 27     
            .hex 64 30         ; $9cdb: 64 30     Invalid Opcode - NOP $30
            .hex 32            ; $9cdd: 32        Invalid Opcode - KIL 
            and ($65,x)        ; $9cde: 21 65     
__9ce0:     .hex 1f 06 1c      ; $9ce0: 1f 06 1c  Invalid Opcode - SLO $1c06,x
            brk                ; $9ce3: 00        
__9ce4:     bvs __9c7d         ; $9ce4: 70 97     
            bcs __9cc7         ; $9ce6: b0 df     
            asl                ; $9ce8: 0a        
            .hex 1f 59 7e      ; $9ce9: 1f 59 7e  Invalid Opcode - SLO $7e59,x
            .hex 9b            ; $9cec: 9b        Invalid Opcode - TAS 
            lda #$d0           ; $9ced: a9 d0     
            ora ($1f,x)        ; $9cef: 01 1f     
            .hex 3c 51 7b      ; $9cf1: 3c 51 7b  Invalid Opcode - NOP $7b51,x
            .hex 7c a0 a9      ; $9cf4: 7c a0 a9  Invalid Opcode - NOP __a9a0,x
            dec __faf1         ; $9cf7: ce f1 fa  
            .hex fb 35 60      ; $9cfa: fb 35 60  Invalid Opcode - ISC $6035,y
            stx __b3aa         ; $9cfd: 8e aa b3  
            cld                ; $9d00: d8        
            ora $33            ; $9d01: 05 33     
            rts                ; $9d03: 60        

;-------------------------------------------------------------------------------
            adc ($9b),y        ; $9d04: 71 9b     
__9d06:     sta __9d9d,x       ; $9d06: 9d 9d 9d  
            sta __9e9e,x       ; $9d09: 9d 9e 9e  
            .hex 9e 9e 9e      ; $9d0c: 9e 9e 9e  Invalid Opcode - SHX __9e9e,y
            .hex 9e 9e 9f      ; $9d0f: 9e 9e 9f  Invalid Opcode - SHX __9f9e,y
            .hex 9f 9f 9f      ; $9d12: 9f 9f 9f  Invalid Opcode - AHX __9f9f,y
            .hex 9f 9f 9f      ; $9d15: 9f 9f 9f  Invalid Opcode - AHX __9f9f,y
            .hex 9f 9f 9f      ; $9d18: 9f 9f 9f  Invalid Opcode - AHX __9f9f,y
            .hex 9f 9f a0      ; $9d1b: 9f 9f a0  Invalid Opcode - AHX __a09f,y
            ldy #$a0           ; $9d1e: a0 a0     
            ldy #$a0           ; $9d20: a0 a0     
            ldy #$a1           ; $9d22: a0 a1     
            lda ($a1,x)        ; $9d24: a1 a1     
            lda ($a1,x)        ; $9d26: a1 a1     
__9d28:     brk                ; $9d28: 00        
            .hex 03 19         ; $9d29: 03 19     Invalid Opcode - SLO ($19,x)
            .hex 1c            ; $9d2b: 1c        Suspected data
__9d2c:     asl $45            ; $9d2c: 06 45     
            cpy #$6b           ; $9d2e: c0 6b     
            dec __8a37         ; $9d30: ce 37 8a  
            ora __f38e,y       ; $9d33: 19 8e f3  
            pha                ; $9d36: 48        
            cmp $3b32          ; $9d37: cd 32 3b  
            .hex 7a            ; $9d3a: 7a        Invalid Opcode - NOP 
            .hex 8f f6 5b      ; $9d3b: 8f f6 5b  Invalid Opcode - SAX $5bf6
            dec __92ff         ; $9d3e: ce ff 92  
            ora $7e            ; $9d41: 05 7e     
            .hex d7 02         ; $9d43: d7 02     Invalid Opcode - DCP $02,x
            and $d8,x          ; $9d45: 35 d8     
            adc $10af,y        ; $9d47: 79 af 10  
            .hex 8f            ; $9d4a: 8f        Suspected data
__9d4b:     .hex 02            ; $9d4b: 02        Invalid Opcode - KIL 
            .hex 6f fa         ; $9d4c: 6f fa     Suspected data
__9d4e:     ldx __aeae         ; $9d4e: ae ae ae  
            ldy $a4            ; $9d51: a4 a4     
            lda $a5            ; $9d53: a5 a5     
            ldx $a6            ; $9d55: a6 a6     
            ldx $a7            ; $9d57: a6 a7     
            .hex a7 a8         ; $9d59: a7 a8     Invalid Opcode - LAX $a8
            tay                ; $9d5b: a8        
            tay                ; $9d5c: a8        
            tay                ; $9d5d: a8        
            tay                ; $9d5e: a8        
            lda #$a9           ; $9d5f: a9 a9     
            lda #$aa           ; $9d61: a9 aa     
            .hex ab ab         ; $9d63: ab ab     Invalid Opcode - LAX #$ab
            .hex ab ac         ; $9d65: ab ac     Invalid Opcode - LAX #$ac
            ldy __adac         ; $9d67: ac ac ad  
            lda ($a2,x)        ; $9d6a: a1 a2     
            ldx #$a3           ; $9d6c: a2 a3     
            .hex a3 a3         ; $9d6e: a3 a3     Invalid Opcode - LAX ($a3,x)
            ror $dd,x          ; $9d70: 76 dd     
            .hex bb 4c ea      ; $9d72: bb 4c ea  Invalid Opcode - LAS __ea4c,y
            ora __cc1b,x       ; $9d75: 1d 1b cc  
            lsr $5d,x          ; $9d78: 56 5d     
            asl $9d,x          ; $9d7a: 16 9d     
            dec $1d            ; $9d7c: c6 1d     
            rol $9d,x          ; $9d7e: 36 9d     
            cmp #$1d           ; $9d80: c9 1d     
            .hex 04 db         ; $9d82: 04 db     Invalid Opcode - NOP $db
            eor #$1d           ; $9d84: 49 1d     
            sty $1b            ; $9d86: 84 1b     
            cmp #$5d           ; $9d88: c9 5d     
            dey                ; $9d8a: 88        
            sta $0f,x          ; $9d8b: 95 0f     
            php                ; $9d8d: 08        
            bmi __9ddc         ; $9d8e: 30 4c     
            sei                ; $9d90: 78        
            .hex 2d a6         ; $9d91: 2d a6     Suspected data
__9d93:     plp                ; $9d93: 28        
            bcc __9d4b         ; $9d94: 90 b5     
            .hex ff 0f 03      ; $9d96: ff 0f 03  Invalid Opcode - ISC $030f,x
            lsr $1b,x          ; $9d99: 56 1b     
            cmp #$1b           ; $9d9b: c9 1b     
__9d9d:     .hex 0f 07 36      ; $9d9d: 0f 07 36  Invalid Opcode - SLO $3607
            .hex 1b aa 1b      ; $9da0: 1b aa 1b  Invalid Opcode - SLO $1baa,y
            pha                ; $9da3: 48        
            sta $0f,x          ; $9da4: 95 0f     
            asl                ; $9da6: 0a        
            rol                ; $9da7: 2a        
            .hex 1b 5b 0c      ; $9da8: 1b 5b 0c  Invalid Opcode - SLO $0c5b,y
            sei                ; $9dab: 78        
            and __b590         ; $9dac: 2d 90 b5  
            .hex ff 0b 8c      ; $9daf: ff 0b 8c  Invalid Opcode - ISC __8c0b,x
            .hex 4b 4c         ; $9db2: 4b 4c     Invalid Opcode - ALR #$4c
            .hex 77 5f         ; $9db4: 77 5f     Invalid Opcode - RRA $5f,x
            .hex eb 0c         ; $9db6: eb 0c     Invalid Opcode - SBC #$0c
            lda $19db,x        ; $9db8: bd db 19  
            sta $1d75,x        ; $9dbb: 9d 75 1d  
__9dbe:     adc __d95b,x       ; $9dbe: 7d 5b d9  
            ora __dd3d,x       ; $9dc1: 1d 3d dd  
            sta $261d,y        ; $9dc4: 99 1d 26  
            sta $2b5a,x        ; $9dc7: 9d 5a 2b  
            txa                ; $9dca: 8a        
            bit $1bca          ; $9dcb: 2c ca 1b  
            jsr $7b95          ; $9dce: 20 95 7b  
            .hex 5c db         ; $9dd1: 5c db     Suspected data
__9dd3:     jmp __cc1b         ; $9dd3: 4c 1b cc  

;-------------------------------------------------------------------------------
            .hex 3b cc 78      ; $9dd6: 3b cc 78  Invalid Opcode - RLA $78cc,y
            and $28a6          ; $9dd9: 2d a6 28  
__9ddc:     bcc __9d93         ; $9ddc: 90 b5     
            .hex ff 0b 8c      ; $9dde: ff 0b 8c  Invalid Opcode - ISC __8c0b,x
            .hex 3b 1d 8b      ; $9de1: 3b 1d 8b  Invalid Opcode - RLA __8b1d,y
            ora $0cab,x        ; $9de4: 1d ab 0c  
            .hex db 1d 0f      ; $9de7: db 1d 0f  Invalid Opcode - DCP $0f1d,y
            .hex 03 65         ; $9dea: 03 65     Invalid Opcode - SLO ($65,x)
            ora $1b6b,x        ; $9dec: 1d 6b 1b  
            ora $9d            ; $9def: 05 9d     
            .hex 0b 1b         ; $9df1: 0b 1b     Invalid Opcode - ANC #$1b
            ora $9b            ; $9df3: 05 9b     
            .hex 0b 1d         ; $9df5: 0b 1d     Invalid Opcode - ANC #$1d
            .hex 8b 0c         ; $9df7: 8b 0c     Invalid Opcode - XAA #$0c
            .hex 1b 8c 70      ; $9df9: 1b 8c 70  Invalid Opcode - SLO $708c,y
            ora $7b,x          ; $9dfc: 15 7b     
            .hex 0c db 0c      ; $9dfe: 0c db 0c  Invalid Opcode - NOP $0cdb
            .hex 0f            ; $9e01: 0f        Suspected data
__9e02:     php                ; $9e02: 08        
            sei                ; $9e03: 78        
            .hex 2d a6         ; $9e04: 2d a6     Suspected data
__9e06:     plp                ; $9e06: 28        
            bcc __9dbe         ; $9e07: 90 b5     
            .hex ff 27 a9      ; $9e09: ff 27 a9  Invalid Opcode - ISC __a927,x
            .hex 4b 0c         ; $9e0c: 4b 0c     Invalid Opcode - ALR #$0c
            pla                ; $9e0e: 68        
            and #$0f           ; $9e0f: 29 0f     
            asl $77            ; $9e11: 06 77     
            .hex 1b 0f 0b      ; $9e13: 1b 0f 0b  Invalid Opcode - SLO $0b0f,y
            rts                ; $9e16: 60        

;-------------------------------------------------------------------------------
            ora $4b,x          ; $9e17: 15 4b     
            sty $2d78          ; $9e19: 8c 78 2d  
            bcc __9dd3         ; $9e1c: 90 b5     
            .hex ff 0f 03      ; $9e1e: ff 0f 03  Invalid Opcode - ISC $030f,x
            stx __e165         ; $9e21: 8e 65 e1  
            .hex bb 38 6d      ; $9e24: bb 38 6d  Invalid Opcode - LAS $6d38,y
__9e27:     tay                ; $9e27: a8        
            rol __e7e5,x       ; $9e28: 3e e5 e7  
            .hex 0f 08 0b      ; $9e2b: 0f 08 0b  Invalid Opcode - SLO $0b08
            .hex 02            ; $9e2e: 02        Invalid Opcode - KIL 
            .hex 2b 02         ; $9e2f: 2b 02     Invalid Opcode - ANC #$02
            lsr __e165,x       ; $9e31: 5e 65 e1  
            .hex bb 0e db      ; $9e34: bb 0e db  Invalid Opcode - LAS __db0e,y
            asl __8ebb         ; $9e37: 0e bb 8e  
            .hex db 0e fe      ; $9e3a: db 0e fe  Invalid Opcode - DCP __fe0e,y
            adc $ec            ; $9e3d: 65 ec     
            .hex 0f 0d 4e      ; $9e3f: 0f 0d 4e  Invalid Opcode - SLO $4e0d
            adc $e1            ; $9e42: 65 e1     
            .hex 0f 0e 4e      ; $9e44: 0f 0e 4e  Invalid Opcode - SLO $4e0e
__9e47:     .hex 02            ; $9e47: 02        Invalid Opcode - KIL 
            cpx #$0f           ; $9e48: e0 0f     
__9e4a:     bpl __9e4a         ; $9e4a: 10 fe     
            sbc $e1            ; $9e4c: e5 e1     
            .hex 1b 85 7b      ; $9e4e: 1b 85 7b  Invalid Opcode - SLO $7b85,y
            .hex 0c 5b 95      ; $9e51: 0c 5b 95  Invalid Opcode - NOP __955b
            sei                ; $9e54: 78        
            and __b590         ; $9e55: 2d 90 b5  
            .hex ff a5 86      ; $9e58: ff a5 86  Invalid Opcode - ISC __86a5,x
            cpx $28            ; $9e5b: e4 28     
            clc                ; $9e5d: 18        
            tay                ; $9e5e: a8        
            eor $83            ; $9e5f: 45 83     
            adc #$03           ; $9e61: 69 03     
            dec $29            ; $9e63: c6 29     
            .hex 9b            ; $9e65: 9b        Invalid Opcode - TAS 
            .hex 83 16         ; $9e66: 83 16     Invalid Opcode - SAX ($16,x)
            ldy $88            ; $9e68: a4 88     
            bit $e9            ; $9e6a: 24 e9     
            plp                ; $9e6c: 28        
            ora $a8            ; $9e6d: 05 a8     
            .hex 7b 28 24      ; $9e6f: 7b 28 24  Invalid Opcode - RRA $2428,y
            .hex 8f c8 03      ; $9e72: 8f c8 03  Invalid Opcode - SAX $03c8
            inx                ; $9e75: e8        
            .hex 03 46         ; $9e76: 03 46     Invalid Opcode - SLO ($46,x)
            tay                ; $9e78: a8        
            sta $24            ; $9e79: 85 24     
            iny                ; $9e7b: c8        
            bit $ff            ; $9e7c: 24 ff     
            .hex eb 8e         ; $9e7e: eb 8e     Invalid Opcode - SBC #$8e
            .hex 0f 03 fb      ; $9e80: 0f 03 fb  Invalid Opcode - SLO __fb03
            ora $17            ; $9e83: 05 17     
            sta $db            ; $9e85: 85 db     
            stx $070f          ; $9e87: 8e 0f 07  
            .hex 57 05         ; $9e8a: 57 05     Invalid Opcode - SRE $05,x
            .hex 7b 05 9b      ; $9e8c: 7b 05 9b  Invalid Opcode - RRA __9b05,y
            .hex 80 2b         ; $9e8f: 80 2b     Invalid Opcode - NOP #$2b
            sta $fb            ; $9e91: 85 fb     
            ora $0f            ; $9e93: 05 0f     
            .hex 0b 1b         ; $9e95: 0b 1b     Invalid Opcode - ANC #$1b
            .hex 05            ; $9e97: 05        Suspected data
__9e98:     .hex 9b            ; $9e98: 9b        Invalid Opcode - TAS 
            ora $ff            ; $9e99: 05 ff     
            rol $66c2          ; $9e9b: 2e c2 66  
__9e9e:     .hex e2 11         ; $9e9e: e2 11     Invalid Opcode - NOP #$11
            .hex 0f 07 02      ; $9ea0: 0f 07 02  Invalid Opcode - SLO $0207
            ora ($0f),y        ; $9ea3: 11 0f     
            .hex 0c 12 11      ; $9ea5: 0c 12 11  Invalid Opcode - NOP $1112
            .hex ff 0e c2      ; $9ea8: ff 0e c2  Invalid Opcode - ISC __c20e,x
            tay                ; $9eab: a8        
            .hex ab 00         ; $9eac: ab 00     Invalid Opcode - LAX #$00
            .hex bb 8e 6b      ; $9eae: bb 8e 6b  Invalid Opcode - LAS $6b8e,y
            .hex 82 de         ; $9eb1: 82 de     Invalid Opcode - NOP #$de
            brk                ; $9eb3: 00        
            ldy #$33           ; $9eb4: a0 33     
            stx $43            ; $9eb6: 86 43     
            asl $3e            ; $9eb8: 06 3e     
            ldy $a0,x          ; $9eba: b4 a0     
            .hex cb 02         ; $9ebc: cb 02     Invalid Opcode - AXS #$02
            .hex 0f 07 7e      ; $9ebe: 0f 07 7e  Invalid Opcode - SLO $7e07
            .hex 42            ; $9ec1: 42        Invalid Opcode - KIL 
            ldx $83            ; $9ec2: a6 83     
            .hex 02            ; $9ec4: 02        Invalid Opcode - KIL 
            .hex 0f 0a 3b      ; $9ec5: 0f 0a 3b  Invalid Opcode - SLO $3b0a
            .hex 02            ; $9ec8: 02        Invalid Opcode - KIL 
            .hex cb 37         ; $9ec9: cb 37     Invalid Opcode - AXS #$37
            .hex 0f 0c e3      ; $9ecb: 0f 0c e3  Invalid Opcode - SLO __e30c
            asl __9bff         ; $9ece: 0e ff 9b  
            stx $0eca          ; $9ed1: 8e ca 0e  
            inc $4442          ; $9ed4: ee 42 44  
            .hex 5b 86 80      ; $9ed7: 5b 86 80  Invalid Opcode - SRE __8086,y
            clv                ; $9eda: b8        
            .hex 1b 80 50      ; $9edb: 1b 80 50  Invalid Opcode - SLO $5080,y
            tsx                ; $9ede: ba        
            bpl __9e98         ; $9edf: 10 b7     
            .hex 5b 00 17      ; $9ee1: 5b 00 17  Invalid Opcode - SRE $1700,y
            sta $4b            ; $9ee4: 85 4b     
            ora $fe            ; $9ee6: 05 fe     
            .hex 34 40         ; $9ee8: 34 40     Invalid Opcode - NOP $40,x
            .hex b7 86         ; $9eea: b7 86     Invalid Opcode - LAX $86,y
            dec $06            ; $9eec: c6 06     
            .hex 5b 80 83      ; $9eee: 5b 80 83  Invalid Opcode - SRE __8380,y
            brk                ; $9ef1: 00        
            bne __9f2c         ; $9ef2: d0 38     
            .hex 5b 8e 8a      ; $9ef4: 5b 8e 8a  Invalid Opcode - SRE __8a8e,y
            .hex 0e a6 00      ; $9ef7: 0e a6 00  Bad Addr Mode - ASL $00a6
            .hex bb 0e c5      ; $9efa: bb 0e c5  Invalid Opcode - LAS __c50e,y
            .hex 80 f3         ; $9efd: 80 f3     Invalid Opcode - NOP #$f3
            brk                ; $9eff: 00        
            .hex ff 1e c2      ; $9f00: ff 1e c2  Invalid Opcode - ISC __c21e,x
            brk                ; $9f03: 00        
            .hex 6b 06         ; $9f04: 6b 06     Invalid Opcode - ARR #$06
            .hex 8b 86         ; $9f06: 8b 86     Invalid Opcode - XAA #$86
            .hex 63 b7         ; $9f08: 63 b7     Invalid Opcode - RRA ($b7,x)
            .hex 0f 05 03      ; $9f0a: 0f 05 03  Invalid Opcode - SLO $0305
            asl $23            ; $9f0d: 06 23     
            asl $4b            ; $9f0f: 06 4b     
            .hex b7 bb         ; $9f11: b7 bb     Invalid Opcode - LAX $bb,y
            brk                ; $9f13: 00        
            .hex 5b b7 fb      ; $9f14: 5b b7 fb  Invalid Opcode - SRE __fbb7,y
            .hex 37 3b         ; $9f17: 37 3b     Invalid Opcode - RLA $3b,x
            .hex b7 0f         ; $9f19: b7 0f     Invalid Opcode - LAX $0f,y
            .hex 0b 1b         ; $9f1b: 0b 1b     Invalid Opcode - ANC #$1b
            .hex 37 ff         ; $9f1d: 37 ff     Invalid Opcode - RLA $ff,x
            .hex 2b d7         ; $9f1f: 2b d7     Invalid Opcode - ANC #$d7
            .hex e3 03         ; $9f21: e3 03     Invalid Opcode - ISC ($03,x)
            .hex c2 86         ; $9f23: c2 86     Invalid Opcode - NOP #$86
            .hex e2 06         ; $9f25: e2 06     Invalid Opcode - NOP #$06
            ror $a5,x          ; $9f27: 76 a5     
            .hex a3 8f         ; $9f29: a3 8f     Invalid Opcode - LAX ($8f,x)
            .hex 03            ; $9f2b: 03        Suspected data
__9f2c:     stx $2b            ; $9f2c: 86 2b     
            .hex 57 68         ; $9f2e: 57 68     Invalid Opcode - SRE $68,x
            plp                ; $9f30: 28        
            sbc #$28           ; $9f31: e9 28     
            sbc $83            ; $9f33: e5 83     
            bit $8f            ; $9f35: 24 8f     
            rol $a8,x          ; $9f37: 36 a8     
            .hex 5b            ; $9f39: 5b        Suspected data
__9f3a:     .hex 03 ff         ; $9f3a: 03 ff     Invalid Opcode - SLO ($ff,x)
            .hex 0f 02 78      ; $9f3c: 0f 02 78  Invalid Opcode - SLO $7802
            rti                ; $9f3f: 40        

;-------------------------------------------------------------------------------
            pha                ; $9f40: 48        
            dec __c3f8         ; $9f41: ce f8 c3  
            sed                ; $9f44: f8        
            .hex c3 0f         ; $9f45: c3 0f     Invalid Opcode - DCP ($0f,x)
            .hex 07 7b         ; $9f47: 07 7b     Invalid Opcode - SLO $7b
            .hex 43 c6         ; $9f49: 43 c6     Invalid Opcode - SRE ($c6,x)
            bne __9f5c         ; $9f4b: d0 0f     
            txa                ; $9f4d: 8a        
            iny                ; $9f4e: c8        
            .hex 50            ; $9f4f: 50        Suspected data
__9f50:     .hex ff            ; $9f50: ff        Suspected data
__9f51:     sta $86            ; $9f51: 85 86     
            .hex 0b 80         ; $9f53: 0b 80     Invalid Opcode - ANC #$80
            .hex 1b 00 db      ; $9f55: 1b 00 db  Invalid Opcode - SLO __db00,y
            .hex 37 77         ; $9f58: 37 77     Invalid Opcode - RLA $77,x
            .hex 80 eb         ; $9f5a: 80 eb     Invalid Opcode - NOP #$eb
__9f5c:     .hex 37 fe         ; $9f5c: 37 fe     Invalid Opcode - RLA $fe,x
            .hex 2b 20         ; $9f5e: 2b 20     Invalid Opcode - ANC #$20
            .hex 2b 80         ; $9f60: 2b 80     Invalid Opcode - ANC #$80
            .hex 7b 38 ab      ; $9f62: 7b 38 ab  Invalid Opcode - RRA __ab38,y
            clv                ; $9f65: b8        
            .hex 77 86         ; $9f66: 77 86     Invalid Opcode - RRA $86,x
            inc $2042,x        ; $9f68: fe 42 20  
            eor #$86           ; $9f6b: 49 86     
            .hex 8b 06         ; $9f6d: 8b 06     Invalid Opcode - XAA #$06
            .hex 9b            ; $9f6f: 9b        Invalid Opcode - TAS 
            .hex 80 7b         ; $9f70: 80 7b     Invalid Opcode - NOP #$7b
            stx __b75b         ; $9f72: 8e 5b b7  
            .hex 9b            ; $9f75: 9b        Invalid Opcode - TAS 
            asl $0ebb          ; $9f76: 0e bb 0e  
            .hex 9b            ; $9f79: 9b        Invalid Opcode - TAS 
            .hex 80 ff         ; $9f7a: 80 ff     Invalid Opcode - NOP #$ff
            .hex 0b 80         ; $9f7c: 0b 80     Invalid Opcode - ANC #$80
            rts                ; $9f7e: 60        

;-------------------------------------------------------------------------------
            sec                ; $9f7f: 38        
            bpl __9f3a         ; $9f80: 10 b8     
__9f82:     cpy #$3b           ; $9f82: c0 3b     
            .hex db 8e 40      ; $9f84: db 8e 40  Invalid Opcode - DCP $408e,y
            clv                ; $9f87: b8        
            beq __9fc2         ; $9f88: f0 38     
            .hex 7b 8e a0      ; $9f8a: 7b 8e a0  Invalid Opcode - RRA __a08e,y
            clv                ; $9f8d: b8        
            cpy #$b8           ; $9f8e: c0 b8     
            .hex fb 00 a0      ; $9f90: fb 00 a0  Invalid Opcode - ISC __a000,y
            clv                ; $9f93: b8        
            bmi __9f51         ; $9f94: 30 bb     
            inc __8842         ; $9f96: ee 42 88  
            .hex 0f 0b 2b      ; $9f99: 0f 0b 2b  Invalid Opcode - SLO $2b0b
            asl $0e67          ; $9f9c: 0e 67 0e  
            .hex ff 0a aa      ; $9f9f: ff 0a aa  Invalid Opcode - ISC __aa0a,x
            asl $2a28          ; $9fa2: 0e 28 2a  
            asl __8831         ; $9fa5: 0e 31 88  
            .hex ff c7 83      ; $9fa8: ff c7 83  Invalid Opcode - ISC __83c7,x
            .hex d7 03         ; $9fab: d7 03     Invalid Opcode - DCP $03,x
            .hex 42            ; $9fad: 42        Invalid Opcode - KIL 
            .hex 8f 7a 03      ; $9fae: 8f 7a 03  Invalid Opcode - SAX $037a
            ora $a4            ; $9fb1: 05 a4     
            sei                ; $9fb3: 78        
            bit $a6            ; $9fb4: 24 a6     
            and $e4            ; $9fb6: 25 e4     
            and $4b            ; $9fb8: 25 4b     
            .hex 83 e3         ; $9fba: 83 e3     Invalid Opcode - SAX ($e3,x)
            .hex 03 05         ; $9fbc: 03 05     Invalid Opcode - SLO ($05,x)
            ldy $89            ; $9fbe: a4 89     
            bit $b5            ; $9fc0: 24 b5     
__9fc2:     bit $09            ; $9fc2: 24 09     
            ldy $65            ; $9fc4: a4 65     
            bit $c9            ; $9fc6: 24 c9     
            bit $0f            ; $9fc8: 24 0f     
            php                ; $9fca: 08        
            sta $25            ; $9fcb: 85 25     
            .hex ff cd a5      ; $9fcd: ff cd a5  Invalid Opcode - ISC __a5cd,x
            lda $a8,x          ; $9fd0: b5 a8     
            .hex 07 a8         ; $9fd2: 07 a8     Invalid Opcode - SLO $a8
            ror $28,x          ; $9fd4: 76 28     
            cpy $6525          ; $9fd6: cc 25 65  
            ldy $a9            ; $9fd9: a4 a9     
            bit $e5            ; $9fdb: 24 e5     
            bit $19            ; $9fdd: 24 19     
            ldy $0f            ; $9fdf: a4 0f     
            .hex 07 95         ; $9fe1: 07 95     Invalid Opcode - SLO $95
            plp                ; $9fe3: 28        
            inc $24            ; $9fe4: e6 24     
            ora __d7a4,y       ; $9fe6: 19 a4 d7  
            and #$16           ; $9fe9: 29 16     
            lda #$58           ; $9feb: a9 58     
            and #$97           ; $9fed: 29 97     
            and #$ff           ; $9fef: 29 ff     
__9ff1:     .hex 0f 02 02      ; $9ff1: 0f 02 02  Invalid Opcode - SLO $0202
            ora ($0f),y        ; $9ff4: 11 0f     
            .hex 07 02         ; $9ff6: 07 02     Invalid Opcode - SLO $02
            ora ($ff),y        ; $9ff8: 11 ff     
            .hex ff 2b 82      ; $9ffa: ff 2b 82  Invalid Opcode - ISC __822b,x
            .hex ab 38         ; $9ffd: ab 38     Invalid Opcode - LAX #$38
            dec __e242,x       ; $9fff: de 42 e2  
            .hex 1b b8 eb      ; $a002: 1b b8 eb  Invalid Opcode - SLO __ebb8,y
            .hex 3b db 80      ; $a005: 3b db 80  Invalid Opcode - RLA __80db,y
            .hex 8b b8         ; $a008: 8b b8     Invalid Opcode - XAA #$b8
            .hex 1b 82 fb      ; $a00a: 1b 82 fb  Invalid Opcode - SLO __fb82,y
            clv                ; $a00d: b8        
            .hex 7b 80 fb      ; $a00e: 7b 80 fb  Invalid Opcode - RRA __fb80,y
            .hex 3c 5b bc      ; $a011: 3c 5b bc  Invalid Opcode - NOP __bc5b,x
            .hex 7b b8 1b      ; $a014: 7b b8 1b  Invalid Opcode - RRA $1bb8,y
            stx $0ecb          ; $a017: 8e cb 0e  
            .hex 1b 8e 0f      ; $a01a: 1b 8e 0f  Invalid Opcode - SLO $0f8e,y
            .hex 0d 2b         ; $a01d: 0d 2b     Suspected data
__a01f:     .hex 3b bb b8      ; $a01f: 3b bb b8  Invalid Opcode - RLA __b8bb,y
            .hex eb 82         ; $a022: eb 82     Invalid Opcode - SBC #$82
            .hex 4b b8         ; $a024: 4b b8     Invalid Opcode - ALR #$b8
            .hex bb 38 3b      ; $a026: bb 38 3b  Invalid Opcode - LAS $3b38,y
            .hex b7 bb         ; $a029: b7 bb     Invalid Opcode - LAX $bb,y
            .hex 02            ; $a02b: 02        Invalid Opcode - KIL 
            .hex 0f 13 1b      ; $a02c: 0f 13 1b  Invalid Opcode - SLO $1b13
            brk                ; $a02f: 00        
            .hex cb 80         ; $a030: cb 80     Invalid Opcode - AXS #$80
            .hex 6b bc         ; $a032: 6b bc     Invalid Opcode - ARR #$bc
            .hex ff 7b 80      ; $a034: ff 7b 80  Invalid Opcode - ISC __807b,x
            ldx reset          ; $a037: ae 00 80  
            .hex 8b 8e         ; $a03a: 8b 8e     Invalid Opcode - XAA #$8e
            inx                ; $a03c: e8        
            ora $f9            ; $a03d: 05 f9     
            stx $17            ; $a03f: 86 17     
            stx $16            ; $a041: 86 16     
            sta $4e            ; $a043: 85 4e     
            .hex 2b 80         ; $a045: 2b 80     Invalid Opcode - ANC #$80
            .hex ab 8e         ; $a047: ab 8e     Invalid Opcode - LAX #$8e
            .hex 87 85         ; $a049: 87 85     Invalid Opcode - SAX $85
            .hex c3 05         ; $a04b: c3 05     Invalid Opcode - DCP ($05,x)
            .hex 8b 82         ; $a04d: 8b 82     Invalid Opcode - XAA #$82
            .hex 9b            ; $a04f: 9b        Invalid Opcode - TAS 
            .hex 02            ; $a050: 02        Invalid Opcode - KIL 
            .hex ab 02         ; $a051: ab 02     Invalid Opcode - LAX #$02
            .hex bb 86 cb      ; $a053: bb 86 cb  Invalid Opcode - LAS __cb86,y
            asl $d3            ; $a056: 06 d3     
            .hex 03 3b         ; $a058: 03 3b     Invalid Opcode - SLO ($3b,x)
            stx $0e6b          ; $a05a: 8e 6b 0e  
            .hex a7 8e         ; $a05d: a7 8e     Invalid Opcode - LAX $8e
            .hex ff            ; $a05f: ff        Suspected data
__a060:     ora $528e,y        ; $a060: 19 8e 52  
            ora ($93),y        ; $a063: 11 93     
            asl $030f          ; $a065: 0e 0f 03  
            .hex 9b            ; $a068: 9b        Invalid Opcode - TAS 
            asl __8e2b         ; $a069: 0e 2b 8e  
            .hex 5b 0e cb      ; $a06c: 5b 0e cb  Invalid Opcode - SRE __cb0e,y
            stx $0efb          ; $a06f: 8e fb 0e  
            .hex fb 82 9b      ; $a072: fb 82 9b  Invalid Opcode - ISC __9b82,y
            .hex 82 bb         ; $a075: 82 bb     Invalid Opcode - NOP #$bb
            .hex 02            ; $a077: 02        Invalid Opcode - KIL 
            inc __e842,x       ; $a078: fe 42 e8  
            .hex bb 8e 0f      ; $a07b: bb 8e 0f  Invalid Opcode - LAS $0f8e,y
            asl                ; $a07e: 0a        
            .hex ab 0e         ; $a07f: ab 0e     Invalid Opcode - LAX #$0e
            .hex cb 0e         ; $a081: cb 0e     Invalid Opcode - AXS #$0e
            sbc __880e,y       ; $a083: f9 0e 88  
            stx $a6            ; $a086: 86 a6     
            asl $db            ; $a088: 06 db     
            .hex 02            ; $a08a: 02        Invalid Opcode - KIL 
            ldx $8e,y          ; $a08b: b6 8e     
            .hex ff ab ce      ; $a08d: ff ab ce  Invalid Opcode - ISC __ceab,x
            dec __c042,x       ; $a090: de 42 c0  
            .hex cb ce         ; $a093: cb ce     Invalid Opcode - AXS #$ce
            .hex 5b 8e 1b      ; $a095: 5b 8e 1b  Invalid Opcode - SRE $1b8e,y
            dec __854b         ; $a098: ce 4b 85  
            .hex 67 45         ; $a09b: 67 45     Invalid Opcode - RRA $45
            .hex 0f 07 2b      ; $a09d: 0f 07 2b  Invalid Opcode - SLO $2b07
            brk                ; $a0a0: 00        
            .hex 7b 85 97      ; $a0a1: 7b 85 97  Invalid Opcode - RRA __9785,y
            ora $0f            ; $a0a4: 05 0f     
            asl                ; $a0a6: 0a        
            .hex 92            ; $a0a7: 92        Invalid Opcode - KIL 
            .hex 02            ; $a0a8: 02        Invalid Opcode - KIL 
            .hex ff 0a aa      ; $a0a9: ff 0a aa  Invalid Opcode - ISC __aa0a,x
            asl $4a24          ; $a0ac: 0e 24 4a  
            asl __aa23,x       ; $a0af: 1e 23 aa  
            .hex ff 1b 80      ; $a0b2: ff 1b 80  Invalid Opcode - ISC __801b,x
            .hex bb 38 4b      ; $a0b5: bb 38 4b  Invalid Opcode - LAS $4b38,y
            ldy $3beb,x        ; $a0b8: bc eb 3b  
            .hex 0f 04 2b      ; $a0bb: 0f 04 2b  Invalid Opcode - SLO $2b04
            brk                ; $a0be: 00        
            .hex ab 38         ; $a0bf: ab 38     Invalid Opcode - LAX #$38
            .hex eb 00         ; $a0c1: eb 00     Invalid Opcode - SBC #$00
            .hex cb 8e         ; $a0c3: cb 8e     Invalid Opcode - AXS #$8e
            .hex fb 80 ab      ; $a0c5: fb 80 ab  Invalid Opcode - ISC __ab80,y
            clv                ; $a0c8: b8        
            .hex 6b 80         ; $a0c9: 6b 80     Invalid Opcode - ARR #$80
            .hex fb 3c 9b      ; $a0cb: fb 3c 9b  Invalid Opcode - ISC __9b3c,y
            .hex bb 5b bc      ; $a0ce: bb 5b bc  Invalid Opcode - LAS __bc5b,y
            .hex fb 00 6b      ; $a0d1: fb 00 6b  Invalid Opcode - ISC $6b00,y
__a0d4:     clv                ; $a0d4: b8        
            .hex fb 38 ff      ; $a0d5: fb 38 ff  Invalid Opcode - ISC __ff38,y
            .hex 0b 86         ; $a0d8: 0b 86     Invalid Opcode - ANC #$86
            .hex 1a            ; $a0da: 1a        Invalid Opcode - NOP 
            asl $db            ; $a0db: 06 db     
            asl $de            ; $a0dd: 06 de     
            .hex c2 02         ; $a0df: c2 02     Invalid Opcode - NOP #$02
            beq __a11e         ; $a0e1: f0 3b     
            .hex bb 80 eb      ; $a0e3: bb 80 eb  Invalid Opcode - LAS __eb80,y
            asl $0b            ; $a0e6: 06 0b     
            stx $93            ; $a0e8: 86 93     
            asl $f0            ; $a0ea: 06 f0     
            and $060f,y        ; $a0ec: 39 0f 06  
            rts                ; $a0ef: 60        

;-------------------------------------------------------------------------------
            clv                ; $a0f0: b8        
            .hex 1b 86 a0      ; $a0f1: 1b 86 a0  Invalid Opcode - SLO __a086,y
            lda $27b7,y        ; $a0f4: b9 b7 27  
            lda $2b27,x        ; $a0f7: bd 27 2b  
            .hex 83 a1         ; $a0fa: 83 a1     Invalid Opcode - SAX ($a1,x)
            rol $a9            ; $a0fc: 26 a9     
            rol $ee            ; $a0fe: 26 ee     
            and $0b            ; $a100: 25 0b     
            .hex 27 b4         ; $a102: 27 b4     Invalid Opcode - RLA $b4
            .hex ff 0f 02      ; $a104: ff 0f 02  Invalid Opcode - ISC $020f,x
            asl $602f,x        ; $a107: 1e 2f 60  
            cpx #$3a           ; $a10a: e0 3a     
            lda $a7            ; $a10c: a5 a7     
            .hex db 80 3b      ; $a10e: db 80 3b  Invalid Opcode - DCP $3b80,y
            .hex 82 8b         ; $a111: 82 8b     Invalid Opcode - NOP #$8b
            .hex 02            ; $a113: 02        Invalid Opcode - KIL 
            inc $6842,x        ; $a114: fe 42 68  
            bvs __a0d4         ; $a117: 70 bb     
            and $a7            ; $a119: 25 a7     
            bit __b227         ; $a11b: 2c 27 b2  
__a11e:     rol $b9            ; $a11e: 26 b9     
            rol $9b            ; $a120: 26 9b     
            .hex 80 a8         ; $a122: 80 a8     Invalid Opcode - NOP #$a8
            .hex 82 b5         ; $a124: 82 b5     Invalid Opcode - NOP #$b5
            .hex 27 bc         ; $a126: 27 bc     Invalid Opcode - RLA $bc
            .hex 27 b0         ; $a128: 27 b0     Invalid Opcode - RLA $b0
            .hex bb            ; $a12a: bb        Suspected data
__a12b:     .hex 3b 82 87      ; $a12b: 3b 82 87  Invalid Opcode - RLA __8782,y
            .hex 34 ee         ; $a12e: 34 ee     Invalid Opcode - NOP $ee,x
            and $6b            ; $a130: 25 6b     
            .hex ff 1e a5      ; $a132: ff 1e a5  Invalid Opcode - ISC __a51e,x
            asl                ; $a135: 0a        
            rol $2728          ; $a136: 2e 28 27  
            rol __c733         ; $a139: 2e 33 c7  
            .hex 0f 03 1e      ; $a13c: 0f 03 1e  Invalid Opcode - SLO $1e03
            rti                ; $a13f: 40        

;-------------------------------------------------------------------------------
            .hex 07 2e         ; $a140: 07 2e     Invalid Opcode - SLO $2e
            bmi __a12b         ; $a142: 30 e7     
            .hex 0f 05 1e      ; $a144: 0f 05 1e  Invalid Opcode - SLO $1e05
            bit $44            ; $a147: 24 44     
            .hex 0f 07 1e      ; $a149: 0f 07 1e  Invalid Opcode - SLO $1e07
            .hex 22            ; $a14c: 22        Invalid Opcode - KIL 
            ror                ; $a14d: 6a        
            rol __ab23         ; $a14e: 2e 23 ab  
            .hex 0f 09 1e      ; $a151: 0f 09 1e  Invalid Opcode - SLO $1e09
            eor ($68,x)        ; $a154: 41 68     
            asl __8a2a,x       ; $a156: 1e 2a 8a  
            rol __a223         ; $a159: 2e 23 a2  
            rol __ea32         ; $a15c: 2e 32 ea  
            .hex ff 3b 87      ; $a15f: ff 3b 87  Invalid Opcode - ISC __873b,x
            ror $27            ; $a162: 66 27     
            cpy __ee27         ; $a164: cc 27 ee  
            and ($87),y        ; $a167: 31 87     
            inc __a723         ; $a169: ee 23 a7  
            .hex 3b 87 db      ; $a16c: 3b 87 db  Invalid Opcode - RLA __db87,y
            .hex 07 ff         ; $a16f: 07 ff     Invalid Opcode - SLO $ff
            .hex 0f 01 2e      ; $a171: 0f 01 2e  Invalid Opcode - SLO $2e01
            and $2b            ; $a174: 25 2b     
            rol $4b25          ; $a176: 2e 25 4b  
            lsr __cb25         ; $a179: 4e 25 cb  
            .hex 6b 07         ; $a17c: 6b 07     Invalid Opcode - ARR #$07
            .hex 97 47         ; $a17e: 97 47     Invalid Opcode - SAX $47,y
            sbc #$87           ; $a180: e9 87     
            .hex 47 c7         ; $a182: 47 c7     Invalid Opcode - SRE $c7
            .hex 7a            ; $a184: 7a        Invalid Opcode - NOP 
            .hex 07 d6         ; $a185: 07 d6     Invalid Opcode - SLO $d6
            .hex c7 78         ; $a187: c7 78     Invalid Opcode - DCP $78
            .hex 07 38         ; $a189: 07 38     Invalid Opcode - SLO $38
            .hex 87 ab         ; $a18b: 87 ab     Invalid Opcode - SAX $ab
            .hex 47 e3         ; $a18d: 47 e3     Invalid Opcode - SRE $e3
            .hex 07 9b         ; $a18f: 07 9b     Invalid Opcode - SLO $9b
            .hex 87 0f         ; $a191: 87 0f     Invalid Opcode - SAX $0f
            ora #$68           ; $a193: 09 68     
            .hex 47 db         ; $a195: 47 db     Invalid Opcode - SRE $db
            .hex c7 3b         ; $a197: c7 3b     Invalid Opcode - DCP $3b
            .hex c7 ff         ; $a199: c7 ff     Invalid Opcode - DCP $ff
            .hex 47 9b         ; $a19b: 47 9b     Invalid Opcode - SRE $9b
            .hex cb 07         ; $a19d: cb 07     Invalid Opcode - AXS #$07
            .hex fa            ; $a19f: fa        Invalid Opcode - NOP 
            ora __9b86,x       ; $a1a0: 1d 86 9b  
            .hex 3a            ; $a1a3: 3a        Invalid Opcode - NOP 
            .hex 87 56         ; $a1a4: 87 56     Invalid Opcode - SAX $56
            .hex 07 88         ; $a1a6: 07 88     Invalid Opcode - SLO $88
            .hex 1b 07 9d      ; $a1a8: 1b 07 9d  Invalid Opcode - SLO __9d07,y
            rol __f065         ; $a1ab: 2e 65 f0  
            .hex ff 9b 07      ; $a1ae: ff 9b 07  Invalid Opcode - ISC $079b,x
            ora $32            ; $a1b1: 05 32     
            asl $33            ; $a1b3: 06 33     
            .hex 07 34         ; $a1b5: 07 34     Invalid Opcode - SLO $34
            dec __dc03         ; $a1b7: ce 03 dc  
            eor ($ee),y        ; $a1ba: 51 ee     
            .hex 07 73         ; $a1bc: 07 73     Invalid Opcode - SLO $73
            cpx #$74           ; $a1be: e0 74     
            asl                ; $a1c0: 0a        
            ror __9e06,x       ; $a1c1: 7e 06 9e  
            asl                ; $a1c4: 0a        
            dec __e406         ; $a1c5: ce 06 e4  
            brk                ; $a1c8: 00        
            inx                ; $a1c9: e8        
            asl                ; $a1ca: 0a        
            inc $2e0a,x        ; $a1cb: fe 0a 2e  
            .hex 89 4e         ; $a1ce: 89 4e     Invalid Opcode - NOP #$4e
            .hex 0b 54         ; $a1d0: 0b 54     Invalid Opcode - ANC #$54
            asl                ; $a1d2: 0a        
            .hex 14 8a         ; $a1d3: 14 8a     Invalid Opcode - NOP $8a,x
            cpy $0a            ; $a1d5: c4 0a     
            .hex 34 8a         ; $a1d7: 34 8a     Invalid Opcode - NOP $8a,x
            ror __c706,x       ; $a1d9: 7e 06 c7  
            asl                ; $a1dc: 0a        
            ora ($e0,x)        ; $a1dd: 01 e0     
            .hex 02            ; $a1df: 02        Invalid Opcode - KIL 
            asl                ; $a1e0: 0a        
            .hex 47 0a         ; $a1e1: 47 0a     Invalid Opcode - SRE $0a
            sta ($60,x)        ; $a1e3: 81 60     
            .hex 82 0a         ; $a1e5: 82 0a     Invalid Opcode - NOP #$0a
            .hex c7 0a         ; $a1e7: c7 0a     Invalid Opcode - DCP $0a
            asl $7e87          ; $a1e9: 0e 87 7e  
            .hex 02            ; $a1ec: 02        Invalid Opcode - KIL 
            .hex a7 02         ; $a1ed: a7 02     Invalid Opcode - LAX $02
            .hex b3 02         ; $a1ef: b3 02     Invalid Opcode - LAX ($02),y
            .hex d7 02         ; $a1f1: d7 02     Invalid Opcode - DCP $02,x
            .hex e3 02         ; $a1f3: e3 02     Invalid Opcode - ISC ($02,x)
            .hex 07 82         ; $a1f5: 07 82     Invalid Opcode - SLO $82
            .hex 13 02         ; $a1f7: 13 02     Invalid Opcode - SLO ($02),y
            rol $7e06,x        ; $a1f9: 3e 06 7e  
            .hex 02            ; $a1fc: 02        Invalid Opcode - KIL 
            ldx __fe07         ; $a1fd: ae 07 fe  
            asl                ; $a200: 0a        
            ora __cdc4         ; $a201: 0d c4 cd  
            .hex 43 ce         ; $a204: 43 ce     Invalid Opcode - SRE ($ce,x)
            ora #$de           ; $a206: 09 de     
            .hex 0b dd         ; $a208: 0b dd     Invalid Opcode - ANC #$dd
            .hex 42            ; $a20a: 42        Invalid Opcode - KIL 
            inc $5d02,x        ; $a20b: fe 02 5d  
            .hex c7 fd         ; $a20e: c7 fd     Invalid Opcode - DCP $fd
            .hex 5b 07 05      ; $a210: 5b 07 05  Invalid Opcode - SRE $0507,y
            .hex 32            ; $a213: 32        Invalid Opcode - KIL 
            asl $33            ; $a214: 06 33     
            .hex 07 34         ; $a216: 07 34     Invalid Opcode - SLO $34
            lsr $680a,x        ; $a218: 5e 0a 68  
            .hex 64 98         ; $a21b: 64 98     Invalid Opcode - NOP $98
            .hex 64 a8         ; $a21d: 64 a8     Invalid Opcode - NOP $a8
            .hex 64 ce         ; $a21f: 64 ce     Invalid Opcode - NOP $ce
            asl $fe            ; $a221: 06 fe     
__a223:     .hex 02            ; $a223: 02        Invalid Opcode - KIL 
            ora $1e01          ; $a224: 0d 01 1e  
            asl $027e          ; $a227: 0e 7e 02  
            sty $63,x          ; $a22a: 94 63     
            ldy $63,x          ; $a22c: b4 63     
            .hex d4 63         ; $a22e: d4 63     Invalid Opcode - NOP $63,x
            .hex f4 63         ; $a230: f4 63     Invalid Opcode - NOP $63,x
            .hex 14 e3         ; $a232: 14 e3     Invalid Opcode - NOP $e3,x
            rol $5e0e          ; $a234: 2e 0e 5e  
            .hex 02            ; $a237: 02        Invalid Opcode - KIL 
            .hex 64 35         ; $a238: 64 35     Invalid Opcode - NOP $35
            dey                ; $a23a: 88        
            .hex 72            ; $a23b: 72        Invalid Opcode - KIL 
            ldx $0d0e,y        ; $a23c: be 0e 0d  
            .hex 04 ae         ; $a23f: 04 ae     Invalid Opcode - NOP $ae
            .hex 02            ; $a241: 02        Invalid Opcode - KIL 
            dec __cd08         ; $a242: ce 08 cd  
__a245:     .hex 4b fe         ; $a245: 4b fe     Invalid Opcode - ALR #$fe
            .hex 02            ; $a247: 02        Invalid Opcode - KIL 
            ora $6805          ; $a248: 0d 05 68  
            and ($7e),y        ; $a24b: 31 7e     
            asl                ; $a24d: 0a        
            stx $31,y          ; $a24e: 96 31     
            lda #$63           ; $a250: a9 63     
            tay                ; $a252: a8        
            .hex 33 d5         ; $a253: 33 d5     Invalid Opcode - RLA ($d5),y
            bmi __a245         ; $a255: 30 ee     
            .hex 02            ; $a257: 02        Invalid Opcode - KIL 
            inc $62            ; $a258: e6 62     
            .hex f4 61         ; $a25a: f4 61     Invalid Opcode - NOP $61,x
            .hex 04 b1         ; $a25c: 04 b1     Invalid Opcode - NOP $b1
            php                ; $a25e: 08        
            .hex 3f 44 33      ; $a25f: 3f 44 33  Invalid Opcode - RLA $3344,x
            sty $63,x          ; $a262: 94 63     
            ldy $31            ; $a264: a4 31     
            cpx $31            ; $a266: e4 31     
            .hex 04 bf         ; $a268: 04 bf     Invalid Opcode - NOP $bf
            php                ; $a26a: 08        
            .hex 3f 04 bf      ; $a26b: 3f 04 bf  Invalid Opcode - RLA __bf04,x
            php                ; $a26e: 08        
            .hex 3f cd 4b      ; $a26f: 3f cd 4b  Invalid Opcode - RLA $4bcd,x
            .hex 03 e4         ; $a272: 03 e4     Invalid Opcode - SLO ($e4,x)
            asl $2e03          ; $a274: 0e 03 2e  
            ora ($7e,x)        ; $a277: 01 7e     
            asl $be            ; $a279: 06 be     
            .hex 02            ; $a27b: 02        Invalid Opcode - KIL 
            dec __fe06,x       ; $a27c: de 06 fe  
            asl                ; $a27f: 0a        
            ora __cdc4         ; $a280: 0d c4 cd  
            .hex 43 ce         ; $a283: 43 ce     Invalid Opcode - SRE ($ce,x)
            ora #$de           ; $a285: 09 de     
            .hex 0b dd         ; $a287: 0b dd     Invalid Opcode - ANC #$dd
            .hex 42            ; $a289: 42        Invalid Opcode - KIL 
            inc $5d02,x        ; $a28a: fe 02 5d  
            .hex c7 fd         ; $a28d: c7 fd     Invalid Opcode - DCP $fd
            .hex 9b            ; $a28f: 9b        Invalid Opcode - TAS 
            .hex 07 05         ; $a290: 07 05     Invalid Opcode - SLO $05
            .hex 32            ; $a292: 32        Invalid Opcode - KIL 
            asl $33            ; $a293: 06 33     
            .hex 07 34         ; $a295: 07 34     Invalid Opcode - SLO $34
            inc $2700,x        ; $a297: fe 00 27  
            lda ($65),y        ; $a29a: b1 65     
            .hex 32            ; $a29c: 32        Invalid Opcode - KIL 
            adc $0a,x          ; $a29d: 75 0a     
            adc ($00),y        ; $a29f: 71 00     
            .hex b7            ; $a2a1: b7        Suspected data
__a2a2:     and ($08),y        ; $a2a2: 31 08     
            cpx $18            ; $a2a4: e4 18     
            .hex 64 1e         ; $a2a6: 64 1e     Invalid Opcode - NOP $1e
            .hex 04 57         ; $a2a8: 04 57     Invalid Opcode - NOP $57
            .hex 3b bb 0a      ; $a2aa: 3b bb 0a  Invalid Opcode - RLA $0abb,y
            .hex 17 8a         ; $a2ad: 17 8a     Invalid Opcode - SLO $8a,x
            .hex 27 3a         ; $a2af: 27 3a     Invalid Opcode - RLA $3a
            .hex 73 0a         ; $a2b1: 73 0a     Invalid Opcode - RRA ($0a),y
            .hex 7b 0a d7      ; $a2b3: 7b 0a d7  Invalid Opcode - RRA __d70a,y
            asl                ; $a2b6: 0a        
            .hex e7 3a         ; $a2b7: e7 3a     Invalid Opcode - ISC $3a
            .hex 3b 8a 97      ; $a2b9: 3b 8a 97  Invalid Opcode - RLA __978a,y
            asl                ; $a2bc: 0a        
            inc $2408,x        ; $a2bd: fe 08 24  
            txa                ; $a2c0: 8a        
            rol $3e00          ; $a2c1: 2e 00 3e  
            rti                ; $a2c4: 40        

;-------------------------------------------------------------------------------
            sec                ; $a2c5: 38        
            .hex 64 6f         ; $a2c6: 64 6f     Invalid Opcode - NOP $6f
            brk                ; $a2c8: 00        
            .hex 9f 00 be      ; $a2c9: 9f 00 be  Invalid Opcode - AHX __be00,y
            .hex 43 c8         ; $a2cc: 43 c8     Invalid Opcode - SRE ($c8,x)
            asl                ; $a2ce: 0a        
            cmp #$63           ; $a2cf: c9 63     
            dec __fe07         ; $a2d1: ce 07 fe  
            .hex 07 2e         ; $a2d4: 07 2e     Invalid Opcode - SLO $2e
            sta ($66,x)        ; $a2d6: 81 66     
            .hex 42            ; $a2d8: 42        Invalid Opcode - KIL 
            ror                ; $a2d9: 6a        
            .hex 42            ; $a2da: 42        Invalid Opcode - KIL 
            adc __be0a,y       ; $a2db: 79 0a be  
            brk                ; $a2de: 00        
            iny                ; $a2df: c8        
            .hex 64 f8         ; $a2e0: 64 f8     Invalid Opcode - NOP $f8
            .hex 64 08         ; $a2e2: 64 08     Invalid Opcode - NOP $08
            cpx $2e            ; $a2e4: e4 2e     
            .hex 07 7e         ; $a2e6: 07 7e     Invalid Opcode - SLO $7e
            .hex 03 9e         ; $a2e8: 03 9e     Invalid Opcode - SLO ($9e,x)
            .hex 07 be         ; $a2ea: 07 be     Invalid Opcode - SLO $be
            .hex 03 de         ; $a2ec: 03 de     Invalid Opcode - SLO ($de,x)
            .hex 07 fe         ; $a2ee: 07 fe     Invalid Opcode - SLO $fe
            asl                ; $a2f0: 0a        
            .hex 03 a5         ; $a2f1: 03 a5     Invalid Opcode - SLO ($a5,x)
            ora __cd44         ; $a2f3: 0d 44 cd  
            .hex 43 ce         ; $a2f6: 43 ce     Invalid Opcode - SRE ($ce,x)
            ora #$dd           ; $a2f8: 09 dd     
            .hex 42            ; $a2fa: 42        Invalid Opcode - KIL 
            dec __fe0b,x       ; $a2fb: de 0b fe  
            .hex 02            ; $a2fe: 02        Invalid Opcode - KIL 
            eor __fdc7,x       ; $a2ff: 5d c7 fd  
            .hex 9b            ; $a302: 9b        Invalid Opcode - TAS 
            .hex 07 05         ; $a303: 07 05     Invalid Opcode - SLO $05
            .hex 32            ; $a305: 32        Invalid Opcode - KIL 
            asl $33            ; $a306: 06 33     
            .hex 07 34         ; $a308: 07 34     Invalid Opcode - SLO $34
            inc $0c06,x        ; $a30a: fe 06 0c  
            sta ($39,x)        ; $a30d: 81 39     
            asl                ; $a30f: 0a        
            .hex 5c 01 89      ; $a310: 5c 01 89  Invalid Opcode - NOP __8901,x
            asl                ; $a313: 0a        
            ldy __d901         ; $a314: ac 01 d9  
            asl                ; $a317: 0a        
            .hex fc 01 2e      ; $a318: fc 01 2e  Invalid Opcode - NOP $2e01,x
            .hex 83 a7         ; $a31b: 83 a7     Invalid Opcode - SAX ($a7,x)
            ora ($b7,x)        ; $a31d: 01 b7     
            brk                ; $a31f: 00        
            .hex c7 01         ; $a320: c7 01     Invalid Opcode - DCP $01
            dec __fe0a,x       ; $a322: de 0a fe  
            .hex 02            ; $a325: 02        Invalid Opcode - KIL 
            lsr $5a83          ; $a326: 4e 83 5a  
            .hex 32            ; $a329: 32        Invalid Opcode - KIL 
            .hex 63 0a         ; $a32a: 63 0a     Invalid Opcode - RRA ($0a,x)
            adc #$0a           ; $a32c: 69 0a     
            ror __ee02,x       ; $a32e: 7e 02 ee  
            .hex 03 fa         ; $a331: 03 fa     Invalid Opcode - SLO ($fa,x)
            .hex 32            ; $a333: 32        Invalid Opcode - KIL 
            .hex 03 8a         ; $a334: 03 8a     Invalid Opcode - SLO ($8a,x)
            ora #$0a           ; $a336: 09 0a     
            asl __ee02,x       ; $a338: 1e 02 ee  
            .hex 03 fa         ; $a33b: 03 fa     Invalid Opcode - SLO ($fa,x)
            .hex 32            ; $a33d: 32        Invalid Opcode - KIL 
            .hex 03 8a         ; $a33e: 03 8a     Invalid Opcode - SLO ($8a,x)
            ora #$0a           ; $a340: 09 0a     
            .hex 14 42         ; $a342: 14 42     Invalid Opcode - NOP $42,x
            asl $7e02,x        ; $a344: 1e 02 7e  
            asl                ; $a347: 0a        
            .hex 9e 07 fe      ; $a348: 9e 07 fe  Invalid Opcode - SHX __fe07,y
            asl                ; $a34b: 0a        
            rol $5e86          ; $a34c: 2e 86 5e  
            asl                ; $a34f: 0a        
            stx __be06         ; $a350: 8e 06 be  
            asl                ; $a353: 0a        
            inc $3e07          ; $a354: ee 07 3e  
            .hex 83 5e         ; $a357: 83 5e     Invalid Opcode - SAX ($5e,x)
            .hex 07 fe         ; $a359: 07 fe     Invalid Opcode - SLO $fe
            asl                ; $a35b: 0a        
            ora $41c4          ; $a35c: 0d c4 41  
            .hex 52            ; $a35f: 52        Invalid Opcode - KIL 
            eor ($52),y        ; $a360: 51 52     
            cmp __ce43         ; $a362: cd 43 ce  
            ora #$de           ; $a365: 09 de     
            .hex 0b dd         ; $a367: 0b dd     Invalid Opcode - ANC #$dd
            .hex 42            ; $a369: 42        Invalid Opcode - KIL 
            inc $5d02,x        ; $a36a: fe 02 5d  
            .hex c7 fd         ; $a36d: c7 fd     Invalid Opcode - DCP $fd
            .hex 5b 07 05      ; $a36f: 5b 07 05  Invalid Opcode - SRE $0507,y
            .hex 32            ; $a372: 32        Invalid Opcode - KIL 
            asl $33            ; $a373: 06 33     
            .hex 07 34         ; $a375: 07 34     Invalid Opcode - SLO $34
            inc __ae0a,x       ; $a377: fe 0a ae  
            stx $be            ; $a37a: 86 be     
            .hex 07 fe         ; $a37c: 07 fe     Invalid Opcode - SLO $fe
            .hex 02            ; $a37e: 02        Invalid Opcode - KIL 
            ora $2702          ; $a37f: 0d 02 27  
            .hex 32            ; $a382: 32        Invalid Opcode - KIL 
            lsr $61            ; $a383: 46 61     
            eor $62,x          ; $a385: 55 62     
            lsr $1e0e,x        ; $a387: 5e 0e 1e  
            .hex 82 68         ; $a38a: 82 68     Invalid Opcode - NOP #$68
            .hex 3c 74 3a      ; $a38c: 3c 74 3a  Invalid Opcode - NOP $3a74,x
            adc $5e4b,x        ; $a38f: 7d 4b 5e  
            stx $4b7d          ; $a392: 8e 7d 4b  
__a395:     ror __8482,x       ; $a395: 7e 82 84  
            .hex 62            ; $a398: 62        Invalid Opcode - KIL 
            sty $61,x          ; $a399: 94 61     
            ldy $31            ; $a39b: a4 31     
            lda __ce4b,x       ; $a39d: bd 4b ce  
            asl $fe            ; $a3a0: 06 fe     
            .hex 02            ; $a3a2: 02        Invalid Opcode - KIL 
            ora $3406          ; $a3a3: 0d 06 34  
            and ($3e),y        ; $a3a6: 31 3e     
            asl                ; $a3a8: 0a        
            .hex 64 32         ; $a3a9: 64 32     Invalid Opcode - NOP $32
            adc $0a,x          ; $a3ab: 75 0a     
            .hex 7b 61 a4      ; $a3ad: 7b 61 a4  Invalid Opcode - RRA __a461,y
            .hex 33 ae         ; $a3b0: 33 ae     Invalid Opcode - RLA ($ae),y
            .hex 02            ; $a3b2: 02        Invalid Opcode - KIL 
            dec $3e0e,x        ; $a3b3: de 0e 3e  
            .hex 82 64         ; $a3b6: 82 64     Invalid Opcode - NOP #$64
            .hex 32            ; $a3b8: 32        Invalid Opcode - KIL 
            sei                ; $a3b9: 78        
            .hex 32            ; $a3ba: 32        Invalid Opcode - KIL 
            ldy $36,x          ; $a3bb: b4 36     
            iny                ; $a3bd: c8        
            rol $dd,x          ; $a3be: 36 dd     
            .hex 4b 44         ; $a3c0: 4b 44     Invalid Opcode - ALR #$44
            .hex b2            ; $a3c2: b2        Invalid Opcode - KIL 
            cli                ; $a3c3: 58        
            .hex 32            ; $a3c4: 32        Invalid Opcode - KIL 
            sty $63,x          ; $a3c5: 94 63     
            ldy $3e            ; $a3c7: a4 3e     
            tsx                ; $a3c9: ba        
            bmi __a395         ; $a3ca: 30 c9     
            adc ($ce,x)        ; $a3cc: 61 ce     
            asl $dd            ; $a3ce: 06 dd     
            .hex 4b ce         ; $a3d0: 4b ce     Invalid Opcode - ALR #$ce
            stx $dd            ; $a3d2: 86 dd     
            .hex 4b fe         ; $a3d4: 4b fe     Invalid Opcode - ALR #$fe
            .hex 02            ; $a3d6: 02        Invalid Opcode - KIL 
            rol $5e86          ; $a3d7: 2e 86 5e  
            .hex 02            ; $a3da: 02        Invalid Opcode - KIL 
            ror __fe06,x       ; $a3db: 7e 06 fe  
            .hex 02            ; $a3de: 02        Invalid Opcode - KIL 
            asl $3e86,x        ; $a3df: 1e 86 3e  
            .hex 02            ; $a3e2: 02        Invalid Opcode - KIL 
            lsr $7e06,x        ; $a3e3: 5e 06 7e  
            .hex 02            ; $a3e6: 02        Invalid Opcode - KIL 
            .hex 9e 06 fe      ; $a3e7: 9e 06 fe  Invalid Opcode - SHX __fe06,y
            asl                ; $a3ea: 0a        
            ora __cdc4         ; $a3eb: 0d c4 cd  
            .hex 43 ce         ; $a3ee: 43 ce     Invalid Opcode - SRE ($ce,x)
            ora #$de           ; $a3f0: 09 de     
            .hex 0b dd         ; $a3f2: 0b dd     Invalid Opcode - ANC #$dd
            .hex 42            ; $a3f4: 42        Invalid Opcode - KIL 
            inc $5d02,x        ; $a3f5: fe 02 5d  
            .hex c7 fd         ; $a3f8: c7 fd     Invalid Opcode - DCP $fd
            .hex 5b 06 05      ; $a3fa: 5b 06 05  Invalid Opcode - SRE $0506,y
            .hex 32            ; $a3fd: 32        Invalid Opcode - KIL 
            asl $33            ; $a3fe: 06 33     
            .hex 07 34         ; $a400: 07 34     Invalid Opcode - SLO $34
            lsr __ae0a,x       ; $a402: 5e 0a ae  
            .hex 02            ; $a405: 02        Invalid Opcode - KIL 
            ora $3901          ; $a406: 0d 01 39  
            .hex 73 0d         ; $a409: 73 0d     Invalid Opcode - RRA ($0d),y
            .hex 03 39         ; $a40b: 03 39     Invalid Opcode - SLO ($39,x)
            .hex 7b 4d 4b      ; $a40d: 7b 4d 4b  Invalid Opcode - RRA $4b4d,y
            dec $1e06,x        ; $a410: de 06 1e  
            txa                ; $a413: 8a        
            ldx __c406         ; $a414: ae 06 c4  
            .hex 33 16         ; $a417: 33 16     Invalid Opcode - RLA ($16),y
            inc $77a5,x        ; $a419: fe a5 77  
            inc __fe02,x       ; $a41c: fe 02 fe  
            .hex 82 0d         ; $a41f: 82 0d     Invalid Opcode - NOP #$0d
            .hex 07 39         ; $a421: 07 39     Invalid Opcode - SLO $39
            .hex 73 a8         ; $a423: 73 a8     Invalid Opcode - RRA ($a8),y
            .hex 74 ed         ; $a425: 74 ed     Invalid Opcode - NOP $ed,x
            .hex 4b 49         ; $a427: 4b 49     Invalid Opcode - ALR #$49
            .hex fb e8 74      ; $a429: fb e8 74  Invalid Opcode - ISC $74e8,y
            inc $2e0a,x        ; $a42c: fe 0a 2e  
            .hex 82 67         ; $a42f: 82 67     Invalid Opcode - NOP #$67
            .hex 02            ; $a431: 02        Invalid Opcode - KIL 
            sty $7a            ; $a432: 84 7a     
            .hex 87 31         ; $a434: 87 31     Invalid Opcode - SAX $31
            ora __fe0b         ; $a436: 0d 0b fe  
            .hex 02            ; $a439: 02        Invalid Opcode - KIL 
            ora $390c          ; $a43a: 0d 0c 39  
            .hex 73 5e         ; $a43d: 73 5e     Invalid Opcode - RRA ($5e),y
            asl $c6            ; $a43f: 06 c6     
            ror $45,x          ; $a441: 76 45     
            .hex ff be 0a      ; $a443: ff be 0a  Invalid Opcode - ISC $0abe,x
            cmp __fe48,x       ; $a446: dd 48 fe  
            asl $3d            ; $a449: 06 3d     
            .hex cb 46         ; $a44b: cb 46     Invalid Opcode - AXS #$46
            ror $4aad,x        ; $a44d: 7e ad 4a  
            inc $3982,x        ; $a450: fe 82 39  
            .hex f3 a9         ; $a453: f3 a9     Invalid Opcode - ISC ($a9),y
            .hex 7b 4e 8a      ; $a455: 7b 4e 8a  Invalid Opcode - RRA __8a4e,y
            .hex 9e 07 fe      ; $a458: 9e 07 fe  Invalid Opcode - SHX __fe07,y
            asl                ; $a45b: 0a        
            ora __cdc4         ; $a45c: 0d c4 cd  
            .hex 43 ce         ; $a45f: 43 ce     Invalid Opcode - SRE ($ce,x)
            ora #$de           ; $a461: 09 de     
            .hex 0b dd         ; $a463: 0b dd     Invalid Opcode - ANC #$dd
            .hex 42            ; $a465: 42        Invalid Opcode - KIL 
            inc $5d02,x        ; $a466: fe 02 5d  
            .hex c7 fd         ; $a469: c7 fd     Invalid Opcode - DCP $fd
            sty $11,x          ; $a46b: 94 11     
            .hex 0f 26 fe      ; $a46d: 0f 26 fe  Invalid Opcode - SLO __fe26
            bpl __a49a         ; $a470: 10 28     
            sty $65,x          ; $a472: 94 65     
            ora $eb,x          ; $a474: 15 eb     
            .hex 12            ; $a476: 12        Invalid Opcode - KIL 
            .hex fa            ; $a477: fa        Invalid Opcode - NOP 
            eor ($4a,x)        ; $a478: 41 4a     
            stx $54,y          ; $a47a: 96 54     
            rti                ; $a47c: 40        

;-------------------------------------------------------------------------------
            ldy $42            ; $a47d: a4 42     
            .hex b7 13         ; $a47f: b7 13     Invalid Opcode - LAX $13,y
__a481:     sbc #$19           ; $a481: e9 19     
            sbc $15,x          ; $a483: f5 15     
            ora ($80),y        ; $a485: 11 80     
            .hex 47 42         ; $a487: 47 42     Invalid Opcode - SRE $42
            adc ($13),y        ; $a489: 71 13     
            .hex 80 41         ; $a48b: 80 41     Invalid Opcode - NOP #$41
            ora $92,x          ; $a48d: 15 92     
            .hex 1b 1f 24      ; $a48f: 1b 1f 24  Invalid Opcode - SLO $241f,y
            rti                ; $a492: 40        

;-------------------------------------------------------------------------------
            eor $12,x          ; $a493: 55 12     
            .hex 64 40         ; $a495: 64 40     Invalid Opcode - NOP $40
            sta $12,x          ; $a497: 95 12     
            .hex a4            ; $a499: a4        Suspected data
__a49a:     rti                ; $a49a: 40        

;-------------------------------------------------------------------------------
            .hex d2            ; $a49b: d2        Invalid Opcode - KIL 
            .hex 12            ; $a49c: 12        Invalid Opcode - KIL 
            sbc ($40,x)        ; $a49d: e1 40     
            .hex 13 c0         ; $a49f: 13 c0     Invalid Opcode - SLO ($c0),y
            bit $2f17          ; $a4a1: 2c 17 2f  
            .hex 12            ; $a4a4: 12        Invalid Opcode - KIL 
            eor #$13           ; $a4a5: 49 13     
            .hex 83 40         ; $a4a7: 83 40     Invalid Opcode - SAX ($40,x)
            .hex 9f 14 a3      ; $a4a9: 9f 14 a3  Invalid Opcode - AHX __a314,y
            rti                ; $a4ac: 40        

;-------------------------------------------------------------------------------
            .hex 17 92         ; $a4ad: 17 92     Invalid Opcode - SLO $92,x
            .hex 83 13         ; $a4af: 83 13     Invalid Opcode - SAX ($13,x)
            .hex 92            ; $a4b1: 92        Invalid Opcode - KIL 
            eor ($b9,x)        ; $a4b2: 41 b9     
            .hex 14 c5         ; $a4b4: 14 c5     Invalid Opcode - NOP $c5,x
            .hex 12            ; $a4b6: 12        Invalid Opcode - KIL 
            iny                ; $a4b7: c8        
            rti                ; $a4b8: 40        

;-------------------------------------------------------------------------------
            .hex d4 40         ; $a4b9: d4 40     Invalid Opcode - NOP $40,x
            .hex 4b 92         ; $a4bb: 4b 92     Invalid Opcode - ALR #$92
            sei                ; $a4bd: 78        
            .hex 1b 9c 94      ; $a4be: 1b 9c 94  Invalid Opcode - SLO __949c,y
            .hex 9f 11 df      ; $a4c1: 9f 11 df  Invalid Opcode - AHX __df11,y
            .hex 14 fe         ; $a4c4: 14 fe     Invalid Opcode - NOP $fe,x
            ora ($7d),y        ; $a4c6: 11 7d     
            cmp ($9e,x)        ; $a4c8: c1 9e     
            .hex 42            ; $a4ca: 42        Invalid Opcode - KIL 
            .hex cf 20 fd      ; $a4cb: cf 20 fd  Invalid Opcode - DCP __fd20
            bcc __a481         ; $a4ce: 90 b1     
            .hex 0f 26 29      ; $a4d0: 0f 26 29  Invalid Opcode - SLO $2926
            sta ($7e),y        ; $a4d3: 91 7e     
            .hex 42            ; $a4d5: 42        Invalid Opcode - KIL 
            inc $2840,x        ; $a4d6: fe 40 28  
            .hex 92            ; $a4d9: 92        Invalid Opcode - KIL 
            lsr $2e42          ; $a4da: 4e 42 2e  
            cpy #$57           ; $a4dd: c0 57     
            .hex 73 c3         ; $a4df: 73 c3     Invalid Opcode - RRA ($c3),y
            and $c7            ; $a4e1: 25 c7     
            .hex 27 23         ; $a4e3: 27 23     Invalid Opcode - RLA $23
            sty $33            ; $a4e5: 84 33     
            jsr $015c          ; $a4e7: 20 5c 01  
            .hex 77 63         ; $a4ea: 77 63     Invalid Opcode - RRA $63,x
            dey                ; $a4ec: 88        
            .hex 62            ; $a4ed: 62        Invalid Opcode - KIL 
            sta __aa61,y       ; $a4ee: 99 61 aa  
            rts                ; $a4f1: 60        

;-------------------------------------------------------------------------------
            ldy __ee01,x       ; $a4f2: bc 01 ee  
            .hex 42            ; $a4f5: 42        Invalid Opcode - KIL 
            lsr $69c0          ; $a4f6: 4e c0 69  
            ora ($7e),y        ; $a4f9: 11 7e     
            .hex 42            ; $a4fb: 42        Invalid Opcode - KIL 
            dec __f840,x       ; $a4fc: de 40 f8  
            .hex 62            ; $a4ff: 62        Invalid Opcode - KIL 
            asl __aec2         ; $a500: 0e c2 ae  
            rti                ; $a503: 40        

;-------------------------------------------------------------------------------
            .hex d7 63         ; $a504: d7 63     Invalid Opcode - DCP $63,x
            .hex e7 63         ; $a506: e7 63     Invalid Opcode - ISC $63
            .hex 33 a7         ; $a508: 33 a7     Invalid Opcode - RLA ($a7),y
            .hex 37 27         ; $a50a: 37 27     Invalid Opcode - RLA $27,x
            .hex 43 04         ; $a50c: 43 04     Invalid Opcode - SRE ($04,x)
            cpy __e701         ; $a50e: cc 01 e7  
            .hex 73 0c         ; $a511: 73 0c     Invalid Opcode - RRA ($0c),y
            sta ($3e,x)        ; $a513: 81 3e     
            .hex 42            ; $a515: 42        Invalid Opcode - KIL 
            ora $5e0a          ; $a516: 0d 0a 5e  
            rti                ; $a519: 40        

;-------------------------------------------------------------------------------
            dey                ; $a51a: 88        
            .hex 72            ; $a51b: 72        Invalid Opcode - KIL 
            ldx __e742,y       ; $a51c: be 42 e7  
            .hex 87 fe         ; $a51f: 87 fe     Invalid Opcode - SAX $fe
            rti                ; $a521: 40        

;-------------------------------------------------------------------------------
            and $4ee1,y        ; $a522: 39 e1 4e  
            brk                ; $a525: 00        
            adc #$60           ; $a526: 69 60     
            .hex 87 60         ; $a528: 87 60     Invalid Opcode - SAX $60
            lda $60            ; $a52a: a5 60     
            .hex c3 31         ; $a52c: c3 31     Invalid Opcode - DCP ($31,x)
            inc $6d31,x        ; $a52e: fe 31 6d  
            cmp ($be,x)        ; $a531: c1 be     
            .hex 42            ; $a533: 42        Invalid Opcode - KIL 
            .hex ef 20 fd      ; $a534: ef 20 fd  Invalid Opcode - ISC __fd20
            .hex 52            ; $a537: 52        Invalid Opcode - KIL 
            and ($0f,x)        ; $a538: 21 0f     
            jsr $406e          ; $a53a: 20 6e 40  
            cli                ; $a53d: 58        
            .hex f2            ; $a53e: f2        Invalid Opcode - KIL 
            .hex 93 01         ; $a53f: 93 01     Invalid Opcode - AHX ($01),y
            .hex 97 00         ; $a541: 97 00     Invalid Opcode - SAX $00,y
            .hex 0c 81 97      ; $a543: 0c 81 97  Invalid Opcode - NOP __9781
            rti                ; $a546: 40        

;-------------------------------------------------------------------------------
            ldx $41            ; $a547: a6 41     
            .hex c7 40         ; $a549: c7 40     Invalid Opcode - DCP $40
            ora $0304          ; $a54b: 0d 04 03  
            ora ($07,x)        ; $a54e: 01 07     
            ora ($23,x)        ; $a550: 01 23     
            ora ($27,x)        ; $a552: 01 27     
            ora ($ec,x)        ; $a554: 01 ec     
            .hex 03 ac         ; $a556: 03 ac     Invalid Opcode - SLO ($ac,x)
            .hex f3 c3         ; $a558: f3 c3     Invalid Opcode - ISC ($c3),y
            .hex 03 78         ; $a55a: 03 78     Invalid Opcode - SLO ($78,x)
            .hex e2 94         ; $a55c: e2 94     Invalid Opcode - NOP #$94
            .hex 43 47         ; $a55e: 43 47     Invalid Opcode - SRE ($47,x)
            .hex f3 74         ; $a560: f3 74     Invalid Opcode - ISC ($74),y
            .hex 43 47         ; $a562: 43 47     Invalid Opcode - SRE ($47,x)
            .hex fb 74 43      ; $a564: fb 74 43  Invalid Opcode - ISC $4374,y
            bit $4cf1          ; $a567: 2c f1 4c  
            .hex 63 47         ; $a56a: 63 47     Invalid Opcode - RRA ($47,x)
            brk                ; $a56c: 00        
            .hex 57 21         ; $a56d: 57 21     Invalid Opcode - SRE $21,x
            .hex 5c 01 7c      ; $a56f: 5c 01 7c  Invalid Opcode - NOP $7c01,x
            .hex 72            ; $a572: 72        Invalid Opcode - KIL 
            and __ecf1,y       ; $a573: 39 f1 ec  
            .hex 02            ; $a576: 02        Invalid Opcode - KIL 
            jmp __d881         ; $a577: 4c 81 d8  

;-------------------------------------------------------------------------------
            .hex 62            ; $a57a: 62        Invalid Opcode - KIL 
            cpx $0d01          ; $a57b: ec 01 0d  
            ora $380f          ; $a57e: 0d 0f 38  
            .hex c7 07         ; $a581: c7 07     Invalid Opcode - DCP $07
            sbc $1d4a          ; $a583: ed 4a 1d  
            cmp ($5f,x)        ; $a586: c1 5f     
            rol $fd            ; $a588: 26 fd     
            .hex 54 21         ; $a58a: 54 21     Invalid Opcode - NOP $21,x
            .hex 0f 26 a7      ; $a58c: 0f 26 a7  Invalid Opcode - SLO __a726
            .hex 22            ; $a58f: 22        Invalid Opcode - KIL 
            .hex 37 fb         ; $a590: 37 fb     Invalid Opcode - RLA $fb,x
            .hex 73 20         ; $a592: 73 20     Invalid Opcode - RRA ($20),y
            .hex 83 07         ; $a594: 83 07     Invalid Opcode - SAX ($07,x)
            .hex 87 02         ; $a596: 87 02     Invalid Opcode - SAX $02
            .hex 93 20         ; $a598: 93 20     Invalid Opcode - AHX ($20),y
            .hex c7 73         ; $a59a: c7 73     Invalid Opcode - DCP $73
            .hex 04 f1         ; $a59c: 04 f1     Invalid Opcode - NOP $f1
            asl $31            ; $a59e: 06 31     
            and $5971,y        ; $a5a0: 39 71 59  
            adc ($e7),y        ; $a5a3: 71 e7     
            .hex 73 37         ; $a5a5: 73 37     Invalid Opcode - RRA ($37),y
            ldy #$47           ; $a5a7: a0 47     
            .hex 04 86         ; $a5a9: 04 86     Invalid Opcode - NOP $86
            .hex 7c e5 71      ; $a5ab: 7c e5 71  Invalid Opcode - NOP $71e5,x
            .hex e7 31         ; $a5ae: e7 31     Invalid Opcode - ISC $31
            .hex 33 a4         ; $a5b0: 33 a4     Invalid Opcode - RLA ($a4),y
            and __a971,y       ; $a5b2: 39 71 a9  
            adc ($d3),y        ; $a5b5: 71 d3     
            .hex 23 08         ; $a5b7: 23 08     Invalid Opcode - RLA ($08,x)
            .hex f2            ; $a5b9: f2        Invalid Opcode - KIL 
            .hex 13 05         ; $a5ba: 13 05     Invalid Opcode - SLO ($05),y
            .hex 27 02         ; $a5bc: 27 02     Invalid Opcode - RLA $02
            eor #$71           ; $a5be: 49 71     
            adc $75,x          ; $a5c0: 75 75     
            inx                ; $a5c2: e8        
            .hex 72            ; $a5c3: 72        Invalid Opcode - KIL 
            .hex 67 f3         ; $a5c4: 67 f3     Invalid Opcode - RRA $f3
            sta __e771,y       ; $a5c6: 99 71 e7  
            jsr $72f4          ; $a5c9: 20 f4 72  
            .hex f7 31         ; $a5cc: f7 31     Invalid Opcode - ISC $31,x
            .hex 17 a0         ; $a5ce: 17 a0     Invalid Opcode - SLO $a0,x
            .hex 33 20         ; $a5d0: 33 20     Invalid Opcode - RLA ($20),y
            and $7371,y        ; $a5d2: 39 71 73  
            plp                ; $a5d5: 28        
            ldy $3905,x        ; $a5d6: bc 05 39  
            sbc ($79),y        ; $a5d9: f1 79     
            adc ($a6),y        ; $a5db: 71 a6     
            and ($c3,x)        ; $a5dd: 21 c3     
            asl $d3            ; $a5df: 06 d3     
            jsr $00dc          ; $a5e1: 20 dc 00  
            .hex fc 00 07      ; $a5e4: fc 00 07  Invalid Opcode - NOP $0700,x
            ldx #$13           ; $a5e7: a2 13     
            and ($5f,x)        ; $a5e9: 21 5f     
            .hex 32            ; $a5eb: 32        Invalid Opcode - KIL 
            sty __9800         ; $a5ec: 8c 00 98  
            .hex 7a            ; $a5ef: 7a        Invalid Opcode - NOP 
            .hex c7 63         ; $a5f0: c7 63     Invalid Opcode - DCP $63
            cmp $0361,y        ; $a5f2: d9 61 03  
            ldx #$07           ; $a5f5: a2 07     
            .hex 22            ; $a5f7: 22        Invalid Opcode - KIL 
            .hex 74 72         ; $a5f8: 74 72     Invalid Opcode - NOP $72,x
            .hex 77 31         ; $a5fa: 77 31     Invalid Opcode - RRA $31,x
            .hex e7 73         ; $a5fc: e7 73     Invalid Opcode - ISC $73
            and $58f1,y        ; $a5fe: 39 f1 58  
            .hex 72            ; $a601: 72        Invalid Opcode - KIL 
            .hex 77 73         ; $a602: 77 73     Invalid Opcode - RRA $73,x
            cld                ; $a604: d8        
            .hex 72            ; $a605: 72        Invalid Opcode - KIL 
__a606:     .hex 7f b1 97      ; $a606: 7f b1 97  Invalid Opcode - RRA __97b1,x
            .hex 73 b6         ; $a609: 73 b6     Invalid Opcode - RRA ($b6),y
            .hex 64 c5         ; $a60b: 64 c5     Invalid Opcode - NOP $c5
            adc $d4            ; $a60d: 65 d4     
            ror $e3            ; $a60f: 66 e3     
            .hex 67 f3         ; $a611: 67 f3     Invalid Opcode - RRA $f3
            .hex 67 8d         ; $a613: 67 8d     Invalid Opcode - RRA $8d
            cmp ($cf,x)        ; $a615: c1 cf     
            rol $fd            ; $a617: 26 fd     
            .hex 52            ; $a619: 52        Invalid Opcode - KIL 
            and ($0f),y        ; $a61a: 31 0f     
            jsr $666e          ; $a61c: 20 6e 66  
            .hex 07 81         ; $a61f: 07 81     Invalid Opcode - SLO $81
            rol $01,x          ; $a621: 36 01     
            ror $00            ; $a623: 66 00     
            .hex a7 22         ; $a625: a7 22     Invalid Opcode - LAX $22
            php                ; $a627: 08        
            .hex f2            ; $a628: f2        Invalid Opcode - KIL 
            .hex 67 7b         ; $a629: 67 7b     Invalid Opcode - RRA $7b
            .hex dc 02 98      ; $a62b: dc 02 98  Invalid Opcode - NOP __9802,x
            .hex f2            ; $a62e: f2        Invalid Opcode - KIL 
            .hex d7 20         ; $a62f: d7 20     Invalid Opcode - DCP $20,x
            and __9ff1,y       ; $a631: 39 f1 9f  
            .hex 33 dc         ; $a634: 33 dc     Invalid Opcode - RLA ($dc),y
            .hex 27 dc         ; $a636: 27 dc     Invalid Opcode - RLA $dc
            .hex 57 23         ; $a638: 57 23     Invalid Opcode - SRE $23,x
            .hex 83 57         ; $a63a: 83 57     Invalid Opcode - SAX ($57,x)
            .hex 63 6c         ; $a63c: 63 6c     Invalid Opcode - RRA ($6c,x)
            eor ($87),y        ; $a63e: 51 87     
            .hex 63 99         ; $a640: 63 99     Invalid Opcode - RRA ($99,x)
            adc ($a3,x)        ; $a642: 61 a3     
            asl $b3            ; $a644: 06 b3     
            and ($77,x)        ; $a646: 21 77     
            .hex f3 f3         ; $a648: f3 f3     Invalid Opcode - ISC ($f3),y
            and ($f7,x)        ; $a64a: 21 f7     
            rol                ; $a64c: 2a        
            .hex 13 81         ; $a64d: 13 81     Invalid Opcode - SLO ($81),y
            .hex 23 22         ; $a64f: 23 22     Invalid Opcode - RLA ($22,x)
            .hex 53 00         ; $a651: 53 00     Invalid Opcode - SRE ($00),y
            .hex 63 22         ; $a653: 63 22     Invalid Opcode - RRA ($22,x)
            sbc #$0b           ; $a655: e9 0b     
            .hex 0c 83 13      ; $a657: 0c 83 13  Invalid Opcode - NOP $1383
            and ($16,x)        ; $a65a: 21 16     
            .hex 22            ; $a65c: 22        Invalid Opcode - KIL 
            .hex 33 05         ; $a65d: 33 05     Invalid Opcode - RLA ($05),y
            .hex 8f 35 ec      ; $a65f: 8f 35 ec  Invalid Opcode - SAX __ec35
            ora ($63,x)        ; $a662: 01 63     
            ldy #$67           ; $a664: a0 67     
            jsr $0173          ; $a666: 20 73 01  
            .hex 77 01         ; $a669: 77 01     Invalid Opcode - RRA $01,x
            .hex 83 20         ; $a66b: 83 20     Invalid Opcode - SAX ($20,x)
            .hex 87 20         ; $a66d: 87 20     Invalid Opcode - SAX $20
            .hex b3 20         ; $a66f: b3 20     Invalid Opcode - LAX ($20),y
            .hex b7 20         ; $a671: b7 20     Invalid Opcode - LAX $20,y
            .hex c3 01         ; $a673: c3 01     Invalid Opcode - DCP ($01,x)
            .hex c7 00         ; $a675: c7 00     Invalid Opcode - DCP $00
            .hex d3 20         ; $a677: d3 20     Invalid Opcode - DCP ($20),y
            .hex d7 20         ; $a679: d7 20     Invalid Opcode - DCP $20,x
            .hex 67 a0         ; $a67b: 67 a0     Invalid Opcode - RRA $a0
            .hex 77 07         ; $a67d: 77 07     Invalid Opcode - RRA $07,x
            .hex 87 22         ; $a67f: 87 22     Invalid Opcode - SAX $22
            inx                ; $a681: e8        
            .hex 62            ; $a682: 62        Invalid Opcode - KIL 
            sbc $65,x          ; $a683: f5 65     
            .hex 1c 82 7f      ; $a685: 1c 82 7f  Invalid Opcode - NOP $7f82,x
            sec                ; $a688: 38        
            sta __cfc1         ; $a689: 8d c1 cf  
            rol $fd            ; $a68c: 26 fd     
            bvc __a6b1         ; $a68e: 50 21     
            .hex 07 81         ; $a690: 07 81     Invalid Opcode - SLO $81
            .hex 47 24         ; $a692: 47 24     Invalid Opcode - SRE $24
            .hex 57 00         ; $a694: 57 00     Invalid Opcode - SRE $00,x
            .hex 63 01         ; $a696: 63 01     Invalid Opcode - RRA ($01,x)
            .hex 77 01         ; $a698: 77 01     Invalid Opcode - RRA $01,x
            cmp #$71           ; $a69a: c9 71     
            pla                ; $a69c: 68        
            .hex f2            ; $a69d: f2        Invalid Opcode - KIL 
            .hex e7 73         ; $a69e: e7 73     Invalid Opcode - ISC $73
            .hex 97 fb         ; $a6a0: 97 fb     Invalid Opcode - SAX $fb,y
            asl $83            ; $a6a2: 06 83     
            .hex 5c 01 d7      ; $a6a4: 5c 01 d7  Invalid Opcode - NOP __d701,x
            .hex 22            ; $a6a7: 22        Invalid Opcode - KIL 
            .hex e7 00         ; $a6a8: e7 00     Invalid Opcode - ISC $00
            .hex 03 a7         ; $a6aa: 03 a7     Invalid Opcode - SLO ($a7,x)
            jmp (__b302)       ; $a6ac: 6c 02 b3  

;-------------------------------------------------------------------------------
            .hex 22            ; $a6af: 22        Invalid Opcode - KIL 
            .hex e3            ; $a6b0: e3        Suspected data
__a6b1:     ora ($e7,x)        ; $a6b1: 01 e7     
            .hex 07 47         ; $a6b3: 07 47     Invalid Opcode - SLO $47
            ldy #$57           ; $a6b5: a0 57     
            asl $a7            ; $a6b7: 06 a7     
            ora ($d3,x)        ; $a6b9: 01 d3     
            brk                ; $a6bb: 00        
            .hex d7 01         ; $a6bc: d7 01     Invalid Opcode - DCP $01,x
            .hex 07 81         ; $a6be: 07 81     Invalid Opcode - SLO $81
            .hex 67 20         ; $a6c0: 67 20     Invalid Opcode - RRA $20
            .hex 93 22         ; $a6c2: 93 22     Invalid Opcode - AHX ($22),y
            .hex 03 a3         ; $a6c4: 03 a3     Invalid Opcode - SLO ($a3,x)
            .hex 1c 61 17      ; $a6c6: 1c 61 17  Invalid Opcode - NOP $1761,x
            and ($6f,x)        ; $a6c9: 21 6f     
            .hex 33 c7         ; $a6cb: 33 c7     Invalid Opcode - RLA ($c7),y
            .hex 63 d8         ; $a6cd: 63 d8     Invalid Opcode - RRA ($d8,x)
            .hex 62            ; $a6cf: 62        Invalid Opcode - KIL 
            sbc #$61           ; $a6d0: e9 61     
            .hex fa            ; $a6d2: fa        Invalid Opcode - NOP 
            rts                ; $a6d3: 60        

;-------------------------------------------------------------------------------
            .hex 4f b3 87      ; $a6d4: 4f b3 87  Invalid Opcode - SRE __87b3
            .hex 63 9c         ; $a6d7: 63 9c     Invalid Opcode - RRA ($9c,x)
            .hex 01            ; $a6d9: 01        Suspected data
__a6da:     .hex b7 63         ; $a6da: b7 63     Invalid Opcode - LAX $63,y
            iny                ; $a6dc: c8        
            .hex 62            ; $a6dd: 62        Invalid Opcode - KIL 
            cmp __ea61,y       ; $a6de: d9 61 ea  
            rts                ; $a6e1: 60        

;-------------------------------------------------------------------------------
            and __87f1,y       ; $a6e2: 39 f1 87  
            and ($a7,x)        ; $a6e5: 21 a7     
            ora ($b7,x)        ; $a6e7: 01 b7     
            jsr __f139         ; $a6e9: 20 39 f1  
            .hex 5f 38 6d      ; $a6ec: 5f 38 6d  Invalid Opcode - SRE $6d38,x
            cmp ($af,x)        ; $a6ef: c1 af     
            rol $fd            ; $a6f1: 26 fd     
            bcc __a706         ; $a6f3: 90 11     
            .hex 0f 26 fe      ; $a6f5: 0f 26 fe  Invalid Opcode - SLO __fe26
            bpl __a724         ; $a6f8: 10 2a     
            .hex 93 87         ; $a6fa: 93 87     Invalid Opcode - AHX ($87),y
            .hex 17 a3         ; $a6fc: 17 a3     Invalid Opcode - SLO $a3,x
            .hex 14 b2         ; $a6fe: 14 b2     Invalid Opcode - NOP $b2,x
            .hex 42            ; $a700: 42        Invalid Opcode - KIL 
            asl                ; $a701: 0a        
__a702:     .hex 92            ; $a702: 92        Invalid Opcode - KIL 
            ora $3640,y        ; $a703: 19 40 36  
__a706:     .hex 14 50         ; $a706: 14 50     Invalid Opcode - NOP $50,x
            eor ($82,x)        ; $a708: 41 82     
            asl $2b,x          ; $a70a: 16 2b     
            .hex 93 24         ; $a70c: 93 24     Invalid Opcode - AHX ($24),y
            eor ($bb,x)        ; $a70e: 41 bb     
            .hex 14 b8         ; $a710: 14 b8     Invalid Opcode - NOP $b8,x
            brk                ; $a712: 00        
            .hex c2 43         ; $a713: c2 43     Invalid Opcode - NOP #$43
            .hex c3 13         ; $a715: c3 13     Invalid Opcode - DCP ($13,x)
            .hex 1b 94 67      ; $a717: 1b 94 67  Invalid Opcode - SLO $6794,y
            .hex 12            ; $a71a: 12        Invalid Opcode - KIL 
            cpy $15            ; $a71b: c4 15     
            .hex 53 c1         ; $a71d: 53 c1     Invalid Opcode - SRE ($c1),y
            .hex d2            ; $a71f: d2        Invalid Opcode - KIL 
            eor ($12,x)        ; $a720: 41 12     
            .hex c1            ; $a722: c1        Suspected data
__a723:     .hex 29            ; $a723: 29        Suspected data
__a724:     .hex 13 85         ; $a724: 13 85     Invalid Opcode - SLO ($85),y
            .hex 17 1b         ; $a726: 17 1b     Invalid Opcode - SLO $1b,x
            .hex 92            ; $a728: 92        Invalid Opcode - KIL 
            .hex 1a            ; $a729: 1a        Invalid Opcode - NOP 
            .hex 42            ; $a72a: 42        Invalid Opcode - KIL 
            .hex 47 13         ; $a72b: 47 13     Invalid Opcode - SRE $13
            .hex 83 41         ; $a72d: 83 41     Invalid Opcode - SAX ($41,x)
            .hex a7 13         ; $a72f: a7 13     Invalid Opcode - LAX $13
            asl __a791         ; $a731: 0e 91 a7  
            .hex 63 b7         ; $a734: 63 b7     Invalid Opcode - RRA ($b7,x)
            .hex 63 c5         ; $a736: 63 c5     Invalid Opcode - RRA ($c5,x)
            adc $d5            ; $a738: 65 d5     
            adc $dd            ; $a73a: 65 dd     
            lsr                ; $a73c: 4a        
            .hex e3 67         ; $a73d: e3 67     Invalid Opcode - ISC ($67,x)
            .hex f3 67         ; $a73f: f3 67     Invalid Opcode - ISC ($67),y
            sta __aec1         ; $a741: 8d c1 ae  
            .hex 42            ; $a744: 42        Invalid Opcode - KIL 
            .hex df 20 fd      ; $a745: df 20 fd  Invalid Opcode - DCP __fd20,x
            bcc __a75b         ; $a748: 90 11     
            .hex 0f 26 6e      ; $a74a: 0f 26 6e  Invalid Opcode - SLO $6e26
            bpl __a6da         ; $a74d: 10 8b     
            .hex 17 af         ; $a74f: 17 af     Invalid Opcode - SLO $af,x
            .hex 32            ; $a751: 32        Invalid Opcode - KIL 
            cld                ; $a752: d8        
            .hex 62            ; $a753: 62        Invalid Opcode - KIL 
            inx                ; $a754: e8        
            .hex 62            ; $a755: 62        Invalid Opcode - KIL 
            .hex fc 3f ad      ; $a756: fc 3f ad  Invalid Opcode - NOP __ad3f,x
            iny                ; $a759: c8        
            sed                ; $a75a: f8        
__a75b:     .hex 64 0c         ; $a75b: 64 0c     Invalid Opcode - NOP $0c
            ldx $4343,y        ; $a75d: be 43 43  
            sed                ; $a760: f8        
            .hex 64 0c         ; $a761: 64 0c     Invalid Opcode - NOP $0c
            .hex bf 73 40      ; $a763: bf 73 40  Invalid Opcode - LAX $4073,y
            sty $40            ; $a766: 84 40     
            .hex 93 40         ; $a768: 93 40     Invalid Opcode - AHX ($40),y
            ldy $40            ; $a76a: a4 40     
            .hex b3 40         ; $a76c: b3 40     Invalid Opcode - LAX ($40),y
            sed                ; $a76e: f8        
            .hex 64 48         ; $a76f: 64 48     Invalid Opcode - NOP $48
            cpx $5c            ; $a771: e4 5c     
            and $4083,y        ; $a773: 39 83 40  
            .hex 92            ; $a776: 92        Invalid Opcode - KIL 
            eor ($b3,x)        ; $a777: 41 b3     
            rti                ; $a779: 40        

;-------------------------------------------------------------------------------
            sed                ; $a77a: f8        
            .hex 64 48         ; $a77b: 64 48     Invalid Opcode - NOP $48
            cpx $5c            ; $a77d: e4 5c     
            and $64f8,y        ; $a77f: 39 f8 64  
            .hex 13 c2         ; $a782: 13 c2     Invalid Opcode - SLO ($c2),y
            .hex 37 65         ; $a784: 37 65     Invalid Opcode - RLA $65,x
            jmp $6324          ; $a786: 4c 24 63  

;-------------------------------------------------------------------------------
            brk                ; $a789: 00        
            .hex 97 65         ; $a78a: 97 65     Invalid Opcode - SAX $65,y
            .hex c3 42         ; $a78c: c3 42     Invalid Opcode - DCP ($42,x)
            .hex 0b 97         ; $a78e: 0b 97     Invalid Opcode - ANC #$97
            .hex ac            ; $a790: ac        Suspected data
__a791:     .hex 32            ; $a791: 32        Invalid Opcode - KIL 
            sed                ; $a792: f8        
            .hex 64 0c         ; $a793: 64 0c     Invalid Opcode - NOP $0c
            ldx $4553,y        ; $a795: be 53 45  
            sta __f848,x       ; $a798: 9d 48 f8  
            .hex 64 2a         ; $a79b: 64 2a     Invalid Opcode - NOP $2a
            .hex e2 3c         ; $a79d: e2 3c     Invalid Opcode - NOP #$3c
            .hex 47 56         ; $a79f: 47 56     Invalid Opcode - SRE $56
            .hex 43 ba         ; $a7a1: 43 ba     Invalid Opcode - SRE ($ba,x)
            .hex 62            ; $a7a3: 62        Invalid Opcode - KIL 
            sed                ; $a7a4: f8        
            .hex 64 0c         ; $a7a5: 64 0c     Invalid Opcode - NOP $0c
            .hex b7 88         ; $a7a7: b7 88     Invalid Opcode - LAX $88,y
            .hex 64 bc         ; $a7a9: 64 bc     Invalid Opcode - NOP $bc
            and ($d4),y        ; $a7ab: 31 d4     
            eor $fc            ; $a7ad: 45 fc     
            and ($3c),y        ; $a7af: 31 3c     
            lda ($78),y        ; $a7b1: b1 78     
            .hex 64 8c         ; $a7b3: 64 8c     Invalid Opcode - NOP $8c
            sec                ; $a7b5: 38        
            .hex 0b 9c         ; $a7b6: 0b 9c     Invalid Opcode - ANC #$9c
            .hex 1a            ; $a7b8: 1a        Invalid Opcode - NOP 
            .hex 33 18         ; $a7b9: 33 18     Invalid Opcode - RLA ($18),y
            adc ($28,x)        ; $a7bb: 61 28     
            adc ($39,x)        ; $a7bd: 61 39     
            rts                ; $a7bf: 60        

;-------------------------------------------------------------------------------
            eor __ee4a,x       ; $a7c0: 5d 4a ee  
            ora ($0f),y        ; $a7c3: 11 0f     
            clv                ; $a7c5: b8        
            ora $3ec1,x        ; $a7c6: 1d c1 3e  
            .hex 42            ; $a7c9: 42        Invalid Opcode - KIL 
            .hex 6f 20 fd      ; $a7ca: 6f 20 fd  Invalid Opcode - RRA __fd20
            .hex 52            ; $a7cd: 52        Invalid Opcode - KIL 
            and ($0f),y        ; $a7ce: 31 0f     
            jsr $406e          ; $a7d0: 20 6e 40  
            .hex f7 20         ; $a7d3: f7 20     Invalid Opcode - ISC $20,x
            .hex 07 84         ; $a7d5: 07 84     Invalid Opcode - SLO $84
            .hex 17 20         ; $a7d7: 17 20     Invalid Opcode - SLO $20,x
            .hex 4f 34 c3      ; $a7d9: 4f 34 c3  Invalid Opcode - SRE __c334
            .hex 03 c7         ; $a7dc: 03 c7     Invalid Opcode - SLO ($c7,x)
            .hex 02            ; $a7de: 02        Invalid Opcode - KIL 
            .hex d3 22         ; $a7df: d3 22     Invalid Opcode - DCP ($22),y
            .hex 27 e3         ; $a7e1: 27 e3     Invalid Opcode - RLA $e3
            and __e761,y       ; $a7e3: 39 61 e7  
            .hex 73 5c         ; $a7e6: 73 5c     Invalid Opcode - RRA ($5c),y
            cpx $57            ; $a7e8: e4 57     
            brk                ; $a7ea: 00        
            jmp ($4773)        ; $a7eb: 6c 73 47  

;-------------------------------------------------------------------------------
            ldy #$53           ; $a7ee: a0 53     
            .hex 06            ; $a7f0: 06        Suspected data
__a7f1:     .hex 63 22         ; $a7f1: 63 22     Invalid Opcode - RRA ($22,x)
            .hex a7 73         ; $a7f3: a7 73     Invalid Opcode - LAX $73
            .hex fc 73 13      ; $a7f5: fc 73 13  Invalid Opcode - NOP $1373,x
            lda ($33,x)        ; $a7f8: a1 33     
            ora $43            ; $a7fa: 05 43     
            and ($5c,x)        ; $a7fc: 21 5c     
            .hex 72            ; $a7fe: 72        Invalid Opcode - KIL 
            .hex c3 23         ; $a7ff: c3 23     Invalid Opcode - DCP ($23,x)
            cpy $7703          ; $a801: cc 03 77  
            .hex fb ac 02      ; $a804: fb ac 02  Invalid Opcode - ISC $02ac,y
            and __a7f1,y       ; $a807: 39 f1 a7  
            .hex 73 d3         ; $a80a: 73 d3     Invalid Opcode - RRA ($d3),y
            .hex 04 e8         ; $a80c: 04 e8     Invalid Opcode - NOP $e8
            .hex 72            ; $a80e: 72        Invalid Opcode - KIL 
            .hex e3 22         ; $a80f: e3 22     Invalid Opcode - ISC ($22,x)
            rol $f4            ; $a811: 26 f4     
            ldy __8c02,x       ; $a813: bc 02 8c  
            sta ($a8,x)        ; $a816: 81 a8     
            .hex 62            ; $a818: 62        Invalid Opcode - KIL 
            .hex 17 87         ; $a819: 17 87     Invalid Opcode - SLO $87,x
            .hex 43 24         ; $a81b: 43 24     Invalid Opcode - SRE ($24,x)
            .hex a7 01         ; $a81d: a7 01     Invalid Opcode - LAX $01
            .hex c3 04         ; $a81f: c3 04     Invalid Opcode - DCP ($04,x)
            php                ; $a821: 08        
            .hex f2            ; $a822: f2        Invalid Opcode - KIL 
            .hex 97 21         ; $a823: 97 21     Invalid Opcode - SAX $21,y
            .hex a3 02         ; $a825: a3 02     Invalid Opcode - LAX ($02,x)
            cmp #$0b           ; $a827: c9 0b     
            sbc ($69,x)        ; $a829: e1 69     
            sbc ($69),y        ; $a82b: f1 69     
            sta __cfc1         ; $a82d: 8d c1 cf  
            rol $fd            ; $a830: 26 fd     
            sec                ; $a832: 38        
            ora ($0f),y        ; $a833: 11 0f     
            rol $ad            ; $a835: 26 ad     
            rti                ; $a837: 40        

;-------------------------------------------------------------------------------
            and __fdc7,x       ; $a838: 3d c7 fd  
            sta $b1,x          ; $a83b: 95 b1     
            .hex 0f 26 0d      ; $a83d: 0f 26 0d  Invalid Opcode - SLO $0d26
            .hex 02            ; $a840: 02        Invalid Opcode - KIL 
            iny                ; $a841: c8        
            .hex 72            ; $a842: 72        Invalid Opcode - KIL 
            .hex 1c 81 38      ; $a843: 1c 81 38  Invalid Opcode - NOP $3881,x
            .hex 72            ; $a846: 72        Invalid Opcode - KIL 
            ora __9705         ; $a847: 0d 05 97  
            .hex 34 98         ; $a84a: 34 98     Invalid Opcode - NOP $98,x
            .hex 62            ; $a84c: 62        Invalid Opcode - KIL 
            .hex a3 20         ; $a84d: a3 20     Invalid Opcode - LAX ($20,x)
            .hex b3 06         ; $a84f: b3 06     Invalid Opcode - LAX ($06),y
            .hex c3 20         ; $a851: c3 20     Invalid Opcode - DCP ($20,x)
            cpy __f903         ; $a853: cc 03 f9  
            sta ($2c),y        ; $a856: 91 2c     
            sta ($48,x)        ; $a858: 81 48     
            .hex 62            ; $a85a: 62        Invalid Opcode - KIL 
            ora $3709          ; $a85b: 0d 09 37  
            .hex 63 47         ; $a85e: 63 47     Invalid Opcode - RRA ($47,x)
            .hex 03 57         ; $a860: 03 57     Invalid Opcode - SLO ($57,x)
            and ($8c,x)        ; $a862: 21 8c     
            .hex 02            ; $a864: 02        Invalid Opcode - KIL 
            cmp $79            ; $a865: c5 79     
            .hex c7 31         ; $a867: c7 31     Invalid Opcode - DCP $31
            sbc $3911,y        ; $a869: f9 11 39  
            sbc ($a9),y        ; $a86c: f1 a9     
            ora ($6f),y        ; $a86e: 11 6f     
            .hex b4            ; $a870: b4        Suspected data
__a871:     .hex d3 65         ; $a871: d3 65     Invalid Opcode - DCP ($65),y
            .hex e3 65         ; $a873: e3 65     Invalid Opcode - ISC ($65,x)
            adc __bfc1,x       ; $a875: 7d c1 bf  
            rol $fd            ; $a878: 26 fd     
            brk                ; $a87a: 00        
            cmp ($4c,x)        ; $a87b: c1 4c     
            brk                ; $a87d: 00        
            .hex f4 4f         ; $a87e: f4 4f     Invalid Opcode - NOP $4f,x
            ora $0202          ; $a880: 0d 02 02  
            .hex 42            ; $a883: 42        Invalid Opcode - KIL 
            .hex 43 4f         ; $a884: 43 4f     Invalid Opcode - SRE ($4f,x)
            .hex 52            ; $a886: 52        Invalid Opcode - KIL 
            .hex c2 de         ; $a887: c2 de     Invalid Opcode - NOP #$de
            brk                ; $a889: 00        
            .hex 5a            ; $a88a: 5a        Invalid Opcode - NOP 
            .hex c2 4d         ; $a88b: c2 4d     Invalid Opcode - NOP #$4d
            .hex c7 fd         ; $a88d: c7 fd     Invalid Opcode - DCP $fd
            bcc __a8e2         ; $a88f: 90 51     
            .hex 0f 26 ee      ; $a891: 0f 26 ee  Invalid Opcode - SLO __ee26
            bpl __a8a1         ; $a894: 10 0b     
            sty $33,x          ; $a896: 94 33     
            .hex 14 42         ; $a898: 14 42     Invalid Opcode - NOP $42,x
            .hex 42            ; $a89a: 42        Invalid Opcode - KIL 
            .hex 77 16         ; $a89b: 77 16     Invalid Opcode - RRA $16,x
            stx $44            ; $a89d: 86 44     
            .hex 02            ; $a89f: 02        Invalid Opcode - KIL 
            .hex 92            ; $a8a0: 92        Invalid Opcode - KIL 
__a8a1:     lsr                ; $a8a1: 4a        
            asl $69,x          ; $a8a2: 16 69     
            .hex 42            ; $a8a4: 42        Invalid Opcode - KIL 
            .hex 73 14         ; $a8a5: 73 14     Invalid Opcode - RRA ($14),y
            bcs __a8a9         ; $a8a7: b0 00     
__a8a9:     .hex c7 12         ; $a8a9: c7 12     Invalid Opcode - DCP $12
            ora $c0            ; $a8ab: 05 c0     
            .hex 1c 17 1f      ; $a8ad: 1c 17 1f  Invalid Opcode - NOP $1f17,x
            ora ($36),y        ; $a8b0: 11 36     
            .hex 12            ; $a8b2: 12        Invalid Opcode - KIL 
            .hex 8f 14 91      ; $a8b3: 8f 14 91  Invalid Opcode - SAX __9114
            rti                ; $a8b6: 40        

;-------------------------------------------------------------------------------
            .hex 1b 94 35      ; $a8b7: 1b 94 35  Invalid Opcode - SLO $3594,y
            .hex 12            ; $a8ba: 12        Invalid Opcode - KIL 
            .hex 34 42         ; $a8bb: 34 42     Invalid Opcode - NOP $42,x
            rts                ; $a8bd: 60        

;-------------------------------------------------------------------------------
            .hex 42            ; $a8be: 42        Invalid Opcode - KIL 
            adc ($12,x)        ; $a8bf: 61 12     
            .hex 87 12         ; $a8c1: 87 12     Invalid Opcode - SAX $12
            stx $40,y          ; $a8c3: 96 40     
            .hex a3 14         ; $a8c5: a3 14     Invalid Opcode - LAX ($14,x)
            .hex 1c 98 1f      ; $a8c7: 1c 98 1f  Invalid Opcode - NOP $1f98,x
            ora ($47),y        ; $a8ca: 11 47     
            .hex 12            ; $a8cc: 12        Invalid Opcode - KIL 
            .hex 9f 15 cc      ; $a8cd: 9f 15 cc  Invalid Opcode - AHX __cc15,y
            ora $cf,x          ; $a8d0: 15 cf     
            ora ($05),y        ; $a8d2: 11 05     
            cpy #$1f           ; $a8d4: c0 1f     
            ora $39,x          ; $a8d6: 15 39     
            .hex 12            ; $a8d8: 12        Invalid Opcode - KIL 
            .hex 7c 16 7f      ; $a8d9: 7c 16 7f  Invalid Opcode - NOP $7f16,x
            ora ($82),y        ; $a8dc: 11 82     
            rti                ; $a8de: 40        

;-------------------------------------------------------------------------------
            tya                ; $a8df: 98        
            .hex 12            ; $a8e0: 12        Invalid Opcode - KIL 
            .hex df            ; $a8e1: df        Suspected data
__a8e2:     ora $16,x          ; $a8e2: 15 16     
            cpy $17            ; $a8e4: c4 17     
            .hex 14 54         ; $a8e6: 14 54     Invalid Opcode - NOP $54,x
            .hex 12            ; $a8e8: 12        Invalid Opcode - KIL 
            .hex 9b            ; $a8e9: 9b        Invalid Opcode - TAS 
            asl $28,x          ; $a8ea: 16 28     
            sty $ce,x          ; $a8ec: 94 ce     
            ora ($3d,x)        ; $a8ee: 01 3d     
            cmp ($5e,x)        ; $a8f0: c1 5e     
            .hex 42            ; $a8f2: 42        Invalid Opcode - KIL 
            .hex 8f 20 fd      ; $a8f3: 8f 20 fd  Invalid Opcode - SAX __fd20
            .hex 97 11         ; $a8f6: 97 11     Invalid Opcode - SAX $11,y
            .hex 0f 26 fe      ; $a8f8: 0f 26 fe  Invalid Opcode - SLO __fe26
            bpl __a928         ; $a8fb: 10 2b     
            .hex 92            ; $a8fd: 92        Invalid Opcode - KIL 
            .hex 57 12         ; $a8fe: 57 12     Invalid Opcode - SRE $12,x
            .hex 8b 12         ; $a900: 8b 12     Invalid Opcode - XAA #$12
            cpy #$41           ; $a902: c0 41     
            .hex f7 13         ; $a904: f7 13     Invalid Opcode - ISC $13,x
            .hex 5b 92 69      ; $a906: 5b 92 69  Invalid Opcode - SRE $6992,y
            .hex 0b bb         ; $a909: 0b bb     Invalid Opcode - ANC #$bb
            .hex 12            ; $a90b: 12        Invalid Opcode - KIL 
            .hex b2            ; $a90c: b2        Invalid Opcode - KIL 
            lsr $19            ; $a90d: 46 19     
            .hex 93 71         ; $a90f: 93 71     Invalid Opcode - AHX ($71),y
            brk                ; $a911: 00        
            .hex 17 94         ; $a912: 17 94     Invalid Opcode - SLO $94,x
            .hex 7c 14 7f      ; $a914: 7c 14 7f  Invalid Opcode - NOP $7f14,x
            ora ($93),y        ; $a917: 11 93     
            eor ($bf,x)        ; $a919: 41 bf     
            ora $fc,x          ; $a91b: 15 fc     
            .hex 13 ff         ; $a91d: 13 ff     Invalid Opcode - SLO ($ff),y
            ora ($2f),y        ; $a91f: 11 2f     
            sta $50,x          ; $a921: 95 50     
            .hex 42            ; $a923: 42        Invalid Opcode - KIL 
            eor ($12),y        ; $a924: 51 12     
            cli                ; $a926: 58        
            .hex 14            ; $a927: 14        Suspected data
__a928:     ldx $12            ; $a928: a6 12     
            .hex db 12 1b      ; $a92a: db 12 1b  Invalid Opcode - DCP $1b12,y
            .hex 93 46         ; $a92d: 93 46     Invalid Opcode - AHX ($46),y
            .hex 43 7b         ; $a92f: 43 7b     Invalid Opcode - SRE ($7b,x)
            .hex 12            ; $a931: 12        Invalid Opcode - KIL 
            sta __b749         ; $a932: 8d 49 b7  
            .hex 14 1b         ; $a935: 14 1b     Invalid Opcode - NOP $1b,x
            sty $49,x          ; $a937: 94 49     
            .hex 0b bb         ; $a939: 0b bb     Invalid Opcode - ANC #$bb
            .hex 12            ; $a93b: 12        Invalid Opcode - KIL 
            .hex fc 13 ff      ; $a93c: fc 13 ff  Invalid Opcode - NOP __ff13,x
            .hex 12            ; $a93f: 12        Invalid Opcode - KIL 
            .hex 03 c1         ; $a940: 03 c1     Invalid Opcode - SLO ($c1,x)
            .hex 2f 15 43      ; $a942: 2f 15 43  Invalid Opcode - RLA $4315
            .hex 12            ; $a945: 12        Invalid Opcode - KIL 
            .hex 4b 13         ; $a946: 4b 13     Invalid Opcode - ALR #$13
            .hex 77 13         ; $a948: 77 13     Invalid Opcode - RRA $13,x
            sta $154a,x        ; $a94a: 9d 4a 15  
            cmp ($a1,x)        ; $a94d: c1 a1     
            eor ($c3,x)        ; $a94f: 41 c3     
            .hex 12            ; $a951: 12        Invalid Opcode - KIL 
            inc $7d01,x        ; $a952: fe 01 7d  
            cmp ($9e,x)        ; $a955: c1 9e     
            .hex 42            ; $a957: 42        Invalid Opcode - KIL 
            .hex cf 20 fd      ; $a958: cf 20 fd  Invalid Opcode - DCP __fd20
            .hex 52            ; $a95b: 52        Invalid Opcode - KIL 
            and ($0f,x)        ; $a95c: 21 0f     
            jsr $446e          ; $a95e: 20 6e 44  
            .hex 0c f1 4c      ; $a961: 0c f1 4c  Invalid Opcode - NOP $4cf1
            ora ($aa,x)        ; $a964: 01 aa     
            and $d9,x          ; $a966: 35 d9     
            .hex 34 ee         ; $a968: 34 ee     Invalid Opcode - NOP $ee,x
            jsr __b308         ; $a96a: 20 08 b3  
            .hex 37 32         ; $a96d: 37 32     Invalid Opcode - RLA $32,x
            .hex 43 04         ; $a96f: 43 04     Invalid Opcode - SRE ($04,x)
__a971:     lsr $5321          ; $a971: 4e 21 53  
            jsr $017c          ; $a974: 20 7c 01  
            .hex 97 21         ; $a977: 97 21     Invalid Opcode - SAX $21,y
            .hex b7 07         ; $a979: b7 07     Invalid Opcode - LAX $07,y
            .hex 9c 81 e7      ; $a97b: 9c 81 e7  Invalid Opcode - SHY __e781,x
            .hex 42            ; $a97e: 42        Invalid Opcode - KIL 
            .hex 5f b3 97      ; $a97f: 5f b3 97  Invalid Opcode - SRE __97b3,x
            .hex 63 ac         ; $a982: 63 ac     Invalid Opcode - RRA ($ac,x)
            .hex 02            ; $a984: 02        Invalid Opcode - KIL 
            cmp $41            ; $a985: c5 41     
            eor #$e0           ; $a987: 49 e0     
            cli                ; $a989: 58        
            adc ($76,x)        ; $a98a: 61 76     
            .hex 64 85         ; $a98c: 64 85     Invalid Opcode - NOP $85
            adc $94            ; $a98e: 65 94     
            ror $a4            ; $a990: 66 a4     
            .hex 22            ; $a992: 22        Invalid Opcode - KIL 
            ldx $03            ; $a993: a6 03     
            iny                ; $a995: c8        
            .hex 22            ; $a996: 22        Invalid Opcode - KIL 
            .hex dc 02 68      ; $a997: dc 02 68  Invalid Opcode - NOP $6802,x
            .hex f2            ; $a99a: f2        Invalid Opcode - KIL 
            stx $42,y          ; $a99b: 96 42     
            .hex 13 82         ; $a99d: 13 82     Invalid Opcode - SLO ($82),y
            .hex 17 02         ; $a99f: 17 02     Invalid Opcode - SLO $02,x
            .hex af 34 f6      ; $a9a1: af 34 f6  Invalid Opcode - LAX __f634
            and ($fc,x)        ; $a9a4: 21 fc     
            asl $26            ; $a9a6: 06 26     
            .hex 80 2a         ; $a9a8: 80 2a     Invalid Opcode - NOP #$2a
            bit $36            ; $a9aa: 24 36     
            ora ($8c,x)        ; $a9ac: 01 8c     
            brk                ; $a9ae: 00        
            .hex ff 35 4e      ; $a9af: ff 35 4e  Invalid Opcode - ISC $4e35,x
            ldy #$55           ; $a9b2: a0 55     
            and ($77,x)        ; $a9b4: 21 77     
            jsr $0787          ; $a9b6: 20 87 07  
            .hex 89 22         ; $a9b9: 89 22     Invalid Opcode - NOP #$22
            .hex ae 21         ; $a9bb: ae 21     Suspected data
__a9bd:     jmp __9f82         ; $a9bd: 4c 82 9f  

;-------------------------------------------------------------------------------
            .hex 34 ec         ; $a9c0: 34 ec     Invalid Opcode - NOP $ec,x
            ora ($03,x)        ; $a9c2: 01 03     
            .hex e7 13         ; $a9c4: e7 13     Invalid Opcode - ISC $13
            .hex 67 8d         ; $a9c6: 67 8d     Invalid Opcode - RRA $8d
            lsr                ; $a9c8: 4a        
            lda $0f41          ; $a9c9: ad 41 0f  
            ldx $fd            ; $a9cc: a6 fd     
            bpl __aa21         ; $a9ce: 10 51     
            jmp __c700         ; $a9d0: 4c 00 c7  

;-------------------------------------------------------------------------------
            .hex 12            ; $a9d3: 12        Invalid Opcode - KIL 
            dec $42            ; $a9d4: c6 42     
            .hex 03 92         ; $a9d6: 03 92     Invalid Opcode - SLO ($92,x)
            .hex 02            ; $a9d8: 02        Invalid Opcode - KIL 
            .hex 42            ; $a9d9: 42        Invalid Opcode - KIL 
            and #$12           ; $a9da: 29 12     
            .hex 63 12         ; $a9dc: 63 12     Invalid Opcode - RRA ($12,x)
            .hex 62            ; $a9de: 62        Invalid Opcode - KIL 
            .hex 42            ; $a9df: 42        Invalid Opcode - KIL 
            adc #$14           ; $a9e0: 69 14     
            lda $12            ; $a9e2: a5 12     
            ldy $42            ; $a9e4: a4 42     
            .hex e2 14         ; $a9e6: e2 14     Invalid Opcode - NOP #$14
            sbc ($44,x)        ; $a9e8: e1 44     
            sed                ; $a9ea: f8        
            asl $37,x          ; $a9eb: 16 37     
            cmp ($8f,x)        ; $a9ed: c1 8f     
            sec                ; $a9ef: 38        
            .hex 02            ; $a9f0: 02        Invalid Opcode - KIL 
            .hex bb 28 7a      ; $a9f1: bb 28 7a  Invalid Opcode - LAS $7a28,y
            pla                ; $a9f4: 68        
            .hex 7a            ; $a9f5: 7a        Invalid Opcode - NOP 
            tay                ; $a9f6: a8        
            .hex 7a            ; $a9f7: 7a        Invalid Opcode - NOP 
            cpx #$6a           ; $a9f8: e0 6a     
            beq __aa66         ; $a9fa: f0 6a     
            adc __fdc5         ; $a9fc: 6d c5 fd  
            .hex 92            ; $a9ff: 92        Invalid Opcode - KIL 
            and ($0f),y        ; $aa00: 31 0f     
            jsr $406e          ; $aa02: 20 6e 40  
            ora $3702          ; $aa05: 0d 02 37  
            .hex 73 ec         ; $aa08: 73 ec     Invalid Opcode - RRA ($ec),y
            brk                ; $aa0a: 00        
            .hex 0c 80 3c      ; $aa0b: 0c 80 3c  Invalid Opcode - NOP $3c80
            brk                ; $aa0e: 00        
            jmp (__9c00)       ; $aa0f: 6c 00 9c  

;-------------------------------------------------------------------------------
            brk                ; $aa12: 00        
            asl $c0            ; $aa13: 06 c0     
            .hex c7 73         ; $aa15: c7 73     Invalid Opcode - DCP $73
            asl $83            ; $aa17: 06 83     
            plp                ; $aa19: 28        
            .hex 72            ; $aa1a: 72        Invalid Opcode - KIL 
            stx $40,y          ; $aa1b: 96 40     
            .hex e7 73         ; $aa1d: e7 73     Invalid Opcode - ISC $73
            rol $c0            ; $aa1f: 26 c0     
__aa21:     .hex 87 7b         ; $aa21: 87 7b     Invalid Opcode - SAX $7b
__aa23:     .hex d2            ; $aa23: d2        Invalid Opcode - KIL 
            eor ($39,x)        ; $aa24: 41 39     
            sbc ($c8),y        ; $aa26: f1 c8     
            .hex f2            ; $aa28: f2        Invalid Opcode - KIL 
            .hex 97 e3         ; $aa29: 97 e3     Invalid Opcode - SAX $e3,y
            .hex a3 23         ; $aa2b: a3 23     Invalid Opcode - LAX ($23,x)
            .hex e7 02         ; $aa2d: e7 02     Invalid Opcode - ISC $02
            .hex e3 07         ; $aa2f: e3 07     Invalid Opcode - ISC ($07,x)
            .hex f3 22         ; $aa31: f3 22     Invalid Opcode - ISC ($22),y
            .hex 37 e3         ; $aa33: 37 e3     Invalid Opcode - RLA $e3,x
            .hex 9c 00 bc      ; $aa35: 9c 00 bc  Invalid Opcode - SHY __bc00,x
            brk                ; $aa38: 00        
            cpx $0c00          ; $aa39: ec 00 0c  
            .hex 80 3c         ; $aa3c: 80 3c     Invalid Opcode - NOP #$3c
            brk                ; $aa3e: 00        
            stx $21            ; $aa3f: 86 21     
            ldx $06            ; $aa41: a6 06     
            ldx $24,y          ; $aa43: b6 24     
            .hex 5c 80 7c      ; $aa45: 5c 80 7c  Invalid Opcode - NOP $7c80,x
            brk                ; $aa48: 00        
            .hex 9c 00 29      ; $aa49: 9c 00 29  Invalid Opcode - SHY $2900,x
            sbc ($dc,x)        ; $aa4c: e1 dc     
            ora $f6            ; $aa4e: 05 f6     
            eor ($dc,x)        ; $aa50: 41 dc     
            .hex 80 e8         ; $aa52: 80 e8     Invalid Opcode - NOP #$e8
            .hex 72            ; $aa54: 72        Invalid Opcode - KIL 
            .hex 0c 81 27      ; $aa55: 0c 81 27  Invalid Opcode - NOP $2781
            .hex 73 4c         ; $aa58: 73 4c     Invalid Opcode - RRA ($4c),y
            ora ($66,x)        ; $aa5a: 01 66     
            .hex 74 0d         ; $aa5c: 74 0d     Invalid Opcode - NOP $0d,x
            ora ($3f),y        ; $aa5e: 11 3f     
            .hex 35            ; $aa60: 35        Suspected data
__aa61:     ldx $41,y          ; $aa61: b6 41     
            bit $3682          ; $aa63: 2c 82 36  
__aa66:     rti                ; $aa66: 40        

;-------------------------------------------------------------------------------
            .hex 7c 02 86      ; $aa67: 7c 02 86  Invalid Opcode - NOP __8602,x
            rti                ; $aa6a: 40        

;-------------------------------------------------------------------------------
            sbc $3961,y        ; $aa6b: f9 61 39  
            sbc ($ac,x)        ; $aa6e: e1 ac     
            .hex 04 c6         ; $aa70: 04 c6     Invalid Opcode - NOP $c6
            eor ($0c,x)        ; $aa72: 41 0c     
            .hex 83 16         ; $aa74: 83 16     Invalid Opcode - SAX ($16,x)
            eor ($88,x)        ; $aa76: 41 88     
            .hex f2            ; $aa78: f2        Invalid Opcode - KIL 
            and $7cf1,y        ; $aa79: 39 f1 7c  
            brk                ; $aa7c: 00        
            .hex 89 61         ; $aa7d: 89 61     Invalid Opcode - NOP #$61
            .hex 9c 00 a7      ; $aa7f: 9c 00 a7  Invalid Opcode - SHY __a700,x
            .hex 63 bc         ; $aa82: 63 bc     Invalid Opcode - RRA ($bc,x)
            brk                ; $aa84: 00        
            cmp $65            ; $aa85: c5 65     
            .hex dc 00 e3      ; $aa87: dc 00 e3  Invalid Opcode - NOP __e300,x
            .hex 67 f3         ; $aa8a: 67 f3     Invalid Opcode - RRA $f3
            .hex 67 8d         ; $aa8c: 67 8d     Invalid Opcode - RRA $8d
            cmp ($cf,x)        ; $aa8e: c1 cf     
            rol $fd            ; $aa90: 26 fd     
            eor $b1,x          ; $aa92: 55 b1     
            .hex 0f 26 cf      ; $aa94: 0f 26 cf  Invalid Opcode - SLO __cf26
            .hex 33 07         ; $aa97: 33 07     Invalid Opcode - RLA ($07),y
            .hex b2            ; $aa99: b2        Invalid Opcode - KIL 
            ora $11,x          ; $aa9a: 15 11     
            .hex 52            ; $aa9c: 52        Invalid Opcode - KIL 
            .hex 42            ; $aa9d: 42        Invalid Opcode - KIL 
            sta __ac0b,y       ; $aa9e: 99 0b ac  
            .hex 02            ; $aaa1: 02        Invalid Opcode - KIL 
            .hex d3 24         ; $aaa2: d3 24     Invalid Opcode - DCP ($24),y
            dec $42,x          ; $aaa4: d6 42     
            .hex d7 25         ; $aaa6: d7 25     Invalid Opcode - DCP $25,x
            .hex 23 84         ; $aaa8: 23 84     Invalid Opcode - RLA ($84,x)
            .hex cf 33 07      ; $aaaa: cf 33 07  Invalid Opcode - DCP $0733
            .hex e3 19         ; $aaad: e3 19     Invalid Opcode - ISC ($19,x)
            adc ($78,x)        ; $aaaf: 61 78     
            .hex 7a            ; $aab1: 7a        Invalid Opcode - NOP 
            .hex ef 33 2c      ; $aab2: ef 33 2c  Invalid Opcode - ISC $2c33
            sta ($46,x)        ; $aab5: 81 46     
            .hex 64            ; $aab7: 64        Suspected data
__aab8:     eor $65,x          ; $aab8: 55 65     
            adc $65            ; $aaba: 65 65     
            cpx $4774          ; $aabc: ec 74 47  
            .hex 82 53         ; $aabf: 82 53     Invalid Opcode - NOP #$53
            ora $63            ; $aac1: 05 63     
            and ($62,x)        ; $aac3: 21 62     
            eor ($96,x)        ; $aac5: 41 96     
            .hex 22            ; $aac7: 22        Invalid Opcode - KIL 
            txs                ; $aac8: 9a        
            eor ($cc,x)        ; $aac9: 41 cc     
            .hex 03 b9         ; $aacb: 03 b9     Invalid Opcode - SLO ($b9,x)
            sta ($39),y        ; $aacd: 91 39     
            sbc ($63),y        ; $aacf: f1 63     
            rol $67            ; $aad1: 26 67     
            .hex 27 d3         ; $aad3: 27 d3     Invalid Opcode - RLA $d3
            asl $fc            ; $aad5: 06 fc     
            ora ($18,x)        ; $aad7: 01 18     
            .hex e2 d9         ; $aad9: e2 d9     Invalid Opcode - NOP #$d9
            .hex 07 e9         ; $aadb: 07 e9     Invalid Opcode - SLO $e9
            .hex 04 0c         ; $aadd: 04 0c     Invalid Opcode - NOP $0c
            stx $37            ; $aadf: 86 37     
            .hex 22            ; $aae1: 22        Invalid Opcode - KIL 
            .hex 93 24         ; $aae2: 93 24     Invalid Opcode - AHX ($24),y
            .hex 87 84         ; $aae4: 87 84     Invalid Opcode - SAX $84
            ldy __c202         ; $aae6: ac 02 c2  
            eor ($c3,x)        ; $aae9: 41 c3     
            .hex 23 d9         ; $aaeb: 23 d9     Invalid Opcode - RLA ($d9,x)
__aaed:     adc ($fc),y        ; $aaed: 71 fc     
            ora ($7f,x)        ; $aaef: 01 7f     
            lda ($9c),y        ; $aaf1: b1 9c     
            brk                ; $aaf3: 00        
            .hex a7 63         ; $aaf4: a7 63     Invalid Opcode - LAX $63
            ldx $64,y          ; $aaf6: b6 64     
            cpy __d400         ; $aaf8: cc 00 d4  
            ror $e3            ; $aafb: 66 e3     
            .hex 67 f3         ; $aafd: 67 f3     Invalid Opcode - RRA $f3
            .hex 67 8d         ; $aaff: 67 8d     Invalid Opcode - RRA $8d
            cmp ($cf,x)        ; $ab01: c1 cf     
            rol $fd            ; $ab03: 26 fd     
            bvc __aab8         ; $ab05: 50 b1     
            .hex 0f 26 fc      ; $ab07: 0f 26 fc  Invalid Opcode - SLO __fc26
            brk                ; $ab0a: 00        
            .hex 1f b3 5c      ; $ab0b: 1f b3 5c  Invalid Opcode - SLO $5cb3,x
            brk                ; $ab0e: 00        
            adc $65            ; $ab0f: 65 65     
            .hex 74 66         ; $ab11: 74 66     Invalid Opcode - NOP $66,x
            .hex 83 67         ; $ab13: 83 67     Invalid Opcode - SAX ($67,x)
            .hex 93 67         ; $ab15: 93 67     Invalid Opcode - AHX ($67),y
            .hex dc 73 4c      ; $ab17: dc 73 4c  Invalid Opcode - NOP $4c73,x
            .hex 80 b3         ; $ab1a: 80 b3     Invalid Opcode - NOP #$b3
            jsr $0bc9          ; $ab1c: 20 c9 0b  
            .hex c3 08         ; $ab1f: c3 08     Invalid Opcode - DCP ($08,x)
            .hex d3 2f         ; $ab21: d3 2f     Invalid Opcode - DCP ($2f),y
__ab23:     .hex dc 00 2c      ; $ab23: dc 00 2c  Invalid Opcode - NOP $2c00,x
            .hex 80 4c         ; $ab26: 80 4c     Invalid Opcode - NOP #$4c
            brk                ; $ab28: 00        
            sty __d300         ; $ab29: 8c 00 d3  
            rol $4aed          ; $ab2c: 2e ed 4a  
            .hex fc 00 d7      ; $ab2f: fc 00 d7  Invalid Opcode - NOP __d700,x
            lda ($ec,x)        ; $ab32: a1 ec     
            ora ($4c,x)        ; $ab34: 01 4c     
            .hex 80 59         ; $ab36: 80 59     Invalid Opcode - NOP #$59
            ora ($d8),y        ; $ab38: 11 d8     
            ora ($da),y        ; $ab3a: 11 da     
            bpl __ab75         ; $ab3c: 10 37     
            ldy #$47           ; $ab3e: a0 47     
            .hex 04 99         ; $ab40: 04 99     Invalid Opcode - NOP $99
            ora ($e7),y        ; $ab42: 11 e7     
            and ($3a,x)        ; $ab44: 21 3a     
            bcc __abaf         ; $ab46: 90 67     
            jsr $1076          ; $ab48: 20 76 10  
            .hex 77 60         ; $ab4b: 77 60     Invalid Opcode - RRA $60,x
            .hex 87 07         ; $ab4d: 87 07     Invalid Opcode - SAX $07
            cld                ; $ab4f: d8        
            .hex 12            ; $ab50: 12        Invalid Opcode - KIL 
            and __acf1,y       ; $ab51: 39 f1 ac  
            brk                ; $ab54: 00        
            sbc #$71           ; $ab55: e9 71     
            .hex 0c 80 2c      ; $ab57: 0c 80 2c  Invalid Opcode - NOP $2c80
            brk                ; $ab5a: 00        
            jmp __c705         ; $ab5b: 4c 05 c7  

;-------------------------------------------------------------------------------
            .hex 7b 39 f1      ; $ab5e: 7b 39 f1  Invalid Opcode - RRA __f139,y
            cpx __f900         ; $ab61: ec 00 f9  
            ora ($0c),y        ; $ab64: 11 0c     
            .hex 82 6f         ; $ab66: 82 6f     Invalid Opcode - NOP #$6f
            .hex 34 f8         ; $ab68: 34 f8     Invalid Opcode - NOP $f8,x
            ora ($fa),y        ; $ab6a: 11 fa     
;            bpl __aaed         ; $ab6c: 10 7f     
; MODIFICATION
            .hex 10 7f         ; $ab6c: 10 7f     
            .hex b2            ; $ab6e: b2        Invalid Opcode - KIL 
            ldy __b600         ; $ab6f: ac 00 b6  
            .hex 64 cc         ; $ab72: 64 cc     Invalid Opcode - NOP $cc
            .hex 01            ; $ab74: 01        Suspected data
__ab75:     .hex e3 67         ; $ab75: e3 67     Invalid Opcode - ISC ($67,x)
            .hex f3 67         ; $ab77: f3 67     Invalid Opcode - ISC ($67),y
            sta __cfc1         ; $ab79: 8d c1 cf  
            rol $fd            ; $ab7c: 26 fd     
            .hex 52            ; $ab7e: 52        Invalid Opcode - KIL 
            .hex b1            ; $ab7f: b1        Suspected data
__ab80:     .hex 0f 20 6e      ; $ab80: 0f 20 6e  Invalid Opcode - SLO $6e20
            eor $39            ; $ab83: 45 39     
            sta ($b3),y        ; $ab85: 91 b3     
            .hex 04 c3         ; $ab87: 04 c3     Invalid Opcode - NOP $c3
            and ($c8,x)        ; $ab89: 21 c8     
            ora ($ca),y        ; $ab8b: 11 ca     
            bpl __abd8         ; $ab8d: 10 49     
            sta ($7c),y        ; $ab8f: 91 7c     
            .hex 73 e8         ; $ab91: 73 e8     Invalid Opcode - RRA ($e8),y
            .hex 12            ; $ab93: 12        Invalid Opcode - KIL 
            dey                ; $ab94: 88        
            sta ($8a),y        ; $ab95: 91 8a     
            bpl __ab80         ; $ab97: 10 e7     
            and ($05,x)        ; $ab99: 21 05     
            sta ($07),y        ; $ab9b: 91 07     
            bmi __abb6         ; $ab9d: 30 17     
            .hex 07 27         ; $ab9f: 07 27     Invalid Opcode - SLO $27
            jsr $1149          ; $aba1: 20 49 11  
            .hex 9c 01 c8      ; $aba4: 9c 01 c8  Invalid Opcode - SHY __c801,x
            .hex 72            ; $aba7: 72        Invalid Opcode - KIL 
            .hex 23 a6         ; $aba8: 23 a6     Invalid Opcode - RLA ($a6,x)
            .hex 27 26         ; $abaa: 27 26     Invalid Opcode - RLA $26
            .hex d3 03         ; $abac: d3 03     Invalid Opcode - DCP ($03),y
            cld                ; $abae: d8        
__abaf:     .hex 7a            ; $abaf: 7a        Invalid Opcode - NOP 
            .hex 89 91         ; $abb0: 89 91     Invalid Opcode - NOP #$91
            cld                ; $abb2: d8        
            .hex 72            ; $abb3: 72        Invalid Opcode - KIL 
            .hex 39 f1         ; $abb4: 39 f1     Suspected data
__abb6:     lda #$11           ; $abb6: a9 11     
            ora #$f1           ; $abb8: 09 f1     
            .hex 63 24         ; $abba: 63 24     Invalid Opcode - RRA ($24,x)
            .hex 67 24         ; $abbc: 67 24     Invalid Opcode - RRA $24
            cld                ; $abbe: d8        
            .hex 62            ; $abbf: 62        Invalid Opcode - KIL 
            plp                ; $abc0: 28        
            sta ($2a),y        ; $abc1: 91 2a     
            bpl __ac1b         ; $abc3: 10 56     
            and ($70,x)        ; $abc5: 21 70     
            .hex 04 79         ; $abc7: 04 79     Invalid Opcode - NOP $79
            .hex 0b 8c         ; $abc9: 0b 8c     Invalid Opcode - ANC #$8c
            brk                ; $abcb: 00        
            sty $21,x          ; $abcc: 94 21     
            .hex 9f 35 2f      ; $abce: 9f 35 2f  Invalid Opcode - AHX $2f35,y
            clv                ; $abd1: b8        
            and $7fc1,x        ; $abd2: 3d c1 7f  
            rol $fd            ; $abd5: 26 fd     
            .hex 06            ; $abd7: 06        Suspected data
__abd8:     cmp ($4c,x)        ; $abd8: c1 4c     
            brk                ; $abda: 00        
            .hex f4 4f         ; $abdb: f4 4f     Invalid Opcode - NOP $4f,x
            ora $0602          ; $abdd: 0d 02 06  
            jsr $4f24          ; $abe0: 20 24 4f  
            and $a0,x          ; $abe3: 35 a0     
            rol $20,x          ; $abe5: 36 20     
            .hex 53 46         ; $abe7: 53 46     Invalid Opcode - SRE ($46),y
            cmp $20,x          ; $abe9: d5 20     
            dec $20,x          ; $abeb: d6 20     
            .hex 34 a1         ; $abed: 34 a1     Invalid Opcode - NOP $a1,x
            .hex 73 49         ; $abef: 73 49     Invalid Opcode - RRA ($49),y
            .hex 74 20         ; $abf1: 74 20     Invalid Opcode - NOP $20,x
            sty $20,x          ; $abf3: 94 20     
            ldy $20,x          ; $abf5: b4 20     
            .hex d4 20         ; $abf7: d4 20     Invalid Opcode - NOP $20,x
            .hex f4 20         ; $abf9: f4 20     Invalid Opcode - NOP $20,x
            rol $5980          ; $abfb: 2e 80 59  
            .hex 42            ; $abfe: 42        Invalid Opcode - KIL 
            eor __fdc7         ; $abff: 4d c7 fd  
            stx $31,y          ; $ac02: 96 31     
            .hex 0f 26 0d      ; $ac04: 0f 26 0d  Invalid Opcode - SLO $0d26
            .hex 03 1a         ; $ac07: 03 1a     Invalid Opcode - SLO ($1a,x)
            rts                ; $ac09: 60        

;-------------------------------------------------------------------------------
            .hex 77            ; $ac0a: 77        Suspected data
__ac0b:     .hex 42            ; $ac0b: 42        Invalid Opcode - KIL 
__ac0c:     cpy $00            ; $ac0c: c4 00     
            iny                ; $ac0e: c8        
            .hex 62            ; $ac0f: 62        Invalid Opcode - KIL 
            lda __d3e1,y       ; $ac10: b9 e1 d3  
            asl $d7            ; $ac13: 06 d7     
            .hex 07 f9         ; $ac15: 07 f9     Invalid Opcode - SLO $f9
            adc ($0c,x)        ; $ac17: 61 0c     
            sta ($4e,x)        ; $ac19: 81 4e     
__ac1b:     lda ($8e),y        ; $ac1b: b1 8e     
            lda ($bc),y        ; $ac1d: b1 bc     
            ora ($e4,x)        ; $ac1f: 01 e4     
            bvc __ac0c         ; $ac21: 50 e9     
            adc ($0c,x)        ; $ac23: 61 0c     
            sta ($0d,x)        ; $ac25: 81 0d     
            asl                ; $ac27: 0a        
            sty $43            ; $ac28: 84 43     
            tya                ; $ac2a: 98        
            .hex 72            ; $ac2b: 72        Invalid Opcode - KIL 
            ora $0f0c          ; $ac2c: 0d 0c 0f  
            sec                ; $ac2f: 38        
            ora $5fc1,x        ; $ac30: 1d c1 5f  
            rol $fd            ; $ac33: 26 fd     
            pha                ; $ac35: 48        
            .hex 0f 0e 01      ; $ac36: 0f 0e 01  Invalid Opcode - SLO $010e
            lsr __a702,x       ; $ac39: 5e 02 a7  
            brk                ; $ac3c: 00        
            ldy $1a73,x        ; $ac3d: bc 73 1a  
            cpx #$39           ; $ac40: e0 39     
            adc ($58,x)        ; $ac42: 61 58     
            .hex 62            ; $ac44: 62        Invalid Opcode - KIL 
            .hex 77 63         ; $ac45: 77 63     Invalid Opcode - RRA $63,x
            .hex 97 63         ; $ac47: 97 63     Invalid Opcode - SAX $63,y
            clv                ; $ac49: b8        
            .hex 62            ; $ac4a: 62        Invalid Opcode - KIL 
            dec $07,x          ; $ac4b: d6 07     
            sed                ; $ac4d: f8        
            .hex 62            ; $ac4e: 62        Invalid Opcode - KIL 
            ora $75e1,y        ; $ac4f: 19 e1 75  
            .hex 52            ; $ac52: 52        Invalid Opcode - KIL 
            stx $40            ; $ac53: 86 40     
            .hex 87 50         ; $ac55: 87 50     Invalid Opcode - SAX $50
            sta $52,x          ; $ac57: 95 52     
            .hex 93 43         ; $ac59: 93 43     Invalid Opcode - AHX ($43),y
            lda $21            ; $ac5b: a5 21     
            cmp $52            ; $ac5d: c5 52     
            dec $40,x          ; $ac5f: d6 40     
            .hex d7 20         ; $ac61: d7 20     Invalid Opcode - DCP $20,x
            sbc $06            ; $ac63: e5 06     
            inc $51            ; $ac65: e6 51     
            rol $5e8d,x        ; $ac67: 3e 8d 5e  
            .hex 03 67         ; $ac6a: 03 67     Invalid Opcode - SLO ($67,x)
            .hex 52            ; $ac6c: 52        Invalid Opcode - KIL 
            .hex 77 52         ; $ac6d: 77 52     Invalid Opcode - RRA $52,x
            ror __9e02,x       ; $ac6f: 7e 02 9e  
            .hex 03 a6         ; $ac72: 03 a6     Invalid Opcode - SLO ($a6,x)
            .hex 43 a7         ; $ac74: 43 a7     Invalid Opcode - SRE ($a7,x)
            .hex 23 de         ; $ac76: 23 de     Invalid Opcode - RLA ($de,x)
            ora $fe            ; $ac78: 05 fe     
            .hex 02            ; $ac7a: 02        Invalid Opcode - KIL 
            asl $3383,x        ; $ac7b: 1e 83 33  
            .hex 54 46         ; $ac7e: 54 46     Invalid Opcode - NOP $46,x
            rti                ; $ac80: 40        

;-------------------------------------------------------------------------------
            .hex 47 21         ; $ac81: 47 21     Invalid Opcode - SRE $21
            lsr $04,x          ; $ac83: 56 04     
            lsr __8302,x       ; $ac85: 5e 02 83  
            .hex 54 93         ; $ac88: 54 93     Invalid Opcode - NOP $93,x
            .hex 52            ; $ac8a: 52        Invalid Opcode - KIL 
            stx $07,y          ; $ac8b: 96 07     
            .hex 97 50         ; $ac8d: 97 50     Invalid Opcode - SAX $50,y
            ldx __c703,y       ; $ac8f: be 03 c7  
            .hex 23 fe         ; $ac92: 23 fe     Invalid Opcode - RLA ($fe,x)
            .hex 02            ; $ac94: 02        Invalid Opcode - KIL 
            .hex 0c 82 43      ; $ac95: 0c 82 43  Invalid Opcode - NOP $4382
            eor $45            ; $ac98: 45 45     
            bit $46            ; $ac9a: 24 46     
            bit $90            ; $ac9c: 24 90     
            php                ; $ac9e: 08        
            sta $51,x          ; $ac9f: 95 51     
            sei                ; $aca1: 78        
            .hex fa            ; $aca2: fa        Invalid Opcode - NOP 
            .hex d7 73         ; $aca3: d7 73     Invalid Opcode - DCP $73,x
            and __8cf1,y       ; $aca5: 39 f1 8c  
            ora ($a8,x)        ; $aca8: 01 a8     
            .hex 52            ; $acaa: 52        Invalid Opcode - KIL 
            clv                ; $acab: b8        
            .hex 52            ; $acac: 52        Invalid Opcode - KIL 
            cpy $5f01          ; $acad: cc 01 5f  
            .hex b3 97         ; $acb0: b3 97     Invalid Opcode - LAX ($97),y
            .hex 63 9e         ; $acb2: 63 9e     Invalid Opcode - RRA ($9e,x)
            brk                ; $acb4: 00        
            asl $1681          ; $acb5: 0e 81 16  
            bit $66            ; $acb8: 24 66     
            .hex 04 8e         ; $acba: 04 8e     Invalid Opcode - NOP $8e
            brk                ; $acbc: 00        
            inc $0801,x        ; $acbd: fe 01 08  
            .hex d2            ; $acc0: d2        Invalid Opcode - KIL 
            asl $6f06          ; $acc1: 0e 06 6f  
            .hex 47 9e         ; $acc4: 47 9e     Invalid Opcode - SRE $9e
            .hex 0f 0e 82      ; $acc6: 0f 0e 82  Invalid Opcode - SLO __820e
            and $2847          ; $acc9: 2d 47 28  
            .hex 7a            ; $accc: 7a        Invalid Opcode - NOP 
            pla                ; $accd: 68        
            .hex 7a            ; $acce: 7a        Invalid Opcode - NOP 
            tay                ; $accf: a8        
            .hex 7a            ; $acd0: 7a        Invalid Opcode - NOP 
            ldx __de01         ; $acd1: ae 01 de  
            .hex 0f 6d c5      ; $acd4: 0f 6d c5  Invalid Opcode - SLO __c56d
            sbc $0f48,x        ; $acd7: fd 48 0f  
            asl $5e01          ; $acda: 0e 01 5e  
            .hex 02            ; $acdd: 02        Invalid Opcode - KIL 
            ldy __fc01,x       ; $acde: bc 01 fc  
            ora ($2c,x)        ; $ace1: 01 2c     
            .hex 82 41         ; $ace3: 82 41     Invalid Opcode - NOP #$41
            .hex 52            ; $ace5: 52        Invalid Opcode - KIL 
            lsr $6704          ; $ace6: 4e 04 67  
            and $68            ; $ace9: 25 68     
            bit $69            ; $aceb: 24 69     
            bit $ba            ; $aced: 24 ba     
            .hex 42            ; $acef: 42        Invalid Opcode - KIL 
            .hex c7            ; $acf0: c7        Suspected data
__acf1:     .hex 04 de         ; $acf1: 04 de     Invalid Opcode - NOP $de
            .hex 0b b2         ; $acf3: 0b b2     Invalid Opcode - ANC #$b2
            .hex 87 fe         ; $acf5: 87 fe     Invalid Opcode - SAX $fe
            .hex 02            ; $acf7: 02        Invalid Opcode - KIL 
            bit $2ce1          ; $acf8: 2c e1 2c  
            adc ($67),y        ; $acfb: 71 67     
            ora ($77,x)        ; $acfd: 01 77     
            brk                ; $acff: 00        
            .hex 87 01         ; $ad00: 87 01     Invalid Opcode - SAX $01
            stx __ee00         ; $ad02: 8e 00 ee  
            ora ($f6,x)        ; $ad05: 01 f6     
            .hex 02            ; $ad07: 02        Invalid Opcode - KIL 
            .hex 03 85         ; $ad08: 03 85     Invalid Opcode - SLO ($85,x)
            ora $02            ; $ad0a: 05 02     
            .hex 13 21         ; $ad0c: 13 21     Invalid Opcode - SLO ($21),y
            asl $02,x          ; $ad0e: 16 02     
            .hex 27 02         ; $ad10: 27 02     Invalid Opcode - RLA $02
            rol __8802         ; $ad12: 2e 02 88  
            .hex 72            ; $ad15: 72        Invalid Opcode - KIL 
            .hex c7 20         ; $ad16: c7 20     Invalid Opcode - DCP $20
            .hex d7 07         ; $ad18: d7 07     Invalid Opcode - DCP $07,x
            cpx $76            ; $ad1a: e4 76     
            .hex 07 a0         ; $ad1c: 07 a0     Invalid Opcode - SLO $a0
            .hex 17 06         ; $ad1e: 17 06     Invalid Opcode - SLO $06,x
            pha                ; $ad20: 48        
            .hex 7a            ; $ad21: 7a        Invalid Opcode - NOP 
            ror $20,x          ; $ad22: 76 20     
            tya                ; $ad24: 98        
            .hex 72            ; $ad25: 72        Invalid Opcode - KIL 
            adc __88e1,y       ; $ad26: 79 e1 88  
            .hex 62            ; $ad29: 62        Invalid Opcode - KIL 
            .hex 9c 01 b7      ; $ad2a: 9c 01 b7  Invalid Opcode - SHY __b701,x
            .hex 73 dc         ; $ad2d: 73 dc     Invalid Opcode - RRA ($dc),y
            ora ($f8,x)        ; $ad2f: 01 f8     
            .hex 62            ; $ad31: 62        Invalid Opcode - KIL 
            inc $0801,x        ; $ad32: fe 01 08  
            .hex e2 0e         ; $ad35: e2 0e     Invalid Opcode - NOP #$0e
            brk                ; $ad37: 00        
            ror $7302          ; $ad38: 6e 02 73  
            jsr $2377          ; $ad3b: 20 77 23  
            .hex 83 04         ; $ad3e: 83 04     Invalid Opcode - SAX ($04,x)
            .hex 93 20         ; $ad40: 93 20     Invalid Opcode - AHX ($20),y
            ldx __fe00         ; $ad42: ae 00 fe  
            asl                ; $ad45: 0a        
            .hex 0e 82         ; $ad46: 0e 82     Suspected data
__ad48:     and __a871,y       ; $ad48: 39 71 a8  
            .hex 72            ; $ad4b: 72        Invalid Opcode - KIL 
            .hex e7 73         ; $ad4c: e7 73     Invalid Opcode - ISC $73
            .hex 0c 81 8f      ; $ad4e: 0c 81 8f  Invalid Opcode - NOP __8f81
            .hex 32            ; $ad51: 32        Invalid Opcode - KIL 
            ldx __fe00         ; $ad52: ae 00 fe  
            .hex 04 04         ; $ad55: 04 04     Invalid Opcode - NOP $04
            cmp ($17),y        ; $ad57: d1 17     
            .hex 04 26         ; $ad59: 04 26     Invalid Opcode - NOP $26
            eor #$27           ; $ad5b: 49 27     
            and #$df           ; $ad5d: 29 df     
            .hex 33 fe         ; $ad5f: 33 fe     Invalid Opcode - RLA ($fe),y
            .hex 02            ; $ad61: 02        Invalid Opcode - KIL 
            .hex 44 f6         ; $ad62: 44 f6     Invalid Opcode - NOP $f6
            .hex 7c 01 8e      ; $ad64: 7c 01 8e  Invalid Opcode - NOP __8e01,x
            asl $bf            ; $ad67: 06 bf     
            .hex 47 ee         ; $ad69: 47 ee     Invalid Opcode - SRE $ee
            .hex 0f 4d c7      ; $ad6b: 0f 4d c7  Invalid Opcode - SLO __c74d
            asl $6882          ; $ad6e: 0e 82 68  
            .hex 7a            ; $ad71: 7a        Invalid Opcode - NOP 
            ldx __de01         ; $ad72: ae 01 de  
            .hex 0f 6d c5      ; $ad75: 0f 6d c5  Invalid Opcode - SLO __c56d
            sbc $0148,x        ; $ad78: fd 48 01  
            .hex 0e 01 00      ; $ad7b: 0e 01 00  Bad Addr Mode - ASL $0001
            .hex 5a            ; $ad7e: 5a        Invalid Opcode - NOP 
            rol $4506,x        ; $ad7f: 3e 06 45  
            lsr $47            ; $ad82: 46 47     
            lsr $53            ; $ad84: 46 53     
            .hex 44 ae         ; $ad86: 44 ae     Invalid Opcode - NOP $ae
            ora ($df,x)        ; $ad88: 01 df     
            lsr                ; $ad8a: 4a        
            eor $0ec7          ; $ad8b: 4d c7 0e  
__ad8e:     sta ($00,x)        ; $ad8e: 81 00     
            .hex 5a            ; $ad90: 5a        Invalid Opcode - NOP 
            rol $3704          ; $ad91: 2e 04 37  
            plp                ; $ad94: 28        
            .hex 3a            ; $ad95: 3a        Invalid Opcode - NOP 
            pha                ; $ad96: 48        
            lsr $47            ; $ad97: 46 47     
            .hex c7 07         ; $ad99: c7 07     Invalid Opcode - DCP $07
            dec __df0f         ; $ad9b: ce 0f df  
            lsr                ; $ad9e: 4a        
            eor $0ec7          ; $ad9f: 4d c7 0e  
            sta ($00,x)        ; $ada2: 81 00     
            .hex 5a            ; $ada4: 5a        Invalid Opcode - NOP 
            .hex 33 53         ; $ada5: 33 53     Invalid Opcode - RLA ($53),y
            .hex 43 51         ; $ada7: 43 51     Invalid Opcode - SRE ($51,x)
            lsr $40            ; $ada9: 46 40     
            .hex 47            ; $adab: 47        Suspected data
__adac:     bvc __ae01         ; $adac: 50 53     
            .hex 04 55         ; $adae: 04 55     Invalid Opcode - NOP $55
            rti                ; $adb0: 40        

;-------------------------------------------------------------------------------
            .hex 56            ; $adb1: 56        Suspected data
__adb2:     bvc __ae16         ; $adb2: 50 62     
            .hex 43 64         ; $adb4: 43 64     Invalid Opcode - SRE ($64,x)
            rti                ; $adb6: 40        

;-------------------------------------------------------------------------------
            adc $50            ; $adb7: 65 50     
            adc ($41),y        ; $adb9: 71 41     
            .hex 73 51         ; $adbb: 73 51     Invalid Opcode - RRA ($51),y
            .hex 83 51         ; $adbd: 83 51     Invalid Opcode - SAX ($51,x)
            sty $40,x          ; $adbf: 94 40     
            sta $50,x          ; $adc1: 95 50     
            .hex a3 50         ; $adc3: a3 50     Invalid Opcode - LAX ($50,x)
            lda $40            ; $adc5: a5 40     
            ldx $50            ; $adc7: a6 50     
            .hex b3 51         ; $adc9: b3 51     Invalid Opcode - LAX ($51),y
            ldx $40,y          ; $adcb: b6 40     
            .hex b7 50         ; $adcd: b7 50     Invalid Opcode - LAX $50,y
            .hex c3 53         ; $adcf: c3 53     Invalid Opcode - DCP ($53,x)
            .hex df 4a 4d      ; $add1: df 4a 4d  Invalid Opcode - DCP $4d4a,x
            .hex c7 0e         ; $add4: c7 0e     Invalid Opcode - DCP $0e
            sta ($00,x)        ; $add6: 81 00     
            .hex 5a            ; $add8: 5a        Invalid Opcode - NOP 
            rol $3602          ; $add9: 2e 02 36  
            .hex 47 37         ; $addc: 47 37     Invalid Opcode - SRE $37
            .hex 52            ; $adde: 52        Invalid Opcode - KIL 
            .hex 3a            ; $addf: 3a        Invalid Opcode - NOP 
            eor #$47           ; $ade0: 49 47     
            and $a7            ; $ade2: 25 a7     
            .hex 52            ; $ade4: 52        Invalid Opcode - KIL 
            .hex d7 04         ; $ade5: d7 04     Invalid Opcode - DCP $04,x
            .hex df 4a 4d      ; $ade7: df 4a 4d  Invalid Opcode - DCP $4d4a,x
            .hex c7 0e         ; $adea: c7 0e     Invalid Opcode - DCP $0e
            sta ($00,x)        ; $adec: 81 00     
            .hex 5a            ; $adee: 5a        Invalid Opcode - NOP 
            rol $4402,x        ; $adef: 3e 02 44  
            eor ($53),y        ; $adf2: 51 53     
            .hex 44 54         ; $adf4: 44 54     Invalid Opcode - NOP $54
            .hex 44 55         ; $adf6: 44 55     Invalid Opcode - NOP $55
            bit $a1            ; $adf8: 24 a1     
            .hex 54 ae         ; $adfa: 54 ae     Invalid Opcode - NOP $ae,x
            ora ($b4,x)        ; $adfc: 01 b4     
            and ($df,x)        ; $adfe: 21 df     
            lsr                ; $ae00: 4a        
__ae01:     sbc $07            ; $ae01: e5 07     
            eor __fdc7         ; $ae03: 4d c7 fd  
            eor ($01,x)        ; $ae06: 41 01     
            ldy $34,x          ; $ae08: b4 34     
__ae0a:     iny                ; $ae0a: c8        
            .hex 52            ; $ae0b: 52        Invalid Opcode - KIL 
            .hex f2            ; $ae0c: f2        Invalid Opcode - KIL 
            eor ($47),y        ; $ae0d: 51 47     
            .hex d3 6c         ; $ae0f: d3 6c     Invalid Opcode - DCP ($6c),y
            .hex 03 65         ; $ae11: 03 65     Invalid Opcode - SLO ($65,x)
            eor #$9e           ; $ae13: 49 9e     
            .hex 07            ; $ae15: 07        Suspected data
__ae16:     ldx __cc01,y       ; $ae16: be 01 cc  
            .hex 03 fe         ; $ae19: 03 fe     Invalid Opcode - SLO ($fe,x)
            .hex 07 0d         ; $ae1b: 07 0d     Invalid Opcode - SLO $0d
            cmp #$1e           ; $ae1d: c9 1e     
            ora ($6c,x)        ; $ae1f: 01 6c     
            ora ($62,x)        ; $ae21: 01 62     
            and $63,x          ; $ae23: 35 63     
            .hex 53 8a         ; $ae25: 53 8a     Invalid Opcode - SRE ($8a),y
            eor ($ac,x)        ; $ae27: 41 ac     
            ora ($b3,x)        ; $ae29: 01 b3     
            .hex 53 e9         ; $ae2b: 53 e9     Invalid Opcode - SRE ($e9),y
            eor ($26),y        ; $ae2d: 51 26     
            .hex c3 27         ; $ae2f: c3 27     Invalid Opcode - DCP ($27,x)
            .hex 33 63         ; $ae31: 33 63     Invalid Opcode - RLA ($63),y
            .hex 43 64         ; $ae33: 43 64     Invalid Opcode - SRE ($64,x)
            .hex 33 ba         ; $ae35: 33 ba     Invalid Opcode - RLA ($ba),y
            rts                ; $ae37: 60        

;-------------------------------------------------------------------------------
            cmp #$61           ; $ae38: c9 61     
            dec __de0b         ; $ae3a: ce 0b de  
            .hex 0f e5 09      ; $ae3d: 0f e5 09  Invalid Opcode - SLO $09e5
            adc $7dca,x        ; $ae40: 7d ca 7d  
            .hex 47 fd         ; $ae43: 47 fd     Invalid Opcode - SRE $fd
            eor ($01,x)        ; $ae45: 41 01     
            clv                ; $ae47: b8        
            .hex 52            ; $ae48: 52        Invalid Opcode - KIL 
            nop                ; $ae49: ea        
            eor ($27,x)        ; $ae4a: 41 27     
            .hex b2            ; $ae4c: b2        Invalid Opcode - KIL 
            .hex b3 42         ; $ae4d: b3 42     Invalid Opcode - LAX ($42),y
            asl $d4,x          ; $ae4f: 16 d4     
            lsr                ; $ae51: 4a        
            .hex 42            ; $ae52: 42        Invalid Opcode - KIL 
            lda $51            ; $ae53: a5 51     
            .hex a7 31         ; $ae55: a7 31     Invalid Opcode - LAX $31
            .hex 27 d3         ; $ae57: 27 d3     Invalid Opcode - RLA $d3
            php                ; $ae59: 08        
            .hex e2            ; $ae5a: e2        Suspected data
__ae5b:     asl $64,x          ; $ae5b: 16 64     
            bit $3804          ; $ae5d: 2c 04 38  
            .hex 42            ; $ae60: 42        Invalid Opcode - KIL 
            ror $64,x          ; $ae61: 76 64     
            dey                ; $ae63: 88        
            .hex 62            ; $ae64: 62        Invalid Opcode - KIL 
            dec __fe07,x       ; $ae65: de 07 fe  
            ora ($0d,x)        ; $ae68: 01 0d     
            cmp #$23           ; $ae6a: c9 23     
            .hex 32            ; $ae6c: 32        Invalid Opcode - KIL 
            and ($51),y        ; $ae6d: 31 51     
            tya                ; $ae6f: 98        
            .hex 52            ; $ae70: 52        Invalid Opcode - KIL 
            ora $59c9          ; $ae71: 0d c9 59  
            .hex 42            ; $ae74: 42        Invalid Opcode - KIL 
            .hex 63 53         ; $ae75: 63 53     Invalid Opcode - RRA ($53,x)
            .hex 67 31         ; $ae77: 67 31     Invalid Opcode - RRA $31
            .hex 14 c2         ; $ae79: 14 c2     Invalid Opcode - NOP $c2,x
            rol $31,x          ; $ae7b: 36 31     
            .hex 87 53         ; $ae7d: 87 53     Invalid Opcode - SAX $53
            .hex 17 e3         ; $ae7f: 17 e3     Invalid Opcode - SLO $e3,x
            and #$61           ; $ae81: 29 61     
            bmi __aee7         ; $ae83: 30 62     
            .hex 3c 08 42      ; $ae85: 3c 08 42  Invalid Opcode - NOP $4208,x
__ae88:     .hex 37 59         ; $ae88: 37 59     Invalid Opcode - RLA $59,x
            rti                ; $ae8a: 40        

;-------------------------------------------------------------------------------
            ror                ; $ae8b: 6a        
            .hex 42            ; $ae8c: 42        Invalid Opcode - KIL 
            sta __c940,y       ; $ae8d: 99 40 c9  
            adc ($d7,x)        ; $ae90: 61 d7     
            .hex 63 39         ; $ae92: 63 39     Invalid Opcode - RRA ($39,x)
            cmp ($58),y        ; $ae94: d1 58     
            .hex 52            ; $ae96: 52        Invalid Opcode - KIL 
            .hex c3 67         ; $ae97: c3 67     Invalid Opcode - DCP ($67,x)
            .hex d3 31         ; $ae99: d3 31     Invalid Opcode - DCP ($31),y
            .hex dc 06 f7      ; $ae9b: dc 06 f7  Invalid Opcode - NOP __f706,x
            .hex 42            ; $ae9e: 42        Invalid Opcode - KIL 
            .hex fa            ; $ae9f: fa        Invalid Opcode - NOP 
            .hex 42            ; $aea0: 42        Invalid Opcode - KIL 
            .hex 23 b1         ; $aea1: 23 b1     Invalid Opcode - RLA ($b1,x)
            .hex 43 67         ; $aea3: 43 67     Invalid Opcode - SRE ($67,x)
            .hex c3 34         ; $aea5: c3 34     Invalid Opcode - DCP ($34,x)
            .hex c7 34         ; $aea7: c7 34     Invalid Opcode - DCP $34
            cmp ($51),y        ; $aea9: d1 51     
            .hex 43 b3         ; $aeab: 43 b3     Invalid Opcode - SRE ($b3,x)
            .hex 47            ; $aead: 47        Suspected data
__aeae:     .hex 33 9a         ; $aeae: 33 9a     Invalid Opcode - RLA ($9a),y
            bmi __ae5b         ; $aeb0: 30 a9     
            adc ($b8,x)        ; $aeb2: 61 b8     
            .hex 62            ; $aeb4: 62        Invalid Opcode - KIL 
            ldx __ce0b,y       ; $aeb5: be 0b ce  
            .hex 0f d5 09      ; $aeb8: 0f d5 09  Invalid Opcode - SLO $09d5
            ora $7dca          ; $aebb: 0d ca 7d  
            .hex 47 fd         ; $aebe: 47 fd     Invalid Opcode - SRE $fd
            .hex 49            ; $aec0: 49        Suspected data
__aec1:     .hex 0f            ; $aec1: 0f        Suspected data
__aec2:     asl $3901,x        ; $aec2: 1e 01 39  
            .hex 73 5e         ; $aec5: 73 5e     Invalid Opcode - RRA ($5e),y
            .hex 07 ae         ; $aec7: 07 ae     Invalid Opcode - SLO $ae
            .hex 0b 1e         ; $aec9: 0b 1e     Invalid Opcode - ANC #$1e
            .hex 82 6e         ; $aecb: 82 6e     Invalid Opcode - NOP #$6e
            dey                ; $aecd: 88        
            .hex 9e 02 0d      ; $aece: 9e 02 0d  Invalid Opcode - SHX $0d02,y
            .hex 04 2e         ; $aed1: 04 2e     Invalid Opcode - NOP $2e
__aed3:     .hex 0b 3e         ; $aed3: 0b 3e     Invalid Opcode - ANC #$3e
            .hex 0f 45 09      ; $aed5: 0f 45 09  Invalid Opcode - SLO $0945
            sbc __fd47         ; $aed8: ed 47 fd  
            .hex ff ad 72      ; $aedb: ff ad 72  Invalid Opcode - ISC $72ad,x
            .hex 07 20         ; $aede: 07 20     Invalid Opcode - SLO $20
            .hex 04 8e         ; $aee0: 04 8e     Invalid Opcode - NOP $8e
            cpx $8f            ; $aee2: e4 8f     
            .hex 67 85         ; $aee4: 67 85     Invalid Opcode - RRA $85
            .hex 71            ; $aee6: 71        Suspected data
__aee7:     bcc __aed3         ; $aee7: 90 ea     
            .hex ae            ; $aee9: ae        Suspected data
__aeea:     ldx $0753          ; $aeea: ae 53 07  
            lda $06fc,x        ; $aeed: bd fc 06  
            sta $06fc          ; $aef0: 8d fc 06  
__aef3:     jsr __b04a         ; $aef3: 20 4a b0  
            lda $0772          ; $aef6: ad 72 07  
            cmp #$03           ; $aef9: c9 03     
            bcs __aefe         ; $aefb: b0 01     
            rts                ; $aefd: 60        

;-------------------------------------------------------------------------------
__aefe:     jsr __b624         ; $aefe: 20 24 b6  
            ldx #$00           ; $af01: a2 00     
__af03:     stx $08            ; $af03: 86 08     
            jsr __c04d         ; $af05: 20 4d c0  
            jsr __84c3         ; $af08: 20 c3 84  
            inx                ; $af0b: e8        
            cpx #$06           ; $af0c: e0 06     
            bne __af03         ; $af0e: d0 f3     
            jsr __f187         ; $af10: 20 87 f1  
            jsr __f131         ; $af13: 20 31 f1  
            jsr __eef0         ; $af16: 20 f0 ee  
            jsr __bed9         ; $af19: 20 d9 be  
            ldx #$01           ; $af1c: a2 01     
            stx $08            ; $af1e: 86 08     
            jsr __be75         ; $af20: 20 75 be  
            dex                ; $af23: ca        
            stx $08            ; $af24: 86 08     
            jsr __be75         ; $af26: 20 75 be  
            jsr __bb9b         ; $af29: 20 9b bb  
            jsr __b9c1         ; $af2c: 20 c1 b9  
            jsr __b7b8         ; $af2f: 20 b8 b7  
            jsr __b855         ; $af32: 20 55 b8  
            jsr __b74f         ; $af35: 20 4f b7  
            jsr __89e1         ; $af38: 20 e1 89  
            lda $b5            ; $af3b: a5 b5     
            cmp #$02           ; $af3d: c9 02     
            bpl __af52         ; $af3f: 10 11     
            lda $079f          ; $af41: ad 9f 07  
            beq __af64         ; $af44: f0 1e     
            cmp #$04           ; $af46: c9 04     
            bne __af52         ; $af48: d0 08     
            lda $077f          ; $af4a: ad 7f 07  
            bne __af52         ; $af4d: d0 03     
            jsr __90ed         ; $af4f: 20 ed 90  
__af52:     ldy $079f          ; $af52: ac 9f 07  
            lda $09            ; $af55: a5 09     
            cpy #$08           ; $af57: c0 08     
            bcs __af5d         ; $af59: b0 02     
            lsr                ; $af5b: 4a        
            lsr                ; $af5c: 4a        
__af5d:     lsr                ; $af5d: 4a        
            jsr __b288         ; $af5e: 20 88 b2  
            jmp __af67         ; $af61: 4c 67 af  

;-------------------------------------------------------------------------------
__af64:     jsr __b29a         ; $af64: 20 9a b2  
__af67:     lda $0a            ; $af67: a5 0a     
            sta $0d            ; $af69: 85 0d     
            lda #$00           ; $af6b: a9 00     
            sta $0c            ; $af6d: 85 0c     
__af6f:     lda $0773          ; $af6f: ad 73 07  
            cmp #$06           ; $af72: c9 06     
            beq __af92         ; $af74: f0 1c     
            lda $071f          ; $af76: ad 1f 07  
            bne __af8f         ; $af79: d0 14     
            lda $073d          ; $af7b: ad 3d 07  
            cmp #$20           ; $af7e: c9 20     
            bmi __af92         ; $af80: 30 10     
            lda $073d          ; $af82: ad 3d 07  
            sbc #$20           ; $af85: e9 20     
            sta $073d          ; $af87: 8d 3d 07  
            lda #$00           ; $af8a: a9 00     
            sta $0340          ; $af8c: 8d 40 03  
__af8f:     jsr __92b0         ; $af8f: 20 b0 92  
__af92:     rts                ; $af92: 60        

;-------------------------------------------------------------------------------
__af93:     lda $06ff          ; $af93: ad ff 06  
            clc                ; $af96: 18        
            adc $03a1          ; $af97: 6d a1 03  
            sta $06ff          ; $af9a: 8d ff 06  
            lda $0723          ; $af9d: ad 23 07  
            bne __affb         ; $afa0: d0 59     
            lda $0755          ; $afa2: ad 55 07  
            cmp #$50           ; $afa5: c9 50     
            bcc __affb         ; $afa7: 90 52     
            lda $0785          ; $afa9: ad 85 07  
            bne __affb         ; $afac: d0 4d     
            ldy $06ff          ; $afae: ac ff 06  
            dey                ; $afb1: 88        
            bmi __affb         ; $afb2: 30 47     
            iny                ; $afb4: c8        
            cpy #$02           ; $afb5: c0 02     
            bcc __afba         ; $afb7: 90 01     
            dey                ; $afb9: 88        
__afba:     lda $0755          ; $afba: ad 55 07  
            cmp #$70           ; $afbd: c9 70     
            bcc __afc4         ; $afbf: 90 03     
            ldy $06ff          ; $afc1: ac ff 06  
__afc4:     tya                ; $afc4: 98        
            sta $0775          ; $afc5: 8d 75 07  
            clc                ; $afc8: 18        
            adc $073d          ; $afc9: 6d 3d 07  
            sta $073d          ; $afcc: 8d 3d 07  
            tya                ; $afcf: 98        
            clc                ; $afd0: 18        
            adc $071c          ; $afd1: 6d 1c 07  
            sta $071c          ; $afd4: 8d 1c 07  
            sta $073f          ; $afd7: 8d 3f 07  
            lda $071a          ; $afda: ad 1a 07  
            adc #$00           ; $afdd: 69 00     
            sta $071a          ; $afdf: 8d 1a 07  
            and #$01           ; $afe2: 29 01     
            sta $00            ; $afe4: 85 00     
            lda $0778          ; $afe6: ad 78 07  
            and #$fe           ; $afe9: 29 fe     
            ora $00            ; $afeb: 05 00     
            sta $0778          ; $afed: 8d 78 07  
            jsr __b038         ; $aff0: 20 38 b0  
            lda #$08           ; $aff3: a9 08     
            sta $0795          ; $aff5: 8d 95 07  
            jmp __b000         ; $aff8: 4c 00 b0  

;-------------------------------------------------------------------------------
__affb:     lda #$00           ; $affb: a9 00     
            sta $0775          ; $affd: 8d 75 07  
__b000:     ldx #$00           ; $b000: a2 00     
            jsr __f1fd         ; $b002: 20 fd f1  
            sta $00            ; $b005: 85 00     
            ldy #$00           ; $b007: a0 00     
            asl                ; $b009: 0a        
            bcs __b013         ; $b00a: b0 07     
            iny                ; $b00c: c8        
            lda $00            ; $b00d: a5 00     
            and #$20           ; $b00f: 29 20     
            beq __b02e         ; $b011: f0 1b     
__b013:     lda $071c,y        ; $b013: b9 1c 07  
            sec                ; $b016: 38        
            sbc __b034,y       ; $b017: f9 34 b0  
            sta $86            ; $b01a: 85 86     
            lda $071a,y        ; $b01c: b9 1a 07  
            sbc #$00           ; $b01f: e9 00     
            sta $6d            ; $b021: 85 6d     
            lda $0c            ; $b023: a5 0c     
            cmp __b036,y       ; $b025: d9 36 b0  
            beq __b02e         ; $b028: f0 04     
            lda #$00           ; $b02a: a9 00     
            sta $57            ; $b02c: 85 57     
__b02e:     lda #$00           ; $b02e: a9 00     
            sta $03a1          ; $b030: 8d a1 03  
            rts                ; $b033: 60        

;-------------------------------------------------------------------------------
__b034:     brk                ; $b034: 00        
            .hex 10            ; $b035: 10        Suspected data
__b036:     ora ($02,x)        ; $b036: 01 02     
__b038:     lda $071c          ; $b038: ad 1c 07  
            clc                ; $b03b: 18        
            adc #$ff           ; $b03c: 69 ff     
            sta $071d          ; $b03e: 8d 1d 07  
            lda $071a          ; $b041: ad 1a 07  
            adc #$00           ; $b044: 69 00     
            sta $071b          ; $b046: 8d 1b 07  
__b049:     rts                ; $b049: 60        

;-------------------------------------------------------------------------------
__b04a:     lda $0e            ; $b04a: a5 0e     
            jsr __8e04         ; $b04c: 20 04 8e  
            and ($91),y        ; $b04f: 31 91     
            .hex c7 b1         ; $b051: c7 b1     Invalid Opcode - DCP $b1
            asl $b2            ; $b053: 06 b2     
            sbc $b1            ; $b055: e5 b1     
            ldy $b2            ; $b057: a4 b2     
            dex                ; $b059: ca        
            .hex b2            ; $b05a: b2        Invalid Opcode - KIL 
            cmp $6991          ; $b05b: cd 91 69  
            bcs __b049         ; $b05e: b0 e9     
            bcs __b095         ; $b060: b0 33     
            .hex b2            ; $b062: b2        Invalid Opcode - KIL 
            eor $b2            ; $b063: 45 b2     
            adc #$b2           ; $b065: 69 b2     
            adc __adb2,x       ; $b067: 7d b2 ad  
            .hex 52            ; $b06a: 52        Invalid Opcode - KIL 
            .hex 07 c9         ; $b06b: 07 c9     Invalid Opcode - SLO $c9
            .hex 02            ; $b06d: 02        Invalid Opcode - KIL 
            beq __b09b         ; $b06e: f0 2b     
            lda #$00           ; $b070: a9 00     
            ldy $ce            ; $b072: a4 ce     
            cpy #$30           ; $b074: c0 30     
            bcc __b0e6         ; $b076: 90 6e     
            lda $0710          ; $b078: ad 10 07  
            cmp #$06           ; $b07b: c9 06     
            beq __b083         ; $b07d: f0 04     
            cmp #$07           ; $b07f: c9 07     
            bne __b0d3         ; $b081: d0 50     
__b083:     lda $03c4          ; $b083: ad c4 03  
            bne __b08d         ; $b086: d0 05     
            lda #$01           ; $b088: a9 01     
            jmp __b0e6         ; $b08a: 4c e6 b0  

;-------------------------------------------------------------------------------
__b08d:     jsr __b21f         ; $b08d: 20 1f b2  
            dec $06de          ; $b090: ce de 06  
            bne __b0e5         ; $b093: d0 50     
__b095:     inc $0769          ; $b095: ee 69 07  
            jmp __b315         ; $b098: 4c 15 b3  

;-------------------------------------------------------------------------------
__b09b:     lda $0758          ; $b09b: ad 58 07  
            bne __b0ac         ; $b09e: d0 0c     
            lda #$ff           ; $b0a0: a9 ff     
            jsr __b200         ; $b0a2: 20 00 b2  
            lda $ce            ; $b0a5: a5 ce     
            cmp #$91           ; $b0a7: c9 91     
            bcc __b0d3         ; $b0a9: 90 28     
            rts                ; $b0ab: 60        

;-------------------------------------------------------------------------------
__b0ac:     lda $0399          ; $b0ac: ad 99 03  
            cmp #$60           ; $b0af: c9 60     
            bne __b0e5         ; $b0b1: d0 32     
            lda $ce            ; $b0b3: a5 ce     
            cmp #$99           ; $b0b5: c9 99     
            ldy #$00           ; $b0b7: a0 00     
            lda #$01           ; $b0b9: a9 01     
            bcc __b0c7         ; $b0bb: 90 0a     
            lda #$03           ; $b0bd: a9 03     
            sta $1d            ; $b0bf: 85 1d     
            iny                ; $b0c1: c8        
            lda #$08           ; $b0c2: a9 08     
            sta $05b4          ; $b0c4: 8d b4 05  
__b0c7:     sty $0716          ; $b0c7: 8c 16 07  
            jsr __b0e6         ; $b0ca: 20 e6 b0  
            lda $86            ; $b0cd: a5 86     
            cmp #$48           ; $b0cf: c9 48     
            bcc __b0e5         ; $b0d1: 90 12     
__b0d3:     lda #$08           ; $b0d3: a9 08     
            sta $0e            ; $b0d5: 85 0e     
            lda #$01           ; $b0d7: a9 01     
            sta $33            ; $b0d9: 85 33     
            lsr                ; $b0db: 4a        
            sta $0752          ; $b0dc: 8d 52 07  
            sta $0716          ; $b0df: 8d 16 07  
            sta $0758          ; $b0e2: 8d 58 07  
__b0e5:     rts                ; $b0e5: 60        

;-------------------------------------------------------------------------------
__b0e6:     sta $06fc          ; $b0e6: 8d fc 06  
__b0e9:     lda $0e            ; $b0e9: a5 0e     
            cmp #$0b           ; $b0eb: c9 0b     
            beq __b12b         ; $b0ed: f0 3c     
            lda $074e          ; $b0ef: ad 4e 07  
            bne __b104         ; $b0f2: d0 10     
            ldy $b5            ; $b0f4: a4 b5     
            dey                ; $b0f6: 88        
            bne __b0ff         ; $b0f7: d0 06     
            lda $ce            ; $b0f9: a5 ce     
            cmp #$d0           ; $b0fb: c9 d0     
            bcc __b104         ; $b0fd: 90 05     
__b0ff:     lda #$00           ; $b0ff: a9 00     
            sta $06fc          ; $b101: 8d fc 06  
__b104:     lda $06fc          ; $b104: ad fc 06  
__b107:     and #$c0           ; $b107: 29 c0     
            sta $0a            ; $b109: 85 0a     
            lda $06fc          ; $b10b: ad fc 06  
            and #$03           ; $b10e: 29 03     
            sta $0c            ; $b110: 85 0c     
            lda $06fc          ; $b112: ad fc 06  
            and #$0c           ; $b115: 29 0c     
            sta $0b            ; $b117: 85 0b     
            and #$04           ; $b119: 29 04     
            beq __b12b         ; $b11b: f0 0e     
            lda $1d            ; $b11d: a5 1d     
            bne __b12b         ; $b11f: d0 0a     
            ldy $0c            ; $b121: a4 0c     
            beq __b12b         ; $b123: f0 06     
            lda #$00           ; $b125: a9 00     
            sta $0c            ; $b127: 85 0c     
            sta $0b            ; $b129: 85 0b     
__b12b:     jsr __b329         ; $b12b: 20 29 b3  
            ldy #$01           ; $b12e: a0 01     
            lda $0754          ; $b130: ad 54 07  
            bne __b13e         ; $b133: d0 09     
            ldy #$00           ; $b135: a0 00     
            lda $0714          ; $b137: ad 14 07  
            beq __b13e         ; $b13a: f0 02     
            ldy #$02           ; $b13c: a0 02     
__b13e:     sty $0499          ; $b13e: 8c 99 04  
            lda #$01           ; $b141: a9 01     
            ldy $57            ; $b143: a4 57     
            beq __b14c         ; $b145: f0 05     
            bpl __b14a         ; $b147: 10 01     
            asl                ; $b149: 0a        
__b14a:     sta $45            ; $b14a: 85 45     
__b14c:     jsr __af93         ; $b14c: 20 93 af  
            jsr __f187         ; $b14f: 20 87 f1  
            jsr __f131         ; $b152: 20 31 f1  
            ldx #$00           ; $b155: a2 00     
            jsr __e2a4         ; $b157: 20 a4 e2  
            jsr __dc66         ; $b15a: 20 66 dc  
            lda $ce            ; $b15d: a5 ce     
            cmp #$40           ; $b15f: c9 40     
            bcc __b179         ; $b161: 90 16     
            lda $0e            ; $b163: a5 0e     
            cmp #$05           ; $b165: c9 05     
            beq __b179         ; $b167: f0 10     
            cmp #$07           ; $b169: c9 07     
            beq __b179         ; $b16b: f0 0c     
            cmp #$04           ; $b16d: c9 04     
            bcc __b179         ; $b16f: 90 08     
            lda $03c4          ; $b171: ad c4 03  
            and #$df           ; $b174: 29 df     
            sta $03c4          ; $b176: 8d c4 03  
__b179:     lda $b5            ; $b179: a5 b5     
            cmp #$02           ; $b17b: c9 02     
            bmi __b1ba         ; $b17d: 30 3b     
            ldx #$01           ; $b17f: a2 01     
            stx $0723          ; $b181: 8e 23 07  
            ldy #$04           ; $b184: a0 04     
            sty $07            ; $b186: 84 07     
            ldx #$00           ; $b188: a2 00     
            ldy $0759          ; $b18a: ac 59 07  
            bne __b194         ; $b18d: d0 05     
            ldy $0743          ; $b18f: ac 43 07  
            bne __b1aa         ; $b192: d0 16     
__b194:     inx                ; $b194: e8        
            ldy $0e            ; $b195: a4 0e     
            cpy #$0b           ; $b197: c0 0b     
            beq __b1aa         ; $b199: f0 0f     
            ldy $0712          ; $b19b: ac 12 07  
            bne __b1a6         ; $b19e: d0 06     
            iny                ; $b1a0: c8        
            sty $fc            ; $b1a1: 84 fc     
            sty $0712          ; $b1a3: 8c 12 07  
__b1a6:     ldy #$06           ; $b1a6: a0 06     
            sty $07            ; $b1a8: 84 07     
__b1aa:     cmp $07            ; $b1aa: c5 07     
            bmi __b1ba         ; $b1ac: 30 0c     
            dex                ; $b1ae: ca        
            bmi __b1bb         ; $b1af: 30 0a     
            ldy $07b1          ; $b1b1: ac b1 07  
            bne __b1ba         ; $b1b4: d0 04     
            lda #$06           ; $b1b6: a9 06     
            sta $0e            ; $b1b8: 85 0e     
__b1ba:     rts                ; $b1ba: 60        

;-------------------------------------------------------------------------------
__b1bb:     lda #$00           ; $b1bb: a9 00     
            sta $0758          ; $b1bd: 8d 58 07  
            jsr __b1dd         ; $b1c0: 20 dd b1  
            inc $0752          ; $b1c3: ee 52 07  
            rts                ; $b1c6: 60        

;-------------------------------------------------------------------------------
            lda $b5            ; $b1c7: a5 b5     
            bne __b1d1         ; $b1c9: d0 06     
            lda $ce            ; $b1cb: a5 ce     
            cmp #$e4           ; $b1cd: c9 e4     
            bcc __b1dd         ; $b1cf: 90 0c     
__b1d1:     lda #$08           ; $b1d1: a9 08     
            sta $0758          ; $b1d3: 8d 58 07  
            ldy #$03           ; $b1d6: a0 03     
            sty $1d            ; $b1d8: 84 1d     
            jmp __b0e6         ; $b1da: 4c e6 b0  

;-------------------------------------------------------------------------------
__b1dd:     lda #$02           ; $b1dd: a9 02     
            sta $0752          ; $b1df: 8d 52 07  
            jmp __b213         ; $b1e2: 4c 13 b2  

;-------------------------------------------------------------------------------
            lda #$01           ; $b1e5: a9 01     
            jsr __b200         ; $b1e7: 20 00 b2  
            jsr __af93         ; $b1ea: 20 93 af  
            ldy #$00           ; $b1ed: a0 00     
            lda $06d6          ; $b1ef: ad d6 06  
            bne __b20b         ; $b1f2: d0 17     
            iny                ; $b1f4: c8        
            lda $074e          ; $b1f5: ad 4e 07  
            cmp #$03           ; $b1f8: c9 03     
            bne __b20b         ; $b1fa: d0 0f     
            iny                ; $b1fc: c8        
            jmp __b20b         ; $b1fd: 4c 0b b2  

;-------------------------------------------------------------------------------
__b200:     clc                ; $b200: 18        
            adc $ce            ; $b201: 65 ce     
            sta $ce            ; $b203: 85 ce     
            rts                ; $b205: 60        

;-------------------------------------------------------------------------------
            jsr __b21f         ; $b206: 20 1f b2  
            ldy #$02           ; $b209: a0 02     
__b20b:     dec $06de          ; $b20b: ce de 06  
            bne __b21e         ; $b20e: d0 0e     
            sty $0752          ; $b210: 8c 52 07  
__b213:     inc $0774          ; $b213: ee 74 07  
            lda #$00           ; $b216: a9 00     
            sta $0772          ; $b218: 8d 72 07  
            sta $0722          ; $b21b: 8d 22 07  
__b21e:     rts                ; $b21e: 60        

;-------------------------------------------------------------------------------
__b21f:     lda #$08           ; $b21f: a9 08     
            sta $57            ; $b221: 85 57     
            ldy #$01           ; $b223: a0 01     
            lda $86            ; $b225: a5 86     
__b227:     and #$0f           ; $b227: 29 0f     
            bne __b22e         ; $b229: d0 03     
            sta $57            ; $b22b: 85 57     
            tay                ; $b22d: a8        
__b22e:     tya                ; $b22e: 98        
            jsr __b0e6         ; $b22f: 20 e6 b0  
            rts                ; $b232: 60        

;-------------------------------------------------------------------------------
            lda $0747          ; $b233: ad 47 07  
            cmp #$f8           ; $b236: c9 f8     
            bne __b23d         ; $b238: d0 03     
            jmp __b255         ; $b23a: 4c 55 b2  

;-------------------------------------------------------------------------------
__b23d:     cmp #$c4           ; $b23d: c9 c4     
            bne __b244         ; $b23f: d0 03     
            jsr __b273         ; $b241: 20 73 b2  
__b244:     rts                ; $b244: 60        

;-------------------------------------------------------------------------------
            lda $0747          ; $b245: ad 47 07  
            cmp #$f0           ; $b248: c9 f0     
            bcs __b253         ; $b24a: b0 07     
            cmp #$c8           ; $b24c: c9 c8     
            beq __b273         ; $b24e: f0 23     
            jmp __b0e9         ; $b250: 4c e9 b0  

;-------------------------------------------------------------------------------
__b253:     bne __b268         ; $b253: d0 13     
__b255:     ldy $070b          ; $b255: ac 0b 07  
            bne __b268         ; $b258: d0 0e     
            sty $070d          ; $b25a: 8c 0d 07  
            inc $070b          ; $b25d: ee 0b 07  
            lda $0754          ; $b260: ad 54 07  
            eor #$01           ; $b263: 49 01     
            sta $0754          ; $b265: 8d 54 07  
__b268:     rts                ; $b268: 60        

;-------------------------------------------------------------------------------
            lda $0747          ; $b269: ad 47 07  
            cmp #$f0           ; $b26c: c9 f0     
            bcs __b2a3         ; $b26e: b0 33     
            jmp __b0e9         ; $b270: 4c e9 b0  

;-------------------------------------------------------------------------------
__b273:     lda #$00           ; $b273: a9 00     
            sta $0747          ; $b275: 8d 47 07  
            lda #$08           ; $b278: a9 08     
            sta $0e            ; $b27a: 85 0e     
            rts                ; $b27c: 60        

;-------------------------------------------------------------------------------
            lda $0747          ; $b27d: ad 47 07  
            cmp #$c0           ; $b280: c9 c0     
            beq __b297         ; $b282: f0 13     
            lda $09            ; $b284: a5 09     
            lsr                ; $b286: 4a        
            lsr                ; $b287: 4a        
__b288:     and #$03           ; $b288: 29 03     
            sta $00            ; $b28a: 85 00     
            lda $03c4          ; $b28c: ad c4 03  
            and #$fc           ; $b28f: 29 fc     
            ora $00            ; $b291: 05 00     
            sta $03c4          ; $b293: 8d c4 03  
            rts                ; $b296: 60        

;-------------------------------------------------------------------------------
__b297:     jsr __b273         ; $b297: 20 73 b2  
__b29a:     lda $03c4          ; $b29a: ad c4 03  
            and #$fc           ; $b29d: 29 fc     
            sta $03c4          ; $b29f: 8d c4 03  
            rts                ; $b2a2: 60        

;-------------------------------------------------------------------------------
__b2a3:     rts                ; $b2a3: 60        

;-------------------------------------------------------------------------------
            lda $1b            ; $b2a4: a5 1b     
            cmp #$30           ; $b2a6: c9 30     
            bne __b2bf         ; $b2a8: d0 15     
            lda $0713          ; $b2aa: ad 13 07  
            sta $ff            ; $b2ad: 85 ff     
            lda #$00           ; $b2af: a9 00     
            sta $0713          ; $b2b1: 8d 13 07  
            ldy $ce            ; $b2b4: a4 ce     
            cpy #$9e           ; $b2b6: c0 9e     
            bcs __b2bc         ; $b2b8: b0 02     
            lda #$04           ; $b2ba: a9 04     
__b2bc:     jmp __b0e6         ; $b2bc: 4c e6 b0  

;-------------------------------------------------------------------------------
__b2bf:     inc $0e            ; $b2bf: e6 0e     
            rts                ; $b2c1: 60        

;-------------------------------------------------------------------------------
            ora $23,x          ; $b2c2: 15 23     
            asl $1b,x          ; $b2c4: 16 1b     
            .hex 17 18         ; $b2c6: 17 18     Invalid Opcode - SLO $18,x
            .hex 23 63         ; $b2c8: 23 63     Invalid Opcode - RLA ($63,x)
            lda #$01           ; $b2ca: a9 01     
            jsr __b0e6         ; $b2cc: 20 e6 b0  
            lda $ce            ; $b2cf: a5 ce     
            cmp #$ae           ; $b2d1: c9 ae     
            bcc __b2e3         ; $b2d3: 90 0e     
            lda $0723          ; $b2d5: ad 23 07  
            beq __b2e3         ; $b2d8: f0 09     
            lda #$20           ; $b2da: a9 20     
            sta $fc            ; $b2dc: 85 fc     
            lda #$00           ; $b2de: a9 00     
            sta $0723          ; $b2e0: 8d 23 07  
__b2e3:     lda $0490          ; $b2e3: ad 90 04  
            lsr                ; $b2e6: 4a        
            bcs __b2f6         ; $b2e7: b0 0d     
            lda $0746          ; $b2e9: ad 46 07  
            bne __b2f1         ; $b2ec: d0 03     
            inc $0746          ; $b2ee: ee 46 07  
__b2f1:     lda #$20           ; $b2f1: a9 20     
            sta $03c4          ; $b2f3: 8d c4 03  
__b2f6:     lda $0746          ; $b2f6: ad 46 07  
            cmp #$05           ; $b2f9: c9 05     
            bne __b328         ; $b2fb: d0 2b     
            inc $075c          ; $b2fd: ee 5c 07  
            .hex ad 5c         ; $b300: ad 5c     Suspected data
__b302:     .hex 07 c9         ; $b302: 07 c9     Invalid Opcode - SLO $c9
            .hex 03 d0         ; $b304: 03 d0     Invalid Opcode - SLO ($d0,x)
            .hex 0e ac         ; $b306: 0e ac     Suspected data
__b308:     .hex 5f 07 ad      ; $b308: 5f 07 ad  Invalid Opcode - SRE __ad07,x
            pha                ; $b30b: 48        
            .hex 07 d9         ; $b30c: 07 d9     Invalid Opcode - SLO $d9
            .hex c2 b2         ; $b30e: c2 b2     Invalid Opcode - NOP #$b2
            bcc __b315         ; $b310: 90 03     
            inc $075d          ; $b312: ee 5d 07  
__b315:     inc $0760          ; $b315: ee 60 07  
            jsr __9c03         ; $b318: 20 03 9c  
            inc $0757          ; $b31b: ee 57 07  
            jsr __b213         ; $b31e: 20 13 b2  
            sta $075b          ; $b321: 8d 5b 07  
            lda #$80           ; $b324: a9 80     
            sta $fc            ; $b326: 85 fc     
__b328:     rts                ; $b328: 60        

;-------------------------------------------------------------------------------
__b329:     lda #$00           ; $b329: a9 00     
            ldy $0754          ; $b32b: ac 54 07  
            bne __b338         ; $b32e: d0 08     
            lda $1d            ; $b330: a5 1d     
            bne __b33b         ; $b332: d0 07     
            lda $0b            ; $b334: a5 0b     
            and #$04           ; $b336: 29 04     
__b338:     sta $0714          ; $b338: 8d 14 07  
__b33b:     jsr __b450         ; $b33b: 20 50 b4  
            lda $070b          ; $b33e: ad 0b 07  
            bne __b359         ; $b341: d0 16     
            lda $1d            ; $b343: a5 1d     
            cmp #$03           ; $b345: c9 03     
            beq __b34e         ; $b347: f0 05     
            ldy #$18           ; $b349: a0 18     
            sty $0789          ; $b34b: 8c 89 07  
__b34e:     jsr __8e04         ; $b34e: 20 04 8e  
            .hex 5a            ; $b351: 5a        Invalid Opcode - NOP 
            .hex b3 76         ; $b352: b3 76     Invalid Opcode - LAX ($76),y
            .hex b3 6d         ; $b354: b3 6d     Invalid Opcode - LAX ($6d),y
            .hex b3 cf         ; $b356: b3 cf     Invalid Opcode - LAX ($cf),y
            .hex b3            ; $b358: b3        Suspected data
__b359:     rts                ; $b359: 60        

;-------------------------------------------------------------------------------
            jsr __b58f         ; $b35a: 20 8f b5  
            lda $0c            ; $b35d: a5 0c     
            beq __b363         ; $b35f: f0 02     
            sta $33            ; $b361: 85 33     
__b363:     jsr __b5cc         ; $b363: 20 cc b5  
            jsr __bf0e         ; $b366: 20 0e bf  
            sta $06ff          ; $b369: 8d ff 06  
            rts                ; $b36c: 60        

;-------------------------------------------------------------------------------
            lda $070a          ; $b36d: ad 0a 07  
            sta $0709          ; $b370: 8d 09 07  
            jmp __b3ac         ; $b373: 4c ac b3  

;-------------------------------------------------------------------------------
            ldy $9f            ; $b376: a4 9f     
            bpl __b38d         ; $b378: 10 13     
            lda $0a            ; $b37a: a5 0a     
            and #$80           ; $b37c: 29 80     
            and $0d            ; $b37e: 25 0d     
            bne __b393         ; $b380: d0 11     
            lda $0708          ; $b382: ad 08 07  
            sec                ; $b385: 38        
            sbc $ce            ; $b386: e5 ce     
            cmp $0706          ; $b388: cd 06 07  
            bcc __b393         ; $b38b: 90 06     
__b38d:     lda $070a          ; $b38d: ad 0a 07  
            sta $0709          ; $b390: 8d 09 07  
__b393:     lda $0704          ; $b393: ad 04 07  
            beq __b3ac         ; $b396: f0 14     
            jsr __b58f         ; $b398: 20 8f b5  
            lda $ce            ; $b39b: a5 ce     
            cmp #$14           ; $b39d: c9 14     
            bcs __b3a6         ; $b39f: b0 05     
            lda #$18           ; $b3a1: a9 18     
            sta $0709          ; $b3a3: 8d 09 07  
__b3a6:     lda $0c            ; $b3a6: a5 0c     
            beq __b3ac         ; $b3a8: f0 02     
__b3aa:     sta $33            ; $b3aa: 85 33     
__b3ac:     lda $0c            ; $b3ac: a5 0c     
            beq __b3b3         ; $b3ae: f0 03     
            jsr __b5cc         ; $b3b0: 20 cc b5  
__b3b3:     jsr __bf0e         ; $b3b3: 20 0e bf  
            sta $06ff          ; $b3b6: 8d ff 06  
            lda $0e            ; $b3b9: a5 0e     
            cmp #$0b           ; $b3bb: c9 0b     
            bne __b3c4         ; $b3bd: d0 05     
            lda #$28           ; $b3bf: a9 28     
            sta $0709          ; $b3c1: 8d 09 07  
__b3c4:     jmp __bf52         ; $b3c4: 4c 52 bf  

;-------------------------------------------------------------------------------
__b3c7:     asl __fc04         ; $b3c7: 0e 04 fc  
            .hex f2            ; $b3ca: f2        Invalid Opcode - KIL 
__b3cb:     brk                ; $b3cb: 00        
            brk                ; $b3cc: 00        
            .hex ff ff ad      ; $b3cd: ff ff ad  Invalid Opcode - ISC __adff,x
            asl $04,x          ; $b3d0: 16 04     
            clc                ; $b3d2: 18        
            adc $0433          ; $b3d3: 6d 33 04  
            sta $0416          ; $b3d6: 8d 16 04  
            ldy #$00           ; $b3d9: a0 00     
            lda $9f            ; $b3db: a5 9f     
            bpl __b3e0         ; $b3dd: 10 01     
            dey                ; $b3df: 88        
__b3e0:     sty $00            ; $b3e0: 84 00     
            adc $ce            ; $b3e2: 65 ce     
            sta $ce            ; $b3e4: 85 ce     
            lda $b5            ; $b3e6: a5 b5     
            adc $00            ; $b3e8: 65 00     
            sta $b5            ; $b3ea: 85 b5     
            lda $0c            ; $b3ec: a5 0c     
            and $0490          ; $b3ee: 2d 90 04  
            beq __b420         ; $b3f1: f0 2d     
            ldy $0789          ; $b3f3: ac 89 07  
            bne __b41f         ; $b3f6: d0 27     
            ldy #$18           ; $b3f8: a0 18     
            sty $0789          ; $b3fa: 8c 89 07  
            ldx #$00           ; $b3fd: a2 00     
__b3ff:     ldy $33            ; $b3ff: a4 33     
            lsr                ; $b401: 4a        
            bcs __b406         ; $b402: b0 02     
            inx                ; $b404: e8        
            inx                ; $b405: e8        
__b406:     dey                ; $b406: 88        
            beq __b40a         ; $b407: f0 01     
            inx                ; $b409: e8        
__b40a:     lda $86            ; $b40a: a5 86     
            clc                ; $b40c: 18        
            adc __b3c7,x       ; $b40d: 7d c7 b3  
            sta $86            ; $b410: 85 86     
            lda $6d            ; $b412: a5 6d     
            adc __b3cb,x       ; $b414: 7d cb b3  
            sta $6d            ; $b417: 85 6d     
            lda $0c            ; $b419: a5 0c     
            eor #$03           ; $b41b: 49 03     
            sta $33            ; $b41d: 85 33     
__b41f:     rts                ; $b41f: 60        

;-------------------------------------------------------------------------------
__b420:     sta $0789          ; $b420: 8d 89 07  
            rts                ; $b423: 60        

;-------------------------------------------------------------------------------
__b424:     bmi __b456         ; $b424: 30 30     
__b426:     and $3838          ; $b426: 2d 38 38  
            .hex 0d 04         ; $b429: 0d 04     Suspected data
__b42b:     tay                ; $b42b: a8        
            tay                ; $b42c: a8        
            bcc __b3ff         ; $b42d: 90 d0     
            bne __b43b         ; $b42f: d0 0a     
            .hex 09            ; $b431: 09        Suspected data
__b432:     .hex fb fb fb      ; $b432: fb fb fb  Invalid Opcode - ISC __fbfb,y
            .hex fa            ; $b435: fa        Invalid Opcode - NOP 
            .hex fa            ; $b436: fa        Invalid Opcode - NOP 
            .hex fe ff         ; $b437: fe ff     Suspected data
__b439:     .hex 34 34         ; $b439: 34 34     Invalid Opcode - NOP $34,x
__b43b:     .hex 34 00         ; $b43b: 34 00     Invalid Opcode - NOP $00,x
            brk                ; $b43d: 00        
            .hex 80 00         ; $b43e: 80 00     Invalid Opcode - NOP #$00
__b440:     bne __b426         ; $b440: d0 e4     
            .hex ed            ; $b442: ed        Suspected data
__b443:     bmi __b461         ; $b443: 30 1c     
            .hex 13 0e         ; $b445: 13 0e     Invalid Opcode - SLO ($0e),y
__b447:     cpy #$00           ; $b447: c0 00     
            .hex 80            ; $b449: 80        Suspected data
__b44a:     brk                ; $b44a: 00        
            .hex ff 01         ; $b44b: ff 01     Suspected data
__b44d:     brk                ; $b44d: 00        
            .hex 20 ff         ; $b44e: 20 ff     Suspected data
__b450:     lda $1d            ; $b450: a5 1d     
            cmp #$03           ; $b452: c9 03     
            bne __b479         ; $b454: d0 23     
__b456:     ldy #$00           ; $b456: a0 00     
            lda $0b            ; $b458: a5 0b     
            and $0490          ; $b45a: 2d 90 04  
            beq __b465         ; $b45d: f0 06     
            iny                ; $b45f: c8        
            .hex 29            ; $b460: 29        Suspected data
__b461:     php                ; $b461: 08        
            bne __b465         ; $b462: d0 01     
            iny                ; $b464: c8        
__b465:     ldx __b44d,y       ; $b465: be 4d b4  
            stx $0433          ; $b468: 8e 33 04  
            lda #$08           ; $b46b: a9 08     
            ldx __b44a,y       ; $b46d: be 4a b4  
            stx $9f            ; $b470: 86 9f     
            bmi __b475         ; $b472: 30 01     
            lsr                ; $b474: 4a        
__b475:     sta $070c          ; $b475: 8d 0c 07  
            rts                ; $b478: 60        

;-------------------------------------------------------------------------------
__b479:     lda $070e          ; $b479: ad 0e 07  
            bne __b488         ; $b47c: d0 0a     
            lda $0a            ; $b47e: a5 0a     
            and #$80           ; $b480: 29 80     
            beq __b488         ; $b482: f0 04     
            and $0d            ; $b484: 25 0d     
            beq __b48b         ; $b486: f0 03     
__b488:     jmp __b51c         ; $b488: 4c 1c b5  

;-------------------------------------------------------------------------------
__b48b:     lda $1d            ; $b48b: a5 1d     
            beq __b4a0         ; $b48d: f0 11     
            lda $0704          ; $b48f: ad 04 07  
            beq __b488         ; $b492: f0 f4     
            lda $0782          ; $b494: ad 82 07  
            bne __b4a0         ; $b497: d0 07     
            lda $9f            ; $b499: a5 9f     
            bpl __b4a0         ; $b49b: 10 03     
            jmp __b51c         ; $b49d: 4c 1c b5  

;-------------------------------------------------------------------------------
__b4a0:     lda #$20           ; $b4a0: a9 20     
            sta $0782          ; $b4a2: 8d 82 07  
            ldy #$00           ; $b4a5: a0 00     
            sty $0416          ; $b4a7: 8c 16 04  
            sty $0433          ; $b4aa: 8c 33 04  
            lda $b5            ; $b4ad: a5 b5     
            sta $0707          ; $b4af: 8d 07 07  
            lda $ce            ; $b4b2: a5 ce     
            sta $0708          ; $b4b4: 8d 08 07  
            lda #$01           ; $b4b7: a9 01     
            sta $1d            ; $b4b9: 85 1d     
            lda $0700          ; $b4bb: ad 00 07  
            cmp #$0a           ; $b4be: c9 0a     
            bcc __b4d2         ; $b4c0: 90 10     
            iny                ; $b4c2: c8        
            cmp #$12           ; $b4c3: c9 12     
            bcc __b4d2         ; $b4c5: 90 0b     
            iny                ; $b4c7: c8        
            cmp #$1d           ; $b4c8: c9 1d     
            bcc __b4d2         ; $b4ca: 90 06     
            iny                ; $b4cc: c8        
            cmp #$22           ; $b4cd: c9 22     
            bcc __b4d2         ; $b4cf: 90 01     
            iny                ; $b4d1: c8        
__b4d2:     lda #$01           ; $b4d2: a9 01     
            sta $0706          ; $b4d4: 8d 06 07  
            lda $0704          ; $b4d7: ad 04 07  
            beq __b4e4         ; $b4da: f0 08     
            ldy #$05           ; $b4dc: a0 05     
            lda $047d          ; $b4de: ad 7d 04  
            beq __b4e4         ; $b4e1: f0 01     
            iny                ; $b4e3: c8        
__b4e4:     lda __b424,y       ; $b4e4: b9 24 b4  
            sta $0709          ; $b4e7: 8d 09 07  
            lda __b42b,y       ; $b4ea: b9 2b b4  
            sta $070a          ; $b4ed: 8d 0a 07  
            lda __b439,y       ; $b4f0: b9 39 b4  
            sta $0433          ; $b4f3: 8d 33 04  
            lda __b432,y       ; $b4f6: b9 32 b4  
            sta $9f            ; $b4f9: 85 9f     
            lda $0704          ; $b4fb: ad 04 07  
            beq __b511         ; $b4fe: f0 11     
            lda #$04           ; $b500: a9 04     
            sta $ff            ; $b502: 85 ff     
            lda $ce            ; $b504: a5 ce     
            cmp #$14           ; $b506: c9 14     
            bcs __b51c         ; $b508: b0 12     
            lda #$00           ; $b50a: a9 00     
            sta $9f            ; $b50c: 85 9f     
            jmp __b51c         ; $b50e: 4c 1c b5  

;-------------------------------------------------------------------------------
__b511:     lda #$01           ; $b511: a9 01     
            ldy $0754          ; $b513: ac 54 07  
            beq __b51a         ; $b516: f0 02     
            lda #$80           ; $b518: a9 80     
__b51a:     sta $ff            ; $b51a: 85 ff     
__b51c:     ldy #$00           ; $b51c: a0 00     
            sty $00            ; $b51e: 84 00     
            lda $1d            ; $b520: a5 1d     
            beq __b52d         ; $b522: f0 09     
            lda $0700          ; $b524: ad 00 07  
            cmp #$1d           ; $b527: c9 1d     
            bcs __b55e         ; $b529: b0 33     
            bcc __b545         ; $b52b: 90 18     
__b52d:     iny                ; $b52d: c8        
            lda $074e          ; $b52e: ad 4e 07  
            beq __b545         ; $b531: f0 12     
            dey                ; $b533: 88        
            lda $0c            ; $b534: a5 0c     
            cmp $45            ; $b536: c5 45     
            bne __b545         ; $b538: d0 0b     
            lda $0a            ; $b53a: a5 0a     
            and #$40           ; $b53c: 29 40     
            bne __b559         ; $b53e: d0 19     
            lda $0783          ; $b540: ad 83 07  
            bne __b55e         ; $b543: d0 19     
__b545:     iny                ; $b545: c8        
            inc $00            ; $b546: e6 00     
            lda $0703          ; $b548: ad 03 07  
            bne __b554         ; $b54b: d0 07     
            lda $0700          ; $b54d: ad 00 07  
            cmp #$27           ; $b550: c9 27     
            bcc __b55e         ; $b552: 90 0a     
__b554:     inc $00            ; $b554: e6 00     
            jmp __b55e         ; $b556: 4c 5e b5  

;-------------------------------------------------------------------------------
__b559:     lda #$0a           ; $b559: a9 0a     
            sta $0783          ; $b55b: 8d 83 07  
__b55e:     lda __b440,y       ; $b55e: b9 40 b4  
            sta $0450          ; $b561: 8d 50 04  
            lda $0e            ; $b564: a5 0e     
            cmp #$07           ; $b566: c9 07     
            bne __b56c         ; $b568: d0 02     
            ldy #$03           ; $b56a: a0 03     
__b56c:     lda __b443,y       ; $b56c: b9 43 b4  
            sta $0456          ; $b56f: 8d 56 04  
            ldy $00            ; $b572: a4 00     
            lda __b447,y       ; $b574: b9 47 b4  
            sta $0702          ; $b577: 8d 02 07  
            lda #$01           ; $b57a: a9 01     
            sta $0701          ; $b57c: 8d 01 07  
            lda $33            ; $b57f: a5 33     
            cmp $45            ; $b581: c5 45     
            beq __b58b         ; $b583: f0 06     
            asl $0702          ; $b585: 0e 02 07  
            rol $0701          ; $b588: 2e 01 07  
__b58b:     rts                ; $b58b: 60        

;-------------------------------------------------------------------------------
__b58c:     .hex 02            ; $b58c: 02        Invalid Opcode - KIL 
            .hex 03 05         ; $b58d: 03 05     Invalid Opcode - SLO ($05,x)
__b58f:     .hex a0            ; $b58f: a0        Suspected data
__b590:     brk                ; $b590: 00        
            lda $0700          ; $b591: ad 00 07  
            cmp #$20           ; $b594: c9 20     
            bcs __b5ad         ; $b596: b0 15     
            iny                ; $b598: c8        
            cmp #$10           ; $b599: c9 10     
            bcs __b59e         ; $b59b: b0 01     
            iny                ; $b59d: c8        
__b59e:     lda $06fc          ; $b59e: ad fc 06  
            and #$7f           ; $b5a1: 29 7f     
            beq __b5c5         ; $b5a3: f0 20     
            and #$03           ; $b5a5: 29 03     
            cmp $45            ; $b5a7: c5 45     
            bne __b5b3         ; $b5a9: d0 08     
            lda #$00           ; $b5ab: a9 00     
__b5ad:     sta $0703          ; $b5ad: 8d 03 07  
            jmp __b5c5         ; $b5b0: 4c c5 b5  

;-------------------------------------------------------------------------------
__b5b3:     lda $0700          ; $b5b3: ad 00 07  
            cmp #$0d           ; $b5b6: c9 0d     
            bcs __b5c5         ; $b5b8: b0 0b     
            lda $33            ; $b5ba: a5 33     
            sta $45            ; $b5bc: 85 45     
            lda #$00           ; $b5be: a9 00     
            sta $57            ; $b5c0: 85 57     
            sta $0705          ; $b5c2: 8d 05 07  
__b5c5:     lda __b58c,y       ; $b5c5: b9 8c b5  
            sta $070c          ; $b5c8: 8d 0c 07  
            rts                ; $b5cb: 60        

;-------------------------------------------------------------------------------
__b5cc:     and $0490          ; $b5cc: 2d 90 04  
            cmp #$00           ; $b5cf: c9 00     
            bne __b5db         ; $b5d1: d0 08     
            lda $57            ; $b5d3: a5 57     
            beq __b620         ; $b5d5: f0 49     
            bpl __b5fc         ; $b5d7: 10 23     
            bmi __b5de         ; $b5d9: 30 03     
__b5db:     lsr                ; $b5db: 4a        
            bcc __b5fc         ; $b5dc: 90 1e     
__b5de:     lda $0705          ; $b5de: ad 05 07  
            clc                ; $b5e1: 18        
            adc $0702          ; $b5e2: 6d 02 07  
            sta $0705          ; $b5e5: 8d 05 07  
            lda $57            ; $b5e8: a5 57     
            adc $0701          ; $b5ea: 6d 01 07  
            sta $57            ; $b5ed: 85 57     
            cmp $0456          ; $b5ef: cd 56 04  
            bmi __b617         ; $b5f2: 30 23     
            lda $0456          ; $b5f4: ad 56 04  
            sta $57            ; $b5f7: 85 57     
            jmp __b620         ; $b5f9: 4c 20 b6  

;-------------------------------------------------------------------------------
__b5fc:     lda $0705          ; $b5fc: ad 05 07  
            sec                ; $b5ff: 38        
__b600:     sbc $0702          ; $b600: ed 02 07  
            sta $0705          ; $b603: 8d 05 07  
            lda $57            ; $b606: a5 57     
            sbc $0701          ; $b608: ed 01 07  
            sta $57            ; $b60b: 85 57     
            cmp $0450          ; $b60d: cd 50 04  
            bpl __b617         ; $b610: 10 05     
            lda $0450          ; $b612: ad 50 04  
            sta $57            ; $b615: 85 57     
__b617:     cmp #$00           ; $b617: c9 00     
            bpl __b620         ; $b619: 10 05     
            eor #$ff           ; $b61b: 49 ff     
            clc                ; $b61d: 18        
            adc #$01           ; $b61e: 69 01     
__b620:     sta $0700          ; $b620: 8d 00 07  
            rts                ; $b623: 60        

;-------------------------------------------------------------------------------
__b624:     lda $0756          ; $b624: ad 56 07  
            cmp #$02           ; $b627: c9 02     
            bcc __b66e         ; $b629: 90 43     
            lda $0a            ; $b62b: a5 0a     
            and #$40           ; $b62d: 29 40     
            beq __b664         ; $b62f: f0 33     
            and $0d            ; $b631: 25 0d     
            bne __b664         ; $b633: d0 2f     
            lda $06ce          ; $b635: ad ce 06  
            and #$01           ; $b638: 29 01     
            tax                ; $b63a: aa        
            lda $24,x          ; $b63b: b5 24     
            bne __b664         ; $b63d: d0 25     
            ldy $b5            ; $b63f: a4 b5     
            dey                ; $b641: 88        
            bne __b664         ; $b642: d0 20     
            lda $0714          ; $b644: ad 14 07  
            bne __b664         ; $b647: d0 1b     
            lda $1d            ; $b649: a5 1d     
            cmp #$03           ; $b64b: c9 03     
            beq __b664         ; $b64d: f0 15     
            lda #$20           ; $b64f: a9 20     
            sta $ff            ; $b651: 85 ff     
            lda #$02           ; $b653: a9 02     
            sta $24,x          ; $b655: 95 24     
            ldy $070c          ; $b657: ac 0c 07  
            sty $0711          ; $b65a: 8c 11 07  
            dey                ; $b65d: 88        
            sty $0781          ; $b65e: 8c 81 07  
            inc $06ce          ; $b661: ee ce 06  
__b664:     ldx #$00           ; $b664: a2 00     
            jsr __b689         ; $b666: 20 89 b6  
            ldx #$01           ; $b669: a2 01     
            jsr __b689         ; $b66b: 20 89 b6  
__b66e:     lda $074e          ; $b66e: ad 4e 07  
            bne __b686         ; $b671: d0 13     
            ldx #$02           ; $b673: a2 02     
__b675:     stx $08            ; $b675: 86 08     
            jsr __b6f9         ; $b677: 20 f9 b6  
            jsr __f138         ; $b67a: 20 38 f1  
            jsr __f198         ; $b67d: 20 98 f1  
            jsr __ede8         ; $b680: 20 e8 ed  
            dex                ; $b683: ca        
            bpl __b675         ; $b684: 10 ef     
__b686:     rts                ; $b686: 60        

;-------------------------------------------------------------------------------
__b687:     .hex 4c b4         ; $b687: 4c b4     Suspected data
__b689:     stx $08            ; $b689: 86 08     
            lda $24,x          ; $b68b: b5 24     
            asl                ; $b68d: 0a        
            bcs __b6f3         ; $b68e: b0 63     
            ldy $24,x          ; $b690: b4 24     
            beq __b6f2         ; $b692: f0 5e     
            dey                ; $b694: 88        
            beq __b6be         ; $b695: f0 27     
            lda $86            ; $b697: a5 86     
            adc #$04           ; $b699: 69 04     
            sta $8d,x          ; $b69b: 95 8d     
            lda $6d            ; $b69d: a5 6d     
            adc #$00           ; $b69f: 69 00     
            sta $74,x          ; $b6a1: 95 74     
            lda $ce            ; $b6a3: a5 ce     
            sta $d5,x          ; $b6a5: 95 d5     
            lda #$01           ; $b6a7: a9 01     
            sta $bc,x          ; $b6a9: 95 bc     
            ldy $33            ; $b6ab: a4 33     
            dey                ; $b6ad: 88        
            lda __b687,y       ; $b6ae: b9 87 b6  
            sta $5e,x          ; $b6b1: 95 5e     
            lda #$05           ; $b6b3: a9 05     
            sta $a6,x          ; $b6b5: 95 a6     
            lda #$07           ; $b6b7: a9 07     
            sta $04a0,x        ; $b6b9: 9d a0 04  
            dec $24,x          ; $b6bc: d6 24     
__b6be:     txa                ; $b6be: 8a        
            clc                ; $b6bf: 18        
            adc #$07           ; $b6c0: 69 07     
            tax                ; $b6c2: aa        
            lda #$60           ; $b6c3: a9 60     
            sta $00            ; $b6c5: 85 00     
            lda #$05           ; $b6c7: a9 05     
            sta $02            ; $b6c9: 85 02     
            lda #$00           ; $b6cb: a9 00     
            jsr __bfdc         ; $b6cd: 20 dc bf  
            jsr __bf14         ; $b6d0: 20 14 bf  
            ldx $08            ; $b6d3: a6 08     
            jsr __f142         ; $b6d5: 20 42 f1  
            jsr __f18e         ; $b6d8: 20 8e f1  
            jsr __e235         ; $b6db: 20 35 e2  
            jsr __e1d0         ; $b6de: 20 d0 e1  
            lda $03d2          ; $b6e1: ad d2 03  
            and #$cc           ; $b6e4: 29 cc     
            bne __b6ee         ; $b6e6: d0 06     
            jsr __d6d9         ; $b6e8: 20 d9 d6  
            jmp __ece5         ; $b6eb: 4c e5 ec  

;-------------------------------------------------------------------------------
__b6ee:     lda #$00           ; $b6ee: a9 00     
            sta $24,x          ; $b6f0: 95 24     
__b6f2:     rts                ; $b6f2: 60        

;-------------------------------------------------------------------------------
__b6f3:     jsr __f142         ; $b6f3: 20 42 f1  
            jmp __ed10         ; $b6f6: 4c 10 ed  

;-------------------------------------------------------------------------------
__b6f9:     lda $07a8,x        ; $b6f9: bd a8 07  
            and #$01           ; $b6fc: 29 01     
            sta $07            ; $b6fe: 85 07     
            lda $e4,x          ; $b700: b5 e4     
            cmp #$f8           ; $b702: c9 f8     
            bne __b732         ; $b704: d0 2c     
            lda $0792          ; $b706: ad 92 07  
            bne __b74a         ; $b709: d0 3f     
__b70b:     ldy #$00           ; $b70b: a0 00     
            lda $33            ; $b70d: a5 33     
            lsr                ; $b70f: 4a        
            bcc __b714         ; $b710: 90 02     
            ldy #$08           ; $b712: a0 08     
__b714:     tya                ; $b714: 98        
            adc $86            ; $b715: 65 86     
            sta $9c,x          ; $b717: 95 9c     
            lda $6d            ; $b719: a5 6d     
            adc #$00           ; $b71b: 69 00     
            sta $83,x          ; $b71d: 95 83     
            lda $ce            ; $b71f: a5 ce     
            clc                ; $b721: 18        
            adc #$08           ; $b722: 69 08     
            sta $e4,x          ; $b724: 95 e4     
            lda #$01           ; $b726: a9 01     
            sta $cb,x          ; $b728: 95 cb     
            ldy $07            ; $b72a: a4 07     
            lda __b74d,y       ; $b72c: b9 4d b7  
            sta $0792          ; $b72f: 8d 92 07  
__b732:     ldy $07            ; $b732: a4 07     
            lda $042c,x        ; $b734: bd 2c 04  
            sec                ; $b737: 38        
            sbc __b74b,y       ; $b738: f9 4b b7  
            sta $042c,x        ; $b73b: 9d 2c 04  
            lda $e4,x          ; $b73e: b5 e4     
            sbc #$00           ; $b740: e9 00     
            cmp #$20           ; $b742: c9 20     
            bcs __b748         ; $b744: b0 02     
            lda #$f8           ; $b746: a9 f8     
__b748:     .hex 95            ; $b748: 95        Suspected data
__b749:     .hex e4            ; $b749: e4        Suspected data
__b74a:     rts                ; $b74a: 60        

;-------------------------------------------------------------------------------
__b74b:     .hex ff 50         ; $b74b: ff 50     Suspected data
__b74d:     rti                ; $b74d: 40        

;-------------------------------------------------------------------------------
            .hex 20            ; $b74e: 20        Suspected data
__b74f:     lda $0770          ; $b74f: ad 70 07  
            beq __b7a3         ; $b752: f0 4f     
            lda $0e            ; $b754: a5 0e     
            cmp #$08           ; $b756: c9 08     
            bcc __b7a3         ; $b758: 90 49     
            .hex c9            ; $b75a: c9        Suspected data
__b75b:     .hex 0b f0         ; $b75b: 0b f0     Invalid Opcode - ANC #$f0
            eor $a5            ; $b75d: 45 a5     
            lda $c9,x          ; $b75f: b5 c9     
            .hex 02            ; $b761: 02        Invalid Opcode - KIL 
            bcs __b7a3         ; $b762: b0 3f     
            lda $0787          ; $b764: ad 87 07  
            bne __b7a3         ; $b767: d0 3a     
            lda $07f8          ; $b769: ad f8 07  
            ora $07f9          ; $b76c: 0d f9 07  
            ora $07fa          ; $b76f: 0d fa 07  
            beq __b79a         ; $b772: f0 26     
            ldy $07f8          ; $b774: ac f8 07  
            dey                ; $b777: 88        
            bne __b786         ; $b778: d0 0c     
            lda $07f9          ; $b77a: ad f9 07  
            ora $07fa          ; $b77d: 0d fa 07  
            bne __b786         ; $b780: d0 04     
            lda #$40           ; $b782: a9 40     
            sta $fc            ; $b784: 85 fc     
__b786:     lda #$14           ; $b786: a9 14     
            sta $0787          ; $b788: 8d 87 07  
            ldy #$23           ; $b78b: a0 23     
            lda #$ff           ; $b78d: a9 ff     
            sta $0139          ; $b78f: 8d 39 01  
            jsr __8f5f         ; $b792: 20 5f 8f  
            lda #$a4           ; $b795: a9 a4     
            jmp __8f06         ; $b797: 4c 06 8f  

;-------------------------------------------------------------------------------
__b79a:     sta $0756          ; $b79a: 8d 56 07  
            jsr __d932         ; $b79d: 20 32 d9  
            inc $0759          ; $b7a0: ee 59 07  
__b7a3:     rts                ; $b7a3: 60        

;-------------------------------------------------------------------------------
            lda $0723          ; $b7a4: ad 23 07  
            beq __b7a3         ; $b7a7: f0 fa     
            lda $ce            ; $b7a9: a5 ce     
            and $b5            ; $b7ab: 25 b5     
            bne __b7a3         ; $b7ad: d0 f4     
            sta $0723          ; $b7af: 8d 23 07  
            inc $06d6          ; $b7b2: ee d6 06  
            jmp __c99e         ; $b7b5: 4c 9e c9  

;-------------------------------------------------------------------------------
__b7b8:     lda $074e          ; $b7b8: ad 4e 07  
            bne __b7f4         ; $b7bb: d0 37     
            sta $047d          ; $b7bd: 8d 7d 04  
            lda $0747          ; $b7c0: ad 47 07  
            bne __b7f4         ; $b7c3: d0 2f     
            ldy #$04           ; $b7c5: a0 04     
__b7c7:     lda $0471,y        ; $b7c7: b9 71 04  
            clc                ; $b7ca: 18        
            adc $0477,y        ; $b7cb: 79 77 04  
            sta $02            ; $b7ce: 85 02     
            lda $046b,y        ; $b7d0: b9 6b 04  
            beq __b7f1         ; $b7d3: f0 1c     
            adc #$00           ; $b7d5: 69 00     
            sta $01            ; $b7d7: 85 01     
            lda $86            ; $b7d9: a5 86     
            sec                ; $b7db: 38        
            sbc $0471,y        ; $b7dc: f9 71 04  
            lda $6d            ; $b7df: a5 6d     
            sbc $046b,y        ; $b7e1: f9 6b 04  
            bmi __b7f1         ; $b7e4: 30 0b     
            lda $02            ; $b7e6: a5 02     
            sec                ; $b7e8: 38        
            sbc $86            ; $b7e9: e5 86     
            lda $01            ; $b7eb: a5 01     
            sbc $6d            ; $b7ed: e5 6d     
            bpl __b7f5         ; $b7ef: 10 04     
__b7f1:     dey                ; $b7f1: 88        
            bpl __b7c7         ; $b7f2: 10 d3     
__b7f4:     rts                ; $b7f4: 60        

;-------------------------------------------------------------------------------
__b7f5:     lda $0477,y        ; $b7f5: b9 77 04  
            lsr                ; $b7f8: 4a        
            sta $00            ; $b7f9: 85 00     
            lda $0471,y        ; $b7fb: b9 71 04  
            clc                ; $b7fe: 18        
            adc $00            ; $b7ff: 65 00     
            sta $01            ; $b801: 85 01     
            lda $046b,y        ; $b803: b9 6b 04  
            adc #$00           ; $b806: 69 00     
            sta $00            ; $b808: 85 00     
            lda $09            ; $b80a: a5 09     
            lsr                ; $b80c: 4a        
            bcc __b83b         ; $b80d: 90 2c     
            lda $01            ; $b80f: a5 01     
            sec                ; $b811: 38        
            sbc $86            ; $b812: e5 86     
            lda $00            ; $b814: a5 00     
            sbc $6d            ; $b816: e5 6d     
            bpl __b828         ; $b818: 10 0e     
            lda $86            ; $b81a: a5 86     
__b81c:     sec                ; $b81c: 38        
            sbc #$01           ; $b81d: e9 01     
            sta $86            ; $b81f: 85 86     
            lda $6d            ; $b821: a5 6d     
            sbc #$00           ; $b823: e9 00     
            jmp __b839         ; $b825: 4c 39 b8  

;-------------------------------------------------------------------------------
__b828:     lda $0490          ; $b828: ad 90 04  
            lsr                ; $b82b: 4a        
            bcc __b83b         ; $b82c: 90 0d     
            lda $86            ; $b82e: a5 86     
            clc                ; $b830: 18        
            adc #$01           ; $b831: 69 01     
            sta $86            ; $b833: 85 86     
            lda $6d            ; $b835: a5 6d     
            adc #$00           ; $b837: 69 00     
__b839:     sta $6d            ; $b839: 85 6d     
__b83b:     lda #$10           ; $b83b: a9 10     
            sta $00            ; $b83d: 85 00     
            lda #$01           ; $b83f: a9 01     
            sta $047d          ; $b841: 8d 7d 04  
            sta $02            ; $b844: 85 02     
            lsr                ; $b846: 4a        
            tax                ; $b847: aa        
            jmp __bfdc         ; $b848: 4c dc bf  

;-------------------------------------------------------------------------------
__b84b:     ora $02            ; $b84b: 05 02     
            php                ; $b84d: 08        
            .hex 04 01         ; $b84e: 04 01     Invalid Opcode - NOP $01
__b850:     .hex 03 03         ; $b850: 03 03     Invalid Opcode - SLO ($03,x)
            .hex 04 04         ; $b852: 04 04     Invalid Opcode - NOP $04
            .hex 04            ; $b854: 04        Suspected data
__b855:     ldx #$05           ; $b855: a2 05     
            stx $08            ; $b857: 86 08     
            lda $16,x          ; $b859: b5 16     
            cmp #$30           ; $b85b: c9 30     
            bne __b8b5         ; $b85d: d0 56     
            lda $0e            ; $b85f: a5 0e     
            cmp #$04           ; $b861: c9 04     
            bne __b896         ; $b863: d0 31     
            lda $1d            ; $b865: a5 1d     
            cmp #$03           ; $b867: c9 03     
            bne __b896         ; $b869: d0 2b     
            lda $cf,x          ; $b86b: b5 cf     
            cmp #$aa           ; $b86d: c9 aa     
            bcs __b899         ; $b86f: b0 28     
            lda $ce            ; $b871: a5 ce     
            cmp #$a2           ; $b873: c9 a2     
            bcs __b899         ; $b875: b0 22     
            lda $0417,x        ; $b877: bd 17 04  
            adc #$ff           ; $b87a: 69 ff     
            sta $0417,x        ; $b87c: 9d 17 04  
            lda $cf,x          ; $b87f: b5 cf     
            adc #$01           ; $b881: 69 01     
            sta $cf,x          ; $b883: 95 cf     
            lda $010e          ; $b885: ad 0e 01  
            sec                ; $b888: 38        
            sbc #$ff           ; $b889: e9 ff     
            sta $010e          ; $b88b: 8d 0e 01  
            lda $010d          ; $b88e: ad 0d 01  
            sbc #$01           ; $b891: e9 01     
            sta $010d          ; $b893: 8d 0d 01  
__b896:     jmp __b8ac         ; $b896: 4c ac b8  

;-------------------------------------------------------------------------------
__b899:     ldy $010f          ; $b899: ac 0f 01  
            lda __b84b,y       ; $b89c: b9 4b b8  
            ldx __b850,y       ; $b89f: be 50 b8  
            sta $0134,x        ; $b8a2: 9d 34 01  
            jsr __bc2c         ; $b8a5: 20 2c bc  
            lda #$05           ; $b8a8: a9 05     
            sta $0e            ; $b8aa: 85 0e     
__b8ac:     jsr __f1b6         ; $b8ac: 20 b6 f1  
            jsr __f159         ; $b8af: 20 59 f1  
            jsr __e552         ; $b8b2: 20 52 e5  
__b8b5:     rts                ; $b8b5: 60        

;-------------------------------------------------------------------------------
__b8b6:     php                ; $b8b6: 08        
            bpl __b8c1         ; $b8b7: 10 08     
            brk                ; $b8b9: 00        
            .hex 20            ; $b8ba: 20        Suspected data
__b8bb:     ldx $f1,y          ; $b8bb: b6 f1     
            lda $0747          ; $b8bd: ad 47 07  
            .hex d0            ; $b8c0: d0        Suspected data
__b8c1:     eor $ad            ; $b8c1: 45 ad     
            asl __f007         ; $b8c3: 0e 07 f0  
            rti                ; $b8c6: 40        

;-------------------------------------------------------------------------------
            tay                ; $b8c7: a8        
            dey                ; $b8c8: 88        
            tya                ; $b8c9: 98        
            and #$02           ; $b8ca: 29 02     
            bne __b8d5         ; $b8cc: d0 07     
            inc $ce            ; $b8ce: e6 ce     
            inc $ce            ; $b8d0: e6 ce     
            jmp __b8d9         ; $b8d2: 4c d9 b8  

;-------------------------------------------------------------------------------
__b8d5:     dec $ce            ; $b8d5: c6 ce     
            dec $ce            ; $b8d7: c6 ce     
__b8d9:     lda $58,x          ; $b8d9: b5 58     
            clc                ; $b8db: 18        
            adc __b8b6,y       ; $b8dc: 79 b6 b8  
            sta $cf,x          ; $b8df: 95 cf     
            cpy #$01           ; $b8e1: c0 01     
            bcc __b8f4         ; $b8e3: 90 0f     
            lda $0a            ; $b8e5: a5 0a     
            and #$80           ; $b8e7: 29 80     
            beq __b8f4         ; $b8e9: f0 09     
            and $0d            ; $b8eb: 25 0d     
            bne __b8f4         ; $b8ed: d0 05     
            lda #$f2           ; $b8ef: a9 f2     
            sta $06db          ; $b8f1: 8d db 06  
__b8f4:     cpy #$03           ; $b8f4: c0 03     
            bne __b907         ; $b8f6: d0 0f     
            lda $06db          ; $b8f8: ad db 06  
            sta $9f            ; $b8fb: 85 9f     
            lda #$40           ; $b8fd: a9 40     
            sta $0709          ; $b8ff: 8d 09 07  
            lda #$00           ; $b902: a9 00     
            sta $070e          ; $b904: 8d 0e 07  
__b907:     jsr __f159         ; $b907: 20 59 f1  
            jsr __e884         ; $b90a: 20 84 e8  
            jsr __d642         ; $b90d: 20 42 d6  
            lda $070e          ; $b910: ad 0e 07  
            beq __b922         ; $b913: f0 0d     
            lda $0786          ; $b915: ad 86 07  
            bne __b922         ; $b918: d0 08     
            lda #$04           ; $b91a: a9 04     
            sta $0786          ; $b91c: 8d 86 07  
            inc $070e          ; $b91f: ee 0e 07  
__b922:     rts                ; $b922: 60        

;-------------------------------------------------------------------------------
__b923:     lda #$2f           ; $b923: a9 2f     
            sta $16,x          ; $b925: 95 16     
            lda #$01           ; $b927: a9 01     
            sta $0f,x          ; $b929: 95 0f     
            lda $0076,y        ; $b92b: b9 76 00  
            sta $6e,x          ; $b92e: 95 6e     
            lda $008f,y        ; $b930: b9 8f 00  
            sta $87,x          ; $b933: 95 87     
            lda $00d7,y        ; $b935: b9 d7 00  
            sta $cf,x          ; $b938: 95 cf     
            ldy $0398          ; $b93a: ac 98 03  
            bne __b942         ; $b93d: d0 03     
            sta $039d          ; $b93f: 8d 9d 03  
__b942:     txa                ; $b942: 8a        
            sta $039a,y        ; $b943: 99 9a 03  
            inc $0398          ; $b946: ee 98 03  
            lda #$04           ; $b949: a9 04     
            sta $fe            ; $b94b: 85 fe     
            rts                ; $b94d: 60        

;-------------------------------------------------------------------------------
__b94e:     bmi __b9b0         ; $b94e: 30 60     
__b950:     cpx #$05           ; $b950: e0 05     
            bne __b9bc         ; $b952: d0 68     
            ldy $0398          ; $b954: ac 98 03  
            dey                ; $b957: 88        
            lda $0399          ; $b958: ad 99 03  
            cmp __b94e,y       ; $b95b: d9 4e b9  
            beq __b96f         ; $b95e: f0 0f     
            lda $09            ; $b960: a5 09     
            lsr                ; $b962: 4a        
            lsr                ; $b963: 4a        
            bcc __b96f         ; $b964: 90 09     
            lda $d4            ; $b966: a5 d4     
            sbc #$01           ; $b968: e9 01     
            sta $d4            ; $b96a: 85 d4     
            inc $0399          ; $b96c: ee 99 03  
__b96f:     lda $0399          ; $b96f: ad 99 03  
            cmp #$08           ; $b972: c9 08     
            bcc __b9bc         ; $b974: 90 46     
            jsr __f159         ; $b976: 20 59 f1  
            jsr __f1b6         ; $b979: 20 b6 f1  
            ldy #$00           ; $b97c: a0 00     
__b97e:     jsr __e43c         ; $b97e: 20 3c e4  
            iny                ; $b981: c8        
            cpy $0398          ; $b982: cc 98 03  
            bne __b97e         ; $b985: d0 f7     
            lda $03d1          ; $b987: ad d1 03  
            and #$0c           ; $b98a: 29 0c     
            beq __b99e         ; $b98c: f0 10     
            dey                ; $b98e: 88        
__b98f:     ldx $039a,y        ; $b98f: be 9a 03  
            jsr __c99e         ; $b992: 20 9e c9  
            dey                ; $b995: 88        
            bpl __b98f         ; $b996: 10 f7     
            sta $0398          ; $b998: 8d 98 03  
            sta $0399          ; $b99b: 8d 99 03  
__b99e:     lda $0399          ; $b99e: ad 99 03  
            cmp #$20           ; $b9a1: c9 20     
            bcc __b9bc         ; $b9a3: 90 17     
            ldx #$06           ; $b9a5: a2 06     
            lda #$01           ; $b9a7: a9 01     
            ldy #$1b           ; $b9a9: a0 1b     
            jsr __e3f8         ; $b9ab: 20 f8 e3  
            ldy $02            ; $b9ae: a4 02     
__b9b0:     cpy #$d0           ; $b9b0: c0 d0     
            bcs __b9bc         ; $b9b2: b0 08     
            lda ($06),y        ; $b9b4: b1 06     
            bne __b9bc         ; $b9b6: d0 04     
            lda #$26           ; $b9b8: a9 26     
            sta ($06),y        ; $b9ba: 91 06     
__b9bc:     ldx $08            ; $b9bc: a6 08     
            rts                ; $b9be: 60        

;-------------------------------------------------------------------------------
__b9bf:     .hex 0f 07         ; $b9bf: 0f 07     Suspected data
__b9c1:     lda $074e          ; $b9c1: ad 4e 07  
            beq __ba35         ; $b9c4: f0 6f     
            ldx #$02           ; $b9c6: a2 02     
__b9c8:     stx $08            ; $b9c8: 86 08     
            lda $0f,x          ; $b9ca: b5 0f     
            bne __ba1f         ; $b9cc: d0 51     
            lda $07a8,x        ; $b9ce: bd a8 07  
            ldy $06cc          ; $b9d1: ac cc 06  
            and __b9bf,y       ; $b9d4: 39 bf b9  
            cmp #$06           ; $b9d7: c9 06     
            bcs __ba1f         ; $b9d9: b0 44     
            tay                ; $b9db: a8        
            lda $046b,y        ; $b9dc: b9 6b 04  
            beq __ba1f         ; $b9df: f0 3e     
            lda $047d,y        ; $b9e1: b9 7d 04  
            beq __b9ee         ; $b9e4: f0 08     
            sbc #$00           ; $b9e6: e9 00     
            sta $047d,y        ; $b9e8: 99 7d 04  
            jmp __ba1f         ; $b9eb: 4c 1f ba  

;-------------------------------------------------------------------------------
__b9ee:     lda $0747          ; $b9ee: ad 47 07  
            bne __ba1f         ; $b9f1: d0 2c     
            lda #$0e           ; $b9f3: a9 0e     
            sta $047d,y        ; $b9f5: 99 7d 04  
            lda $046b,y        ; $b9f8: b9 6b 04  
            sta $6e,x          ; $b9fb: 95 6e     
            lda $0471,y        ; $b9fd: b9 71 04  
            sta $87,x          ; $ba00: 95 87     
            lda $0477,y        ; $ba02: b9 77 04  
            sec                ; $ba05: 38        
            sbc #$08           ; $ba06: e9 08     
            sta $cf,x          ; $ba08: 95 cf     
            lda #$01           ; $ba0a: a9 01     
            sta $b6,x          ; $ba0c: 95 b6     
            sta $0f,x          ; $ba0e: 95 0f     
            lsr                ; $ba10: 4a        
            sta $1e,x          ; $ba11: 95 1e     
            lda #$09           ; $ba13: a9 09     
            sta $049a,x        ; $ba15: 9d 9a 04  
            lda #$33           ; $ba18: a9 33     
            sta $16,x          ; $ba1a: 95 16     
            jmp __ba32         ; $ba1c: 4c 32 ba  

;-------------------------------------------------------------------------------
__ba1f:     lda $16,x          ; $ba1f: b5 16     
            cmp #$33           ; $ba21: c9 33     
            bne __ba32         ; $ba23: d0 0d     
            jsr __d642         ; $ba25: 20 42 d6  
            lda $0f,x          ; $ba28: b5 0f     
            beq __ba32         ; $ba2a: f0 06     
            jsr __f1b6         ; $ba2c: 20 b6 f1  
            jsr __ba38         ; $ba2f: 20 38 ba  
__ba32:     dex                ; $ba32: ca        
            bpl __b9c8         ; $ba33: 10 93     
__ba35:     rts                ; $ba35: 60        

;-------------------------------------------------------------------------------
__ba36:     .hex 1c e4         ; $ba36: 1c e4     Suspected data
__ba38:     lda $0747          ; $ba38: ad 47 07  
            bne __ba7b         ; $ba3b: d0 3e     
            lda $1e,x          ; $ba3d: b5 1e     
            bne __ba6f         ; $ba3f: d0 2e     
            lda $03d1          ; $ba41: ad d1 03  
            and #$0c           ; $ba44: 29 0c     
            cmp #$0c           ; $ba46: c9 0c     
            beq __ba8a         ; $ba48: f0 40     
            ldy #$01           ; $ba4a: a0 01     
            jsr __e14b         ; $ba4c: 20 4b e1  
            bmi __ba52         ; $ba4f: 30 01     
            iny                ; $ba51: c8        
__ba52:     sty $46,x          ; $ba52: 94 46     
            dey                ; $ba54: 88        
            lda __ba36,y       ; $ba55: b9 36 ba  
            sta $58,x          ; $ba58: 95 58     
            lda $00            ; $ba5a: a5 00     
            adc #$28           ; $ba5c: 69 28     
            cmp #$50           ; $ba5e: c9 50     
            bcc __ba8a         ; $ba60: 90 28     
            lda #$01           ; $ba62: a9 01     
            sta $1e,x          ; $ba64: 95 1e     
            lda #$09           ; $ba66: a9 09     
            sta $078a,x        ; $ba68: 9d 8a 07  
            lda #$08           ; $ba6b: a9 08     
            sta $fe            ; $ba6d: 85 fe     
__ba6f:     lda $1e,x          ; $ba6f: b5 1e     
            and #$20           ; $ba71: 29 20     
            beq __ba78         ; $ba73: f0 03     
            jsr __bf68         ; $ba75: 20 68 bf  
__ba78:     jsr __bf07         ; $ba78: 20 07 bf  
__ba7b:     jsr __f1b6         ; $ba7b: 20 b6 f1  
            jsr __f159         ; $ba7e: 20 59 f1  
            jsr __e24b         ; $ba81: 20 4b e2  
            jsr __d853         ; $ba84: 20 53 d8  
            jmp __e884         ; $ba87: 4c 84 e8  

;-------------------------------------------------------------------------------
__ba8a:     jsr __c99e         ; $ba8a: 20 9e c9  
            rts                ; $ba8d: 60        

;-------------------------------------------------------------------------------
__ba8e:     .hex 04 04         ; $ba8e: 04 04     Invalid Opcode - NOP $04
            .hex 04 05         ; $ba90: 04 05     Invalid Opcode - NOP $05
            ora $05            ; $ba92: 05 05     
            asl $06            ; $ba94: 06 06     
            .hex 06            ; $ba96: 06        Suspected data
__ba97:     .hex 14 ec         ; $ba97: 14 ec     Invalid Opcode - NOP $ec,x
__ba99:     lda $07a8          ; $ba99: ad a8 07  
            and #$07           ; $ba9c: 29 07     
            bne __baa5         ; $ba9e: d0 05     
            lda $07a8          ; $baa0: ad a8 07  
            and #$08           ; $baa3: 29 08     
__baa5:     tay                ; $baa5: a8        
            lda $002a,y        ; $baa6: b9 2a 00  
            bne __bac4         ; $baa9: d0 19     
            ldx __ba8e,y       ; $baab: be 8e ba  
            lda $0f,x          ; $baae: b5 0f     
            bne __bac4         ; $bab0: d0 12     
            ldx $08            ; $bab2: a6 08     
            txa                ; $bab4: 8a        
            sta $06ae,y        ; $bab5: 99 ae 06  
            lda #$90           ; $bab8: a9 90     
            sta $002a,y        ; $baba: 99 2a 00  
            lda #$07           ; $babd: a9 07     
            sta $04a2,y        ; $babf: 99 a2 04  
            sec                ; $bac2: 38        
            rts                ; $bac3: 60        

;-------------------------------------------------------------------------------
__bac4:     ldx $08            ; $bac4: a6 08     
            clc                ; $bac6: 18        
            rts                ; $bac7: 60        

;-------------------------------------------------------------------------------
__bac8:     lda $0747          ; $bac8: ad 47 07  
            bne __bb30         ; $bacb: d0 63     
            lda $2a,x          ; $bacd: b5 2a     
            and #$7f           ; $bacf: 29 7f     
            .hex bc            ; $bad1: bc        Suspected data
__bad2:     ldx __c906         ; $bad2: ae 06 c9  
            .hex 02            ; $bad5: 02        Invalid Opcode - KIL 
            beq __baf8         ; $bad6: f0 20     
            bcs __bb0e         ; $bad8: b0 34     
            txa                ; $bada: 8a        
            clc                ; $badb: 18        
            adc #$0d           ; $badc: 69 0d     
            tax                ; $bade: aa        
            lda #$23           ; $badf: a9 23     
            sta $00            ; $bae1: 85 00     
            lda #$0f           ; $bae3: a9 0f     
            sta $01            ; $bae5: 85 01     
            lda #$04           ; $bae7: a9 04     
            sta $02            ; $bae9: 85 02     
            lda #$00           ; $baeb: a9 00     
            jsr __bfdc         ; $baed: 20 dc bf  
            jsr __bf14         ; $baf0: 20 14 bf  
            ldx $08            ; $baf3: a6 08     
            jmp __bb2d         ; $baf5: 4c 2d bb  

;-------------------------------------------------------------------------------
__baf8:     lda #$fd           ; $baf8: a9 fd     
            sta $ac,x          ; $bafa: 95 ac     
            lda $001e,y        ; $bafc: b9 1e 00  
            and #$f7           ; $baff: 29 f7     
            sta $001e,y        ; $bb01: 99 1e 00  
            ldx $46,y          ; $bb04: b6 46     
            dex                ; $bb06: ca        
            lda __ba97,x       ; $bb07: bd 97 ba  
            ldx $08            ; $bb0a: a6 08     
            sta $64,x          ; $bb0c: 95 64     
__bb0e:     dec $2a,x          ; $bb0e: d6 2a     
            lda $0087,y        ; $bb10: b9 87 00  
            clc                ; $bb13: 18        
            adc #$02           ; $bb14: 69 02     
            sta $93,x          ; $bb16: 95 93     
            lda $006e,y        ; $bb18: b9 6e 00  
            adc #$00           ; $bb1b: 69 00     
            sta $7a,x          ; $bb1d: 95 7a     
            lda $00cf,y        ; $bb1f: b9 cf 00  
            sec                ; $bb22: 38        
            sbc #$0a           ; $bb23: e9 0a     
            sta $db,x          ; $bb25: 95 db     
            lda #$01           ; $bb27: a9 01     
            sta $c2,x          ; $bb29: 95 c2     
            bne __bb30         ; $bb2b: d0 03     
__bb2d:     jsr __d7c4         ; $bb2d: 20 c4 d7  
__bb30:     jsr __f1a2         ; $bb30: 20 a2 f1  
            jsr __f14f         ; $bb33: 20 4f f1  
            jsr __e23e         ; $bb36: 20 3e e2  
            jsr __e4e3         ; $bb39: 20 e3 e4  
            rts                ; $bb3c: 60        

;-------------------------------------------------------------------------------
__bb3d:     jsr __bb89         ; $bb3d: 20 89 bb  
            lda $76,x          ; $bb40: b5 76     
            sta $007a,y        ; $bb42: 99 7a 00  
            lda $8f,x          ; $bb45: b5 8f     
            ora #$05           ; $bb47: 09 05     
            sta $0093,y        ; $bb49: 99 93 00  
            lda $d7,x          ; $bb4c: b5 d7     
            sbc #$10           ; $bb4e: e9 10     
            sta $00db,y        ; $bb50: 99 db 00  
            jmp __bb71         ; $bb53: 4c 71 bb  

;-------------------------------------------------------------------------------
__bb56:     jsr __bb89         ; $bb56: 20 89 bb  
            lda $03ea,x        ; $bb59: bd ea 03  
            sta $007a,y        ; $bb5c: 99 7a 00  
            lda $06            ; $bb5f: a5 06     
            asl                ; $bb61: 0a        
            asl                ; $bb62: 0a        
            asl                ; $bb63: 0a        
            asl                ; $bb64: 0a        
            ora #$05           ; $bb65: 09 05     
            sta $0093,y        ; $bb67: 99 93 00  
            lda $02            ; $bb6a: a5 02     
            adc #$20           ; $bb6c: 69 20     
            sta $00db,y        ; $bb6e: 99 db 00  
__bb71:     lda #$fb           ; $bb71: a9 fb     
            sta $00ac,y        ; $bb73: 99 ac 00  
            lda #$01           ; $bb76: a9 01     
            sta $00c2,y        ; $bb78: 99 c2 00  
            sta $002a,y        ; $bb7b: 99 2a 00  
            sta $fe            ; $bb7e: 85 fe     
            stx $08            ; $bb80: 86 08     
            jsr __bc03         ; $bb82: 20 03 bc  
            inc $0748          ; $bb85: ee 48 07  
            rts                ; $bb88: 60        

;-------------------------------------------------------------------------------
__bb89:     ldy #$08           ; $bb89: a0 08     
__bb8b:     lda $002a,y        ; $bb8b: b9 2a 00  
            beq __bb97         ; $bb8e: f0 07     
            dey                ; $bb90: 88        
            cpy #$05           ; $bb91: c0 05     
            bne __bb8b         ; $bb93: d0 f6     
            ldy #$08           ; $bb95: a0 08     
__bb97:     sty $06b7          ; $bb97: 8c b7 06  
            rts                ; $bb9a: 60        

;-------------------------------------------------------------------------------
__bb9b:     ldx #$08           ; $bb9b: a2 08     
__bb9d:     stx $08            ; $bb9d: 86 08     
            lda $2a,x          ; $bb9f: b5 2a     
            beq __bbf9         ; $bba1: f0 56     
            asl                ; $bba3: 0a        
            bcc __bbac         ; $bba4: 90 06     
            jsr __bac8         ; $bba6: 20 c8 ba  
            jmp __bbf9         ; $bba9: 4c f9 bb  

;-------------------------------------------------------------------------------
__bbac:     ldy $2a,x          ; $bbac: b4 2a     
            dey                ; $bbae: 88        
            beq __bbce         ; $bbaf: f0 1d     
            inc $2a,x          ; $bbb1: f6 2a     
            lda $93,x          ; $bbb3: b5 93     
            clc                ; $bbb5: 18        
            adc $0775          ; $bbb6: 6d 75 07  
            sta $93,x          ; $bbb9: 95 93     
            lda $7a,x          ; $bbbb: b5 7a     
            adc #$00           ; $bbbd: 69 00     
            sta $7a,x          ; $bbbf: 95 7a     
            lda $2a,x          ; $bbc1: b5 2a     
            cmp #$30           ; $bbc3: c9 30     
            bne __bbed         ; $bbc5: d0 26     
            lda #$00           ; $bbc7: a9 00     
            sta $2a,x          ; $bbc9: 95 2a     
            jmp __bbf9         ; $bbcb: 4c f9 bb  

;-------------------------------------------------------------------------------
__bbce:     txa                ; $bbce: 8a        
            clc                ; $bbcf: 18        
            adc #$0d           ; $bbd0: 69 0d     
            tax                ; $bbd2: aa        
            lda #$50           ; $bbd3: a9 50     
            sta $00            ; $bbd5: 85 00     
            lda #$06           ; $bbd7: a9 06     
            sta $02            ; $bbd9: 85 02     
            lsr                ; $bbdb: 4a        
            sta $01            ; $bbdc: 85 01     
            lda #$00           ; $bbde: a9 00     
            jsr __bfdc         ; $bbe0: 20 dc bf  
            ldx $08            ; $bbe3: a6 08     
            lda $ac,x          ; $bbe5: b5 ac     
            cmp #$05           ; $bbe7: c9 05     
            bne __bbed         ; $bbe9: d0 02     
            inc $2a,x          ; $bbeb: f6 2a     
__bbed:     jsr __f14f         ; $bbed: 20 4f f1  
            jsr __f1a2         ; $bbf0: 20 a2 f1  
            jsr __e23e         ; $bbf3: 20 3e e2  
            jsr __e68d         ; $bbf6: 20 8d e6  
__bbf9:     dex                ; $bbf9: ca        
            bpl __bb9d         ; $bbfa: 10 a1     
            rts                ; $bbfc: 60        

;-------------------------------------------------------------------------------
__bbfd:     .hex 17 1d         ; $bbfd: 17 1d     Invalid Opcode - SLO $1d,x
__bbff:     .hex 0b 11         ; $bbff: 0b 11     Invalid Opcode - ANC #$11
__bc01:     .hex 02            ; $bc01: 02        Invalid Opcode - KIL 
            .hex 13            ; $bc02: 13        Suspected data
__bc03:     lda #$01           ; $bc03: a9 01     
            sta $0139          ; $bc05: 8d 39 01  
            ldx $0753          ; $bc08: ae 53 07  
            ldy __bbfd,x       ; $bc0b: bc fd bb  
            jsr __8f5f         ; $bc0e: 20 5f 8f  
            inc $075e          ; $bc11: ee 5e 07  
            lda $075e          ; $bc14: ad 5e 07  
            cmp #$64           ; $bc17: c9 64     
            bne __bc27         ; $bc19: d0 0c     
            lda #$00           ; $bc1b: a9 00     
            sta $075e          ; $bc1d: 8d 5e 07  
            inc $075a          ; $bc20: ee 5a 07  
            lda #$40           ; $bc23: a9 40     
            sta $fe            ; $bc25: 85 fe     
__bc27:     lda #$02           ; $bc27: a9 02     
            sta $0138          ; $bc29: 8d 38 01  
__bc2c:     ldx $0753          ; $bc2c: ae 53 07  
            ldy __bbff,x       ; $bc2f: bc ff bb  
            jsr __8f5f         ; $bc32: 20 5f 8f  
__bc35:     ldy $0753          ; $bc35: ac 53 07  
            lda __bc01,y       ; $bc38: b9 01 bc  
__bc3b:     jsr __8f06         ; $bc3b: 20 06 8f  
            ldy $0300          ; $bc3e: ac 00 03  
            lda $02fb,y        ; $bc41: b9 fb 02  
            bne __bc4b         ; $bc44: d0 05     
            lda #$24           ; $bc46: a9 24     
            sta $02fb,y        ; $bc48: 99 fb 02  
__bc4b:     ldx $08            ; $bc4b: a6 08     
            rts                ; $bc4d: 60        

;-------------------------------------------------------------------------------
__bc4e:     lda #$2e           ; $bc4e: a9 2e     
            sta $1b            ; $bc50: 85 1b     
            lda $76,x          ; $bc52: b5 76     
            sta $73            ; $bc54: 85 73     
            lda $8f,x          ; $bc56: b5 8f     
            sta $8c            ; $bc58: 85 8c     
            lda #$01           ; $bc5a: a9 01     
            sta $bb            ; $bc5c: 85 bb     
            lda $d7,x          ; $bc5e: b5 d7     
            sec                ; $bc60: 38        
            sbc #$08           ; $bc61: e9 08     
            sta $d4            ; $bc63: 85 d4     
            lda #$01           ; $bc65: a9 01     
            sta $23            ; $bc67: 85 23     
            sta $14            ; $bc69: 85 14     
            lda #$03           ; $bc6b: a9 03     
            sta $049f          ; $bc6d: 8d 9f 04  
            lda $39            ; $bc70: a5 39     
            cmp #$02           ; $bc72: c9 02     
            bcs __bc80         ; $bc74: b0 0a     
            lda $0756          ; $bc76: ad 56 07  
            cmp #$02           ; $bc79: c9 02     
            bcc __bc7e         ; $bc7b: 90 01     
            lsr                ; $bc7d: 4a        
__bc7e:     sta $39            ; $bc7e: 85 39     
__bc80:     lda #$20           ; $bc80: a9 20     
            sta $03ca          ; $bc82: 8d ca 03  
            lda #$02           ; $bc85: a9 02     
            sta $fe            ; $bc87: 85 fe     
            rts                ; $bc89: 60        

;-------------------------------------------------------------------------------
            ldx #$05           ; $bc8a: a2 05     
            stx $08            ; $bc8c: 86 08     
            lda $23            ; $bc8e: a5 23     
            beq __bcef         ; $bc90: f0 5d     
            asl                ; $bc92: 0a        
            bcc __bcb8         ; $bc93: 90 23     
            lda $0747          ; $bc95: ad 47 07  
            bne __bcdd         ; $bc98: d0 43     
            lda $39            ; $bc9a: a5 39     
            beq __bcaf         ; $bc9c: f0 11     
            cmp #$03           ; $bc9e: c9 03     
            beq __bcaf         ; $bca0: f0 0d     
            cmp #$02           ; $bca2: c9 02     
            bne __bcdd         ; $bca4: d0 37     
            jsr __caff         ; $bca6: 20 ff ca  
            jsr __e16b         ; $bca9: 20 6b e1  
            jmp __bcdd         ; $bcac: 4c dd bc  

;-------------------------------------------------------------------------------
__bcaf:     jsr __ca7d         ; $bcaf: 20 7d ca  
            jsr __dfc9         ; $bcb2: 20 c9 df  
            jmp __bcdd         ; $bcb5: 4c dd bc  

;-------------------------------------------------------------------------------
__bcb8:     lda $09            ; $bcb8: a5 09     
            and #$03           ; $bcba: 29 03     
            .hex d0            ; $bcbc: d0        Suspected data
__bcbd:     ora __d4c6,y       ; $bcbd: 19 c6 d4  
            lda $23            ; $bcc0: a5 23     
            inc $23            ; $bcc2: e6 23     
            cmp #$11           ; $bcc4: c9 11     
            bcc __bcd7         ; $bcc6: 90 0f     
            lda #$10           ; $bcc8: a9 10     
            sta $58,x          ; $bcca: 95 58     
            lda #$80           ; $bccc: a9 80     
            sta $23            ; $bcce: 85 23     
            asl                ; $bcd0: 0a        
            sta $03ca          ; $bcd1: 8d ca 03  
            rol                ; $bcd4: 2a        
            sta $46,x          ; $bcd5: 95 46     
__bcd7:     lda $23            ; $bcd7: a5 23     
            cmp #$06           ; $bcd9: c9 06     
            bcc __bcef         ; $bcdb: 90 12     
__bcdd:     jsr __f159         ; $bcdd: 20 59 f1  
            jsr __f1b6         ; $bce0: 20 b6 f1  
            jsr __e24b         ; $bce3: 20 4b e2  
            jsr __e6d9         ; $bce6: 20 d9 e6  
            jsr __d853         ; $bce9: 20 53 d8  
            jsr __d642         ; $bcec: 20 42 d6  
__bcef:     rts                ; $bcef: 60        

;-------------------------------------------------------------------------------
__bcf0:     .hex 04 12         ; $bcf0: 04 12     Invalid Opcode - NOP $12
__bcf2:     pha                ; $bcf2: 48        
            lda #$11           ; $bcf3: a9 11     
            ldx $03ee          ; $bcf5: ae ee 03  
            ldy $0754          ; $bcf8: ac 54 07  
            bne __bcff         ; $bcfb: d0 02     
            lda #$12           ; $bcfd: a9 12     
__bcff:     sta $26,x          ; $bcff: 95 26     
            jsr __8a6b         ; $bd01: 20 6b 8a  
            ldx $03ee          ; $bd04: ae ee 03  
            lda $02            ; $bd07: a5 02     
            sta $03e4,x        ; $bd09: 9d e4 03  
            tay                ; $bd0c: a8        
            lda $06            ; $bd0d: a5 06     
            sta $03e6,x        ; $bd0f: 9d e6 03  
            lda ($06),y        ; $bd12: b1 06     
            jsr __bdfb         ; $bd14: 20 fb bd  
            sta $00            ; $bd17: 85 00     
            ldy $0754          ; $bd19: ac 54 07  
            bne __bd1f         ; $bd1c: d0 01     
            tya                ; $bd1e: 98        
__bd1f:     bcc __bd46         ; $bd1f: 90 25     
            ldy #$11           ; $bd21: a0 11     
            sty $26,x          ; $bd23: 94 26     
            lda #$c4           ; $bd25: a9 c4     
            ldy $00            ; $bd27: a4 00     
            cpy #$58           ; $bd29: c0 58     
            beq __bd31         ; $bd2b: f0 04     
            cpy #$5d           ; $bd2d: c0 5d     
            bne __bd46         ; $bd2f: d0 15     
__bd31:     lda $06bc          ; $bd31: ad bc 06  
            bne __bd3e         ; $bd34: d0 08     
            lda #$0b           ; $bd36: a9 0b     
            sta $079d          ; $bd38: 8d 9d 07  
            inc $06bc          ; $bd3b: ee bc 06  
__bd3e:     lda $079d          ; $bd3e: ad 9d 07  
            bne __bd45         ; $bd41: d0 02     
            ldy #$c4           ; $bd43: a0 c4     
__bd45:     tya                ; $bd45: 98        
__bd46:     sta $03e8,x        ; $bd46: 9d e8 03  
            jsr __bd89         ; $bd49: 20 89 bd  
            ldy $02            ; $bd4c: a4 02     
            lda #$23           ; $bd4e: a9 23     
            sta ($06),y        ; $bd50: 91 06     
            lda #$0c           ; $bd52: a9 0c     
            sta $0784          ; $bd54: 8d 84 07  
            pla                ; $bd57: 68        
            sta $05            ; $bd58: 85 05     
            ldy #$00           ; $bd5a: a0 00     
            lda $0714          ; $bd5c: ad 14 07  
            bne __bd66         ; $bd5f: d0 05     
            lda $0754          ; $bd61: ad 54 07  
            beq __bd67         ; $bd64: f0 01     
__bd66:     iny                ; $bd66: c8        
__bd67:     lda $ce            ; $bd67: a5 ce     
            clc                ; $bd69: 18        
            adc __bcf0,y       ; $bd6a: 79 f0 bc  
            and #$f0           ; $bd6d: 29 f0     
            sta $d7,x          ; $bd6f: 95 d7     
            ldy $26,x          ; $bd71: b4 26     
            cpy #$11           ; $bd73: c0 11     
            beq __bd7d         ; $bd75: f0 06     
            jsr __be07         ; $bd77: 20 07 be  
            jmp __bd80         ; $bd7a: 4c 80 bd  

;-------------------------------------------------------------------------------
__bd7d:     jsr __bda0         ; $bd7d: 20 a0 bd  
__bd80:     lda $03ee          ; $bd80: ad ee 03  
            eor #$01           ; $bd83: 49 01     
            sta $03ee          ; $bd85: 8d ee 03  
            rts                ; $bd88: 60        

;-------------------------------------------------------------------------------
__bd89:     lda $86            ; $bd89: a5 86     
            clc                ; $bd8b: 18        
            adc #$08           ; $bd8c: 69 08     
            and #$f0           ; $bd8e: 29 f0     
            sta $8f,x          ; $bd90: 95 8f     
            lda $6d            ; $bd92: a5 6d     
            adc #$00           ; $bd94: 69 00     
            sta $76,x          ; $bd96: 95 76     
            sta $03ea,x        ; $bd98: 9d ea 03  
            lda $b5            ; $bd9b: a5 b5     
            sta $be,x          ; $bd9d: 95 be     
            rts                ; $bd9f: 60        

;-------------------------------------------------------------------------------
__bda0:     jsr __be24         ; $bda0: 20 24 be  
            lda #$02           ; $bda3: a9 02     
            sta $ff            ; $bda5: 85 ff     
            lda #$00           ; $bda7: a9 00     
            sta $60,x          ; $bda9: 95 60     
            sta $043c,x        ; $bdab: 9d 3c 04  
            sta $9f            ; $bdae: 85 9f     
            lda #$fe           ; $bdb0: a9 fe     
            sta $a8,x          ; $bdb2: 95 a8     
            lda $05            ; $bdb4: a5 05     
            jsr __bdfb         ; $bdb6: 20 fb bd  
__bdb9:     bcc __bdec         ; $bdb9: 90 31     
            tya                ; $bdbb: 98        
            cmp #$09           ; $bdbc: c9 09     
            bcc __bdc2         ; $bdbe: 90 02     
            sbc #$05           ; $bdc0: e9 05     
__bdc2:     .hex 20            ; $bdc2: 20        Suspected data
__bdc3:     .hex 04 8e         ; $bdc3: 04 8e     Invalid Opcode - NOP $8e
            .hex d7 bd         ; $bdc5: d7 bd     Invalid Opcode - DCP $bd,x
            and $3dbb,x        ; $bdc7: 3d bb 3d  
            .hex bb dd bd      ; $bdca: bb dd bd  Invalid Opcode - LAS __bddd,y
            .hex d7 bd         ; $bdcd: d7 bd     Invalid Opcode - DCP $bd,x
            cpx $bd            ; $bdcf: e4 bd     
            .hex da            ; $bdd1: da        Invalid Opcode - NOP 
            lda __bb3d,x       ; $bdd2: bd 3d bb  
            cmp __a9bd,x       ; $bdd5: dd bd a9  
            brk                ; $bdd8: 00        
            bit $02a9          ; $bdd9: 2c a9 02  
            bit $03a9          ; $bddc: 2c a9 03  
            sta $39            ; $bddf: 85 39     
            jmp __bc4e         ; $bde1: 4c 4e bc  

;-------------------------------------------------------------------------------
            ldx #$05           ; $bde4: a2 05     
            ldy $03ee          ; $bde6: ac ee 03  
            jsr __b923         ; $bde9: 20 23 b9  
__bdec:     rts                ; $bdec: 60        

;-------------------------------------------------------------------------------
__bded:     cmp ($c0,x)        ; $bded: c1 c0     
            .hex 5f 60 55      ; $bdef: 5f 60 55  Invalid Opcode - SRE $5560,x
            lsr $57,x          ; $bdf2: 56 57     
            cli                ; $bdf4: 58        
            eor $5b5a,y        ; $bdf5: 59 5a 5b  
            .hex 5c 5d 5e      ; $bdf8: 5c 5d 5e  Invalid Opcode - NOP $5e5d,x
__bdfb:     ldy #$0d           ; $bdfb: a0 0d     
__bdfd:     cmp __bded,y       ; $bdfd: d9 ed bd  
            beq __be06         ; $be00: f0 04     
            dey                ; $be02: 88        
            bpl __bdfd         ; $be03: 10 f8     
            clc                ; $be05: 18        
__be06:     rts                ; $be06: 60        

;-------------------------------------------------------------------------------
__be07:     jsr __be24         ; $be07: 20 24 be  
__be0a:     lda #$01           ; $be0a: a9 01     
            sta $03ec,x        ; $be0c: 9d ec 03  
            sta $fd            ; $be0f: 85 fd     
            jsr __be46         ; $be11: 20 46 be  
            lda #$fe           ; $be14: a9 fe     
            sta $9f            ; $be16: 85 9f     
            lda #$05           ; $be18: a9 05     
            sta $0139          ; $be1a: 8d 39 01  
            jsr __bc2c         ; $be1d: 20 2c bc  
            ldx $03ee          ; $be20: ae ee 03  
            rts                ; $be23: 60        

;-------------------------------------------------------------------------------
__be24:     ldx $03ee          ; $be24: ae ee 03  
            ldy $02            ; $be27: a4 02     
            beq __be45         ; $be29: f0 1a     
            tya                ; $be2b: 98        
            sec                ; $be2c: 38        
            sbc #$10           ; $be2d: e9 10     
            sta $02            ; $be2f: 85 02     
            tay                ; $be31: a8        
            lda ($06),y        ; $be32: b1 06     
            cmp #$c2           ; $be34: c9 c2     
            bne __be45         ; $be36: d0 0d     
            lda #$00           ; $be38: a9 00     
            sta ($06),y        ; $be3a: 91 06     
            jsr __8a4d         ; $be3c: 20 4d 8a  
            ldx $03ee          ; $be3f: ae ee 03  
            jsr __bb56         ; $be42: 20 56 bb  
__be45:     rts                ; $be45: 60        

;-------------------------------------------------------------------------------
__be46:     lda $8f,x          ; $be46: b5 8f     
            sta $03f1,x        ; $be48: 9d f1 03  
            lda #$f0           ; $be4b: a9 f0     
            sta $60,x          ; $be4d: 95 60     
            sta $62,x          ; $be4f: 95 62     
            lda #$fa           ; $be51: a9 fa     
            sta $a8,x          ; $be53: 95 a8     
            lda #$fc           ; $be55: a9 fc     
            sta $aa,x          ; $be57: 95 aa     
            lda #$00           ; $be59: a9 00     
            sta $043c,x        ; $be5b: 9d 3c 04  
            sta $043e,x        ; $be5e: 9d 3e 04  
            lda $76,x          ; $be61: b5 76     
            sta $78,x          ; $be63: 95 78     
            lda $8f,x          ; $be65: b5 8f     
            sta $91,x          ; $be67: 95 91     
            lda $d7,x          ; $be69: b5 d7     
            clc                ; $be6b: 18        
            adc #$08           ; $be6c: 69 08     
            sta $d9,x          ; $be6e: 95 d9     
            lda #$fa           ; $be70: a9 fa     
            sta $a8,x          ; $be72: 95 a8     
            rts                ; $be74: 60        

;-------------------------------------------------------------------------------
__be75:     lda $26,x          ; $be75: b5 26     
            beq __bed6         ; $be77: f0 5d     
            and #$0f           ; $be79: 29 0f     
            pha                ; $be7b: 48        
            tay                ; $be7c: a8        
            txa                ; $be7d: 8a        
            clc                ; $be7e: 18        
            adc #$09           ; $be7f: 69 09     
            tax                ; $be81: aa        
            dey                ; $be82: 88        
            beq __beb8         ; $be83: f0 33     
            jsr __bfa9         ; $be85: 20 a9 bf  
            jsr __bf14         ; $be88: 20 14 bf  
            txa                ; $be8b: 8a        
            clc                ; $be8c: 18        
            adc #$02           ; $be8d: 69 02     
            tax                ; $be8f: aa        
            jsr __bfa9         ; $be90: 20 a9 bf  
            jsr __bf14         ; $be93: 20 14 bf  
            ldx $08            ; $be96: a6 08     
            jsr __f160         ; $be98: 20 60 f1  
            jsr __f1bd         ; $be9b: 20 bd f1  
            jsr __ec5a         ; $be9e: 20 5a ec  
            pla                ; $bea1: 68        
            ldy $be,x          ; $bea2: b4 be     
            beq __bed6         ; $bea4: f0 30     
            pha                ; $bea6: 48        
            lda #$f0           ; $bea7: a9 f0     
            cmp $d9,x          ; $bea9: d5 d9     
            bcs __beaf         ; $beab: b0 02     
            sta $d9,x          ; $bead: 95 d9     
__beaf:     lda $d7,x          ; $beaf: b5 d7     
            cmp #$f0           ; $beb1: c9 f0     
            pla                ; $beb3: 68        
            bcc __bed6         ; $beb4: 90 20     
            bcs __bed4         ; $beb6: b0 1c     
__beb8:     jsr __bfa9         ; $beb8: 20 a9 bf  
            ldx $08            ; $bebb: a6 08     
            jsr __f160         ; $bebd: 20 60 f1  
            jsr __f1bd         ; $bec0: 20 bd f1  
            jsr __ebd8         ; $bec3: 20 d8 eb  
            lda $d7,x          ; $bec6: b5 d7     
            and #$0f           ; $bec8: 29 0f     
            cmp #$05           ; $beca: c9 05     
            pla                ; $becc: 68        
            bcs __bed6         ; $becd: b0 07     
            lda #$01           ; $becf: a9 01     
            sta $03ec,x        ; $bed1: 9d ec 03  
__bed4:     lda #$00           ; $bed4: a9 00     
__bed6:     sta $26,x          ; $bed6: 95 26     
            rts                ; $bed8: 60        

;-------------------------------------------------------------------------------
__bed9:     ldx #$01           ; $bed9: a2 01     
__bedb:     stx $08            ; $bedb: 86 08     
            lda $0301          ; $bedd: ad 01 03  
            bne __bf03         ; $bee0: d0 21     
            lda $03ec,x        ; $bee2: bd ec 03  
            beq __bf03         ; $bee5: f0 1c     
            lda $03e6,x        ; $bee7: bd e6 03  
            sta $06            ; $beea: 85 06     
            lda #$05           ; $beec: a9 05     
            sta $07            ; $beee: 85 07     
            lda $03e4,x        ; $bef0: bd e4 03  
            sta $02            ; $bef3: 85 02     
            tay                ; $bef5: a8        
            lda $03e8,x        ; $bef6: bd e8 03  
            sta ($06),y        ; $bef9: 91 06     
            jsr __8a61         ; $befb: 20 61 8a  
            lda #$00           ; $befe: a9 00     
            sta $03ec,x        ; $bf00: 9d ec 03  
__bf03:     dex                ; $bf03: ca        
            bpl __bedb         ; $bf04: 10 d5     
            rts                ; $bf06: 60        

;-------------------------------------------------------------------------------
__bf07:     inx                ; $bf07: e8        
            jsr __bf14         ; $bf08: 20 14 bf  
            ldx $08            ; $bf0b: a6 08     
            rts                ; $bf0d: 60        

;-------------------------------------------------------------------------------
__bf0e:     lda $070e          ; $bf0e: ad 0e 07  
            bne __bf51         ; $bf11: d0 3e     
            tax                ; $bf13: aa        
__bf14:     lda $57,x          ; $bf14: b5 57     
            asl                ; $bf16: 0a        
            asl                ; $bf17: 0a        
            asl                ; $bf18: 0a        
            asl                ; $bf19: 0a        
            sta $01            ; $bf1a: 85 01     
            lda $57,x          ; $bf1c: b5 57     
            lsr                ; $bf1e: 4a        
            lsr                ; $bf1f: 4a        
            lsr                ; $bf20: 4a        
            lsr                ; $bf21: 4a        
            cmp #$08           ; $bf22: c9 08     
            bcc __bf28         ; $bf24: 90 02     
            ora #$f0           ; $bf26: 09 f0     
__bf28:     sta $00            ; $bf28: 85 00     
            ldy #$00           ; $bf2a: a0 00     
            cmp #$00           ; $bf2c: c9 00     
            bpl __bf31         ; $bf2e: 10 01     
            dey                ; $bf30: 88        
__bf31:     sty $02            ; $bf31: 84 02     
            lda $0400,x        ; $bf33: bd 00 04  
            clc                ; $bf36: 18        
            adc $01            ; $bf37: 65 01     
            sta $0400,x        ; $bf39: 9d 00 04  
            lda #$00           ; $bf3c: a9 00     
            rol                ; $bf3e: 2a        
            pha                ; $bf3f: 48        
            ror                ; $bf40: 6a        
            lda $86,x          ; $bf41: b5 86     
            adc $00            ; $bf43: 65 00     
            sta $86,x          ; $bf45: 95 86     
            lda $6d,x          ; $bf47: b5 6d     
            adc $02            ; $bf49: 65 02     
            sta $6d,x          ; $bf4b: 95 6d     
            pla                ; $bf4d: 68        
            clc                ; $bf4e: 18        
            adc $00            ; $bf4f: 65 00     
__bf51:     rts                ; $bf51: 60        

;-------------------------------------------------------------------------------
__bf52:     ldx #$00           ; $bf52: a2 00     
            lda $0747          ; $bf54: ad 47 07  
            bne __bf5e         ; $bf57: d0 05     
            lda $070e          ; $bf59: ad 0e 07  
            bne __bf51         ; $bf5c: d0 f3     
__bf5e:     lda $0709          ; $bf5e: ad 09 07  
            sta $00            ; $bf61: 85 00     
            lda #$05           ; $bf63: a9 05     
            jmp __bfb2         ; $bf65: 4c b2 bf  

;-------------------------------------------------------------------------------
__bf68:     ldy #$3d           ; $bf68: a0 3d     
            lda $1e,x          ; $bf6a: b5 1e     
            cmp #$05           ; $bf6c: c9 05     
            bne __bf72         ; $bf6e: d0 02     
__bf70:     ldy #$20           ; $bf70: a0 20     
__bf72:     jmp __bf99         ; $bf72: 4c 99 bf  

;-------------------------------------------------------------------------------
__bf75:     ldy #$00           ; $bf75: a0 00     
            jmp __bf7c         ; $bf77: 4c 7c bf  

;-------------------------------------------------------------------------------
__bf7a:     ldy #$01           ; $bf7a: a0 01     
__bf7c:     inx                ; $bf7c: e8        
            lda #$03           ; $bf7d: a9 03     
            sta $00            ; $bf7f: 85 00     
            lda #$06           ; $bf81: a9 06     
            sta $01            ; $bf83: 85 01     
            lda #$02           ; $bf85: a9 02     
            sta $02            ; $bf87: 85 02     
            tya                ; $bf89: 98        
            jmp __bfd6         ; $bf8a: 4c d6 bf  

;-------------------------------------------------------------------------------
__bf8d:     ldy #$7f           ; $bf8d: a0 7f     
            bne __bf93         ; $bf8f: d0 02     
__bf91:     ldy #$12           ; $bf91: a0 12     
__bf93:     lda #$02           ; $bf93: a9 02     
            bne __bf9b         ; $bf95: d0 04     
__bf97:     ldy #$1f           ; $bf97: a0 1f     
__bf99:     lda #$04           ; $bf99: a9 04     
__bf9b:     sty $00            ; $bf9b: 84 00     
            inx                ; $bf9d: e8        
            jsr __bfb2         ; $bf9e: 20 b2 bf  
            ldx $08            ; $bfa1: a6 08     
            rts                ; $bfa3: 60        

;-------------------------------------------------------------------------------
__bfa4:     asl $08            ; $bfa4: 06 08     
            ldy #$00           ; $bfa6: a0 00     
            .hex 2c            ; $bfa8: 2c        Suspected data
__bfa9:     ldy #$01           ; $bfa9: a0 01     
            lda #$58           ; $bfab: a9 58     
            sta $00            ; $bfad: 85 00     
            lda __bfa4,y       ; $bfaf: b9 a4 bf  
__bfb2:     sta $02            ; $bfb2: 85 02     
            lda #$00           ; $bfb4: a9 00     
            jmp __bfdc         ; $bfb6: 4c dc bf  

;-------------------------------------------------------------------------------
__bfb9:     lda #$00           ; $bfb9: a9 00     
            .hex 2c            ; $bfbb: 2c        Suspected data
__bfbc:     lda #$01           ; $bfbc: a9 01     
__bfbe:     pha                ; $bfbe: 48        
            ldy $16,x          ; $bfbf: b4 16     
__bfc1:     inx                ; $bfc1: e8        
            lda #$05           ; $bfc2: a9 05     
            cpy #$29           ; $bfc4: c0 29     
            bne __bfca         ; $bfc6: d0 02     
            lda #$09           ; $bfc8: a9 09     
__bfca:     sta $00            ; $bfca: 85 00     
            lda #$0a           ; $bfcc: a9 0a     
            sta $01            ; $bfce: 85 01     
            lda #$03           ; $bfd0: a9 03     
            sta $02            ; $bfd2: 85 02     
            pla                ; $bfd4: 68        
            tay                ; $bfd5: a8        
__bfd6:     jsr __bfdc         ; $bfd6: 20 dc bf  
            ldx $08            ; $bfd9: a6 08     
            rts                ; $bfdb: 60        

;-------------------------------------------------------------------------------
__bfdc:     pha                ; $bfdc: 48        
            lda $0416,x        ; $bfdd: bd 16 04  
            clc                ; $bfe0: 18        
            adc $0433,x        ; $bfe1: 7d 33 04  
            sta $0416,x        ; $bfe4: 9d 16 04  
            ldy #$00           ; $bfe7: a0 00     
            lda $9f,x          ; $bfe9: b5 9f     
            bpl __bfee         ; $bfeb: 10 01     
            dey                ; $bfed: 88        
__bfee:     sty $07            ; $bfee: 84 07     
            adc $ce,x          ; $bff0: 75 ce     
            sta $ce,x          ; $bff2: 95 ce     
            lda $b5,x          ; $bff4: b5 b5     
            adc $07            ; $bff6: 65 07     
            .hex 95            ; $bff8: 95        Suspected data
__bff9:     lda $bd,x          ; $bff9: b5 bd     
            .hex 33 04         ; $bffb: 33 04     Invalid Opcode - RLA ($04),y
            clc                ; $bffd: 18        
            adc $00            ; $bffe: 65 00     
            sta $0433,x        ; $c000: 9d 33 04  
            lda $9f,x          ; $c003: b5 9f     
            adc #$00           ; $c005: 69 00     
            sta $9f,x          ; $c007: 95 9f     
            cmp $02            ; $c009: c5 02     
            bmi __c01d         ; $c00b: 30 10     
            lda $0433,x        ; $c00d: bd 33 04  
            cmp #$80           ; $c010: c9 80     
            bcc __c01d         ; $c012: 90 09     
            lda $02            ; $c014: a5 02     
            sta $9f,x          ; $c016: 95 9f     
            lda #$00           ; $c018: a9 00     
            sta $0433,x        ; $c01a: 9d 33 04  
__c01d:     pla                ; $c01d: 68        
            beq __c04b         ; $c01e: f0 2b     
            lda $02            ; $c020: a5 02     
            eor #$ff           ; $c022: 49 ff     
            tay                ; $c024: a8        
            iny                ; $c025: c8        
            sty $07            ; $c026: 84 07     
            lda $0433,x        ; $c028: bd 33 04  
            sec                ; $c02b: 38        
            sbc $01            ; $c02c: e5 01     
            sta $0433,x        ; $c02e: 9d 33 04  
            lda $9f,x          ; $c031: b5 9f     
            sbc #$00           ; $c033: e9 00     
            sta $9f,x          ; $c035: 95 9f     
            cmp $07            ; $c037: c5 07     
            .hex 10            ; $c039: 10        Suspected data
__c03a:     bpl __bff9         ; $c03a: 10 bd     
            .hex 33 04         ; $c03c: 33 04     Invalid Opcode - RLA ($04),y
            cmp #$80           ; $c03e: c9 80     
            bcs __c04b         ; $c040: b0 09     
__c042:     lda $07            ; $c042: a5 07     
            sta $9f,x          ; $c044: 95 9f     
            lda #$ff           ; $c046: a9 ff     
            sta $0433,x        ; $c048: 9d 33 04  
__c04b:     rts                ; $c04b: 60        

;-------------------------------------------------------------------------------
            .hex ff            ; $c04c: ff        Suspected data
__c04d:     lda $0f,x          ; $c04d: b5 0f     
            pha                ; $c04f: 48        
            asl                ; $c050: 0a        
            bcs __c065         ; $c051: b0 12     
            pla                ; $c053: 68        
            beq __c059         ; $c054: f0 03     
            jmp __c888         ; $c056: 4c 88 c8  

;-------------------------------------------------------------------------------
__c059:     lda $071f          ; $c059: ad 1f 07  
            and #$07           ; $c05c: 29 07     
            cmp #$07           ; $c05e: c9 07     
            beq __c070         ; $c060: f0 0e     
            jmp __c0d2         ; $c062: 4c d2 c0  

;-------------------------------------------------------------------------------
__c065:     pla                ; $c065: 68        
            and #$0f           ; $c066: 29 0f     
            tay                ; $c068: a8        
            lda $000f,y        ; $c069: b9 0f 00  
            bne __c070         ; $c06c: d0 02     
            sta $0f,x          ; $c06e: 95 0f     
__c070:     rts                ; $c070: 60        

;-------------------------------------------------------------------------------
__c071:     .hex 03 03         ; $c071: 03 03     Invalid Opcode - SLO ($03,x)
            asl $06            ; $c073: 06 06     
            asl $06            ; $c075: 06 06     
            asl $06            ; $c077: 06 06     
            .hex 07 07         ; $c079: 07 07     Invalid Opcode - SLO $07
            .hex 07            ; $c07b: 07        Suspected data
__c07c:     ora $09            ; $c07c: 05 09     
            .hex 04 05         ; $c07e: 04 05     Invalid Opcode - NOP $05
            .hex 06            ; $c080: 06        Suspected data
__c081:     php                ; $c081: 08        
            ora #$0a           ; $c082: 09 0a     
            asl $0b            ; $c084: 06 0b     
            .hex 10            ; $c086: 10        Suspected data
__c087:     rti                ; $c087: 40        

;-------------------------------------------------------------------------------
            bcs __c03a         ; $c088: b0 b0     
            .hex 80 40         ; $c08a: 80 40     Invalid Opcode - NOP #$40
            rti                ; $c08c: 40        

;-------------------------------------------------------------------------------
            .hex 80 40         ; $c08d: 80 40     Invalid Opcode - NOP #$40
            beq __c081         ; $c08f: f0 f0     
            .hex f0            ; $c091: f0        Suspected data
__c092:     lda $6d            ; $c092: a5 6d     
            sec                ; $c094: 38        
            sbc #$04           ; $c095: e9 04     
            sta $6d            ; $c097: 85 6d     
            lda $0725          ; $c099: ad 25 07  
            sec                ; $c09c: 38        
            sbc #$04           ; $c09d: e9 04     
            sta $0725          ; $c09f: 8d 25 07  
            lda $071a          ; $c0a2: ad 1a 07  
            sec                ; $c0a5: 38        
            sbc #$04           ; $c0a6: e9 04     
            sta $071a          ; $c0a8: 8d 1a 07  
            lda $071b          ; $c0ab: ad 1b 07  
            sec                ; $c0ae: 38        
            sbc #$04           ; $c0af: e9 04     
            sta $071b          ; $c0b1: 8d 1b 07  
            lda $072a          ; $c0b4: ad 2a 07  
            sec                ; $c0b7: 38        
            sbc #$04           ; $c0b8: e9 04     
            sta $072a          ; $c0ba: 8d 2a 07  
            lda #$00           ; $c0bd: a9 00     
            .hex 8d 3b         ; $c0bf: 8d 3b     Suspected data
__c0c1:     .hex 07 8d         ; $c0c1: 07 8d     Invalid Opcode - SLO $8d
            .hex 2b 07         ; $c0c3: 2b 07     Invalid Opcode - ANC #$07
            sta $0739          ; $c0c5: 8d 39 07  
            sta $073a          ; $c0c8: 8d 3a 07  
            lda __9bf8,y       ; $c0cb: b9 f8 9b  
            sta $072c          ; $c0ce: 8d 2c 07  
            rts                ; $c0d1: 60        

;-------------------------------------------------------------------------------
__c0d2:     lda $0745          ; $c0d2: ad 45 07  
            beq __c135         ; $c0d5: f0 5e     
            lda $0726          ; $c0d7: ad 26 07  
            bne __c135         ; $c0da: d0 59     
            ldy #$0b           ; $c0dc: a0 0b     
__c0de:     dey                ; $c0de: 88        
            bmi __c135         ; $c0df: 30 54     
            lda $075f          ; $c0e1: ad 5f 07  
            cmp __c071,y       ; $c0e4: d9 71 c0  
            bne __c0de         ; $c0e7: d0 f5     
            lda $0725          ; $c0e9: ad 25 07  
            cmp __c07c,y       ; $c0ec: d9 7c c0  
            bne __c0de         ; $c0ef: d0 ed     
            lda $ce            ; $c0f1: a5 ce     
            cmp __c087,y       ; $c0f3: d9 87 c0  
            bne __c11b         ; $c0f6: d0 23     
            lda $1d            ; $c0f8: a5 1d     
            cmp #$00           ; $c0fa: c9 00     
            bne __c11b         ; $c0fc: d0 1d     
            lda $075f          ; $c0fe: ad 5f 07  
            cmp #$06           ; $c101: c9 06     
            bne __c128         ; $c103: d0 23     
            inc $06d9          ; $c105: ee d9 06  
__c108:     inc $06da          ; $c108: ee da 06  
            lda $06da          ; $c10b: ad da 06  
            cmp #$03           ; $c10e: c9 03     
            bne __c130         ; $c110: d0 1e     
            lda $06d9          ; $c112: ad d9 06  
            cmp #$03           ; $c115: c9 03     
            beq __c128         ; $c117: f0 0f     
            bne __c122         ; $c119: d0 07     
__c11b:     lda $075f          ; $c11b: ad 5f 07  
            cmp #$06           ; $c11e: c9 06     
            beq __c108         ; $c120: f0 e6     
__c122:     jsr __c092         ; $c122: 20 92 c0  
            jsr __d039         ; $c125: 20 39 d0  
__c128:     lda #$00           ; $c128: a9 00     
            sta $06da          ; $c12a: 8d da 06  
            sta $06d9          ; $c12d: 8d d9 06  
__c130:     lda #$00           ; $c130: a9 00     
            sta $0745          ; $c132: 8d 45 07  
__c135:     lda $06cd          ; $c135: ad cd 06  
            beq __c14a         ; $c138: f0 10     
            sta $16,x          ; $c13a: 95 16     
            lda #$01           ; $c13c: a9 01     
            sta $0f,x          ; $c13e: 95 0f     
            lda #$00           ; $c140: a9 00     
            sta $1e,x          ; $c142: 95 1e     
            sta $06cd          ; $c144: 8d cd 06  
            jmp __c22c         ; $c147: 4c 2c c2  

;-------------------------------------------------------------------------------
__c14a:     ldy $0739          ; $c14a: ac 39 07  
            lda ($e9),y        ; $c14d: b1 e9     
            cmp #$ff           ; $c14f: c9 ff     
            bne __c156         ; $c151: d0 03     
            jmp __c21c         ; $c153: 4c 1c c2  

;-------------------------------------------------------------------------------
__c156:     and #$0f           ; $c156: 29 0f     
            cmp #$0e           ; $c158: c9 0e     
            beq __c16a         ; $c15a: f0 0e     
            cpx #$05           ; $c15c: e0 05     
            bcc __c16a         ; $c15e: 90 0a     
            iny                ; $c160: c8        
            lda ($e9),y        ; $c161: b1 e9     
            and #$3f           ; $c163: 29 3f     
            cmp #$2e           ; $c165: c9 2e     
            beq __c16a         ; $c167: f0 01     
            rts                ; $c169: 60        

;-------------------------------------------------------------------------------
__c16a:     lda $071d          ; $c16a: ad 1d 07  
            clc                ; $c16d: 18        
            adc #$30           ; $c16e: 69 30     
            and #$f0           ; $c170: 29 f0     
            sta $07            ; $c172: 85 07     
            lda $071b          ; $c174: ad 1b 07  
            adc #$00           ; $c177: 69 00     
            sta $06            ; $c179: 85 06     
            ldy $0739          ; $c17b: ac 39 07  
            iny                ; $c17e: c8        
            lda ($e9),y        ; $c17f: b1 e9     
            asl                ; $c181: 0a        
            bcc __c18f         ; $c182: 90 0b     
            lda $073b          ; $c184: ad 3b 07  
            bne __c18f         ; $c187: d0 06     
            inc $073b          ; $c189: ee 3b 07  
            inc $073a          ; $c18c: ee 3a 07  
__c18f:     dey                ; $c18f: 88        
            lda ($e9),y        ; $c190: b1 e9     
            and #$0f           ; $c192: 29 0f     
            cmp #$0f           ; $c194: c9 0f     
            bne __c1b1         ; $c196: d0 19     
            lda $073b          ; $c198: ad 3b 07  
            bne __c1b1         ; $c19b: d0 14     
            iny                ; $c19d: c8        
            lda ($e9),y        ; $c19e: b1 e9     
            and #$3f           ; $c1a0: 29 3f     
            sta $073a          ; $c1a2: 8d 3a 07  
            inc $0739          ; $c1a5: ee 39 07  
            inc $0739          ; $c1a8: ee 39 07  
            inc $073b          ; $c1ab: ee 3b 07  
            jmp __c0d2         ; $c1ae: 4c d2 c0  

;-------------------------------------------------------------------------------
__c1b1:     lda $073a          ; $c1b1: ad 3a 07  
            sta $6e,x          ; $c1b4: 95 6e     
            lda ($e9),y        ; $c1b6: b1 e9     
            and #$f0           ; $c1b8: 29 f0     
            sta $87,x          ; $c1ba: 95 87     
            cmp $071d          ; $c1bc: cd 1d 07  
            lda $6e,x          ; $c1bf: b5 6e     
            sbc $071b          ; $c1c1: ed 1b 07  
            bcs __c1d1         ; $c1c4: b0 0b     
            lda ($e9),y        ; $c1c6: b1 e9     
            and #$0f           ; $c1c8: 29 0f     
            cmp #$0e           ; $c1ca: c9 0e     
            beq __c237         ; $c1cc: f0 69     
            jmp __c256         ; $c1ce: 4c 56 c2  

;-------------------------------------------------------------------------------
__c1d1:     lda $07            ; $c1d1: a5 07     
            cmp $87,x          ; $c1d3: d5 87     
            lda $06            ; $c1d5: a5 06     
            sbc $6e,x          ; $c1d7: f5 6e     
            bcc __c21c         ; $c1d9: 90 41     
            lda #$01           ; $c1db: a9 01     
            sta $b6,x          ; $c1dd: 95 b6     
            lda ($e9),y        ; $c1df: b1 e9     
            asl                ; $c1e1: 0a        
            asl                ; $c1e2: 0a        
            asl                ; $c1e3: 0a        
            asl                ; $c1e4: 0a        
            sta $cf,x          ; $c1e5: 95 cf     
            cmp #$e0           ; $c1e7: c9 e0     
            beq __c237         ; $c1e9: f0 4c     
            iny                ; $c1eb: c8        
            lda ($e9),y        ; $c1ec: b1 e9     
            and #$40           ; $c1ee: 29 40     
            beq __c1f7         ; $c1f0: f0 05     
            lda $06cc          ; $c1f2: ad cc 06  
            beq __c264         ; $c1f5: f0 6d     
__c1f7:     lda ($e9),y        ; $c1f7: b1 e9     
            and #$3f           ; $c1f9: 29 3f     
            cmp #$37           ; $c1fb: c9 37     
            bcc __c203         ; $c1fd: 90 04     
            cmp #$3f           ; $c1ff: c9 3f     
            .hex 90            ; $c201: 90        Suspected data
__c202:     .hex 31            ; $c202: 31        Suspected data
__c203:     cmp #$06           ; $c203: c9 06     
            bne __c20e         ; $c205: d0 07     
            ldy $076a          ; $c207: ac 6a 07  
            beq __c20e         ; $c20a: f0 02     
            lda #$02           ; $c20c: a9 02     
__c20e:     sta $16,x          ; $c20e: 95 16     
            lda #$01           ; $c210: a9 01     
            sta $0f,x          ; $c212: 95 0f     
            jsr __c22c         ; $c214: 20 2c c2  
            lda $0f,x          ; $c217: b5 0f     
            bne __c264         ; $c219: d0 49     
            rts                ; $c21b: 60        

;-------------------------------------------------------------------------------
__c21c:     lda $06cb          ; $c21c: ad cb 06  
            bne __c22a         ; $c21f: d0 09     
            lda $0398          ; $c221: ad 98 03  
            cmp #$01           ; $c224: c9 01     
            bne __c233         ; $c226: d0 0b     
            lda #$2f           ; $c228: a9 2f     
__c22a:     sta $16,x          ; $c22a: 95 16     
__c22c:     lda #$00           ; $c22c: a9 00     
            sta $1e,x          ; $c22e: 95 1e     
            jsr __c272         ; $c230: 20 72 c2  
__c233:     rts                ; $c233: 60        

;-------------------------------------------------------------------------------
            jmp __c721         ; $c234: 4c 21 c7  

;-------------------------------------------------------------------------------
__c237:     iny                ; $c237: c8        
            iny                ; $c238: c8        
            lda ($e9),y        ; $c239: b1 e9     
            lsr                ; $c23b: 4a        
            lsr                ; $c23c: 4a        
            lsr                ; $c23d: 4a        
            lsr                ; $c23e: 4a        
            lsr                ; $c23f: 4a        
            cmp $075f          ; $c240: cd 5f 07  
            bne __c253         ; $c243: d0 0e     
            dey                ; $c245: 88        
            lda ($e9),y        ; $c246: b1 e9     
            sta $0750          ; $c248: 8d 50 07  
            iny                ; $c24b: c8        
            lda ($e9),y        ; $c24c: b1 e9     
            and #$1f           ; $c24e: 29 1f     
            sta $0751          ; $c250: 8d 51 07  
__c253:     jmp __c261         ; $c253: 4c 61 c2  

;-------------------------------------------------------------------------------
__c256:     ldy $0739          ; $c256: ac 39 07  
            lda ($e9),y        ; $c259: b1 e9     
            and #$0f           ; $c25b: 29 0f     
            cmp #$0e           ; $c25d: c9 0e     
            bne __c264         ; $c25f: d0 03     
__c261:     inc $0739          ; $c261: ee 39 07  
__c264:     inc $0739          ; $c264: ee 39 07  
            inc $0739          ; $c267: ee 39 07  
            lda #$00           ; $c26a: a9 00     
            sta $073b          ; $c26c: 8d 3b 07  
            ldx $08            ; $c26f: a6 08     
            rts                ; $c271: 60        

;-------------------------------------------------------------------------------
__c272:     lda $16,x          ; $c272: b5 16     
            cmp #$15           ; $c274: c9 15     
            bcs __c285         ; $c276: b0 0d     
            tay                ; $c278: a8        
            lda $cf,x          ; $c279: b5 cf     
            adc #$08           ; $c27b: 69 08     
            sta $cf,x          ; $c27d: 95 cf     
            lda #$01           ; $c27f: a9 01     
            sta $03d8,x        ; $c281: 9d d8 03  
            tya                ; $c284: 98        
__c285:     jsr __8e04         ; $c285: 20 04 8e  
            .hex 14 c3         ; $c288: 14 c3     Invalid Opcode - NOP $c3,x
            .hex 14 c3         ; $c28a: 14 c3     Invalid Opcode - NOP $c3,x
            .hex 14 c3         ; $c28c: 14 c3     Invalid Opcode - NOP $c3,x
            bit $c3            ; $c28e: 24 c3     
            inc $c2,x          ; $c290: f6 c2     
            rol __f7c3         ; $c292: 2e c3 f7  
            .hex c2 48         ; $c295: c2 48     Invalid Opcode - NOP #$48
            .hex c3 71         ; $c297: c3 71     Invalid Opcode - DCP ($71,x)
            .hex c3 f6         ; $c299: c3 f6     Invalid Opcode - DCP ($f6,x)
            .hex c2 7b         ; $c29b: c2 7b     Invalid Opcode - NOP #$7b
            .hex c3 7b         ; $c29d: c3 7b     Invalid Opcode - DCP ($7b,x)
            .hex c3 fd         ; $c29f: c3 fd     Invalid Opcode - DCP ($fd,x)
            .hex c2 8d         ; $c2a1: c2 8d     Invalid Opcode - NOP #$8d
            .hex c7 d7         ; $c2a3: c7 d7     Invalid Opcode - DCP $d7
            .hex c7 50         ; $c2a5: c7 50     Invalid Opcode - DCP $50
            .hex c3 43         ; $c2a7: c3 43     Invalid Opcode - DCP ($43,x)
            .hex c3 8b         ; $c2a9: c3 8b     Invalid Opcode - DCP ($8b,x)
            .hex c3 a6         ; $c2ab: c3 a6     Invalid Opcode - DCP ($a6,x)
            .hex c7 f6         ; $c2ad: c7 f6     Invalid Opcode - DCP $f6
            .hex c2 a6         ; $c2af: c2 a6     Invalid Opcode - NOP #$a6
            .hex c7 a6         ; $c2b1: c7 a6     Invalid Opcode - DCP $a6
            .hex c7 a6         ; $c2b3: c7 a6     Invalid Opcode - DCP $a6
            .hex c7 a6         ; $c2b5: c7 a6     Invalid Opcode - DCP $a6
            .hex c7 be         ; $c2b7: c7 be     Invalid Opcode - DCP $be
            .hex c7 f6         ; $c2b9: c7 f6     Invalid Opcode - DCP $f6
            .hex c2 f6         ; $c2bb: c2 f6     Invalid Opcode - NOP #$f6
            .hex c2 62         ; $c2bd: c2 62     Invalid Opcode - NOP #$62
            cpy $62            ; $c2bf: c4 62     
            cpy $62            ; $c2c1: c4 62     
            cpy $62            ; $c2c3: c4 62     
            cpy $5f            ; $c2c5: c4 5f     
            cpy $f6            ; $c2c7: c4 f6     
            .hex c2 f6         ; $c2c9: c2 f6     Invalid Opcode - NOP #$f6
            .hex c2 f6         ; $c2cb: c2 f6     Invalid Opcode - NOP #$f6
            .hex c2 f6         ; $c2cd: c2 f6     Invalid Opcode - NOP #$f6
            .hex c2 e5         ; $c2cf: c2 e5     Invalid Opcode - NOP #$e5
            .hex c7 18         ; $c2d1: c7 18     Invalid Opcode - DCP $18
            iny                ; $c2d3: c8        
            eor $c8            ; $c2d4: 45 c8     
            .hex 4b c8         ; $c2d6: 4b c8     Invalid Opcode - ALR #$c8
            ora ($c8),y        ; $c2d8: 11 c8     
            ora #$c8           ; $c2da: 09 c8     
            ora ($c8),y        ; $c2dc: 11 c8     
            eor ($c8),y        ; $c2de: 51 c8     
            eor $4fc8,x        ; $c2e0: 5d c8 4f  
            cmp $65            ; $c2e3: c5 65     
            ldy __b923,x       ; $c2e5: bc 23 b9  
            inc $c2,x          ; $c2e8: f6 c2     
            inc $c2,x          ; $c2ea: f6 c2     
            inc $c2,x          ; $c2ec: f6 c2     
            inc $c2,x          ; $c2ee: f6 c2     
            inc $c2,x          ; $c2f0: f6 c2     
            ora __87c3         ; $c2f2: 0d c3 87  
            iny                ; $c2f5: c8        
            rts                ; $c2f6: 60        

;-------------------------------------------------------------------------------
            jsr __c314         ; $c2f7: 20 14 c3  
            jmp __c34c         ; $c2fa: 4c 4c c3  

;-------------------------------------------------------------------------------
__c2fd:     lda #$02           ; $c2fd: a9 02     
            sta $b6,x          ; $c2ff: 95 b6     
            sta $cf,x          ; $c301: 95 cf     
            lsr                ; $c303: 4a        
            sta $0796,x        ; $c304: 9d 96 07  
            lsr                ; $c307: 4a        
            sta $1e,x          ; $c308: 95 1e     
            jmp __c34c         ; $c30a: 4c 4c c3  

;-------------------------------------------------------------------------------
            lda #$b8           ; $c30d: a9 b8     
            sta $cf,x          ; $c30f: 95 cf     
            rts                ; $c311: 60        

;-------------------------------------------------------------------------------
__c312:     inc $f1,x          ; $c312: f6 f1     
__c314:     ldy #$01           ; $c314: a0 01     
            lda $076a          ; $c316: ad 6a 07  
            bne __c31c         ; $c319: d0 01     
            dey                ; $c31b: 88        
__c31c:     lda __c312,y       ; $c31c: b9 12 c3  
__c31f:     sta $58,x          ; $c31f: 95 58     
            jmp __c360         ; $c321: 4c 60 c3  

;-------------------------------------------------------------------------------
            jsr __c314         ; $c324: 20 14 c3  
            lda #$01           ; $c327: a9 01     
            sta $1e,x          ; $c329: 95 1e     
            rts                ; $c32b: 60        

;-------------------------------------------------------------------------------
__c32c:     .hex 80 50         ; $c32c: 80 50     Invalid Opcode - NOP #$50
            lda #$00           ; $c32e: a9 00     
            sta $03a2,x        ; $c330: 9d a2 03  
            sta $58,x          ; $c333: 95 58     
            ldy $06cc          ; $c335: ac cc 06  
            lda __c32c,y       ; $c338: b9 2c c3  
            sta $0796,x        ; $c33b: 9d 96 07  
            lda #$0b           ; $c33e: a9 0b     
            jmp __c362         ; $c340: 4c 62 c3  

;-------------------------------------------------------------------------------
__c343:     lda #$00           ; $c343: a9 00     
            jmp __c31f         ; $c345: 4c 1f c3  

;-------------------------------------------------------------------------------
            lda #$00           ; $c348: a9 00     
            sta $58,x          ; $c34a: 95 58     
__c34c:     lda #$09           ; $c34c: a9 09     
            bne __c362         ; $c34e: d0 12     
            ldy #$30           ; $c350: a0 30     
            lda $cf,x          ; $c352: b5 cf     
            sta $0401,x        ; $c354: 9d 01 04  
            bpl __c35b         ; $c357: 10 02     
            ldy #$e0           ; $c359: a0 e0     
__c35b:     tya                ; $c35b: 98        
            adc $cf,x          ; $c35c: 75 cf     
            sta $58,x          ; $c35e: 95 58     
__c360:     lda #$03           ; $c360: a9 03     
__c362:     sta $049a,x        ; $c362: 9d 9a 04  
            lda #$02           ; $c365: a9 02     
            sta $46,x          ; $c367: 95 46     
__c369:     lda #$00           ; $c369: a9 00     
            sta $a0,x          ; $c36b: 95 a0     
            sta $0434,x        ; $c36d: 9d 34 04  
            rts                ; $c370: 60        

;-------------------------------------------------------------------------------
            lda #$02           ; $c371: a9 02     
            sta $46,x          ; $c373: 95 46     
            lda #$09           ; $c375: a9 09     
            sta $049a,x        ; $c377: 9d 9a 04  
            rts                ; $c37a: 60        

;-------------------------------------------------------------------------------
            jsr __c34c         ; $c37b: 20 4c c3  
            lda $07a7,x        ; $c37e: bd a7 07  
            and #$10           ; $c381: 29 10     
            sta $58,x          ; $c383: 95 58     
            lda $cf,x          ; $c385: b5 cf     
            sta $0434,x        ; $c387: 9d 34 04  
            rts                ; $c38a: 60        

;-------------------------------------------------------------------------------
            lda $06cb          ; $c38b: ad cb 06  
            bne __c39b         ; $c38e: d0 0b     
__c390:     lda #$00           ; $c390: a9 00     
            sta $06d1          ; $c392: 8d d1 06  
            jsr __c343         ; $c395: 20 43 c3  
            jmp __c7df         ; $c398: 4c df c7  

;-------------------------------------------------------------------------------
__c39b:     jmp __c99e         ; $c39b: 4c 9e c9  

;-------------------------------------------------------------------------------
__c39e:     rol $2c            ; $c39e: 26 2c     
            .hex 32            ; $c3a0: 32        Invalid Opcode - KIL 
            sec                ; $c3a1: 38        
            jsr $2422          ; $c3a2: 20 22 24  
            rol $13            ; $c3a5: 26 13     
            .hex 14 15         ; $c3a7: 14 15     Invalid Opcode - NOP $15,x
            asl $ad,x          ; $c3a9: 16 ad     
            .hex 8f 07 d0      ; $c3ab: 8f 07 d0  Invalid Opcode - SAX __d007
            .hex 3c e0 05      ; $c3ae: 3c e0 05  Invalid Opcode - NOP $05e0,x
            bcs __c3eb         ; $c3b1: b0 38     
            lda #$80           ; $c3b3: a9 80     
            sta $078f          ; $c3b5: 8d 8f 07  
            ldy #$04           ; $c3b8: a0 04     
__c3ba:     lda $0016,y        ; $c3ba: b9 16 00  
            cmp #$11           ; $c3bd: c9 11     
            beq __c3ec         ; $c3bf: f0 2b     
            dey                ; $c3c1: 88        
            bpl __c3ba         ; $c3c2: 10 f6     
            inc $06d1          ; $c3c4: ee d1 06  
            lda $06d1          ; $c3c7: ad d1 06  
            cmp #$07           ; $c3ca: c9 07     
            bcc __c3eb         ; $c3cc: 90 1d     
            ldx #$04           ; $c3ce: a2 04     
__c3d0:     lda $0f,x          ; $c3d0: b5 0f     
            beq __c3d9         ; $c3d2: f0 05     
            dex                ; $c3d4: ca        
            bpl __c3d0         ; $c3d5: 10 f9     
            bmi __c3e9         ; $c3d7: 30 10     
__c3d9:     lda #$00           ; $c3d9: a9 00     
            sta $1e,x          ; $c3db: 95 1e     
            lda #$11           ; $c3dd: a9 11     
            sta $16,x          ; $c3df: 95 16     
            jsr __c390         ; $c3e1: 20 90 c3  
            lda #$20           ; $c3e4: a9 20     
            jsr __c5de         ; $c3e6: 20 de c5  
__c3e9:     ldx $08            ; $c3e9: a6 08     
__c3eb:     rts                ; $c3eb: 60        

;-------------------------------------------------------------------------------
__c3ec:     lda $ce            ; $c3ec: a5 ce     
            cmp #$2c           ; $c3ee: c9 2c     
            bcc __c3eb         ; $c3f0: 90 f9     
            lda $001e,y        ; $c3f2: b9 1e 00  
            bne __c3eb         ; $c3f5: d0 f4     
            .hex b9            ; $c3f7: b9        Suspected data
__c3f8:     ror __9500         ; $c3f8: 6e 00 95  
            ror __87b9         ; $c3fb: 6e b9 87  
            brk                ; $c3fe: 00        
            sta $87,x          ; $c3ff: 95 87     
            lda #$01           ; $c401: a9 01     
            sta $b6,x          ; $c403: 95 b6     
            .hex b9            ; $c405: b9        Suspected data
__c406:     .hex cf 00 38      ; $c406: cf 00 38  Invalid Opcode - DCP $3800
            sbc #$08           ; $c409: e9 08     
            sta $cf,x          ; $c40b: 95 cf     
            lda $07a7,x        ; $c40d: bd a7 07  
            and #$03           ; $c410: 29 03     
            tay                ; $c412: a8        
            ldx #$02           ; $c413: a2 02     
__c415:     lda __c39e,y       ; $c415: b9 9e c3  
            sta $01,x          ; $c418: 95 01     
            iny                ; $c41a: c8        
            iny                ; $c41b: c8        
            iny                ; $c41c: c8        
            iny                ; $c41d: c8        
            dex                ; $c41e: ca        
            bpl __c415         ; $c41f: 10 f4     
            ldx $08            ; $c421: a6 08     
            jsr __cf34         ; $c423: 20 34 cf  
            ldy $57            ; $c426: a4 57     
            cpy #$0c           ; $c428: c0 0c     
            bcs __c43a         ; $c42a: b0 0e     
            tay                ; $c42c: a8        
            lda $07a8,x        ; $c42d: bd a8 07  
            and #$03           ; $c430: 29 03     
            beq __c439         ; $c432: f0 05     
            tya                ; $c434: 98        
            eor #$ff           ; $c435: 49 ff     
            tay                ; $c437: a8        
            iny                ; $c438: c8        
__c439:     tya                ; $c439: 98        
__c43a:     jsr __c34c         ; $c43a: 20 4c c3  
            ldy #$02           ; $c43d: a0 02     
            sta $58,x          ; $c43f: 95 58     
            cmp #$00           ; $c441: c9 00     
            bmi __c446         ; $c443: 30 01     
            dey                ; $c445: 88        
__c446:     sty $46,x          ; $c446: 94 46     
            lda #$fd           ; $c448: a9 fd     
            sta $a0,x          ; $c44a: 95 a0     
            lda #$01           ; $c44c: a9 01     
            sta $0f,x          ; $c44e: 95 0f     
            lda #$05           ; $c450: a9 05     
            sta $1e,x          ; $c452: 95 1e     
__c454:     rts                ; $c454: 60        

;-------------------------------------------------------------------------------
            bmi __c49a         ; $c455: 30 43     
            bmi __c49c         ; $c457: 30 43     
            bmi __c45b         ; $c459: 30 00     
__c45b:     brk                ; $c45b: 00        
            bpl __c46e         ; $c45c: 10 10     
            brk                ; $c45e: 00        
            jsr __c57b         ; $c45f: 20 7b c5  
            lda #$00           ; $c462: a9 00     
            sta $58,x          ; $c464: 95 58     
            lda $16,x          ; $c466: b5 16     
            sec                ; $c468: 38        
            sbc #$1b           ; $c469: e9 1b     
            tay                ; $c46b: a8        
            .hex b9 55         ; $c46c: b9 55     Suspected data
__c46e:     cpy $9d            ; $c46e: c4 9d     
            dey                ; $c470: 88        
            .hex 03 b9         ; $c471: 03 b9     Invalid Opcode - SLO ($b9,x)
            .hex 5a            ; $c473: 5a        Invalid Opcode - NOP 
            cpy $95            ; $c474: c4 95     
            .hex 34 b5         ; $c476: 34 b5     Invalid Opcode - NOP $b5,x
            .hex cf 18 69      ; $c478: cf 18 69  Invalid Opcode - DCP $6918
            .hex 04 95         ; $c47b: 04 95     Invalid Opcode - NOP $95
            .hex cf b5 87      ; $c47d: cf b5 87  Invalid Opcode - DCP __87b5
            clc                ; $c480: 18        
            adc #$04           ; $c481: 69 04     
            sta $87,x          ; $c483: 95 87     
            lda $6e,x          ; $c485: b5 6e     
            adc #$00           ; $c487: 69 00     
            sta $6e,x          ; $c489: 95 6e     
            jmp __c7df         ; $c48b: 4c df c7  

;-------------------------------------------------------------------------------
__c48e:     .hex 80 30         ; $c48e: 80 30     Invalid Opcode - NOP #$30
            rti                ; $c490: 40        

;-------------------------------------------------------------------------------
            .hex 80 30         ; $c491: 80 30     Invalid Opcode - NOP #$30
            bvc __c4e5         ; $c493: 50 50     
            bvs __c4b7         ; $c495: 70 20     
            rti                ; $c497: 40        

;-------------------------------------------------------------------------------
            .hex 80 a0         ; $c498: 80 a0     Invalid Opcode - NOP #$a0
__c49a:     bvs __c4dc         ; $c49a: 70 40     
__c49c:     bcc __c506         ; $c49c: 90 68     
__c49e:     ora ($07),y        ; $c49e: 11 07     
            php                ; $c4a0: 08        
            asl                ; $c4a1: 0a        
            .hex 23 28         ; $c4a2: 23 28     Invalid Opcode - RLA ($28,x)
            ora $10,x          ; $c4a4: 15 10     
            .hex 22            ; $c4a6: 22        Invalid Opcode - KIL 
            bit $1b1f          ; $c4a7: 2c 1f 1b  
__c4aa:     bpl __c50c         ; $c4aa: 10 60     
            jsr __ad48         ; $c4ac: 20 48 ad  
            .hex 8f 07 d0      ; $c4af: 8f 07 d0  Invalid Opcode - SAX __d007
            lda ($20,x)        ; $c4b2: a1 20     
            jmp __bdc3         ; $c4b4: 4c c3 bd  

;-------------------------------------------------------------------------------
__c4b7:     tay                ; $c4b7: a8        
            .hex 07 29         ; $c4b8: 07 29     Invalid Opcode - SLO $29
            .hex 03 a8         ; $c4ba: 03 a8     Invalid Opcode - SLO ($a8,x)
            lda __c4aa,y       ; $c4bc: b9 aa c4  
            sta $078f          ; $c4bf: 8d 8f 07  
            ldy #$03           ; $c4c2: a0 03     
            lda $06cc          ; $c4c4: ad cc 06  
            beq __c4ca         ; $c4c7: f0 01     
            iny                ; $c4c9: c8        
__c4ca:     sty $00            ; $c4ca: 84 00     
            cpx $00            ; $c4cc: e4 00     
            bcs __c454         ; $c4ce: b0 84     
            lda $07a7,x        ; $c4d0: bd a7 07  
            and #$03           ; $c4d3: 29 03     
            sta $00            ; $c4d5: 85 00     
            sta $01            ; $c4d7: 85 01     
            lda #$fa           ; $c4d9: a9 fa     
            .hex 95            ; $c4db: 95        Suspected data
__c4dc:     ldy #$a9           ; $c4dc: a0 a9     
            brk                ; $c4de: 00        
            ldy $57            ; $c4df: a4 57     
            beq __c4ea         ; $c4e1: f0 07     
            lda #$04           ; $c4e3: a9 04     
__c4e5:     cpy #$1d           ; $c4e5: c0 1d     
            bcc __c4ea         ; $c4e7: 90 01     
            asl                ; $c4e9: 0a        
__c4ea:     pha                ; $c4ea: 48        
            clc                ; $c4eb: 18        
            adc $00            ; $c4ec: 65 00     
            sta $00            ; $c4ee: 85 00     
            lda $07a8,x        ; $c4f0: bd a8 07  
            and #$03           ; $c4f3: 29 03     
            beq __c4fe         ; $c4f5: f0 07     
            lda $07a9,x        ; $c4f7: bd a9 07  
            and #$0f           ; $c4fa: 29 0f     
            sta $00            ; $c4fc: 85 00     
__c4fe:     pla                ; $c4fe: 68        
            clc                ; $c4ff: 18        
            adc $01            ; $c500: 65 01     
            tay                ; $c502: a8        
            lda __c49e,y       ; $c503: b9 9e c4  
__c506:     sta $58,x          ; $c506: 95 58     
            lda #$01           ; $c508: a9 01     
            sta $46,x          ; $c50a: 95 46     
__c50c:     lda $57            ; $c50c: a5 57     
            bne __c522         ; $c50e: d0 12     
            ldy $00            ; $c510: a4 00     
            tya                ; $c512: 98        
            and #$02           ; $c513: 29 02     
            beq __c522         ; $c515: f0 0b     
            lda $58,x          ; $c517: b5 58     
            eor #$ff           ; $c519: 49 ff     
            clc                ; $c51b: 18        
            adc #$01           ; $c51c: 69 01     
            sta $58,x          ; $c51e: 95 58     
            inc $46,x          ; $c520: f6 46     
__c522:     tya                ; $c522: 98        
            and #$02           ; $c523: 29 02     
__c525:     beq __c536         ; $c525: f0 0f     
            lda $86            ; $c527: a5 86     
            clc                ; $c529: 18        
            adc __c48e,y       ; $c52a: 79 8e c4  
            sta $87,x          ; $c52d: 95 87     
            lda $6d            ; $c52f: a5 6d     
            adc #$00           ; $c531: 69 00     
            jmp __c542         ; $c533: 4c 42 c5  

;-------------------------------------------------------------------------------
__c536:     .hex a5            ; $c536: a5        Suspected data
__c537:     stx $38            ; $c537: 86 38     
            sbc __c48e,y       ; $c539: f9 8e c4  
            sta $87,x          ; $c53c: 95 87     
            lda $6d            ; $c53e: a5 6d     
            sbc #$00           ; $c540: e9 00     
__c542:     sta $6e,x          ; $c542: 95 6e     
            lda #$01           ; $c544: a9 01     
            sta $0f,x          ; $c546: 95 0f     
            sta $b6,x          ; $c548: 95 b6     
            lda #$f8           ; $c54a: a9 f8     
            sta $cf,x          ; $c54c: 95 cf     
            rts                ; $c54e: 60        

;-------------------------------------------------------------------------------
            jsr __c57b         ; $c54f: 20 7b c5  
            stx $0368          ; $c552: 8e 68 03  
            lda #$00           ; $c555: a9 00     
            sta $0363          ; $c557: 8d 63 03  
            sta $0369          ; $c55a: 8d 69 03  
            lda $87,x          ; $c55d: b5 87     
            sta $0366          ; $c55f: 8d 66 03  
            lda #$df           ; $c562: a9 df     
            sta $0790          ; $c564: 8d 90 07  
            sta $46,x          ; $c567: 95 46     
            lda #$20           ; $c569: a9 20     
            sta $0364          ; $c56b: 8d 64 03  
            sta $078a,x        ; $c56e: 9d 8a 07  
            lda #$05           ; $c571: a9 05     
            sta $0483          ; $c573: 8d 83 04  
            lsr                ; $c576: 4a        
            sta $0365          ; $c577: 8d 65 03  
            rts                ; $c57a: 60        

;-------------------------------------------------------------------------------
__c57b:     ldy #$ff           ; $c57b: a0 ff     
__c57d:     iny                ; $c57d: c8        
            lda $000f,y        ; $c57e: b9 0f 00  
            bne __c57d         ; $c581: d0 fa     
            sty $06cf          ; $c583: 8c cf 06  
            txa                ; $c586: 8a        
            ora #$80           ; $c587: 09 80     
            sta $000f,y        ; $c589: 99 0f 00  
            lda $6e,x          ; $c58c: b5 6e     
            sta $006e,y        ; $c58e: 99 6e 00  
            lda $87,x          ; $c591: b5 87     
            sta $0087,y        ; $c593: 99 87 00  
            lda #$01           ; $c596: a9 01     
            sta $0f,x          ; $c598: 95 0f     
            sta $00b6,y        ; $c59a: 99 b6 00  
            lda $cf,x          ; $c59d: b5 cf     
            sta $00cf,y        ; $c59f: 99 cf 00  
            rts                ; $c5a2: 60        

;-------------------------------------------------------------------------------
__c5a3:     bcc __c525         ; $c5a3: 90 80     
            bvs __c537         ; $c5a5: 70 90     
__c5a7:     .hex ff 01 ad      ; $c5a7: ff 01 ad  Invalid Opcode - ISC __ad01,x
            .hex 8f 07 d0      ; $c5aa: 8f 07 d0  Invalid Opcode - SAX __d007
            .hex f4 9d         ; $c5ad: f4 9d     Invalid Opcode - NOP $9d,x
            .hex 34 04         ; $c5af: 34 04     Invalid Opcode - NOP $04,x
            lda $fd            ; $c5b1: a5 fd     
            ora #$02           ; $c5b3: 09 02     
            sta $fd            ; $c5b5: 85 fd     
            ldy $0368          ; $c5b7: ac 68 03  
            lda $0016,y        ; $c5ba: b9 16 00  
            cmp #$2d           ; $c5bd: c9 2d     
            beq __c5f2         ; $c5bf: f0 31     
            jsr __d1a1         ; $c5c1: 20 a1 d1  
            clc                ; $c5c4: 18        
            adc #$20           ; $c5c5: 69 20     
            ldy $06cc          ; $c5c7: ac cc 06  
            beq __c5cf         ; $c5ca: f0 03     
            sec                ; $c5cc: 38        
            sbc #$10           ; $c5cd: e9 10     
__c5cf:     sta $078f          ; $c5cf: 8d 8f 07  
            lda $07a7,x        ; $c5d2: bd a7 07  
            and #$03           ; $c5d5: 29 03     
            sta $0417,x        ; $c5d7: 9d 17 04  
            tay                ; $c5da: a8        
            lda __c5a3,y       ; $c5db: b9 a3 c5  
__c5de:     sta $cf,x          ; $c5de: 95 cf     
            lda $071d          ; $c5e0: ad 1d 07  
            clc                ; $c5e3: 18        
            adc #$20           ; $c5e4: 69 20     
            sta $87,x          ; $c5e6: 95 87     
            lda $071b          ; $c5e8: ad 1b 07  
            adc #$00           ; $c5eb: 69 00     
            sta $6e,x          ; $c5ed: 95 6e     
            .hex 4c 25         ; $c5ef: 4c 25     Suspected data
__c5f1:     .hex c6            ; $c5f1: c6        Suspected data
__c5f2:     lda $0087,y        ; $c5f2: b9 87 00  
            sec                ; $c5f5: 38        
            sbc #$0e           ; $c5f6: e9 0e     
            sta $87,x          ; $c5f8: 95 87     
            lda $006e,y        ; $c5fa: b9 6e 00  
            sta $6e,x          ; $c5fd: 95 6e     
            lda $00cf,y        ; $c5ff: b9 cf 00  
            clc                ; $c602: 18        
            adc #$08           ; $c603: 69 08     
            sta $cf,x          ; $c605: 95 cf     
            lda $07a7,x        ; $c607: bd a7 07  
            and #$03           ; $c60a: 29 03     
            sta $0417,x        ; $c60c: 9d 17 04  
            tay                ; $c60f: a8        
            lda __c5a3,y       ; $c610: b9 a3 c5  
            ldy #$00           ; $c613: a0 00     
            cmp $cf,x          ; $c615: d5 cf     
            bcc __c61a         ; $c617: 90 01     
            iny                ; $c619: c8        
__c61a:     lda __c5a7,y       ; $c61a: b9 a7 c5  
            sta $0434,x        ; $c61d: 9d 34 04  
            lda #$00           ; $c620: a9 00     
            sta $06cb          ; $c622: 8d cb 06  
            lda #$08           ; $c625: a9 08     
            sta $049a,x        ; $c627: 9d 9a 04  
            lda #$01           ; $c62a: a9 01     
            sta $b6,x          ; $c62c: 95 b6     
            sta $0f,x          ; $c62e: 95 0f     
            lsr                ; $c630: 4a        
            sta $0401,x        ; $c631: 9d 01 04  
            sta $1e,x          ; $c634: 95 1e     
            rts                ; $c636: 60        

;-------------------------------------------------------------------------------
__c637:     brk                ; $c637: 00        
            bmi __c69a         ; $c638: 30 60     
            rts                ; $c63a: 60        

;-------------------------------------------------------------------------------
            brk                ; $c63b: 00        
            .hex 20            ; $c63c: 20        Suspected data
__c63d:     rts                ; $c63d: 60        

;-------------------------------------------------------------------------------
            rti                ; $c63e: 40        

;-------------------------------------------------------------------------------
            bvs __c681         ; $c63f: 70 40     
            rts                ; $c641: 60        

;-------------------------------------------------------------------------------
            bmi __c5f1         ; $c642: 30 ad     
            .hex 8f 07 d0      ; $c644: 8f 07 d0  Invalid Opcode - SAX __d007
            .hex 47 a9         ; $c647: 47 a9     Invalid Opcode - SRE $a9
            jsr __8f8d         ; $c649: 20 8d 8f  
            .hex 07 ce         ; $c64c: 07 ce     Invalid Opcode - SLO $ce
            .hex d7 06         ; $c64e: d7 06     Invalid Opcode - DCP $06,x
            ldy #$06           ; $c650: a0 06     
__c652:     dey                ; $c652: 88        
            lda $0016,y        ; $c653: b9 16 00  
            cmp #$31           ; $c656: c9 31     
            bne __c652         ; $c658: d0 f8     
            lda $0087,y        ; $c65a: b9 87 00  
            sec                ; $c65d: 38        
            sbc #$30           ; $c65e: e9 30     
            pha                ; $c660: 48        
            lda $006e,y        ; $c661: b9 6e 00  
            sbc #$00           ; $c664: e9 00     
            sta $00            ; $c666: 85 00     
            lda $06d7          ; $c668: ad d7 06  
            clc                ; $c66b: 18        
            adc $001e,y        ; $c66c: 79 1e 00  
            tay                ; $c66f: a8        
            pla                ; $c670: 68        
            clc                ; $c671: 18        
            adc __c637,y       ; $c672: 79 37 c6  
            sta $87,x          ; $c675: 95 87     
            lda $00            ; $c677: a5 00     
            adc #$00           ; $c679: 69 00     
            sta $6e,x          ; $c67b: 95 6e     
            lda __c63d,y       ; $c67d: b9 3d c6  
            .hex 95            ; $c680: 95        Suspected data
__c681:     .hex cf a9 01      ; $c681: cf a9 01  Invalid Opcode - DCP $01a9
            sta $b6,x          ; $c684: 95 b6     
            sta $0f,x          ; $c686: 95 0f     
            lsr                ; $c688: 4a        
            sta $58,x          ; $c689: 95 58     
            lda #$08           ; $c68b: a9 08     
            sta $a0,x          ; $c68d: 95 a0     
            rts                ; $c68f: 60        

;-------------------------------------------------------------------------------
__c690:     ora ($02,x)        ; $c690: 01 02     
            .hex 04 08         ; $c692: 04 08     Invalid Opcode - NOP $08
            bpl __c6b6         ; $c694: 10 20     
            rti                ; $c696: 40        

;-------------------------------------------------------------------------------
            .hex 80            ; $c697: 80        Suspected data
__c698:     rti                ; $c698: 40        

;-------------------------------------------------------------------------------
            .hex 30            ; $c699: 30        Suspected data
__c69a:     bcc __c6ec         ; $c69a: 90 50     
            jsr __a060         ; $c69c: 20 60 a0  
            .hex 70            ; $c69f: 70        Suspected data
__c6a0:     asl                ; $c6a0: 0a        
            .hex 0b ad         ; $c6a1: 0b ad     Invalid Opcode - ANC #$ad
            .hex 8f 07 d0      ; $c6a3: 8f 07 d0  Invalid Opcode - SAX __d007
            .hex 6f ad 4e      ; $c6a6: 6f ad 4e  Invalid Opcode - RRA $4ead
            .hex 07 d0         ; $c6a9: 07 d0     Invalid Opcode - SLO $d0
            .hex 57 e0         ; $c6ab: 57 e0     Invalid Opcode - SRE $e0,x
            .hex 03 b0         ; $c6ad: 03 b0     Invalid Opcode - SLO ($b0,x)
            ror $a0            ; $c6af: 66 a0     
            brk                ; $c6b1: 00        
            lda $07a7,x        ; $c6b2: bd a7 07  
            .hex c9            ; $c6b5: c9        Suspected data
__c6b6:     tax                ; $c6b6: aa        
            bcc __c6ba         ; $c6b7: 90 01     
            iny                ; $c6b9: c8        
__c6ba:     lda $075f          ; $c6ba: ad 5f 07  
            cmp #$01           ; $c6bd: c9 01     
            beq __c6c2         ; $c6bf: f0 01     
            iny                ; $c6c1: c8        
__c6c2:     tya                ; $c6c2: 98        
            and #$01           ; $c6c3: 29 01     
            tay                ; $c6c5: a8        
            lda __c6a0,y       ; $c6c6: b9 a0 c6  
__c6c9:     sta $16,x          ; $c6c9: 95 16     
            lda $06dd          ; $c6cb: ad dd 06  
            cmp #$ff           ; $c6ce: c9 ff     
            bne __c6d7         ; $c6d0: d0 05     
            lda #$00           ; $c6d2: a9 00     
            sta $06dd          ; $c6d4: 8d dd 06  
__c6d7:     lda $07a7,x        ; $c6d7: bd a7 07  
            and #$07           ; $c6da: 29 07     
__c6dc:     tay                ; $c6dc: a8        
            lda __c690,y       ; $c6dd: b9 90 c6  
            bit $06dd          ; $c6e0: 2c dd 06  
            beq __c6ec         ; $c6e3: f0 07     
            iny                ; $c6e5: c8        
            tya                ; $c6e6: 98        
            and #$07           ; $c6e7: 29 07     
            jmp __c6dc         ; $c6e9: 4c dc c6  

;-------------------------------------------------------------------------------
__c6ec:     ora $06dd          ; $c6ec: 0d dd 06  
            sta $06dd          ; $c6ef: 8d dd 06  
            lda __c698,y       ; $c6f2: b9 98 c6  
            jsr __c5de         ; $c6f5: 20 de c5  
            sta $0417,x        ; $c6f8: 9d 17 04  
            lda #$20           ; $c6fb: a9 20     
            sta $078f          ; $c6fd: 8d 8f 07  
__c700:     jmp __c272         ; $c700: 4c 72 c2  

;-------------------------------------------------------------------------------
__c703:     ldy #$ff           ; $c703: a0 ff     
__c705:     iny                ; $c705: c8        
__c706:     cpy #$05           ; $c706: c0 05     
            bcs __c717         ; $c708: b0 0d     
            lda $000f,y        ; $c70a: b9 0f 00  
            beq __c705         ; $c70d: f0 f6     
            lda $0016,y        ; $c70f: b9 16 00  
            cmp #$08           ; $c712: c9 08     
            bne __c705         ; $c714: d0 ef     
            rts                ; $c716: 60        

;-------------------------------------------------------------------------------
__c717:     lda $fe            ; $c717: a5 fe     
            ora #$08           ; $c719: 09 08     
            sta $fe            ; $c71b: 85 fe     
            lda #$08           ; $c71d: a9 08     
            bne __c6c9         ; $c71f: d0 a8     
__c721:     ldy #$00           ; $c721: a0 00     
            sec                ; $c723: 38        
            sbc #$37           ; $c724: e9 37     
            pha                ; $c726: 48        
            cmp #$04           ; $c727: c9 04     
            bcs __c736         ; $c729: b0 0b     
            pha                ; $c72b: 48        
            ldy #$06           ; $c72c: a0 06     
            lda $076a          ; $c72e: ad 6a 07  
            beq __c735         ; $c731: f0 02     
__c733:     ldy #$02           ; $c733: a0 02     
__c735:     pla                ; $c735: 68        
__c736:     sty $01            ; $c736: 84 01     
            ldy #$b0           ; $c738: a0 b0     
            and #$02           ; $c73a: 29 02     
            beq __c740         ; $c73c: f0 02     
            ldy #$70           ; $c73e: a0 70     
__c740:     sty $00            ; $c740: 84 00     
            lda $071b          ; $c742: ad 1b 07  
            sta $02            ; $c745: 85 02     
            lda $071d          ; $c747: ad 1d 07  
            sta $03            ; $c74a: 85 03     
            ldy #$02           ; $c74c: a0 02     
            pla                ; $c74e: 68        
            lsr                ; $c74f: 4a        
            bcc __c753         ; $c750: 90 01     
            iny                ; $c752: c8        
__c753:     sty $06d3          ; $c753: 8c d3 06  
__c756:     ldx #$ff           ; $c756: a2 ff     
__c758:     inx                ; $c758: e8        
            cpx #$05           ; $c759: e0 05     
            bcs __c78a         ; $c75b: b0 2d     
            lda $0f,x          ; $c75d: b5 0f     
            bne __c758         ; $c75f: d0 f7     
            lda $01            ; $c761: a5 01     
            sta $16,x          ; $c763: 95 16     
            lda $02            ; $c765: a5 02     
            sta $6e,x          ; $c767: 95 6e     
            lda $03            ; $c769: a5 03     
            sta $87,x          ; $c76b: 95 87     
            clc                ; $c76d: 18        
            adc #$18           ; $c76e: 69 18     
            sta $03            ; $c770: 85 03     
            lda $02            ; $c772: a5 02     
            adc #$00           ; $c774: 69 00     
            sta $02            ; $c776: 85 02     
            lda $00            ; $c778: a5 00     
            sta $cf,x          ; $c77a: 95 cf     
            lda #$01           ; $c77c: a9 01     
            sta $b6,x          ; $c77e: 95 b6     
            sta $0f,x          ; $c780: 95 0f     
            jsr __c272         ; $c782: 20 72 c2  
            dec $06d3          ; $c785: ce d3 06  
            bne __c756         ; $c788: d0 cc     
__c78a:     jmp __c264         ; $c78a: 4c 64 c2  

;-------------------------------------------------------------------------------
            lda #$01           ; $c78d: a9 01     
            sta $58,x          ; $c78f: 95 58     
            lsr                ; $c791: 4a        
            sta $1e,x          ; $c792: 95 1e     
            sta $a0,x          ; $c794: 95 a0     
            lda $cf,x          ; $c796: b5 cf     
            sta $0434,x        ; $c798: 9d 34 04  
            sec                ; $c79b: 38        
            sbc #$18           ; $c79c: e9 18     
            sta $0417,x        ; $c79e: 9d 17 04  
            lda #$09           ; $c7a1: a9 09     
            jmp __c7e1         ; $c7a3: 4c e1 c7  

;-------------------------------------------------------------------------------
            lda $16,x          ; $c7a6: b5 16     
            sta $06cb          ; $c7a8: 8d cb 06  
            sec                ; $c7ab: 38        
            sbc #$12           ; $c7ac: e9 12     
            jsr __8e04         ; $c7ae: 20 04 8e  
            tax                ; $c7b1: aa        
            .hex c3 bd         ; $c7b2: c3 bd     Invalid Opcode - DCP ($bd,x)
            .hex c7 ae         ; $c7b4: c7 ae     Invalid Opcode - DCP $ae
            cpy $a9            ; $c7b6: c4 a9     
            cmp $43            ; $c7b8: c5 43     
            dec $a2            ; $c7ba: c6 a2     
            dec $60            ; $c7bc: c6 60     
            ldy #$05           ; $c7be: a0 05     
__c7c0:     lda $0016,y        ; $c7c0: b9 16 00  
            cmp #$11           ; $c7c3: c9 11     
            bne __c7cc         ; $c7c5: d0 05     
            lda #$01           ; $c7c7: a9 01     
            sta $001e,y        ; $c7c9: 99 1e 00  
__c7cc:     dey                ; $c7cc: 88        
            bpl __c7c0         ; $c7cd: 10 f1     
            lda #$00           ; $c7cf: a9 00     
            sta $06cb          ; $c7d1: 8d cb 06  
            sta $0f,x          ; $c7d4: 95 0f     
            rts                ; $c7d6: 60        

;-------------------------------------------------------------------------------
            lda #$02           ; $c7d7: a9 02     
            sta $46,x          ; $c7d9: 95 46     
            lda #$f6           ; $c7db: a9 f6     
            sta $58,x          ; $c7dd: 95 58     
__c7df:     lda #$03           ; $c7df: a9 03     
__c7e1:     sta $049a,x        ; $c7e1: 9d 9a 04  
            rts                ; $c7e4: 60        

;-------------------------------------------------------------------------------
            dec $cf,x          ; $c7e5: d6 cf     
            dec $cf,x          ; $c7e7: d6 cf     
            ldy $06cc          ; $c7e9: ac cc 06  
            bne __c7f3         ; $c7ec: d0 05     
            ldy #$02           ; $c7ee: a0 02     
            jsr __c877         ; $c7f0: 20 77 c8  
__c7f3:     ldy #$ff           ; $c7f3: a0 ff     
            lda $03a0          ; $c7f5: ad a0 03  
            sta $1e,x          ; $c7f8: 95 1e     
            bpl __c7fe         ; $c7fa: 10 02     
            txa                ; $c7fc: 8a        
            tay                ; $c7fd: a8        
__c7fe:     sty $03a0          ; $c7fe: 8c a0 03  
            lda #$00           ; $c801: a9 00     
            sta $46,x          ; $c803: 95 46     
            tay                ; $c805: a8        
            .hex 20            ; $c806: 20        Suspected data
__c807:     .hex 77 c8         ; $c807: 77 c8     Invalid Opcode - RRA $c8,x
            lda #$ff           ; $c809: a9 ff     
            sta $03a2,x        ; $c80b: 9d a2 03  
            jmp __c82e         ; $c80e: 4c 2e c8  

;-------------------------------------------------------------------------------
            lda #$00           ; $c811: a9 00     
            sta $58,x          ; $c813: 95 58     
            jmp __c82e         ; $c815: 4c 2e c8  

;-------------------------------------------------------------------------------
            ldy #$40           ; $c818: a0 40     
            lda $cf,x          ; $c81a: b5 cf     
            bpl __c825         ; $c81c: 10 07     
            eor #$ff           ; $c81e: 49 ff     
            clc                ; $c820: 18        
            adc #$01           ; $c821: 69 01     
            ldy #$c0           ; $c823: a0 c0     
__c825:     sta $0401,x        ; $c825: 9d 01 04  
__c828:     tya                ; $c828: 98        
            clc                ; $c829: 18        
            adc $cf,x          ; $c82a: 75 cf     
            sta $58,x          ; $c82c: 95 58     
__c82e:     jsr __c369         ; $c82e: 20 69 c3  
__c831:     lda #$05           ; $c831: a9 05     
            ldy $074e          ; $c833: ac 4e 07  
            cpy #$03           ; $c836: c0 03     
            beq __c841         ; $c838: f0 07     
            ldy $06cc          ; $c83a: ac cc 06  
            bne __c841         ; $c83d: d0 02     
            lda #$06           ; $c83f: a9 06     
__c841:     sta $049a,x        ; $c841: 9d 9a 04  
            rts                ; $c844: 60        

;-------------------------------------------------------------------------------
            jsr __c851         ; $c845: 20 51 c8  
            jmp __c84e         ; $c848: 4c 4e c8  

;-------------------------------------------------------------------------------
            jsr __c85d         ; $c84b: 20 5d c8  
__c84e:     jmp __c831         ; $c84e: 4c 31 c8  

;-------------------------------------------------------------------------------
__c851:     lda #$10           ; $c851: a9 10     
            sta $0434,x        ; $c853: 9d 34 04  
            lda #$ff           ; $c856: a9 ff     
            sta $a0,x          ; $c858: 95 a0     
            jmp __c866         ; $c85a: 4c 66 c8  

;-------------------------------------------------------------------------------
__c85d:     lda #$f0           ; $c85d: a9 f0     
            sta $0434,x        ; $c85f: 9d 34 04  
            lda #$00           ; $c862: a9 00     
            sta $a0,x          ; $c864: 95 a0     
__c866:     ldy #$01           ; $c866: a0 01     
            jsr __c877         ; $c868: 20 77 c8  
            lda #$04           ; $c86b: a9 04     
            sta $049a,x        ; $c86d: 9d 9a 04  
            rts                ; $c870: 60        

;-------------------------------------------------------------------------------
__c871:     php                ; $c871: 08        
            .hex 0c f8         ; $c872: 0c f8     Suspected data
__c874:     brk                ; $c874: 00        
            brk                ; $c875: 00        
            .hex ff            ; $c876: ff        Suspected data
__c877:     lda $87,x          ; $c877: b5 87     
            clc                ; $c879: 18        
            adc __c871,y       ; $c87a: 79 71 c8  
            sta $87,x          ; $c87d: 95 87     
            lda $6e,x          ; $c87f: b5 6e     
            adc __c874,y       ; $c881: 79 74 c8  
            sta $6e,x          ; $c884: 95 6e     
            rts                ; $c886: 60        

;-------------------------------------------------------------------------------
            rts                ; $c887: 60        

;-------------------------------------------------------------------------------
__c888:     ldx $08            ; $c888: a6 08     
            lda #$00           ; $c88a: a9 00     
            ldy $16,x          ; $c88c: b4 16     
            cpy #$15           ; $c88e: c0 15     
            bcc __c895         ; $c890: 90 03     
            tya                ; $c892: 98        
            sbc #$14           ; $c893: e9 14     
__c895:     jsr __8e04         ; $c895: 20 04 8e  
            inc $c8            ; $c898: e6 c8     
            .hex 3b c9 5d      ; $c89a: 3b c9 5d  Invalid Opcode - RLA $5dc9,y
            .hex d2            ; $c89d: d2        Invalid Opcode - KIL 
            .hex dc c8 dc      ; $c89e: dc c8 dc  Invalid Opcode - NOP __dcc8,x
            iny                ; $c8a1: c8        
            .hex dc c8 dc      ; $c8a2: dc c8 dc  Invalid Opcode - NOP __dcc8,x
            iny                ; $c8a5: c8        
            eor $4dc9          ; $c8a6: 4d c9 4d  
            cmp #$4d           ; $c8a9: c9 4d     
            cmp #$4d           ; $c8ab: c9 4d     
            cmp #$4d           ; $c8ad: c9 4d     
            cmp #$4d           ; $c8af: c9 4d     
            cmp #$4d           ; $c8b1: c9 4d     
            cmp #$4d           ; $c8b3: c9 4d     
            cmp #$dc           ; $c8b5: c9 dc     
            iny                ; $c8b7: c8        
            .hex 6b c9         ; $c8b8: 6b c9     Invalid Opcode - ARR #$c9
            .hex 6b c9         ; $c8ba: 6b c9     Invalid Opcode - ARR #$c9
            .hex 6b c9         ; $c8bc: 6b c9     Invalid Opcode - ARR #$c9
            .hex 6b c9         ; $c8be: 6b c9     Invalid Opcode - ARR #$c9
            .hex 6b c9         ; $c8c0: 6b c9     Invalid Opcode - ARR #$c9
            .hex 6b c9         ; $c8c2: 6b c9     Invalid Opcode - ARR #$c9
            .hex 6b c9         ; $c8c4: 6b c9     Invalid Opcode - ARR #$c9
            .hex 53 c9         ; $c8c6: 53 c9     Invalid Opcode - SRE ($c9),y
            .hex 53 c9         ; $c8c8: 53 c9     Invalid Opcode - SRE ($c9),y
            and __8ad0         ; $c8ca: 2d d0 8a  
            ldy __b950,x       ; $c8cd: bc 50 b9  
            .hex dc c8 a1      ; $c8d0: dc c8 a1  Invalid Opcode - NOP __a1c8,x
            .hex d2            ; $c8d3: d2        Invalid Opcode - KIL 
            tsx                ; $c8d4: ba        
            clv                ; $c8d5: b8        
            .hex dc c8 a4      ; $c8d6: dc c8 a4  Invalid Opcode - NOP __a4c8,x
            .hex b7 dd         ; $c8d9: b7 dd     Invalid Opcode - LAX $dd,y
            iny                ; $c8db: c8        
            rts                ; $c8dc: 60        

;-------------------------------------------------------------------------------
__c8dd:     jsr __f1b6         ; $c8dd: 20 b6 f1  
            jsr __f159         ; $c8e0: 20 59 f1  
            jmp __e884         ; $c8e3: 4c 84 e8  

;-------------------------------------------------------------------------------
            lda #$00           ; $c8e6: a9 00     
            sta $03c5,x        ; $c8e8: 9d c5 03  
            jsr __f1b6         ; $c8eb: 20 b6 f1  
            jsr __f159         ; $c8ee: 20 59 f1  
            .hex 20            ; $c8f1: 20        Suspected data
__c8f2:     sty $e8            ; $c8f2: 84 e8     
__c8f4:     jsr __e24b         ; $c8f4: 20 4b e2  
            jsr __dfc9         ; $c8f7: 20 c9 df  
            jsr __da35         ; $c8fa: 20 35 da  
            jsr __d853         ; $c8fd: 20 53 d8  
            .hex ac 47         ; $c900: ac 47     Suspected data
__c902:     .hex 07 d0         ; $c902: 07 d0     Invalid Opcode - SLO $d0
            .hex 03 20         ; $c904: 03 20     Invalid Opcode - SLO ($20,x)
__c906:     .hex 0b c9         ; $c906: 0b c9     Invalid Opcode - ANC #$c9
            jmp __d642         ; $c908: 4c 42 d6  

;-------------------------------------------------------------------------------
            lda $16,x          ; $c90b: b5 16     
            jsr __8e04         ; $c90d: 20 04 8e  
            adc $7dca,x        ; $c910: 7d ca 7d  
            dex                ; $c913: ca        
            adc $7dca,x        ; $c914: 7d ca 7d  
            dex                ; $c917: ca        
            adc __deca,x       ; $c918: 7d ca de  
            cmp #$7d           ; $c91b: c9 7d     
            dex                ; $c91d: ca        
            .hex 8f cb 3c      ; $c91e: 8f cb 3c  Invalid Opcode - SAX $3ccb
            cpy __c93a         ; $c921: cc 3a c9  
            bvc __c8f2         ; $c924: 50 cc     
            bvc __c8f4         ; $c926: 50 cc     
            ldx $c9,y          ; $c928: b6 c9     
            sei                ; $c92a: 78        
            .hex d3 ff         ; $c92b: d3 ff     Invalid Opcode - DCP ($ff),y
            dex                ; $c92d: ca        
            ora $cb            ; $c92e: 05 cb     
            .hex 2b cb         ; $c930: 2b cb     Invalid Opcode - ANC #$cb
            beq __c902         ; $c932: f0 ce     
            adc $3aca,x        ; $c934: 7d ca 3a  
            cmp #$db           ; $c937: c9 db     
            .hex ce            ; $c939: ce        Suspected data
__c93a:     rts                ; $c93a: 60        

;-------------------------------------------------------------------------------
            jsr __d1b3         ; $c93b: 20 b3 d1  
            .hex 20 b6         ; $c93e: 20 b6     Suspected data
__c940:     sbc ($20),y        ; $c940: f1 20     
            eor $20f1,y        ; $c942: 59 f1 20  
            .hex 4b e2         ; $c945: 4b e2     Invalid Opcode - ALR #$e2
            jsr __d853         ; $c947: 20 53 d8  
            jmp __d642         ; $c94a: 4c 42 d6  

;-------------------------------------------------------------------------------
            jsr __cd42         ; $c94d: 20 42 cd  
            jmp __d642         ; $c950: 4c 42 d6  

;-------------------------------------------------------------------------------
            jsr __f1b6         ; $c953: 20 b6 f1  
            jsr __f159         ; $c956: 20 59 f1  
            jsr __e254         ; $c959: 20 54 e2  
            jsr __db7d         ; $c95c: 20 7d db  
            jsr __f159         ; $c95f: 20 59 f1  
            jsr __ed6d         ; $c962: 20 6d ed  
            jsr __d61d         ; $c965: 20 1d d6  
            jmp __d642         ; $c968: 4c 42 d6  

;-------------------------------------------------------------------------------
            jsr __f1b6         ; $c96b: 20 b6 f1  
            jsr __f159         ; $c96e: 20 59 f1  
            jsr __e27b         ; $c971: 20 7b e2  
            jsr __db47         ; $c974: 20 47 db  
            lda $0747          ; $c977: ad 47 07  
            bne __c97f         ; $c97a: d0 03     
            jsr __c988         ; $c97c: 20 88 c9  
__c97f:     jsr __f159         ; $c97f: 20 59 f1  
            jsr __e5cf         ; $c982: 20 cf e5  
            jmp __d642         ; $c985: 4c 42 d6  

;-------------------------------------------------------------------------------
__c988:     lda $16,x          ; $c988: b5 16     
            sec                ; $c98a: 38        
            sbc #$24           ; $c98b: e9 24     
            jsr __8e04         ; $c98d: 20 04 8e  
            .hex fa            ; $c990: fa        Invalid Opcode - NOP 
            .hex d3 9b         ; $c991: d3 9b     Invalid Opcode - DCP ($9b),y
            cmp $17,x          ; $c993: d5 17     
            dec $17,x          ; $c995: d6 17     
            dec $cf,x          ; $c997: d6 cf     
            cmp $f9,x          ; $c999: d5 f9     
            cmp $05,x          ; $c99b: d5 05     
            .hex d6            ; $c99d: d6        Suspected data
__c99e:     lda #$00           ; $c99e: a9 00     
            sta $0f,x          ; $c9a0: 95 0f     
            sta $16,x          ; $c9a2: 95 16     
            sta $1e,x          ; $c9a4: 95 1e     
            sta $0110,x        ; $c9a6: 9d 10 01  
            sta $0796,x        ; $c9a9: 9d 96 07  
            sta $0125,x        ; $c9ac: 9d 25 01  
            sta $03c5,x        ; $c9af: 9d c5 03  
            sta $078a,x        ; $c9b2: 9d 8a 07  
            rts                ; $c9b5: 60        

;-------------------------------------------------------------------------------
            lda $0796,x        ; $c9b6: bd 96 07  
            bne __c9d1         ; $c9b9: d0 16     
            jsr __c2fd         ; $c9bb: 20 fd c2  
            lda $07a8,x        ; $c9be: bd a8 07  
            ora #$80           ; $c9c1: 09 80     
            sta $0434,x        ; $c9c3: 9d 34 04  
            and #$0f           ; $c9c6: 29 0f     
            ora #$06           ; $c9c8: 09 06     
__c9ca:     sta $0796,x        ; $c9ca: 9d 96 07  
            lda #$f9           ; $c9cd: a9 f9     
            sta $a0,x          ; $c9cf: 95 a0     
__c9d1:     jmp __bf97         ; $c9d1: 4c 97 bf  

;-------------------------------------------------------------------------------
__c9d4:     bmi __c9f2         ; $c9d4: 30 1c     
__c9d6:     brk                ; $c9d6: 00        
            inx                ; $c9d7: e8        
            brk                ; $c9d8: 00        
            clc                ; $c9d9: 18        
__c9da:     php                ; $c9da: 08        
            sed                ; $c9db: f8        
            .hex 0c f4 b5      ; $c9dc: 0c f4 b5  Invalid Opcode - NOP __b5f4
            asl $2029,x        ; $c9df: 1e 29 20  
            beq __c9e7         ; $c9e2: f0 03     
            jmp __caeb         ; $c9e4: 4c eb ca  

;-------------------------------------------------------------------------------
__c9e7:     lda $3c,x          ; $c9e7: b5 3c     
            beq __ca18         ; $c9e9: f0 2d     
            dec $3c,x          ; $c9eb: d6 3c     
            lda $03d1          ; $c9ed: ad d1 03  
            and #$0c           ; $c9f0: 29 0c     
__c9f2:     bne __ca5e         ; $c9f2: d0 6a     
            lda $03a2,x        ; $c9f4: bd a2 03  
            bne __ca10         ; $c9f7: d0 17     
            ldy $06cc          ; $c9f9: ac cc 06  
            lda __c9d4,y       ; $c9fc: b9 d4 c9  
            sta $03a2,x        ; $c9ff: 9d a2 03  
            jsr __ba99         ; $ca02: 20 99 ba  
            bcc __ca10         ; $ca05: 90 09     
            lda $1e,x          ; $ca07: b5 1e     
            ora #$08           ; $ca09: 09 08     
            sta $1e,x          ; $ca0b: 95 1e     
            jmp __ca5e         ; $ca0d: 4c 5e ca  

;-------------------------------------------------------------------------------
__ca10:     dec $03a2,x        ; $ca10: de a2 03  
            jmp __ca5e         ; $ca13: 4c 5e ca  

;-------------------------------------------------------------------------------
__ca16:     .hex 20 37         ; $ca16: 20 37     Suspected data
__ca18:     lda $1e,x          ; $ca18: b5 1e     
            and #$07           ; $ca1a: 29 07     
            cmp #$01           ; $ca1c: c9 01     
            beq __ca5e         ; $ca1e: f0 3e     
            lda #$00           ; $ca20: a9 00     
            sta $00            ; $ca22: 85 00     
            ldy #$fa           ; $ca24: a0 fa     
            lda $cf,x          ; $ca26: b5 cf     
            bmi __ca3d         ; $ca28: 30 13     
            ldy #$fd           ; $ca2a: a0 fd     
            cmp #$70           ; $ca2c: c9 70     
            inc $00            ; $ca2e: e6 00     
            bcc __ca3d         ; $ca30: 90 0b     
            dec $00            ; $ca32: c6 00     
            lda $07a8,x        ; $ca34: bd a8 07  
            and #$01           ; $ca37: 29 01     
            bne __ca3d         ; $ca39: d0 02     
            ldy #$fa           ; $ca3b: a0 fa     
__ca3d:     sty $a0,x          ; $ca3d: 94 a0     
            lda $1e,x          ; $ca3f: b5 1e     
            ora #$01           ; $ca41: 09 01     
            sta $1e,x          ; $ca43: 95 1e     
            lda $00            ; $ca45: a5 00     
            and $07a9,x        ; $ca47: 3d a9 07  
            tay                ; $ca4a: a8        
            lda $06cc          ; $ca4b: ad cc 06  
            bne __ca51         ; $ca4e: d0 01     
            tay                ; $ca50: a8        
__ca51:     lda __ca16,y       ; $ca51: b9 16 ca  
            sta $078a,x        ; $ca54: 9d 8a 07  
            lda $07a8,x        ; $ca57: bd a8 07  
            ora #$c0           ; $ca5a: 09 c0     
            sta $3c,x          ; $ca5c: 95 3c     
__ca5e:     ldy #$fb           ; $ca5e: a0 fb     
            lda $09            ; $ca60: a5 09     
            and #$40           ; $ca62: 29 40     
            bne __ca68         ; $ca64: d0 02     
            ldy #$05           ; $ca66: a0 05     
__ca68:     sty $58,x          ; $ca68: 94 58     
            ldy #$01           ; $ca6a: a0 01     
            jsr __e14b         ; $ca6c: 20 4b e1  
            bmi __ca7b         ; $ca6f: 30 0a     
            iny                ; $ca71: c8        
            lda $0796,x        ; $ca72: bd 96 07  
            bne __ca7b         ; $ca75: d0 04     
            lda #$f6           ; $ca77: a9 f6     
            sta $58,x          ; $ca79: 95 58     
__ca7b:     sty $46,x          ; $ca7b: 94 46     
__ca7d:     ldy #$00           ; $ca7d: a0 00     
            lda $1e,x          ; $ca7f: b5 1e     
            and #$40           ; $ca81: 29 40     
            bne __ca9e         ; $ca83: d0 19     
            lda $1e,x          ; $ca85: b5 1e     
            asl                ; $ca87: 0a        
            bcs __caba         ; $ca88: b0 30     
            lda $1e,x          ; $ca8a: b5 1e     
            and #$20           ; $ca8c: 29 20     
            bne __caeb         ; $ca8e: d0 5b     
            lda $1e,x          ; $ca90: b5 1e     
            and #$07           ; $ca92: 29 07     
            beq __caba         ; $ca94: f0 24     
            cmp #$05           ; $ca96: c9 05     
            beq __ca9e         ; $ca98: f0 04     
            cmp #$03           ; $ca9a: c9 03     
            bcs __cace         ; $ca9c: b0 30     
__ca9e:     jsr __bf68         ; $ca9e: 20 68 bf  
            ldy #$00           ; $caa1: a0 00     
            lda $1e,x          ; $caa3: b5 1e     
            cmp #$02           ; $caa5: c9 02     
            beq __cab5         ; $caa7: f0 0c     
            and #$40           ; $caa9: 29 40     
            beq __caba         ; $caab: f0 0d     
            lda $16,x          ; $caad: b5 16     
            cmp #$2e           ; $caaf: c9 2e     
            beq __caba         ; $cab1: f0 07     
            bne __cab8         ; $cab3: d0 03     
__cab5:     jmp __bf07         ; $cab5: 4c 07 bf  

;-------------------------------------------------------------------------------
__cab8:     ldy #$01           ; $cab8: a0 01     
__caba:     lda $58,x          ; $caba: b5 58     
            pha                ; $cabc: 48        
            bpl __cac1         ; $cabd: 10 02     
            iny                ; $cabf: c8        
            iny                ; $cac0: c8        
__cac1:     clc                ; $cac1: 18        
            adc __c9d6,y       ; $cac2: 79 d6 c9  
            sta $58,x          ; $cac5: 95 58     
            jsr __bf07         ; $cac7: 20 07 bf  
            pla                ; $caca: 68        
            sta $58,x          ; $cacb: 95 58     
            rts                ; $cacd: 60        

;-------------------------------------------------------------------------------
__cace:     lda $0796,x        ; $cace: bd 96 07  
            bne __caf1         ; $cad1: d0 1e     
            sta $1e,x          ; $cad3: 95 1e     
            lda $09            ; $cad5: a5 09     
            and #$01           ; $cad7: 29 01     
            tay                ; $cad9: a8        
            iny                ; $cada: c8        
            sty $46,x          ; $cadb: 94 46     
            dey                ; $cadd: 88        
            lda $076a          ; $cade: ad 6a 07  
            beq __cae5         ; $cae1: f0 02     
            iny                ; $cae3: c8        
            iny                ; $cae4: c8        
__cae5:     lda __c9da,y       ; $cae5: b9 da c9  
            sta $58,x          ; $cae8: 95 58     
            rts                ; $caea: 60        

;-------------------------------------------------------------------------------
__caeb:     jsr __bf68         ; $caeb: 20 68 bf  
            jmp __bf07         ; $caee: 4c 07 bf  

;-------------------------------------------------------------------------------
__caf1:     cmp #$0b           ; $caf1: c9 0b     
            bne __cafe         ; $caf3: d0 09     
            lda $16,x          ; $caf5: b5 16     
            cmp #$06           ; $caf7: c9 06     
            bne __cafe         ; $caf9: d0 03     
            jsr __c99e         ; $cafb: 20 9e c9  
__cafe:     rts                ; $cafe: 60        

;-------------------------------------------------------------------------------
__caff:     jsr __bf97         ; $caff: 20 97 bf  
            jmp __bf07         ; $cb02: 4c 07 bf  

;-------------------------------------------------------------------------------
            lda $a0,x          ; $cb05: b5 a0     
            ora $0434,x        ; $cb07: 1d 34 04  
            bne __cb1f         ; $cb0a: d0 13     
            sta $0417,x        ; $cb0c: 9d 17 04  
            lda $cf,x          ; $cb0f: b5 cf     
            cmp $0401,x        ; $cb11: dd 01 04  
            bcs __cb1f         ; $cb14: b0 09     
            lda $09            ; $cb16: a5 09     
            and #$07           ; $cb18: 29 07     
            bne __cb1e         ; $cb1a: d0 02     
            inc $cf,x          ; $cb1c: f6 cf     
__cb1e:     rts                ; $cb1e: 60        

;-------------------------------------------------------------------------------
__cb1f:     lda $cf,x          ; $cb1f: b5 cf     
            cmp $58,x          ; $cb21: d5 58     
            bcc __cb28         ; $cb23: 90 03     
__cb25:     jmp __bf7a         ; $cb25: 4c 7a bf  

;-------------------------------------------------------------------------------
__cb28:     jmp __bf75         ; $cb28: 4c 75 bf  

;-------------------------------------------------------------------------------
            jsr __cb4b         ; $cb2b: 20 4b cb  
            jsr __cb6c         ; $cb2e: 20 6c cb  
            ldy #$01           ; $cb31: a0 01     
            lda $09            ; $cb33: a5 09     
            and #$03           ; $cb35: 29 03     
            bne __cb4a         ; $cb37: d0 11     
            lda $09            ; $cb39: a5 09     
            and #$40           ; $cb3b: 29 40     
            bne __cb41         ; $cb3d: d0 02     
            ldy #$ff           ; $cb3f: a0 ff     
__cb41:     sty $00            ; $cb41: 84 00     
            lda $cf,x          ; $cb43: b5 cf     
            clc                ; $cb45: 18        
            adc $00            ; $cb46: 65 00     
            sta $cf,x          ; $cb48: 95 cf     
__cb4a:     rts                ; $cb4a: 60        

;-------------------------------------------------------------------------------
__cb4b:     lda #$13           ; $cb4b: a9 13     
__cb4d:     sta $01            ; $cb4d: 85 01     
            lda $09            ; $cb4f: a5 09     
            and #$03           ; $cb51: 29 03     
            bne __cb62         ; $cb53: d0 0d     
            ldy $58,x          ; $cb55: b4 58     
            lda $a0,x          ; $cb57: b5 a0     
            lsr                ; $cb59: 4a        
            bcs __cb66         ; $cb5a: b0 0a     
            cpy $01            ; $cb5c: c4 01     
            beq __cb63         ; $cb5e: f0 03     
            inc $58,x          ; $cb60: f6 58     
__cb62:     rts                ; $cb62: 60        

;-------------------------------------------------------------------------------
__cb63:     inc $a0,x          ; $cb63: f6 a0     
            rts                ; $cb65: 60        

;-------------------------------------------------------------------------------
__cb66:     tya                ; $cb66: 98        
            beq __cb63         ; $cb67: f0 fa     
            dec $58,x          ; $cb69: d6 58     
            rts                ; $cb6b: 60        

;-------------------------------------------------------------------------------
__cb6c:     lda $58,x          ; $cb6c: b5 58     
            pha                ; $cb6e: 48        
            ldy #$01           ; $cb6f: a0 01     
            lda $a0,x          ; $cb71: b5 a0     
            and #$02           ; $cb73: 29 02     
            bne __cb82         ; $cb75: d0 0b     
            lda $58,x          ; $cb77: b5 58     
            eor #$ff           ; $cb79: 49 ff     
            clc                ; $cb7b: 18        
            adc #$01           ; $cb7c: 69 01     
            sta $58,x          ; $cb7e: 95 58     
            ldy #$02           ; $cb80: a0 02     
__cb82:     sty $46,x          ; $cb82: 94 46     
            jsr __bf07         ; $cb84: 20 07 bf  
            sta $00            ; $cb87: 85 00     
            pla                ; $cb89: 68        
            sta $58,x          ; $cb8a: 95 58     
            rts                ; $cb8c: 60        

;-------------------------------------------------------------------------------
__cb8d:     .hex 07 01         ; $cb8d: 07 01     Invalid Opcode - SLO $01
            lda $1e,x          ; $cb8f: b5 1e     
            and #$20           ; $cb91: 29 20     
            bne __cbe2         ; $cb93: d0 4d     
            ldy $06cc          ; $cb95: ac cc 06  
            lda $07a8,x        ; $cb98: bd a8 07  
            and __cb8d,y       ; $cb9b: 39 8d cb  
            bne __cbb2         ; $cb9e: d0 12     
            txa                ; $cba0: 8a        
            lsr                ; $cba1: 4a        
            bcc __cba8         ; $cba2: 90 04     
            ldy $45            ; $cba4: a4 45     
            bcs __cbb0         ; $cba6: b0 08     
__cba8:     ldy #$02           ; $cba8: a0 02     
            jsr __e14b         ; $cbaa: 20 4b e1  
            bpl __cbb0         ; $cbad: 10 01     
            dey                ; $cbaf: 88        
__cbb0:     sty $46,x          ; $cbb0: 94 46     
__cbb2:     jsr __cbe5         ; $cbb2: 20 e5 cb  
            lda $cf,x          ; $cbb5: b5 cf     
            sec                ; $cbb7: 38        
            sbc $0434,x        ; $cbb8: fd 34 04  
            cmp #$20           ; $cbbb: c9 20     
            bcc __cbc1         ; $cbbd: 90 02     
            sta $cf,x          ; $cbbf: 95 cf     
__cbc1:     ldy $46,x          ; $cbc1: b4 46     
            dey                ; $cbc3: 88        
            bne __cbd4         ; $cbc4: d0 0e     
            lda $87,x          ; $cbc6: b5 87     
            clc                ; $cbc8: 18        
            adc $58,x          ; $cbc9: 75 58     
            sta $87,x          ; $cbcb: 95 87     
            lda $6e,x          ; $cbcd: b5 6e     
            adc #$00           ; $cbcf: 69 00     
            sta $6e,x          ; $cbd1: 95 6e     
            rts                ; $cbd3: 60        

;-------------------------------------------------------------------------------
__cbd4:     lda $87,x          ; $cbd4: b5 87     
            sec                ; $cbd6: 38        
            sbc $58,x          ; $cbd7: f5 58     
            sta $87,x          ; $cbd9: 95 87     
            lda $6e,x          ; $cbdb: b5 6e     
            sbc #$00           ; $cbdd: e9 00     
            sta $6e,x          ; $cbdf: 95 6e     
            rts                ; $cbe1: 60        

;-------------------------------------------------------------------------------
__cbe2:     jmp __bf91         ; $cbe2: 4c 91 bf  

;-------------------------------------------------------------------------------
__cbe5:     lda $a0,x          ; $cbe5: b5 a0     
            and #$02           ; $cbe7: 29 02     
            bne __cc22         ; $cbe9: d0 37     
            lda $09            ; $cbeb: a5 09     
            and #$07           ; $cbed: 29 07     
            pha                ; $cbef: 48        
            lda $a0,x          ; $cbf0: b5 a0     
            lsr                ; $cbf2: 4a        
            bcs __cc0a         ; $cbf3: b0 15     
            pla                ; $cbf5: 68        
            bne __cc09         ; $cbf6: d0 11     
            lda $0434,x        ; $cbf8: bd 34 04  
            clc                ; $cbfb: 18        
            adc #$01           ; $cbfc: 69 01     
            sta $0434,x        ; $cbfe: 9d 34 04  
__cc01:     sta $58,x          ; $cc01: 95 58     
            cmp #$02           ; $cc03: c9 02     
            bne __cc09         ; $cc05: d0 02     
            inc $a0,x          ; $cc07: f6 a0     
__cc09:     rts                ; $cc09: 60        

;-------------------------------------------------------------------------------
__cc0a:     pla                ; $cc0a: 68        
            bne __cc21         ; $cc0b: d0 14     
            lda $0434,x        ; $cc0d: bd 34 04  
            sec                ; $cc10: 38        
            sbc #$01           ; $cc11: e9 01     
            sta $0434,x        ; $cc13: 9d 34 04  
            sta $58,x          ; $cc16: 95 58     
            bne __cc21         ; $cc18: d0 07     
            .hex f6            ; $cc1a: f6        Suspected data
__cc1b:     ldy #$a9           ; $cc1b: a0 a9     
            .hex 02            ; $cc1d: 02        Invalid Opcode - KIL 
            sta $0796,x        ; $cc1e: 9d 96 07  
__cc21:     rts                ; $cc21: 60        

;-------------------------------------------------------------------------------
__cc22:     lda $0796,x        ; $cc22: bd 96 07  
            beq __cc2f         ; $cc25: f0 08     
__cc27:     lda $09            ; $cc27: a5 09     
            lsr                ; $cc29: 4a        
            bcs __cc2e         ; $cc2a: b0 02     
            inc $cf,x          ; $cc2c: f6 cf     
__cc2e:     rts                ; $cc2e: 60        

;-------------------------------------------------------------------------------
__cc2f:     lda $cf,x          ; $cc2f: b5 cf     
            adc #$0c           ; $cc31: 69 0c     
            cmp $ce            ; $cc33: c5 ce     
            bcc __cc27         ; $cc35: 90 f0     
            lda #$00           ; $cc37: a9 00     
            sta $a0,x          ; $cc39: 95 a0     
            rts                ; $cc3b: 60        

;-------------------------------------------------------------------------------
            lda $1e,x          ; $cc3c: b5 1e     
            and #$20           ; $cc3e: 29 20     
            beq __cc45         ; $cc40: f0 03     
            jmp __bf97         ; $cc42: 4c 97 bf  

;-------------------------------------------------------------------------------
__cc45:     lda #$e8           ; $cc45: a9 e8     
            sta $58,x          ; $cc47: 95 58     
            jmp __bf07         ; $cc49: 4c 07 bf  

;-------------------------------------------------------------------------------
__cc4c:     rti                ; $cc4c: 40        

;-------------------------------------------------------------------------------
            .hex 80 04         ; $cc4d: 80 04     Invalid Opcode - NOP #$04
            .hex 04 b5         ; $cc4f: 04 b5     Invalid Opcode - NOP $b5
            asl $2029,x        ; $cc51: 1e 29 20  
            beq __cc59         ; $cc54: f0 03     
            jmp __bf91         ; $cc56: 4c 91 bf  

;-------------------------------------------------------------------------------
__cc59:     sta $03            ; $cc59: 85 03     
            lda $16,x          ; $cc5b: b5 16     
            sec                ; $cc5d: 38        
            sbc #$0a           ; $cc5e: e9 0a     
            tay                ; $cc60: a8        
            lda __cc4c,y       ; $cc61: b9 4c cc  
            sta $02            ; $cc64: 85 02     
            lda $0401,x        ; $cc66: bd 01 04  
            sec                ; $cc69: 38        
            sbc $02            ; $cc6a: e5 02     
            sta $0401,x        ; $cc6c: 9d 01 04  
            lda $87,x          ; $cc6f: b5 87     
            sbc #$00           ; $cc71: e9 00     
            sta $87,x          ; $cc73: 95 87     
            lda $6e,x          ; $cc75: b5 6e     
            sbc #$00           ; $cc77: e9 00     
            sta $6e,x          ; $cc79: 95 6e     
            lda #$20           ; $cc7b: a9 20     
            sta $02            ; $cc7d: 85 02     
            cpx #$02           ; $cc7f: e0 02     
            bcc __cccc         ; $cc81: 90 49     
            lda $58,x          ; $cc83: b5 58     
            cmp #$10           ; $cc85: c9 10     
            bcc __cc9f         ; $cc87: 90 16     
            lda $0417,x        ; $cc89: bd 17 04  
            clc                ; $cc8c: 18        
            adc $02            ; $cc8d: 65 02     
            sta $0417,x        ; $cc8f: 9d 17 04  
            lda $cf,x          ; $cc92: b5 cf     
            adc $03            ; $cc94: 65 03     
            sta $cf,x          ; $cc96: 95 cf     
            lda $b6,x          ; $cc98: b5 b6     
            adc #$00           ; $cc9a: 69 00     
            jmp __ccb2         ; $cc9c: 4c b2 cc  

;-------------------------------------------------------------------------------
__cc9f:     lda $0417,x        ; $cc9f: bd 17 04  
            sec                ; $cca2: 38        
            sbc $02            ; $cca3: e5 02     
            sta $0417,x        ; $cca5: 9d 17 04  
            lda $cf,x          ; $cca8: b5 cf     
            sbc $03            ; $ccaa: e5 03     
            sta $cf,x          ; $ccac: 95 cf     
            lda $b6,x          ; $ccae: b5 b6     
            sbc #$00           ; $ccb0: e9 00     
__ccb2:     sta $b6,x          ; $ccb2: 95 b6     
            ldy #$00           ; $ccb4: a0 00     
            lda $cf,x          ; $ccb6: b5 cf     
            sec                ; $ccb8: 38        
            sbc $0434,x        ; $ccb9: fd 34 04  
            bpl __ccc5         ; $ccbc: 10 07     
            ldy #$10           ; $ccbe: a0 10     
            eor #$ff           ; $ccc0: 49 ff     
            clc                ; $ccc2: 18        
            adc #$01           ; $ccc3: 69 01     
__ccc5:     cmp #$0f           ; $ccc5: c9 0f     
            bcc __cccc         ; $ccc7: 90 03     
            tya                ; $ccc9: 98        
            sta $58,x          ; $ccca: 95 58     
__cccc:     rts                ; $cccc: 60        

;-------------------------------------------------------------------------------
__cccd:     brk                ; $cccd: 00        
            ora ($03,x)        ; $ccce: 01 03     
            .hex 04 05         ; $ccd0: 04 05     Invalid Opcode - NOP $05
            asl $07            ; $ccd2: 06 07     
            .hex 07 08         ; $ccd4: 07 08     Invalid Opcode - SLO $08
            brk                ; $ccd6: 00        
            .hex 03 06         ; $ccd7: 03 06     Invalid Opcode - SLO ($06,x)
            ora #$0b           ; $ccd9: 09 0b     
            ora $0f0e          ; $ccdb: 0d 0e 0f  
            bpl __cce0         ; $ccde: 10 00     
__cce0:     .hex 04 09         ; $cce0: 04 09     Invalid Opcode - NOP $09
            ora $1310          ; $cce2: 0d 10 13  
            asl $17,x          ; $cce5: 16 17     
            clc                ; $cce7: 18        
            brk                ; $cce8: 00        
            asl $0c            ; $cce9: 06 0c     
            .hex 12            ; $cceb: 12        Invalid Opcode - KIL 
            asl $1a,x          ; $ccec: 16 1a     
            ora $201f,x        ; $ccee: 1d 1f 20  
            brk                ; $ccf1: 00        
            .hex 07 0f         ; $ccf2: 07 0f     Invalid Opcode - SLO $0f
            asl $1c,x          ; $ccf4: 16 1c     
            and ($25,x)        ; $ccf6: 21 25     
            .hex 27 28         ; $ccf8: 27 28     Invalid Opcode - RLA $28
            brk                ; $ccfa: 00        
            ora #$12           ; $ccfb: 09 12     
            .hex 1b 21 27      ; $ccfd: 1b 21 27  Invalid Opcode - SLO $2721,y
            bit $302f          ; $cd00: 2c 2f 30  
            brk                ; $cd03: 00        
            .hex 0b 15         ; $cd04: 0b 15     Invalid Opcode - ANC #$15
            .hex 1f 27         ; $cd06: 1f 27     Suspected data
__cd08:     rol $3733          ; $cd08: 2e 33 37  
            sec                ; $cd0b: 38        
            brk                ; $cd0c: 00        
            .hex 0c 18 24      ; $cd0d: 0c 18 24  Invalid Opcode - NOP $2418
            and $3b35          ; $cd10: 2d 35 3b  
            .hex 3e 40 00      ; $cd13: 3e 40 00  Bad Addr Mode - ROL $0040,x
            asl $281b          ; $cd16: 0e 1b 28  
            .hex 32            ; $cd19: 32        Invalid Opcode - KIL 
            .hex 3b 42 46      ; $cd1a: 3b 42 46  Invalid Opcode - RLA $4642,y
            pha                ; $cd1d: 48        
            brk                ; $cd1e: 00        
            .hex 0f 1f 2d      ; $cd1f: 0f 1f 2d  Invalid Opcode - SLO $2d1f
            sec                ; $cd22: 38        
            .hex 42            ; $cd23: 42        Invalid Opcode - KIL 
            lsr                ; $cd24: 4a        
            .hex 4e 50 00      ; $cd25: 4e 50 00  Bad Addr Mode - LSR $0050
            ora ($22),y        ; $cd28: 11 22     
            and ($3e),y        ; $cd2a: 31 3e     
            eor #$51           ; $cd2c: 49 51     
            lsr $58,x          ; $cd2e: 56 58     
__cd30:     ora ($03,x)        ; $cd30: 01 03     
            .hex 02            ; $cd32: 02        Invalid Opcode - KIL 
            brk                ; $cd33: 00        
__cd34:     brk                ; $cd34: 00        
            ora #$12           ; $cd35: 09 12     
            .hex 1b 24 2d      ; $cd37: 1b 24 2d  Invalid Opcode - SLO $2d24,y
            rol $3f,x          ; $cd3a: 36 3f     
            pha                ; $cd3c: 48        
            eor ($5a),y        ; $cd3d: 51 5a     
            .hex 63            ; $cd3f: 63        Suspected data
__cd40:     .hex 0c 18         ; $cd40: 0c 18     Suspected data
__cd42:     .hex 20 b6         ; $cd42: 20 b6     Suspected data
__cd44:     sbc ($ad),y        ; $cd44: f1 ad     
            cmp ($03),y        ; $cd46: d1 03     
            and #$08           ; $cd48: 29 08     
            bne __cdc0         ; $cd4a: d0 74     
            lda $0747          ; $cd4c: ad 47 07  
            bne __cd5b         ; $cd4f: d0 0a     
            lda $0388,x        ; $cd51: bd 88 03  
            jsr __d3d8         ; $cd54: 20 d8 d3  
            and #$1f           ; $cd57: 29 1f     
            sta $a0,x          ; $cd59: 95 a0     
__cd5b:     lda $a0,x          ; $cd5b: b5 a0     
            ldy $16,x          ; $cd5d: b4 16     
            cpy #$1f           ; $cd5f: c0 1f     
            bcc __cd70         ; $cd61: 90 0d     
            cmp #$08           ; $cd63: c9 08     
            beq __cd6b         ; $cd65: f0 04     
            cmp #$18           ; $cd67: c9 18     
            bne __cd70         ; $cd69: d0 05     
__cd6b:     clc                ; $cd6b: 18        
            adc #$01           ; $cd6c: 69 01     
            sta $a0,x          ; $cd6e: 95 a0     
__cd70:     sta $ef            ; $cd70: 85 ef     
            jsr __f159         ; $cd72: 20 59 f1  
            jsr __ce94         ; $cd75: 20 94 ce  
            ldy $06e5,x        ; $cd78: bc e5 06  
            lda $03b9          ; $cd7b: ad b9 03  
            sta $0200,y        ; $cd7e: 99 00 02  
            sta $07            ; $cd81: 85 07     
            lda $03ae          ; $cd83: ad ae 03  
            sta $0203,y        ; $cd86: 99 03 02  
            sta $06            ; $cd89: 85 06     
            lda #$01           ; $cd8b: a9 01     
            sta $00            ; $cd8d: 85 00     
            jsr __ce0e         ; $cd8f: 20 0e ce  
            ldy #$05           ; $cd92: a0 05     
            lda $16,x          ; $cd94: b5 16     
            cmp #$1f           ; $cd96: c9 1f     
            bcc __cd9c         ; $cd98: 90 02     
            ldy #$0b           ; $cd9a: a0 0b     
__cd9c:     sty $ed            ; $cd9c: 84 ed     
            lda #$00           ; $cd9e: a9 00     
            sta $00            ; $cda0: 85 00     
__cda2:     lda $ef            ; $cda2: a5 ef     
            jsr __ce94         ; $cda4: 20 94 ce  
            jsr __cdc1         ; $cda7: 20 c1 cd  
            lda $00            ; $cdaa: a5 00     
            cmp #$04           ; $cdac: c9 04     
            bne __cdb8         ; $cdae: d0 08     
            ldy $06cf          ; $cdb0: ac cf 06  
            lda $06e5,y        ; $cdb3: b9 e5 06  
            sta $06            ; $cdb6: 85 06     
__cdb8:     inc $00            ; $cdb8: e6 00     
            lda $00            ; $cdba: a5 00     
            cmp $ed            ; $cdbc: c5 ed     
            bcc __cda2         ; $cdbe: 90 e2     
__cdc0:     rts                ; $cdc0: 60        

;-------------------------------------------------------------------------------
__cdc1:     lda $03            ; $cdc1: a5 03     
            .hex 85            ; $cdc3: 85        Suspected data
__cdc4:     ora $a4            ; $cdc4: 05 a4     
            asl $a5            ; $cdc6: 06 a5     
            ora ($46,x)        ; $cdc8: 01 46     
            .hex 05            ; $cdca: 05        Suspected data
__cdcb:     bcs __cdd1         ; $cdcb: b0 04     
            eor #$ff           ; $cdcd: 49 ff     
            adc #$01           ; $cdcf: 69 01     
__cdd1:     clc                ; $cdd1: 18        
            adc $03ae          ; $cdd2: 6d ae 03  
            sta $0203,y        ; $cdd5: 99 03 02  
            sta $06            ; $cdd8: 85 06     
            cmp $03ae          ; $cdda: cd ae 03  
            bcs __cde8         ; $cddd: b0 09     
            lda $03ae          ; $cddf: ad ae 03  
            sec                ; $cde2: 38        
            sbc $06            ; $cde3: e5 06     
            jmp __cdec         ; $cde5: 4c ec cd  

;-------------------------------------------------------------------------------
__cde8:     sec                ; $cde8: 38        
            sbc $03ae          ; $cde9: ed ae 03  
__cdec:     cmp #$59           ; $cdec: c9 59     
            bcc __cdf4         ; $cdee: 90 04     
            lda #$f8           ; $cdf0: a9 f8     
            bne __ce09         ; $cdf2: d0 15     
__cdf4:     lda $03b9          ; $cdf4: ad b9 03  
            cmp #$f8           ; $cdf7: c9 f8     
            beq __ce09         ; $cdf9: f0 0e     
            lda $02            ; $cdfb: a5 02     
            lsr $05            ; $cdfd: 46 05     
            bcs __ce05         ; $cdff: b0 04     
            eor #$ff           ; $ce01: 49 ff     
            adc #$01           ; $ce03: 69 01     
__ce05:     clc                ; $ce05: 18        
            adc $03b9          ; $ce06: 6d b9 03  
__ce09:     .hex 99 00         ; $ce09: 99 00     Suspected data
__ce0b:     .hex 02            ; $ce0b: 02        Invalid Opcode - KIL 
            sta $07            ; $ce0c: 85 07     
__ce0e:     jsr __ecf4         ; $ce0e: 20 f4 ec  
            tya                ; $ce11: 98        
            pha                ; $ce12: 48        
            lda $079f          ; $ce13: ad 9f 07  
            ora $0747          ; $ce16: 0d 47 07  
            bne __ce8b         ; $ce19: d0 70     
            sta $05            ; $ce1b: 85 05     
            ldy $b5            ; $ce1d: a4 b5     
            dey                ; $ce1f: 88        
            bne __ce8b         ; $ce20: d0 69     
            ldy $ce            ; $ce22: a4 ce     
            lda $0754          ; $ce24: ad 54 07  
            bne __ce2e         ; $ce27: d0 05     
            lda $0714          ; $ce29: ad 14 07  
            beq __ce37         ; $ce2c: f0 09     
__ce2e:     inc $05            ; $ce2e: e6 05     
            inc $05            ; $ce30: e6 05     
            tya                ; $ce32: 98        
            clc                ; $ce33: 18        
            adc #$18           ; $ce34: 69 18     
            tay                ; $ce36: a8        
__ce37:     tya                ; $ce37: 98        
__ce38:     sec                ; $ce38: 38        
            sbc $07            ; $ce39: e5 07     
            bpl __ce42         ; $ce3b: 10 05     
            eor #$ff           ; $ce3d: 49 ff     
            clc                ; $ce3f: 18        
            adc #$01           ; $ce40: 69 01     
__ce42:     .hex c9            ; $ce42: c9        Suspected data
__ce43:     php                ; $ce43: 08        
            bcs __ce62         ; $ce44: b0 1c     
            lda $06            ; $ce46: a5 06     
            cmp #$f0           ; $ce48: c9 f0     
            .hex b0            ; $ce4a: b0        Suspected data
__ce4b:     asl $ad,x          ; $ce4b: 16 ad     
            .hex 07 02         ; $ce4d: 07 02     Invalid Opcode - SLO $02
            clc                ; $ce4f: 18        
            adc #$04           ; $ce50: 69 04     
            sta $04            ; $ce52: 85 04     
            sec                ; $ce54: 38        
            sbc $06            ; $ce55: e5 06     
            bpl __ce5e         ; $ce57: 10 05     
            eor #$ff           ; $ce59: 49 ff     
            clc                ; $ce5b: 18        
            adc #$01           ; $ce5c: 69 01     
__ce5e:     cmp #$08           ; $ce5e: c9 08     
            bcc __ce75         ; $ce60: 90 13     
__ce62:     lda $05            ; $ce62: a5 05     
            cmp #$02           ; $ce64: c9 02     
            beq __ce8b         ; $ce66: f0 23     
            ldy $05            ; $ce68: a4 05     
            lda $ce            ; $ce6a: a5 ce     
            clc                ; $ce6c: 18        
            adc __cd40,y       ; $ce6d: 79 40 cd  
            inc $05            ; $ce70: e6 05     
            jmp __ce38         ; $ce72: 4c 38 ce  

;-------------------------------------------------------------------------------
__ce75:     ldx #$01           ; $ce75: a2 01     
            lda $04            ; $ce77: a5 04     
            cmp $06            ; $ce79: c5 06     
            bcs __ce7e         ; $ce7b: b0 01     
            inx                ; $ce7d: e8        
__ce7e:     stx $46            ; $ce7e: 86 46     
            ldx #$00           ; $ce80: a2 00     
            lda $00            ; $ce82: a5 00     
            pha                ; $ce84: 48        
            jsr __d92d         ; $ce85: 20 2d d9  
            pla                ; $ce88: 68        
            sta $00            ; $ce89: 85 00     
__ce8b:     pla                ; $ce8b: 68        
            clc                ; $ce8c: 18        
            adc #$04           ; $ce8d: 69 04     
            sta $06            ; $ce8f: 85 06     
            ldx $08            ; $ce91: a6 08     
            rts                ; $ce93: 60        

;-------------------------------------------------------------------------------
__ce94:     pha                ; $ce94: 48        
            and #$0f           ; $ce95: 29 0f     
            cmp #$09           ; $ce97: c9 09     
            bcc __cea0         ; $ce99: 90 05     
            eor #$0f           ; $ce9b: 49 0f     
            clc                ; $ce9d: 18        
            adc #$01           ; $ce9e: 69 01     
__cea0:     sta $01            ; $cea0: 85 01     
            ldy $00            ; $cea2: a4 00     
            lda __cd34,y       ; $cea4: b9 34 cd  
            clc                ; $cea7: 18        
            adc $01            ; $cea8: 65 01     
            tay                ; $ceaa: a8        
            lda __cccd,y       ; $ceab: b9 cd cc  
            sta $01            ; $ceae: 85 01     
            pla                ; $ceb0: 68        
            pha                ; $ceb1: 48        
            clc                ; $ceb2: 18        
            adc #$08           ; $ceb3: 69 08     
            and #$0f           ; $ceb5: 29 0f     
            cmp #$09           ; $ceb7: c9 09     
            bcc __cec0         ; $ceb9: 90 05     
            eor #$0f           ; $cebb: 49 0f     
            clc                ; $cebd: 18        
            adc #$01           ; $cebe: 69 01     
__cec0:     sta $02            ; $cec0: 85 02     
            ldy $00            ; $cec2: a4 00     
            lda __cd34,y       ; $cec4: b9 34 cd  
            clc                ; $cec7: 18        
            adc $02            ; $cec8: 65 02     
            tay                ; $ceca: a8        
            .hex b9 cd         ; $cecb: b9 cd     Suspected data
__cecd:     cpy $0285          ; $cecd: cc 85 02  
            pla                ; $ced0: 68        
            lsr                ; $ced1: 4a        
            lsr                ; $ced2: 4a        
            lsr                ; $ced3: 4a        
            tay                ; $ced4: a8        
            lda __cd30,y       ; $ced5: b9 30 cd  
            sta $03            ; $ced8: 85 03     
            rts                ; $ceda: 60        

;-------------------------------------------------------------------------------
            ldy #$20           ; $cedb: a0 20     
            lda $1e,x          ; $cedd: b5 1e     
            and #$20           ; $cedf: 29 20     
            bne __cee8         ; $cee1: d0 05     
            jsr __bf07         ; $cee3: 20 07 bf  
            ldy #$17           ; $cee6: a0 17     
__cee8:     lda #$05           ; $cee8: a9 05     
            jmp __bf9b         ; $ceea: 4c 9b bf  

;-------------------------------------------------------------------------------
__ceed:     ora $30,x          ; $ceed: 15 30     
            rti                ; $ceef: 40        

;-------------------------------------------------------------------------------
            lda $1e,x          ; $cef0: b5 1e     
            and #$20           ; $cef2: 29 20     
            beq __cef9         ; $cef4: f0 03     
            jmp __bf68         ; $cef6: 4c 68 bf  

;-------------------------------------------------------------------------------
__cef9:     lda $1e,x          ; $cef9: b5 1e     
            beq __cf08         ; $cefb: f0 0b     
            lda #$00           ; $cefd: a9 00     
            sta $a0,x          ; $ceff: 95 a0     
            sta $06cb          ; $cf01: 8d cb 06  
            lda #$10           ; $cf04: a9 10     
            bne __cf1b         ; $cf06: d0 13     
__cf08:     lda #$12           ; $cf08: a9 12     
            sta $06cb          ; $cf0a: 8d cb 06  
            ldy #$02           ; $cf0d: a0 02     
__cf0f:     lda __ceed,y       ; $cf0f: b9 ed ce  
            sta $0001,y        ; $cf12: 99 01 00  
            dey                ; $cf15: 88        
            bpl __cf0f         ; $cf16: 10 f7     
            jsr __cf34         ; $cf18: 20 34 cf  
__cf1b:     sta $58,x          ; $cf1b: 95 58     
            ldy #$01           ; $cf1d: a0 01     
            lda $a0,x          ; $cf1f: b5 a0     
            and #$01           ; $cf21: 29 01     
            bne __cf2f         ; $cf23: d0 0a     
            lda $58,x          ; $cf25: b5 58     
            eor #$ff           ; $cf27: 49 ff     
            clc                ; $cf29: 18        
            adc #$01           ; $cf2a: 69 01     
            sta $58,x          ; $cf2c: 95 58     
            iny                ; $cf2e: c8        
__cf2f:     sty $46,x          ; $cf2f: 94 46     
            jmp __bf07         ; $cf31: 4c 07 bf  

;-------------------------------------------------------------------------------
__cf34:     ldy #$00           ; $cf34: a0 00     
            jsr __e14b         ; $cf36: 20 4b e1  
            bpl __cf45         ; $cf39: 10 0a     
__cf3b:     iny                ; $cf3b: c8        
            lda $00            ; $cf3c: a5 00     
            eor #$ff           ; $cf3e: 49 ff     
            clc                ; $cf40: 18        
            adc #$01           ; $cf41: 69 01     
            sta $00            ; $cf43: 85 00     
__cf45:     lda $00            ; $cf45: a5 00     
            cmp #$3c           ; $cf47: c9 3c     
            bcc __cf67         ; $cf49: 90 1c     
            lda #$3c           ; $cf4b: a9 3c     
            sta $00            ; $cf4d: 85 00     
            lda $16,x          ; $cf4f: b5 16     
            cmp #$11           ; $cf51: c9 11     
            bne __cf67         ; $cf53: d0 12     
            tya                ; $cf55: 98        
            cmp $a0,x          ; $cf56: d5 a0     
            beq __cf67         ; $cf58: f0 0d     
            lda $a0,x          ; $cf5a: b5 a0     
            beq __cf64         ; $cf5c: f0 06     
            dec $58,x          ; $cf5e: d6 58     
            lda $58,x          ; $cf60: b5 58     
            bne __cfa4         ; $cf62: d0 40     
__cf64:     tya                ; $cf64: 98        
            sta $a0,x          ; $cf65: 95 a0     
__cf67:     lda $00            ; $cf67: a5 00     
            and #$3c           ; $cf69: 29 3c     
            lsr                ; $cf6b: 4a        
            lsr                ; $cf6c: 4a        
            sta $00            ; $cf6d: 85 00     
            ldy #$00           ; $cf6f: a0 00     
            lda $57            ; $cf71: a5 57     
            beq __cf99         ; $cf73: f0 24     
            lda $0775          ; $cf75: ad 75 07  
            beq __cf99         ; $cf78: f0 1f     
            iny                ; $cf7a: c8        
            lda $57            ; $cf7b: a5 57     
            cmp #$1d           ; $cf7d: c9 1d     
            bcc __cf89         ; $cf7f: 90 08     
            lda $0775          ; $cf81: ad 75 07  
            cmp #$02           ; $cf84: c9 02     
            bcc __cf89         ; $cf86: 90 01     
            iny                ; $cf88: c8        
__cf89:     lda $16,x          ; $cf89: b5 16     
            cmp #$12           ; $cf8b: c9 12     
            bne __cf93         ; $cf8d: d0 04     
            lda $57            ; $cf8f: a5 57     
            bne __cf99         ; $cf91: d0 06     
__cf93:     lda $a0,x          ; $cf93: b5 a0     
            bne __cf99         ; $cf95: d0 02     
            ldy #$00           ; $cf97: a0 00     
__cf99:     lda $0001,y        ; $cf99: b9 01 00  
            ldy $00            ; $cf9c: a4 00     
__cf9e:     sec                ; $cf9e: 38        
            sbc #$01           ; $cf9f: e9 01     
            dey                ; $cfa1: 88        
            bpl __cf9e         ; $cfa2: 10 fa     
__cfa4:     rts                ; $cfa4: 60        

;-------------------------------------------------------------------------------
__cfa5:     .hex 1a            ; $cfa5: 1a        Invalid Opcode - NOP 
            cli                ; $cfa6: 58        
            tya                ; $cfa7: 98        
            stx $94,y          ; $cfa8: 96 94     
            .hex 92            ; $cfaa: 92        Invalid Opcode - KIL 
            bcc __cf3b         ; $cfab: 90 8e     
            sty __888a         ; $cfad: 8c 8a 88  
            stx $84            ; $cfb0: 86 84     
            .hex 82 80         ; $cfb2: 82 80     Invalid Opcode - NOP #$80
            ldx $0368          ; $cfb4: ae 68 03  
            lda $16,x          ; $cfb7: b5 16     
            cmp #$2d           ; $cfb9: c9 2d     
            bne __cfcd         ; $cfbb: d0 10     
            stx $08            ; $cfbd: 86 08     
            lda $1e,x          ; $cfbf: b5 1e     
__cfc1:     beq __cfdd         ; $cfc1: f0 1a     
            and #$40           ; $cfc3: 29 40     
            beq __cfcd         ; $cfc5: f0 06     
            lda $cf,x          ; $cfc7: b5 cf     
            cmp #$e0           ; $cfc9: c9 e0     
            bcc __cfd7         ; $cfcb: 90 0a     
__cfcd:     lda #$80           ; $cfcd: a9 80     
__cfcf:     sta $fc            ; $cfcf: 85 fc     
            inc $0772          ; $cfd1: ee 72 07  
            jmp __d039         ; $cfd4: 4c 39 d0  

;-------------------------------------------------------------------------------
__cfd7:     jsr __bf91         ; $cfd7: 20 91 bf  
            jmp __d143         ; $cfda: 4c 43 d1  

;-------------------------------------------------------------------------------
__cfdd:     dec $0364          ; $cfdd: ce 64 03  
            bne __d026         ; $cfe0: d0 44     
            lda #$04           ; $cfe2: a9 04     
            sta $0364          ; $cfe4: 8d 64 03  
            lda $0363          ; $cfe7: ad 63 03  
            eor #$01           ; $cfea: 49 01     
            sta $0363          ; $cfec: 8d 63 03  
            lda #$22           ; $cfef: a9 22     
            sta $05            ; $cff1: 85 05     
            ldy $0369          ; $cff3: ac 69 03  
            lda __cfa5,y       ; $cff6: b9 a5 cf  
            sta $04            ; $cff9: 85 04     
            ldy $0300          ; $cffb: ac 00 03  
            iny                ; $cffe: c8        
            ldx #$0c           ; $cfff: a2 0c     
            jsr __8acd         ; $d001: 20 cd 8a  
            ldx $08            ; $d004: a6 08     
            jsr __8a8f         ; $d006: 20 8f 8a  
            lda #$08           ; $d009: a9 08     
            sta $fe            ; $d00b: 85 fe     
            lda #$01           ; $d00d: a9 01     
            sta $fd            ; $d00f: 85 fd     
            inc $0369          ; $d011: ee 69 03  
            lda $0369          ; $d014: ad 69 03  
            cmp #$0f           ; $d017: c9 0f     
            bne __d026         ; $d019: d0 0b     
            jsr __c369         ; $d01b: 20 69 c3  
            lda #$40           ; $d01e: a9 40     
            .hex 95            ; $d020: 95        Suspected data
__d021:     asl __80a9,x       ; $d021: 1e a9 80  
            sta $fe            ; $d024: 85 fe     
__d026:     jmp __d143         ; $d026: 4c 43 d1  

;-------------------------------------------------------------------------------
__d029:     and ($41,x)        ; $d029: 21 41     
            ora ($31),y        ; $d02b: 11 31     
            lda $1e,x          ; $d02d: b5 1e     
            and #$20           ; $d02f: 29 20     
            beq __d047         ; $d031: f0 14     
            lda $cf,x          ; $d033: b5 cf     
            cmp #$e0           ; $d035: c9 e0     
            bcc __cfd7         ; $d037: 90 9e     
__d039:     ldx #$04           ; $d039: a2 04     
__d03b:     jsr __c99e         ; $d03b: 20 9e c9  
            dex                ; $d03e: ca        
            bpl __d03b         ; $d03f: 10 fa     
            sta $06cb          ; $d041: 8d cb 06  
            ldx $08            ; $d044: a6 08     
            rts                ; $d046: 60        

;-------------------------------------------------------------------------------
__d047:     lda #$00           ; $d047: a9 00     
            sta $06cb          ; $d049: 8d cb 06  
            lda $0747          ; $d04c: ad 47 07  
            beq __d054         ; $d04f: f0 03     
            jmp __d101         ; $d051: 4c 01 d1  

;-------------------------------------------------------------------------------
__d054:     lda $0363          ; $d054: ad 63 03  
            bpl __d05c         ; $d057: 10 03     
            jmp __d0d7         ; $d059: 4c d7 d0  

;-------------------------------------------------------------------------------
__d05c:     dec $0364          ; $d05c: ce 64 03  
            bne __d06e         ; $d05f: d0 0d     
            lda #$20           ; $d061: a9 20     
            sta $0364          ; $d063: 8d 64 03  
            lda $0363          ; $d066: ad 63 03  
            eor #$01           ; $d069: 49 01     
            sta $0363          ; $d06b: 8d 63 03  
__d06e:     lda $09            ; $d06e: a5 09     
            and #$0f           ; $d070: 29 0f     
            bne __d078         ; $d072: d0 04     
            lda #$02           ; $d074: a9 02     
            sta $46,x          ; $d076: 95 46     
__d078:     lda $078a,x        ; $d078: bd 8a 07  
            beq __d099         ; $d07b: f0 1c     
            jsr __e14b         ; $d07d: 20 4b e1  
            bpl __d099         ; $d080: 10 17     
            lda #$01           ; $d082: a9 01     
            sta $46,x          ; $d084: 95 46     
            lda #$02           ; $d086: a9 02     
            sta $0365          ; $d088: 8d 65 03  
            lda #$20           ; $d08b: a9 20     
            sta $078a,x        ; $d08d: 9d 8a 07  
            sta $0790          ; $d090: 8d 90 07  
            lda $87,x          ; $d093: b5 87     
            cmp #$c8           ; $d095: c9 c8     
            bcs __d0d7         ; $d097: b0 3e     
__d099:     lda $09            ; $d099: a5 09     
            and #$03           ; $d09b: 29 03     
            bne __d0d7         ; $d09d: d0 38     
            lda $87,x          ; $d09f: b5 87     
            cmp $0366          ; $d0a1: cd 66 03  
            bne __d0b2         ; $d0a4: d0 0c     
            lda $07a7,x        ; $d0a6: bd a7 07  
            and #$03           ; $d0a9: 29 03     
            tay                ; $d0ab: a8        
            lda __d029,y       ; $d0ac: b9 29 d0  
            sta $06dc          ; $d0af: 8d dc 06  
__d0b2:     lda $87,x          ; $d0b2: b5 87     
            clc                ; $d0b4: 18        
            adc $0365          ; $d0b5: 6d 65 03  
            sta $87,x          ; $d0b8: 95 87     
            ldy $46,x          ; $d0ba: b4 46     
            cpy #$01           ; $d0bc: c0 01     
            beq __d0d7         ; $d0be: f0 17     
            ldy #$ff           ; $d0c0: a0 ff     
            sec                ; $d0c2: 38        
            sbc $0366          ; $d0c3: ed 66 03  
            bpl __d0cf         ; $d0c6: 10 07     
            eor #$ff           ; $d0c8: 49 ff     
            clc                ; $d0ca: 18        
            adc #$01           ; $d0cb: 69 01     
            ldy #$01           ; $d0cd: a0 01     
__d0cf:     cmp $06dc          ; $d0cf: cd dc 06  
            bcc __d0d7         ; $d0d2: 90 03     
            sty $0365          ; $d0d4: 8c 65 03  
__d0d7:     lda $078a,x        ; $d0d7: bd 8a 07  
            bne __d104         ; $d0da: d0 28     
            jsr __bf91         ; $d0dc: 20 91 bf  
            lda $075f          ; $d0df: ad 5f 07  
            cmp #$05           ; $d0e2: c9 05     
            bcc __d0ef         ; $d0e4: 90 09     
            lda $09            ; $d0e6: a5 09     
            and #$03           ; $d0e8: 29 03     
            bne __d0ef         ; $d0ea: d0 03     
            jsr __ba99         ; $d0ec: 20 99 ba  
__d0ef:     lda $cf,x          ; $d0ef: b5 cf     
            cmp #$80           ; $d0f1: c9 80     
            bcc __d111         ; $d0f3: 90 1c     
            lda $07a7,x        ; $d0f5: bd a7 07  
            and #$03           ; $d0f8: 29 03     
            tay                ; $d0fa: a8        
            lda __d029,y       ; $d0fb: b9 29 d0  
            .hex 9d 8a         ; $d0fe: 9d 8a     Suspected data
__d100:     .hex 07            ; $d100: 07        Suspected data
__d101:     jmp __d111         ; $d101: 4c 11 d1  

;-------------------------------------------------------------------------------
__d104:     cmp #$01           ; $d104: c9 01     
            bne __d111         ; $d106: d0 09     
            dec $cf,x          ; $d108: d6 cf     
            jsr __c369         ; $d10a: 20 69 c3  
            lda #$fe           ; $d10d: a9 fe     
            sta $a0,x          ; $d10f: 95 a0     
__d111:     lda $075f          ; $d111: ad 5f 07  
            cmp #$07           ; $d114: c9 07     
            beq __d11c         ; $d116: f0 04     
            cmp #$05           ; $d118: c9 05     
            bcs __d143         ; $d11a: b0 27     
__d11c:     .hex ad            ; $d11c: ad        Suspected data
__d11d:     bcc __d126         ; $d11d: 90 07     
            bne __d143         ; $d11f: d0 22     
            lda #$20           ; $d121: a9 20     
            sta $0790          ; $d123: 8d 90 07  
__d126:     lda $0363          ; $d126: ad 63 03  
            eor #$80           ; $d129: 49 80     
            sta $0363          ; $d12b: 8d 63 03  
            bmi __d111         ; $d12e: 30 e1     
            jsr __d1a1         ; $d130: 20 a1 d1  
            ldy $06cc          ; $d133: ac cc 06  
            beq __d13b         ; $d136: f0 03     
            sec                ; $d138: 38        
            sbc #$10           ; $d139: e9 10     
__d13b:     sta $0790          ; $d13b: 8d 90 07  
            lda #$15           ; $d13e: a9 15     
            sta $06cb          ; $d140: 8d cb 06  
__d143:     jsr __d184         ; $d143: 20 84 d1  
            ldy #$10           ; $d146: a0 10     
            lda $46,x          ; $d148: b5 46     
            lsr                ; $d14a: 4a        
            bcc __d14f         ; $d14b: 90 02     
            ldy #$f0           ; $d14d: a0 f0     
__d14f:     tya                ; $d14f: 98        
            clc                ; $d150: 18        
            adc $87,x          ; $d151: 75 87     
            ldy $06cf          ; $d153: ac cf 06  
            sta $0087,y        ; $d156: 99 87 00  
            lda $cf,x          ; $d159: b5 cf     
            clc                ; $d15b: 18        
            adc #$08           ; $d15c: 69 08     
            sta $00cf,y        ; $d15e: 99 cf 00  
            lda $1e,x          ; $d161: b5 1e     
            sta $001e,y        ; $d163: 99 1e 00  
            lda $46,x          ; $d166: b5 46     
            sta $0046,y        ; $d168: 99 46 00  
            lda $08            ; $d16b: a5 08     
            pha                ; $d16d: 48        
            ldx $06cf          ; $d16e: ae cf 06  
            stx $08            ; $d171: 86 08     
            lda #$2d           ; $d173: a9 2d     
            sta $16,x          ; $d175: 95 16     
            jsr __d184         ; $d177: 20 84 d1  
            pla                ; $d17a: 68        
            .hex 85            ; $d17b: 85        Suspected data
__d17c:     php                ; $d17c: 08        
            tax                ; $d17d: aa        
            lda #$00           ; $d17e: a9 00     
            sta $036a          ; $d180: 8d 6a 03  
__d183:     rts                ; $d183: 60        

;-------------------------------------------------------------------------------
__d184:     inc $036a          ; $d184: ee 6a 03  
            jsr __c8dd         ; $d187: 20 dd c8  
            lda $1e,x          ; $d18a: b5 1e     
            bne __d183         ; $d18c: d0 f5     
            lda #$0a           ; $d18e: a9 0a     
            sta $049a,x        ; $d190: 9d 9a 04  
            jsr __e24b         ; $d193: 20 4b e2  
            jmp __d853         ; $d196: 4c 53 d8  

;-------------------------------------------------------------------------------
__d199:     .hex 80 30         ; $d199: 80 30     Invalid Opcode - NOP #$30
            bmi __d11d         ; $d19b: 30 80     
            .hex 80 80         ; $d19d: 80 80     Invalid Opcode - NOP #$80
            bmi __d1f1         ; $d19f: 30 50     
__d1a1:     ldy $0367          ; $d1a1: ac 67 03  
            inc $0367          ; $d1a4: ee 67 03  
            lda $0367          ; $d1a7: ad 67 03  
            and #$07           ; $d1aa: 29 07     
            sta $0367          ; $d1ac: 8d 67 03  
            lda __d199,y       ; $d1af: b9 99 d1  
__d1b2:     rts                ; $d1b2: 60        

;-------------------------------------------------------------------------------
__d1b3:     lda $0747          ; $d1b3: ad 47 07  
            bne __d1e8         ; $d1b6: d0 30     
            lda #$70           ; $d1b8: a9 70     
            ldy $06cc          ; $d1ba: ac cc 06  
            beq __d1c1         ; $d1bd: f0 02     
            lda #$90           ; $d1bf: a9 90     
__d1c1:     sta $00            ; $d1c1: 85 00     
            lda $0401,x        ; $d1c3: bd 01 04  
            sec                ; $d1c6: 38        
            sbc $00            ; $d1c7: e5 00     
            sta $0401,x        ; $d1c9: 9d 01 04  
            lda $87,x          ; $d1cc: b5 87     
            sbc #$01           ; $d1ce: e9 01     
            sta $87,x          ; $d1d0: 95 87     
            lda $6e,x          ; $d1d2: b5 6e     
            sbc #$00           ; $d1d4: e9 00     
            sta $6e,x          ; $d1d6: 95 6e     
            ldy $0417,x        ; $d1d8: bc 17 04  
            lda $cf,x          ; $d1db: b5 cf     
            cmp __c5a3,y       ; $d1dd: d9 a3 c5  
            beq __d1e8         ; $d1e0: f0 06     
            clc                ; $d1e2: 18        
            adc $0434,x        ; $d1e3: 7d 34 04  
            sta $cf,x          ; $d1e6: 95 cf     
__d1e8:     jsr __f159         ; $d1e8: 20 59 f1  
            lda $1e,x          ; $d1eb: b5 1e     
            bne __d1b2         ; $d1ed: d0 c3     
            lda #$51           ; $d1ef: a9 51     
__d1f1:     sta $00            ; $d1f1: 85 00     
            ldy #$02           ; $d1f3: a0 02     
            lda $09            ; $d1f5: a5 09     
            and #$02           ; $d1f7: 29 02     
            beq __d1fd         ; $d1f9: f0 02     
            ldy #$82           ; $d1fb: a0 82     
__d1fd:     sty $01            ; $d1fd: 84 01     
            ldy $06e5,x        ; $d1ff: bc e5 06  
            ldx #$00           ; $d202: a2 00     
__d204:     lda $03b9          ; $d204: ad b9 03  
            sta $0200,y        ; $d207: 99 00 02  
            lda $00            ; $d20a: a5 00     
            sta $0201,y        ; $d20c: 99 01 02  
            inc $00            ; $d20f: e6 00     
            lda $01            ; $d211: a5 01     
            sta $0202,y        ; $d213: 99 02 02  
            lda $03ae          ; $d216: ad ae 03  
            sta $0203,y        ; $d219: 99 03 02  
            clc                ; $d21c: 18        
            adc #$08           ; $d21d: 69 08     
            sta $03ae          ; $d21f: 8d ae 03  
            iny                ; $d222: c8        
            iny                ; $d223: c8        
            iny                ; $d224: c8        
            iny                ; $d225: c8        
            inx                ; $d226: e8        
            cpx #$03           ; $d227: e0 03     
            bcc __d204         ; $d229: 90 d9     
            ldx $08            ; $d22b: a6 08     
            jsr __f1b6         ; $d22d: 20 b6 f1  
            ldy $06e5,x        ; $d230: bc e5 06  
            lda $03d1          ; $d233: ad d1 03  
            lsr                ; $d236: 4a        
            pha                ; $d237: 48        
            bcc __d23f         ; $d238: 90 05     
            lda #$f8           ; $d23a: a9 f8     
            sta $020c,y        ; $d23c: 99 0c 02  
__d23f:     pla                ; $d23f: 68        
            lsr                ; $d240: 4a        
            pha                ; $d241: 48        
            bcc __d249         ; $d242: 90 05     
            lda #$f8           ; $d244: a9 f8     
            sta $0208,y        ; $d246: 99 08 02  
__d249:     pla                ; $d249: 68        
            lsr                ; $d24a: 4a        
            pha                ; $d24b: 48        
            bcc __d253         ; $d24c: 90 05     
            lda #$f8           ; $d24e: a9 f8     
            sta $0204,y        ; $d250: 99 04 02  
__d253:     pla                ; $d253: 68        
            lsr                ; $d254: 4a        
            bcc __d25c         ; $d255: 90 05     
            lda #$f8           ; $d257: a9 f8     
            sta $0200,y        ; $d259: 99 00 02  
__d25c:     rts                ; $d25c: 60        

;-------------------------------------------------------------------------------
            dec $a0,x          ; $d25d: d6 a0     
            bne __d26d         ; $d25f: d0 0c     
            lda #$08           ; $d261: a9 08     
            sta $a0,x          ; $d263: 95 a0     
            inc $58,x          ; $d265: f6 58     
            lda $58,x          ; $d267: b5 58     
            cmp #$03           ; $d269: c9 03     
            bcs __d285         ; $d26b: b0 18     
__d26d:     jsr __f159         ; $d26d: 20 59 f1  
            lda $03b9          ; $d270: ad b9 03  
            sta $03ba          ; $d273: 8d ba 03  
            lda $03ae          ; $d276: ad ae 03  
            sta $03af          ; $d279: 8d af 03  
            ldy $06e5,x        ; $d27c: bc e5 06  
            lda $58,x          ; $d27f: b5 58     
            jsr __ed1e         ; $d281: 20 1e ed  
            rts                ; $d284: 60        

;-------------------------------------------------------------------------------
__d285:     lda #$00           ; $d285: a9 00     
            sta $0f,x          ; $d287: 95 0f     
            lda #$08           ; $d289: a9 08     
            sta $fe            ; $d28b: 85 fe     
            lda #$05           ; $d28d: a9 05     
            sta $0138          ; $d28f: 8d 38 01  
            jmp __d2fe         ; $d292: 4c fe d2  

;-------------------------------------------------------------------------------
__d295:     brk                ; $d295: 00        
            brk                ; $d296: 00        
            php                ; $d297: 08        
            php                ; $d298: 08        
__d299:     brk                ; $d299: 00        
            php                ; $d29a: 08        
            brk                ; $d29b: 00        
            php                ; $d29c: 08        
__d29d:     .hex 54 55         ; $d29d: 54 55     Invalid Opcode - NOP $55,x
            lsr $57,x          ; $d29f: 56 57     
            lda #$00           ; $d2a1: a9 00     
            sta $06cb          ; $d2a3: 8d cb 06  
            lda $0746          ; $d2a6: ad 46 07  
            cmp #$05           ; $d2a9: c9 05     
            bcs __d2d9         ; $d2ab: b0 2c     
            jsr __8e04         ; $d2ad: 20 04 8e  
            cmp __bad2,y       ; $d2b0: d9 d2 ba  
            .hex d2            ; $d2b3: d2        Invalid Opcode - KIL 
            .hex da            ; $d2b4: da        Invalid Opcode - NOP 
            .hex d2            ; $d2b5: d2        Invalid Opcode - KIL 
            asl $d3,x          ; $d2b6: 16 d3     
            ror                ; $d2b8: 6a        
            .hex d3 a0         ; $d2b9: d3 a0     Invalid Opcode - DCP ($a0),y
            ora $ad            ; $d2bb: 05 ad     
            .hex fa            ; $d2bd: fa        Invalid Opcode - NOP 
            .hex 07 c9         ; $d2be: 07 c9     Invalid Opcode - SLO $c9
            ora ($f0,x)        ; $d2c0: 01 f0     
            asl $03a0          ; $d2c2: 0e a0 03  
            cmp #$03           ; $d2c5: c9 03     
            beq __d2d1         ; $d2c7: f0 08     
            ldy #$00           ; $d2c9: a0 00     
            cmp #$06           ; $d2cb: c9 06     
            beq __d2d1         ; $d2cd: f0 02     
            lda #$ff           ; $d2cf: a9 ff     
__d2d1:     .hex 8d d7         ; $d2d1: 8d d7     Suspected data
__d2d3:     asl $94            ; $d2d3: 06 94     
            .hex 1e            ; $d2d5: 1e        Suspected data
__d2d6:     inc $0746          ; $d2d6: ee 46 07  
__d2d9:     rts                ; $d2d9: 60        

;-------------------------------------------------------------------------------
            lda $07f8          ; $d2da: ad f8 07  
            ora $07f9          ; $d2dd: 0d f9 07  
            ora $07fa          ; $d2e0: 0d fa 07  
            beq __d2d6         ; $d2e3: f0 f1     
            lda $09            ; $d2e5: a5 09     
            and #$04           ; $d2e7: 29 04     
            beq __d2ef         ; $d2e9: f0 04     
            lda #$10           ; $d2eb: a9 10     
            sta $fe            ; $d2ed: 85 fe     
__d2ef:     ldy #$23           ; $d2ef: a0 23     
            lda #$ff           ; $d2f1: a9 ff     
            sta $0139          ; $d2f3: 8d 39 01  
            jsr __8f5f         ; $d2f6: 20 5f 8f  
            lda #$05           ; $d2f9: a9 05     
            sta $0139          ; $d2fb: 8d 39 01  
__d2fe:     ldy #$0b           ; $d2fe: a0 0b     
__d300:     lda $0753          ; $d300: ad 53 07  
            beq __d307         ; $d303: f0 02     
            ldy #$11           ; $d305: a0 11     
__d307:     jsr __8f5f         ; $d307: 20 5f 8f  
            lda $0753          ; $d30a: ad 53 07  
            asl                ; $d30d: 0a        
            asl                ; $d30e: 0a        
            asl                ; $d30f: 0a        
            asl                ; $d310: 0a        
            ora #$04           ; $d311: 09 04     
            jmp __bc3b         ; $d313: 4c 3b bc  

;-------------------------------------------------------------------------------
            lda $cf,x          ; $d316: b5 cf     
            cmp #$72           ; $d318: c9 72     
            bcc __d321         ; $d31a: 90 05     
            dec $cf,x          ; $d31c: d6 cf     
            jmp __d32d         ; $d31e: 4c 2d d3  

;-------------------------------------------------------------------------------
__d321:     lda $06d7          ; $d321: ad d7 06  
            beq __d35e         ; $d324: f0 38     
            bmi __d35e         ; $d326: 30 36     
            lda #$16           ; $d328: a9 16     
            sta $06cb          ; $d32a: 8d cb 06  
__d32d:     jsr __f159         ; $d32d: 20 59 f1  
            ldy $06e5,x        ; $d330: bc e5 06  
            ldx #$03           ; $d333: a2 03     
__d335:     lda $03b9          ; $d335: ad b9 03  
            clc                ; $d338: 18        
            adc __d295,x       ; $d339: 7d 95 d2  
            sta $0200,y        ; $d33c: 99 00 02  
            lda __d29d,x       ; $d33f: bd 9d d2  
            sta $0201,y        ; $d342: 99 01 02  
            lda #$22           ; $d345: a9 22     
            sta $0202,y        ; $d347: 99 02 02  
            lda $03ae          ; $d34a: ad ae 03  
            clc                ; $d34d: 18        
            adc __d299,x       ; $d34e: 7d 99 d2  
            sta $0203,y        ; $d351: 99 03 02  
            iny                ; $d354: c8        
            iny                ; $d355: c8        
            iny                ; $d356: c8        
            iny                ; $d357: c8        
            dex                ; $d358: ca        
            bpl __d335         ; $d359: 10 da     
            ldx $08            ; $d35b: a6 08     
            rts                ; $d35d: 60        

;-------------------------------------------------------------------------------
__d35e:     jsr __d32d         ; $d35e: 20 2d d3  
            lda #$06           ; $d361: a9 06     
            sta $0796,x        ; $d363: 9d 96 07  
__d366:     inc $0746          ; $d366: ee 46 07  
            rts                ; $d369: 60        

;-------------------------------------------------------------------------------
            jsr __d32d         ; $d36a: 20 2d d3  
            lda $0796,x        ; $d36d: bd 96 07  
            bne __d377         ; $d370: d0 05     
            lda $07b1          ; $d372: ad b1 07  
            beq __d366         ; $d375: f0 ef     
__d377:     rts                ; $d377: 60        

;-------------------------------------------------------------------------------
            lda $1e,x          ; $d378: b5 1e     
            bne __d3d2         ; $d37a: d0 56     
            lda $078a,x        ; $d37c: bd 8a 07  
            bne __d3d2         ; $d37f: d0 51     
            lda $a0,x          ; $d381: b5 a0     
            bne __d3a8         ; $d383: d0 23     
            lda $58,x          ; $d385: b5 58     
            bmi __d39d         ; $d387: 30 14     
            jsr __e14b         ; $d389: 20 4b e1  
            bpl __d397         ; $d38c: 10 09     
            lda $00            ; $d38e: a5 00     
            eor #$ff           ; $d390: 49 ff     
            clc                ; $d392: 18        
            adc #$01           ; $d393: 69 01     
            sta $00            ; $d395: 85 00     
__d397:     lda $00            ; $d397: a5 00     
            .hex c9            ; $d399: c9        Suspected data
__d39a:     and ($90,x)        ; $d39a: 21 90     
            .hex 35            ; $d39c: 35        Suspected data
__d39d:     lda $58,x          ; $d39d: b5 58     
            eor #$ff           ; $d39f: 49 ff     
            clc                ; $d3a1: 18        
            adc #$01           ; $d3a2: 69 01     
            sta $58,x          ; $d3a4: 95 58     
            inc $a0,x          ; $d3a6: f6 a0     
__d3a8:     lda $0434,x        ; $d3a8: bd 34 04  
            ldy $58,x          ; $d3ab: b4 58     
__d3ad:     bpl __d3b2         ; $d3ad: 10 03     
            lda $0417,x        ; $d3af: bd 17 04  
__d3b2:     sta $00            ; $d3b2: 85 00     
            lda $09            ; $d3b4: a5 09     
            lsr                ; $d3b6: 4a        
            bcc __d3d2         ; $d3b7: 90 19     
            lda $0747          ; $d3b9: ad 47 07  
            bne __d3d2         ; $d3bc: d0 14     
            lda $cf,x          ; $d3be: b5 cf     
            clc                ; $d3c0: 18        
            adc $58,x          ; $d3c1: 75 58     
            sta $cf,x          ; $d3c3: 95 cf     
            cmp $00            ; $d3c5: c5 00     
            bne __d3d2         ; $d3c7: d0 09     
            lda #$00           ; $d3c9: a9 00     
            sta $a0,x          ; $d3cb: 95 a0     
            lda #$40           ; $d3cd: a9 40     
            sta $078a,x        ; $d3cf: 9d 8a 07  
__d3d2:     lda #$20           ; $d3d2: a9 20     
            sta $03c5,x        ; $d3d4: 9d c5 03  
            rts                ; $d3d7: 60        

;-------------------------------------------------------------------------------
__d3d8:     sta $07            ; $d3d8: 85 07     
            lda $34,x          ; $d3da: b5 34     
            bne __d3ec         ; $d3dc: d0 0e     
            ldy #$18           ; $d3de: a0 18     
            .hex b5            ; $d3e0: b5        Suspected data
__d3e1:     cli                ; $d3e1: 58        
            clc                ; $d3e2: 18        
            adc $07            ; $d3e3: 65 07     
            sta $58,x          ; $d3e5: 95 58     
            lda $a0,x          ; $d3e7: b5 a0     
            adc #$00           ; $d3e9: 69 00     
            rts                ; $d3eb: 60        

;-------------------------------------------------------------------------------
__d3ec:     ldy #$08           ; $d3ec: a0 08     
            lda $58,x          ; $d3ee: b5 58     
            sec                ; $d3f0: 38        
            sbc $07            ; $d3f1: e5 07     
            sta $58,x          ; $d3f3: 95 58     
            lda $a0,x          ; $d3f5: b5 a0     
            sbc #$00           ; $d3f7: e9 00     
            rts                ; $d3f9: 60        

;-------------------------------------------------------------------------------
            lda $b6,x          ; $d3fa: b5 b6     
            cmp #$03           ; $d3fc: c9 03     
            bne __d403         ; $d3fe: d0 03     
__d400:     jmp __c99e         ; $d400: 4c 9e c9  

;-------------------------------------------------------------------------------
__d403:     lda $1e,x          ; $d403: b5 1e     
            bpl __d408         ; $d405: 10 01     
            rts                ; $d407: 60        

;-------------------------------------------------------------------------------
__d408:     tay                ; $d408: a8        
            lda $03a2,x        ; $d409: bd a2 03  
            sta $00            ; $d40c: 85 00     
            lda $46,x          ; $d40e: b5 46     
            beq __d415         ; $d410: f0 03     
            jmp __d583         ; $d412: 4c 83 d5  

;-------------------------------------------------------------------------------
__d415:     lda #$2d           ; $d415: a9 2d     
            cmp $cf,x          ; $d417: d5 cf     
            bcc __d42a         ; $d419: 90 0f     
            cpy $00            ; $d41b: c4 00     
            beq __d427         ; $d41d: f0 08     
            clc                ; $d41f: 18        
            adc #$02           ; $d420: 69 02     
            sta $cf,x          ; $d422: 95 cf     
            jmp __d579         ; $d424: 4c 79 d5  

;-------------------------------------------------------------------------------
__d427:     jmp __d560         ; $d427: 4c 60 d5  

;-------------------------------------------------------------------------------
__d42a:     cmp $00cf,y        ; $d42a: d9 cf 00  
            bcc __d43c         ; $d42d: 90 0d     
            cpx $00            ; $d42f: e4 00     
            beq __d427         ; $d431: f0 f4     
            clc                ; $d433: 18        
            adc #$02           ; $d434: 69 02     
            sta $00cf,y        ; $d436: 99 cf 00  
            jmp __d579         ; $d439: 4c 79 d5  

;-------------------------------------------------------------------------------
__d43c:     lda $cf,x          ; $d43c: b5 cf     
            pha                ; $d43e: 48        
            lda $03a2,x        ; $d43f: bd a2 03  
            bpl __d45c         ; $d442: 10 18     
            lda $0434,x        ; $d444: bd 34 04  
            clc                ; $d447: 18        
            adc #$05           ; $d448: 69 05     
            sta $00            ; $d44a: 85 00     
            lda $a0,x          ; $d44c: b5 a0     
            adc #$00           ; $d44e: 69 00     
            bmi __d46c         ; $d450: 30 1a     
            bne __d460         ; $d452: d0 0c     
            lda $00            ; $d454: a5 00     
            cmp #$0b           ; $d456: c9 0b     
            bcc __d466         ; $d458: 90 0c     
            bcs __d460         ; $d45a: b0 04     
__d45c:     cmp $08            ; $d45c: c5 08     
            beq __d46c         ; $d45e: f0 0c     
__d460:     jsr __bfbc         ; $d460: 20 bc bf  
            jmp __d46f         ; $d463: 4c 6f d4  

;-------------------------------------------------------------------------------
__d466:     jsr __d579         ; $d466: 20 79 d5  
            jmp __d46f         ; $d469: 4c 6f d4  

;-------------------------------------------------------------------------------
__d46c:     jsr __bfb9         ; $d46c: 20 b9 bf  
__d46f:     ldy $1e,x          ; $d46f: b4 1e     
            pla                ; $d471: 68        
            sec                ; $d472: 38        
            sbc $cf,x          ; $d473: f5 cf     
            clc                ; $d475: 18        
            adc $00cf,y        ; $d476: 79 cf 00  
            sta $00cf,y        ; $d479: 99 cf 00  
            lda $03a2,x        ; $d47c: bd a2 03  
            bmi __d485         ; $d47f: 30 04     
            tax                ; $d481: aa        
            jsr __dc23         ; $d482: 20 23 dc  
__d485:     ldy $08            ; $d485: a4 08     
            lda $00a0,y        ; $d487: b9 a0 00  
            ora $0434,y        ; $d48a: 19 34 04  
            beq __d506         ; $d48d: f0 77     
            ldx $0300          ; $d48f: ae 00 03  
            cpx #$20           ; $d492: e0 20     
            bcs __d506         ; $d494: b0 70     
            lda $00a0,y        ; $d496: b9 a0 00  
            pha                ; $d499: 48        
            pha                ; $d49a: 48        
            jsr __d509         ; $d49b: 20 09 d5  
            lda $01            ; $d49e: a5 01     
            sta $0301,x        ; $d4a0: 9d 01 03  
            lda $00            ; $d4a3: a5 00     
            sta $0302,x        ; $d4a5: 9d 02 03  
            lda #$02           ; $d4a8: a9 02     
            sta $0303,x        ; $d4aa: 9d 03 03  
            lda $00a0,y        ; $d4ad: b9 a0 00  
            bmi __d4bf         ; $d4b0: 30 0d     
            lda #$a2           ; $d4b2: a9 a2     
            sta $0304,x        ; $d4b4: 9d 04 03  
            lda #$a3           ; $d4b7: a9 a3     
            sta $0305,x        ; $d4b9: 9d 05 03  
            jmp __d4c7         ; $d4bc: 4c c7 d4  

;-------------------------------------------------------------------------------
__d4bf:     lda #$24           ; $d4bf: a9 24     
            sta $0304,x        ; $d4c1: 9d 04 03  
            .hex 9d 05         ; $d4c4: 9d 05     Suspected data
__d4c6:     .hex 03            ; $d4c6: 03        Suspected data
__d4c7:     lda $001e,y        ; $d4c7: b9 1e 00  
            tay                ; $d4ca: a8        
            pla                ; $d4cb: 68        
            eor #$ff           ; $d4cc: 49 ff     
            jsr __d509         ; $d4ce: 20 09 d5  
            lda $01            ; $d4d1: a5 01     
            sta $0306,x        ; $d4d3: 9d 06 03  
            lda $00            ; $d4d6: a5 00     
            sta $0307,x        ; $d4d8: 9d 07 03  
            lda #$02           ; $d4db: a9 02     
            sta $0308,x        ; $d4dd: 9d 08 03  
            pla                ; $d4e0: 68        
            bpl __d4f0         ; $d4e1: 10 0d     
            lda #$a2           ; $d4e3: a9 a2     
            sta $0309,x        ; $d4e5: 9d 09 03  
            lda #$a3           ; $d4e8: a9 a3     
            sta $030a,x        ; $d4ea: 9d 0a 03  
            jmp __d4f8         ; $d4ed: 4c f8 d4  

;-------------------------------------------------------------------------------
__d4f0:     lda #$24           ; $d4f0: a9 24     
            sta $0309,x        ; $d4f2: 9d 09 03  
            sta $030a,x        ; $d4f5: 9d 0a 03  
__d4f8:     lda #$00           ; $d4f8: a9 00     
            sta $030b,x        ; $d4fa: 9d 0b 03  
            lda $0300          ; $d4fd: ad 00 03  
            clc                ; $d500: 18        
            adc #$0a           ; $d501: 69 0a     
            sta $0300          ; $d503: 8d 00 03  
__d506:     ldx $08            ; $d506: a6 08     
            rts                ; $d508: 60        

;-------------------------------------------------------------------------------
__d509:     pha                ; $d509: 48        
            lda $0087,y        ; $d50a: b9 87 00  
            clc                ; $d50d: 18        
            adc #$08           ; $d50e: 69 08     
            ldx $06cc          ; $d510: ae cc 06  
            bne __d518         ; $d513: d0 03     
            clc                ; $d515: 18        
            adc #$10           ; $d516: 69 10     
__d518:     pha                ; $d518: 48        
            lda $006e,y        ; $d519: b9 6e 00  
            adc #$00           ; $d51c: 69 00     
            sta $02            ; $d51e: 85 02     
            pla                ; $d520: 68        
            and #$f0           ; $d521: 29 f0     
            lsr                ; $d523: 4a        
            lsr                ; $d524: 4a        
            lsr                ; $d525: 4a        
            sta $00            ; $d526: 85 00     
            ldx $cf,y          ; $d528: b6 cf     
            pla                ; $d52a: 68        
            bpl __d532         ; $d52b: 10 05     
            txa                ; $d52d: 8a        
            clc                ; $d52e: 18        
            adc #$08           ; $d52f: 69 08     
            tax                ; $d531: aa        
__d532:     txa                ; $d532: 8a        
            ldx $0300          ; $d533: ae 00 03  
            asl                ; $d536: 0a        
            rol                ; $d537: 2a        
            pha                ; $d538: 48        
            rol                ; $d539: 2a        
            and #$03           ; $d53a: 29 03     
            ora #$20           ; $d53c: 09 20     
            sta $01            ; $d53e: 85 01     
            lda $02            ; $d540: a5 02     
            and #$01           ; $d542: 29 01     
            asl                ; $d544: 0a        
            asl                ; $d545: 0a        
            ora $01            ; $d546: 05 01     
            sta $01            ; $d548: 85 01     
            pla                ; $d54a: 68        
            and #$e0           ; $d54b: 29 e0     
            clc                ; $d54d: 18        
            adc $00            ; $d54e: 65 00     
            sta $00            ; $d550: 85 00     
            lda $00cf,y        ; $d552: b9 cf 00  
            cmp #$e8           ; $d555: c9 e8     
            bcc __d55f         ; $d557: 90 06     
            lda $00            ; $d559: a5 00     
            and #$bf           ; $d55b: 29 bf     
            sta $00            ; $d55d: 85 00     
__d55f:     rts                ; $d55f: 60        

;-------------------------------------------------------------------------------
__d560:     tya                ; $d560: 98        
            tax                ; $d561: aa        
            jsr __f1b6         ; $d562: 20 b6 f1  
            lda #$06           ; $d565: a9 06     
            jsr __da13         ; $d567: 20 13 da  
            lda $03ad          ; $d56a: ad ad 03  
            sta $0117,x        ; $d56d: 9d 17 01  
            lda $ce            ; $d570: a5 ce     
            sta $011e,x        ; $d572: 9d 1e 01  
            lda #$01           ; $d575: a9 01     
            sta $46,x          ; $d577: 95 46     
__d579:     jsr __c369         ; $d579: 20 69 c3  
            sta $00a0,y        ; $d57c: 99 a0 00  
            sta $0434,y        ; $d57f: 99 34 04  
            rts                ; $d582: 60        

;-------------------------------------------------------------------------------
__d583:     tya                ; $d583: 98        
            pha                ; $d584: 48        
            jsr __bf70         ; $d585: 20 70 bf  
            pla                ; $d588: 68        
            tax                ; $d589: aa        
            jsr __bf70         ; $d58a: 20 70 bf  
            ldx $08            ; $d58d: a6 08     
            lda $03a2,x        ; $d58f: bd a2 03  
            bmi __d598         ; $d592: 30 04     
            tax                ; $d594: aa        
            jsr __dc23         ; $d595: 20 23 dc  
__d598:     ldx $08            ; $d598: a6 08     
            rts                ; $d59a: 60        

;-------------------------------------------------------------------------------
            lda $a0,x          ; $d59b: b5 a0     
            ora $0434,x        ; $d59d: 1d 34 04  
            bne __d5b7         ; $d5a0: d0 15     
            sta $0417,x        ; $d5a2: 9d 17 04  
            lda $cf,x          ; $d5a5: b5 cf     
            cmp $0401,x        ; $d5a7: dd 01 04  
            bcs __d5b7         ; $d5aa: b0 0b     
            lda $09            ; $d5ac: a5 09     
            and #$07           ; $d5ae: 29 07     
            bne __d5b4         ; $d5b0: d0 02     
            inc $cf,x          ; $d5b2: f6 cf     
__d5b4:     jmp __d5c6         ; $d5b4: 4c c6 d5  

;-------------------------------------------------------------------------------
__d5b7:     lda $cf,x          ; $d5b7: b5 cf     
            cmp $58,x          ; $d5b9: d5 58     
            bcc __d5c3         ; $d5bb: 90 06     
            jsr __bfbc         ; $d5bd: 20 bc bf  
            jmp __d5c6         ; $d5c0: 4c c6 d5  

;-------------------------------------------------------------------------------
__d5c3:     jsr __bfb9         ; $d5c3: 20 b9 bf  
__d5c6:     lda $03a2,x        ; $d5c6: bd a2 03  
            bmi __d5ce         ; $d5c9: 30 03     
            jsr __dc23         ; $d5cb: 20 23 dc  
__d5ce:     rts                ; $d5ce: 60        

;-------------------------------------------------------------------------------
            lda #$0e           ; $d5cf: a9 0e     
            jsr __cb4d         ; $d5d1: 20 4d cb  
            jsr __cb6c         ; $d5d4: 20 6c cb  
            lda $03a2,x        ; $d5d7: bd a2 03  
            bmi __d5f8         ; $d5da: 30 1c     
__d5dc:     lda $86            ; $d5dc: a5 86     
            clc                ; $d5de: 18        
            adc $00            ; $d5df: 65 00     
            sta $86            ; $d5e1: 85 86     
            lda $6d            ; $d5e3: a5 6d     
            ldy $00            ; $d5e5: a4 00     
            bmi __d5ee         ; $d5e7: 30 05     
            adc #$00           ; $d5e9: 69 00     
            jmp __d5f0         ; $d5eb: 4c f0 d5  

;-------------------------------------------------------------------------------
__d5ee:     sbc #$00           ; $d5ee: e9 00     
__d5f0:     sta $6d            ; $d5f0: 85 6d     
            sty $03a1          ; $d5f2: 8c a1 03  
            jsr __dc23         ; $d5f5: 20 23 dc  
__d5f8:     rts                ; $d5f8: 60        

;-------------------------------------------------------------------------------
            lda $03a2,x        ; $d5f9: bd a2 03  
            bmi __d604         ; $d5fc: 30 06     
            jsr __bf8d         ; $d5fe: 20 8d bf  
            jsr __dc23         ; $d601: 20 23 dc  
__d604:     rts                ; $d604: 60        

;-------------------------------------------------------------------------------
            jsr __bf07         ; $d605: 20 07 bf  
            sta $00            ; $d608: 85 00     
            lda $03a2,x        ; $d60a: bd a2 03  
            bmi __d616         ; $d60d: 30 07     
            lda #$13           ; $d60f: a9 13     
            sta $58,x          ; $d611: 95 58     
            jsr __d5dc         ; $d613: 20 dc d5  
__d616:     rts                ; $d616: 60        

;-------------------------------------------------------------------------------
            jsr __d623         ; $d617: 20 23 d6  
            jmp __d5c6         ; $d61a: 4c c6 d5  

;-------------------------------------------------------------------------------
__d61d:     jsr __d623         ; $d61d: 20 23 d6  
            jmp __d639         ; $d620: 4c 39 d6  

;-------------------------------------------------------------------------------
__d623:     lda $0747          ; $d623: ad 47 07  
            bne __d641         ; $d626: d0 19     
            lda $0417,x        ; $d628: bd 17 04  
            clc                ; $d62b: 18        
            adc $0434,x        ; $d62c: 7d 34 04  
            sta $0417,x        ; $d62f: 9d 17 04  
            lda $cf,x          ; $d632: b5 cf     
            adc $a0,x          ; $d634: 75 a0     
            sta $cf,x          ; $d636: 95 cf     
            rts                ; $d638: 60        

;-------------------------------------------------------------------------------
__d639:     lda $03a2,x        ; $d639: bd a2 03  
            beq __d641         ; $d63c: f0 03     
            jsr __dc1b         ; $d63e: 20 1b dc  
__d641:     rts                ; $d641: 60        

;-------------------------------------------------------------------------------
__d642:     lda $16,x          ; $d642: b5 16     
            cmp #$14           ; $d644: c9 14     
            beq __d69d         ; $d646: f0 55     
            lda $071c          ; $d648: ad 1c 07  
            ldy $16,x          ; $d64b: b4 16     
            cpy #$05           ; $d64d: c0 05     
            beq __d655         ; $d64f: f0 04     
            cpy #$0d           ; $d651: c0 0d     
            bne __d657         ; $d653: d0 02     
__d655:     adc #$38           ; $d655: 69 38     
__d657:     sbc #$48           ; $d657: e9 48     
            sta $01            ; $d659: 85 01     
            lda $071a          ; $d65b: ad 1a 07  
            sbc #$00           ; $d65e: e9 00     
            sta $00            ; $d660: 85 00     
            lda $071d          ; $d662: ad 1d 07  
            adc #$48           ; $d665: 69 48     
            sta $03            ; $d667: 85 03     
            lda $071b          ; $d669: ad 1b 07  
            adc #$00           ; $d66c: 69 00     
            sta $02            ; $d66e: 85 02     
            lda $87,x          ; $d670: b5 87     
            cmp $01            ; $d672: c5 01     
            lda $6e,x          ; $d674: b5 6e     
            sbc $00            ; $d676: e5 00     
            bmi __d69a         ; $d678: 30 20     
            lda $87,x          ; $d67a: b5 87     
            cmp $03            ; $d67c: c5 03     
            lda $6e,x          ; $d67e: b5 6e     
            sbc $02            ; $d680: e5 02     
            bmi __d69d         ; $d682: 30 19     
            lda $1e,x          ; $d684: b5 1e     
            cmp #$05           ; $d686: c9 05     
            beq __d69d         ; $d688: f0 13     
            cpy #$0d           ; $d68a: c0 0d     
            beq __d69d         ; $d68c: f0 0f     
            cpy #$30           ; $d68e: c0 30     
            beq __d69d         ; $d690: f0 0b     
            cpy #$31           ; $d692: c0 31     
            beq __d69d         ; $d694: f0 07     
            cpy #$32           ; $d696: c0 32     
            beq __d69d         ; $d698: f0 03     
__d69a:     jsr __c99e         ; $d69a: 20 9e c9  
__d69d:     rts                ; $d69d: 60        

;-------------------------------------------------------------------------------
            .hex ff ff ff      ; $d69e: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6a1: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6a4: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6a7: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6aa: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6ad: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6b0: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6b3: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6b6: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6b9: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6bc: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6bf: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6c2: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6c5: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6c8: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6cb: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6ce: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff ff      ; $d6d1: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex ff ff         ; $d6d4: ff ff     Suspected data
__d6d6:     .hex ff ff ff      ; $d6d6: ff ff ff  Invalid Opcode - ISC $ffff,x
__d6d9:     lda $24,x          ; $d6d9: b5 24     
            beq __d733         ; $d6db: f0 56     
            asl                ; $d6dd: 0a        
            bcs __d733         ; $d6de: b0 53     
            lda $09            ; $d6e0: a5 09     
            lsr                ; $d6e2: 4a        
            bcs __d733         ; $d6e3: b0 4e     
            txa                ; $d6e5: 8a        
            asl                ; $d6e6: 0a        
            asl                ; $d6e7: 0a        
            clc                ; $d6e8: 18        
            adc #$1c           ; $d6e9: 69 1c     
            tay                ; $d6eb: a8        
            ldx #$04           ; $d6ec: a2 04     
__d6ee:     stx $01            ; $d6ee: 86 01     
            tya                ; $d6f0: 98        
            pha                ; $d6f1: 48        
            lda $1e,x          ; $d6f2: b5 1e     
            and #$20           ; $d6f4: 29 20     
            bne __d72c         ; $d6f6: d0 34     
            lda $0f,x          ; $d6f8: b5 0f     
            beq __d72c         ; $d6fa: f0 30     
            lda $16,x          ; $d6fc: b5 16     
            cmp #$24           ; $d6fe: c9 24     
            bcc __d706         ; $d700: 90 04     
            cmp #$2b           ; $d702: c9 2b     
            bcc __d72c         ; $d704: 90 26     
__d706:     cmp #$06           ; $d706: c9 06     
            bne __d710         ; $d708: d0 06     
            lda $1e,x          ; $d70a: b5 1e     
            cmp #$02           ; $d70c: c9 02     
            bcs __d72c         ; $d70e: b0 1c     
__d710:     lda $03d8,x        ; $d710: bd d8 03  
            bne __d72c         ; $d713: d0 17     
            txa                ; $d715: 8a        
            asl                ; $d716: 0a        
            asl                ; $d717: 0a        
            clc                ; $d718: 18        
            adc #$04           ; $d719: 69 04     
            tax                ; $d71b: aa        
            jsr __e32f         ; $d71c: 20 2f e3  
            ldx $08            ; $d71f: a6 08     
            bcc __d72c         ; $d721: 90 09     
            lda #$80           ; $d723: a9 80     
            sta $24,x          ; $d725: 95 24     
            ldx $01            ; $d727: a6 01     
            jsr __d73e         ; $d729: 20 3e d7  
__d72c:     pla                ; $d72c: 68        
            tay                ; $d72d: a8        
            ldx $01            ; $d72e: a6 01     
            dex                ; $d730: ca        
            bpl __d6ee         ; $d731: 10 bb     
__d733:     ldx $08            ; $d733: a6 08     
            rts                ; $d735: 60        

;-------------------------------------------------------------------------------
__d736:     asl $00            ; $d736: 06 00     
            .hex 02            ; $d738: 02        Invalid Opcode - KIL 
            .hex 12            ; $d739: 12        Invalid Opcode - KIL 
            ora ($07),y        ; $d73a: 11 07     
            ora $2d            ; $d73c: 05 2d     
__d73e:     jsr __f159         ; $d73e: 20 59 f1  
            ldx $01            ; $d741: a6 01     
            lda $0f,x          ; $d743: b5 0f     
            bpl __d752         ; $d745: 10 0b     
            and #$0f           ; $d747: 29 0f     
            tax                ; $d749: aa        
            lda $16,x          ; $d74a: b5 16     
            cmp #$2d           ; $d74c: c9 2d     
            beq __d75c         ; $d74e: f0 0c     
            ldx $01            ; $d750: a6 01     
__d752:     lda $16,x          ; $d752: b5 16     
            cmp #$02           ; $d754: c9 02     
            beq __d7c3         ; $d756: f0 6b     
            cmp #$2d           ; $d758: c9 2d     
            bne __d789         ; $d75a: d0 2d     
__d75c:     dec $0483          ; $d75c: ce 83 04  
            bne __d7c3         ; $d75f: d0 62     
            jsr __c369         ; $d761: 20 69 c3  
            sta $58,x          ; $d764: 95 58     
            sta $06cb          ; $d766: 8d cb 06  
            lda #$fe           ; $d769: a9 fe     
            sta $a0,x          ; $d76b: 95 a0     
            ldy $075f          ; $d76d: ac 5f 07  
            lda __d736,y       ; $d770: b9 36 d7  
            sta $16,x          ; $d773: 95 16     
            lda #$20           ; $d775: a9 20     
            cpy #$03           ; $d777: c0 03     
            bcs __d77d         ; $d779: b0 02     
            ora #$03           ; $d77b: 09 03     
__d77d:     sta $1e,x          ; $d77d: 95 1e     
            lda #$80           ; $d77f: a9 80     
            sta $fe            ; $d781: 85 fe     
            ldx $01            ; $d783: a6 01     
            lda #$09           ; $d785: a9 09     
            bne __d7bc         ; $d787: d0 33     
__d789:     cmp #$08           ; $d789: c9 08     
            beq __d7c3         ; $d78b: f0 36     
            cmp #$0c           ; $d78d: c9 0c     
            beq __d7c3         ; $d78f: f0 32     
            cmp #$15           ; $d791: c9 15     
            bcs __d7c3         ; $d793: b0 2e     
__d795:     lda $16,x          ; $d795: b5 16     
            cmp #$0d           ; $d797: c9 0d     
            bne __d7a1         ; $d799: d0 06     
            lda $cf,x          ; $d79b: b5 cf     
            adc #$18           ; $d79d: 69 18     
            sta $cf,x          ; $d79f: 95 cf     
__d7a1:     jsr __e023         ; $d7a1: 20 23 e0  
__d7a4:     lda $1e,x          ; $d7a4: b5 1e     
            and #$1f           ; $d7a6: 29 1f     
            ora #$20           ; $d7a8: 09 20     
            sta $1e,x          ; $d7aa: 95 1e     
            lda #$02           ; $d7ac: a9 02     
            ldy $16,x          ; $d7ae: b4 16     
            cpy #$05           ; $d7b0: c0 05     
            bne __d7b6         ; $d7b2: d0 02     
            lda #$06           ; $d7b4: a9 06     
__d7b6:     cpy #$06           ; $d7b6: c0 06     
            bne __d7bc         ; $d7b8: d0 02     
            lda #$01           ; $d7ba: a9 01     
__d7bc:     jsr __da13         ; $d7bc: 20 13 da  
            lda #$08           ; $d7bf: a9 08     
            sta $ff            ; $d7c1: 85 ff     
__d7c3:     rts                ; $d7c3: 60        

;-------------------------------------------------------------------------------
__d7c4:     lda $09            ; $d7c4: a5 09     
            lsr                ; $d7c6: 4a        
            bcc __d7ff         ; $d7c7: 90 36     
            lda $0747          ; $d7c9: ad 47 07  
            ora $03d6          ; $d7cc: 0d d6 03  
            bne __d7ff         ; $d7cf: d0 2e     
            txa                ; $d7d1: 8a        
            asl                ; $d7d2: 0a        
            asl                ; $d7d3: 0a        
            clc                ; $d7d4: 18        
            adc #$24           ; $d7d5: 69 24     
            tay                ; $d7d7: a8        
            jsr __e32d         ; $d7d8: 20 2d e3  
            ldx $08            ; $d7db: a6 08     
            bcc __d7fa         ; $d7dd: 90 1b     
            lda $06be,x        ; $d7df: bd be 06  
            bne __d7ff         ; $d7e2: d0 1b     
            lda #$01           ; $d7e4: a9 01     
            sta $06be,x        ; $d7e6: 9d be 06  
            lda $64,x          ; $d7e9: b5 64     
            eor #$ff           ; $d7eb: 49 ff     
            clc                ; $d7ed: 18        
            adc #$01           ; $d7ee: 69 01     
            sta $64,x          ; $d7f0: 95 64     
            lda $079f          ; $d7f2: ad 9f 07  
            bne __d7ff         ; $d7f5: d0 08     
            jmp __d92d         ; $d7f7: 4c 2d d9  

;-------------------------------------------------------------------------------
__d7fa:     lda #$00           ; $d7fa: a9 00     
            sta $06be,x        ; $d7fc: 9d be 06  
__d7ff:     rts                ; $d7ff: 60        

;-------------------------------------------------------------------------------
__d800:     jsr __c99e         ; $d800: 20 9e c9  
            lda #$06           ; $d803: a9 06     
            jsr __da13         ; $d805: 20 13 da  
            lda #$20           ; $d808: a9 20     
            sta $fe            ; $d80a: 85 fe     
            lda $39            ; $d80c: a5 39     
            cmp #$02           ; $d80e: c9 02     
            bcc __d820         ; $d810: 90 0e     
            cmp #$03           ; $d812: c9 03     
            beq __d83a         ; $d814: f0 24     
            lda #$23           ; $d816: a9 23     
            sta $079f          ; $d818: 8d 9f 07  
            lda #$40           ; $d81b: a9 40     
            sta $fb            ; $d81d: 85 fb     
            rts                ; $d81f: 60        

;-------------------------------------------------------------------------------
__d820:     lda $0756          ; $d820: ad 56 07  
            beq __d840         ; $d823: f0 1b     
            cmp #$01           ; $d825: c9 01     
            bne __d84c         ; $d827: d0 23     
            ldx $08            ; $d829: a6 08     
            lda #$02           ; $d82b: a9 02     
            sta $0756          ; $d82d: 8d 56 07  
            jsr __85f1         ; $d830: 20 f1 85  
            ldx $08            ; $d833: a6 08     
            lda #$0c           ; $d835: a9 0c     
            jmp __d847         ; $d837: 4c 47 d8  

;-------------------------------------------------------------------------------
__d83a:     lda #$0b           ; $d83a: a9 0b     
            sta $0110,x        ; $d83c: 9d 10 01  
            rts                ; $d83f: 60        

;-------------------------------------------------------------------------------
__d840:     lda #$01           ; $d840: a9 01     
            sta $0756          ; $d842: 8d 56 07  
            lda #$09           ; $d845: a9 09     
__d847:     ldy #$00           ; $d847: a0 00     
            jsr __d94a         ; $d849: 20 4a d9  
__d84c:     rts                ; $d84c: 60        

;-------------------------------------------------------------------------------
            clc                ; $d84d: 18        
            inx                ; $d84e: e8        
__d84f:     sec                ; $d84f: 38        
            iny                ; $d850: c8        
__d851:     php                ; $d851: 08        
            sed                ; $d852: f8        
__d853:     lda $09            ; $d853: a5 09     
            lsr                ; $d855: 4a        
            bcs __d84c         ; $d856: b0 f4     
            jsr __dc43         ; $d858: 20 43 dc  
            bcs __d880         ; $d85b: b0 23     
            lda $03d8,x        ; $d85d: bd d8 03  
            bne __d880         ; $d860: d0 1e     
            lda $0e            ; $d862: a5 0e     
            cmp #$08           ; $d864: c9 08     
            bne __d880         ; $d866: d0 18     
            lda $1e,x          ; $d868: b5 1e     
            and #$20           ; $d86a: 29 20     
            bne __d880         ; $d86c: d0 12     
            jsr __dc54         ; $d86e: 20 54 dc  
            jsr __e32d         ; $d871: 20 2d e3  
            ldx $08            ; $d874: a6 08     
            bcs __d881         ; $d876: b0 09     
            lda $0491,x        ; $d878: bd 91 04  
            and #$fe           ; $d87b: 29 fe     
            sta $0491,x        ; $d87d: 9d 91 04  
__d880:     rts                ; $d880: 60        

;-------------------------------------------------------------------------------
__d881:     ldy $16,x          ; $d881: b4 16     
            cpy #$2e           ; $d883: c0 2e     
            bne __d88a         ; $d885: d0 03     
            jmp __d800         ; $d887: 4c 00 d8  

;-------------------------------------------------------------------------------
__d88a:     lda $079f          ; $d88a: ad 9f 07  
            beq __d895         ; $d88d: f0 06     
            jmp __d795         ; $d88f: 4c 95 d7  

;-------------------------------------------------------------------------------
__d892:     asl                ; $d892: 0a        
            asl $04            ; $d893: 06 04     
__d895:     lda $0491,x        ; $d895: bd 91 04  
            and #$01           ; $d898: 29 01     
            ora $03d8,x        ; $d89a: 1d d8 03  
            bne __d8f8         ; $d89d: d0 59     
            lda #$01           ; $d89f: a9 01     
            ora $0491,x        ; $d8a1: 1d 91 04  
            sta $0491,x        ; $d8a4: 9d 91 04  
            cpy #$12           ; $d8a7: c0 12     
            beq __d8f9         ; $d8a9: f0 4e     
            cpy #$0d           ; $d8ab: c0 0d     
            beq __d92d         ; $d8ad: f0 7e     
            cpy #$0c           ; $d8af: c0 0c     
            beq __d92d         ; $d8b1: f0 7a     
            cpy #$33           ; $d8b3: c0 33     
            beq __d8f9         ; $d8b5: f0 42     
            cpy #$15           ; $d8b7: c0 15     
            bcs __d92d         ; $d8b9: b0 72     
            lda $074e          ; $d8bb: ad 4e 07  
            beq __d92d         ; $d8be: f0 6d     
            lda $1e,x          ; $d8c0: b5 1e     
            asl                ; $d8c2: 0a        
            bcs __d8f9         ; $d8c3: b0 34     
            lda $1e,x          ; $d8c5: b5 1e     
            and #$07           ; $d8c7: 29 07     
            cmp #$02           ; $d8c9: c9 02     
            bcc __d8f9         ; $d8cb: 90 2c     
            lda $16,x          ; $d8cd: b5 16     
            cmp #$06           ; $d8cf: c9 06     
            beq __d8f8         ; $d8d1: f0 25     
            lda #$08           ; $d8d3: a9 08     
            sta $ff            ; $d8d5: 85 ff     
            lda $1e,x          ; $d8d7: b5 1e     
            ora #$80           ; $d8d9: 09 80     
            sta $1e,x          ; $d8db: 95 1e     
            jsr __da07         ; $d8dd: 20 07 da  
            lda __d84f,y       ; $d8e0: b9 4f d8  
            sta $58,x          ; $d8e3: 95 58     
            lda #$03           ; $d8e5: a9 03     
            clc                ; $d8e7: 18        
            adc $0484          ; $d8e8: 6d 84 04  
            ldy $0796,x        ; $d8eb: bc 96 07  
            cpy #$03           ; $d8ee: c0 03     
            bcs __d8f5         ; $d8f0: b0 03     
            lda __d892,y       ; $d8f2: b9 92 d8  
__d8f5:     jsr __da13         ; $d8f5: 20 13 da  
__d8f8:     rts                ; $d8f8: 60        

;-------------------------------------------------------------------------------
__d8f9:     lda $9f            ; $d8f9: a5 9f     
            bmi __d8ff         ; $d8fb: 30 02     
            bne __d96b         ; $d8fd: d0 6c     
__d8ff:     lda #$14           ; $d8ff: a9 14     
__d901:     ldy $16,x          ; $d901: b4 16     
            cpy #$14           ; $d903: c0 14     
            bne __d909         ; $d905: d0 02     
            lda #$07           ; $d907: a9 07     
__d909:     adc $ce            ; $d909: 65 ce     
            cmp $cf,x          ; $d90b: d5 cf     
            bcc __d96b         ; $d90d: 90 5c     
            lda $0791          ; $d90f: ad 91 07  
            bne __d96b         ; $d912: d0 57     
            lda $079e          ; $d914: ad 9e 07  
            bne __d957         ; $d917: d0 3e     
            lda $03ad          ; $d919: ad ad 03  
            cmp $03ae          ; $d91c: cd ae 03  
            bcc __d924         ; $d91f: 90 03     
            jmp __d9f8         ; $d921: 4c f8 d9  

;-------------------------------------------------------------------------------
__d924:     lda $46,x          ; $d924: b5 46     
            cmp #$01           ; $d926: c9 01     
            bne __d92d         ; $d928: d0 03     
            jmp __da01         ; $d92a: 4c 01 da  

;-------------------------------------------------------------------------------
__d92d:     lda $079e          ; $d92d: ad 9e 07  
            bne __d957         ; $d930: d0 25     
__d932:     ldx $0756          ; $d932: ae 56 07  
            beq __d95a         ; $d935: f0 23     
            sta $0756          ; $d937: 8d 56 07  
            lda #$08           ; $d93a: a9 08     
            sta $079e          ; $d93c: 8d 9e 07  
            lda #$10           ; $d93f: a9 10     
            sta $ff            ; $d941: 85 ff     
            jsr __85f1         ; $d943: 20 f1 85  
            lda #$0a           ; $d946: a9 0a     
__d948:     ldy #$01           ; $d948: a0 01     
__d94a:     sta $0e            ; $d94a: 85 0e     
            sty $1d            ; $d94c: 84 1d     
            ldy #$ff           ; $d94e: a0 ff     
            sty $0747          ; $d950: 8c 47 07  
            iny                ; $d953: c8        
            sty $0775          ; $d954: 8c 75 07  
__d957:     ldx $08            ; $d957: a6 08     
            rts                ; $d959: 60        

;-------------------------------------------------------------------------------
__d95a:     .hex 86            ; $d95a: 86        Suspected data
__d95b:     .hex 57 e8         ; $d95b: 57 e8     Invalid Opcode - SRE $e8,x
            stx $fc            ; $d95d: 86 fc     
            lda #$fc           ; $d95f: a9 fc     
            sta $9f            ; $d961: 85 9f     
            lda #$0b           ; $d963: a9 0b     
            bne __d948         ; $d965: d0 e1     
__d967:     .hex 02            ; $d967: 02        Invalid Opcode - KIL 
            asl $05            ; $d968: 06 05     
            .hex 06            ; $d96a: 06        Suspected data
__d96b:     lda $16,x          ; $d96b: b5 16     
            cmp #$12           ; $d96d: c9 12     
            beq __d92d         ; $d96f: f0 bc     
            lda #$04           ; $d971: a9 04     
            sta $ff            ; $d973: 85 ff     
            lda $16,x          ; $d975: b5 16     
            ldy #$00           ; $d977: a0 00     
            cmp #$14           ; $d979: c9 14     
            beq __d998         ; $d97b: f0 1b     
            cmp #$08           ; $d97d: c9 08     
            beq __d998         ; $d97f: f0 17     
            cmp #$33           ; $d981: c9 33     
            beq __d998         ; $d983: f0 13     
            cmp #$0c           ; $d985: c9 0c     
            beq __d998         ; $d987: f0 0f     
            iny                ; $d989: c8        
            cmp #$05           ; $d98a: c9 05     
            beq __d998         ; $d98c: f0 0a     
            iny                ; $d98e: c8        
            cmp #$11           ; $d98f: c9 11     
            beq __d998         ; $d991: f0 05     
            iny                ; $d993: c8        
            cmp #$07           ; $d994: c9 07     
            bne __d9b5         ; $d996: d0 1d     
__d998:     lda __d967,y       ; $d998: b9 67 d9  
            jsr __da13         ; $d99b: 20 13 da  
            lda $46,x          ; $d99e: b5 46     
            pha                ; $d9a0: 48        
            jsr __e037         ; $d9a1: 20 37 e0  
            pla                ; $d9a4: 68        
            sta $46,x          ; $d9a5: 95 46     
            lda #$20           ; $d9a7: a9 20     
            sta $1e,x          ; $d9a9: 95 1e     
            jsr __c369         ; $d9ab: 20 69 c3  
            sta $58,x          ; $d9ae: 95 58     
            lda #$fd           ; $d9b0: a9 fd     
            sta $9f            ; $d9b2: 85 9f     
            rts                ; $d9b4: 60        

;-------------------------------------------------------------------------------
__d9b5:     cmp #$09           ; $d9b5: c9 09     
            bcc __d9d6         ; $d9b7: 90 1d     
            and #$01           ; $d9b9: 29 01     
            sta $16,x          ; $d9bb: 95 16     
            ldy #$00           ; $d9bd: a0 00     
            sty $1e,x          ; $d9bf: 94 1e     
            lda #$03           ; $d9c1: a9 03     
            jsr __da13         ; $d9c3: 20 13 da  
            jsr __c369         ; $d9c6: 20 69 c3  
            jsr __da07         ; $d9c9: 20 07 da  
            lda __d851,y       ; $d9cc: b9 51 d8  
            sta $58,x          ; $d9cf: 95 58     
            jmp __d9f3         ; $d9d1: 4c f3 d9  

;-------------------------------------------------------------------------------
__d9d4:     .hex 0d 09         ; $d9d4: 0d 09     Suspected data
__d9d6:     lda #$04           ; $d9d6: a9 04     
            sta $1e,x          ; $d9d8: 95 1e     
            inc $0484          ; $d9da: ee 84 04  
            lda $0484          ; $d9dd: ad 84 04  
            clc                ; $d9e0: 18        
            adc $0791          ; $d9e1: 6d 91 07  
            jsr __da13         ; $d9e4: 20 13 da  
            inc $0791          ; $d9e7: ee 91 07  
            ldy $076a          ; $d9ea: ac 6a 07  
            lda __d9d4,y       ; $d9ed: b9 d4 d9  
            sta $0796,x        ; $d9f0: 9d 96 07  
__d9f3:     lda #$fc           ; $d9f3: a9 fc     
            sta $9f            ; $d9f5: 85 9f     
            rts                ; $d9f7: 60        

;-------------------------------------------------------------------------------
__d9f8:     lda $46,x          ; $d9f8: b5 46     
            cmp #$01           ; $d9fa: c9 01     
            bne __da01         ; $d9fc: d0 03     
            jmp __d92d         ; $d9fe: 4c 2d d9  

;-------------------------------------------------------------------------------
__da01:     jsr __db1e         ; $da01: 20 1e db  
            jmp __d92d         ; $da04: 4c 2d d9  

;-------------------------------------------------------------------------------
__da07:     ldy #$01           ; $da07: a0 01     
            jsr __e14b         ; $da09: 20 4b e1  
            bpl __da0f         ; $da0c: 10 01     
            iny                ; $da0e: c8        
__da0f:     sty $46,x          ; $da0f: 94 46     
            dey                ; $da11: 88        
            rts                ; $da12: 60        

;-------------------------------------------------------------------------------
__da13:     sta $0110,x        ; $da13: 9d 10 01  
            lda #$30           ; $da16: a9 30     
            sta $012c,x        ; $da18: 9d 2c 01  
            lda $cf,x          ; $da1b: b5 cf     
            sta $011e,x        ; $da1d: 9d 1e 01  
            lda $03ae          ; $da20: ad ae 03  
            sta $0117,x        ; $da23: 9d 17 01  
__da26:     rts                ; $da26: 60        

;-------------------------------------------------------------------------------
__da27:     .hex 80 40         ; $da27: 80 40     Invalid Opcode - NOP #$40
            jsr $0810          ; $da29: 20 10 08  
            .hex 04 02         ; $da2c: 04 02     Invalid Opcode - NOP $02
__da2e:     .hex 7f bf df      ; $da2e: 7f bf df  Invalid Opcode - RRA __dfbf,x
            .hex ef f7 fb      ; $da31: ef f7 fb  Invalid Opcode - ISC __fbf7
            .hex fd            ; $da34: fd        Suspected data
__da35:     lda $09            ; $da35: a5 09     
            lsr                ; $da37: 4a        
            bcc __da26         ; $da38: 90 ec     
            lda $074e          ; $da3a: ad 4e 07  
            beq __da26         ; $da3d: f0 e7     
            lda $16,x          ; $da3f: b5 16     
            cmp #$15           ; $da41: c9 15     
            bcs __dab3         ; $da43: b0 6e     
            cmp #$11           ; $da45: c9 11     
            beq __dab3         ; $da47: f0 6a     
            cmp #$0d           ; $da49: c9 0d     
            beq __dab3         ; $da4b: f0 66     
            lda $03d8,x        ; $da4d: bd d8 03  
            bne __dab3         ; $da50: d0 61     
            jsr __dc54         ; $da52: 20 54 dc  
            dex                ; $da55: ca        
            bmi __dab3         ; $da56: 30 5b     
__da58:     stx $01            ; $da58: 86 01     
            tya                ; $da5a: 98        
            pha                ; $da5b: 48        
            lda $0f,x          ; $da5c: b5 0f     
            beq __daac         ; $da5e: f0 4c     
            lda $16,x          ; $da60: b5 16     
            cmp #$15           ; $da62: c9 15     
            bcs __daac         ; $da64: b0 46     
            cmp #$11           ; $da66: c9 11     
            beq __daac         ; $da68: f0 42     
            cmp #$0d           ; $da6a: c9 0d     
            beq __daac         ; $da6c: f0 3e     
            lda $03d8,x        ; $da6e: bd d8 03  
            bne __daac         ; $da71: d0 39     
            txa                ; $da73: 8a        
            asl                ; $da74: 0a        
            asl                ; $da75: 0a        
            clc                ; $da76: 18        
            adc #$04           ; $da77: 69 04     
            tax                ; $da79: aa        
            jsr __e32f         ; $da7a: 20 2f e3  
            ldx $08            ; $da7d: a6 08     
            ldy $01            ; $da7f: a4 01     
            bcc __daa3         ; $da81: 90 20     
            lda $1e,x          ; $da83: b5 1e     
            ora $001e,y        ; $da85: 19 1e 00  
            and #$80           ; $da88: 29 80     
            bne __da9d         ; $da8a: d0 11     
            lda $0491,y        ; $da8c: b9 91 04  
            and __da27,x       ; $da8f: 3d 27 da  
            bne __daac         ; $da92: d0 18     
            lda $0491,y        ; $da94: b9 91 04  
            ora __da27,x       ; $da97: 1d 27 da  
            sta $0491,y        ; $da9a: 99 91 04  
__da9d:     jsr __dab6         ; $da9d: 20 b6 da  
            jmp __daac         ; $daa0: 4c ac da  

;-------------------------------------------------------------------------------
__daa3:     lda $0491,y        ; $daa3: b9 91 04  
            and __da2e,x       ; $daa6: 3d 2e da  
            sta $0491,y        ; $daa9: 99 91 04  
__daac:     pla                ; $daac: 68        
            tay                ; $daad: a8        
            ldx $01            ; $daae: a6 01     
            dex                ; $dab0: ca        
            bpl __da58         ; $dab1: 10 a5     
__dab3:     ldx $08            ; $dab3: a6 08     
            rts                ; $dab5: 60        

;-------------------------------------------------------------------------------
__dab6:     lda $001e,y        ; $dab6: b9 1e 00  
            ora $1e,x          ; $dab9: 15 1e     
            and #$20           ; $dabb: 29 20     
            bne __daf2         ; $dabd: d0 33     
            lda $1e,x          ; $dabf: b5 1e     
            cmp #$06           ; $dac1: c9 06     
            bcc __daf3         ; $dac3: 90 2e     
            lda $16,x          ; $dac5: b5 16     
            cmp #$05           ; $dac7: c9 05     
            beq __daf2         ; $dac9: f0 27     
            lda $001e,y        ; $dacb: b9 1e 00  
            asl                ; $dace: 0a        
            bcc __dadb         ; $dacf: 90 0a     
            lda #$06           ; $dad1: a9 06     
            jsr __da13         ; $dad3: 20 13 da  
            jsr __d795         ; $dad6: 20 95 d7  
            ldy $01            ; $dad9: a4 01     
__dadb:     tya                ; $dadb: 98        
            tax                ; $dadc: aa        
            jsr __d795         ; $dadd: 20 95 d7  
            ldx $08            ; $dae0: a6 08     
            lda $0125,x        ; $dae2: bd 25 01  
            clc                ; $dae5: 18        
            adc #$04           ; $dae6: 69 04     
            ldx $01            ; $dae8: a6 01     
            jsr __da13         ; $daea: 20 13 da  
            ldx $08            ; $daed: a6 08     
            inc $0125,x        ; $daef: fe 25 01  
__daf2:     rts                ; $daf2: 60        

;-------------------------------------------------------------------------------
__daf3:     lda $001e,y        ; $daf3: b9 1e 00  
            cmp #$06           ; $daf6: c9 06     
            bcc __db17         ; $daf8: 90 1d     
            lda $0016,y        ; $dafa: b9 16 00  
            cmp #$05           ; $dafd: c9 05     
            beq __daf2         ; $daff: f0 f1     
            jsr __d795         ; $db01: 20 95 d7  
            ldy $01            ; $db04: a4 01     
            lda $0125,y        ; $db06: b9 25 01  
            clc                ; $db09: 18        
            adc #$04           ; $db0a: 69 04     
            ldx $08            ; $db0c: a6 08     
            jsr __da13         ; $db0e: 20 13 da  
            ldx $01            ; $db11: a6 01     
            inc $0125,x        ; $db13: fe 25 01  
            rts                ; $db16: 60        

;-------------------------------------------------------------------------------
__db17:     tya                ; $db17: 98        
            tax                ; $db18: aa        
            jsr __db1e         ; $db19: 20 1e db  
            ldx $08            ; $db1c: a6 08     
__db1e:     lda $16,x          ; $db1e: b5 16     
            cmp #$0d           ; $db20: c9 0d     
            beq __db46         ; $db22: f0 22     
            cmp #$11           ; $db24: c9 11     
            beq __db46         ; $db26: f0 1e     
            cmp #$05           ; $db28: c9 05     
            beq __db46         ; $db2a: f0 1a     
            cmp #$12           ; $db2c: c9 12     
            beq __db38         ; $db2e: f0 08     
            cmp #$0e           ; $db30: c9 0e     
            beq __db38         ; $db32: f0 04     
            cmp #$07           ; $db34: c9 07     
            bcs __db46         ; $db36: b0 0e     
__db38:     lda $58,x          ; $db38: b5 58     
            eor #$ff           ; $db3a: 49 ff     
            tay                ; $db3c: a8        
            iny                ; $db3d: c8        
            sty $58,x          ; $db3e: 94 58     
            lda $46,x          ; $db40: b5 46     
            eor #$03           ; $db42: 49 03     
            sta $46,x          ; $db44: 95 46     
__db46:     rts                ; $db46: 60        

;-------------------------------------------------------------------------------
__db47:     lda #$ff           ; $db47: a9 ff     
            sta $03a2,x        ; $db49: 9d a2 03  
            lda $0747          ; $db4c: ad 47 07  
            bne __db7a         ; $db4f: d0 29     
            lda $1e,x          ; $db51: b5 1e     
            bmi __db7a         ; $db53: 30 25     
            lda $16,x          ; $db55: b5 16     
            cmp #$24           ; $db57: c9 24     
            bne __db61         ; $db59: d0 06     
            lda $1e,x          ; $db5b: b5 1e     
            tax                ; $db5d: aa        
            jsr __db61         ; $db5e: 20 61 db  
__db61:     jsr __dc43         ; $db61: 20 43 dc  
            bcs __db7a         ; $db64: b0 14     
            txa                ; $db66: 8a        
            jsr __dc56         ; $db67: 20 56 dc  
            lda $cf,x          ; $db6a: b5 cf     
            sta $00            ; $db6c: 85 00     
            txa                ; $db6e: 8a        
            pha                ; $db6f: 48        
            jsr __e32d         ; $db70: 20 2d e3  
            pla                ; $db73: 68        
            tax                ; $db74: aa        
            bcc __db7a         ; $db75: 90 03     
            jsr __dbbe         ; $db77: 20 be db  
__db7a:     ldx $08            ; $db7a: a6 08     
            rts                ; $db7c: 60        

;-------------------------------------------------------------------------------
__db7d:     lda $0747          ; $db7d: ad 47 07  
            bne __dbb9         ; $db80: d0 37     
            sta $03a2,x        ; $db82: 9d a2 03  
            jsr __dc43         ; $db85: 20 43 dc  
            bcs __dbb9         ; $db88: b0 2f     
            lda #$02           ; $db8a: a9 02     
            sta $00            ; $db8c: 85 00     
__db8e:     ldx $08            ; $db8e: a6 08     
            jsr __dc54         ; $db90: 20 54 dc  
            and #$02           ; $db93: 29 02     
            bne __dbb9         ; $db95: d0 22     
            lda $04ad,y        ; $db97: b9 ad 04  
            cmp #$20           ; $db9a: c9 20     
            bcc __dba3         ; $db9c: 90 05     
            jsr __e32d         ; $db9e: 20 2d e3  
            bcs __dbbc         ; $dba1: b0 19     
__dba3:     lda $04ad,y        ; $dba3: b9 ad 04  
            clc                ; $dba6: 18        
            adc #$80           ; $dba7: 69 80     
            sta $04ad,y        ; $dba9: 99 ad 04  
            lda $04af,y        ; $dbac: b9 af 04  
            clc                ; $dbaf: 18        
            adc #$80           ; $dbb0: 69 80     
            sta $04af,y        ; $dbb2: 99 af 04  
            dec $00            ; $dbb5: c6 00     
            bne __db8e         ; $dbb7: d0 d5     
__dbb9:     ldx $08            ; $dbb9: a6 08     
            rts                ; $dbbb: 60        

;-------------------------------------------------------------------------------
__dbbc:     ldx $08            ; $dbbc: a6 08     
__dbbe:     lda $04af,y        ; $dbbe: b9 af 04  
            sec                ; $dbc1: 38        
            sbc $04ad          ; $dbc2: ed ad 04  
            cmp #$04           ; $dbc5: c9 04     
            bcs __dbd1         ; $dbc7: b0 08     
            lda $9f            ; $dbc9: a5 9f     
            bpl __dbd1         ; $dbcb: 10 04     
            lda #$01           ; $dbcd: a9 01     
            sta $9f            ; $dbcf: 85 9f     
__dbd1:     lda $04af          ; $dbd1: ad af 04  
            sec                ; $dbd4: 38        
            sbc $04ad,y        ; $dbd5: f9 ad 04  
            cmp #$06           ; $dbd8: c9 06     
            bcs __dbf7         ; $dbda: b0 1b     
            lda $9f            ; $dbdc: a5 9f     
            bmi __dbf7         ; $dbde: 30 17     
            lda $00            ; $dbe0: a5 00     
            ldy $16,x          ; $dbe2: b4 16     
            cpy #$2b           ; $dbe4: c0 2b     
            beq __dbed         ; $dbe6: f0 05     
            cpy #$2c           ; $dbe8: c0 2c     
            beq __dbed         ; $dbea: f0 01     
            txa                ; $dbec: 8a        
__dbed:     ldx $08            ; $dbed: a6 08     
            sta $03a2,x        ; $dbef: 9d a2 03  
            lda #$00           ; $dbf2: a9 00     
            sta $1d            ; $dbf4: 85 1d     
            rts                ; $dbf6: 60        

;-------------------------------------------------------------------------------
__dbf7:     lda #$01           ; $dbf7: a9 01     
            sta $00            ; $dbf9: 85 00     
            lda $04ae          ; $dbfb: ad ae 04  
            sec                ; $dbfe: 38        
            sbc $04ac,y        ; $dbff: f9 ac 04  
            .hex c9            ; $dc02: c9        Suspected data
__dc03:     php                ; $dc03: 08        
            bcc __dc13         ; $dc04: 90 0d     
            inc $00            ; $dc06: e6 00     
            lda $04ae,y        ; $dc08: b9 ae 04  
            clc                ; $dc0b: 18        
            sbc $04ac          ; $dc0c: ed ac 04  
            cmp #$09           ; $dc0f: c9 09     
            bcs __dc16         ; $dc11: b0 03     
__dc13:     jsr __df53         ; $dc13: 20 53 df  
__dc16:     ldx $08            ; $dc16: a6 08     
__dc18:     rts                ; $dc18: 60        

;-------------------------------------------------------------------------------
            .hex 80 00         ; $dc19: 80 00     Invalid Opcode - NOP #$00
__dc1b:     tay                ; $dc1b: a8        
            lda $cf,x          ; $dc1c: b5 cf     
            clc                ; $dc1e: 18        
            adc __dc18,y       ; $dc1f: 79 18 dc  
            .hex 2c            ; $dc22: 2c        Suspected data
__dc23:     lda $cf,x          ; $dc23: b5 cf     
            ldy $0e            ; $dc25: a4 0e     
            cpy #$0b           ; $dc27: c0 0b     
            beq __dc42         ; $dc29: f0 17     
            ldy $b6,x          ; $dc2b: b4 b6     
            cpy #$01           ; $dc2d: c0 01     
            bne __dc42         ; $dc2f: d0 11     
            sec                ; $dc31: 38        
            sbc #$20           ; $dc32: e9 20     
            sta $ce            ; $dc34: 85 ce     
            tya                ; $dc36: 98        
            sbc #$00           ; $dc37: e9 00     
            sta $b5            ; $dc39: 85 b5     
            lda #$00           ; $dc3b: a9 00     
            sta $9f            ; $dc3d: 85 9f     
            sta $0433          ; $dc3f: 8d 33 04  
__dc42:     rts                ; $dc42: 60        

;-------------------------------------------------------------------------------
__dc43:     lda $03d0          ; $dc43: ad d0 03  
            cmp #$f0           ; $dc46: c9 f0     
            bcs __dc53         ; $dc48: b0 09     
            ldy $b5            ; $dc4a: a4 b5     
            dey                ; $dc4c: 88        
            bne __dc53         ; $dc4d: d0 04     
            lda $ce            ; $dc4f: a5 ce     
            cmp #$d0           ; $dc51: c9 d0     
__dc53:     rts                ; $dc53: 60        

;-------------------------------------------------------------------------------
__dc54:     lda $08            ; $dc54: a5 08     
__dc56:     asl                ; $dc56: 0a        
            asl                ; $dc57: 0a        
            clc                ; $dc58: 18        
            adc #$04           ; $dc59: 69 04     
            tay                ; $dc5b: a8        
            lda $03d1          ; $dc5c: ad d1 03  
            and #$0f           ; $dc5f: 29 0f     
            cmp #$0f           ; $dc61: c9 0f     
            rts                ; $dc63: 60        

;-------------------------------------------------------------------------------
__dc64:     .hex 20 10         ; $dc64: 20 10     Suspected data
__dc66:     lda $0716          ; $dc66: ad 16 07  
            bne __dc99         ; $dc69: d0 2e     
            lda $0e            ; $dc6b: a5 0e     
            cmp #$0b           ; $dc6d: c9 0b     
            beq __dc99         ; $dc6f: f0 28     
            cmp #$04           ; $dc71: c9 04     
            bcc __dc99         ; $dc73: 90 24     
            lda #$01           ; $dc75: a9 01     
            ldy $0704          ; $dc77: ac 04 07  
            bne __dc86         ; $dc7a: d0 0a     
            lda $1d            ; $dc7c: a5 1d     
            beq __dc84         ; $dc7e: f0 04     
            cmp #$03           ; $dc80: c9 03     
            bne __dc88         ; $dc82: d0 04     
__dc84:     lda #$02           ; $dc84: a9 02     
__dc86:     sta $1d            ; $dc86: 85 1d     
__dc88:     lda $b5            ; $dc88: a5 b5     
            cmp #$01           ; $dc8a: c9 01     
            bne __dc99         ; $dc8c: d0 0b     
            lda #$ff           ; $dc8e: a9 ff     
            sta $0490          ; $dc90: 8d 90 04  
            lda $ce            ; $dc93: a5 ce     
            cmp #$cf           ; $dc95: c9 cf     
            bcc __dc9a         ; $dc97: 90 01     
__dc99:     rts                ; $dc99: 60        

;-------------------------------------------------------------------------------
__dc9a:     ldy #$02           ; $dc9a: a0 02     
            lda $0714          ; $dc9c: ad 14 07  
            bne __dcad         ; $dc9f: d0 0c     
            lda $0754          ; $dca1: ad 54 07  
            bne __dcad         ; $dca4: d0 07     
            dey                ; $dca6: 88        
            lda $0704          ; $dca7: ad 04 07  
            bne __dcad         ; $dcaa: d0 01     
            dey                ; $dcac: 88        
__dcad:     lda __e3b5,y       ; $dcad: b9 b5 e3  
            sta $eb            ; $dcb0: 85 eb     
            tay                ; $dcb2: a8        
            ldx $0754          ; $dcb3: ae 54 07  
            lda $0714          ; $dcb6: ad 14 07  
            beq __dcbc         ; $dcb9: f0 01     
            inx                ; $dcbb: e8        
__dcbc:     lda $ce            ; $dcbc: a5 ce     
            cmp __dc64,x       ; $dcbe: dd 64 dc  
            bcc __dcfe         ; $dcc1: 90 3b     
            jsr __e3f1         ; $dcc3: 20 f1 e3  
            beq __dcfe         ; $dcc6: f0 36     
            jsr __dfa9         ; $dcc8: 20 a9 df  
            bcs __dd22         ; $dccb: b0 55     
            ldy $9f            ; $dccd: a4 9f     
            bpl __dcfe         ; $dccf: 10 2d     
            ldy $04            ; $dcd1: a4 04     
            cpy #$04           ; $dcd3: c0 04     
            bcc __dcfe         ; $dcd5: 90 27     
            jsr __df97         ; $dcd7: 20 97 df  
            bcs __dcec         ; $dcda: b0 10     
            ldy $074e          ; $dcdc: ac 4e 07  
            beq __dcf4         ; $dcdf: f0 13     
            ldy $0784          ; $dce1: ac 84 07  
            bne __dcf4         ; $dce4: d0 0e     
            jsr __bcf2         ; $dce6: 20 f2 bc  
            jmp __dcfe         ; $dce9: 4c fe dc  

;-------------------------------------------------------------------------------
__dcec:     cmp #$26           ; $dcec: c9 26     
            beq __dcf4         ; $dcee: f0 04     
            lda #$02           ; $dcf0: a9 02     
            sta $ff            ; $dcf2: 85 ff     
__dcf4:     ldy #$01           ; $dcf4: a0 01     
            lda $074e          ; $dcf6: ad 4e 07  
            bne __dcfc         ; $dcf9: d0 01     
            dey                ; $dcfb: 88        
__dcfc:     sty $9f            ; $dcfc: 84 9f     
__dcfe:     ldy $eb            ; $dcfe: a4 eb     
            lda $ce            ; $dd00: a5 ce     
            cmp #$cf           ; $dd02: c9 cf     
            bcs __dd66         ; $dd04: b0 60     
            jsr __e3f0         ; $dd06: 20 f0 e3  
            jsr __dfa9         ; $dd09: 20 a9 df  
            bcs __dd22         ; $dd0c: b0 14     
            pha                ; $dd0e: 48        
            jsr __e3f0         ; $dd0f: 20 f0 e3  
            sta $00            ; $dd12: 85 00     
            pla                ; $dd14: 68        
            sta $01            ; $dd15: 85 01     
            bne __dd25         ; $dd17: d0 0c     
            lda $00            ; $dd19: a5 00     
            beq __dd66         ; $dd1b: f0 49     
            jsr __dfa9         ; $dd1d: 20 a9 df  
            bcc __dd25         ; $dd20: 90 03     
__dd22:     jmp __de0d         ; $dd22: 4c 0d de  

;-------------------------------------------------------------------------------
__dd25:     jsr __dfa2         ; $dd25: 20 a2 df  
            bcs __dd66         ; $dd28: b0 3c     
            ldy $9f            ; $dd2a: a4 9f     
            bmi __dd66         ; $dd2c: 30 38     
            cmp #$c5           ; $dd2e: c9 c5     
            bne __dd35         ; $dd30: d0 03     
            jmp __de16         ; $dd32: 4c 16 de  

;-------------------------------------------------------------------------------
__dd35:     jsr __dec5         ; $dd35: 20 c5 de  
            beq __dd66         ; $dd38: f0 2c     
            ldy $070e          ; $dd3a: ac 0e 07  
__dd3d:     bne __dd62         ; $dd3d: d0 23     
            ldy $04            ; $dd3f: a4 04     
            cpy #$06           ; $dd41: c0 06     
            bcc __dd4c         ; $dd43: 90 07     
            lda $45            ; $dd45: a5 45     
            sta $00            ; $dd47: 85 00     
            jmp __df53         ; $dd49: 4c 53 df  

;-------------------------------------------------------------------------------
__dd4c:     jsr __decc         ; $dd4c: 20 cc de  
            lda #$f0           ; $dd4f: a9 f0     
            and $ce            ; $dd51: 25 ce     
            sta $ce            ; $dd53: 85 ce     
            jsr __def0         ; $dd55: 20 f0 de  
            lda #$00           ; $dd58: a9 00     
            sta $9f            ; $dd5a: 85 9f     
            sta $0433          ; $dd5c: 8d 33 04  
            sta $0484          ; $dd5f: 8d 84 04  
__dd62:     lda #$00           ; $dd62: a9 00     
            sta $1d            ; $dd64: 85 1d     
__dd66:     ldy $eb            ; $dd66: a4 eb     
            iny                ; $dd68: c8        
            iny                ; $dd69: c8        
            lda #$02           ; $dd6a: a9 02     
            sta $00            ; $dd6c: 85 00     
__dd6e:     iny                ; $dd6e: c8        
            sty $eb            ; $dd6f: 84 eb     
            lda $ce            ; $dd71: a5 ce     
            cmp #$20           ; $dd73: c9 20     
            bcc __dd8d         ; $dd75: 90 16     
            cmp #$e4           ; $dd77: c9 e4     
            bcs __dda3         ; $dd79: b0 28     
            jsr __e3f4         ; $dd7b: 20 f4 e3  
            beq __dd8d         ; $dd7e: f0 0d     
            cmp #$1c           ; $dd80: c9 1c     
            beq __dd8d         ; $dd82: f0 09     
            cmp #$6b           ; $dd84: c9 6b     
            beq __dd8d         ; $dd86: f0 05     
            jsr __dfa2         ; $dd88: 20 a2 df  
            bcc __dda4         ; $dd8b: 90 17     
__dd8d:     ldy $eb            ; $dd8d: a4 eb     
            iny                ; $dd8f: c8        
__dd90:     lda $ce            ; $dd90: a5 ce     
            cmp #$08           ; $dd92: c9 08     
            bcc __dda3         ; $dd94: 90 0d     
            cmp #$d0           ; $dd96: c9 d0     
            bcs __dda3         ; $dd98: b0 09     
            jsr __e3f4         ; $dd9a: 20 f4 e3  
            bne __dda4         ; $dd9d: d0 05     
            dec $00            ; $dd9f: c6 00     
            bne __dd6e         ; $dda1: d0 cb     
__dda3:     rts                ; $dda3: 60        

;-------------------------------------------------------------------------------
__dda4:     jsr __dec5         ; $dda4: 20 c5 de  
            beq __de0a         ; $dda7: f0 61     
            jsr __dfa2         ; $dda9: 20 a2 df  
            bcc __ddb1         ; $ddac: 90 03     
            jmp __de36         ; $ddae: 4c 36 de  

;-------------------------------------------------------------------------------
__ddb1:     jsr __dfa9         ; $ddb1: 20 a9 df  
            bcs __de0d         ; $ddb4: b0 57     
            jsr __dee5         ; $ddb6: 20 e5 de  
            bcc __ddc3         ; $ddb9: 90 08     
            lda $070e          ; $ddbb: ad 0e 07  
            bne __de0a         ; $ddbe: d0 4a     
            jmp __de07         ; $ddc0: 4c 07 de  

;-------------------------------------------------------------------------------
__ddc3:     ldy $1d            ; $ddc3: a4 1d     
            cpy #$00           ; $ddc5: c0 00     
            bne __de07         ; $ddc7: d0 3e     
            ldy $33            ; $ddc9: a4 33     
            dey                ; $ddcb: 88        
            bne __de07         ; $ddcc: d0 39     
            cmp #$6c           ; $ddce: c9 6c     
            beq __ddd6         ; $ddd0: f0 04     
            cmp #$1f           ; $ddd2: c9 1f     
            .hex d0            ; $ddd4: d0        Suspected data
__ddd5:     .hex 31            ; $ddd5: 31        Suspected data
__ddd6:     lda $03c4          ; $ddd6: ad c4 03  
            bne __dddf         ; $ddd9: d0 04     
            ldy #$10           ; $dddb: a0 10     
            sty $ff            ; $dddd: 84 ff     
__dddf:     ora #$20           ; $dddf: 09 20     
            sta $03c4          ; $dde1: 8d c4 03  
            lda $86            ; $dde4: a5 86     
            and #$0f           ; $dde6: 29 0f     
            beq __ddf8         ; $dde8: f0 0e     
            ldy #$00           ; $ddea: a0 00     
            lda $071a          ; $ddec: ad 1a 07  
            beq __ddf2         ; $ddef: f0 01     
            iny                ; $ddf1: c8        
__ddf2:     lda __de0b,y       ; $ddf2: b9 0b de  
            sta $06de          ; $ddf5: 8d de 06  
__ddf8:     lda $0e            ; $ddf8: a5 0e     
            cmp #$07           ; $ddfa: c9 07     
            beq __de0a         ; $ddfc: f0 0c     
            cmp #$08           ; $ddfe: c9 08     
            .hex d0            ; $de00: d0        Suspected data
__de01:     php                ; $de01: 08        
            lda #$02           ; $de02: a9 02     
            sta $0e            ; $de04: 85 0e     
            rts                ; $de06: 60        

;-------------------------------------------------------------------------------
__de07:     jsr __df53         ; $de07: 20 53 df  
__de0a:     rts                ; $de0a: 60        

;-------------------------------------------------------------------------------
__de0b:     sta $2b            ; $de0b: 85 2b     
__de0d:     jsr __de24         ; $de0d: 20 24 de  
            inc $0748          ; $de10: ee 48 07  
            jmp __bc03         ; $de13: 4c 03 bc  

;-------------------------------------------------------------------------------
__de16:     lda #$00           ; $de16: a9 00     
            sta $0772          ; $de18: 8d 72 07  
            lda #$02           ; $de1b: a9 02     
            sta $0770          ; $de1d: 8d 70 07  
            lda #$18           ; $de20: a9 18     
            sta $57            ; $de22: 85 57     
__de24:     ldy $02            ; $de24: a4 02     
            lda #$00           ; $de26: a9 00     
            sta ($06),y        ; $de28: 91 06     
            .hex 4c 4d         ; $de2a: 4c 4d     Suspected data
__de2c:     txa                ; $de2c: 8a        
            .hex f9            ; $de2d: f9        Suspected data
__de2e:     .hex 07 ff         ; $de2e: 07 ff     Invalid Opcode - SLO $ff
            brk                ; $de30: 00        
__de31:     clc                ; $de31: 18        
            .hex 22            ; $de32: 22        Invalid Opcode - KIL 
            bvc __de9d         ; $de33: 50 68     
            .hex 90            ; $de35: 90        Suspected data
__de36:     ldy $04            ; $de36: a4 04     
            cpy #$06           ; $de38: c0 06     
            bcc __de40         ; $de3a: 90 04     
            cpy #$0a           ; $de3c: c0 0a     
            bcc __de41         ; $de3e: 90 01     
__de40:     rts                ; $de40: 60        

;-------------------------------------------------------------------------------
__de41:     cmp #$24           ; $de41: c9 24     
            beq __de49         ; $de43: f0 04     
            cmp #$25           ; $de45: c9 25     
            bne __de82         ; $de47: d0 39     
__de49:     lda $0e            ; $de49: a5 0e     
            cmp #$05           ; $de4b: c9 05     
            beq __de90         ; $de4d: f0 41     
            lda #$01           ; $de4f: a9 01     
            sta $33            ; $de51: 85 33     
            inc $0723          ; $de53: ee 23 07  
            lda $0e            ; $de56: a5 0e     
            cmp #$04           ; $de58: c9 04     
            beq __de7b         ; $de5a: f0 1f     
            lda #$33           ; $de5c: a9 33     
            jsr __9716         ; $de5e: 20 16 97  
            lda #$80           ; $de61: a9 80     
            sta $fc            ; $de63: 85 fc     
            lsr                ; $de65: 4a        
            sta $0713          ; $de66: 8d 13 07  
            ldx #$04           ; $de69: a2 04     
            lda $ce            ; $de6b: a5 ce     
            sta $070f          ; $de6d: 8d 0f 07  
__de70:     cmp __de31,x       ; $de70: dd 31 de  
            bcs __de78         ; $de73: b0 03     
            dex                ; $de75: ca        
            bne __de70         ; $de76: d0 f8     
__de78:     stx $010f          ; $de78: 8e 0f 01  
__de7b:     lda #$04           ; $de7b: a9 04     
            sta $0e            ; $de7d: 85 0e     
            jmp __de90         ; $de7f: 4c 90 de  

;-------------------------------------------------------------------------------
__de82:     cmp #$26           ; $de82: c9 26     
            bne __de90         ; $de84: d0 0a     
            lda $ce            ; $de86: a5 ce     
            cmp #$20           ; $de88: c9 20     
            bcs __de90         ; $de8a: b0 04     
            lda #$01           ; $de8c: a9 01     
            sta $0e            ; $de8e: 85 0e     
__de90:     lda #$03           ; $de90: a9 03     
            sta $1d            ; $de92: 85 1d     
            lda #$00           ; $de94: a9 00     
            sta $57            ; $de96: 85 57     
            sta $0705          ; $de98: 8d 05 07  
            lda $86            ; $de9b: a5 86     
__de9d:     sec                ; $de9d: 38        
            sbc $071c          ; $de9e: ed 1c 07  
            cmp #$10           ; $dea1: c9 10     
            bcs __dea9         ; $dea3: b0 04     
            lda #$02           ; $dea5: a9 02     
            sta $33            ; $dea7: 85 33     
__dea9:     ldy $33            ; $dea9: a4 33     
            lda $06            ; $deab: a5 06     
            asl                ; $dead: 0a        
            asl                ; $deae: 0a        
            asl                ; $deaf: 0a        
            asl                ; $deb0: 0a        
            clc                ; $deb1: 18        
            adc __de2c,y       ; $deb2: 79 2c de  
            sta $86            ; $deb5: 85 86     
            lda $06            ; $deb7: a5 06     
            bne __dec4         ; $deb9: d0 09     
            lda $071b          ; $debb: ad 1b 07  
            clc                ; $debe: 18        
            adc __de2e,y       ; $debf: 79 2e de  
            sta $6d            ; $dec2: 85 6d     
__dec4:     rts                ; $dec4: 60        

;-------------------------------------------------------------------------------
__dec5:     cmp #$5f           ; $dec5: c9 5f     
            beq __decb         ; $dec7: f0 02     
            .hex c9            ; $dec9: c9        Suspected data
__deca:     rts                ; $deca: 60        

;-------------------------------------------------------------------------------
__decb:     rts                ; $decb: 60        

;-------------------------------------------------------------------------------
__decc:     jsr __dee5         ; $decc: 20 e5 de  
            bcc __dee4         ; $decf: 90 13     
            lda #$70           ; $ded1: a9 70     
            sta $0709          ; $ded3: 8d 09 07  
            lda #$f8           ; $ded6: a9 f8     
            sta $06db          ; $ded8: 8d db 06  
            lda #$03           ; $dedb: a9 03     
            .hex 8d            ; $dedd: 8d        Suspected data
__dede:     stx $07            ; $dede: 86 07     
            lsr                ; $dee0: 4a        
            sta $070e          ; $dee1: 8d 0e 07  
__dee4:     rts                ; $dee4: 60        

;-------------------------------------------------------------------------------
__dee5:     cmp #$67           ; $dee5: c9 67     
            beq __deee         ; $dee7: f0 05     
            cmp #$68           ; $dee9: c9 68     
            clc                ; $deeb: 18        
            bne __deef         ; $deec: d0 01     
__deee:     sec                ; $deee: 38        
__deef:     rts                ; $deef: 60        

;-------------------------------------------------------------------------------
__def0:     lda $0b            ; $def0: a5 0b     
            and #$04           ; $def2: 29 04     
            beq __df52         ; $def4: f0 5c     
            lda $00            ; $def6: a5 00     
            cmp #$11           ; $def8: c9 11     
            bne __df52         ; $defa: d0 56     
            lda $01            ; $defc: a5 01     
            cmp #$10           ; $defe: c9 10     
            bne __df52         ; $df00: d0 50     
            lda #$28           ; $df02: a9 28     
            sta $06de          ; $df04: 8d de 06  
            lda #$03           ; $df07: a9 03     
            sta $0e            ; $df09: 85 0e     
            lda #$10           ; $df0b: a9 10     
            sta $ff            ; $df0d: 85 ff     
__df0f:     lda #$20           ; $df0f: a9 20     
            sta $03c4          ; $df11: 8d c4 03  
            lda $06d6          ; $df14: ad d6 06  
            beq __df52         ; $df17: f0 39     
            and #$03           ; $df19: 29 03     
            asl                ; $df1b: 0a        
            asl                ; $df1c: 0a        
            tax                ; $df1d: aa        
            lda $86            ; $df1e: a5 86     
            cmp #$60           ; $df20: c9 60     
            bcc __df2a         ; $df22: 90 06     
            inx                ; $df24: e8        
            cmp #$a0           ; $df25: c9 a0     
            bcc __df2a         ; $df27: 90 01     
            inx                ; $df29: e8        
__df2a:     ldy __87f2,x       ; $df2a: bc f2 87  
            dey                ; $df2d: 88        
            sty $075f          ; $df2e: 8c 5f 07  
            ldx __9cb4,y       ; $df31: be b4 9c  
            lda __9cbc,x       ; $df34: bd bc 9c  
            sta $0750          ; $df37: 8d 50 07  
            lda #$80           ; $df3a: a9 80     
            sta $fc            ; $df3c: 85 fc     
            lda #$00           ; $df3e: a9 00     
            sta $0751          ; $df40: 8d 51 07  
            sta $0760          ; $df43: 8d 60 07  
            sta $075c          ; $df46: 8d 5c 07  
            sta $0752          ; $df49: 8d 52 07  
            inc $075d          ; $df4c: ee 5d 07  
            inc $0757          ; $df4f: ee 57 07  
__df52:     rts                ; $df52: 60        

;-------------------------------------------------------------------------------
__df53:     lda #$00           ; $df53: a9 00     
            ldy $57            ; $df55: a4 57     
            ldx $00            ; $df57: a6 00     
            dex                ; $df59: ca        
            bne __df66         ; $df5a: d0 0a     
            inx                ; $df5c: e8        
            cpy #$00           ; $df5d: c0 00     
            bmi __df89         ; $df5f: 30 28     
            lda #$ff           ; $df61: a9 ff     
            jmp __df6e         ; $df63: 4c 6e df  

;-------------------------------------------------------------------------------
__df66:     ldx #$02           ; $df66: a2 02     
            cpy #$01           ; $df68: c0 01     
            bpl __df89         ; $df6a: 10 1d     
            lda #$01           ; $df6c: a9 01     
__df6e:     ldy #$10           ; $df6e: a0 10     
            sty $0785          ; $df70: 8c 85 07  
            ldy #$00           ; $df73: a0 00     
            sty $57            ; $df75: 84 57     
            cmp #$00           ; $df77: c9 00     
            bpl __df7c         ; $df79: 10 01     
            dey                ; $df7b: 88        
__df7c:     sty $00            ; $df7c: 84 00     
            clc                ; $df7e: 18        
            adc $86            ; $df7f: 65 86     
            sta $86            ; $df81: 85 86     
            lda $6d            ; $df83: a5 6d     
            adc $00            ; $df85: 65 00     
            sta $6d            ; $df87: 85 6d     
__df89:     txa                ; $df89: 8a        
            eor #$ff           ; $df8a: 49 ff     
            and $0490          ; $df8c: 2d 90 04  
            sta $0490          ; $df8f: 8d 90 04  
            rts                ; $df92: 60        

;-------------------------------------------------------------------------------
__df93:     bpl __dff6         ; $df93: 10 61     
            dey                ; $df95: 88        
            .hex c4            ; $df96: c4        Suspected data
__df97:     jsr __dfb8         ; $df97: 20 b8 df  
            cmp __df93,x       ; $df9a: dd 93 df  
            rts                ; $df9d: 60        

;-------------------------------------------------------------------------------
__df9e:     bit $6d            ; $df9e: 24 6d     
            txa                ; $dfa0: 8a        
            .hex c6            ; $dfa1: c6        Suspected data
__dfa2:     jsr __dfb8         ; $dfa2: 20 b8 df  
            cmp __df9e,x       ; $dfa5: dd 9e df  
            rts                ; $dfa8: 60        

;-------------------------------------------------------------------------------
__dfa9:     cmp #$c2           ; $dfa9: c9 c2     
            beq __dfb3         ; $dfab: f0 06     
            cmp #$c3           ; $dfad: c9 c3     
            beq __dfb3         ; $dfaf: f0 02     
            clc                ; $dfb1: 18        
            rts                ; $dfb2: 60        

;-------------------------------------------------------------------------------
__dfb3:     lda #$01           ; $dfb3: a9 01     
            sta $fe            ; $dfb5: 85 fe     
            rts                ; $dfb7: 60        

;-------------------------------------------------------------------------------
__dfb8:     tay                ; $dfb8: a8        
__dfb9:     and #$c0           ; $dfb9: 29 c0     
            asl                ; $dfbb: 0a        
            rol                ; $dfbc: 2a        
            rol                ; $dfbd: 2a        
            tax                ; $dfbe: aa        
            tya                ; $dfbf: 98        
__dfc0:     rts                ; $dfc0: 60        

;-------------------------------------------------------------------------------
__dfc1:     ora ($01,x)        ; $dfc1: 01 01     
            .hex 02            ; $dfc3: 02        Invalid Opcode - KIL 
            .hex 02            ; $dfc4: 02        Invalid Opcode - KIL 
            .hex 02            ; $dfc5: 02        Invalid Opcode - KIL 
            .hex 05            ; $dfc6: 05        Suspected data
__dfc7:     bpl __dfb9         ; $dfc7: 10 f0     
__dfc9:     lda $1e,x          ; $dfc9: b5 1e     
            and #$20           ; $dfcb: 29 20     
            bne __dfc0         ; $dfcd: d0 f1     
            jsr __e163         ; $dfcf: 20 63 e1  
            bcc __dfc0         ; $dfd2: 90 ec     
            ldy $16,x          ; $dfd4: b4 16     
            cpy #$12           ; $dfd6: c0 12     
            bne __dfe0         ; $dfd8: d0 06     
            lda $cf,x          ; $dfda: b5 cf     
            cmp #$25           ; $dfdc: c9 25     
            bcc __dfc0         ; $dfde: 90 e0     
__dfe0:     cpy #$0e           ; $dfe0: c0 0e     
            bne __dfe7         ; $dfe2: d0 03     
            jmp __e16b         ; $dfe4: 4c 6b e1  

;-------------------------------------------------------------------------------
__dfe7:     cpy #$05           ; $dfe7: c0 05     
            bne __dfee         ; $dfe9: d0 03     
            jmp __e18d         ; $dfeb: 4c 8d e1  

;-------------------------------------------------------------------------------
__dfee:     cpy #$12           ; $dfee: c0 12     
            beq __dffa         ; $dff0: f0 08     
            cpy #$2e           ; $dff2: c0 2e     
            beq __dffa         ; $dff4: f0 04     
__dff6:     cpy #$07           ; $dff6: c0 07     
            bcs __e06e         ; $dff8: b0 74     
__dffa:     jsr __e1b6         ; $dffa: 20 b6 e1  
            bne __e002         ; $dffd: d0 03     
__dfff:     jmp __e0ea         ; $dfff: 4c ea e0  

;-------------------------------------------------------------------------------
__e002:     jsr __e1bd         ; $e002: 20 bd e1  
            beq __dfff         ; $e005: f0 f8     
            cmp #$23           ; $e007: c9 23     
            bne __e06f         ; $e009: d0 64     
            ldy $02            ; $e00b: a4 02     
            lda #$00           ; $e00d: a9 00     
            sta ($06),y        ; $e00f: 91 06     
            lda $16,x          ; $e011: b5 16     
            cmp #$15           ; $e013: c9 15     
            bcs __e023         ; $e015: b0 0c     
            cmp #$06           ; $e017: c9 06     
            bne __e01e         ; $e019: d0 03     
            jsr __e196         ; $e01b: 20 96 e1  
__e01e:     lda #$01           ; $e01e: a9 01     
            jsr __da13         ; $e020: 20 13 da  
__e023:     cmp #$09           ; $e023: c9 09     
            bcc __e037         ; $e025: 90 10     
            cmp #$11           ; $e027: c9 11     
            bcs __e037         ; $e029: b0 0c     
            cmp #$0a           ; $e02b: c9 0a     
            bcc __e033         ; $e02d: 90 04     
            cmp #$0d           ; $e02f: c9 0d     
            bcc __e037         ; $e031: 90 04     
__e033:     and #$01           ; $e033: 29 01     
            sta $16,x          ; $e035: 95 16     
__e037:     lda $1e,x          ; $e037: b5 1e     
            and #$f0           ; $e039: 29 f0     
            ora #$02           ; $e03b: 09 02     
            sta $1e,x          ; $e03d: 95 1e     
            dec $cf,x          ; $e03f: d6 cf     
            dec $cf,x          ; $e041: d6 cf     
            lda $16,x          ; $e043: b5 16     
            cmp #$07           ; $e045: c9 07     
            beq __e050         ; $e047: f0 07     
            lda #$fd           ; $e049: a9 fd     
            ldy $074e          ; $e04b: ac 4e 07  
            bne __e052         ; $e04e: d0 02     
__e050:     lda #$ff           ; $e050: a9 ff     
__e052:     sta $a0,x          ; $e052: 95 a0     
            ldy #$01           ; $e054: a0 01     
            jsr __e14b         ; $e056: 20 4b e1  
            bpl __e05c         ; $e059: 10 01     
            iny                ; $e05b: c8        
__e05c:     lda $16,x          ; $e05c: b5 16     
            cmp #$33           ; $e05e: c9 33     
            beq __e068         ; $e060: f0 06     
            cmp #$08           ; $e062: c9 08     
            beq __e068         ; $e064: f0 02     
            sty $46,x          ; $e066: 94 46     
__e068:     dey                ; $e068: 88        
            lda __dfc7,y       ; $e069: b9 c7 df  
            sta $58,x          ; $e06c: 95 58     
__e06e:     rts                ; $e06e: 60        

;-------------------------------------------------------------------------------
__e06f:     lda $04            ; $e06f: a5 04     
            sec                ; $e071: 38        
            sbc #$08           ; $e072: e9 08     
            cmp #$05           ; $e074: c9 05     
            bcs __e0ea         ; $e076: b0 72     
            lda $1e,x          ; $e078: b5 1e     
            and #$40           ; $e07a: 29 40     
            bne __e0d5         ; $e07c: d0 57     
            lda $1e,x          ; $e07e: b5 1e     
            asl                ; $e080: 0a        
            bcc __e086         ; $e081: 90 03     
__e083:     jmp __e106         ; $e083: 4c 06 e1  

;-------------------------------------------------------------------------------
__e086:     lda $1e,x          ; $e086: b5 1e     
            beq __e083         ; $e088: f0 f9     
            cmp #$05           ; $e08a: c9 05     
            beq __e0ad         ; $e08c: f0 1f     
            cmp #$03           ; $e08e: c9 03     
            bcs __e0ac         ; $e090: b0 1a     
            lda $1e,x          ; $e092: b5 1e     
            cmp #$02           ; $e094: c9 02     
            bne __e0ad         ; $e096: d0 15     
            lda #$10           ; $e098: a9 10     
            ldy $16,x          ; $e09a: b4 16     
            cpy #$12           ; $e09c: c0 12     
            bne __e0a2         ; $e09e: d0 02     
            lda #$00           ; $e0a0: a9 00     
__e0a2:     sta $0796,x        ; $e0a2: 9d 96 07  
            lda #$03           ; $e0a5: a9 03     
            sta $1e,x          ; $e0a7: 95 1e     
            jsr __e157         ; $e0a9: 20 57 e1  
__e0ac:     rts                ; $e0ac: 60        

;-------------------------------------------------------------------------------
__e0ad:     lda $16,x          ; $e0ad: b5 16     
            cmp #$06           ; $e0af: c9 06     
            beq __e0d5         ; $e0b1: f0 22     
            cmp #$12           ; $e0b3: c9 12     
            bne __e0c5         ; $e0b5: d0 0e     
            lda #$01           ; $e0b7: a9 01     
            sta $46,x          ; $e0b9: 95 46     
            lda #$08           ; $e0bb: a9 08     
            sta $58,x          ; $e0bd: 95 58     
            lda $09            ; $e0bf: a5 09     
            and #$07           ; $e0c1: 29 07     
            beq __e0d5         ; $e0c3: f0 10     
__e0c5:     ldy #$01           ; $e0c5: a0 01     
            jsr __e14b         ; $e0c7: 20 4b e1  
            bpl __e0cd         ; $e0ca: 10 01     
            iny                ; $e0cc: c8        
__e0cd:     tya                ; $e0cd: 98        
            cmp $46,x          ; $e0ce: d5 46     
            bne __e0d5         ; $e0d0: d0 03     
            jsr __e12c         ; $e0d2: 20 2c e1  
__e0d5:     jsr __e157         ; $e0d5: 20 57 e1  
            lda $1e,x          ; $e0d8: b5 1e     
            and #$80           ; $e0da: 29 80     
            bne __e0e3         ; $e0dc: d0 05     
            lda #$00           ; $e0de: a9 00     
            sta $1e,x          ; $e0e0: 95 1e     
            rts                ; $e0e2: 60        

;-------------------------------------------------------------------------------
__e0e3:     lda $1e,x          ; $e0e3: b5 1e     
            and #$bf           ; $e0e5: 29 bf     
            sta $1e,x          ; $e0e7: 95 1e     
            rts                ; $e0e9: 60        

;-------------------------------------------------------------------------------
__e0ea:     lda $16,x          ; $e0ea: b5 16     
            cmp #$03           ; $e0ec: c9 03     
            bne __e0f4         ; $e0ee: d0 04     
            lda $1e,x          ; $e0f0: b5 1e     
            beq __e12c         ; $e0f2: f0 38     
__e0f4:     lda $1e,x          ; $e0f4: b5 1e     
            tay                ; $e0f6: a8        
            asl                ; $e0f7: 0a        
            bcc __e101         ; $e0f8: 90 07     
            lda $1e,x          ; $e0fa: b5 1e     
            ora #$40           ; $e0fc: 09 40     
            jmp __e104         ; $e0fe: 4c 04 e1  

;-------------------------------------------------------------------------------
__e101:     lda __dfc1,y       ; $e101: b9 c1 df  
__e104:     sta $1e,x          ; $e104: 95 1e     
__e106:     lda $cf,x          ; $e106: b5 cf     
            cmp #$20           ; $e108: c9 20     
            bcc __e12b         ; $e10a: 90 1f     
            ldy #$16           ; $e10c: a0 16     
            lda #$02           ; $e10e: a9 02     
            sta $eb            ; $e110: 85 eb     
__e112:     lda $eb            ; $e112: a5 eb     
            cmp $46,x          ; $e114: d5 46     
            bne __e124         ; $e116: d0 0c     
            lda #$01           ; $e118: a9 01     
            jsr __e390         ; $e11a: 20 90 e3  
            beq __e124         ; $e11d: f0 05     
            jsr __e1bd         ; $e11f: 20 bd e1  
            bne __e12c         ; $e122: d0 08     
__e124:     dec $eb            ; $e124: c6 eb     
            iny                ; $e126: c8        
            cpy #$18           ; $e127: c0 18     
            bcc __e112         ; $e129: 90 e7     
__e12b:     rts                ; $e12b: 60        

;-------------------------------------------------------------------------------
__e12c:     cpx #$05           ; $e12c: e0 05     
            beq __e139         ; $e12e: f0 09     
            lda $1e,x          ; $e130: b5 1e     
            asl                ; $e132: 0a        
            bcc __e139         ; $e133: 90 04     
            lda #$02           ; $e135: a9 02     
            sta $ff            ; $e137: 85 ff     
__e139:     lda $16,x          ; $e139: b5 16     
            cmp #$05           ; $e13b: c9 05     
            bne __e148         ; $e13d: d0 09     
            lda #$00           ; $e13f: a9 00     
            sta $00            ; $e141: 85 00     
            ldy #$fa           ; $e143: a0 fa     
            jmp __ca3d         ; $e145: 4c 3d ca  

;-------------------------------------------------------------------------------
__e148:     jmp __db38         ; $e148: 4c 38 db  

;-------------------------------------------------------------------------------
__e14b:     lda $87,x          ; $e14b: b5 87     
            sec                ; $e14d: 38        
            sbc $86            ; $e14e: e5 86     
            sta $00            ; $e150: 85 00     
            lda $6e,x          ; $e152: b5 6e     
            sbc $6d            ; $e154: e5 6d     
            rts                ; $e156: 60        

;-------------------------------------------------------------------------------
__e157:     jsr __c369         ; $e157: 20 69 c3  
            lda $cf,x          ; $e15a: b5 cf     
            and #$f0           ; $e15c: 29 f0     
            ora #$08           ; $e15e: 09 08     
            sta $cf,x          ; $e160: 95 cf     
            rts                ; $e162: 60        

;-------------------------------------------------------------------------------
__e163:     lda $cf,x          ; $e163: b5 cf     
__e165:     clc                ; $e165: 18        
            adc #$3e           ; $e166: 69 3e     
            cmp #$44           ; $e168: c9 44     
            rts                ; $e16a: 60        

;-------------------------------------------------------------------------------
__e16b:     jsr __e163         ; $e16b: 20 63 e1  
            bcc __e18a         ; $e16e: 90 1a     
            lda $a0,x          ; $e170: b5 a0     
            clc                ; $e172: 18        
            adc #$02           ; $e173: 69 02     
            cmp #$03           ; $e175: c9 03     
            bcc __e18a         ; $e177: 90 11     
            jsr __e1b6         ; $e179: 20 b6 e1  
            beq __e18a         ; $e17c: f0 0c     
            jsr __e1bd         ; $e17e: 20 bd e1  
            beq __e18a         ; $e181: f0 07     
            jsr __e157         ; $e183: 20 57 e1  
            lda #$fd           ; $e186: a9 fd     
            sta $a0,x          ; $e188: 95 a0     
__e18a:     jmp __e106         ; $e18a: 4c 06 e1  

;-------------------------------------------------------------------------------
__e18d:     jsr __e1b6         ; $e18d: 20 b6 e1  
            beq __e1af         ; $e190: f0 1d     
            cmp #$23           ; $e192: c9 23     
            bne __e19e         ; $e194: d0 08     
__e196:     jsr __d795         ; $e196: 20 95 d7  
            lda #$fc           ; $e199: a9 fc     
            sta $a0,x          ; $e19b: 95 a0     
            rts                ; $e19d: 60        

;-------------------------------------------------------------------------------
__e19e:     lda $078a,x        ; $e19e: bd 8a 07  
            bne __e1af         ; $e1a1: d0 0c     
            lda $1e,x          ; $e1a3: b5 1e     
            and #$88           ; $e1a5: 29 88     
            sta $1e,x          ; $e1a7: 95 1e     
            jsr __e157         ; $e1a9: 20 57 e1  
            jmp __e106         ; $e1ac: 4c 06 e1  

;-------------------------------------------------------------------------------
__e1af:     lda $1e,x          ; $e1af: b5 1e     
            ora #$01           ; $e1b1: 09 01     
            sta $1e,x          ; $e1b3: 95 1e     
            rts                ; $e1b5: 60        

;-------------------------------------------------------------------------------
__e1b6:     lda #$00           ; $e1b6: a9 00     
            ldy #$15           ; $e1b8: a0 15     
            jmp __e390         ; $e1ba: 4c 90 e3  

;-------------------------------------------------------------------------------
__e1bd:     cmp #$26           ; $e1bd: c9 26     
            beq __e1cf         ; $e1bf: f0 0e     
            cmp #$c2           ; $e1c1: c9 c2     
            beq __e1cf         ; $e1c3: f0 0a     
            cmp #$c3           ; $e1c5: c9 c3     
            beq __e1cf         ; $e1c7: f0 06     
            cmp #$5f           ; $e1c9: c9 5f     
            beq __e1cf         ; $e1cb: f0 02     
            cmp #$60           ; $e1cd: c9 60     
__e1cf:     rts                ; $e1cf: 60        

;-------------------------------------------------------------------------------
__e1d0:     lda $d5,x          ; $e1d0: b5 d5     
            cmp #$18           ; $e1d2: c9 18     
            bcc __e1f7         ; $e1d4: 90 21     
            jsr __e3a4         ; $e1d6: 20 a4 e3  
            beq __e1f7         ; $e1d9: f0 1c     
            jsr __e1bd         ; $e1db: 20 bd e1  
            beq __e1f7         ; $e1de: f0 17     
            lda $a6,x          ; $e1e0: b5 a6     
            bmi __e1fc         ; $e1e2: 30 18     
            lda $3a,x          ; $e1e4: b5 3a     
            bne __e1fc         ; $e1e6: d0 14     
            lda #$fd           ; $e1e8: a9 fd     
            sta $a6,x          ; $e1ea: 95 a6     
            lda #$01           ; $e1ec: a9 01     
            sta $3a,x          ; $e1ee: 95 3a     
            lda $d5,x          ; $e1f0: b5 d5     
            and #$f8           ; $e1f2: 29 f8     
            sta $d5,x          ; $e1f4: 95 d5     
            rts                ; $e1f6: 60        

;-------------------------------------------------------------------------------
__e1f7:     lda #$00           ; $e1f7: a9 00     
            sta $3a,x          ; $e1f9: 95 3a     
            rts                ; $e1fb: 60        

;-------------------------------------------------------------------------------
__e1fc:     lda #$80           ; $e1fc: a9 80     
            sta $24,x          ; $e1fe: 95 24     
            lda #$02           ; $e200: a9 02     
            sta $ff            ; $e202: 85 ff     
            rts                ; $e204: 60        

;-------------------------------------------------------------------------------
__e205:     .hex 02            ; $e205: 02        Invalid Opcode - KIL 
            php                ; $e206: 08        
__e207:     asl $0320          ; $e207: 0e 20 03  
            .hex 14 0d         ; $e20a: 14 0d     Invalid Opcode - NOP $0d,x
            jsr $1402          ; $e20c: 20 02 14  
            asl $0220          ; $e20f: 0e 20 02  
            ora #$0e           ; $e212: 09 0e     
            ora $00,x          ; $e214: 15 00     
            brk                ; $e216: 00        
            clc                ; $e217: 18        
            asl $00            ; $e218: 06 00     
            brk                ; $e21a: 00        
            jsr $000d          ; $e21b: 20 0d 00  
            brk                ; $e21e: 00        
            bmi __e22e         ; $e21f: 30 0d     
            brk                ; $e221: 00        
            brk                ; $e222: 00        
            php                ; $e223: 08        
            php                ; $e224: 08        
            asl $04            ; $e225: 06 04     
            asl                ; $e227: 0a        
            php                ; $e228: 08        
            .hex 03 0c         ; $e229: 03 0c     Invalid Opcode - SLO ($0c,x)
            .hex 0d 14 00      ; $e22b: 0d 14 00  Bad Addr Mode - ORA $0014
__e22e:     .hex 02            ; $e22e: 02        Invalid Opcode - KIL 
            bpl __e246         ; $e22f: 10 15     
            .hex 04 04         ; $e231: 04 04     Invalid Opcode - NOP $04
            .hex 0c 1c         ; $e233: 0c 1c     Suspected data
__e235:     txa                ; $e235: 8a        
            clc                ; $e236: 18        
            adc #$07           ; $e237: 69 07     
            tax                ; $e239: aa        
            ldy #$02           ; $e23a: a0 02     
            bne __e245         ; $e23c: d0 07     
__e23e:     txa                ; $e23e: 8a        
            clc                ; $e23f: 18        
            adc #$09           ; $e240: 69 09     
__e242:     tax                ; $e242: aa        
            ldy #$06           ; $e243: a0 06     
__e245:     .hex 20            ; $e245: 20        Suspected data
__e246:     ldy $e2            ; $e246: a4 e2     
            jmp __e2e6         ; $e248: 4c e6 e2  

;-------------------------------------------------------------------------------
__e24b:     ldy #$48           ; $e24b: a0 48     
            sty $00            ; $e24d: 84 00     
            ldy #$44           ; $e24f: a0 44     
            jmp __e25a         ; $e251: 4c 5a e2  

;-------------------------------------------------------------------------------
__e254:     ldy #$08           ; $e254: a0 08     
            sty $00            ; $e256: 84 00     
            ldy #$04           ; $e258: a0 04     
__e25a:     lda $87,x          ; $e25a: b5 87     
            sec                ; $e25c: 38        
            sbc $071c          ; $e25d: ed 1c 07  
            sta $01            ; $e260: 85 01     
            lda $6e,x          ; $e262: b5 6e     
            sbc $071a          ; $e264: ed 1a 07  
            bmi __e26f         ; $e267: 30 06     
            ora $01            ; $e269: 05 01     
            beq __e26f         ; $e26b: f0 02     
            ldy $00            ; $e26d: a4 00     
__e26f:     tya                ; $e26f: 98        
            and $03d1          ; $e270: 2d d1 03  
            sta $03d8,x        ; $e273: 9d d8 03  
            bne __e291         ; $e276: d0 19     
            jmp __e284         ; $e278: 4c 84 e2  

;-------------------------------------------------------------------------------
__e27b:     inx                ; $e27b: e8        
            jsr __f1fd         ; $e27c: 20 fd f1  
            dex                ; $e27f: ca        
            cmp #$fe           ; $e280: c9 fe     
            bcs __e291         ; $e282: b0 0d     
__e284:     txa                ; $e284: 8a        
            clc                ; $e285: 18        
            adc #$01           ; $e286: 69 01     
            tax                ; $e288: aa        
            ldy #$01           ; $e289: a0 01     
            jsr __e2a4         ; $e28b: 20 a4 e2  
            jmp __e2e6         ; $e28e: 4c e6 e2  

;-------------------------------------------------------------------------------
__e291:     txa                ; $e291: 8a        
            asl                ; $e292: 0a        
            asl                ; $e293: 0a        
            tay                ; $e294: a8        
            lda #$ff           ; $e295: a9 ff     
            sta $04b0,y        ; $e297: 99 b0 04  
            sta $04b1,y        ; $e29a: 99 b1 04  
            sta $04b2,y        ; $e29d: 99 b2 04  
            sta $04b3,y        ; $e2a0: 99 b3 04  
            rts                ; $e2a3: 60        

;-------------------------------------------------------------------------------
__e2a4:     stx $00            ; $e2a4: 86 00     
            lda $03b8,y        ; $e2a6: b9 b8 03  
            sta $02            ; $e2a9: 85 02     
            lda $03ad,y        ; $e2ab: b9 ad 03  
            sta $01            ; $e2ae: 85 01     
            txa                ; $e2b0: 8a        
            asl                ; $e2b1: 0a        
            asl                ; $e2b2: 0a        
            pha                ; $e2b3: 48        
            tay                ; $e2b4: a8        
            lda $0499,x        ; $e2b5: bd 99 04  
            asl                ; $e2b8: 0a        
            asl                ; $e2b9: 0a        
            tax                ; $e2ba: aa        
            lda $01            ; $e2bb: a5 01     
            clc                ; $e2bd: 18        
            adc __e205,x       ; $e2be: 7d 05 e2  
            sta $04ac,y        ; $e2c1: 99 ac 04  
            lda $01            ; $e2c4: a5 01     
            clc                ; $e2c6: 18        
            adc __e207,x       ; $e2c7: 7d 07 e2  
            sta $04ae,y        ; $e2ca: 99 ae 04  
            inx                ; $e2cd: e8        
            iny                ; $e2ce: c8        
            lda $02            ; $e2cf: a5 02     
            clc                ; $e2d1: 18        
            adc __e205,x       ; $e2d2: 7d 05 e2  
            sta $04ac,y        ; $e2d5: 99 ac 04  
            lda $02            ; $e2d8: a5 02     
            clc                ; $e2da: 18        
            adc __e207,x       ; $e2db: 7d 07 e2  
            sta $04ae,y        ; $e2de: 99 ae 04  
            pla                ; $e2e1: 68        
            tay                ; $e2e2: a8        
            ldx $00            ; $e2e3: a6 00     
            rts                ; $e2e5: 60        

;-------------------------------------------------------------------------------
__e2e6:     lda $071c          ; $e2e6: ad 1c 07  
            clc                ; $e2e9: 18        
            adc #$80           ; $e2ea: 69 80     
            sta $02            ; $e2ec: 85 02     
            lda $071a          ; $e2ee: ad 1a 07  
            adc #$00           ; $e2f1: 69 00     
            sta $01            ; $e2f3: 85 01     
            lda $86,x          ; $e2f5: b5 86     
            cmp $02            ; $e2f7: c5 02     
            lda $6d,x          ; $e2f9: b5 6d     
            sbc $01            ; $e2fb: e5 01     
            bcc __e314         ; $e2fd: 90 15     
            lda $04ae,y        ; $e2ff: b9 ae 04  
            bmi __e311         ; $e302: 30 0d     
            lda #$ff           ; $e304: a9 ff     
            ldx $04ac,y        ; $e306: be ac 04  
            bmi __e30e         ; $e309: 30 03     
            sta $04ac,y        ; $e30b: 99 ac 04  
__e30e:     sta $04ae,y        ; $e30e: 99 ae 04  
__e311:     ldx $08            ; $e311: a6 08     
            rts                ; $e313: 60        

;-------------------------------------------------------------------------------
__e314:     lda $04ac,y        ; $e314: b9 ac 04  
            bpl __e32a         ; $e317: 10 11     
            cmp #$a0           ; $e319: c9 a0     
            bcc __e32a         ; $e31b: 90 0d     
            lda #$00           ; $e31d: a9 00     
            ldx $04ae,y        ; $e31f: be ae 04  
            bpl __e327         ; $e322: 10 03     
            sta $04ae,y        ; $e324: 99 ae 04  
__e327:     sta $04ac,y        ; $e327: 99 ac 04  
__e32a:     ldx $08            ; $e32a: a6 08     
            rts                ; $e32c: 60        

;-------------------------------------------------------------------------------
__e32d:     ldx #$00           ; $e32d: a2 00     
__e32f:     sty $06            ; $e32f: 84 06     
            lda #$01           ; $e331: a9 01     
            sta $07            ; $e333: 85 07     
__e335:     lda $04ac,y        ; $e335: b9 ac 04  
            cmp $04ac,x        ; $e338: dd ac 04  
            bcs __e367         ; $e33b: b0 2a     
            cmp $04ae,x        ; $e33d: dd ae 04  
            bcc __e354         ; $e340: 90 12     
            beq __e386         ; $e342: f0 42     
            lda $04ae,y        ; $e344: b9 ae 04  
            cmp $04ac,y        ; $e347: d9 ac 04  
            bcc __e386         ; $e34a: 90 3a     
            cmp $04ac,x        ; $e34c: dd ac 04  
            bcs __e386         ; $e34f: b0 35     
            ldy $06            ; $e351: a4 06     
            rts                ; $e353: 60        

;-------------------------------------------------------------------------------
__e354:     lda $04ae,x        ; $e354: bd ae 04  
            cmp $04ac,x        ; $e357: dd ac 04  
            bcc __e386         ; $e35a: 90 2a     
            lda $04ae,y        ; $e35c: b9 ae 04  
            cmp $04ac,x        ; $e35f: dd ac 04  
            bcs __e386         ; $e362: b0 22     
            ldy $06            ; $e364: a4 06     
            rts                ; $e366: 60        

;-------------------------------------------------------------------------------
__e367:     cmp $04ac,x        ; $e367: dd ac 04  
            beq __e386         ; $e36a: f0 1a     
            cmp $04ae,x        ; $e36c: dd ae 04  
            bcc __e386         ; $e36f: 90 15     
            beq __e386         ; $e371: f0 13     
            cmp $04ae,y        ; $e373: d9 ae 04  
            bcc __e382         ; $e376: 90 0a     
            beq __e382         ; $e378: f0 08     
            lda $04ae,y        ; $e37a: b9 ae 04  
            cmp $04ac,x        ; $e37d: dd ac 04  
            bcs __e386         ; $e380: b0 04     
__e382:     clc                ; $e382: 18        
            ldy $06            ; $e383: a4 06     
            rts                ; $e385: 60        

;-------------------------------------------------------------------------------
__e386:     inx                ; $e386: e8        
            iny                ; $e387: c8        
            dec $07            ; $e388: c6 07     
            bpl __e335         ; $e38a: 10 a9     
            sec                ; $e38c: 38        
            ldy $06            ; $e38d: a4 06     
            rts                ; $e38f: 60        

;-------------------------------------------------------------------------------
__e390:     pha                ; $e390: 48        
            txa                ; $e391: 8a        
            clc                ; $e392: 18        
            adc #$01           ; $e393: 69 01     
            tax                ; $e395: aa        
            pla                ; $e396: 68        
            jmp __e3ad         ; $e397: 4c ad e3  

;-------------------------------------------------------------------------------
            txa                ; $e39a: 8a        
            clc                ; $e39b: 18        
            adc #$0d           ; $e39c: 69 0d     
            tax                ; $e39e: aa        
            ldy #$1b           ; $e39f: a0 1b     
            jmp __e3ab         ; $e3a1: 4c ab e3  

;-------------------------------------------------------------------------------
__e3a4:     ldy #$1a           ; $e3a4: a0 1a     
            txa                ; $e3a6: 8a        
            clc                ; $e3a7: 18        
            adc #$07           ; $e3a8: 69 07     
            tax                ; $e3aa: aa        
__e3ab:     lda #$00           ; $e3ab: a9 00     
__e3ad:     jsr __e3f8         ; $e3ad: 20 f8 e3  
            ldx $08            ; $e3b0: a6 08     
            cmp #$00           ; $e3b2: c9 00     
            rts                ; $e3b4: 60        

;-------------------------------------------------------------------------------
__e3b5:     brk                ; $e3b5: 00        
            .hex 07 0e         ; $e3b6: 07 0e     Invalid Opcode - SLO $0e
__e3b8:     php                ; $e3b8: 08        
            .hex 03 0c         ; $e3b9: 03 0c     Invalid Opcode - SLO ($0c,x)
            .hex 02            ; $e3bb: 02        Invalid Opcode - KIL 
            .hex 02            ; $e3bc: 02        Invalid Opcode - KIL 
            ora $080d          ; $e3bd: 0d 0d 08  
            .hex 03 0c         ; $e3c0: 03 0c     Invalid Opcode - SLO ($0c,x)
            .hex 02            ; $e3c2: 02        Invalid Opcode - KIL 
            .hex 02            ; $e3c3: 02        Invalid Opcode - KIL 
            ora $080d          ; $e3c4: 0d 0d 08  
            .hex 03 0c         ; $e3c7: 03 0c     Invalid Opcode - SLO ($0c,x)
            .hex 02            ; $e3c9: 02        Invalid Opcode - KIL 
            .hex 02            ; $e3ca: 02        Invalid Opcode - KIL 
            ora $080d          ; $e3cb: 0d 0d 08  
            brk                ; $e3ce: 00        
            bpl __e3d5         ; $e3cf: 10 04     
            .hex 14 04         ; $e3d1: 14 04     Invalid Opcode - NOP $04,x
            .hex 04            ; $e3d3: 04        Suspected data
__e3d4:     .hex 04            ; $e3d4: 04        Suspected data
__e3d5:     jsr $0820          ; $e3d5: 20 20 08  
            clc                ; $e3d8: 18        
            php                ; $e3d9: 08        
            clc                ; $e3da: 18        
            .hex 02            ; $e3db: 02        Invalid Opcode - KIL 
            jsr $0820          ; $e3dc: 20 20 08  
            clc                ; $e3df: 18        
            php                ; $e3e0: 08        
            clc                ; $e3e1: 18        
            .hex 12            ; $e3e2: 12        Invalid Opcode - KIL 
            jsr $1820          ; $e3e3: 20 20 18  
            clc                ; $e3e6: 18        
            clc                ; $e3e7: 18        
            clc                ; $e3e8: 18        
            clc                ; $e3e9: 18        
            .hex 14 14         ; $e3ea: 14 14     Invalid Opcode - NOP $14,x
            asl $06            ; $e3ec: 06 06     
            php                ; $e3ee: 08        
            .hex 10            ; $e3ef: 10        Suspected data
__e3f0:     iny                ; $e3f0: c8        
__e3f1:     lda #$00           ; $e3f1: a9 00     
            .hex 2c            ; $e3f3: 2c        Suspected data
__e3f4:     lda #$01           ; $e3f4: a9 01     
            ldx #$00           ; $e3f6: a2 00     
__e3f8:     pha                ; $e3f8: 48        
            sty $04            ; $e3f9: 84 04     
            lda __e3b8,y       ; $e3fb: b9 b8 e3  
            clc                ; $e3fe: 18        
            adc $86,x          ; $e3ff: 75 86     
            sta $05            ; $e401: 85 05     
            lda $6d,x          ; $e403: b5 6d     
            .hex 69            ; $e405: 69        Suspected data
__e406:     brk                ; $e406: 00        
            and #$01           ; $e407: 29 01     
            lsr                ; $e409: 4a        
            ora $05            ; $e40a: 05 05     
            ror                ; $e40c: 6a        
            lsr                ; $e40d: 4a        
            lsr                ; $e40e: 4a        
            lsr                ; $e40f: 4a        
            jsr __9be3         ; $e410: 20 e3 9b  
            ldy $04            ; $e413: a4 04     
            lda $ce,x          ; $e415: b5 ce     
            clc                ; $e417: 18        
            adc __e3d4,y       ; $e418: 79 d4 e3  
            and #$f0           ; $e41b: 29 f0     
            sec                ; $e41d: 38        
            sbc #$20           ; $e41e: e9 20     
            sta $02            ; $e420: 85 02     
            tay                ; $e422: a8        
            lda ($06),y        ; $e423: b1 06     
            sta $03            ; $e425: 85 03     
            ldy $04            ; $e427: a4 04     
            pla                ; $e429: 68        
            bne __e431         ; $e42a: d0 05     
            lda $ce,x          ; $e42c: b5 ce     
            jmp __e433         ; $e42e: 4c 33 e4  

;-------------------------------------------------------------------------------
__e431:     lda $86,x          ; $e431: b5 86     
__e433:     and #$0f           ; $e433: 29 0f     
            sta $04            ; $e435: 85 04     
            lda $03            ; $e437: a5 03     
            rts                ; $e439: 60        

;-------------------------------------------------------------------------------
__e43a:     brk                ; $e43a: 00        
            .hex 30            ; $e43b: 30        Suspected data
__e43c:     sty $00            ; $e43c: 84 00     
            lda $03b9          ; $e43e: ad b9 03  
            clc                ; $e441: 18        
            adc __e43a,y       ; $e442: 79 3a e4  
            ldx $039a,y        ; $e445: be 9a 03  
            ldy $06e5,x        ; $e448: bc e5 06  
            sty $02            ; $e44b: 84 02     
            jsr __e4b5         ; $e44d: 20 b5 e4  
            lda $03ae          ; $e450: ad ae 03  
            sta $0203,y        ; $e453: 99 03 02  
            sta $020b,y        ; $e456: 99 0b 02  
            sta $0213,y        ; $e459: 99 13 02  
            clc                ; $e45c: 18        
            adc #$06           ; $e45d: 69 06     
            sta $0207,y        ; $e45f: 99 07 02  
            sta $020f,y        ; $e462: 99 0f 02  
            sta $0217,y        ; $e465: 99 17 02  
            lda #$21           ; $e468: a9 21     
            sta $0202,y        ; $e46a: 99 02 02  
            sta $020a,y        ; $e46d: 99 0a 02  
            sta $0212,y        ; $e470: 99 12 02  
            ora #$40           ; $e473: 09 40     
            sta $0206,y        ; $e475: 99 06 02  
            sta $020e,y        ; $e478: 99 0e 02  
            sta $0216,y        ; $e47b: 99 16 02  
            ldx #$05           ; $e47e: a2 05     
__e480:     lda #$e1           ; $e480: a9 e1     
            sta $0201,y        ; $e482: 99 01 02  
            iny                ; $e485: c8        
            iny                ; $e486: c8        
            iny                ; $e487: c8        
            iny                ; $e488: c8        
            dex                ; $e489: ca        
            bpl __e480         ; $e48a: 10 f4     
            ldy $02            ; $e48c: a4 02     
            lda $00            ; $e48e: a5 00     
            bne __e497         ; $e490: d0 05     
            lda #$e0           ; $e492: a9 e0     
            sta $0201,y        ; $e494: 99 01 02  
__e497:     ldx #$00           ; $e497: a2 00     
__e499:     lda $039d          ; $e499: ad 9d 03  
            sec                ; $e49c: 38        
            sbc $0200,y        ; $e49d: f9 00 02  
            cmp #$64           ; $e4a0: c9 64     
            bcc __e4a9         ; $e4a2: 90 05     
            lda #$f8           ; $e4a4: a9 f8     
            sta $0200,y        ; $e4a6: 99 00 02  
__e4a9:     iny                ; $e4a9: c8        
            iny                ; $e4aa: c8        
            iny                ; $e4ab: c8        
            iny                ; $e4ac: c8        
            inx                ; $e4ad: e8        
            cpx #$06           ; $e4ae: e0 06     
            bne __e499         ; $e4b0: d0 e7     
            ldy $00            ; $e4b2: a4 00     
            rts                ; $e4b4: 60        

;-------------------------------------------------------------------------------
__e4b5:     ldx #$06           ; $e4b5: a2 06     
__e4b7:     sta $0200,y        ; $e4b7: 99 00 02  
            clc                ; $e4ba: 18        
            adc #$08           ; $e4bb: 69 08     
            iny                ; $e4bd: c8        
            iny                ; $e4be: c8        
            iny                ; $e4bf: c8        
            iny                ; $e4c0: c8        
            dex                ; $e4c1: ca        
            bne __e4b7         ; $e4c2: d0 f3     
            ldy $02            ; $e4c4: a4 02     
            rts                ; $e4c6: 60        

;-------------------------------------------------------------------------------
__e4c7:     .hex 04 00         ; $e4c7: 04 00     Invalid Opcode - NOP $00
            .hex 04 00         ; $e4c9: 04 00     Invalid Opcode - NOP $00
__e4cb:     brk                ; $e4cb: 00        
            .hex 04 00         ; $e4cc: 04 00     Invalid Opcode - NOP $00
            .hex 04            ; $e4ce: 04        Suspected data
__e4cf:     brk                ; $e4cf: 00        
            php                ; $e4d0: 08        
            brk                ; $e4d1: 00        
            php                ; $e4d2: 08        
__e4d3:     php                ; $e4d3: 08        
            brk                ; $e4d4: 00        
            php                ; $e4d5: 08        
            brk                ; $e4d6: 00        
__e4d7:     .hex 80 82         ; $e4d7: 80 82     Invalid Opcode - NOP #$82
            sta ($83,x)        ; $e4d9: 81 83     
__e4db:     sta ($83,x)        ; $e4db: 81 83     
            .hex 80 82         ; $e4dd: 80 82     Invalid Opcode - NOP #$82
__e4df:     .hex 03 03         ; $e4df: 03 03     Invalid Opcode - SLO ($03,x)
            .hex c3 c3         ; $e4e1: c3 c3     Invalid Opcode - DCP ($c3,x)
__e4e3:     .hex bc            ; $e4e3: bc        Suspected data
__e4e4:     .hex f3 06         ; $e4e4: f3 06     Invalid Opcode - ISC ($06),y
            lda $0747          ; $e4e6: ad 47 07  
            bne __e4f3         ; $e4e9: d0 08     
            lda $2a,x          ; $e4eb: b5 2a     
            and #$7f           ; $e4ed: 29 7f     
            cmp #$01           ; $e4ef: c9 01     
            beq __e4f7         ; $e4f1: f0 04     
__e4f3:     ldx #$00           ; $e4f3: a2 00     
            beq __e4fe         ; $e4f5: f0 07     
__e4f7:     lda $09            ; $e4f7: a5 09     
            lsr                ; $e4f9: 4a        
            lsr                ; $e4fa: 4a        
            and #$03           ; $e4fb: 29 03     
            tax                ; $e4fd: aa        
__e4fe:     lda $03be          ; $e4fe: ad be 03  
            clc                ; $e501: 18        
            adc __e4cb,x       ; $e502: 7d cb e4  
            sta $0200,y        ; $e505: 99 00 02  
            clc                ; $e508: 18        
            adc __e4d3,x       ; $e509: 7d d3 e4  
            sta $0204,y        ; $e50c: 99 04 02  
            lda $03b3          ; $e50f: ad b3 03  
            clc                ; $e512: 18        
            adc __e4c7,x       ; $e513: 7d c7 e4  
            sta $0203,y        ; $e516: 99 03 02  
            clc                ; $e519: 18        
            adc __e4cf,x       ; $e51a: 7d cf e4  
            sta $0207,y        ; $e51d: 99 07 02  
            lda __e4d7,x       ; $e520: bd d7 e4  
            sta $0201,y        ; $e523: 99 01 02  
            lda __e4db,x       ; $e526: bd db e4  
            sta $0205,y        ; $e529: 99 05 02  
            lda __e4df,x       ; $e52c: bd df e4  
            sta $0202,y        ; $e52f: 99 02 02  
            sta $0206,y        ; $e532: 99 06 02  
            ldx $08            ; $e535: a6 08     
            lda $03d6          ; $e537: ad d6 03  
            and #$fc           ; $e53a: 29 fc     
            beq __e547         ; $e53c: f0 09     
            lda #$00           ; $e53e: a9 00     
            sta $2a,x          ; $e540: 95 2a     
__e542:     lda #$f8           ; $e542: a9 f8     
            jsr __e5c8         ; $e544: 20 c8 e5  
__e547:     rts                ; $e547: 60        

;-------------------------------------------------------------------------------
__e548:     .hex f9            ; $e548: f9        Suspected data
__e549:     bvc __e542         ; $e549: 50 f7     
            bvc __e547         ; $e54b: 50 fa     
            .hex fb f8 fb      ; $e54d: fb f8 fb  Invalid Opcode - ISC __fbf8,y
            inc $fb,x          ; $e550: f6 fb     
__e552:     ldy $06e5,x        ; $e552: bc e5 06  
            lda $03ae          ; $e555: ad ae 03  
            sta $0203,y        ; $e558: 99 03 02  
            clc                ; $e55b: 18        
            adc #$08           ; $e55c: 69 08     
            sta $0207,y        ; $e55e: 99 07 02  
            sta $020b,y        ; $e561: 99 0b 02  
            clc                ; $e564: 18        
            adc #$0c           ; $e565: 69 0c     
            sta $05            ; $e567: 85 05     
            lda $cf,x          ; $e569: b5 cf     
            jsr __e5c8         ; $e56b: 20 c8 e5  
            adc #$08           ; $e56e: 69 08     
            sta $0208,y        ; $e570: 99 08 02  
            lda $010d          ; $e573: ad 0d 01  
            sta $02            ; $e576: 85 02     
            lda #$01           ; $e578: a9 01     
            sta $03            ; $e57a: 85 03     
            sta $04            ; $e57c: 85 04     
            sta $0202,y        ; $e57e: 99 02 02  
            sta $0206,y        ; $e581: 99 06 02  
            sta $020a,y        ; $e584: 99 0a 02  
            lda #$7e           ; $e587: a9 7e     
            sta $0201,y        ; $e589: 99 01 02  
            sta $0209,y        ; $e58c: 99 09 02  
            lda #$7f           ; $e58f: a9 7f     
            sta $0205,y        ; $e591: 99 05 02  
            lda $070f          ; $e594: ad 0f 07  
            beq __e5ae         ; $e597: f0 15     
            tya                ; $e599: 98        
__e59a:     clc                ; $e59a: 18        
            adc #$0c           ; $e59b: 69 0c     
            tay                ; $e59d: a8        
            lda $010f          ; $e59e: ad 0f 01  
            asl                ; $e5a1: 0a        
            tax                ; $e5a2: aa        
            lda __e548,x       ; $e5a3: bd 48 e5  
            sta $00            ; $e5a6: 85 00     
            lda __e549,x       ; $e5a8: bd 49 e5  
            jsr __ebb9         ; $e5ab: 20 b9 eb  
__e5ae:     ldx $08            ; $e5ae: a6 08     
            ldy $06e5,x        ; $e5b0: bc e5 06  
            lda $03d1          ; $e5b3: ad d1 03  
            and #$0e           ; $e5b6: 29 0e     
            beq __e5ce         ; $e5b8: f0 14     
__e5ba:     lda #$f8           ; $e5ba: a9 f8     
__e5bc:     sta $0214,y        ; $e5bc: 99 14 02  
            sta $0210,y        ; $e5bf: 99 10 02  
__e5c2:     sta $020c,y        ; $e5c2: 99 0c 02  
__e5c5:     sta $0208,y        ; $e5c5: 99 08 02  
__e5c8:     sta $0204,y        ; $e5c8: 99 04 02  
            sta $0200,y        ; $e5cb: 99 00 02  
__e5ce:     rts                ; $e5ce: 60        

;-------------------------------------------------------------------------------
__e5cf:     ldy $06e5,x        ; $e5cf: bc e5 06  
            sty $02            ; $e5d2: 84 02     
            iny                ; $e5d4: c8        
            iny                ; $e5d5: c8        
            iny                ; $e5d6: c8        
            lda $03ae          ; $e5d7: ad ae 03  
            jsr __e4b5         ; $e5da: 20 b5 e4  
            ldx $08            ; $e5dd: a6 08     
            lda $cf,x          ; $e5df: b5 cf     
            jsr __e5c2         ; $e5e1: 20 c2 e5  
            ldy $074e          ; $e5e4: ac 4e 07  
            cpy #$03           ; $e5e7: c0 03     
            beq __e5f0         ; $e5e9: f0 05     
            ldy $06cc          ; $e5eb: ac cc 06  
            beq __e5f2         ; $e5ee: f0 02     
__e5f0:     lda #$f8           ; $e5f0: a9 f8     
__e5f2:     ldy $06e5,x        ; $e5f2: bc e5 06  
            sta $0210,y        ; $e5f5: 99 10 02  
            sta $0214,y        ; $e5f8: 99 14 02  
            lda #$5b           ; $e5fb: a9 5b     
            ldx $0743          ; $e5fd: ae 43 07  
            beq __e604         ; $e600: f0 02     
            lda #$75           ; $e602: a9 75     
__e604:     ldx $08            ; $e604: a6 08     
            iny                ; $e606: c8        
            jsr __e5bc         ; $e607: 20 bc e5  
            lda #$02           ; $e60a: a9 02     
            iny                ; $e60c: c8        
            jsr __e5bc         ; $e60d: 20 bc e5  
            inx                ; $e610: e8        
            jsr __f1fd         ; $e611: 20 fd f1  
            dex                ; $e614: ca        
            ldy $06e5,x        ; $e615: bc e5 06  
            asl                ; $e618: 0a        
            pha                ; $e619: 48        
            bcc __e621         ; $e61a: 90 05     
            lda #$f8           ; $e61c: a9 f8     
            sta $0200,y        ; $e61e: 99 00 02  
__e621:     pla                ; $e621: 68        
            asl                ; $e622: 0a        
            pha                ; $e623: 48        
            bcc __e62b         ; $e624: 90 05     
            lda #$f8           ; $e626: a9 f8     
            sta $0204,y        ; $e628: 99 04 02  
__e62b:     pla                ; $e62b: 68        
            asl                ; $e62c: 0a        
            pha                ; $e62d: 48        
            bcc __e635         ; $e62e: 90 05     
            lda #$f8           ; $e630: a9 f8     
            sta $0208,y        ; $e632: 99 08 02  
__e635:     pla                ; $e635: 68        
            asl                ; $e636: 0a        
            pha                ; $e637: 48        
            bcc __e63f         ; $e638: 90 05     
            lda #$f8           ; $e63a: a9 f8     
            sta $020c,y        ; $e63c: 99 0c 02  
__e63f:     pla                ; $e63f: 68        
            asl                ; $e640: 0a        
            pha                ; $e641: 48        
            bcc __e649         ; $e642: 90 05     
            lda #$f8           ; $e644: a9 f8     
            sta $0210,y        ; $e646: 99 10 02  
__e649:     pla                ; $e649: 68        
            asl                ; $e64a: 0a        
            bcc __e652         ; $e64b: 90 05     
            lda #$f8           ; $e64d: a9 f8     
            sta $0214,y        ; $e64f: 99 14 02  
__e652:     lda $03d1          ; $e652: ad d1 03  
            asl                ; $e655: 0a        
            bcc __e65b         ; $e656: 90 03     
            jsr __e5ba         ; $e658: 20 ba e5  
__e65b:     rts                ; $e65b: 60        

;-------------------------------------------------------------------------------
__e65c:     lda $09            ; $e65c: a5 09     
            lsr                ; $e65e: 4a        
            bcs __e663         ; $e65f: b0 02     
            dec $db,x          ; $e661: d6 db     
__e663:     lda $db,x          ; $e663: b5 db     
            jsr __e5c8         ; $e665: 20 c8 e5  
            lda $03b3          ; $e668: ad b3 03  
            sta $0203,y        ; $e66b: 99 03 02  
            clc                ; $e66e: 18        
            adc #$08           ; $e66f: 69 08     
            sta $0207,y        ; $e671: 99 07 02  
            lda #$02           ; $e674: a9 02     
            sta $0202,y        ; $e676: 99 02 02  
            sta $0206,y        ; $e679: 99 06 02  
            lda #$f7           ; $e67c: a9 f7     
            sta $0201,y        ; $e67e: 99 01 02  
            lda #$fb           ; $e681: a9 fb     
            sta $0205,y        ; $e683: 99 05 02  
            jmp __e6c4         ; $e686: 4c c4 e6  

;-------------------------------------------------------------------------------
__e689:     rts                ; $e689: 60        

;-------------------------------------------------------------------------------
            adc ($62,x)        ; $e68a: 61 62     
            .hex 63            ; $e68c: 63        Suspected data
__e68d:     ldy $06f3,x        ; $e68d: bc f3 06  
            lda $2a,x          ; $e690: b5 2a     
            cmp #$02           ; $e692: c9 02     
            bcs __e65c         ; $e694: b0 c6     
            lda $db,x          ; $e696: b5 db     
            sta $0200,y        ; $e698: 99 00 02  
            clc                ; $e69b: 18        
            adc #$08           ; $e69c: 69 08     
            sta $0204,y        ; $e69e: 99 04 02  
            lda $03b3          ; $e6a1: ad b3 03  
            sta $0203,y        ; $e6a4: 99 03 02  
            sta $0207,y        ; $e6a7: 99 07 02  
            lda $09            ; $e6aa: a5 09     
            lsr                ; $e6ac: 4a        
            and #$03           ; $e6ad: 29 03     
            tax                ; $e6af: aa        
            lda __e689,x       ; $e6b0: bd 89 e6  
            iny                ; $e6b3: c8        
            jsr __e5c8         ; $e6b4: 20 c8 e5  
            dey                ; $e6b7: 88        
            lda #$02           ; $e6b8: a9 02     
            sta $0202,y        ; $e6ba: 99 02 02  
            lda #$82           ; $e6bd: a9 82     
            sta $0206,y        ; $e6bf: 99 06 02  
            ldx $08            ; $e6c2: a6 08     
__e6c4:     rts                ; $e6c4: 60        

;-------------------------------------------------------------------------------
__e6c5:     .hex 76            ; $e6c5: 76        Suspected data
__e6c6:     .hex 77 78         ; $e6c6: 77 78     Invalid Opcode - RRA $78,x
            adc __d6d6,y       ; $e6c8: 79 d6 d6  
            cmp __8dd9,y       ; $e6cb: d9 d9 8d  
            sta __e4e4         ; $e6ce: 8d e4 e4  
            ror $77,x          ; $e6d1: 76 77     
            sei                ; $e6d3: 78        
            .hex 79            ; $e6d4: 79        Suspected data
__e6d5:     .hex 02            ; $e6d5: 02        Invalid Opcode - KIL 
            ora ($02,x)        ; $e6d6: 01 02     
            .hex 01            ; $e6d8: 01        Suspected data
__e6d9:     ldy $06ea          ; $e6d9: ac ea 06  
            lda $03b9          ; $e6dc: ad b9 03  
            clc                ; $e6df: 18        
            adc #$08           ; $e6e0: 69 08     
            sta $02            ; $e6e2: 85 02     
            lda $03ae          ; $e6e4: ad ae 03  
            sta $05            ; $e6e7: 85 05     
            ldx $39            ; $e6e9: a6 39     
            lda __e6d5,x       ; $e6eb: bd d5 e6  
            ora $03ca          ; $e6ee: 0d ca 03  
            sta $04            ; $e6f1: 85 04     
            txa                ; $e6f3: 8a        
            pha                ; $e6f4: 48        
            asl                ; $e6f5: 0a        
            asl                ; $e6f6: 0a        
            tax                ; $e6f7: aa        
            lda #$01           ; $e6f8: a9 01     
            sta $07            ; $e6fa: 85 07     
            sta $03            ; $e6fc: 85 03     
__e6fe:     lda __e6c5,x       ; $e6fe: bd c5 e6  
__e701:     .hex 85            ; $e701: 85        Suspected data
__e702:     brk                ; $e702: 00        
            lda __e6c6,x       ; $e703: bd c6 e6  
            jsr __ebb9         ; $e706: 20 b9 eb  
            dec $07            ; $e709: c6 07     
            bpl __e6fe         ; $e70b: 10 f1     
            ldy $06ea          ; $e70d: ac ea 06  
            pla                ; $e710: 68        
            beq __e742         ; $e711: f0 2f     
            cmp #$03           ; $e713: c9 03     
            beq __e742         ; $e715: f0 2b     
            sta $00            ; $e717: 85 00     
            lda $09            ; $e719: a5 09     
            lsr                ; $e71b: 4a        
            and #$03           ; $e71c: 29 03     
            ora $03ca          ; $e71e: 0d ca 03  
            sta $0202,y        ; $e721: 99 02 02  
            sta $0206,y        ; $e724: 99 06 02  
            ldx $00            ; $e727: a6 00     
            dex                ; $e729: ca        
            beq __e732         ; $e72a: f0 06     
            sta $020a,y        ; $e72c: 99 0a 02  
            sta $020e,y        ; $e72f: 99 0e 02  
__e732:     lda $0206,y        ; $e732: b9 06 02  
            ora #$40           ; $e735: 09 40     
            sta $0206,y        ; $e737: 99 06 02  
            lda $020e,y        ; $e73a: b9 0e 02  
            ora #$40           ; $e73d: 09 40     
            sta $020e,y        ; $e73f: 99 0e 02  
__e742:     jmp __eb6b         ; $e742: 4c 6b eb  

;-------------------------------------------------------------------------------
__e745:     .hex fc            ; $e745: fc        Suspected data
__e746:     .hex fc aa ab      ; $e746: fc aa ab  Invalid Opcode - NOP __abaa,x
            ldy __fcad         ; $e749: ac ad fc  
            .hex fc ae af      ; $e74c: fc ae af  Invalid Opcode - NOP __afae,x
            bcs __e702         ; $e74f: b0 b1     
            .hex fc a5 a6      ; $e751: fc a5 a6  Invalid Opcode - NOP __a6a5,x
            .hex a7 a8         ; $e754: a7 a8     Invalid Opcode - LAX $a8
            lda #$fc           ; $e756: a9 fc     
            ldy #$a1           ; $e758: a0 a1     
            ldx #$a3           ; $e75a: a2 a3     
            ldy $69            ; $e75c: a4 69     
            lda $6a            ; $e75e: a5 6a     
            .hex a7            ; $e760: a7        Suspected data
__e761:     tay                ; $e761: a8        
            lda #$6b           ; $e762: a9 6b     
            ldy #$6c           ; $e764: a0 6c     
            ldx #$a3           ; $e766: a2 a3     
            ldy $fc            ; $e768: a4 fc     
            .hex fc 96 97      ; $e76a: fc 96 97  Invalid Opcode - NOP __9796,x
            tya                ; $e76d: 98        
            sta __fcfc,y       ; $e76e: 99 fc fc  
__e771:     txs                ; $e771: 9a        
            .hex 9b            ; $e772: 9b        Invalid Opcode - TAS 
            .hex 9c 9d fc      ; $e773: 9c 9d fc  Invalid Opcode - SHY __fc9d,x
            .hex fc 8f 8e      ; $e776: fc 8f 8e  Invalid Opcode - NOP __8e8f,x
            stx __fc8f         ; $e779: 8e 8f fc  
            .hex fc 95 94      ; $e77c: fc 95 94  Invalid Opcode - NOP __9495,x
            sty $95,x          ; $e77f: 94 95     
            .hex fc fc dc      ; $e781: fc fc dc  Invalid Opcode - NOP __dcfc,x
            .hex dc df df      ; $e784: dc df df  Invalid Opcode - NOP __dfdf,x
            .hex dc dc dd      ; $e787: dc dc dd  Invalid Opcode - NOP __dddc,x
            cmp __dede,x       ; $e78a: dd de de  
            .hex fc fc b2      ; $e78d: fc fc b2  Invalid Opcode - NOP __b2fc,x
            .hex b3 b4         ; $e790: b3 b4     Invalid Opcode - LAX ($b4),y
            lda $fc,x          ; $e792: b5 fc     
            .hex fc b6 b3      ; $e794: fc b6 b3  Invalid Opcode - NOP __b3b6,x
            .hex b7 b5         ; $e797: b7 b5     Invalid Opcode - LAX $b5,y
            .hex fc fc 70      ; $e799: fc fc 70  Invalid Opcode - NOP $70fc,x
            adc ($72),y        ; $e79c: 71 72     
            .hex 73 fc         ; $e79e: 73 fc     Invalid Opcode - RRA ($fc),y
            .hex fc 6e 6e      ; $e7a0: fc 6e 6e  Invalid Opcode - NOP $6e6e,x
            .hex 6f 6f fc      ; $e7a3: 6f 6f fc  Invalid Opcode - RRA __fc6f
            .hex fc 6d 6d      ; $e7a6: fc 6d 6d  Invalid Opcode - NOP $6d6d,x
            .hex 6f 6f fc      ; $e7a9: 6f 6f fc  Invalid Opcode - RRA __fc6f
            .hex fc 6f 6f      ; $e7ac: fc 6f 6f  Invalid Opcode - NOP $6f6f,x
            ror __fc6e         ; $e7af: 6e 6e fc  
            .hex fc 6f 6f      ; $e7b2: fc 6f 6f  Invalid Opcode - NOP $6f6f,x
            adc __fc6d         ; $e7b5: 6d 6d fc  
            .hex fc f4 f4      ; $e7b8: fc f4 f4  Invalid Opcode - NOP __f4f4,x
            sbc $f5,x          ; $e7bb: f5 f5     
            .hex fc fc f4      ; $e7bd: fc fc f4  Invalid Opcode - NOP __f4fc,x
            .hex f4 f5         ; $e7c0: f4 f5     Invalid Opcode - NOP $f5,x
            sbc $fc,x          ; $e7c2: f5 fc     
            .hex fc f5 f5      ; $e7c4: fc f5 f5  Invalid Opcode - NOP __f5f5,x
            .hex f4 f4         ; $e7c7: f4 f4     Invalid Opcode - NOP $f4,x
            .hex fc fc f5      ; $e7c9: fc fc f5  Invalid Opcode - NOP __f5fc,x
            sbc $f4,x          ; $e7cc: f5 f4     
            .hex f4 fc         ; $e7ce: f4 fc     Invalid Opcode - NOP $fc,x
            .hex fc fc fc      ; $e7d0: fc fc fc  Invalid Opcode - NOP __fcfc,x
            .hex ef ef b9      ; $e7d3: ef ef b9  Invalid Opcode - ISC __b9ef
            clv                ; $e7d6: b8        
            .hex bb ba bc      ; $e7d7: bb ba bc  Invalid Opcode - LAS __bcba,y
            ldy __fcfc,x       ; $e7da: bc fc fc  
            lda __bcbd,x       ; $e7dd: bd bd bc  
            ldy $7b7a,x        ; $e7e0: bc 7a 7b  
            .hex da            ; $e7e3: da        Invalid Opcode - NOP 
            .hex db            ; $e7e4: db        Suspected data
__e7e5:     cld                ; $e7e5: d8        
            cld                ; $e7e6: d8        
            cmp __cecd         ; $e7e7: cd cd ce  
            dec __cfcf         ; $e7ea: ce cf cf  
__e7ed:     adc __d17c,x       ; $e7ed: 7d 7c d1  
            sty __d2d3         ; $e7f0: 8c d3 d2  
            adc __897c,x       ; $e7f3: 7d 7c 89  
            dey                ; $e7f6: 88        
            .hex 8b 8a         ; $e7f7: 8b 8a     Invalid Opcode - XAA #$8a
            cmp $d4,x          ; $e7f9: d5 d4     
            .hex e3 e2         ; $e7fb: e3 e2     Invalid Opcode - ISC ($e2,x)
            .hex d3 d2         ; $e7fd: d3 d2     Invalid Opcode - DCP ($d2),y
            cmp $d4,x          ; $e7ff: d5 d4     
            .hex e3 e2         ; $e801: e3 e2     Invalid Opcode - ISC ($e2,x)
            .hex 8b 8a         ; $e803: 8b 8a     Invalid Opcode - XAA #$8a
            sbc $e5            ; $e805: e5 e5     
            inc $e6            ; $e807: e6 e6     
            .hex eb eb         ; $e809: eb eb     Invalid Opcode - SBC #$eb
            cpx __edec         ; $e80b: ec ec ed  
            sbc __eeee         ; $e80e: ed ee ee  
            .hex fc fc d0      ; $e811: fc fc d0  Invalid Opcode - NOP __d0fc,x
            bne __e7ed         ; $e814: d0 d7     
            .hex d7 bf         ; $e816: d7 bf     Invalid Opcode - DCP $bf,x
            ldx __c0c1,y       ; $e818: be c1 c0  
            .hex c2 fc         ; $e81b: c2 fc     Invalid Opcode - NOP #$fc
            cpy $c3            ; $e81d: c4 c3     
            dec $c5            ; $e81f: c6 c5     
            iny                ; $e821: c8        
            .hex c7 bf         ; $e822: c7 bf     Invalid Opcode - DCP $bf
            ldx __c9ca,y       ; $e824: be ca c9  
            .hex c2 fc         ; $e827: c2 fc     Invalid Opcode - NOP #$fc
            cpy $c3            ; $e829: c4 c3     
            dec $c5            ; $e82b: c6 c5     
            cpy __fccb         ; $e82d: cc cb fc  
            .hex fc e8 e7      ; $e830: fc e8 e7  Invalid Opcode - NOP __e7e8,x
            nop                ; $e833: ea        
            sbc #$f2           ; $e834: e9 f2     
            .hex f2            ; $e836: f2        Invalid Opcode - KIL 
            .hex f3 f3         ; $e837: f3 f3     Invalid Opcode - ISC ($f3),y
            .hex f2            ; $e839: f2        Invalid Opcode - KIL 
            .hex f2            ; $e83a: f2        Invalid Opcode - KIL 
            sbc ($f1),y        ; $e83b: f1 f1     
            sbc ($f1),y        ; $e83d: f1 f1     
            .hex fc            ; $e83f: fc        Suspected data
__e840:     .hex fc f0         ; $e840: fc f0     Suspected data
__e842:     beq __e840         ; $e842: f0 fc     
            .hex fc fc fc      ; $e844: fc fc fc  Invalid Opcode - NOP __fcfc,x
__e847:     .hex 0c 0c 00      ; $e847: 0c 0c 00  Bad Addr Mode - NOP $000c
            .hex 0c 0c a8      ; $e84a: 0c 0c a8  Invalid Opcode - NOP __a80c
            .hex 54 3c         ; $e84d: 54 3c     Invalid Opcode - NOP $3c,x
            nop                ; $e84f: ea        
            clc                ; $e850: 18        
            pha                ; $e851: 48        
            pha                ; $e852: 48        
            cpy $18c0          ; $e853: cc c0 18  
            clc                ; $e856: 18        
__e857:     clc                ; $e857: 18        
            bcc __e87e         ; $e858: 90 24     
            .hex ff 48 9c      ; $e85a: ff 48 9c  Invalid Opcode - ISC __9c48,x
            .hex d2            ; $e85d: d2        Invalid Opcode - KIL 
            cld                ; $e85e: d8        
            beq __e857         ; $e85f: f0 f6     
            .hex fc            ; $e861: fc        Suspected data
__e862:     ora ($02,x)        ; $e862: 01 02     
            .hex 03 02         ; $e864: 03 02     Invalid Opcode - SLO ($02,x)
            ora ($01,x)        ; $e866: 01 01     
            .hex 03 03         ; $e868: 03 03     Invalid Opcode - SLO ($03,x)
            .hex 03 01         ; $e86a: 03 01     Invalid Opcode - SLO ($01,x)
            ora ($02,x)        ; $e86c: 01 02     
            .hex 02            ; $e86e: 02        Invalid Opcode - KIL 
            and ($01,x)        ; $e86f: 21 01     
            .hex 02            ; $e871: 02        Invalid Opcode - KIL 
            ora ($01,x)        ; $e872: 01 01     
            .hex 02            ; $e874: 02        Invalid Opcode - KIL 
            .hex ff 02 02      ; $e875: ff 02 02  Invalid Opcode - ISC $0202,x
            ora ($01,x)        ; $e878: 01 01     
            .hex 02            ; $e87a: 02        Invalid Opcode - KIL 
            .hex 02            ; $e87b: 02        Invalid Opcode - KIL 
            .hex 02            ; $e87c: 02        Invalid Opcode - KIL 
__e87d:     php                ; $e87d: 08        
__e87e:     clc                ; $e87e: 18        
__e87f:     clc                ; $e87f: 18        
            ora $191a,y        ; $e880: 19 1a 19  
            clc                ; $e883: 18        
__e884:     lda $cf,x          ; $e884: b5 cf     
            sta $02            ; $e886: 85 02     
            lda $03ae          ; $e888: ad ae 03  
            sta $05            ; $e88b: 85 05     
            ldy $06e5,x        ; $e88d: bc e5 06  
            sty $eb            ; $e890: 84 eb     
            lda #$00           ; $e892: a9 00     
            sta $0109          ; $e894: 8d 09 01  
            lda $46,x          ; $e897: b5 46     
            sta $03            ; $e899: 85 03     
            lda $03c5,x        ; $e89b: bd c5 03  
            sta $04            ; $e89e: 85 04     
            lda $16,x          ; $e8a0: b5 16     
            cmp #$0d           ; $e8a2: c9 0d     
            bne __e8b0         ; $e8a4: d0 0a     
            ldy $58,x          ; $e8a6: b4 58     
            bmi __e8b0         ; $e8a8: 30 06     
            ldy $078a,x        ; $e8aa: bc 8a 07  
            beq __e8b0         ; $e8ad: f0 01     
            rts                ; $e8af: 60        

;-------------------------------------------------------------------------------
__e8b0:     lda $1e,x          ; $e8b0: b5 1e     
            sta $ed            ; $e8b2: 85 ed     
            and #$1f           ; $e8b4: 29 1f     
            tay                ; $e8b6: a8        
            lda $16,x          ; $e8b7: b5 16     
            cmp #$35           ; $e8b9: c9 35     
            bne __e8c5         ; $e8bb: d0 08     
            ldy #$00           ; $e8bd: a0 00     
            lda #$01           ; $e8bf: a9 01     
            sta $03            ; $e8c1: 85 03     
            lda #$15           ; $e8c3: a9 15     
__e8c5:     cmp #$33           ; $e8c5: c9 33     
            bne __e8dc         ; $e8c7: d0 13     
            dec $02            ; $e8c9: c6 02     
            lda #$03           ; $e8cb: a9 03     
            ldy $078a,x        ; $e8cd: bc 8a 07  
            beq __e8d4         ; $e8d0: f0 02     
            ora #$20           ; $e8d2: 09 20     
__e8d4:     sta $04            ; $e8d4: 85 04     
            ldy #$00           ; $e8d6: a0 00     
            sty $ed            ; $e8d8: 84 ed     
            lda #$08           ; $e8da: a9 08     
__e8dc:     cmp #$32           ; $e8dc: c9 32     
            bne __e8e8         ; $e8de: d0 08     
            ldy #$03           ; $e8e0: a0 03     
            ldx $070e          ; $e8e2: ae 0e 07  
            lda __e87f,x       ; $e8e5: bd 7f e8  
__e8e8:     sta $ef            ; $e8e8: 85 ef     
            sty $ec            ; $e8ea: 84 ec     
            ldx $08            ; $e8ec: a6 08     
            cmp #$0c           ; $e8ee: c9 0c     
            bne __e8f9         ; $e8f0: d0 07     
            lda $a0,x          ; $e8f2: b5 a0     
            bmi __e8f9         ; $e8f4: 30 03     
            inc $0109          ; $e8f6: ee 09 01  
__e8f9:     lda $036a          ; $e8f9: ad 6a 03  
            beq __e907         ; $e8fc: f0 09     
            ldy #$16           ; $e8fe: a0 16     
            cmp #$01           ; $e900: c9 01     
            beq __e905         ; $e902: f0 01     
            iny                ; $e904: c8        
__e905:     .hex 84            ; $e905: 84        Suspected data
__e906:     .hex ef            ; $e906: ef        Suspected data
__e907:     ldy $ef            ; $e907: a4 ef     
            cpy #$06           ; $e909: c0 06     
            bne __e92a         ; $e90b: d0 1d     
            lda $1e,x          ; $e90d: b5 1e     
            cmp #$02           ; $e90f: c9 02     
            bcc __e917         ; $e911: 90 04     
            ldx #$04           ; $e913: a2 04     
            stx $ec            ; $e915: 86 ec     
__e917:     and #$20           ; $e917: 29 20     
            ora $0747          ; $e919: 0d 47 07  
            bne __e92a         ; $e91c: d0 0c     
            lda $09            ; $e91e: a5 09     
            and #$08           ; $e920: 29 08     
            bne __e92a         ; $e922: d0 06     
            lda $03            ; $e924: a5 03     
            eor #$03           ; $e926: 49 03     
            sta $03            ; $e928: 85 03     
__e92a:     lda __e862,y       ; $e92a: b9 62 e8  
            ora $04            ; $e92d: 05 04     
            sta $04            ; $e92f: 85 04     
            lda __e847,y       ; $e931: b9 47 e8  
            tax                ; $e934: aa        
            ldy $ec            ; $e935: a4 ec     
            lda $036a          ; $e937: ad 6a 03  
            beq __e96c         ; $e93a: f0 30     
            cmp #$01           ; $e93c: c9 01     
            bne __e953         ; $e93e: d0 13     
            lda $0363          ; $e940: ad 63 03  
            bpl __e947         ; $e943: 10 02     
            ldx #$de           ; $e945: a2 de     
__e947:     lda $ed            ; $e947: a5 ed     
            and #$20           ; $e949: 29 20     
            beq __e950         ; $e94b: f0 03     
__e94d:     stx $0109          ; $e94d: 8e 09 01  
__e950:     jmp __ea52         ; $e950: 4c 52 ea  

;-------------------------------------------------------------------------------
__e953:     lda $0363          ; $e953: ad 63 03  
            and #$01           ; $e956: 29 01     
            beq __e95c         ; $e958: f0 02     
            ldx #$e4           ; $e95a: a2 e4     
__e95c:     lda $ed            ; $e95c: a5 ed     
            and #$20           ; $e95e: 29 20     
            beq __e950         ; $e960: f0 ee     
            lda $02            ; $e962: a5 02     
            sec                ; $e964: 38        
            sbc #$10           ; $e965: e9 10     
            sta $02            ; $e967: 85 02     
            jmp __e94d         ; $e969: 4c 4d e9  

;-------------------------------------------------------------------------------
__e96c:     cpx #$24           ; $e96c: e0 24     
            bne __e981         ; $e96e: d0 11     
            cpy #$05           ; $e970: c0 05     
            bne __e97e         ; $e972: d0 0a     
            ldx #$30           ; $e974: a2 30     
            lda #$02           ; $e976: a9 02     
            sta $03            ; $e978: 85 03     
            lda #$05           ; $e97a: a9 05     
            sta $ec            ; $e97c: 85 ec     
__e97e:     jmp __e9d1         ; $e97e: 4c d1 e9  

;-------------------------------------------------------------------------------
__e981:     cpx #$90           ; $e981: e0 90     
            bne __e997         ; $e983: d0 12     
            lda $ed            ; $e985: a5 ed     
            and #$20           ; $e987: 29 20     
            bne __e994         ; $e989: d0 09     
            lda $078f          ; $e98b: ad 8f 07  
            cmp #$10           ; $e98e: c9 10     
            bcs __e994         ; $e990: b0 02     
            ldx #$96           ; $e992: a2 96     
__e994:     jmp __ea3e         ; $e994: 4c 3e ea  

;-------------------------------------------------------------------------------
__e997:     lda $ef            ; $e997: a5 ef     
            cmp #$04           ; $e999: c9 04     
            bcs __e9ad         ; $e99b: b0 10     
            cpy #$02           ; $e99d: c0 02     
            bcc __e9ad         ; $e99f: 90 0c     
            ldx #$5a           ; $e9a1: a2 5a     
            ldy $ef            ; $e9a3: a4 ef     
            cpy #$02           ; $e9a5: c0 02     
            bne __e9ad         ; $e9a7: d0 04     
            ldx #$7e           ; $e9a9: a2 7e     
            inc $02            ; $e9ab: e6 02     
__e9ad:     lda $ec            ; $e9ad: a5 ec     
            cmp #$04           ; $e9af: c9 04     
            bne __e9d1         ; $e9b1: d0 1e     
            ldx #$72           ; $e9b3: a2 72     
            inc $02            ; $e9b5: e6 02     
            ldy $ef            ; $e9b7: a4 ef     
            cpy #$02           ; $e9b9: c0 02     
            beq __e9c1         ; $e9bb: f0 04     
            ldx #$66           ; $e9bd: a2 66     
            inc $02            ; $e9bf: e6 02     
__e9c1:     cpy #$06           ; $e9c1: c0 06     
            bne __e9d1         ; $e9c3: d0 0c     
            ldx #$54           ; $e9c5: a2 54     
            lda $ed            ; $e9c7: a5 ed     
            and #$20           ; $e9c9: 29 20     
            bne __e9d1         ; $e9cb: d0 04     
            ldx #$8a           ; $e9cd: a2 8a     
            dec $02            ; $e9cf: c6 02     
__e9d1:     ldy $08            ; $e9d1: a4 08     
            lda $ef            ; $e9d3: a5 ef     
            cmp #$05           ; $e9d5: c9 05     
            bne __e9e5         ; $e9d7: d0 0c     
            lda $ed            ; $e9d9: a5 ed     
            beq __ea01         ; $e9db: f0 24     
            and #$08           ; $e9dd: 29 08     
            beq __ea3e         ; $e9df: f0 5d     
            ldx #$b4           ; $e9e1: a2 b4     
            bne __ea01         ; $e9e3: d0 1c     
__e9e5:     cpx #$48           ; $e9e5: e0 48     
            beq __ea01         ; $e9e7: f0 18     
            lda $0796,y        ; $e9e9: b9 96 07  
            cmp #$05           ; $e9ec: c9 05     
            bcs __ea3e         ; $e9ee: b0 4e     
            cpx #$3c           ; $e9f0: e0 3c     
            bne __ea01         ; $e9f2: d0 0d     
            cmp #$01           ; $e9f4: c9 01     
            beq __ea3e         ; $e9f6: f0 46     
            inc $02            ; $e9f8: e6 02     
            inc $02            ; $e9fa: e6 02     
            inc $02            ; $e9fc: e6 02     
            jmp __ea30         ; $e9fe: 4c 30 ea  

;-------------------------------------------------------------------------------
__ea01:     lda $ef            ; $ea01: a5 ef     
            cmp #$06           ; $ea03: c9 06     
            beq __ea3e         ; $ea05: f0 37     
            cmp #$08           ; $ea07: c9 08     
            beq __ea3e         ; $ea09: f0 33     
            cmp #$0c           ; $ea0b: c9 0c     
            beq __ea3e         ; $ea0d: f0 2f     
            cmp #$18           ; $ea0f: c9 18     
            bcs __ea3e         ; $ea11: b0 2b     
            ldy #$00           ; $ea13: a0 00     
            cmp #$15           ; $ea15: c9 15     
            bne __ea29         ; $ea17: d0 10     
            iny                ; $ea19: c8        
            lda $075f          ; $ea1a: ad 5f 07  
            cmp #$07           ; $ea1d: c9 07     
            bcs __ea3e         ; $ea1f: b0 1d     
            ldx #$a2           ; $ea21: a2 a2     
            lda #$03           ; $ea23: a9 03     
            sta $ec            ; $ea25: 85 ec     
            bne __ea3e         ; $ea27: d0 15     
__ea29:     lda $09            ; $ea29: a5 09     
            and __e87d,y       ; $ea2b: 39 7d e8  
            bne __ea3e         ; $ea2e: d0 0e     
__ea30:     lda $ed            ; $ea30: a5 ed     
__ea32:     and #$a0           ; $ea32: 29 a0     
            ora $0747          ; $ea34: 0d 47 07  
            bne __ea3e         ; $ea37: d0 05     
            txa                ; $ea39: 8a        
            clc                ; $ea3a: 18        
            adc #$06           ; $ea3b: 69 06     
            tax                ; $ea3d: aa        
__ea3e:     lda $ed            ; $ea3e: a5 ed     
            and #$20           ; $ea40: 29 20     
            beq __ea52         ; $ea42: f0 0e     
            lda $ef            ; $ea44: a5 ef     
            cmp #$04           ; $ea46: c9 04     
            bcc __ea52         ; $ea48: 90 08     
            ldy #$01           ; $ea4a: a0 01     
            sty $0109          ; $ea4c: 8c 09 01  
            dey                ; $ea4f: 88        
            sty $ec            ; $ea50: 84 ec     
__ea52:     ldy $eb            ; $ea52: a4 eb     
            jsr __ebb1         ; $ea54: 20 b1 eb  
            jsr __ebb1         ; $ea57: 20 b1 eb  
            jsr __ebb1         ; $ea5a: 20 b1 eb  
            ldx $08            ; $ea5d: a6 08     
            .hex bc e5         ; $ea5f: bc e5     Suspected data
__ea61:     asl $a5            ; $ea61: 06 a5     
            .hex ef c9 08      ; $ea63: ef c9 08  Invalid Opcode - ISC $08c9
            bne __ea6b         ; $ea66: d0 03     
__ea68:     jmp __eb6b         ; $ea68: 4c 6b eb  

;-------------------------------------------------------------------------------
__ea6b:     lda $0109          ; $ea6b: ad 09 01  
            beq __eaad         ; $ea6e: f0 3d     
            lda $0202,y        ; $ea70: b9 02 02  
            ora #$80           ; $ea73: 09 80     
            iny                ; $ea75: c8        
            iny                ; $ea76: c8        
            jsr __e5bc         ; $ea77: 20 bc e5  
            dey                ; $ea7a: 88        
            dey                ; $ea7b: 88        
            tya                ; $ea7c: 98        
            tax                ; $ea7d: aa        
            lda $ef            ; $ea7e: a5 ef     
            cmp #$05           ; $ea80: c9 05     
            beq __ea91         ; $ea82: f0 0d     
            cmp #$11           ; $ea84: c9 11     
            beq __ea91         ; $ea86: f0 09     
            cmp #$15           ; $ea88: c9 15     
            bcs __ea91         ; $ea8a: b0 05     
            txa                ; $ea8c: 8a        
            clc                ; $ea8d: 18        
            adc #$08           ; $ea8e: 69 08     
            tax                ; $ea90: aa        
__ea91:     lda $0201,x        ; $ea91: bd 01 02  
            pha                ; $ea94: 48        
            lda $0205,x        ; $ea95: bd 05 02  
            pha                ; $ea98: 48        
            lda $0211,y        ; $ea99: b9 11 02  
            sta $0201,x        ; $ea9c: 9d 01 02  
            lda $0215,y        ; $ea9f: b9 15 02  
            sta $0205,x        ; $eaa2: 9d 05 02  
            pla                ; $eaa5: 68        
            sta $0215,y        ; $eaa6: 99 15 02  
            pla                ; $eaa9: 68        
            sta $0211,y        ; $eaaa: 99 11 02  
__eaad:     lda $036a          ; $eaad: ad 6a 03  
            bne __ea68         ; $eab0: d0 b6     
            lda $ef            ; $eab2: a5 ef     
            ldx $ec            ; $eab4: a6 ec     
            cmp #$05           ; $eab6: c9 05     
            bne __eabd         ; $eab8: d0 03     
            jmp __eb6b         ; $eaba: 4c 6b eb  

;-------------------------------------------------------------------------------
__eabd:     cmp #$07           ; $eabd: c9 07     
            beq __eade         ; $eabf: f0 1d     
            cmp #$0d           ; $eac1: c9 0d     
            beq __eade         ; $eac3: f0 19     
            cmp #$0c           ; $eac5: c9 0c     
            beq __eade         ; $eac7: f0 15     
            cmp #$12           ; $eac9: c9 12     
            bne __ead1         ; $eacb: d0 04     
            cpx #$05           ; $eacd: e0 05     
            bne __eb19         ; $eacf: d0 48     
__ead1:     cmp #$15           ; $ead1: c9 15     
            bne __eada         ; $ead3: d0 05     
            lda #$42           ; $ead5: a9 42     
            sta $0216,y        ; $ead7: 99 16 02  
__eada:     cpx #$02           ; $eada: e0 02     
            bcc __eb19         ; $eadc: 90 3b     
__eade:     lda $036a          ; $eade: ad 6a 03  
            bne __eb19         ; $eae1: d0 36     
            lda $0202,y        ; $eae3: b9 02 02  
            and #$a3           ; $eae6: 29 a3     
            sta $0202,y        ; $eae8: 99 02 02  
            sta $020a,y        ; $eaeb: 99 0a 02  
            sta $0212,y        ; $eaee: 99 12 02  
            ora #$40           ; $eaf1: 09 40     
            cpx #$05           ; $eaf3: e0 05     
            bne __eaf9         ; $eaf5: d0 02     
            ora #$80           ; $eaf7: 09 80     
__eaf9:     sta $0206,y        ; $eaf9: 99 06 02  
            sta $020e,y        ; $eafc: 99 0e 02  
            sta $0216,y        ; $eaff: 99 16 02  
            cpx #$04           ; $eb02: e0 04     
            bne __eb19         ; $eb04: d0 13     
            lda $020a,y        ; $eb06: b9 0a 02  
            ora #$80           ; $eb09: 09 80     
            sta $020a,y        ; $eb0b: 99 0a 02  
            sta $0212,y        ; $eb0e: 99 12 02  
            ora #$40           ; $eb11: 09 40     
            sta $020e,y        ; $eb13: 99 0e 02  
            sta $0216,y        ; $eb16: 99 16 02  
__eb19:     lda $ef            ; $eb19: a5 ef     
            cmp #$11           ; $eb1b: c9 11     
            bne __eb55         ; $eb1d: d0 36     
            lda $0109          ; $eb1f: ad 09 01  
            bne __eb45         ; $eb22: d0 21     
            lda $0212,y        ; $eb24: b9 12 02  
            and #$81           ; $eb27: 29 81     
            sta $0212,y        ; $eb29: 99 12 02  
            lda $0216,y        ; $eb2c: b9 16 02  
            ora #$41           ; $eb2f: 09 41     
            sta $0216,y        ; $eb31: 99 16 02  
            ldx $078f          ; $eb34: ae 8f 07  
            cpx #$10           ; $eb37: e0 10     
            bcs __eb6b         ; $eb39: b0 30     
            sta $020e,y        ; $eb3b: 99 0e 02  
            and #$81           ; $eb3e: 29 81     
            sta $020a,y        ; $eb40: 99 0a 02  
            bcc __eb6b         ; $eb43: 90 26     
__eb45:     lda $0202,y        ; $eb45: b9 02 02  
            and #$81           ; $eb48: 29 81     
            sta $0202,y        ; $eb4a: 99 02 02  
            lda $0206,y        ; $eb4d: b9 06 02  
            ora #$41           ; $eb50: 09 41     
            sta $0206,y        ; $eb52: 99 06 02  
__eb55:     lda $ef            ; $eb55: a5 ef     
            cmp #$18           ; $eb57: c9 18     
            bcc __eb6b         ; $eb59: 90 10     
            lda #$82           ; $eb5b: a9 82     
            sta $020a,y        ; $eb5d: 99 0a 02  
            sta $0212,y        ; $eb60: 99 12 02  
            ora #$40           ; $eb63: 09 40     
            sta $020e,y        ; $eb65: 99 0e 02  
            sta $0216,y        ; $eb68: 99 16 02  
__eb6b:     ldx $08            ; $eb6b: a6 08     
            lda $03d1          ; $eb6d: ad d1 03  
            lsr                ; $eb70: 4a        
            lsr                ; $eb71: 4a        
            lsr                ; $eb72: 4a        
            pha                ; $eb73: 48        
            bcc __eb7b         ; $eb74: 90 05     
            lda #$04           ; $eb76: a9 04     
            jsr __ebc8         ; $eb78: 20 c8 eb  
__eb7b:     pla                ; $eb7b: 68        
            lsr                ; $eb7c: 4a        
            pha                ; $eb7d: 48        
            bcc __eb85         ; $eb7e: 90 05     
            lda #$00           ; $eb80: a9 00     
            jsr __ebc8         ; $eb82: 20 c8 eb  
__eb85:     pla                ; $eb85: 68        
            lsr                ; $eb86: 4a        
            lsr                ; $eb87: 4a        
            pha                ; $eb88: 48        
            bcc __eb90         ; $eb89: 90 05     
            lda #$10           ; $eb8b: a9 10     
            jsr __ebbe         ; $eb8d: 20 be eb  
__eb90:     pla                ; $eb90: 68        
            lsr                ; $eb91: 4a        
            pha                ; $eb92: 48        
            bcc __eb9a         ; $eb93: 90 05     
            lda #$08           ; $eb95: a9 08     
            jsr __ebbe         ; $eb97: 20 be eb  
__eb9a:     pla                ; $eb9a: 68        
            lsr                ; $eb9b: 4a        
            bcc __ebb0         ; $eb9c: 90 12     
            jsr __ebbe         ; $eb9e: 20 be eb  
            lda $16,x          ; $eba1: b5 16     
            cmp #$0c           ; $eba3: c9 0c     
            beq __ebb0         ; $eba5: f0 09     
            lda $b6,x          ; $eba7: b5 b6     
            cmp #$02           ; $eba9: c9 02     
            bne __ebb0         ; $ebab: d0 03     
            jsr __c99e         ; $ebad: 20 9e c9  
__ebb0:     rts                ; $ebb0: 60        

;-------------------------------------------------------------------------------
__ebb1:     lda __e745,x       ; $ebb1: bd 45 e7  
            sta $00            ; $ebb4: 85 00     
            lda __e746,x       ; $ebb6: bd 46 e7  
__ebb9:     sta $01            ; $ebb9: 85 01     
            jmp __f289         ; $ebbb: 4c 89 f2  

;-------------------------------------------------------------------------------
__ebbe:     clc                ; $ebbe: 18        
            adc $06e5,x        ; $ebbf: 7d e5 06  
            tay                ; $ebc2: a8        
            lda #$f8           ; $ebc3: a9 f8     
            jmp __e5c8         ; $ebc5: 4c c8 e5  

;-------------------------------------------------------------------------------
__ebc8:     clc                ; $ebc8: 18        
            adc $06e5,x        ; $ebc9: 7d e5 06  
            tay                ; $ebcc: a8        
            jsr __ec51         ; $ebcd: 20 51 ec  
            sta $0210,y        ; $ebd0: 99 10 02  
            rts                ; $ebd3: 60        

;-------------------------------------------------------------------------------
__ebd4:     .hex 85            ; $ebd4: 85        Suspected data
__ebd5:     sta $86            ; $ebd5: 85 86     
            .hex 86            ; $ebd7: 86        Suspected data
__ebd8:     lda $03bc          ; $ebd8: ad bc 03  
            sta $02            ; $ebdb: 85 02     
            lda $03b1          ; $ebdd: ad b1 03  
            sta $05            ; $ebe0: 85 05     
            lda #$03           ; $ebe2: a9 03     
            sta $04            ; $ebe4: 85 04     
            lsr                ; $ebe6: 4a        
            sta $03            ; $ebe7: 85 03     
            ldy $06ec,x        ; $ebe9: bc ec 06  
            ldx #$00           ; $ebec: a2 00     
__ebee:     lda __ebd4,x       ; $ebee: bd d4 eb  
            sta $00            ; $ebf1: 85 00     
            lda __ebd5,x       ; $ebf3: bd d5 eb  
            jsr __ebb9         ; $ebf6: 20 b9 eb  
            cpx #$04           ; $ebf9: e0 04     
            bne __ebee         ; $ebfb: d0 f1     
            ldx $08            ; $ebfd: a6 08     
            ldy $06ec,x        ; $ebff: bc ec 06  
            lda $074e          ; $ec02: ad 4e 07  
            cmp #$01           ; $ec05: c9 01     
            beq __ec11         ; $ec07: f0 08     
            lda #$86           ; $ec09: a9 86     
            sta $0201,y        ; $ec0b: 99 01 02  
            sta $0205,y        ; $ec0e: 99 05 02  
__ec11:     lda $03e8,x        ; $ec11: bd e8 03  
            cmp #$c4           ; $ec14: c9 c4     
            bne __ec3c         ; $ec16: d0 24     
            lda #$87           ; $ec18: a9 87     
            iny                ; $ec1a: c8        
            jsr __e5c2         ; $ec1b: 20 c2 e5  
            dey                ; $ec1e: 88        
            lda #$03           ; $ec1f: a9 03     
            ldx $074e          ; $ec21: ae 4e 07  
            dex                ; $ec24: ca        
            beq __ec28         ; $ec25: f0 01     
            lsr                ; $ec27: 4a        
__ec28:     ldx $08            ; $ec28: a6 08     
            sta $0202,y        ; $ec2a: 99 02 02  
            ora #$40           ; $ec2d: 09 40     
            sta $0206,y        ; $ec2f: 99 06 02  
            ora #$80           ; $ec32: 09 80     
            sta $020e,y        ; $ec34: 99 0e 02  
            and #$83           ; $ec37: 29 83     
            sta $020a,y        ; $ec39: 99 0a 02  
__ec3c:     lda $03d4          ; $ec3c: ad d4 03  
            pha                ; $ec3f: 48        
            and #$04           ; $ec40: 29 04     
            beq __ec4c         ; $ec42: f0 08     
            lda #$f8           ; $ec44: a9 f8     
            sta $0204,y        ; $ec46: 99 04 02  
            sta $020c,y        ; $ec49: 99 0c 02  
__ec4c:     pla                ; $ec4c: 68        
__ec4d:     and #$08           ; $ec4d: 29 08     
            beq __ec59         ; $ec4f: f0 08     
__ec51:     lda #$f8           ; $ec51: a9 f8     
            sta $0200,y        ; $ec53: 99 00 02  
            sta $0208,y        ; $ec56: 99 08 02  
__ec59:     rts                ; $ec59: 60        

;-------------------------------------------------------------------------------
__ec5a:     lda #$02           ; $ec5a: a9 02     
            sta $00            ; $ec5c: 85 00     
            lda #$75           ; $ec5e: a9 75     
            ldy $0e            ; $ec60: a4 0e     
            cpy #$05           ; $ec62: c0 05     
            beq __ec6c         ; $ec64: f0 06     
            lda #$03           ; $ec66: a9 03     
            sta $00            ; $ec68: 85 00     
            lda #$84           ; $ec6a: a9 84     
__ec6c:     ldy $06ec,x        ; $ec6c: bc ec 06  
            iny                ; $ec6f: c8        
            jsr __e5c2         ; $ec70: 20 c2 e5  
            lda $09            ; $ec73: a5 09     
            asl                ; $ec75: 0a        
            asl                ; $ec76: 0a        
            asl                ; $ec77: 0a        
            asl                ; $ec78: 0a        
            and #$c0           ; $ec79: 29 c0     
            ora $00            ; $ec7b: 05 00     
            iny                ; $ec7d: c8        
            jsr __e5c2         ; $ec7e: 20 c2 e5  
            dey                ; $ec81: 88        
            dey                ; $ec82: 88        
            lda $03bc          ; $ec83: ad bc 03  
            jsr __e5c8         ; $ec86: 20 c8 e5  
            lda $03b1          ; $ec89: ad b1 03  
            sta $0203,y        ; $ec8c: 99 03 02  
            lda $03f1,x        ; $ec8f: bd f1 03  
            sec                ; $ec92: 38        
            sbc $071c          ; $ec93: ed 1c 07  
            sta $00            ; $ec96: 85 00     
            sec                ; $ec98: 38        
            sbc $03b1          ; $ec99: ed b1 03  
            adc $00            ; $ec9c: 65 00     
            adc #$06           ; $ec9e: 69 06     
            sta $0207,y        ; $eca0: 99 07 02  
            lda $03bd          ; $eca3: ad bd 03  
            sta $0208,y        ; $eca6: 99 08 02  
            sta $020c,y        ; $eca9: 99 0c 02  
            lda $03b2          ; $ecac: ad b2 03  
            sta $020b,y        ; $ecaf: 99 0b 02  
            lda $00            ; $ecb2: a5 00     
            sec                ; $ecb4: 38        
            sbc $03b2          ; $ecb5: ed b2 03  
            adc $00            ; $ecb8: 65 00     
            adc #$06           ; $ecba: 69 06     
            sta $020f,y        ; $ecbc: 99 0f 02  
            lda $03d4          ; $ecbf: ad d4 03  
            jsr __ec4d         ; $ecc2: 20 4d ec  
            lda $03d4          ; $ecc5: ad d4 03  
            asl                ; $ecc8: 0a        
            bcc __ecd0         ; $ecc9: 90 05     
            lda #$f8           ; $eccb: a9 f8     
            jsr __e5c8         ; $eccd: 20 c8 e5  
__ecd0:     lda $00            ; $ecd0: a5 00     
            bpl __ece4         ; $ecd2: 10 10     
            lda $0203,y        ; $ecd4: b9 03 02  
            cmp $0207,y        ; $ecd7: d9 07 02  
            bcc __ece4         ; $ecda: 90 08     
            lda #$f8           ; $ecdc: a9 f8     
            sta $0204,y        ; $ecde: 99 04 02  
            sta $020c,y        ; $ece1: 99 0c 02  
__ece4:     rts                ; $ece4: 60        

;-------------------------------------------------------------------------------
__ece5:     ldy $06f1,x        ; $ece5: bc f1 06  
            lda $03ba          ; $ece8: ad ba 03  
            sta $0200,y        ; $eceb: 99 00 02  
            lda $03af          ; $ecee: ad af 03  
__ecf1:     sta $0203,y        ; $ecf1: 99 03 02  
__ecf4:     lda $09            ; $ecf4: a5 09     
            lsr                ; $ecf6: 4a        
            lsr                ; $ecf7: 4a        
            pha                ; $ecf8: 48        
            and #$01           ; $ecf9: 29 01     
            eor #$64           ; $ecfb: 49 64     
            sta $0201,y        ; $ecfd: 99 01 02  
            pla                ; $ed00: 68        
            lsr                ; $ed01: 4a        
            lsr                ; $ed02: 4a        
            lda #$02           ; $ed03: a9 02     
            bcc __ed09         ; $ed05: 90 02     
            ora #$c0           ; $ed07: 09 c0     
__ed09:     sta $0202,y        ; $ed09: 99 02 02  
            rts                ; $ed0c: 60        

;-------------------------------------------------------------------------------
__ed0d:     pla                ; $ed0d: 68        
            .hex 67 66         ; $ed0e: 67 66     Invalid Opcode - RRA $66
__ed10:     ldy $06ec,x        ; $ed10: bc ec 06  
            lda $24,x          ; $ed13: b5 24     
            inc $24,x          ; $ed15: f6 24     
            lsr                ; $ed17: 4a        
            and #$07           ; $ed18: 29 07     
            cmp #$03           ; $ed1a: c9 03     
            bcs __ed68         ; $ed1c: b0 4a     
__ed1e:     tax                ; $ed1e: aa        
            lda __ed0d,x       ; $ed1f: bd 0d ed  
            iny                ; $ed22: c8        
            jsr __e5c2         ; $ed23: 20 c2 e5  
            dey                ; $ed26: 88        
            ldx $08            ; $ed27: a6 08     
            lda $03ba          ; $ed29: ad ba 03  
            sec                ; $ed2c: 38        
            sbc #$04           ; $ed2d: e9 04     
            sta $0200,y        ; $ed2f: 99 00 02  
            sta $0208,y        ; $ed32: 99 08 02  
            clc                ; $ed35: 18        
            adc #$08           ; $ed36: 69 08     
            sta $0204,y        ; $ed38: 99 04 02  
            sta $020c,y        ; $ed3b: 99 0c 02  
            lda $03af          ; $ed3e: ad af 03  
            sec                ; $ed41: 38        
            sbc #$04           ; $ed42: e9 04     
            sta $0203,y        ; $ed44: 99 03 02  
            sta $0207,y        ; $ed47: 99 07 02  
            clc                ; $ed4a: 18        
            adc #$08           ; $ed4b: 69 08     
            sta $020b,y        ; $ed4d: 99 0b 02  
            sta $020f,y        ; $ed50: 99 0f 02  
            lda #$02           ; $ed53: a9 02     
            sta $0202,y        ; $ed55: 99 02 02  
            lda #$82           ; $ed58: a9 82     
            sta $0206,y        ; $ed5a: 99 06 02  
            lda #$42           ; $ed5d: a9 42     
            sta $020a,y        ; $ed5f: 99 0a 02  
            lda #$c2           ; $ed62: a9 c2     
            sta $020e,y        ; $ed64: 99 0e 02  
            rts                ; $ed67: 60        

;-------------------------------------------------------------------------------
__ed68:     lda #$00           ; $ed68: a9 00     
            sta $24,x          ; $ed6a: 95 24     
            rts                ; $ed6c: 60        

;-------------------------------------------------------------------------------
__ed6d:     ldy $06e5,x        ; $ed6d: bc e5 06  
            lda #$5b           ; $ed70: a9 5b     
            iny                ; $ed72: c8        
            jsr __e5bc         ; $ed73: 20 bc e5  
            iny                ; $ed76: c8        
            lda #$02           ; $ed77: a9 02     
            jsr __e5bc         ; $ed79: 20 bc e5  
            dey                ; $ed7c: 88        
            dey                ; $ed7d: 88        
            lda $03ae          ; $ed7e: ad ae 03  
            sta $0203,y        ; $ed81: 99 03 02  
            sta $020f,y        ; $ed84: 99 0f 02  
            clc                ; $ed87: 18        
            adc #$08           ; $ed88: 69 08     
            sta $0207,y        ; $ed8a: 99 07 02  
            sta $0213,y        ; $ed8d: 99 13 02  
            clc                ; $ed90: 18        
            adc #$08           ; $ed91: 69 08     
            sta $020b,y        ; $ed93: 99 0b 02  
            sta $0217,y        ; $ed96: 99 17 02  
            lda $cf,x          ; $ed99: b5 cf     
            tax                ; $ed9b: aa        
            pha                ; $ed9c: 48        
            cpx #$20           ; $ed9d: e0 20     
            bcs __eda3         ; $ed9f: b0 02     
            lda #$f8           ; $eda1: a9 f8     
__eda3:     jsr __e5c5         ; $eda3: 20 c5 e5  
            pla                ; $eda6: 68        
            clc                ; $eda7: 18        
            adc #$80           ; $eda8: 69 80     
            tax                ; $edaa: aa        
            cpx #$20           ; $edab: e0 20     
            bcs __edb1         ; $edad: b0 02     
            lda #$f8           ; $edaf: a9 f8     
__edb1:     sta $020c,y        ; $edb1: 99 0c 02  
            sta $0210,y        ; $edb4: 99 10 02  
            sta $0214,y        ; $edb7: 99 14 02  
            lda $03d1          ; $edba: ad d1 03  
            pha                ; $edbd: 48        
            and #$08           ; $edbe: 29 08     
            beq __edca         ; $edc0: f0 08     
            lda #$f8           ; $edc2: a9 f8     
            sta $0200,y        ; $edc4: 99 00 02  
            sta $020c,y        ; $edc7: 99 0c 02  
__edca:     pla                ; $edca: 68        
            pha                ; $edcb: 48        
            and #$04           ; $edcc: 29 04     
            beq __edd8         ; $edce: f0 08     
            lda #$f8           ; $edd0: a9 f8     
            sta $0204,y        ; $edd2: 99 04 02  
            sta $0210,y        ; $edd5: 99 10 02  
__edd8:     pla                ; $edd8: 68        
            and #$02           ; $edd9: 29 02     
            beq __ede5         ; $eddb: f0 08     
            lda #$f8           ; $eddd: a9 f8     
            sta $0208,y        ; $eddf: 99 08 02  
            sta $0214,y        ; $ede2: 99 14 02  
__ede5:     ldx $08            ; $ede5: a6 08     
            rts                ; $ede7: 60        

;-------------------------------------------------------------------------------
__ede8:     ldy $b5            ; $ede8: a4 b5     
            dey                ; $edea: 88        
            .hex d0            ; $edeb: d0        Suspected data
__edec:     jsr __d3ad         ; $edec: 20 ad d3  
            .hex 03 29         ; $edef: 03 29     Invalid Opcode - SLO ($29,x)
            php                ; $edf1: 08        
            bne __ee0d         ; $edf2: d0 19     
            ldy $06ee,x        ; $edf4: bc ee 06  
            lda $03b0          ; $edf7: ad b0 03  
            sta $0203,y        ; $edfa: 99 03 02  
            lda $03bb          ; $edfd: ad bb 03  
__ee00:     .hex 99            ; $ee00: 99        Suspected data
__ee01:     brk                ; $ee01: 00        
__ee02:     .hex 02            ; $ee02: 02        Invalid Opcode - KIL 
            lda #$74           ; $ee03: a9 74     
            sta $0201,y        ; $ee05: 99 01 02  
            lda #$02           ; $ee08: a9 02     
            sta $0202,y        ; $ee0a: 99 02 02  
__ee0d:     rts                ; $ee0d: 60        

;-------------------------------------------------------------------------------
__ee0e:     jsr __c828         ; $ee0e: 20 28 c8  
            clc                ; $ee11: 18        
            brk                ; $ee12: 00        
            rti                ; $ee13: 40        

;-------------------------------------------------------------------------------
            bvc __ee6e         ; $ee14: 50 58     
            .hex 80 88         ; $ee16: 80 88     Invalid Opcode - NOP #$88
            clv                ; $ee18: b8        
            sei                ; $ee19: 78        
            rts                ; $ee1a: 60        

;-------------------------------------------------------------------------------
            ldy #$b0           ; $ee1b: a0 b0     
            clv                ; $ee1d: b8        
__ee1e:     brk                ; $ee1e: 00        
__ee1f:     ora ($02,x)        ; $ee1f: 01 02     
            .hex 03 04         ; $ee21: 03 04     Invalid Opcode - SLO ($04,x)
            ora $06            ; $ee23: 05 06     
            .hex 07 08         ; $ee25: 07 08     Invalid Opcode - SLO $08
__ee27:     ora #$0a           ; $ee27: 09 0a     
            .hex 0b 0c         ; $ee29: 0b 0c     Invalid Opcode - ANC #$0c
            ora $0f0e          ; $ee2b: 0d 0e 0f  
            bpl __ee41         ; $ee2e: 10 11     
            .hex 12            ; $ee30: 12        Invalid Opcode - KIL 
            .hex 13 14         ; $ee31: 13 14     Invalid Opcode - SLO ($14),y
            ora $16,x          ; $ee33: 15 16     
            .hex 17 18         ; $ee35: 17 18     Invalid Opcode - SLO $18,x
            ora $1b1a,y        ; $ee37: 19 1a 1b  
            .hex 1c 1d 1e      ; $ee3a: 1c 1d 1e  Invalid Opcode - NOP $1e1d,x
            .hex 1f 20 21      ; $ee3d: 1f 20 21  Invalid Opcode - SLO $2120,x
            .hex 22            ; $ee40: 22        Invalid Opcode - KIL 
__ee41:     .hex 23 24         ; $ee41: 23 24     Invalid Opcode - RLA ($24,x)
            and $26            ; $ee43: 25 26     
            .hex 27 08         ; $ee45: 27 08     Invalid Opcode - RLA $08
            ora #$28           ; $ee47: 09 28     
            .hex 29            ; $ee49: 29        Suspected data
__ee4a:     rol                ; $ee4a: 2a        
            .hex 2b 2c         ; $ee4b: 2b 2c     Invalid Opcode - ANC #$2c
            and $0908          ; $ee4d: 2d 08 09  
            asl                ; $ee50: 0a        
            .hex 0b 0c         ; $ee51: 0b 0c     Invalid Opcode - ANC #$0c
            bmi __ee81         ; $ee53: 30 2c     
            and $0908          ; $ee55: 2d 08 09  
            asl                ; $ee58: 0a        
            .hex 0b 2e         ; $ee59: 0b 2e     Invalid Opcode - ANC #$2e
            .hex 2f 2c 2d      ; $ee5b: 2f 2c 2d  Invalid Opcode - RLA $2d2c
            php                ; $ee5e: 08        
            ora #$28           ; $ee5f: 09 28     
            and #$2a           ; $ee61: 29 2a     
            .hex 2b 5c         ; $ee63: 2b 5c     Invalid Opcode - ANC #$5c
            eor $0908,x        ; $ee65: 5d 08 09  
            asl                ; $ee68: 0a        
            .hex 0b 0c         ; $ee69: 0b 0c     Invalid Opcode - ANC #$0c
            ora $5f5e          ; $ee6b: 0d 5e 5f  
__ee6e:     .hex fc fc 08      ; $ee6e: fc fc 08  Invalid Opcode - NOP $08fc,x
            ora #$58           ; $ee71: 09 58     
            eor $5a5a,y        ; $ee73: 59 5a 5a  
            php                ; $ee76: 08        
            ora #$28           ; $ee77: 09 28     
            and #$2a           ; $ee79: 29 2a     
            .hex 2b 0e         ; $ee7b: 2b 0e     Invalid Opcode - ANC #$0e
            .hex 0f fc fc      ; $ee7d: 0f fc fc  Invalid Opcode - SLO __fcfc
            .hex fc            ; $ee80: fc        Suspected data
__ee81:     .hex fc 32 33      ; $ee81: fc 32 33  Invalid Opcode - NOP $3332,x
            .hex 34 35         ; $ee84: 34 35     Invalid Opcode - NOP $35,x
            .hex fc fc fc      ; $ee86: fc fc fc  Invalid Opcode - NOP __fcfc,x
            .hex fc 36 37      ; $ee89: fc 36 37  Invalid Opcode - NOP $3736,x
            sec                ; $ee8c: 38        
            and __fcfc,y       ; $ee8d: 39 fc fc  
            .hex fc fc 3a      ; $ee90: fc fc 3a  Invalid Opcode - NOP $3afc,x
            .hex 37 3b         ; $ee93: 37 3b     Invalid Opcode - RLA $3b,x
            .hex 3c fc fc      ; $ee95: 3c fc fc  Invalid Opcode - NOP __fcfc,x
            .hex fc fc 3d      ; $ee98: fc fc 3d  Invalid Opcode - NOP $3dfc,x
            rol $403f,x        ; $ee9b: 3e 3f 40  
            .hex fc fc fc      ; $ee9e: fc fc fc  Invalid Opcode - NOP __fcfc,x
            .hex fc 32 41      ; $eea1: fc 32 41  Invalid Opcode - NOP $4132,x
            .hex 42            ; $eea4: 42        Invalid Opcode - KIL 
            .hex 43 fc         ; $eea5: 43 fc     Invalid Opcode - SRE ($fc,x)
            .hex fc fc fc      ; $eea7: fc fc fc  Invalid Opcode - NOP __fcfc,x
            .hex 32            ; $eeaa: 32        Invalid Opcode - KIL 
            .hex 33 44         ; $eeab: 33 44     Invalid Opcode - RLA ($44),y
            eor $fc            ; $eead: 45 fc     
            .hex fc fc fc      ; $eeaf: fc fc fc  Invalid Opcode - NOP __fcfc,x
            .hex 32            ; $eeb2: 32        Invalid Opcode - KIL 
            .hex 33 44         ; $eeb3: 33 44     Invalid Opcode - RLA ($44),y
            .hex 47 fc         ; $eeb5: 47 fc     Invalid Opcode - SRE $fc
            .hex fc fc fc      ; $eeb7: fc fc fc  Invalid Opcode - NOP __fcfc,x
            .hex 32            ; $eeba: 32        Invalid Opcode - KIL 
            .hex 33            ; $eebb: 33        Suspected data
__eebc:     pha                ; $eebc: 48        
            eor #$fc           ; $eebd: 49 fc     
            .hex fc fc fc      ; $eebf: fc fc fc  Invalid Opcode - NOP __fcfc,x
            .hex 32            ; $eec2: 32        Invalid Opcode - KIL 
            .hex 33 90         ; $eec3: 33 90     Invalid Opcode - RLA ($90),y
            sta ($fc),y        ; $eec5: 91 fc     
            .hex fc fc fc      ; $eec7: fc fc fc  Invalid Opcode - NOP __fcfc,x
            .hex 3a            ; $eeca: 3a        Invalid Opcode - NOP 
            .hex 37 92         ; $eecb: 37 92     Invalid Opcode - RLA $92,x
            .hex 93 fc         ; $eecd: 93 fc     Invalid Opcode - AHX ($fc),y
            .hex fc fc fc      ; $eecf: fc fc fc  Invalid Opcode - NOP __fcfc,x
            .hex 9e 9e 9f      ; $eed2: 9e 9e 9f  Invalid Opcode - SHX __9f9e,y
            .hex 9f fc fc      ; $eed5: 9f fc fc  Invalid Opcode - AHX __fcfc,y
            .hex fc fc 3a      ; $eed8: fc fc 3a  Invalid Opcode - NOP $3afc,x
            .hex 37 4f         ; $eedb: 37 4f     Invalid Opcode - RLA $4f,x
            .hex 4f fc fc      ; $eedd: 4f fc fc  Invalid Opcode - SRE __fcfc
            brk                ; $eee0: 00        
            ora ($4c,x)        ; $eee1: 01 4c     
            eor $4e4e          ; $eee3: 4d 4e 4e  
            brk                ; $eee6: 00        
            .hex 01            ; $eee7: 01        Suspected data
__eee8:     jmp $4a4d          ; $eee8: 4c 4d 4a  

;-------------------------------------------------------------------------------
            lsr                ; $eeeb: 4a        
            .hex 4b 4b         ; $eeec: 4b 4b     Invalid Opcode - ALR #$4b
__eeee:     and ($46),y        ; $eeee: 31 46     
__eef0:     lda $079e          ; $eef0: ad 9e 07  
            beq __eefa         ; $eef3: f0 05     
            lda $09            ; $eef5: a5 09     
            lsr                ; $eef7: 4a        
            bcs __ef3a         ; $eef8: b0 40     
__eefa:     lda $0e            ; $eefa: a5 0e     
            cmp #$0b           ; $eefc: c9 0b     
            beq __ef47         ; $eefe: f0 47     
            lda $070b          ; $ef00: ad 0b 07  
            bne __ef41         ; $ef03: d0 3c     
            ldy $0704          ; $ef05: ac 04 07  
            beq __ef3b         ; $ef08: f0 31     
            lda $1d            ; $ef0a: a5 1d     
            cmp #$00           ; $ef0c: c9 00     
            beq __ef3b         ; $ef0e: f0 2b     
            jsr __ef3b         ; $ef10: 20 3b ef  
            lda $09            ; $ef13: a5 09     
            and #$04           ; $ef15: 29 04     
            bne __ef3a         ; $ef17: d0 21     
            tax                ; $ef19: aa        
            ldy $06e4          ; $ef1a: ac e4 06  
            lda $33            ; $ef1d: a5 33     
            lsr                ; $ef1f: 4a        
            bcs __ef26         ; $ef20: b0 04     
            iny                ; $ef22: c8        
            iny                ; $ef23: c8        
            iny                ; $ef24: c8        
            iny                ; $ef25: c8        
__ef26:     lda $0754          ; $ef26: ad 54 07  
            beq __ef34         ; $ef29: f0 09     
            lda $0219,y        ; $ef2b: b9 19 02  
            cmp __eebc         ; $ef2e: cd bc ee  
            beq __ef3a         ; $ef31: f0 07     
            inx                ; $ef33: e8        
__ef34:     lda __eeee,x       ; $ef34: bd ee ee  
            sta $0219,y        ; $ef37: 99 19 02  
__ef3a:     rts                ; $ef3a: 60        

;-------------------------------------------------------------------------------
__ef3b:     jsr __eff3         ; $ef3b: 20 f3 ef  
            jmp __ef4c         ; $ef3e: 4c 4c ef  

;-------------------------------------------------------------------------------
__ef41:     jsr __f0b7         ; $ef41: 20 b7 f0  
            jmp __ef4c         ; $ef44: 4c 4c ef  

;-------------------------------------------------------------------------------
__ef47:     ldy #$0e           ; $ef47: a0 0e     
            lda __ee0e,y       ; $ef49: b9 0e ee  
__ef4c:     sta $06d5          ; $ef4c: 8d d5 06  
            lda #$04           ; $ef4f: a9 04     
            jsr __efc5         ; $ef51: 20 c5 ef  
            jsr __f0f0         ; $ef54: 20 f0 f0  
            lda $0711          ; $ef57: ad 11 07  
            beq __ef81         ; $ef5a: f0 25     
            ldy #$00           ; $ef5c: a0 00     
            lda $0781          ; $ef5e: ad 81 07  
            cmp $0711          ; $ef61: cd 11 07  
            sty $0711          ; $ef64: 8c 11 07  
            bcs __ef81         ; $ef67: b0 18     
            sta $0711          ; $ef69: 8d 11 07  
            ldy #$07           ; $ef6c: a0 07     
            lda __ee0e,y       ; $ef6e: b9 0e ee  
            sta $06d5          ; $ef71: 8d d5 06  
            ldy #$04           ; $ef74: a0 04     
            lda $57            ; $ef76: a5 57     
            ora $0c            ; $ef78: 05 0c     
            beq __ef7d         ; $ef7a: f0 01     
            dey                ; $ef7c: 88        
__ef7d:     tya                ; $ef7d: 98        
            jsr __efc5         ; $ef7e: 20 c5 ef  
__ef81:     lda $03d0          ; $ef81: ad d0 03  
            lsr                ; $ef84: 4a        
            lsr                ; $ef85: 4a        
            lsr                ; $ef86: 4a        
            lsr                ; $ef87: 4a        
            sta $00            ; $ef88: 85 00     
            ldx #$03           ; $ef8a: a2 03     
            lda $06e4          ; $ef8c: ad e4 06  
            clc                ; $ef8f: 18        
            adc #$18           ; $ef90: 69 18     
            tay                ; $ef92: a8        
__ef93:     lda #$f8           ; $ef93: a9 f8     
            lsr $00            ; $ef95: 46 00     
            bcc __ef9c         ; $ef97: 90 03     
            jsr __e5c8         ; $ef99: 20 c8 e5  
__ef9c:     tya                ; $ef9c: 98        
            sec                ; $ef9d: 38        
            sbc #$08           ; $ef9e: e9 08     
            tay                ; $efa0: a8        
            dex                ; $efa1: ca        
            bpl __ef93         ; $efa2: 10 ef     
            rts                ; $efa4: 60        

;-------------------------------------------------------------------------------
__efa5:     cli                ; $efa5: 58        
            ora ($00,x)        ; $efa6: 01 00     
            rts                ; $efa8: 60        

;-------------------------------------------------------------------------------
            .hex ff 04         ; $efa9: ff 04     Suspected data
__efab:     ldx #$05           ; $efab: a2 05     
__efad:     lda __efa5,x       ; $efad: bd a5 ef  
            sta $02,x          ; $efb0: 95 02     
            dex                ; $efb2: ca        
            bpl __efad         ; $efb3: 10 f8     
            ldx #$b8           ; $efb5: a2 b8     
            ldy #$04           ; $efb7: a0 04     
            jsr __efe3         ; $efb9: 20 e3 ef  
            lda $0226          ; $efbc: ad 26 02  
            ora #$40           ; $efbf: 09 40     
            sta $0222          ; $efc1: 8d 22 02  
            rts                ; $efc4: 60        

;-------------------------------------------------------------------------------
__efc5:     sta $07            ; $efc5: 85 07     
            lda $03ad          ; $efc7: ad ad 03  
            sta $0755          ; $efca: 8d 55 07  
            sta $05            ; $efcd: 85 05     
            lda $03b8          ; $efcf: ad b8 03  
            sta $02            ; $efd2: 85 02     
            lda $33            ; $efd4: a5 33     
            sta $03            ; $efd6: 85 03     
            lda $03c4          ; $efd8: ad c4 03  
            sta $04            ; $efdb: 85 04     
            ldx $06d5          ; $efdd: ae d5 06  
            ldy $06e4          ; $efe0: ac e4 06  
__efe3:     lda __ee1e,x       ; $efe3: bd 1e ee  
            sta $00            ; $efe6: 85 00     
            lda __ee1f,x       ; $efe8: bd 1f ee  
            jsr __ebb9         ; $efeb: 20 b9 eb  
            dec $07            ; $efee: c6 07     
            bne __efe3         ; $eff0: d0 f1     
            rts                ; $eff2: 60        

;-------------------------------------------------------------------------------
__eff3:     lda $1d            ; $eff3: a5 1d     
            cmp #$03           ; $eff5: c9 03     
            beq __f04b         ; $eff7: f0 52     
            cmp #$02           ; $eff9: c9 02     
            beq __f03b         ; $effb: f0 3e     
            cmp #$01           ; $effd: c9 01     
            bne __f012         ; $efff: d0 11     
            lda $0704          ; $f001: ad 04 07  
            bne __f057         ; $f004: d0 51     
            .hex a0            ; $f006: a0        Suspected data
__f007:     asl $ad            ; $f007: 06 ad     
            .hex 14 07         ; $f009: 14 07     Invalid Opcode - NOP $07,x
            bne __f02f         ; $f00b: d0 22     
            ldy #$00           ; $f00d: a0 00     
            jmp __f02f         ; $f00f: 4c 2f f0  

;-------------------------------------------------------------------------------
__f012:     ldy #$06           ; $f012: a0 06     
            lda $0714          ; $f014: ad 14 07  
            bne __f02f         ; $f017: d0 16     
            ldy #$02           ; $f019: a0 02     
            lda $57            ; $f01b: a5 57     
            ora $0c            ; $f01d: 05 0c     
            beq __f02f         ; $f01f: f0 0e     
            lda $0700          ; $f021: ad 00 07  
            cmp #$0a           ; $f024: c9 0a     
            bcc __f043         ; $f026: 90 1b     
            lda $45            ; $f028: a5 45     
            and $33            ; $f02a: 25 33     
            bne __f043         ; $f02c: d0 15     
            iny                ; $f02e: c8        
__f02f:     jsr __f098         ; $f02f: 20 98 f0  
            lda #$00           ; $f032: a9 00     
            sta $070d          ; $f034: 8d 0d 07  
            lda __ee0e,y       ; $f037: b9 0e ee  
            rts                ; $f03a: 60        

;-------------------------------------------------------------------------------
__f03b:     ldy #$04           ; $f03b: a0 04     
            jsr __f098         ; $f03d: 20 98 f0  
            jmp __f069         ; $f040: 4c 69 f0  

;-------------------------------------------------------------------------------
__f043:     ldy #$04           ; $f043: a0 04     
            jsr __f098         ; $f045: 20 98 f0  
            jmp __f06f         ; $f048: 4c 6f f0  

;-------------------------------------------------------------------------------
__f04b:     ldy #$05           ; $f04b: a0 05     
            lda $9f            ; $f04d: a5 9f     
            beq __f02f         ; $f04f: f0 de     
            jsr __f098         ; $f051: 20 98 f0  
            jmp __f074         ; $f054: 4c 74 f0  

;-------------------------------------------------------------------------------
__f057:     ldy #$01           ; $f057: a0 01     
            jsr __f098         ; $f059: 20 98 f0  
            lda $0782          ; $f05c: ad 82 07  
            ora $070d          ; $f05f: 0d 0d 07  
            bne __f06f         ; $f062: d0 0b     
            .hex a5            ; $f064: a5        Suspected data
__f065:     asl                ; $f065: 0a        
            asl                ; $f066: 0a        
            bcs __f06f         ; $f067: b0 06     
__f069:     lda $070d          ; $f069: ad 0d 07  
            jmp __f0d7         ; $f06c: 4c d7 f0  

;-------------------------------------------------------------------------------
__f06f:     lda #$03           ; $f06f: a9 03     
            jmp __f076         ; $f071: 4c 76 f0  

;-------------------------------------------------------------------------------
__f074:     lda #$02           ; $f074: a9 02     
__f076:     sta $00            ; $f076: 85 00     
            jsr __f069         ; $f078: 20 69 f0  
            pha                ; $f07b: 48        
            lda $0781          ; $f07c: ad 81 07  
            bne __f096         ; $f07f: d0 15     
            lda $070c          ; $f081: ad 0c 07  
            sta $0781          ; $f084: 8d 81 07  
            lda $070d          ; $f087: ad 0d 07  
            clc                ; $f08a: 18        
            adc #$01           ; $f08b: 69 01     
            cmp $00            ; $f08d: c5 00     
            bcc __f093         ; $f08f: 90 02     
            lda #$00           ; $f091: a9 00     
__f093:     sta $070d          ; $f093: 8d 0d 07  
__f096:     pla                ; $f096: 68        
            rts                ; $f097: 60        

;-------------------------------------------------------------------------------
__f098:     lda $0754          ; $f098: ad 54 07  
            beq __f0a2         ; $f09b: f0 05     
            tya                ; $f09d: 98        
            clc                ; $f09e: 18        
            adc #$08           ; $f09f: 69 08     
            tay                ; $f0a1: a8        
__f0a2:     rts                ; $f0a2: 60        

;-------------------------------------------------------------------------------
__f0a3:     brk                ; $f0a3: 00        
            ora ($00,x)        ; $f0a4: 01 00     
            ora ($00,x)        ; $f0a6: 01 00     
            ora ($02,x)        ; $f0a8: 01 02     
            brk                ; $f0aa: 00        
            ora ($02,x)        ; $f0ab: 01 02     
            .hex 02            ; $f0ad: 02        Invalid Opcode - KIL 
            brk                ; $f0ae: 00        
            .hex 02            ; $f0af: 02        Invalid Opcode - KIL 
            brk                ; $f0b0: 00        
            .hex 02            ; $f0b1: 02        Invalid Opcode - KIL 
            brk                ; $f0b2: 00        
            .hex 02            ; $f0b3: 02        Invalid Opcode - KIL 
            brk                ; $f0b4: 00        
            .hex 02            ; $f0b5: 02        Invalid Opcode - KIL 
            brk                ; $f0b6: 00        
__f0b7:     ldy $070d          ; $f0b7: ac 0d 07  
            lda $09            ; $f0ba: a5 09     
            and #$03           ; $f0bc: 29 03     
            bne __f0cd         ; $f0be: d0 0d     
            iny                ; $f0c0: c8        
            cpy #$0a           ; $f0c1: c0 0a     
            bcc __f0ca         ; $f0c3: 90 05     
            ldy #$00           ; $f0c5: a0 00     
            sty $070b          ; $f0c7: 8c 0b 07  
__f0ca:     sty $070d          ; $f0ca: 8c 0d 07  
__f0cd:     lda $0754          ; $f0cd: ad 54 07  
            bne __f0de         ; $f0d0: d0 0c     
            lda __f0a3,y       ; $f0d2: b9 a3 f0  
            ldy #$0f           ; $f0d5: a0 0f     
__f0d7:     asl                ; $f0d7: 0a        
            asl                ; $f0d8: 0a        
            asl                ; $f0d9: 0a        
            adc __ee0e,y       ; $f0da: 79 0e ee  
            rts                ; $f0dd: 60        

;-------------------------------------------------------------------------------
__f0de:     tya                ; $f0de: 98        
            clc                ; $f0df: 18        
            adc #$0a           ; $f0e0: 69 0a     
            tax                ; $f0e2: aa        
            ldy #$09           ; $f0e3: a0 09     
            lda __f0a3,x       ; $f0e5: bd a3 f0  
            bne __f0ec         ; $f0e8: d0 02     
            ldy #$01           ; $f0ea: a0 01     
__f0ec:     lda __ee0e,y       ; $f0ec: b9 0e ee  
            rts                ; $f0ef: 60        

;-------------------------------------------------------------------------------
__f0f0:     ldy $06e4          ; $f0f0: ac e4 06  
            lda $0e            ; $f0f3: a5 0e     
            cmp #$0b           ; $f0f5: c9 0b     
            beq __f10c         ; $f0f7: f0 13     
            lda $06d5          ; $f0f9: ad d5 06  
            cmp #$50           ; $f0fc: c9 50     
            beq __f11e         ; $f0fe: f0 1e     
            .hex c9            ; $f100: c9        Suspected data
__f101:     clv                ; $f101: b8        
            beq __f11e         ; $f102: f0 1a     
            cmp #$c0           ; $f104: c9 c0     
            beq __f11e         ; $f106: f0 16     
            cmp #$c8           ; $f108: c9 c8     
            bne __f130         ; $f10a: d0 24     
__f10c:     lda $0212,y        ; $f10c: b9 12 02  
            and #$3f           ; $f10f: 29 3f     
            sta $0212,y        ; $f111: 99 12 02  
            lda $0216,y        ; $f114: b9 16 02  
            and #$3f           ; $f117: 29 3f     
            ora #$40           ; $f119: 09 40     
            sta $0216,y        ; $f11b: 99 16 02  
__f11e:     lda $021a,y        ; $f11e: b9 1a 02  
            and #$3f           ; $f121: 29 3f     
            sta $021a,y        ; $f123: 99 1a 02  
            lda $021e,y        ; $f126: b9 1e 02  
            and #$3f           ; $f129: 29 3f     
            ora #$40           ; $f12b: 09 40     
            sta $021e,y        ; $f12d: 99 1e 02  
__f130:     rts                ; $f130: 60        

;-------------------------------------------------------------------------------
__f131:     ldx #$00           ; $f131: a2 00     
            ldy #$00           ; $f133: a0 00     
            jmp __f149         ; $f135: 4c 49 f1  

;-------------------------------------------------------------------------------
__f138:     .hex a0            ; $f138: a0        Suspected data
__f139:     ora ($20,x)        ; $f139: 01 20     
            .hex af f1 a0      ; $f13b: af f1 a0  Invalid Opcode - LAX __a0f1
            .hex 03 4c         ; $f13e: 03 4c     Invalid Opcode - SLO ($4c,x)
            eor #$f1           ; $f140: 49 f1     
__f142:     ldy #$00           ; $f142: a0 00     
            jsr __f1af         ; $f144: 20 af f1  
            ldy #$02           ; $f147: a0 02     
__f149:     jsr __f178         ; $f149: 20 78 f1  
            ldx $08            ; $f14c: a6 08     
            rts                ; $f14e: 60        

;-------------------------------------------------------------------------------
__f14f:     ldy #$02           ; $f14f: a0 02     
            jsr __f1af         ; $f151: 20 af f1  
            ldy #$06           ; $f154: a0 06     
            jmp __f149         ; $f156: 4c 49 f1  

;-------------------------------------------------------------------------------
__f159:     lda #$01           ; $f159: a9 01     
            ldy #$01           ; $f15b: a0 01     
            jmp __f16c         ; $f15d: 4c 6c f1  

;-------------------------------------------------------------------------------
__f160:     lda #$09           ; $f160: a9 09     
            ldy #$04           ; $f162: a0 04     
            jsr __f16c         ; $f164: 20 6c f1  
            inx                ; $f167: e8        
            inx                ; $f168: e8        
            lda #$09           ; $f169: a9 09     
            iny                ; $f16b: c8        
__f16c:     stx $00            ; $f16c: 86 00     
            clc                ; $f16e: 18        
            adc $00            ; $f16f: 65 00     
            tax                ; $f171: aa        
            jsr __f178         ; $f172: 20 78 f1  
            ldx $08            ; $f175: a6 08     
            rts                ; $f177: 60        

;-------------------------------------------------------------------------------
__f178:     lda $ce,x          ; $f178: b5 ce     
            sta $03b8,y        ; $f17a: 99 b8 03  
            lda $86,x          ; $f17d: b5 86     
            sec                ; $f17f: 38        
            sbc $071c          ; $f180: ed 1c 07  
            sta $03ad,y        ; $f183: 99 ad 03  
            rts                ; $f186: 60        

;-------------------------------------------------------------------------------
__f187:     ldx #$00           ; $f187: a2 00     
            ldy #$00           ; $f189: a0 00     
            jmp __f1c7         ; $f18b: 4c c7 f1  

;-------------------------------------------------------------------------------
__f18e:     ldy #$00           ; $f18e: a0 00     
            jsr __f1af         ; $f190: 20 af f1  
            ldy #$02           ; $f193: a0 02     
            jmp __f1c7         ; $f195: 4c c7 f1  

;-------------------------------------------------------------------------------
__f198:     ldy #$01           ; $f198: a0 01     
            jsr __f1af         ; $f19a: 20 af f1  
            ldy #$03           ; $f19d: a0 03     
            jmp __f1c7         ; $f19f: 4c c7 f1  

;-------------------------------------------------------------------------------
__f1a2:     ldy #$02           ; $f1a2: a0 02     
            jsr __f1af         ; $f1a4: 20 af f1  
            ldy #$06           ; $f1a7: a0 06     
            jmp __f1c7         ; $f1a9: 4c c7 f1  

;-------------------------------------------------------------------------------
__f1ac:     .hex 07 16         ; $f1ac: 07 16     Invalid Opcode - SLO $16
            .hex 0d            ; $f1ae: 0d        Suspected data
__f1af:     txa                ; $f1af: 8a        
            clc                ; $f1b0: 18        
            adc __f1ac,y       ; $f1b1: 79 ac f1  
            tax                ; $f1b4: aa        
            rts                ; $f1b5: 60        

;-------------------------------------------------------------------------------
__f1b6:     lda #$01           ; $f1b6: a9 01     
            ldy #$01           ; $f1b8: a0 01     
            jmp __f1c1         ; $f1ba: 4c c1 f1  

;-------------------------------------------------------------------------------
__f1bd:     lda #$09           ; $f1bd: a9 09     
            ldy #$04           ; $f1bf: a0 04     
__f1c1:     stx $00            ; $f1c1: 86 00     
            clc                ; $f1c3: 18        
            adc $00            ; $f1c4: 65 00     
            tax                ; $f1c6: aa        
__f1c7:     tya                ; $f1c7: 98        
            pha                ; $f1c8: 48        
            jsr __f1de         ; $f1c9: 20 de f1  
            asl                ; $f1cc: 0a        
            asl                ; $f1cd: 0a        
            asl                ; $f1ce: 0a        
            asl                ; $f1cf: 0a        
            ora $00            ; $f1d0: 05 00     
            sta $00            ; $f1d2: 85 00     
            pla                ; $f1d4: 68        
            tay                ; $f1d5: a8        
            lda $00            ; $f1d6: a5 00     
            sta $03d0,y        ; $f1d8: 99 d0 03  
            ldx $08            ; $f1db: a6 08     
            rts                ; $f1dd: 60        

;-------------------------------------------------------------------------------
__f1de:     jsr __f1fd         ; $f1de: 20 fd f1  
            lsr                ; $f1e1: 4a        
            lsr                ; $f1e2: 4a        
            lsr                ; $f1e3: 4a        
            lsr                ; $f1e4: 4a        
            sta $00            ; $f1e5: 85 00     
            jmp __f240         ; $f1e7: 4c 40 f2  

;-------------------------------------------------------------------------------
__f1ea:     .hex 7f 3f 1f      ; $f1ea: 7f 3f 1f  Invalid Opcode - RRA $1f3f,x
            .hex 0f 07 03      ; $f1ed: 0f 07 03  Invalid Opcode - SLO $0307
            ora ($00,x)        ; $f1f0: 01 00     
            .hex 80 c0         ; $f1f2: 80 c0     Invalid Opcode - NOP #$c0
            cpx #$f0           ; $f1f4: e0 f0     
            sed                ; $f1f6: f8        
            .hex fc fe ff      ; $f1f7: fc fe ff  Invalid Opcode - NOP $fffe,x
__f1fa:     .hex 07            ; $f1fa: 07        Suspected data
__f1fb:     .hex 0f 07         ; $f1fb: 0f 07     Suspected data
__f1fd:     stx $04            ; $f1fd: 86 04     
            ldy #$01           ; $f1ff: a0 01     
__f201:     lda $071c,y        ; $f201: b9 1c 07  
            sec                ; $f204: 38        
            sbc $86,x          ; $f205: f5 86     
            sta $07            ; $f207: 85 07     
            lda $071a,y        ; $f209: b9 1a 07  
            sbc $6d,x          ; $f20c: f5 6d     
            ldx __f1fa,y       ; $f20e: be fa f1  
            cmp #$00           ; $f211: c9 00     
            bmi __f225         ; $f213: 30 10     
            ldx __f1fb,y       ; $f215: be fb f1  
            cmp #$01           ; $f218: c9 01     
            bpl __f225         ; $f21a: 10 09     
            lda #$38           ; $f21c: a9 38     
            sta $06            ; $f21e: 85 06     
            lda #$08           ; $f220: a9 08     
            jsr __f274         ; $f222: 20 74 f2  
__f225:     lda __f1ea,x       ; $f225: bd ea f1  
            ldx $04            ; $f228: a6 04     
            cmp #$00           ; $f22a: c9 00     
            bne __f231         ; $f22c: d0 03     
            dey                ; $f22e: 88        
            bpl __f201         ; $f22f: 10 d0     
__f231:     rts                ; $f231: 60        

;-------------------------------------------------------------------------------
__f232:     brk                ; $f232: 00        
            php                ; $f233: 08        
            .hex 0c 0e 0f      ; $f234: 0c 0e 0f  Invalid Opcode - NOP $0f0e
            .hex 07 03         ; $f237: 07 03     Invalid Opcode - SLO $03
            ora ($00,x)        ; $f239: 01 00     
__f23b:     .hex 04            ; $f23b: 04        Suspected data
__f23c:     brk                ; $f23c: 00        
            .hex 04            ; $f23d: 04        Suspected data
__f23e:     .hex ff 00         ; $f23e: ff 00     Suspected data
__f240:     stx $04            ; $f240: 86 04     
            ldy #$01           ; $f242: a0 01     
__f244:     lda __f23e,y       ; $f244: b9 3e f2  
            sec                ; $f247: 38        
            sbc $ce,x          ; $f248: f5 ce     
            sta $07            ; $f24a: 85 07     
            lda #$01           ; $f24c: a9 01     
            sbc $b5,x          ; $f24e: f5 b5     
            ldx __f23b,y       ; $f250: be 3b f2  
            cmp #$00           ; $f253: c9 00     
            bmi __f267         ; $f255: 30 10     
            ldx __f23c,y       ; $f257: be 3c f2  
            cmp #$01           ; $f25a: c9 01     
            bpl __f267         ; $f25c: 10 09     
            lda #$20           ; $f25e: a9 20     
            sta $06            ; $f260: 85 06     
            lda #$04           ; $f262: a9 04     
            jsr __f274         ; $f264: 20 74 f2  
__f267:     lda __f232,x       ; $f267: bd 32 f2  
            ldx $04            ; $f26a: a6 04     
            cmp #$00           ; $f26c: c9 00     
            bne __f273         ; $f26e: d0 03     
            dey                ; $f270: 88        
            bpl __f244         ; $f271: 10 d1     
__f273:     rts                ; $f273: 60        

;-------------------------------------------------------------------------------
__f274:     sta $05            ; $f274: 85 05     
            lda $07            ; $f276: a5 07     
            cmp $06            ; $f278: c5 06     
            bcs __f288         ; $f27a: b0 0c     
            lsr                ; $f27c: 4a        
            lsr                ; $f27d: 4a        
            lsr                ; $f27e: 4a        
            and #$07           ; $f27f: 29 07     
            cpy #$01           ; $f281: c0 01     
            bcs __f287         ; $f283: b0 02     
            adc $05            ; $f285: 65 05     
__f287:     tax                ; $f287: aa        
__f288:     rts                ; $f288: 60        

;-------------------------------------------------------------------------------
__f289:     lda $03            ; $f289: a5 03     
            lsr                ; $f28b: 4a        
            lsr                ; $f28c: 4a        
            lda $00            ; $f28d: a5 00     
            bcc __f29d         ; $f28f: 90 0c     
            sta $0205,y        ; $f291: 99 05 02  
            lda $01            ; $f294: a5 01     
            sta $0201,y        ; $f296: 99 01 02  
            .hex a9            ; $f299: a9        Suspected data
__f29a:     rti                ; $f29a: 40        

;-------------------------------------------------------------------------------
            bne __f2a7         ; $f29b: d0 0a     
__f29d:     sta $0201,y        ; $f29d: 99 01 02  
            lda $01            ; $f2a0: a5 01     
            sta $0205,y        ; $f2a2: 99 05 02  
            lda #$00           ; $f2a5: a9 00     
__f2a7:     ora $04            ; $f2a7: 05 04     
            sta $0202,y        ; $f2a9: 99 02 02  
            sta $0206,y        ; $f2ac: 99 06 02  
            lda $02            ; $f2af: a5 02     
            sta $0200,y        ; $f2b1: 99 00 02  
            sta $0204,y        ; $f2b4: 99 04 02  
            lda $05            ; $f2b7: a5 05     
            sta $0203,y        ; $f2b9: 99 03 02  
            clc                ; $f2bc: 18        
            adc #$08           ; $f2bd: 69 08     
            sta $0207,y        ; $f2bf: 99 07 02  
            lda $02            ; $f2c2: a5 02     
            clc                ; $f2c4: 18        
            adc #$08           ; $f2c5: 69 08     
            sta $02            ; $f2c7: 85 02     
            tya                ; $f2c9: 98        
            clc                ; $f2ca: 18        
            adc #$08           ; $f2cb: 69 08     
            tay                ; $f2cd: a8        
            inx                ; $f2ce: e8        
            inx                ; $f2cf: e8        
            rts                ; $f2d0: 60        

;-------------------------------------------------------------------------------
__f2d1:     lda $0770          ; $f2d1: ad 70 07  
            bne __f2da         ; $f2d4: d0 04     
            sta $4015          ; $f2d6: 8d 15 40  
            rts                ; $f2d9: 60        

;-------------------------------------------------------------------------------
__f2da:     lda #$ff           ; $f2da: a9 ff     
            sta $4017          ; $f2dc: 8d 17 40  
            lda #$0f           ; $f2df: a9 0f     
            sta $4015          ; $f2e1: 8d 15 40  
            lda $07c6          ; $f2e4: ad c6 07  
            bne __f2ef         ; $f2e7: d0 06     
            lda $fa            ; $f2e9: a5 fa     
            cmp #$01           ; $f2eb: c9 01     
            bne __f34c         ; $f2ed: d0 5d     
__f2ef:     lda $07b2          ; $f2ef: ad b2 07  
            bne __f317         ; $f2f2: d0 23     
            lda $fa            ; $f2f4: a5 fa     
            beq __f35e         ; $f2f6: f0 66     
            sta $07b2          ; $f2f8: 8d b2 07  
            sta $07c6          ; $f2fb: 8d c6 07  
            lda #$00           ; $f2fe: a9 00     
            sta $4015          ; $f300: 8d 15 40  
            sta $f1            ; $f303: 85 f1     
            sta $f2            ; $f305: 85 f2     
            sta $f3            ; $f307: 85 f3     
            lda #$0f           ; $f309: a9 0f     
            sta $4015          ; $f30b: 8d 15 40  
            lda #$2a           ; $f30e: a9 2a     
            sta $07bb          ; $f310: 8d bb 07  
__f313:     lda #$44           ; $f313: a9 44     
            bne __f328         ; $f315: d0 11     
__f317:     lda $07bb          ; $f317: ad bb 07  
            cmp #$24           ; $f31a: c9 24     
            beq __f326         ; $f31c: f0 08     
            cmp #$1e           ; $f31e: c9 1e     
            beq __f313         ; $f320: f0 f1     
            cmp #$18           ; $f322: c9 18     
            bne __f32f         ; $f324: d0 09     
__f326:     lda #$64           ; $f326: a9 64     
__f328:     ldx #$84           ; $f328: a2 84     
            ldy #$7f           ; $f32a: a0 7f     
            jsr __f389         ; $f32c: 20 89 f3  
__f32f:     dec $07bb          ; $f32f: ce bb 07  
            bne __f35e         ; $f332: d0 2a     
            lda #$00           ; $f334: a9 00     
            sta $4015          ; $f336: 8d 15 40  
            lda $07b2          ; $f339: ad b2 07  
            cmp #$02           ; $f33c: c9 02     
            bne __f345         ; $f33e: d0 05     
            lda #$00           ; $f340: a9 00     
            sta $07c6          ; $f342: 8d c6 07  
__f345:     lda #$00           ; $f345: a9 00     
            sta $07b2          ; $f347: 8d b2 07  
            .hex f0            ; $f34a: f0        Suspected data
__f34b:     .hex 12            ; $f34b: 12        Invalid Opcode - KIL 
__f34c:     jsr __f41c         ; $f34c: 20 1c f4  
            jsr __f57d         ; $f34f: 20 7d f5  
            jsr __f668         ; $f352: 20 68 f6  
            jsr __f695         ; $f355: 20 95 f6  
            lda #$00           ; $f358: a9 00     
            sta $fb            ; $f35a: 85 fb     
            sta $fc            ; $f35c: 85 fc     
__f35e:     lda #$00           ; $f35e: a9 00     
            sta $ff            ; $f360: 85 ff     
            sta $fe            ; $f362: 85 fe     
            sta $fd            ; $f364: 85 fd     
            sta $fa            ; $f366: 85 fa     
            ldy $07c0          ; $f368: ac c0 07  
            lda $f4            ; $f36b: a5 f4     
            and #$03           ; $f36d: 29 03     
            beq __f378         ; $f36f: f0 07     
            inc $07c0          ; $f371: ee c0 07  
            cpy #$30           ; $f374: c0 30     
            bcc __f37e         ; $f376: 90 06     
__f378:     tya                ; $f378: 98        
            beq __f37e         ; $f379: f0 03     
            dec $07c0          ; $f37b: ce c0 07  
__f37e:     sty $4011          ; $f37e: 8c 11 40  
            rts                ; $f381: 60        

;-------------------------------------------------------------------------------
__f382:     sty $4001          ; $f382: 8c 01 40  
            stx $4000          ; $f385: 8e 00 40  
            rts                ; $f388: 60        

;-------------------------------------------------------------------------------
__f389:     jsr __f382         ; $f389: 20 82 f3  
__f38c:     ldx #$00           ; $f38c: a2 00     
__f38e:     tay                ; $f38e: a8        
            lda __ff01,y       ; $f38f: b9 01 ff  
            beq __f39f         ; $f392: f0 0b     
            sta $4002,x        ; $f394: 9d 02 40  
            lda __ff00,y       ; $f397: b9 00 ff  
            ora #$08           ; $f39a: 09 08     
            sta $4003,x        ; $f39c: 9d 03 40  
__f39f:     rts                ; $f39f: 60        

;-------------------------------------------------------------------------------
__f3a0:     stx $4004          ; $f3a0: 8e 04 40  
            sty $4005          ; $f3a3: 8c 05 40  
            rts                ; $f3a6: 60        

;-------------------------------------------------------------------------------
__f3a7:     jsr __f3a0         ; $f3a7: 20 a0 f3  
__f3aa:     ldx #$04           ; $f3aa: a2 04     
            bne __f38e         ; $f3ac: d0 e0     
            ldx #$08           ; $f3ae: a2 08     
            .hex d0            ; $f3b0: d0        Suspected data
__f3b1:     .hex dc 9f 9b      ; $f3b1: dc 9f 9b  Invalid Opcode - NOP __9b9f,x
            tya                ; $f3b4: 98        
            stx $95,y          ; $f3b5: 96 95     
__f3b7:     sty $92,x          ; $f3b7: 94 92     
            bcc __f34b         ; $f3b9: 90 90     
            txs                ; $f3bb: 9a        
            .hex 97 95         ; $f3bc: 97 95     Invalid Opcode - SAX $95,y
            .hex 93 92         ; $f3be: 93 92     Invalid Opcode - AHX ($92),y
__f3c0:     lda #$40           ; $f3c0: a9 40     
            sta $07bb          ; $f3c2: 8d bb 07  
            lda #$62           ; $f3c5: a9 62     
            jsr __f38c         ; $f3c7: 20 8c f3  
            ldx #$99           ; $f3ca: a2 99     
            bne __f3f3         ; $f3cc: d0 25     
__f3ce:     lda #$26           ; $f3ce: a9 26     
            bne __f3d4         ; $f3d0: d0 02     
__f3d2:     lda #$18           ; $f3d2: a9 18     
__f3d4:     ldx #$82           ; $f3d4: a2 82     
            ldy #$a7           ; $f3d6: a0 a7     
            jsr __f389         ; $f3d8: 20 89 f3  
            lda #$28           ; $f3db: a9 28     
            sta $07bb          ; $f3dd: 8d bb 07  
__f3e0:     lda $07bb          ; $f3e0: ad bb 07  
            cmp #$25           ; $f3e3: c9 25     
            bne __f3ed         ; $f3e5: d0 06     
            ldx #$5f           ; $f3e7: a2 5f     
            ldy #$f6           ; $f3e9: a0 f6     
            bne __f3f5         ; $f3eb: d0 08     
__f3ed:     cmp #$20           ; $f3ed: c9 20     
            bne __f41a         ; $f3ef: d0 29     
            ldx #$48           ; $f3f1: a2 48     
__f3f3:     ldy #$bc           ; $f3f3: a0 bc     
__f3f5:     jsr __f382         ; $f3f5: 20 82 f3  
            bne __f41a         ; $f3f8: d0 20     
__f3fa:     lda #$05           ; $f3fa: a9 05     
            ldy #$99           ; $f3fc: a0 99     
            bne __f404         ; $f3fe: d0 04     
__f400:     lda #$0a           ; $f400: a9 0a     
            ldy #$93           ; $f402: a0 93     
__f404:     ldx #$9e           ; $f404: a2 9e     
            sta $07bb          ; $f406: 8d bb 07  
            lda #$0c           ; $f409: a9 0c     
            jsr __f389         ; $f40b: 20 89 f3  
__f40e:     lda $07bb          ; $f40e: ad bb 07  
            cmp #$06           ; $f411: c9 06     
            bne __f41a         ; $f413: d0 05     
            lda #$bb           ; $f415: a9 bb     
            sta $4001          ; $f417: 8d 01 40  
__f41a:     bne __f47c         ; $f41a: d0 60     
__f41c:     ldy $ff            ; $f41c: a4 ff     
            beq __f440         ; $f41e: f0 20     
            sty $f1            ; $f420: 84 f1     
            bmi __f3ce         ; $f422: 30 aa     
            lsr $ff            ; $f424: 46 ff     
            bcs __f3d2         ; $f426: b0 aa     
            lsr $ff            ; $f428: 46 ff     
            bcs __f400         ; $f42a: b0 d4     
            lsr $ff            ; $f42c: 46 ff     
            bcs __f45c         ; $f42e: b0 2c     
            lsr $ff            ; $f430: 46 ff     
            bcs __f47e         ; $f432: b0 4a     
            lsr $ff            ; $f434: 46 ff     
;            bcs __f3b7         ; $f436: b0 7f     
; MODIFICATION
            .hex b0 7f         ; $f436: b0 7f     
            lsr $ff            ; $f438: 46 ff     
            bcs __f3fa         ; $f43a: b0 be     
            lsr $ff            ; $f43c: 46 ff     
            bcs __f3c0         ; $f43e: b0 80     
__f440:     lda $f1            ; $f440: a5 f1     
            beq __f45b         ; $f442: f0 17     
            bmi __f3e0         ; $f444: 30 9a     
            lsr                ; $f446: 4a        
            bcs __f3e0         ; $f447: b0 97     
            lsr                ; $f449: 4a        
            bcs __f40e         ; $f44a: b0 c2     
            lsr                ; $f44c: 4a        
            bcs __f46a         ; $f44d: b0 1b     
            lsr                ; $f44f: 4a        
            bcs __f48e         ; $f450: b0 3c     
            lsr                ; $f452: 4a        
            bcs __f4bc         ; $f453: b0 67     
            lsr                ; $f455: 4a        
            bcs __f40e         ; $f456: b0 b6     
            lsr                ; $f458: 4a        
            bcs __f4a3         ; $f459: b0 48     
__f45b:     rts                ; $f45b: 60        

;-------------------------------------------------------------------------------
__f45c:     lda #$0e           ; $f45c: a9 0e     
            sta $07bb          ; $f45e: 8d bb 07  
            ldy #$9c           ; $f461: a0 9c     
            ldx #$9e           ; $f463: a2 9e     
            lda #$26           ; $f465: a9 26     
            jsr __f389         ; $f467: 20 89 f3  
__f46a:     ldy $07bb          ; $f46a: ac bb 07  
            lda __f3b1,y       ; $f46d: b9 b1 f3  
            sta $4000          ; $f470: 8d 00 40  
            cpy #$06           ; $f473: c0 06     
            bne __f47c         ; $f475: d0 05     
            lda #$9e           ; $f477: a9 9e     
            sta $4002          ; $f479: 8d 02 40  
__f47c:     bne __f4a3         ; $f47c: d0 25     
__f47e:     lda #$0e           ; $f47e: a9 0e     
            ldy #$cb           ; $f480: a0 cb     
            ldx #$9f           ; $f482: a2 9f     
            sta $07bb          ; $f484: 8d bb 07  
            lda #$28           ; $f487: a9 28     
            jsr __f389         ; $f489: 20 89 f3  
            bne __f4a3         ; $f48c: d0 15     
__f48e:     ldy $07bb          ; $f48e: ac bb 07  
            cpy #$08           ; $f491: c0 08     
            bne __f49e         ; $f493: d0 09     
            lda #$a0           ; $f495: a9 a0     
            sta $4002          ; $f497: 8d 02 40  
            lda #$9f           ; $f49a: a9 9f     
            bne __f4a0         ; $f49c: d0 02     
__f49e:     lda #$90           ; $f49e: a9 90     
__f4a0:     sta $4000          ; $f4a0: 8d 00 40  
__f4a3:     dec $07bb          ; $f4a3: ce bb 07  
            bne __f4b6         ; $f4a6: d0 0e     
__f4a8:     ldx #$00           ; $f4a8: a2 00     
            stx $f1            ; $f4aa: 86 f1     
            ldx #$0e           ; $f4ac: a2 0e     
            stx $4015          ; $f4ae: 8e 15 40  
            ldx #$0f           ; $f4b1: a2 0f     
            stx $4015          ; $f4b3: 8e 15 40  
__f4b6:     rts                ; $f4b6: 60        

;-------------------------------------------------------------------------------
            lda #$2f           ; $f4b7: a9 2f     
            sta $07bb          ; $f4b9: 8d bb 07  
__f4bc:     lda $07bb          ; $f4bc: ad bb 07  
            lsr                ; $f4bf: 4a        
            bcs __f4d2         ; $f4c0: b0 10     
            lsr                ; $f4c2: 4a        
            bcs __f4d2         ; $f4c3: b0 0d     
            and #$02           ; $f4c5: 29 02     
            beq __f4d2         ; $f4c7: f0 09     
            ldy #$91           ; $f4c9: a0 91     
            ldx #$9a           ; $f4cb: a2 9a     
            lda #$44           ; $f4cd: a9 44     
            jsr __f389         ; $f4cf: 20 89 f3  
__f4d2:     .hex 4c a3         ; $f4d2: 4c a3     Suspected data
__f4d4:     .hex f4 58         ; $f4d4: f4 58     Invalid Opcode - NOP $58,x
            .hex 02            ; $f4d6: 02        Invalid Opcode - KIL 
            .hex 54 56         ; $f4d7: 54 56     Invalid Opcode - NOP $56,x
            .hex 4e            ; $f4d9: 4e        Suspected data
__f4da:     .hex 44 4c         ; $f4da: 44 4c     Invalid Opcode - NOP $4c
            .hex 52            ; $f4dc: 52        Invalid Opcode - KIL 
            jmp $3e48          ; $f4dd: 4c 48 3e  

;-------------------------------------------------------------------------------
            rol $3e,x          ; $f4e0: 36 3e     
            rol $30,x          ; $f4e2: 36 30     
            plp                ; $f4e4: 28        
            lsr                ; $f4e5: 4a        
            bvc __f532         ; $f4e6: 50 4a     
            .hex 64 3c         ; $f4e8: 64 3c     Invalid Opcode - NOP $3c
            .hex 32            ; $f4ea: 32        Invalid Opcode - KIL 
            .hex 3c 32 2c      ; $f4eb: 3c 32 2c  Invalid Opcode - NOP $2c32,x
            bit $3a            ; $f4ee: 24 3a     
            .hex 64 3a         ; $f4f0: 64 3a     Invalid Opcode - NOP $3a
            .hex 34 2c         ; $f4f2: 34 2c     Invalid Opcode - NOP $2c,x
            .hex 22            ; $f4f4: 22        Invalid Opcode - KIL 
            bit $1c22          ; $f4f5: 2c 22 1c  
            .hex 14            ; $f4f8: 14        Suspected data
__f4f9:     .hex 14 04         ; $f4f9: 14 04     Invalid Opcode - NOP $04,x
            .hex 22            ; $f4fb: 22        Invalid Opcode - KIL 
            bit $16            ; $f4fc: 24 16     
            .hex 04 24         ; $f4fe: 04 24     Invalid Opcode - NOP $24
            rol $18            ; $f500: 26 18     
            .hex 04 26         ; $f502: 04 26     Invalid Opcode - NOP $26
            plp                ; $f504: 28        
            .hex 1a            ; $f505: 1a        Invalid Opcode - NOP 
            .hex 04 28         ; $f506: 04 28     Invalid Opcode - NOP $28
            rol                ; $f508: 2a        
            .hex 1c 04 2a      ; $f509: 1c 04 2a  Invalid Opcode - NOP $2a04,x
            bit $041e          ; $f50c: 2c 1e 04  
            bit $202e          ; $f50f: 2c 2e 20  
            .hex 04 2e         ; $f512: 04 2e     Invalid Opcode - NOP $2e
            bmi __f538         ; $f514: 30 22     
            .hex 04 30         ; $f516: 04 30     Invalid Opcode - NOP $30
            .hex 32            ; $f518: 32        Invalid Opcode - KIL 
__f519:     lda #$35           ; $f519: a9 35     
            ldx #$8d           ; $f51b: a2 8d     
            bne __f523         ; $f51d: d0 04     
__f51f:     lda #$06           ; $f51f: a9 06     
            ldx #$98           ; $f521: a2 98     
__f523:     sta $07bd          ; $f523: 8d bd 07  
            ldy #$7f           ; $f526: a0 7f     
            lda #$42           ; $f528: a9 42     
            jsr __f3a7         ; $f52a: 20 a7 f3  
__f52d:     lda $07bd          ; $f52d: ad bd 07  
            cmp #$30           ; $f530: c9 30     
__f532:     bne __f539         ; $f532: d0 05     
            lda #$4e           ; $f534: a9 4e     
            .hex 8d 06         ; $f536: 8d 06     Suspected data
__f538:     rti                ; $f538: 40        

;-------------------------------------------------------------------------------
__f539:     bne __f569         ; $f539: d0 2e     
__f53b:     lda #$20           ; $f53b: a9 20     
            sta $07bd          ; $f53d: 8d bd 07  
            ldy #$94           ; $f540: a0 94     
            lda #$5e           ; $f542: a9 5e     
            bne __f551         ; $f544: d0 0b     
__f546:     lda $07bd          ; $f546: ad bd 07  
            cmp #$18           ; $f549: c9 18     
            bne __f569         ; $f54b: d0 1c     
            ldy #$93           ; $f54d: a0 93     
            lda #$18           ; $f54f: a9 18     
;__f551:     bne __f4d2         ; $f551: d0 7f     
; MODIFICATION
__f551:     .hex d0 7f         ; $f551: d0 7f     
__f553:     lda #$36           ; $f553: a9 36     
            sta $07bd          ; $f555: 8d bd 07  
__f558:     lda $07bd          ; $f558: ad bd 07  
            lsr                ; $f55b: 4a        
            bcs __f569         ; $f55c: b0 0b     
            tay                ; $f55e: a8        
            lda __f4da,y       ; $f55f: b9 da f4  
            ldx #$5d           ; $f562: a2 5d     
            ldy #$7f           ; $f564: a0 7f     
__f566:     jsr __f3a7         ; $f566: 20 a7 f3  
__f569:     dec $07bd          ; $f569: ce bd 07  
            bne __f57c         ; $f56c: d0 0e     
__f56e:     ldx #$00           ; $f56e: a2 00     
            stx $f2            ; $f570: 86 f2     
__f572:     ldx #$0d           ; $f572: a2 0d     
            stx $4015          ; $f574: 8e 15 40  
            ldx #$0f           ; $f577: a2 0f     
            stx $4015          ; $f579: 8e 15 40  
__f57c:     rts                ; $f57c: 60        

;-------------------------------------------------------------------------------
__f57d:     lda $f2            ; $f57d: a5 f2     
            and #$40           ; $f57f: 29 40     
            bne __f5e8         ; $f581: d0 65     
            ldy $fe            ; $f583: a4 fe     
            beq __f5a7         ; $f585: f0 20     
            sty $f2            ; $f587: 84 f2     
            bmi __f5c9         ; $f589: 30 3e     
            lsr $fe            ; $f58b: 46 fe     
            bcs __f519         ; $f58d: b0 8a     
            lsr $fe            ; $f58f: 46 fe     
            bcs __f5fd         ; $f591: b0 6a     
            lsr $fe            ; $f593: 46 fe     
            bcs __f601         ; $f595: b0 6a     
            lsr $fe            ; $f597: 46 fe     
            bcs __f53b         ; $f599: b0 a0     
            lsr $fe            ; $f59b: 46 fe     
            bcs __f51f         ; $f59d: b0 80     
            lsr $fe            ; $f59f: 46 fe     
            bcs __f553         ; $f5a1: b0 b0     
            lsr $fe            ; $f5a3: 46 fe     
            bcs __f5e3         ; $f5a5: b0 3c     
__f5a7:     lda $f2            ; $f5a7: a5 f2     
            beq __f5c2         ; $f5a9: f0 17     
            bmi __f5d4         ; $f5ab: 30 27     
            lsr                ; $f5ad: 4a        
            bcs __f5c3         ; $f5ae: b0 13     
            lsr                ; $f5b0: 4a        
            bcs __f610         ; $f5b1: b0 5d     
            lsr                ; $f5b3: 4a        
            bcs __f610         ; $f5b4: b0 5a     
            lsr                ; $f5b6: 4a        
            bcs __f546         ; $f5b7: b0 8d     
            lsr                ; $f5b9: 4a        
            bcs __f5c3         ; $f5ba: b0 07     
            lsr                ; $f5bc: 4a        
            bcs __f558         ; $f5bd: b0 99     
            lsr                ; $f5bf: 4a        
            bcs __f5e8         ; $f5c0: b0 26     
__f5c2:     rts                ; $f5c2: 60        

;-------------------------------------------------------------------------------
__f5c3:     jmp __f52d         ; $f5c3: 4c 2d f5  

;-------------------------------------------------------------------------------
__f5c6:     jmp __f569         ; $f5c6: 4c 69 f5  

;-------------------------------------------------------------------------------
__f5c9:     lda #$38           ; $f5c9: a9 38     
            sta $07bd          ; $f5cb: 8d bd 07  
            ldy #$c4           ; $f5ce: a0 c4     
            lda #$18           ; $f5d0: a9 18     
            bne __f5df         ; $f5d2: d0 0b     
__f5d4:     lda $07bd          ; $f5d4: ad bd 07  
            cmp #$08           ; $f5d7: c9 08     
            bne __f569         ; $f5d9: d0 8e     
            ldy #$a4           ; $f5db: a0 a4     
            lda #$5a           ; $f5dd: a9 5a     
__f5df:     ldx #$9f           ; $f5df: a2 9f     
__f5e1:     bne __f566         ; $f5e1: d0 83     
__f5e3:     lda #$30           ; $f5e3: a9 30     
            sta $07bd          ; $f5e5: 8d bd 07  
__f5e8:     lda $07bd          ; $f5e8: ad bd 07  
            ldx #$03           ; $f5eb: a2 03     
__f5ed:     lsr                ; $f5ed: 4a        
            bcs __f5c6         ; $f5ee: b0 d6     
            dex                ; $f5f0: ca        
            bne __f5ed         ; $f5f1: d0 fa     
            tay                ; $f5f3: a8        
            lda __f4d4,y       ; $f5f4: b9 d4 f4  
            ldx #$82           ; $f5f7: a2 82     
            ldy #$7f           ; $f5f9: a0 7f     
            bne __f5e1         ; $f5fb: d0 e4     
__f5fd:     lda #$10           ; $f5fd: a9 10     
            bne __f603         ; $f5ff: d0 02     
__f601:     lda #$20           ; $f601: a9 20     
__f603:     sta $07bd          ; $f603: 8d bd 07  
            lda #$7f           ; $f606: a9 7f     
            sta $4005          ; $f608: 8d 05 40  
            lda #$00           ; $f60b: a9 00     
            sta $07be          ; $f60d: 8d be 07  
__f610:     inc $07be          ; $f610: ee be 07  
            lda $07be          ; $f613: ad be 07  
            lsr                ; $f616: 4a        
            tay                ; $f617: a8        
            cpy $07bd          ; $f618: cc bd 07  
            beq __f629         ; $f61b: f0 0c     
            lda #$9d           ; $f61d: a9 9d     
            sta $4004          ; $f61f: 8d 04 40  
            lda __f4f9,y       ; $f622: b9 f9 f4  
            jsr __f3aa         ; $f625: 20 aa f3  
            rts                ; $f628: 60        

;-------------------------------------------------------------------------------
__f629:     jmp __f56e         ; $f629: 4c 6e f5  

;-------------------------------------------------------------------------------
__f62c:     ora ($0e,x)        ; $f62c: 01 0e     
            asl $0b0d          ; $f62e: 0e 0d 0b  
            asl $0c            ; $f631: 06 0c     
            .hex 0f 0a 09      ; $f633: 0f 0a 09  Invalid Opcode - SLO $090a
            .hex 03 0d         ; $f636: 03 0d     Invalid Opcode - SLO ($0d,x)
            php                ; $f638: 08        
            ora $0c06          ; $f639: 0d 06 0c  
__f63c:     lda #$20           ; $f63c: a9 20     
            sta $07bf          ; $f63e: 8d bf 07  
__f641:     lda $07bf          ; $f641: ad bf 07  
            lsr                ; $f644: 4a        
            bcc __f659         ; $f645: 90 12     
            tay                ; $f647: a8        
            ldx __f62c,y       ; $f648: be 2c f6  
            lda __ffea,y       ; $f64b: b9 ea ff  
__f64e:     sta $400c          ; $f64e: 8d 0c 40  
            stx $400e          ; $f651: 8e 0e 40  
            lda #$18           ; $f654: a9 18     
            sta $400f          ; $f656: 8d 0f 40  
__f659:     dec $07bf          ; $f659: ce bf 07  
            bne __f667         ; $f65c: d0 09     
            lda #$f0           ; $f65e: a9 f0     
            sta $400c          ; $f660: 8d 0c 40  
            lda #$00           ; $f663: a9 00     
            sta $f3            ; $f665: 85 f3     
__f667:     rts                ; $f667: 60        

;-------------------------------------------------------------------------------
__f668:     ldy $fd            ; $f668: a4 fd     
            beq __f676         ; $f66a: f0 0a     
            sty $f3            ; $f66c: 84 f3     
            lsr $fd            ; $f66e: 46 fd     
            bcs __f63c         ; $f670: b0 ca     
            lsr $fd            ; $f672: 46 fd     
            bcs __f681         ; $f674: b0 0b     
__f676:     lda $f3            ; $f676: a5 f3     
            beq __f680         ; $f678: f0 06     
            lsr                ; $f67a: 4a        
            bcs __f641         ; $f67b: b0 c4     
            lsr                ; $f67d: 4a        
            bcs __f686         ; $f67e: b0 06     
__f680:     rts                ; $f680: 60        

;-------------------------------------------------------------------------------
__f681:     lda #$40           ; $f681: a9 40     
__f683:     sta $07bf          ; $f683: 8d bf 07  
__f686:     lda $07bf          ; $f686: ad bf 07  
            lsr                ; $f689: 4a        
            tay                ; $f68a: a8        
            ldx #$0f           ; $f68b: a2 0f     
            lda __ffc9,y       ; $f68d: b9 c9 ff  
            bne __f64e         ; $f690: d0 bc     
__f692:     jmp __f73b         ; $f692: 4c 3b f7  

;-------------------------------------------------------------------------------
__f695:     lda $fc            ; $f695: a5 fc     
            bne __f6a5         ; $f697: d0 0c     
            lda $fb            ; $f699: a5 fb     
            bne __f6c9         ; $f69b: d0 2c     
            lda $07b1          ; $f69d: ad b1 07  
            ora $f4            ; $f6a0: 05 f4     
            bne __f692         ; $f6a2: d0 ee     
            rts                ; $f6a4: 60        

;-------------------------------------------------------------------------------
__f6a5:     sta $07b1          ; $f6a5: 8d b1 07  
            cmp #$01           ; $f6a8: c9 01     
            bne __f6b2         ; $f6aa: d0 06     
            jsr __f4a8         ; $f6ac: 20 a8 f4  
            jsr __f572         ; $f6af: 20 72 f5  
__f6b2:     ldx $f4            ; $f6b2: a6 f4     
            stx $07c5          ; $f6b4: 8e c5 07  
            ldy #$00           ; $f6b7: a0 00     
            sty $07c4          ; $f6b9: 8c c4 07  
            sty $f4            ; $f6bc: 84 f4     
            cmp #$40           ; $f6be: c9 40     
            bne __f6f2         ; $f6c0: d0 30     
            ldx #$08           ; $f6c2: a2 08     
            stx $07c4          ; $f6c4: 8e c4 07  
            bne __f6f2         ; $f6c7: d0 29     
__f6c9:     cmp #$04           ; $f6c9: c9 04     
            bne __f6d0         ; $f6cb: d0 03     
            jsr __f4a8         ; $f6cd: 20 a8 f4  
__f6d0:     ldy #$10           ; $f6d0: a0 10     
__f6d2:     sty $07c7          ; $f6d2: 8c c7 07  
__f6d5:     ldy #$00           ; $f6d5: a0 00     
            sty $07b1          ; $f6d7: 8c b1 07  
            sta $f4            ; $f6da: 85 f4     
            cmp #$01           ; $f6dc: c9 01     
            bne __f6ee         ; $f6de: d0 0e     
            inc $07c7          ; $f6e0: ee c7 07  
            ldy $07c7          ; $f6e3: ac c7 07  
            cpy #$32           ; $f6e6: c0 32     
            bne __f6f6         ; $f6e8: d0 0c     
            ldy #$11           ; $f6ea: a0 11     
            bne __f6d2         ; $f6ec: d0 e4     
__f6ee:     ldy #$08           ; $f6ee: a0 08     
            sty $f7            ; $f6f0: 84 f7     
__f6f2:     iny                ; $f6f2: c8        
            lsr                ; $f6f3: 4a        
            bcc __f6f2         ; $f6f4: 90 fc     
__f6f6:     lda __f90d,y       ; $f6f6: b9 0d f9  
            tay                ; $f6f9: a8        
            lda __f90e,y       ; $f6fa: b9 0e f9  
            sta $f0            ; $f6fd: 85 f0     
            lda __f90f,y       ; $f6ff: b9 0f f9  
            sta $f5            ; $f702: 85 f5     
            lda __f910,y       ; $f704: b9 10 f9  
            sta $f6            ; $f707: 85 f6     
            lda __f911,y       ; $f709: b9 11 f9  
            sta $f9            ; $f70c: 85 f9     
            lda __f912,y       ; $f70e: b9 12 f9  
            sta $f8            ; $f711: 85 f8     
            lda __f913,y       ; $f713: b9 13 f9  
            sta $07b0          ; $f716: 8d b0 07  
            sta $07c1          ; $f719: 8d c1 07  
            lda #$01           ; $f71c: a9 01     
            sta $07b4          ; $f71e: 8d b4 07  
            sta $07b6          ; $f721: 8d b6 07  
            sta $07b9          ; $f724: 8d b9 07  
            sta $07ba          ; $f727: 8d ba 07  
            lda #$00           ; $f72a: a9 00     
            sta $f7            ; $f72c: 85 f7     
            sta $07ca          ; $f72e: 8d ca 07  
            lda #$0b           ; $f731: a9 0b     
            sta $4015          ; $f733: 8d 15 40  
            lda #$0f           ; $f736: a9 0f     
            sta $4015          ; $f738: 8d 15 40  
__f73b:     dec $07b4          ; $f73b: ce b4 07  
            bne __f79f         ; $f73e: d0 5f     
            ldy $f7            ; $f740: a4 f7     
            inc $f7            ; $f742: e6 f7     
            lda ($f5),y        ; $f744: b1 f5     
            beq __f74c         ; $f746: f0 04     
            bpl __f787         ; $f748: 10 3d     
            bne __f77b         ; $f74a: d0 2f     
__f74c:     lda $07b1          ; $f74c: ad b1 07  
            cmp #$40           ; $f74f: c9 40     
            bne __f758         ; $f751: d0 05     
            lda $07c5          ; $f753: ad c5 07  
            bne __f775         ; $f756: d0 1d     
__f758:     and #$04           ; $f758: 29 04     
            bne __f778         ; $f75a: d0 1c     
            lda $f4            ; $f75c: a5 f4     
            and #$5f           ; $f75e: 29 5f     
            bne __f775         ; $f760: d0 13     
            lda #$00           ; $f762: a9 00     
            sta $f4            ; $f764: 85 f4     
            sta $07b1          ; $f766: 8d b1 07  
            sta $4008          ; $f769: 8d 08 40  
            lda #$90           ; $f76c: a9 90     
            sta $4000          ; $f76e: 8d 00 40  
            sta $4004          ; $f771: 8d 04 40  
            rts                ; $f774: 60        

;-------------------------------------------------------------------------------
__f775:     jmp __f6d5         ; $f775: 4c d5 f6  

;-------------------------------------------------------------------------------
__f778:     jmp __f6a5         ; $f778: 4c a5 f6  

;-------------------------------------------------------------------------------
__f77b:     jsr __f8cc         ; $f77b: 20 cc f8  
            sta $07b3          ; $f77e: 8d b3 07  
            ldy $f7            ; $f781: a4 f7     
            inc $f7            ; $f783: e6 f7     
            lda ($f5),y        ; $f785: b1 f5     
__f787:     ldx $f2            ; $f787: a6 f2     
            bne __f799         ; $f789: d0 0e     
            jsr __f3aa         ; $f78b: 20 aa f3  
            beq __f793         ; $f78e: f0 03     
            jsr __f8d9         ; $f790: 20 d9 f8  
__f793:     sta $07b5          ; $f793: 8d b5 07  
            jsr __f3a0         ; $f796: 20 a0 f3  
__f799:     lda $07b3          ; $f799: ad b3 07  
            sta $07b4          ; $f79c: 8d b4 07  
__f79f:     lda $f2            ; $f79f: a5 f2     
            bne __f7bd         ; $f7a1: d0 1a     
            lda $07b1          ; $f7a3: ad b1 07  
            and #$91           ; $f7a6: 29 91     
            bne __f7bd         ; $f7a8: d0 13     
            ldy $07b5          ; $f7aa: ac b5 07  
            beq __f7b2         ; $f7ad: f0 03     
            dec $07b5          ; $f7af: ce b5 07  
__f7b2:     jsr __f8f5         ; $f7b2: 20 f5 f8  
            sta $4004          ; $f7b5: 8d 04 40  
            ldx #$7f           ; $f7b8: a2 7f     
            stx $4005          ; $f7ba: 8e 05 40  
__f7bd:     ldy $f8            ; $f7bd: a4 f8     
            beq __f81b         ; $f7bf: f0 5a     
            .hex ce b6         ; $f7c1: ce b6     Suspected data
__f7c3:     .hex 07 d0         ; $f7c3: 07 d0     Invalid Opcode - SLO $d0
            .hex 32            ; $f7c5: 32        Invalid Opcode - KIL 
__f7c6:     ldy $f8            ; $f7c6: a4 f8     
            inc $f8            ; $f7c8: e6 f8     
            lda ($f5),y        ; $f7ca: b1 f5     
            bne __f7dd         ; $f7cc: d0 0f     
            lda #$83           ; $f7ce: a9 83     
            sta $4000          ; $f7d0: 8d 00 40  
            lda #$94           ; $f7d3: a9 94     
            sta $4001          ; $f7d5: 8d 01 40  
            sta $07ca          ; $f7d8: 8d ca 07  
            bne __f7c6         ; $f7db: d0 e9     
__f7dd:     jsr __f8c6         ; $f7dd: 20 c6 f8  
            sta $07b6          ; $f7e0: 8d b6 07  
            ldy $f1            ; $f7e3: a4 f1     
            bne __f81b         ; $f7e5: d0 34     
            txa                ; $f7e7: 8a        
            and #$3e           ; $f7e8: 29 3e     
            jsr __f38c         ; $f7ea: 20 8c f3  
            beq __f7f2         ; $f7ed: f0 03     
            jsr __f8d9         ; $f7ef: 20 d9 f8  
__f7f2:     sta $07b7          ; $f7f2: 8d b7 07  
            jsr __f382         ; $f7f5: 20 82 f3  
            lda $f1            ; $f7f8: a5 f1     
            bne __f81b         ; $f7fa: d0 1f     
            lda $07b1          ; $f7fc: ad b1 07  
            and #$91           ; $f7ff: 29 91     
            bne __f811         ; $f801: d0 0e     
            ldy $07b7          ; $f803: ac b7 07  
            beq __f80b         ; $f806: f0 03     
            dec $07b7          ; $f808: ce b7 07  
__f80b:     jsr __f8f5         ; $f80b: 20 f5 f8  
            sta $4000          ; $f80e: 8d 00 40  
__f811:     lda $07ca          ; $f811: ad ca 07  
            bne __f818         ; $f814: d0 02     
            lda #$7f           ; $f816: a9 7f     
__f818:     sta $4001          ; $f818: 8d 01 40  
__f81b:     lda $f9            ; $f81b: a5 f9     
            dec $07b9          ; $f81d: ce b9 07  
            bne __f86e         ; $f820: d0 4c     
            ldy $f9            ; $f822: a4 f9     
            inc $f9            ; $f824: e6 f9     
            lda ($f5),y        ; $f826: b1 f5     
            beq __f86b         ; $f828: f0 41     
            bpl __f83f         ; $f82a: 10 13     
            jsr __f8cc         ; $f82c: 20 cc f8  
            sta $07b8          ; $f82f: 8d b8 07  
            lda #$1f           ; $f832: a9 1f     
            sta $4008          ; $f834: 8d 08 40  
            ldy $f9            ; $f837: a4 f9     
            inc $f9            ; $f839: e6 f9     
            lda ($f5),y        ; $f83b: b1 f5     
            beq __f86b         ; $f83d: f0 2c     
__f83f:     .hex 20            ; $f83f: 20        Suspected data
__f840:     ldx __aef3         ; $f840: ae f3 ae  
            clv                ; $f843: b8        
            .hex 07 8e         ; $f844: 07 8e     Invalid Opcode - SLO $8e
            .hex b9 07         ; $f846: b9 07     Suspected data
__f848:     lda $07b1          ; $f848: ad b1 07  
            and #$6e           ; $f84b: 29 6e     
            bne __f855         ; $f84d: d0 06     
            lda $f4            ; $f84f: a5 f4     
            and #$0a           ; $f851: 29 0a     
            beq __f86e         ; $f853: f0 19     
__f855:     txa                ; $f855: 8a        
            cmp #$12           ; $f856: c9 12     
            bcs __f869         ; $f858: b0 0f     
            lda $07b1          ; $f85a: ad b1 07  
            and #$08           ; $f85d: 29 08     
            beq __f865         ; $f85f: f0 04     
            lda #$0f           ; $f861: a9 0f     
            bne __f86b         ; $f863: d0 06     
__f865:     lda #$1f           ; $f865: a9 1f     
            bne __f86b         ; $f867: d0 02     
__f869:     lda #$ff           ; $f869: a9 ff     
__f86b:     sta $4008          ; $f86b: 8d 08 40  
__f86e:     lda $f4            ; $f86e: a5 f4     
            and #$f3           ; $f870: 29 f3     
            beq __f8c5         ; $f872: f0 51     
            dec $07ba          ; $f874: ce ba 07  
            bne __f8c5         ; $f877: d0 4c     
__f879:     ldy $07b0          ; $f879: ac b0 07  
            inc $07b0          ; $f87c: ee b0 07  
            lda ($f5),y        ; $f87f: b1 f5     
            bne __f88b         ; $f881: d0 08     
            lda $07c1          ; $f883: ad c1 07  
            sta $07b0          ; $f886: 8d b0 07  
            bne __f879         ; $f889: d0 ee     
__f88b:     jsr __f8c6         ; $f88b: 20 c6 f8  
            sta $07ba          ; $f88e: 8d ba 07  
            txa                ; $f891: 8a        
            and #$3e           ; $f892: 29 3e     
            beq __f8ba         ; $f894: f0 24     
            cmp #$30           ; $f896: c9 30     
            beq __f8b2         ; $f898: f0 18     
            cmp #$20           ; $f89a: c9 20     
            beq __f8aa         ; $f89c: f0 0c     
            and #$10           ; $f89e: 29 10     
            beq __f8ba         ; $f8a0: f0 18     
            lda #$1c           ; $f8a2: a9 1c     
            ldx #$03           ; $f8a4: a2 03     
            ldy #$18           ; $f8a6: a0 18     
            bne __f8bc         ; $f8a8: d0 12     
__f8aa:     lda #$1c           ; $f8aa: a9 1c     
            ldx #$0c           ; $f8ac: a2 0c     
            ldy #$18           ; $f8ae: a0 18     
            bne __f8bc         ; $f8b0: d0 0a     
__f8b2:     lda #$1c           ; $f8b2: a9 1c     
            ldx #$03           ; $f8b4: a2 03     
            ldy #$58           ; $f8b6: a0 58     
            bne __f8bc         ; $f8b8: d0 02     
__f8ba:     lda #$10           ; $f8ba: a9 10     
__f8bc:     sta $400c          ; $f8bc: 8d 0c 40  
            stx $400e          ; $f8bf: 8e 0e 40  
            sty $400f          ; $f8c2: 8c 0f 40  
__f8c5:     rts                ; $f8c5: 60        

;-------------------------------------------------------------------------------
__f8c6:     tax                ; $f8c6: aa        
            ror                ; $f8c7: 6a        
            txa                ; $f8c8: 8a        
            rol                ; $f8c9: 2a        
            rol                ; $f8ca: 2a        
            rol                ; $f8cb: 2a        
__f8cc:     and #$07           ; $f8cc: 29 07     
            clc                ; $f8ce: 18        
            adc $f0            ; $f8cf: 65 f0     
            adc $07c4          ; $f8d1: 6d c4 07  
            tay                ; $f8d4: a8        
            lda __ff66,y       ; $f8d5: b9 66 ff  
            rts                ; $f8d8: 60        

;-------------------------------------------------------------------------------
__f8d9:     lda $07b1          ; $f8d9: ad b1 07  
            and #$08           ; $f8dc: 29 08     
            beq __f8e4         ; $f8de: f0 04     
            lda #$04           ; $f8e0: a9 04     
            bne __f8f0         ; $f8e2: d0 0c     
__f8e4:     lda $f4            ; $f8e4: a5 f4     
            and #$7d           ; $f8e6: 29 7d     
            beq __f8ee         ; $f8e8: f0 04     
            lda #$08           ; $f8ea: a9 08     
            bne __f8f0         ; $f8ec: d0 02     
__f8ee:     lda #$28           ; $f8ee: a9 28     
__f8f0:     ldx #$82           ; $f8f0: a2 82     
            ldy #$7f           ; $f8f2: a0 7f     
            rts                ; $f8f4: 60        

;-------------------------------------------------------------------------------
__f8f5:     lda $07b1          ; $f8f5: ad b1 07  
            and #$08           ; $f8f8: 29 08     
            beq __f900         ; $f8fa: f0 04     
            lda __ff96,y       ; $f8fc: b9 96 ff  
            rts                ; $f8ff: 60        

;-------------------------------------------------------------------------------
__f900:     lda $f4            ; $f900: a5 f4     
            .hex 29            ; $f902: 29        Suspected data
__f903:     adc $04f0,x        ; $f903: 7d f0 04  
            lda __ff9a,y       ; $f906: b9 9a ff  
            rts                ; $f909: 60        

;-------------------------------------------------------------------------------
            lda __ffa2,y       ; $f90a: b9 a2 ff  
__f90d:     rts                ; $f90d: 60        

;-------------------------------------------------------------------------------
__f90e:     .hex a5            ; $f90e: a5        Suspected data
__f90f:     .hex 59            ; $f90f: 59        Suspected data
__f910:     .hex 54            ; $f910: 54        Suspected data
__f911:     .hex 64            ; $f911: 64        Suspected data
__f912:     .hex 59            ; $f912: 59        Suspected data
__f913:     .hex 3c 31 4b      ; $f913: 3c 31 4b  Invalid Opcode - NOP $4b31,x
            adc #$5e           ; $f916: 69 5e     
            lsr $4f            ; $f918: 46 4f     
            rol $8d,x          ; $f91a: 36 8d     
            rol $4b,x          ; $f91c: 36 4b     
            sta $6969          ; $f91e: 8d 69 69  
            .hex 6f 75 6f      ; $f921: 6f 75 6f  Invalid Opcode - RRA $6f75
            .hex 7b 6f 75      ; $f924: 7b 6f 75  Invalid Opcode - RRA $756f,y
            .hex 6f 7b 81      ; $f927: 6f 7b 81  Invalid Opcode - RRA __817b
            .hex 87 81         ; $f92a: 87 81     Invalid Opcode - SAX $81
            .hex 8d            ; $f92c: 8d        Suspected data
__f92d:     adc #$69           ; $f92d: 69 69     
            .hex 93 99         ; $f92f: 93 99     Invalid Opcode - AHX ($99),y
            .hex 93 9f         ; $f931: 93 9f     Invalid Opcode - AHX ($9f),y
            .hex 93 99         ; $f933: 93 99     Invalid Opcode - AHX ($99),y
            .hex 93 9f         ; $f935: 93 9f     Invalid Opcode - AHX ($9f),y
            sta ($87,x)        ; $f937: 81 87     
            sta ($8d,x)        ; $f939: 81 8d     
            .hex 93 99         ; $f93b: 93 99     Invalid Opcode - AHX ($99),y
            .hex 93 9f         ; $f93d: 93 9f     Invalid Opcode - AHX ($9f),y
            php                ; $f93f: 08        
            .hex 73 fc         ; $f940: 73 fc     Invalid Opcode - RRA ($fc),y
            .hex 27 18         ; $f942: 27 18     Invalid Opcode - RLA $18
            jsr __f9b9         ; $f944: 20 b9 f9  
            rol $401a          ; $f947: 2e 1a 40  
            jsr __fcb1         ; $f94a: 20 b1 fc  
            and $2021,x        ; $f94d: 3d 21 20  
            cmp $fc            ; $f950: c5 fc     
            .hex 3f 1d 18      ; $f952: 3f 1d 18  Invalid Opcode - RLA $181d,x
            .hex 12            ; $f955: 12        Invalid Opcode - KIL 
            .hex fd 00 00      ; $f956: fd 00 00  Bad Addr Mode - SBC $0000,x
            php                ; $f959: 08        
            .hex 1d fa 00      ; $f95a: 1d fa 00  Bad Addr Mode - ORA $00fa,x
            brk                ; $f95d: 00        
            lda $fb            ; $f95e: a5 fb     
            .hex 93 62         ; $f960: 93 62     Invalid Opcode - AHX ($62),y
            bpl __f92d         ; $f962: 10 c9     
            inc $1424,x        ; $f964: fe 24 14  
            clc                ; $f967: 18        
            lsr $fc            ; $f968: 46 fc     
            asl $0814,x        ; $f96a: 1e 14 08  
            .hex 53 fd         ; $f96d: 53 fd     Invalid Opcode - SRE ($fd),y
            ldy #$70           ; $f96f: a0 70     
__f971:     pla                ; $f971: 68        
            php                ; $f972: 08        
            .hex 52            ; $f973: 52        Invalid Opcode - KIL 
            inc $244c,x        ; $f974: fe 4c 24  
__f977:     clc                ; $f977: 18        
            .hex 02            ; $f978: 02        Invalid Opcode - KIL 
            .hex fa            ; $f979: fa        Invalid Opcode - NOP 
            and __b81c         ; $f97a: 2d 1c b8  
            clc                ; $f97d: 18        
            lsr                ; $f97e: 4a        
            .hex fa            ; $f97f: fa        Invalid Opcode - NOP 
            jsr $7012          ; $f980: 20 12 70  
            clc                ; $f983: 18        
            ror $fa,x          ; $f984: 76 fa     
            .hex 1b 10 44      ; $f986: 1b 10 44  Invalid Opcode - SLO $4410,y
            clc                ; $f989: 18        
            .hex 9e fa 11      ; $f98a: 9e fa 11  Invalid Opcode - SHX $11fa,y
            asl                ; $f98d: 0a        
            .hex 1c 18 c3      ; $f98e: 1c 18 c3  Invalid Opcode - NOP __c318,x
            .hex fa            ; $f991: fa        Invalid Opcode - NOP 
            and $5810          ; $f992: 2d 10 58  
            clc                ; $f995: 18        
            .hex dc fa 14      ; $f996: dc fa 14  Invalid Opcode - NOP $14fa,x
            ora $183f          ; $f999: 0d 3f 18  
            .hex fa            ; $f99c: fa        Invalid Opcode - NOP 
            .hex fa            ; $f99d: fa        Invalid Opcode - NOP 
            ora $0d,x          ; $f99e: 15 0d     
            and ($18,x)        ; $f9a0: 21 18     
            rol $fb            ; $f9a2: 26 fb     
            clc                ; $f9a4: 18        
            bpl __fa21         ; $f9a5: 10 7a     
            clc                ; $f9a7: 18        
            jmp $19fb          ; $f9a8: 4c fb 19  

;-------------------------------------------------------------------------------
            .hex 0f 54 18      ; $f9ab: 0f 54 18  Invalid Opcode - SLO $1854
            adc $fb,x          ; $f9ae: 75 fb     
            asl $2b12,x        ; $f9b0: 1e 12 2b  
            clc                ; $f9b3: 18        
            .hex 73 fb         ; $f9b4: 73 fb     Invalid Opcode - RRA ($fb),y
            asl $2d0f,x        ; $f9b6: 1e 0f 2d  
__f9b9:     sty $2c            ; $f9b9: 84 2c     
            bit $822c          ; $f9bb: 2c 2c 82  
            .hex 04 2c         ; $f9be: 04 2c     Invalid Opcode - NOP $2c
            .hex 04 85         ; $f9c0: 04 85     Invalid Opcode - NOP $85
            bit $2c84          ; $f9c2: 2c 84 2c  
            bit $2a2a          ; $f9c5: 2c 2a 2a  
            rol                ; $f9c8: 2a        
            .hex 82 04         ; $f9c9: 82 04     Invalid Opcode - NOP #$04
            rol                ; $f9cb: 2a        
            .hex 04 85         ; $f9cc: 04 85     Invalid Opcode - NOP $85
            rol                ; $f9ce: 2a        
            sty $2a            ; $f9cf: 84 2a     
            rol                ; $f9d1: 2a        
            brk                ; $f9d2: 00        
            .hex 1f 1f 1f      ; $f9d3: 1f 1f 1f  Invalid Opcode - SLO $1f1f,x
            tya                ; $f9d6: 98        
            .hex 1f 1f 98      ; $f9d7: 1f 1f 98  Invalid Opcode - SLO __981f,x
            .hex 9e 98 1f      ; $f9da: 9e 98 1f  Invalid Opcode - SHX $1f98,y
            ora $1d1d,x        ; $f9dd: 1d 1d 1d  
            sty $1d,x          ; $f9e0: 94 1d     
            ora __9c94,x       ; $f9e2: 1d 94 9c  
            sty $1d,x          ; $f9e5: 94 1d     
            stx $18            ; $f9e7: 86 18     
            sta $26            ; $f9e9: 85 26     
            bmi __f971         ; $f9eb: 30 84     
            .hex 04 26         ; $f9ed: 04 26     Invalid Opcode - NOP $26
            bmi __f977         ; $f9ef: 30 86     
            .hex 14 85         ; $f9f1: 14 85     Invalid Opcode - NOP $85,x
            .hex 22            ; $f9f3: 22        Invalid Opcode - KIL 
            bit $0484          ; $f9f4: 2c 84 04  
            .hex 22            ; $f9f7: 22        Invalid Opcode - KIL 
            bit __d021         ; $f9f8: 2c 21 d0  
            cpy $d0            ; $f9fb: c4 d0     
            and ($d0),y        ; $f9fd: 31 d0     
            cpy $d0            ; $f9ff: c4 d0     
            brk                ; $fa01: 00        
            sta $2c            ; $fa02: 85 2c     
            .hex 22            ; $fa04: 22        Invalid Opcode - KIL 
            .hex 1c 84 26      ; $fa05: 1c 84 26  Invalid Opcode - NOP $2684,x
            rol                ; $fa08: 2a        
            .hex 82 28         ; $fa09: 82 28     Invalid Opcode - NOP #$28
            rol $04            ; $fa0b: 26 04     
            .hex 87 22         ; $fa0d: 87 22     Invalid Opcode - SAX $22
            .hex 34 3a         ; $fa0f: 34 3a     Invalid Opcode - NOP $3a,x
            .hex 82 40         ; $fa11: 82 40     Invalid Opcode - NOP #$40
            .hex 04 36         ; $fa13: 04 36     Invalid Opcode - NOP $36
            sty $3a            ; $fa15: 84 3a     
            .hex 34 82         ; $fa17: 34 82     Invalid Opcode - NOP $82,x
            bit __8530         ; $fa19: 2c 30 85  
            rol                ; $fa1c: 2a        
            brk                ; $fa1d: 00        
            eor $4d55,x        ; $fa1e: 5d 55 4d  
__fa21:     ora $19,x          ; $fa21: 15 19     
            stx $15,y          ; $fa23: 96 15     
            cmp $e3,x          ; $fa25: d5 e3     
            .hex eb 2d         ; $fa27: eb 2d     Invalid Opcode - SBC #$2d
            ldx $2b            ; $fa29: a6 2b     
            .hex 27 9c         ; $fa2b: 27 9c     Invalid Opcode - RLA $9c
            .hex 9e 59 85      ; $fa2d: 9e 59 85  Invalid Opcode - SHX __8559,y
            .hex 22            ; $fa30: 22        Invalid Opcode - KIL 
            .hex 1c 14 84      ; $fa31: 1c 14 84  Invalid Opcode - NOP __8414,x
            asl __8222,x       ; $fa34: 1e 22 82  
            jsr $041e          ; $fa37: 20 1e 04  
            .hex 87 1c         ; $fa3a: 87 1c     Invalid Opcode - SAX $1c
            bit __8234         ; $fa3c: 2c 34 82  
            rol $04,x          ; $fa3f: 36 04     
            bmi __fa77         ; $fa41: 30 34     
            .hex 04 2c         ; $fa43: 04 2c     Invalid Opcode - NOP $2c
            .hex 04 26         ; $fa45: 04 26     Invalid Opcode - NOP $26
            rol                ; $fa47: 2a        
            sta $22            ; $fa48: 85 22     
            sty $04            ; $fa4a: 84 04     
            .hex 82 3a         ; $fa4c: 82 3a     Invalid Opcode - NOP #$3a
            sec                ; $fa4e: 38        
            rol $32,x          ; $fa4f: 36 32     
            .hex 04 34         ; $fa51: 04 34     Invalid Opcode - NOP $34
            .hex 04 24         ; $fa53: 04 24     Invalid Opcode - NOP $24
            rol $2c            ; $fa55: 26 2c     
            .hex 04 26         ; $fa57: 04 26     Invalid Opcode - NOP $26
            .hex 2c 30 00      ; $fa59: 2c 30 00  Bad Addr Mode - BIT $0030
            ora $b4            ; $fa5c: 05 b4     
            .hex b2            ; $fa5e: b2        Invalid Opcode - KIL 
            bcs __fa8c         ; $fa5f: b0 2b     
            ldy __9c84         ; $fa61: ac 84 9c  
            .hex 9e a2 84      ; $fa64: 9e a2 84  Invalid Opcode - SHX __84a2,y
            sty $9c,x          ; $fa67: 94 9c     
            .hex 9e            ; $fa69: 9e        Suspected data
__fa6a:     sta $14            ; $fa6a: 85 14     
            .hex 22            ; $fa6c: 22        Invalid Opcode - KIL 
            sty $2c            ; $fa6d: 84 2c     
            sta $1e            ; $fa6f: 85 1e     
            .hex 82 2c         ; $fa71: 82 2c     Invalid Opcode - NOP #$2c
            sty $2c            ; $fa73: 84 2c     
            .hex 1e 84         ; $fa75: 1e 84     Suspected data
__fa77:     .hex 04 82         ; $fa77: 04 82     Invalid Opcode - NOP $82
            .hex 3a            ; $fa79: 3a        Invalid Opcode - NOP 
            sec                ; $fa7a: 38        
            rol $32,x          ; $fa7b: 36 32     
            .hex 04 34         ; $fa7d: 04 34     Invalid Opcode - NOP $34
            .hex 04 64         ; $fa7f: 04 64     Invalid Opcode - NOP $64
__fa81:     .hex 04 64         ; $fa81: 04 64     Invalid Opcode - NOP $64
            stx $64            ; $fa83: 86 64     
__fa85:     brk                ; $fa85: 00        
            ora $b4            ; $fa86: 05 b4     
            .hex b2            ; $fa88: b2        Invalid Opcode - KIL 
            bcs __fab6         ; $fa89: b0 2b     
            .hex ac            ; $fa8b: ac        Suspected data
__fa8c:     sty $37            ; $fa8c: 84 37     
            ldx $b6,y          ; $fa8e: b6 b6     
            eor $85            ; $fa90: 45 85     
            .hex 14 1c         ; $fa92: 14 1c     Invalid Opcode - NOP $1c,x
            .hex 82 22         ; $fa94: 82 22     Invalid Opcode - NOP #$22
            sty $2c            ; $fa96: 84 2c     
            lsr $4e82          ; $fa98: 4e 82 4e  
            sty $4e            ; $fa9b: 84 4e     
            .hex 22            ; $fa9d: 22        Invalid Opcode - KIL 
            sty $04            ; $fa9e: 84 04     
            sta $32            ; $faa0: 85 32     
            sta $30            ; $faa2: 85 30     
            stx $2c            ; $faa4: 86 2c     
            .hex 04 00         ; $faa6: 04 00     Invalid Opcode - NOP $00
            ora $a4            ; $faa8: 05 a4     
            ora $9e            ; $faaa: 05 9e     
            ora $9d            ; $faac: 05 9d     
            sta $84            ; $faae: 85 84     
            .hex 14 85         ; $fab0: 14 85     Invalid Opcode - NOP $85,x
            bit $28            ; $fab2: 24 28     
            .hex 2c            ; $fab4: 2c        Suspected data
__fab5:     .hex 82            ; $fab5: 82        Suspected data
__fab6:     .hex 22            ; $fab6: 22        Invalid Opcode - KIL 
            sty $22            ; $fab7: 84 22     
            .hex 14 21         ; $fab9: 14 21     Invalid Opcode - NOP $21,x
            bne __fa81         ; $fabb: d0 c4     
            bne __faf0         ; $fabd: d0 31     
            bne __fa85         ; $fabf: d0 c4     
            bne __fac3         ; $fac1: d0 00     
__fac3:     .hex 82 2c         ; $fac3: 82 2c     Invalid Opcode - NOP #$2c
            sty $2c            ; $fac5: 84 2c     
            bit $2c82          ; $fac7: 2c 82 2c  
            bmi __fad0         ; $faca: 30 04     
            .hex 34 2c         ; $facc: 34 2c     Invalid Opcode - NOP $2c,x
            .hex 04 26         ; $face: 04 26     Invalid Opcode - NOP $26
__fad0:     stx $22            ; $fad0: 86 22     
            brk                ; $fad2: 00        
            ldy $25            ; $fad3: a4 25     
            and $a4            ; $fad5: 25 a4     
            and #$a2           ; $fad7: 29 a2     
            ora __959c,x       ; $fad9: 1d 9c 95  
            .hex 82 2c         ; $fadc: 82 2c     Invalid Opcode - NOP #$2c
            bit $2c04          ; $fade: 2c 04 2c  
            .hex 04 2c         ; $fae1: 04 2c     Invalid Opcode - NOP $2c
            bmi __fa6a         ; $fae3: 30 85     
            .hex 34 04         ; $fae5: 34 04     Invalid Opcode - NOP $04,x
            .hex 04 00         ; $fae7: 04 00     Invalid Opcode - NOP $00
            ldy $25            ; $fae9: a4 25     
            and $a4            ; $faeb: 25 a4     
            tay                ; $faed: a8        
            .hex 63 04         ; $faee: 63 04     Invalid Opcode - RRA ($04,x)
__faf0:     .hex 85            ; $faf0: 85        Suspected data
__faf1:     asl __841a         ; $faf1: 0e 1a 84  
            bit $85            ; $faf4: 24 85     
            .hex 22            ; $faf6: 22        Invalid Opcode - KIL 
            .hex 14 84         ; $faf7: 14 84     Invalid Opcode - NOP $84,x
            .hex 0c 82 34      ; $faf9: 0c 82 34  Invalid Opcode - NOP $3482
            sty $34            ; $fafc: 84 34     
            .hex 34 82         ; $fafe: 34 82     Invalid Opcode - NOP $82,x
            bit $3484          ; $fb00: 2c 84 34  
            stx $3a            ; $fb03: 86 3a     
__fb05:     .hex 04 00         ; $fb05: 04 00     Invalid Opcode - NOP $00
            ldy #$21           ; $fb07: a0 21     
            and ($a0,x)        ; $fb09: 21 a0     
            and ($2b,x)        ; $fb0b: 21 2b     
            ora $a3            ; $fb0d: 05 a3     
            .hex 82 18         ; $fb0f: 82 18     Invalid Opcode - NOP #$18
            sty $18            ; $fb11: 84 18     
            clc                ; $fb13: 18        
            .hex 82 18         ; $fb14: 82 18     Invalid Opcode - NOP #$18
            clc                ; $fb16: 18        
            .hex 04 86         ; $fb17: 04 86     Invalid Opcode - NOP $86
            .hex 3a            ; $fb19: 3a        Invalid Opcode - NOP 
            .hex 22            ; $fb1a: 22        Invalid Opcode - KIL 
            and ($90),y        ; $fb1b: 31 90     
            and ($90),y        ; $fb1d: 31 90     
            and ($71),y        ; $fb1f: 31 71     
            and ($90),y        ; $fb21: 31 90     
            bcc __fab5         ; $fb23: 90 90     
            brk                ; $fb25: 00        
            .hex 82 34         ; $fb26: 82 34     Invalid Opcode - NOP #$34
            sty $2c            ; $fb28: 84 2c     
            sta $22            ; $fb2a: 85 22     
            sty $24            ; $fb2c: 84 24     
            .hex 82 26         ; $fb2e: 82 26     Invalid Opcode - NOP #$26
            rol $04,x          ; $fb30: 36 04     
            rol $86,x          ; $fb32: 36 86     
            rol $00            ; $fb34: 26 00     
            ldy $5d27          ; $fb36: ac 27 5d  
            ora $2d9e,x        ; $fb39: 1d 9e 2d  
            ldy __859f         ; $fb3c: ac 9f 85  
            .hex 14 82         ; $fb3f: 14 82     Invalid Opcode - NOP $82,x
            jsr $2284          ; $fb41: 20 84 22  
            bit $1e1e          ; $fb44: 2c 1e 1e  
            .hex 82 2c         ; $fb47: 82 2c     Invalid Opcode - NOP #$2c
            bit $041e          ; $fb49: 2c 1e 04  
            .hex 87 2a         ; $fb4c: 87 2a     Invalid Opcode - SAX $2a
            rti                ; $fb4e: 40        

;-------------------------------------------------------------------------------
            rti                ; $fb4f: 40        

;-------------------------------------------------------------------------------
            rti                ; $fb50: 40        

;-------------------------------------------------------------------------------
            .hex 3a            ; $fb51: 3a        Invalid Opcode - NOP 
            rol $82,x          ; $fb52: 36 82     
            .hex 34 2c         ; $fb54: 34 2c     Invalid Opcode - NOP $2c,x
            .hex 04 26         ; $fb56: 04 26     Invalid Opcode - NOP $26
            stx $22            ; $fb58: 86 22     
            brk                ; $fb5a: 00        
            .hex e3 f7         ; $fb5b: e3 f7     Invalid Opcode - ISC ($f7,x)
            .hex f7 f7         ; $fb5d: f7 f7     Invalid Opcode - ISC $f7,x
            sbc $f1,x          ; $fb5f: f5 f1     
            ldy __9e27         ; $fb61: ac 27 9e  
            sta $1885,x        ; $fb64: 9d 85 18  
            .hex 82 1e         ; $fb67: 82 1e     Invalid Opcode - NOP #$1e
            sty $22            ; $fb69: 84 22     
            rol                ; $fb6b: 2a        
            .hex 22            ; $fb6c: 22        Invalid Opcode - KIL 
            .hex 22            ; $fb6d: 22        Invalid Opcode - KIL 
            .hex 82 2c         ; $fb6e: 82 2c     Invalid Opcode - NOP #$2c
            bit $0422          ; $fb70: 2c 22 04  
            stx $04            ; $fb73: 86 04     
            .hex 82 2a         ; $fb75: 82 2a     Invalid Opcode - NOP #$2a
            rol $04,x          ; $fb77: 36 04     
            rol $87,x          ; $fb79: 36 87     
            rol $34,x          ; $fb7b: 36 34     
            bmi __fb05         ; $fb7d: 30 86     
            .hex 2c 04 00      ; $fb7f: 2c 04 00  Bad Addr Mode - BIT $0004
            brk                ; $fb82: 00        
            pla                ; $fb83: 68        
            ror                ; $fb84: 6a        
            jmp (__a245)       ; $fb85: 6c 45 a2  

;-------------------------------------------------------------------------------
            and ($b0),y        ; $fb88: 31 b0     
            sbc ($ed),y        ; $fb8a: f1 ed     
            .hex eb a2         ; $fb8c: eb a2     Invalid Opcode - SBC #$a2
            ora __959c,x       ; $fb8e: 1d 9c 95  
            stx $04            ; $fb91: 86 04     
            sta $22            ; $fb93: 85 22     
            .hex 82 22         ; $fb95: 82 22     Invalid Opcode - NOP #$22
            .hex 87 22         ; $fb97: 87 22     Invalid Opcode - SAX $22
            rol $2a            ; $fb99: 26 2a     
            sty $2c            ; $fb9b: 84 2c     
            .hex 22            ; $fb9d: 22        Invalid Opcode - KIL 
            stx $14            ; $fb9e: 86 14     
            eor ($90),y        ; $fba0: 51 90     
            and ($11),y        ; $fba2: 31 11     
            brk                ; $fba4: 00        
            .hex 80 22         ; $fba5: 80 22     Invalid Opcode - NOP #$22
            plp                ; $fba7: 28        
            .hex 22            ; $fba8: 22        Invalid Opcode - KIL 
            rol $22            ; $fba9: 26 22     
            bit $22            ; $fbab: 24 22     
            rol $22            ; $fbad: 26 22     
            plp                ; $fbaf: 28        
            .hex 22            ; $fbb0: 22        Invalid Opcode - KIL 
            rol                ; $fbb1: 2a        
            .hex 22            ; $fbb2: 22        Invalid Opcode - KIL 
            plp                ; $fbb3: 28        
            .hex 22            ; $fbb4: 22        Invalid Opcode - KIL 
            rol $22            ; $fbb5: 26 22     
            plp                ; $fbb7: 28        
            .hex 22            ; $fbb8: 22        Invalid Opcode - KIL 
            rol $22            ; $fbb9: 26 22     
            bit $22            ; $fbbb: 24 22     
            rol $22            ; $fbbd: 26 22     
            plp                ; $fbbf: 28        
            .hex 22            ; $fbc0: 22        Invalid Opcode - KIL 
            rol                ; $fbc1: 2a        
            .hex 22            ; $fbc2: 22        Invalid Opcode - KIL 
            plp                ; $fbc3: 28        
            .hex 22            ; $fbc4: 22        Invalid Opcode - KIL 
            rol $20            ; $fbc5: 26 20     
            rol $20            ; $fbc7: 26 20     
            bit $20            ; $fbc9: 24 20     
            rol $20            ; $fbcb: 26 20     
            plp                ; $fbcd: 28        
            jsr $2026          ; $fbce: 20 26 20  
            plp                ; $fbd1: 28        
            jsr $2026          ; $fbd2: 20 26 20  
            bit $20            ; $fbd5: 24 20     
            rol $20            ; $fbd7: 26 20     
            bit $20            ; $fbd9: 24 20     
            rol $20            ; $fbdb: 26 20     
            plp                ; $fbdd: 28        
            jsr $2026          ; $fbde: 20 26 20  
            plp                ; $fbe1: 28        
            jsr $2026          ; $fbe2: 20 26 20  
            bit $28            ; $fbe5: 24 28     
            bmi __fc11         ; $fbe7: 30 28     
            .hex 32            ; $fbe9: 32        Invalid Opcode - KIL 
            plp                ; $fbea: 28        
            bmi __fc15         ; $fbeb: 30 28     
            rol $3028          ; $fbed: 2e 28 30  
            plp                ; $fbf0: 28        
            rol $2c28          ; $fbf1: 2e 28 2c  
            plp                ; $fbf4: 28        
            rol $3028          ; $fbf5: 2e 28 30  
            plp                ; $fbf8: 28        
            .hex 32            ; $fbf9: 32        Invalid Opcode - KIL 
            plp                ; $fbfa: 28        
            bmi __fc25         ; $fbfb: 30 28     
            rol $3028          ; $fbfd: 2e 28 30  
            plp                ; $fc00: 28        
__fc01:     rol $2c28          ; $fc01: 2e 28 2c  
__fc04:     plp                ; $fc04: 28        
            rol $0400          ; $fc05: 2e 00 04  
            bvs __fc78         ; $fc08: 70 6e     
            jmp ($706e)        ; $fc0a: 6c 6e 70  

;-------------------------------------------------------------------------------
            .hex 72            ; $fc0d: 72        Invalid Opcode - KIL 
            bvs __fc7e         ; $fc0e: 70 6e     
            .hex 70            ; $fc10: 70        Suspected data
__fc11:     ror $6e6c          ; $fc11: 6e 6c 6e  
            .hex 70            ; $fc14: 70        Suspected data
__fc15:     .hex 72            ; $fc15: 72        Invalid Opcode - KIL 
            bvs __fc86         ; $fc16: 70 6e     
            ror $6e6c          ; $fc18: 6e 6c 6e  
            bvs __fc8b         ; $fc1b: 70 6e     
            bvs __fc8d         ; $fc1d: 70 6e     
            jmp ($6c6e)        ; $fc1f: 6c 6e 6c  

;-------------------------------------------------------------------------------
            ror $6e70          ; $fc22: 6e 70 6e  
__fc25:     bvs __fc95         ; $fc25: 70 6e     
            jmp ($7876)        ; $fc27: 6c 76 78  

;-------------------------------------------------------------------------------
            ror $74,x          ; $fc2a: 76 74     
            ror $74,x          ; $fc2c: 76 74     
            .hex 72            ; $fc2e: 72        Invalid Opcode - KIL 
            .hex 74 76         ; $fc2f: 74 76     Invalid Opcode - NOP $76,x
            sei                ; $fc31: 78        
            ror $74,x          ; $fc32: 76 74     
            ror $74,x          ; $fc34: 76 74     
            .hex 72            ; $fc36: 72        Invalid Opcode - KIL 
            .hex 74 84         ; $fc37: 74 84     Invalid Opcode - NOP $84,x
            .hex 1a            ; $fc39: 1a        Invalid Opcode - NOP 
            .hex 83 18         ; $fc3a: 83 18     Invalid Opcode - SAX ($18,x)
            jsr $1e84          ; $fc3c: 20 84 1e  
            .hex 83 1c         ; $fc3f: 83 1c     Invalid Opcode - SAX ($1c,x)
            plp                ; $fc41: 28        
            rol $1c            ; $fc42: 26 1c     
            .hex 1a            ; $fc44: 1a        Invalid Opcode - NOP 
            .hex 1c 82 2c      ; $fc45: 1c 82 2c  Invalid Opcode - NOP $2c82,x
            .hex 04 04         ; $fc48: 04 04     Invalid Opcode - NOP $04
            .hex 22            ; $fc4a: 22        Invalid Opcode - KIL 
            .hex 04 04         ; $fc4b: 04 04     Invalid Opcode - NOP $04
            sty $1c            ; $fc4d: 84 1c     
            .hex 87            ; $fc4f: 87        Suspected data
__fc50:     rol $2a            ; $fc50: 26 2a     
            rol $84            ; $fc52: 26 84     
            bit $28            ; $fc54: 24 28     
            bit $80            ; $fc56: 24 80     
            .hex 22            ; $fc58: 22        Invalid Opcode - KIL 
            brk                ; $fc59: 00        
            .hex 9c 05 94      ; $fc5a: 9c 05 94  Invalid Opcode - SHY __9405,x
            ora $0d            ; $fc5d: 05 0d     
            .hex 9f 1e 9c      ; $fc5f: 9f 1e 9c  Invalid Opcode - AHX __9c1e,y
            tya                ; $fc62: 98        
            sta $2282,x        ; $fc63: 9d 82 22  
            .hex 04 04         ; $fc66: 04 04     Invalid Opcode - NOP $04
            .hex 1c 04 04      ; $fc68: 1c 04 04  Invalid Opcode - NOP $0404,x
            sty $14            ; $fc6b: 84 14     
__fc6d:     .hex 86            ; $fc6d: 86        Suspected data
__fc6e:     asl $1680,x        ; $fc6e: 1e 80 16  
            .hex 80 14         ; $fc71: 80 14     Invalid Opcode - NOP #$14
            sta ($1c,x)        ; $fc73: 81 1c     
            bmi __fc7b         ; $fc75: 30 04     
            .hex 30            ; $fc77: 30        Suspected data
__fc78:     bmi __fc7e         ; $fc78: 30 04     
            .hex 1e            ; $fc7a: 1e        Suspected data
__fc7b:     .hex 32            ; $fc7b: 32        Invalid Opcode - KIL 
            .hex 04 32         ; $fc7c: 04 32     Invalid Opcode - NOP $32
__fc7e:     .hex 32            ; $fc7e: 32        Invalid Opcode - KIL 
            .hex 04 20         ; $fc7f: 04 20     Invalid Opcode - NOP $20
            .hex 34 04         ; $fc81: 34 04     Invalid Opcode - NOP $04,x
            .hex 34 34         ; $fc83: 34 34     Invalid Opcode - NOP $34,x
            .hex 04            ; $fc85: 04        Suspected data
__fc86:     rol $04,x          ; $fc86: 36 04     
__fc88:     sty $36            ; $fc88: 84 36     
            brk                ; $fc8a: 00        
__fc8b:     lsr $a4            ; $fc8b: 46 a4     
__fc8d:     .hex 64 a4         ; $fc8d: 64 a4     Invalid Opcode - NOP $a4
__fc8f:     pha                ; $fc8f: 48        
            .hex a6            ; $fc90: a6        Suspected data
__fc91:     ror $a6            ; $fc91: 66 a6     
            lsr                ; $fc93: 4a        
            tay                ; $fc94: a8        
__fc95:     pla                ; $fc95: 68        
            tay                ; $fc96: a8        
            ror                ; $fc97: 6a        
            .hex 44 2b         ; $fc98: 44 2b     Invalid Opcode - NOP $2b
            sta ($2a,x)        ; $fc9a: 81 2a     
            .hex 42            ; $fc9c: 42        Invalid Opcode - KIL 
            .hex 04 42         ; $fc9d: 04 42     Invalid Opcode - NOP $42
            .hex 42            ; $fc9f: 42        Invalid Opcode - KIL 
            .hex 04 2c         ; $fca0: 04 2c     Invalid Opcode - NOP $2c
            .hex 64 04         ; $fca2: 64 04     Invalid Opcode - NOP $04
            .hex 64 64         ; $fca4: 64 64     Invalid Opcode - NOP $64
            .hex 04 2e         ; $fca6: 04 2e     Invalid Opcode - NOP $2e
            lsr $04            ; $fca8: 46 04     
            lsr $46            ; $fcaa: 46 46     
            .hex 04            ; $fcac: 04        Suspected data
__fcad:     .hex 22            ; $fcad: 22        Invalid Opcode - KIL 
            .hex 04 84         ; $fcae: 04 84     Invalid Opcode - NOP $84
            .hex 22            ; $fcb0: 22        Invalid Opcode - KIL 
__fcb1:     .hex 87 04         ; $fcb1: 87 04     Invalid Opcode - SAX $04
            asl $0c            ; $fcb3: 06 0c     
            .hex 14 1c         ; $fcb5: 14 1c     Invalid Opcode - NOP $1c,x
            .hex 22            ; $fcb7: 22        Invalid Opcode - KIL 
            stx $2c            ; $fcb8: 86 2c     
            .hex 22            ; $fcba: 22        Invalid Opcode - KIL 
            .hex 87 04         ; $fcbb: 87 04     Invalid Opcode - SAX $04
            rts                ; $fcbd: 60        

;-------------------------------------------------------------------------------
            asl $1a14          ; $fcbe: 0e 14 1a  
            bit $86            ; $fcc1: 24 86     
            bit __8724         ; $fcc3: 2c 24 87  
            .hex 04 08         ; $fcc6: 04 08     Invalid Opcode - NOP $08
            bpl __fce2         ; $fcc8: 10 18     
            .hex 1e            ; $fcca: 1e        Suspected data
__fccb:     plp                ; $fccb: 28        
            stx $30            ; $fccc: 86 30     
            bmi __fc50         ; $fcce: 30 80     
            .hex 64 00         ; $fcd0: 64 00     Invalid Opcode - NOP $00
            cmp __ddd5         ; $fcd2: cd d5 dd  
            .hex e3 ed         ; $fcd5: e3 ed     Invalid Opcode - ISC ($ed,x)
            sbc $bb,x          ; $fcd7: f5 bb     
            lda $cf,x          ; $fcd9: b5 cf     
            cmp $db,x          ; $fcdb: d5 db     
            sbc $ed            ; $fcdd: e5 ed     
            .hex f3 bd         ; $fcdf: f3 bd     Invalid Opcode - ISC ($bd),y
            .hex b3            ; $fce1: b3        Suspected data
__fce2:     cmp ($d9),y        ; $fce2: d1 d9     
            .hex df e9 f1      ; $fce4: df e9 f1  Invalid Opcode - DCP __f1e9,x
            .hex f7 bf         ; $fce7: f7 bf     Invalid Opcode - ISC $bf,x
            .hex ff ff ff      ; $fce9: ff ff ff  Invalid Opcode - ISC $ffff,x
            .hex 34 00         ; $fcec: 34 00     Invalid Opcode - NOP $00,x
            stx $04            ; $fcee: 86 04     
            .hex 87 14         ; $fcf0: 87 14     Invalid Opcode - SAX $14
            .hex 1c 22 86      ; $fcf2: 1c 22 86  Invalid Opcode - NOP __8622,x
            .hex 34 84         ; $fcf5: 34 84     Invalid Opcode - NOP $84,x
            bit $0404          ; $fcf7: 2c 04 04  
            .hex 04 87         ; $fcfa: 04 87     Invalid Opcode - NOP $87
__fcfc:     .hex 14 1a         ; $fcfc: 14 1a     Invalid Opcode - NOP $1a,x
            bit $86            ; $fcfe: 24 86     
            .hex 32            ; $fd00: 32        Invalid Opcode - KIL 
            sty $2c            ; $fd01: 84 2c     
            .hex 04 86         ; $fd03: 04 86     Invalid Opcode - NOP $86
            .hex 04 87         ; $fd05: 04 87     Invalid Opcode - NOP $87
            clc                ; $fd07: 18        
            asl __8628,x       ; $fd08: 1e 28 86  
            rol $87,x          ; $fd0b: 36 87     
__fd0d:     bmi __fd3f         ; $fd0d: 30 30     
            bmi __fc91         ; $fd0f: 30 80     
            bit $1482          ; $fd11: 2c 82 14  
            bit $2662          ; $fd14: 2c 62 26  
            bpl __fd41         ; $fd17: 10 28     
            .hex 80 04         ; $fd19: 80 04     Invalid Opcode - NOP #$04
            .hex 82 14         ; $fd1b: 82 14     Invalid Opcode - NOP #$14
            bit $2662          ; $fd1d: 2c 62 26  
            bpl __fd4a         ; $fd20: 10 28     
            .hex 80 04         ; $fd22: 80 04     Invalid Opcode - NOP #$04
            .hex 82 08         ; $fd24: 82 08     Invalid Opcode - NOP #$08
            asl $185e,x        ; $fd26: 1e 5e 18  
            rts                ; $fd29: 60        

;-------------------------------------------------------------------------------
            .hex 1a            ; $fd2a: 1a        Invalid Opcode - NOP 
            .hex 80 04         ; $fd2b: 80 04     Invalid Opcode - NOP #$04
            .hex 82 08         ; $fd2d: 82 08     Invalid Opcode - NOP #$08
            asl $185e,x        ; $fd2f: 1e 5e 18  
            rts                ; $fd32: 60        

;-------------------------------------------------------------------------------
            .hex 1a            ; $fd33: 1a        Invalid Opcode - NOP 
            stx $04            ; $fd34: 86 04     
            .hex 83 1a         ; $fd36: 83 1a     Invalid Opcode - SAX ($1a,x)
            clc                ; $fd38: 18        
            asl $84,x          ; $fd39: 16 84     
            .hex 14 1a         ; $fd3b: 14 1a     Invalid Opcode - NOP $1a,x
            clc                ; $fd3d: 18        
            .hex 0e            ; $fd3e: 0e        Suspected data
__fd3f:     .hex 0c 16         ; $fd3f: 0c 16     Suspected data
__fd41:     .hex 83 14         ; $fd41: 83 14     Invalid Opcode - SAX ($14,x)
__fd43:     jsr $1c1e          ; $fd43: 20 1e 1c  
            plp                ; $fd46: 28        
__fd47:     rol $87            ; $fd47: 26 87     
            .hex 24            ; $fd49: 24        Suspected data
__fd4a:     .hex 1a            ; $fd4a: 1a        Invalid Opcode - NOP 
            .hex 12            ; $fd4b: 12        Invalid Opcode - KIL 
            bpl __fdb0         ; $fd4c: 10 62     
            asl $0480          ; $fd4e: 0e 80 04  
            .hex 04 00         ; $fd51: 04 00     Invalid Opcode - NOP $00
            .hex 82 18         ; $fd53: 82 18     Invalid Opcode - NOP #$18
            .hex 1c 20 22      ; $fd55: 1c 20 22  Invalid Opcode - NOP $2220,x
            rol $28            ; $fd58: 26 28     
            sta ($2a,x)        ; $fd5a: 81 2a     
            rol                ; $fd5c: 2a        
            rol                ; $fd5d: 2a        
            .hex 04 2a         ; $fd5e: 04 2a     Invalid Opcode - NOP $2a
            .hex 04 83         ; $fd60: 04 83     Invalid Opcode - NOP $83
            rol                ; $fd62: 2a        
            .hex 82 22         ; $fd63: 82 22     Invalid Opcode - NOP #$22
            stx $34            ; $fd65: 86 34     
            .hex 32            ; $fd67: 32        Invalid Opcode - KIL 
            .hex 34 81         ; $fd68: 34 81     Invalid Opcode - NOP $81,x
            .hex 04 22         ; $fd6a: 04 22     Invalid Opcode - NOP $22
            rol $2a            ; $fd6c: 26 2a     
            bit __8630         ; $fd6e: 2c 30 86  
            .hex 34 83         ; $fd71: 34 83     Invalid Opcode - NOP $83,x
            .hex 32            ; $fd73: 32        Invalid Opcode - KIL 
            .hex 82 36         ; $fd74: 82 36     Invalid Opcode - NOP #$36
            sty $34            ; $fd76: 84 34     
            sta $04            ; $fd78: 85 04     
            sta ($22,x)        ; $fd7a: 81 22     
            stx $30            ; $fd7c: 86 30     
            rol __8130         ; $fd7e: 2e 30 81  
            .hex 04 22         ; $fd81: 04 22     Invalid Opcode - NOP $22
            rol $2a            ; $fd83: 26 2a     
            bit __862e         ; $fd85: 2c 2e 86  
            bmi __fd0d         ; $fd88: 30 83     
            .hex 22            ; $fd8a: 22        Invalid Opcode - KIL 
            .hex 82 36         ; $fd8b: 82 36     Invalid Opcode - NOP #$36
            sty $34            ; $fd8d: 84 34     
            sta $04            ; $fd8f: 85 04     
            sta ($22,x)        ; $fd91: 81 22     
            stx $3a            ; $fd93: 86 3a     
            .hex 3a            ; $fd95: 3a        Invalid Opcode - NOP 
            .hex 3a            ; $fd96: 3a        Invalid Opcode - NOP 
            .hex 82 3a         ; $fd97: 82 3a     Invalid Opcode - NOP #$3a
            sta ($40,x)        ; $fd99: 81 40     
            .hex 82 04         ; $fd9b: 82 04     Invalid Opcode - NOP #$04
            sta ($3a,x)        ; $fd9d: 81 3a     
            stx $36            ; $fd9f: 86 36     
            rol $36,x          ; $fda1: 36 36     
            .hex 82 36         ; $fda3: 82 36     Invalid Opcode - NOP #$36
            sta ($3a,x)        ; $fda5: 81 3a     
            .hex 82 04         ; $fda7: 82 04     Invalid Opcode - NOP #$04
            sta ($36,x)        ; $fda9: 81 36     
            stx $34            ; $fdab: 86 34     
            .hex 82 26         ; $fdad: 82 26     Invalid Opcode - NOP #$26
            rol                ; $fdaf: 2a        
__fdb0:     rol $81,x          ; $fdb0: 36 81     
            .hex 34 34         ; $fdb2: 34 34     Invalid Opcode - NOP $34,x
            sta $34            ; $fdb4: 85 34     
            sta ($2a,x)        ; $fdb6: 81 2a     
            stx $2c            ; $fdb8: 86 2c     
            brk                ; $fdba: 00        
            sty $90            ; $fdbb: 84 90     
            bcs __fd43         ; $fdbd: b0 84     
            bvc __fe11         ; $fdbf: 50 50     
            bcs __fdc3         ; $fdc1: b0 00     
__fdc3:     tya                ; $fdc3: 98        
            .hex 96            ; $fdc4: 96        Suspected data
__fdc5:     sty $92,x          ; $fdc5: 94 92     
__fdc7:     sty $96,x          ; $fdc7: 94 96     
            cli                ; $fdc9: 58        
            cli                ; $fdca: 58        
            cli                ; $fdcb: 58        
            .hex 44 5c         ; $fdcc: 44 5c     Invalid Opcode - NOP $5c
            .hex 44 9f         ; $fdce: 44 9f     Invalid Opcode - NOP $9f
            .hex a3 a1         ; $fdd0: a3 a1     Invalid Opcode - LAX ($a1,x)
            .hex a3 85         ; $fdd2: a3 85     Invalid Opcode - LAX ($85,x)
            .hex a3 e0         ; $fdd4: a3 e0     Invalid Opcode - LAX ($e0,x)
            ldx $23            ; $fdd6: a6 23     
            cpy $9f            ; $fdd8: c4 9f     
            sta __859f,x       ; $fdda: 9d 9f 85  
            .hex 9f d2 a6      ; $fddd: 9f d2 a6  Invalid Opcode - AHX __a6d2,y
            .hex 23 c4         ; $fde0: 23 c4     Invalid Opcode - RLA ($c4,x)
            lda $b1,x          ; $fde2: b5 b1     
            .hex af 85 b1      ; $fde4: af 85 b1  Invalid Opcode - LAX __b185
            .hex af ad 85      ; $fde7: af ad 85  Invalid Opcode - LAX __85ad
            sta $9e,x          ; $fdea: 95 9e     
            ldx #$aa           ; $fdec: a2 aa     
            ror                ; $fdee: 6a        
            ror                ; $fdef: 6a        
            .hex 6b 5e         ; $fdf0: 6b 5e     Invalid Opcode - ARR #$5e
            sta $0484,x        ; $fdf2: 9d 84 04  
            .hex 04 82         ; $fdf5: 04 82     Invalid Opcode - NOP $82
            .hex 22            ; $fdf7: 22        Invalid Opcode - KIL 
            stx $22            ; $fdf8: 86 22     
            .hex 82 14         ; $fdfa: 82 14     Invalid Opcode - NOP #$14
            .hex 22            ; $fdfc: 22        Invalid Opcode - KIL 
            bit $2212          ; $fdfd: 2c 12 22  
__fe00:     rol                ; $fe00: 2a        
            .hex 14            ; $fe01: 14        Suspected data
__fe02:     .hex 22            ; $fe02: 22        Invalid Opcode - KIL 
            bit $221c          ; $fe03: 2c 1c 22  
__fe06:     .hex 2c            ; $fe06: 2c        Suspected data
__fe07:     .hex 14 22         ; $fe07: 14 22     Invalid Opcode - NOP $22,x
            .hex 2c            ; $fe09: 2c        Suspected data
__fe0a:     .hex 12            ; $fe0a: 12        Invalid Opcode - KIL 
__fe0b:     .hex 22            ; $fe0b: 22        Invalid Opcode - KIL 
            rol                ; $fe0c: 2a        
            .hex 14 22         ; $fe0d: 14 22     Invalid Opcode - NOP $22,x
            .hex 2c 1c         ; $fe0f: 2c 1c     Suspected data
__fe11:     .hex 22            ; $fe11: 22        Invalid Opcode - KIL 
            bit $2218          ; $fe12: 2c 18 22  
            rol                ; $fe15: 2a        
            asl $20,x          ; $fe16: 16 20     
            plp                ; $fe18: 28        
            clc                ; $fe19: 18        
            .hex 22            ; $fe1a: 22        Invalid Opcode - KIL 
            rol                ; $fe1b: 2a        
            .hex 12            ; $fe1c: 12        Invalid Opcode - KIL 
            .hex 22            ; $fe1d: 22        Invalid Opcode - KIL 
            rol                ; $fe1e: 2a        
            clc                ; $fe1f: 18        
            .hex 22            ; $fe20: 22        Invalid Opcode - KIL 
            rol                ; $fe21: 2a        
            .hex 12            ; $fe22: 12        Invalid Opcode - KIL 
            .hex 22            ; $fe23: 22        Invalid Opcode - KIL 
            rol                ; $fe24: 2a        
            .hex 14 22         ; $fe25: 14 22     Invalid Opcode - NOP $22,x
            bit $220c          ; $fe27: 2c 0c 22  
            bit $2214          ; $fe2a: 2c 14 22  
            .hex 34 12         ; $fe2d: 34 12     Invalid Opcode - NOP $12,x
            .hex 22            ; $fe2f: 22        Invalid Opcode - KIL 
            bmi __fe42         ; $fe30: 30 10     
            .hex 22            ; $fe32: 22        Invalid Opcode - KIL 
            rol $2216          ; $fe33: 2e 16 22  
            .hex 34 18         ; $fe36: 34 18     Invalid Opcode - NOP $18,x
            rol $36            ; $fe38: 26 36     
            asl $26,x          ; $fe3a: 16 26     
            rol $14,x          ; $fe3c: 36 14     
            rol $36            ; $fe3e: 26 36     
            .hex 12            ; $fe40: 12        Invalid Opcode - KIL 
            .hex 22            ; $fe41: 22        Invalid Opcode - KIL 
__fe42:     rol $5c,x          ; $fe42: 36 5c     
            .hex 22            ; $fe44: 22        Invalid Opcode - KIL 
            .hex 34 0c         ; $fe45: 34 0c     Invalid Opcode - NOP $0c,x
            .hex 22            ; $fe47: 22        Invalid Opcode - KIL 
__fe48:     .hex 22            ; $fe48: 22        Invalid Opcode - KIL 
            sta ($1e,x)        ; $fe49: 81 1e     
            .hex 1e 85         ; $fe4b: 1e 85     Suspected data
__fe4d:     asl $1281,x        ; $fe4d: 1e 81 12  
            stx $14            ; $fe50: 86 14     
            sta ($2c,x)        ; $fe52: 81 2c     
            .hex 22            ; $fe54: 22        Invalid Opcode - KIL 
__fe55:     .hex 1c 2c 22      ; $fe55: 1c 2c 22  Invalid Opcode - NOP $222c,x
            .hex 1c 85 2c      ; $fe58: 1c 85 2c  Invalid Opcode - NOP $2c85,x
            .hex 04 81         ; $fe5b: 04 81     Invalid Opcode - NOP $81
            rol $1e24          ; $fe5d: 2e 24 1e  
            rol $1e24          ; $fe60: 2e 24 1e  
            sta $2e            ; $fe63: 85 2e     
            .hex 04 81         ; $fe65: 04 81     Invalid Opcode - NOP $81
            .hex 32            ; $fe67: 32        Invalid Opcode - KIL 
            plp                ; $fe68: 28        
            .hex 22            ; $fe69: 22        Invalid Opcode - KIL 
            .hex 32            ; $fe6a: 32        Invalid Opcode - KIL 
            plp                ; $fe6b: 28        
            .hex 22            ; $fe6c: 22        Invalid Opcode - KIL 
            sta $32            ; $fe6d: 85 32     
            .hex 87 36         ; $fe6f: 87 36     Invalid Opcode - SAX $36
            rol $36,x          ; $fe71: 36 36     
            sty $3a            ; $fe73: 84 3a     
            brk                ; $fe75: 00        
            .hex 5c 54 4c      ; $fe76: 5c 54 4c  Invalid Opcode - NOP $4c54,x
            .hex 5c 54 4c      ; $fe79: 5c 54 4c  Invalid Opcode - NOP $4c54,x
            .hex 5c 1c 1c      ; $fe7c: 5c 1c 1c  Invalid Opcode - NOP $1c1c,x
            .hex 5c 5c 5c      ; $fe7f: 5c 5c 5c  Invalid Opcode - NOP $5c5c,x
            .hex 5c 5e 56      ; $fe82: 5c 5e 56  Invalid Opcode - NOP $565e,x
            lsr $565e          ; $fe85: 4e 5e 56  
            lsr $1e5e          ; $fe88: 4e 5e 1e  
            asl $5e5e,x        ; $fe8b: 1e 5e 5e  
            lsr $625e,x        ; $fe8e: 5e 5e 62  
            .hex 5a            ; $fe91: 5a        Invalid Opcode - NOP 
            bvc __fef6         ; $fe92: 50 62     
            .hex 5a            ; $fe94: 5a        Invalid Opcode - NOP 
            bvc __fef9         ; $fe95: 50 62     
            .hex 22            ; $fe97: 22        Invalid Opcode - KIL 
            .hex 22            ; $fe98: 22        Invalid Opcode - KIL 
            .hex 62            ; $fe99: 62        Invalid Opcode - KIL 
            .hex e7 e7         ; $fe9a: e7 e7     Invalid Opcode - ISC $e7
            .hex e7 2b         ; $fe9c: e7 2b     Invalid Opcode - ISC $2b
            stx $14            ; $fe9e: 86 14     
            sta ($14,x)        ; $fea0: 81 14     
            .hex 80 14         ; $fea2: 80 14     Invalid Opcode - NOP #$14
            .hex 14 81         ; $fea4: 14 81     Invalid Opcode - NOP $81,x
            .hex 14 14         ; $fea6: 14 14     Invalid Opcode - NOP $14,x
            .hex 14 14         ; $fea8: 14 14     Invalid Opcode - NOP $14,x
            stx $16            ; $feaa: 86 16     
            sta ($16,x)        ; $feac: 81 16     
            .hex 80 16         ; $feae: 80 16     Invalid Opcode - NOP #$16
            asl $81,x          ; $feb0: 16 81     
            asl $16,x          ; $feb2: 16 16     
            asl $16,x          ; $feb4: 16 16     
            sta ($28,x)        ; $feb6: 81 28     
            .hex 22            ; $feb8: 22        Invalid Opcode - KIL 
            .hex 1a            ; $feb9: 1a        Invalid Opcode - NOP 
            plp                ; $feba: 28        
            .hex 22            ; $febb: 22        Invalid Opcode - KIL 
            .hex 1a            ; $febc: 1a        Invalid Opcode - NOP 
            plp                ; $febd: 28        
            .hex 80 28         ; $febe: 80 28     Invalid Opcode - NOP #$28
            plp                ; $fec0: 28        
            sta ($28,x)        ; $fec1: 81 28     
            .hex 87 2c         ; $fec3: 87 2c     Invalid Opcode - SAX $2c
            bit __842c         ; $fec5: 2c 2c 84  
            bmi __fe4d         ; $fec8: 30 83     
            .hex 04 84         ; $feca: 04 84     Invalid Opcode - NOP $84
            .hex 0c 83 62      ; $fecc: 0c 83 62  Invalid Opcode - NOP $6283
            bpl __fe55         ; $fecf: 10 84     
            .hex 12            ; $fed1: 12        Invalid Opcode - KIL 
            .hex 83 1c         ; $fed2: 83 1c     Invalid Opcode - SAX ($1c,x)
            .hex 22            ; $fed4: 22        Invalid Opcode - KIL 
            asl $2622,x        ; $fed5: 1e 22 26  
            clc                ; $fed8: 18        
            asl $1c04,x        ; $fed9: 1e 04 1c  
            brk                ; $fedc: 00        
__fedd:     .hex e3 e1         ; $fedd: e3 e1     Invalid Opcode - ISC ($e1,x)
            .hex e3 1d         ; $fedf: e3 1d     Invalid Opcode - ISC ($1d,x)
            dec $23e0,x        ; $fee1: de e0 23  
            cpx $7475          ; $fee4: ec 75 74  
            beq __fedd         ; $fee7: f0 f4     
            inc $ea,x          ; $fee9: f6 ea     
            and ($2d),y        ; $feeb: 31 2d     
            .hex 83 12         ; $feed: 83 12     Invalid Opcode - SAX ($12,x)
            .hex 14 04         ; $feef: 14 04     Invalid Opcode - NOP $04,x
            clc                ; $fef1: 18        
            .hex 1a            ; $fef2: 1a        Invalid Opcode - NOP 
            .hex 1c 14 26      ; $fef3: 1c 14 26  Invalid Opcode - NOP $2614,x
__fef6:     .hex 22            ; $fef6: 22        Invalid Opcode - KIL 
            .hex 1e 1c         ; $fef7: 1e 1c     Suspected data
__fef9:     clc                ; $fef9: 18        
            asl $0c22,x        ; $fefa: 1e 22 0c  
            .hex 14 ff         ; $fefd: 14 ff     Invalid Opcode - NOP $ff,x
            .hex ff            ; $feff: ff        Suspected data
__ff00:     brk                ; $ff00: 00        
__ff01:     dey                ; $ff01: 88        
            brk                ; $ff02: 00        
            .hex 2b 00         ; $ff03: 2b 00     Invalid Opcode - ANC #$00
            brk                ; $ff05: 00        
            .hex 02            ; $ff06: 02        Invalid Opcode - KIL 
            .hex 72            ; $ff07: 72        Invalid Opcode - KIL 
            .hex 02            ; $ff08: 02        Invalid Opcode - KIL 
            .hex 4f 02 2e      ; $ff09: 4f 02 2e  Invalid Opcode - SRE $2e02
            .hex 02            ; $ff0c: 02        Invalid Opcode - KIL 
            asl __f101         ; $ff0d: 0e 01 f1  
            ora ($ba,x)        ; $ff10: 01 ba     
            ora ($a1,x)        ; $ff12: 01 a1     
            ora ($8a,x)        ; $ff14: 01 8a     
            ora ($74,x)        ; $ff16: 01 74     
            ora ($5f,x)        ; $ff18: 01 5f     
            ora ($4b,x)        ; $ff1a: 01 4b     
            ora ($39,x)        ; $ff1c: 01 39     
            ora ($27,x)        ; $ff1e: 01 27     
            ora ($17,x)        ; $ff20: 01 17     
            ora ($07,x)        ; $ff22: 01 07     
            brk                ; $ff24: 00        
            sed                ; $ff25: f8        
            brk                ; $ff26: 00        
            nop                ; $ff27: ea        
            brk                ; $ff28: 00        
            cmp __d100,x       ; $ff29: dd 00 d1  
            brk                ; $ff2c: 00        
            cmp $00            ; $ff2d: c5 00     
            tsx                ; $ff2f: ba        
__ff30:     brk                ; $ff30: 00        
            .hex af 00 a5      ; $ff31: af 00 a5  Invalid Opcode - LAX __a500
            brk                ; $ff34: 00        
__ff35:     .hex 9c 00 94      ; $ff35: 9c 00 94  Invalid Opcode - SHY __9400,x
            brk                ; $ff38: 00        
            .hex 8b 00         ; $ff39: 8b 00     Invalid Opcode - XAA #$00
            .hex 83 00         ; $ff3b: 83 00     Invalid Opcode - SAX ($00,x)
            .hex 7c 00 6e      ; $ff3d: 7c 00 6e  Invalid Opcode - NOP $6e00,x
            brk                ; $ff40: 00        
            .hex 74 00         ; $ff41: 74 00     Invalid Opcode - NOP $00,x
            pla                ; $ff43: 68        
            brk                ; $ff44: 00        
            lsr $5c00          ; $ff45: 4e 00 5c  
            brk                ; $ff48: 00        
            cli                ; $ff49: 58        
            brk                ; $ff4a: 00        
            .hex 52            ; $ff4b: 52        Invalid Opcode - KIL 
            brk                ; $ff4c: 00        
            lsr                ; $ff4d: 4a        
            brk                ; $ff4e: 00        
            .hex 42            ; $ff4f: 42        Invalid Opcode - KIL 
            brk                ; $ff50: 00        
            rol $3600,x        ; $ff51: 3e 00 36  
            brk                ; $ff54: 00        
            and ($00),y        ; $ff55: 31 00     
            .hex 27 00         ; $ff57: 27 00     Invalid Opcode - RLA $00
            jsr $1d04          ; $ff59: 20 04 1d  
            .hex 03 15         ; $ff5c: 03 15     Invalid Opcode - SLO ($15,x)
            .hex 02            ; $ff5e: 02        Invalid Opcode - KIL 
            ldx __9802,y       ; $ff5f: be 02 98  
            ora ($d5,x)        ; $ff62: 01 d5     
            brk                ; $ff64: 00        
            .hex 62            ; $ff65: 62        Invalid Opcode - KIL 
__ff66:     .hex 04 08         ; $ff66: 04 08     Invalid Opcode - NOP $08
            bpl __ff8a         ; $ff68: 10 20     
            rti                ; $ff6a: 40        

;-------------------------------------------------------------------------------
            clc                ; $ff6b: 18        
            bmi __ff7a         ; $ff6c: 30 0c     
            .hex 03 06         ; $ff6e: 03 06     Invalid Opcode - SLO ($06,x)
            .hex 0c 18 30      ; $ff70: 0c 18 30  Invalid Opcode - NOP $3018
            .hex 12            ; $ff73: 12        Invalid Opcode - KIL 
            bit $08            ; $ff74: 24 08     
            .hex 03 06         ; $ff76: 03 06     Invalid Opcode - SLO ($06,x)
            .hex 0c 18         ; $ff78: 0c 18     Suspected data
__ff7a:     bmi __ff8e         ; $ff7a: 30 12     
            bit $08            ; $ff7c: 24 08     
            bit $02            ; $ff7e: 24 02     
            asl $04            ; $ff80: 06 04     
            .hex 0c 12 18      ; $ff82: 0c 12 18  Invalid Opcode - NOP $1812
            php                ; $ff85: 08        
            .hex 1b 01 05      ; $ff86: 1b 01 05  Invalid Opcode - SLO $0501,y
            .hex 03            ; $ff89: 03        Suspected data
__ff8a:     ora #$0d           ; $ff8a: 09 0d     
            .hex 12            ; $ff8c: 12        Invalid Opcode - KIL 
            .hex 06            ; $ff8d: 06        Suspected data
__ff8e:     .hex 12            ; $ff8e: 12        Invalid Opcode - KIL 
            ora ($03,x)        ; $ff8f: 01 03     
            .hex 02            ; $ff91: 02        Invalid Opcode - KIL 
            asl $09            ; $ff92: 06 09     
            .hex 0c 04         ; $ff94: 0c 04     Suspected data
__ff96:     tya                ; $ff96: 98        
            sta __9b9a,y       ; $ff97: 99 9a 9b  
__ff9a:     bcc __ff30         ; $ff9a: 90 94     
            sty $95,x          ; $ff9c: 94 95     
            sta $96,x          ; $ff9e: 95 96     
            .hex 97 98         ; $ffa0: 97 98     Invalid Opcode - SAX $98,y
__ffa2:     bcc __ff35         ; $ffa2: 90 91     
            .hex 92            ; $ffa4: 92        Invalid Opcode - KIL 
            .hex 92            ; $ffa5: 92        Invalid Opcode - KIL 
            .hex 93 93         ; $ffa6: 93 93     Invalid Opcode - AHX ($93),y
            .hex 93 94         ; $ffa8: 93 94     Invalid Opcode - AHX ($94),y
            sty $94,x          ; $ffaa: 94 94     
            sty $94,x          ; $ffac: 94 94     
            sty $95,x          ; $ffae: 94 95     
            sta $95,x          ; $ffb0: 95 95     
            sta $95,x          ; $ffb2: 95 95     
            sta $96,x          ; $ffb4: 95 96     
            stx $96,y          ; $ffb6: 96 96     
            stx $96,y          ; $ffb8: 96 96     
            stx $96,y          ; $ffba: 96 96     
            stx $96,y          ; $ffbc: 96 96     
            stx $96,y          ; $ffbe: 96 96     
            stx $96,y          ; $ffc0: 96 96     
            stx $96,y          ; $ffc2: 96 96     
            stx $96,y          ; $ffc4: 96 96     
            sta $95,x          ; $ffc6: 95 95     
            .hex 94            ; $ffc8: 94        Suspected data
__ffc9:     .hex 93 15         ; $ffc9: 93 15     Invalid Opcode - AHX ($15),y
            asl $16,x          ; $ffcb: 16 16     
            .hex 17 17         ; $ffcd: 17 17     Invalid Opcode - SLO $17,x
            clc                ; $ffcf: 18        
            ora $1a19,y        ; $ffd0: 19 19 1a  
            .hex 1a            ; $ffd3: 1a        Invalid Opcode - NOP 
            .hex 1c 1d 1d      ; $ffd4: 1c 1d 1d  Invalid Opcode - NOP $1d1d,x
            asl $1f1e,x        ; $ffd7: 1e 1e 1f  
            .hex 1f 1f 1f      ; $ffda: 1f 1f 1f  Invalid Opcode - SLO $1f1f,x
            asl $1c1d,x        ; $ffdd: 1e 1d 1c  
            asl $1f1f,x        ; $ffe0: 1e 1f 1f  
            asl $1c1d,x        ; $ffe3: 1e 1d 1c  
            .hex 1a            ; $ffe6: 1a        Invalid Opcode - NOP 
            clc                ; $ffe7: 18        
            asl $14,x          ; $ffe8: 16 14     
__ffea:     ora $16,x          ; $ffea: 15 16     
            asl $17,x          ; $ffec: 16 17     
            .hex 17 18         ; $ffee: 17 18     Invalid Opcode - SLO $18,x

;-------------------------------------------------------------------------------
; irq/brk vector
;-------------------------------------------------------------------------------
irq:        ora $1a19,y        ; $fff0: 19 19 1a  
            .hex 1a            ; $fff3: 1a        Invalid Opcode - NOP 
            .hex 1c 1d 1d      ; $fff4: 1c 1d 1d  Invalid Opcode - NOP $1d1d,x
            asl $1f1e,x        ; $fff7: 1e 1e 1f  

;-------------------------------------------------------------------------------
; Vector Table
;-------------------------------------------------------------------------------
vectors:    .dw nmi                        ; $fffa: 82 80     Vector table
            .dw reset                      ; $fffc: 00 80     Vector table
            .dw irq                        ; $fffe: f0 ff     Vector table

;-------------------------------------------------------------------------------
; CHR-ROM
;-------------------------------------------------------------------------------
            .incbin mario.chr  ; Include CHR-ROM
