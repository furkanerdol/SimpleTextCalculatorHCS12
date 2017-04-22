;*****************************************************************
;* This stationery serves as the framework for a                 *
;* user application (single file, absolute assembly application) *
;* For a more comprehensive program that                         *
;* demonstrates the more advanced functionality of this          *
;* processor, please see the demonstration applications          *
;* located in the examples subdirectory of the                   *
;* Freescale CodeWarrior for the HC12 Program directory          *
;*****************************************************************

;Furkan Erdol 131044065

; export symbols
            XDEF Entry, _Startup            ; export 'Entry' symbol
            ABSENTRY Entry        ; for absolute assembly: mark this as application entry point



; Include derivative-specific definitions 
		INCLUDE 'derivative.inc' 

ROMStart    EQU  $4000  ; absolute address to place my code/constant data

; variable/data section

            ORG $1200
            
text FCC "28.33 + 17.28 ="  ;calculated text

            
            ORG $1300     ;necessary variables

operator        DC.B $2B  ;operator plus or minus (default plus)

firstNumber     DC.B 0    ;first number's int part
firstNumberDec  DC.B 0    ;first number's decimal part

secondNumber    DC.B 0    ;second number's int part
secondNumberDec DC.B 0    ;second number's decimal part

tempCounter     DC.B 0    ;counter for int part's number of digits

numberOfDigits  DC.B 0    ;number of digits
numberOfDigits2 DC.B 0    ;number of digits

processCounter  DC.B 0    ;for process subroutine (expresess number of part)

            ORG $1350

digits          DC.B 0    ;for calculate numbers        


; code section
            ORG   ROMStart


Entry:
_Startup:          
            LDX #text

MainLoop:             
            
            LDAA 0,X
            
            LDAB #$2E         ;point character
            CBA
            BEQ Point
            
            LDAB #$2B         ;plus character
            CBA
            BEQ Plus
            
            LDAB #$2D         ;minus character
            CBA
            BEQ Minus
            
            LDAB #$20         ;space character
            CBA
            BEQ Space
            
            LDAB #$3D         ;assign character
            CBA
            BEQ Assign
            
            LDAB X
            SUBB #$30         ;calculate digit value
            STAB Y            ;add digit
            
            INC numberOfDigits
            INC numberOfDigits2
            
            INY               ;increment digit pointer
            
Continue:   INX               ;increment text pointer
            
            BRA MainLoop
                      

          
                    
Plus:       STAB operator     ;plus operator
            JSR Process       ;call process subroutine
            
            LDAA #2           ;if necessary first number doesn't have decimal part
            STAA processCounter   
            JMP Continue


Minus:      STAB operator     ;minus operator
            JSR Process       ;call process subroutine
            
            LDAA #2           ;if necessary first number doesn't have decimal part
            STAA processCounter
            JMP Continue


Space:      BRA Continue      ;ignore whitespace character


Point:      JSR Process       ;call process subroutine
            JMP Continue



Assign:     JSR Process       ;call process subroutine

            LDAB #$FF         
            STAB DDRB
            LDAB #$55
            STAB PORTB

            LDAA operator     ;load operator
            CMPA #$2B         ;if operator is plus
            BNE IsMinus       ;else
            JSR Add           ;call add subroutine
            
  IsMinus:  LDAA operator     ;load operator
            CMPA #$2D         ;if operator is minus
            BNE Result        ;else
            JSR Substract     ;call substract subroutine
            
   Result:  JMP Finish 
          
          
Add:        LDAA firstNumberDec   
            LDAB secondNumberDec            
            ABA                   ;first decimal + second decimal
            CMPA #100
            BMI GoAdd             ;if decimal part have two digit
                                  ;else (decimal part have a digit)
            SUBA #100             
            STAA $1501            ;store decimal part 
            
            LDAA firstNumber
            INCA
            
            LDAB secondNumber            
            ABA                   ;first integer + second integer
            
            BCC NotOver
            LDAB #$FF
            STAB PORTB
          
            
 NotOver:   STAA $1500            ;store integer part 

            RTS
             
   GoAdd:   STAA $1501            ;store decimal part 

            LDAA firstNumber
            LDAB secondNumber            
            ABA
            
            BCC NotOver2
            LDAB #$FF
            STAB PORTB
          
            
NotOver2:   STAA $1500            ;store integer part

            RTS



Substract:  LDAA firstNumberDec
            LDAB secondNumberDec            
            SBA                     ;first decimal - second decimal

            BPL GoSub               ;if decimal part have two digit
                                    ;else (decimal part have a digit)
            ADDA #100            
            STAA $1501              ;store decimal part
            
            LDAA firstNumber
            DECA
            
            LDAB secondNumber            
            SBA                     ;first integer - second integer
            
            LDAB firstNumber
            CMPB secondNumber
            BHS NotOver3
            LDAB #$FF
            STAB PORTB
            
 NotOver3:  STAA $1500              ;store integer part    

            RTS           
  
   GoSub:   STAA $1501              ;store decimal part            
          
            LDAA firstNumber
            LDAB secondNumber            
            SBA
            
            LDAB firstNumber
            CMPB secondNumber
            BHS NotOver4
            LDAB #$FF
            STAB PORTB
            
 NotOver4:  STAA $1500              ;store integer part

            RTS




Process:    LDAA #1
            STAA tempCounter
            
     Loop:  LDAA tempCounter
            DEY
            CLRB
 Multiply:  ADDB Y                    ;calculate number value
            DECA
            BNE Multiply
            
            STAB Y
            
            
            LDAA #10
            CLRB
  Counter:  ADDB tempCounter          ;new counter calculate (1-10-100...)
            DECA
            BNE Counter
            
            STAB tempCounter
            
            DEC numberOfDigits
            BNE Loop
            
            CLRA
Calculate:  ADDA Y
            INY
            DEC numberOfDigits2                
            BNE Calculate
            
            LDAB processCounter
            
    First:  CMPB #0                  ;first integer part
            BNE FirstDec
            STAA firstNumber 
            
 FirstDec:  CMPB #1                  ;first decimal part
            BNE Second
            STAA firstNumberDec
            CMPA #10
            BHS Second
            LDAB #10
            DEY 
            CLRA
      Inc:  ADDA Y
            DECB
            BNE Inc     
            
            STAA firstNumberDec
            
   Second:  CMPB #2                   ;second integer part
            BNE SecondDec
            STAA secondNumber
            
SecondDec:  CMPB #3                   ;second decimal part
            BNE EndProcess
            STAA secondNumberDec
            
            CMPA #10
            BHS EndProcess
            LDAB #10
            DEY 
            CLRA
      Dec:  ADDA Y
            DECB
            BNE Dec                
            STAA secondNumberDec

EndProcess: INC processCounter
            LDY #digits
            
            RTS


Finish:                                   

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************
            ORG   $FFFE
            DC.W  Entry           ; Reset Vector