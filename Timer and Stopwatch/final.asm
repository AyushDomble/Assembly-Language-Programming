.MODEL SMALL
.STACK 100H

.DATA
    menu_msg             DB 'TIMER & STOPWATCH', '$'
    timer_option_msg     DB '[1] TIMER', '$'
    stopwatch_option_msg DB '[2] STOPWATCH', '$'
    timer_msg            DB 'Set time in seconds: $'
    stopwatch_start_msg  DB 'Press any key to start the stopwatch...$'
    stopwatch_stop_msg   DB 'Press any key to stop the stopwatch...$'
    stopped_msg          DB 'Stopwatch stopped. Time elapsed: $'
    time_up_msg          DB 'Time Up!$'
    msg2                 DB 'Time remaining: $'
    output_text          DB '00 seconds$'
    newline              DB 0DH, 0AH, '$'
    buffer               DB 5, ?, '00000'
    timeValue            DW ?

.CODE
MAIN PROC
                          MOV   AX, @DATA
                          MOV   DS, AX

    ; Set 320x200 graphics mode
                          MOV   AH, 00H
                          MOV   AL, 13H
                          INT   10H

                          CALL  DRAW_MAIN_MENU
                          CALL  SHOW_LIVE_CLOCK                ; ⏰ Show clock while waiting for user input

    ; Now read the key (already pressed)
                          MOV   AH, 00H
                          INT   16H
                          SUB   AL, '0'
                          CMP   AL, 1
                          JE    TIMER_MODE
                          CMP   AL, 2
                          JE    STOPWATCH_MODE
                          JMP   EXIT

    TIMER_MODE:           
                          CALL  DRAW_TIMER_SCREEN
                          MOV   BL, 0AH
                          LEA   DX, timer_msg
                          CALL  PRINT_GRAPHICS_TEXT
                          CALL  PRINT_NEWLINE
                          CALL  PRINT_NEWLINE

    ; Read input
                          MOV   DX, OFFSET buffer
                          MOV   AH, 0AH
                          INT   21H
                          CALL  ASCII_TO_INT
                          MOV   timeValue, AX

    COUNTDOWN_LOOP:       
                          CMP   timeValue, 0
                          JLE   TIME_UP

                          MOV   BL, 0BH
                          LEA   DX, msg2
                          CALL  PRINT_GRAPHICS_TEXT
                          CALL  PRINT_NEWLINE

                          MOV   AX, timeValue
                          CALL  INT_TO_ASCII

                          MOV   BL, 0CH
                          LEA   DX, output_text
                          CALL  PRINT_GRAPHICS_TEXT
                          CALL  PRINT_NEWLINE
                          CALL  PRINT_NEWLINE

                          MOV   CX, 1500
                          CALL  PLAY_TONE

                          CALL  DELAY_1_SECOND
                          DEC   timeValue
                          JMP   COUNTDOWN_LOOP

    TIME_UP:              
                          MOV   BL, 0Eh
                          LEA   DX, time_up_msg
                          CALL  PRINT_GRAPHICS_TEXT
                          CALL  PRINT_NEWLINE
                          CALL  PRINT_NEWLINE

                          MOV   CX, 1000
                          CALL  PLAY_TONE
                          JMP   EXIT
    STOPWATCH_MODE:       
                          CALL  DRAW_STOPWATCH_SCREEN

                          LEA   DX, stopwatch_start_msg
                          MOV   AH, 09H
                          INT   21H
                          CALL  PRINT_NEWLINE
                          CALL  PRINT_NEWLINE

                          MOV   AH, 00H
                          INT   16H

                          MOV   AH, 2CH
                          INT   21H
                          MOV   BH, DH

                          LEA   DX, stopwatch_stop_msg
                          MOV   AH, 09H
                          INT   21H
                          CALL  PRINT_NEWLINE
                          CALL  PRINT_NEWLINE

                          MOV   AH, 00H
                          INT   16H

                          MOV   AH, 2CH
                          INT   21H
                          MOV   BL, DH

                          SUB   BL, BH
                          JNS   NO_WRAP
                          ADD   BL, 60

    NO_WRAP:              
                     XOR   AX, AX
MOV   AL, BL
CALL  INT_TO_ASCII_SECONDS   ; new procedure to format with "xx seconds"


    ; Display result
                          MOV   AH, 09H
                          LEA   DX, stopped_msg
                          INT   21H
                          LEA   DX, output_text
                          INT   21H
                          CALL  PRINT_NEWLINE
                          CALL  PRINT_NEWLINE

    ; 🎵 Success chime
                          MOV   CX, 1000
                          CALL  PLAY_TONE
                          MOV   CX, 5000
                          CALL  PLAY_TONE
                          MOV   CX, 5000
                          CALL  PLAY_TONE
                          MOV   CX, 5000
                          CALL  PLAY_TONE
                          MOV   CX, 5000
                          CALL  PLAY_TONE
                          MOV   CX, 5000
                          CALL  PLAY_TONE
                          MOV   CX, 1000
                          CALL  PLAY_TONE
    EXIT:                 
                          MOV   AH, 4CH
                          INT   21H
