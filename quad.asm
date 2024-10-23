.ORG $8000 ; Start from $8000 (ROM)

.define COLOR        #$02
.define BLACK_COLOR  #$00
.define COLOR_ON_RAM $fb
.define CRT          $200

.define TEMP_ACTUAL_POS $00
.define ACTUAL_POS      $fc
.define OLD_POS         $fe

.define MSN        #$f0 ; Most Significant Nibble

.define NMI        $fffa
.define JOYPAD     $4000
.define UP_MASK    #%00000001 
.define DOWN_MASK  #%00000010 
.define LEFT_MASK  #%00000100 
.define RIGHT_MASK #%00001000

; ABI:
;   $00 = Temp actual position
;   $fb = Color
;   $fc[$fd] = Actual position
;   $fe[$ff] = Old position

start:
    LDX COLOR ; COLOR color
    STX COLOR_ON_RAM  ; Write in RAM at $fb address
    STX CRT ; Write in RAM at $200 address   
    LDA COLOR 
    STA $fd ; Load $02 in RAM because by Little Endian: [fc][fd] --> [00][02] --> $0200
    STA $ff ; Seems but for old position offset
    JMP input

up:
    JSR preamble
    SEC ; Set Carry to 1
    SBC #$10
    JSR border_check
    JSR erase 
    JSR confirm_movement_up_down
    SEC 
    SBC #$10
    TAX
    JSR print_color
    JMP input
  
down:
    JSR preamble 
    ADC #$10
    EOR MSN
    JSR border_check 
    JSR erase 
    JSR confirm_movement_up_down 
    ADC #$10
    TAX
    JSR print_color
    JMP input

input_pop: ; Pop 2 bytes
    PLA
    PLA 
input: ; Game Loop
    LDA JOYPAD
    TAX
    AND UP_MASK
    BNE up
    TXA
    AND DOWN_MASK   
    BNE down 
    TXA
    AND LEFT_MASK
    BNE left 
    TXA
    AND RIGHT_MASK  
    BNE right 
    JMP input

left:
    JSR preamble
    DEX
    JSR confirm_movement_left_right
    JSR erase  
    STX OLD_POS
    DEX
    JSR print_color
    JMP input
    
right:
    JSR preamble  
    INX  
    JSR confirm_movement_left_right
    JSR erase 
    STX OLD_POS
    INX
    JSR print_color
    JMP input
    
preamble:
    LDX ACTUAL_POS 
    TXA
    RTS
    
erase:
    LDA BLACK_COLOR
    LDX ACTUAL_POS
    STA CRT, X ; Set Black Color 
    RTS
    
print_color:
    LDA COLOR_ON_RAM
    STA CRT, X ; Write Color in new position
    STX ACTUAL_POS 
    RTS

border_check:
    AND MSN
    CMP MSN
    BEQ input_pop
    RTS

confirm_movement_up_down:
    TXA
    STX OLD_POS 
    RTS

confirm_movement_left_right:  
    STX TEMP_ACTUAL_POS
    EOR TEMP_ACTUAL_POS
    AND MSN
    BNE input_pop
    RTS

nmi:   
    RTI

irq: 
    RTI

.goto NMI
.DW nmi ; NMI
.DW start ; RESET
.DW irq ; IRQ/BRK