            INCLUDE <6811DEF.I>

         ORG $0000
         ZMB 1                  ; one byte holds current position of "cursor"
         RMB 16                 ; within LCD-IMAGE work area.

LCDPOS   = $0000
LCDIMAGE = $0001
LCDSIZE  = 16                   ; number of visible characters on display

EOS      = $04

; LCM Connection List:
;      D4..D7         is        PA4..PA7
;      RS             is        PD3
;      E              is        PD2
;      R/w            is        Tied to GND
;
;-----------------------------------------------------------------------------
         ORG $D000
Msg1 = *
         FCC 'I got this bratty brother...'
Msg2 = *
         FCC 'He bugs me every day...'
Msg3 = *
         FCC 'And this morning my own mother...'
         FCC 'She gave my last cupcake away...'
         FCC 'My dad acts like he belongs...'
         FCC 'He belongs in a zoo...'
         FCC ~I'm the saddest kid...~
         FCC 'In grade number two'
Msg4 = *
         FCC ' Turn The Knob !'
         FCB EOS
;-----------------------------------------------------------------------------
; ClrImage : Sets all positions in the LCDIMAGE to blanks ($20)
;-----------------------------------------------------------------------------
ClrImage:
         pshx
         ldx #LCDIMAGE
Loop@:   bset $00,x $20
         bclr $00,x $DF
         inx
         cpx #LCDIMAGE+LCDSIZE
         bls Loop@
         pulx
         rts
;-----------------------------------------------------------------------------
Str2Image:            ; String image Address is in X, Terminated with an EOS
         pshy
         pshb            ; if exceeds caharacter #16, Sub Terminated.
         pshx
         ldy #LCDIMAGE
         ldab LCDPOS     ; Destination position is in LCDPOS
         aby
Loop@:   ldaa $00,x
         cmpa #EOS
         beq EndStr
         staa $00,y
         inx
         iny
         inc $00         ; Update current Pointer position
         cpy #LCDIMAGE+#LCDSIZE
         bls Loop@
EndStr:  pulx
         pulb
         puly
         rts
Asc2Image:                              ; sends one character to the Image
         pshx
         pshb
         ldx #LCDIMAGE
         inc $00                        ; increase cursor position by 1
         ldab $00
         cmpb #LCDSIZE+#LCDIMAGE
         bhi AscEnd
         abx
         dex
         staa $00,x
AscEnd:  pulb
         pulx
         rts
;-----------------------------------------------------------------------------
; Transfers the contents of the LCDIMAGE area (LCDIMAGE..LCDIMAGE+LCDSIZE)
; to the LCM.
;-----------------------------------------------------------------------------
Image2LCD:
         psha
         pshx
         ldx #LCDIMAGE
         ldaa #$80
         jsr LcdCmd
Loop@:   ldaa $00,x
         jsr LcdDat
         inx
         cpx #LCDSIZE/2+#LCDIMAGE
         bne NextChk
         ldaa #$C0          ; if crossing mid-line position,do the addr. fix
         jsr LcdCmd
NextChk: cpx #LCDIMAGE+#LCDSIZE
         bls Loop@
         pulx
         pula
         rts

;-----------------------------------------------------------------------------
; DecOut : Sends 3 decimal digits (in ASCII codes) to the LCDIMAGE area.
;-----------------------------------------------------------------------------
DecOut:  ldab #'0
Loop@:   cmpa #100
         blo Dig3
         suba #100
         incb
         bra Loop@
Dig3:    psha
         tba
         jsr Asc2Image             ; Send 100's digit
         pula
         ldab #'0
Dig2:    cmpa #10
         blo Dig1
         suba #10
         incb
         bra Dig2
Dig1:    psha
         tba
         jsr Asc2Image             ; Send 10's digit
         pula
         adda #'0
         jsr Asc2Image             ; Send 1's digit
         rts
;-----------------------------------------------------------------------------
; InitLcd : Initializes the LCM for direct interface.
;           * Programs PORT D as all outputs
;           * Fixes PORT A bit 7 (DDRA7)
;           * Sets Interface length (4 bit), 2 display lines ($2c)
;             (= one 16-char display line), and 5 * 7 font (only mode avail.)
;           * Sets Display status as visible, no cursor ($0C)
;           * clears the diplay and waits the required ~1.64 ms
;-----------------------------------------------------------------------------
InitLcd: ldaa #$3F
         ldx #$1000
         staa DDRD,x
         clr PORTD,x
         clr PORTA,x
         ldaa #$80
         staa PACTL,x
         ldaa #$2C              ; Data length 4-Bit, 2 Display Lines,
         jsr LcdCmd             ; 5 * 7 Font
         ldaa #$0C              ; 1/Display ON/Cursor ON/Blink OFF
         jsr LcdCmd
         ldaa #$01              ; Clear Display , Cursor Home
         jsr LcdCmd
         jsr LcdDelay
         jsr LcdDelay
         rts
;-----------------------------------------------------------------------------
; LcdCmd : Sends one command byte to the LCM
; LcdDat : Sends one Data byte to the LCM
;
;-----------------------------------------------------------------------------
LcdCmd:  pshx                   ; Entry Point for Command Tx
         ldx #$1000
         bclr PORTD,x $08
         bra Send2Lcd
LcdDat:  pshx                   ; Entry Point for data Tx
         ldx #$1000
         bset PORTD,x $08
Send2Lcd:
         nop                    ; This Delay essential when sending two
         nop                    ; characters or more one after the other.
         nop                    ;
         tab
         anda #%11110000
         staa $00
         ldaa PORTA,x
         anda #%00001111
         oraa $00
         staa PORTA,x
         bset PORTD,x 04
         bclr PORTD,x 04
         aslb
         aslb
         aslb
         aslb
         stab $00
         ldaa PORTA,x
         anda #%00001111
         oraa $00
         staa PORTA,x
         bset PORTD,x 04
         bclr PORTD,x 04
         pulx
         rts
LcdDelay:
         pshx
         ldx #$0150
loop:    dex
         bne loop
         pulx
         rts
;-----------------------------------------------------------------------------
         ORG $C000
         lds #$004F
         ldaa #$80
         staa $1000+OPTION             ; A/D Power Up
         jsr InitLcd
LooK@:   ldx #$1030
         clr $00
Loo@:    ldaa #$31
         staa $1030
Wait@:   brclr 00,x $80 Wait@
         ldx #Msg4
         jsr Str2Image
         ldaa $1031
         staa $12
;         jsr ClrImage

         lsra
         lsra
         lsra
         lsra
         inca
         ldab #255
         ldx #LCDIMAGE
Loop@:   stab 00,x
         inx
         cpx #LCDIMAGE+#LCDSIZE
         bhi GoOn
         deca
         bne Loop@
         ldaa $12
         anda #%00001111
         adda #48
         cmpa #57
         bls GoOn
         adda #7
GoOn:    clr $00
         jsr Asc2Image
         jsr Image2LCD
         ldx #$1000
L@:      dex
         bne L@

         bra LooK@