MAIN ENDP

    ; ---------------------- SOUND ROUTINE ----------------------

PLAY_TONE PROC
                          PUSH  AX
                          PUSH  BX
                          PUSH  DX

                          MOV   DX, 18H
                          MOV   AX, 34CCh
                          DIV   CX
                          MOV   BX, AX

                          MOV   AL, 0B6H
                          OUT   43H, AL

                          MOV   AL, BL
                          OUT   42H, AL
                          MOV   AL, BH
                          OUT   42H, AL

                          IN    AL, 61H
                          OR    AL, 03H
                          OUT   61H, AL

                          MOV   CX, 10000
    DELAY_LOOP:           
                          NOP
                          LOOP  DELAY_LOOP

                          IN    AL, 61H
                          AND   AL, 0FCH
                          OUT   61H, AL

                          POP   DX
                          POP   BX
                          POP   AX
                          RET
PLAY_TONE ENDP

    ; -------------------- CLOCK ROUTINES --------------------

SHOW_LIVE_CLOCK PROC
    CLOCK_LOOP:           
                          CALL  GET_CURRENT_TIME
                          CALL  DISPLAY_CLOCK

                          MOV   AH, 01H
                          INT   16H
                          JNZ   EXIT_CLOCK

                          MOV   CX, 1000
    WAIT_LOOP:            
                          NOP
                          LOOP  WAIT_LOOP
                          JMP   CLOCK_LOOP

    EXIT_CLOCK:           
                          RET
SHOW_LIVE_CLOCK ENDP

GET_CURRENT_TIME PROC
                          MOV   AH, 02H
                          INT   1AH

                          MOV   AL, CH
                          CALL  BCD_TO_ASCII
                          MOV   output_text, AH
                          MOV   output_text+1, AL

                          MOV   output_text+2, ':'

                          MOV   AL, CL
                          CALL  BCD_TO_ASCII
                          MOV   output_text+3, AH
                          MOV   output_text+4, AL

                          MOV   output_text+5, ':'

                          MOV   AL, DH
                          CALL  BCD_TO_ASCII
                          MOV   output_text+6, AH
                          MOV   output_text+7, AL

                          MOV   BYTE PTR output_text+8, '$'
                          RET
GET_CURRENT_TIME ENDP

BCD_TO_ASCII PROC
                          MOV   AH, AL
                          AND   AH, 0F0H
                          SHR   AH, 4
                          ADD   AH, '0'

                          AND   AL, 0FH
                          ADD   AL, '0'
                          RET
BCD_TO_ASCII ENDP

DISPLAY_CLOCK PROC
                          MOV   DH, 0
                          MOV   DL, 68
                          MOV   BH, 0
                          CALL  SET_CURSOR

                          MOV   BL, 0CH
                          LEA   DX, output_text
                          CALL  PRINT_GRAPHICS_TEXT
                          RET
DISPLAY_CLOCK ENDP

    ; -------------------- GRAPHICS AND UI --------------------

DRAW_MAIN_MENU PROC
                          MOV   AX, 0600H
                          MOV   BH, 00H
                          MOV   CX, 0
                          MOV   DX, 184FH
                          INT   10H

                          MOV   DH, 5
                          MOV   DL, 10
                          MOV   BH, 0
                          CALL  SET_CURSOR
                          MOV   BL, 0BH
                          LEA   DX, menu_msg
                          CALL  PRINT_GRAPHICS_TEXT
                          CALL  PRINT_NEWLINE

                          MOV   DH, 8
                          MOV   DL, 12
                          CALL  SET_CURSOR
                          MOV   BL, 0AH
                          LEA   DX, timer_option_msg
                          CALL  PRINT_GRAPHICS_TEXT
                          CALL  PRINT_NEWLINE

                          MOV   DH, 10
                          MOV   DL, 12
                          CALL  SET_CURSOR
                          MOV   BL, 0Eh
                          LEA   DX, stopwatch_option_msg
                          CALL  PRINT_GRAPHICS_TEXT
                          CALL  PRINT_NEWLINE
                          RET
DRAW_MAIN_MENU ENDP

