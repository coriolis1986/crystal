.include "nesdefs.inc"

.segment "ZEROPAGE"
scroll:         .res 1
ppuctrl_value:  .res 1
.exportzp ppuctrl_value, scroll

.segment "CODE"

.import main
.import draw_person
.import move_person
.import draw_background

.proc irq_handler
        RTI
.endproc

.proc nmi_handler
        LDA #$00
        STA OAM_ADDR
        LDA #$02
        STA OAM_DMA

        JSR move_person
        JSR draw_person

        ; Скроллинг всегда задается в конце обработчика прерывания
        ; иначе другие операции записи в PPU могут повлиять на значения смещения скроллинга
        LDA scroll
        CMP #$00
        BNE do_scrolling

        LDA ppuctrl_value
        EOR #CTRL_NT_2800
        STA ppuctrl_value
        STA PPU_CTRL
        LDA #240
        STA scroll

do_scrolling:
        LDA #$00
        STA PPU_SCROLL

        DEC scroll
        LDA scroll
        STA PPU_SCROLL

        RTI
.endproc

.proc reset_handler
        SEI
        CLD
        LDX #$00
        STX PPU_CTRL
        STX PPU_MASK
vblankwait:
        BIT PPU_STATUS
        BPL vblankwait

;Clear RAM
        LDA #$00
        LDX #$00
clear_loop:
        STA $0000, X
        STA $0100, X
        STA $0200, X
        STA $0300, X
        STA $0400, X
        STA $0500, X
        STA $0600, X
        STA $0700, X
        INX
        CPX #$00
        BNE clear_loop

        JMP main
.endproc

.segment "VECTORS"
.addr nmi_handler, reset_handler, irq_handler
