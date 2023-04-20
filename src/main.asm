.include "nesdefs.inc"
.include "header.inc"
.include "macros.asm"

L_byte         = $0000
H_byte         = $0001

.segment "ZEROPAGE"
player_x:       .res 1
player_y:       .res 1
player_dir:     .res 1
.importzp ppuctrl_value, scroll

.segment "CODE"
.export main
.export move_person
.export draw_person
.export draw_background

.proc main

; Установка первоначальных позиций
        LDA #$80
        STA player_x
        LDA #$A0
        STA player_y

; Установка бэкграунда
        LDA #>NAMETABLE_1
        LDX #>background1
        LDY #<background1
        JSR draw_background

        LDA #>NAMETABLE_3
        LDX #>background2
        LDY #<background2
        JSR draw_background

; Установка палитры
        LDA PPU_STATUS
        LDA #>PALETTE
        STA PPU_ADDR
        LDA #<PALETTE
        STA PPU_ADDR
        
        LDX #$00

load_palettes:
        LDA palettes,X
        STA PPU_DATA
        INX
        CPX #$20
        BNE load_palettes

vblankwait:
        BIT PPU_STATUS
        BPL vblankwait

        LDA #CTRL_NMI|CTRL_BG_0000|CTRL_NT_2000
        STA ppuctrl_value
        STA PPU_CTRL

        LDA #MASK_SPR|MASK_BG|MASK_SPR_CLIP|MASK_BG_CLIP
        STA PPU_MASK
        
        LDA #239
        STA scroll

forever:
        JMP forever
.endproc

.proc move_person
        SUBROUTINE_START

        LDA player_x
        CMP #$E0
        BCC not_at_right_edge
        LDA #$00
        STA player_dir
        JMP direction_set

not_at_right_edge:
        LDA player_x
        CMP #$10
        BCS direction_set
        LDA #$01
        STA player_dir

direction_set:
        LDA player_dir
        CMP #$01
        BEQ move_right
        DEC player_x
        JMP finish_move

move_right:
        INC player_x

finish_move:
        SUBROUTINE_END
.endproc

.proc draw_person
        SUBROUTINE_START

        ; Тайлы из которых состоит спрайт
        LDA #$18
        STA OAM_RAM + $01
        LDA #$19
        STA OAM_RAM + $05
        LDA #$1A
        STA OAM_RAM + $09
        LDA #$1B
        STA OAM_RAM + $0D

        ; Палитры каждого тайла
        LDA #$00
        STA OAM_RAM + $02
        STA OAM_RAM + $06
        STA OAM_RAM + $0A
        STA OAM_RAM + $0E

        ; Расположение тайлов на экране
        ; - левый верхний
        LDA player_y
        STA OAM_RAM + $00
        LDA player_x
        STA OAM_RAM + $03

        ; - правый верхний
        LDA player_y
        STA OAM_RAM + $04
        LDA player_x
        CLC
        ADC #$08
        STA OAM_RAM + $07

        ; - нижний левый
        LDA player_y
        CLC
        ADC #$08
        STA OAM_RAM + $08
        LDA player_x
        STA OAM_RAM + $0B

        ; - нижний правый
        LDA player_y
        CLC
        ADC #$08
        STA OAM_RAM + $0C
        LDA player_x
        CLC
        ADC #$08
        STA OAM_RAM + $0F

        SUBROUTINE_END
.endproc

.proc draw_background
        PHA
        LDA PPU_STATUS
        PLA

        STA PPU_ADDR
        LDA #$00
        STA PPU_ADDR

        PHA

        TXA
        STA H_byte
        TYA
        STA L_byte

        LDX #$00
        LDY #$00
nam_loop:
        LDA ($00), Y
        STA PPU_DATA
        INY
        CPY #$00
        BNE nam_loop
        INC H_byte
        INX
        CPX #$04
        BNE nam_loop
        
; Установка атрибутов бэкграунда
load_attribute:
        LDA PPU_STATUS        ; read PPU status to reset the high/low latch
        PLA

        ADC #$03

        LDA #>ATTRIBUTE_1
        STA PPU_ADDR          ; write the high byte of $23C0 address
        LDA #$C0
        STA PPU_ADDR          ; write the low byte of $23C0 address

        LDX #$00              ; start out at 0

load_attribute_loop:
        LDA attribute, x      ; load data from address (attribute + the value in x)
        STA PPU_DATA          ; write to PPU
        INX                   ; X = X + 1
        CPX #$40              ; Compare X to hex $08, decimal 8 - copying 8 bytes
        BNE load_attribute_loop

        RTS
.endproc

.segment "RODATA"
palettes:
        .byte   $29, $19, $09, $0F              ; Палитра 1
        .byte   $0F, $09, $0A, $29              ; Палитра 2
        .byte   $0F, $11, $0C, $39              ; Палитра 3
        .byte   $0F, $13, $0E, $38              ; Палитра 4
        .byte   $0F, $15, $21, $37              ; Палитра 5
        .byte   $0F, $17, $20, $35              ; Палитра 6
        .byte   $0F, $19, $24, $33              ; Палитра 7
        .byte   $0F, $1B, $25, $32              ; Палитра 8

sprites:
        .byte   $80, $01, $00, $80

attribute:
        .byte %00000000, %00010000, %0010000, %00010000, %00000000, %00000000, %00000000, %00110000

background1:
        .incbin "../data/back1.nam"

background2:
        .incbin "../data/back2.nam"

.segment "CHARS"
        .incbin "../data/tiles.chr"

.segment "BSS"
bgaddr:
        .word   $0000

.segment "STARTUP"