DRAW_TIMER_SCREEN PROC
                          MOV   AX, 0600H
                          MOV   BH, 00H
                          MOV   CX, 0
                          MOV   DX, 184FH
                          INT   10H
                          MOV   DH, 4
                          MOV   DL, 8
                          CALL  SET_CURSOR
                          MOV   BL, 0AH
                          RET
DRAW_TIMER_SCREEN ENDP

DRAW_STOPWATCH_SCREEN PROC
                          MOV   AX, 0600H
                          MOV   BH, 00H
                          MOV   CX, 0
                          MOV   DX, 184FH
                          INT   10H
                          MOV   DH, 4
                          MOV   DL, 6
                          CALL  SET_CURSOR
                          MOV   BL, 0FH
                          RET
DRAW_STOPWATCH_SCREEN ENDP

    ; -------------------- UTILITIES --------------------

PRINT_GRAPHICS_TEXT PROC
                          MOV   SI, DX
    PRINT_LOOP:           
                          LODSB
                          CMP   AL, '$'
                          JE    PRINT_DONE
                          MOV   AH, 0EH
                          MOV   BH, 00H
                          INT   10H
                          JMP   PRINT_LOOP
    PRINT_DONE:           
                          MOV   AH, 0EH
                          MOV   AL, 0DH
                          INT   10H
                          MOV   AL, 0AH
                          INT   10H
                          RET
PRINT_GRAPHICS_TEXT ENDP

PRINT_NEWLINE PROC
                          MOV   AH, 0EH
                          MOV   AL, 0DH
                          INT   10H
                          MOV   AL, 0AH
                          INT   10H
                          RET
PRINT_NEWLINE ENDP

SET_CURSOR PROC
                          MOV   AH, 02H
                          INT   10H
                          RET
SET_CURSOR ENDP

ASCII_TO_INT PROC
                          MOV   SI, OFFSET buffer + 2
                          XOR   AX, AX
                          MOV   CX, 0
    ASCII_LOOP:           
                          MOV   BL, [SI]
                          CMP   BL, 0DH
                          JE    ASCII_DONE
                          SUB   BL, '0'
                          MOV   DX, 10
                          IMUL  DX
                          ADD   AX, BX
                          INC   SI
                          JMP   ASCII_LOOP
    ASCII_DONE:           
                          RET
ASCII_TO_INT ENDP

INT_TO_ASCII PROC
                          MOV   SI, OFFSET output_text
                          MOV   CX, 0
                          MOV   BX, 10
    CONVERT_LOOP:         
                          XOR   DX, DX
                          DIV   BX
                          ADD   DL, '0'
                          PUSH  DX
                          INC   CX
                          CMP   AX, 0
                          JNE   CONVERT_LOOP
    REVERSE_OUTPUT:       
                          POP   DX
                          MOV   [SI], DL
                          INC   SI
                          LOOP  REVERSE_OUTPUT
                          MOV   BYTE PTR [SI], ' '
                          MOV   BYTE PTR [SI+1], 's'
                          MOV   BYTE PTR [SI+2], 'e'
                          MOV   BYTE PTR [SI+3], 'c'
                          MOV   BYTE PTR [SI+4], 'o'
                          MOV   BYTE PTR [SI+5], 'n'
                          MOV   BYTE PTR [SI+6], 'd'
                          MOV   BYTE PTR [SI+7], 's'
                          MOV   BYTE PTR [SI+8], '$'
                          RET
INT_TO_ASCII ENDP


INT_TO_ASCII_SECONDS PROC
    MOV   SI, OFFSET output_text
    MOV   CX, 0
    MOV   BX, 10
SW_CONVERT_LOOP:
    XOR   DX, DX
    DIV   BX
    ADD   DL, '0'
    PUSH  DX
    INC   CX
    CMP   AX, 0
    JNE   CONVERT_LOOP

SW_REVERSE_OUTPUT:
    POP   DX
    MOV   [SI], DL
    INC   SI
    LOOP  REVERSE_OUTPUT

    MOV   BYTE PTR [SI], ' '
    MOV   BYTE PTR [SI+1], 's'
    MOV   BYTE PTR [SI+2], 'e'
    MOV   BYTE PTR [SI+3], 'c'
    MOV   BYTE PTR [SI+4], 'o'
    MOV   BYTE PTR [SI+5], 'n'
    MOV   BYTE PTR [SI+6], 'd'
    MOV   BYTE PTR [SI+7], 's'
    MOV   BYTE PTR [SI+8], '$'
    RET
INT_TO_ASCII_SECONDS ENDP


DELAY_1_SECOND PROC
                          MOV   CX, 22
    OUTER:                
                          MOV   DX, 0FFFFH
    INNER:                
                          DEC   DX
                          JNZ   INNER
                          LOOP  OUTER
                          RET
DELAY_1_SECOND ENDP

END MAIN