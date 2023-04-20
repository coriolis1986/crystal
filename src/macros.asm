.macro  RESET_PPU_ADDR
        LDX PPU_STATUS
.endmacro

.macro  SET_PPU_ADDR    hi, lo
        LDX hi
        STX PPU_ADDR
        LDX lo
        STX PPU_ADDR
.endmacro

.macro SUBROUTINE_START
        PHP
        PHA
        TXA
        PHA
        TYA
        PHA
.endmacro

.macro SUBROUTINE_END
        PLA
        TAY
        PLA
        TXA
        PLA
        PLP
        RTS
.endmacro
