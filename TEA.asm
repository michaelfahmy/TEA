.model small
.stack 100h
.data
    ;Title
    t1 db ' ____ _  _ _____ __  __ _____ _____', 10, 13, '$'
    t2 db '((    \\// ||_// ||==|| ||==  ||_//', 10, 13, '$'
    t3 db ' \\__  //  ||    ||  || ||___ || \\', 10, 13, '$'

    ;Opciones de menu
    op1 db ' Cifrar', 10, 13, '$'
    op2 db ' Descifrar', 10, 13, '$'
    op3 db ' Salir', 10, 13, '$'
    chev db '>$'    

    ;Instrucciones de menu
    inst db 10, 13, ' Usar las teclas [W] y [S] para navegar y [espacio] para seleccionar una opcion. ', 10, 13, '$'

    ;variables para manejo archivo
    fileName db 'FILE1',0
    enFileName db 'ENC1',0
    enfHandle dw ?
    fHandle dw ?
    bytesBuffer db ?

    ;variables para encripcion y desencripcion    
    delta DW 9e37h; delta
    sum dw 0
    v0 DW 0; input 1 o Z para el algoritmo
    v1 DW 0; input 2 o Y para el algoritmo
    ;las 4 llaves
    k0 DW 77h
    k1 DW 77h
    k2 DW 77h
    k3 DW 77h
    
    enPrompt db 'Encriptando...', 10, 13, '$'
    dePrompt db 'Desencriptando...', 10, 13, '$'
.code
    mov ax, @data
    mov ds, ax
    main proc
        mov ch, 1; menu position

        .printMenu:
            call newScreen

            lea dx, inst
            mov ah, 9
            int 21h

            cmp ch, 1
            jne .one
            call printChevron
            .one:
            lea dx, op1
            mov ah, 9
            int 21H


            cmp ch, 2
            jne .two
            call printChevron
            .two:
            lea dx, op2
            mov ah, 9
            int 21H
           
            cmp ch, 3
            jne .three
            call printChevron
            .three:
            lea dx, op3
            mov ah, 9
            int 21H

        mov ah,1; Leer linea
        int 21H

        cmp al, 73h
        je .addi

        cmp al, 77h
        je .diff

        cmp al, 20h
        je .select
        jmp .fin

        .diff:
        cmp ch, 1
        je .fin
        dec ch
        jmp .fin

        .addi:
        cmp ch, 3
        je .fin
        inc ch
        
        .fin:
        jmp .printMenu

        .select:
            cmp ch, 3
            je .endm

            cmp ch, 1
            je .cypher
            .decypher:
                call newScreen

                lea dx, dePrompt
                mov ah, 9
                int 21H

                call decOpenFile; open ENC1
                jc .endm;saltar si error
                call decReadFile; read ENC1
                call decCloseFile; close ENC1

                jmp .endm

            .cypher:
                call newScreen
                lea dx, enPrompt
                mov ah, 9
                int 21H

                call openFile; open FILE1
                jc .endm;saltar si error
                call createFile; create ENC1
                call encReadFile; read FILE1 end encrypt
                call closeFile; close FILE
                jmp main
        .endm:
        mov AH,4CH; terminar programa
        int 21H
    main endp

    openFile proc
        mov ah,3DH
        lea dx,fileName
        mov al,0
        int 21H
        mov fHandle,AX      
        ret    
    openFile endp

    encReadFile proc
        mov cx, 5

        .readChar:
            mov ah,3FH
            mov bx,fHandle
            lea dx,bytesBuffer; mover a que punto del buffer leer
            push cx

            mov cx, 1; leer un caracter
            int 21H
            cmp ax,0 ;si no leyo nada, terminar lector
            jz EOFF
            mov dl,bytesBuffer

            pop cx
            dec cx
            cmp cx, 4
            je .bh0
            cmp cx, 3
            je .bl0
            cmp cx, 2
            je .bh1
            cmp cx, 1
            je .bl1         
            cmp cx, 0
            
            .bh0:
                mov bh, dl
                mov bl, 0
                push bx
                jmp .CHR
            .bl0:
                pop bx
                mov bl, dl
                mov v0, bx
                jmp .CHR
            .bh1:
                mov bh, dl
                mov bl, 0
                push bx
                jmp .CHR
            .bl1:
                pop bx
                mov bl, dl
                mov v1, bx

                mov sum, 0
                call encrypt                

                mov ah, 02h
                ; print v0       
                mov bx, v0
                mov dl, bh
                int 21h
                mov dl, bl
                int 21h
                
                ; print v1
                mov bx, v1
                mov dl, bh
                int 21h
                mov dl, bl
                int 21h

                call writeFile
                
                mov cx, 5
                mov bx, 0
        .CHR:;Char repeat
            jmp .readChar; repetir para el siguiente caracter            
    EOFF:
        pop cx

        cmp cx, 4
        je .fill3
        cmp cx, 3
        je .fill2
        cmp cx, 2
        je .fill1
        cmp cx, 5
        je .retu

        .fill1:
            pop bx
            mov bl, 0
            mov v1, bx
            jmp .reprint

        .fill2:
            mov bh, 0
            mov bl, 0
            mov v1, bx
            jmp .reprint

        .fill3:
            pop bx
            mov bl, 0
            mov v0, bx
            mov bh, 0
            mov bl, 0
            mov v1, bx

        .reprint:
            call encrypt

            mov ah, 02h     
            ; print v0       
            mov bx, v0
            mov dl, bh
            int 21h
            mov dl, bl
            int 21h
            
            ; print v1
            mov bx, v1
            mov dl, bh             
            int 21h
            mov dl, bl
            int 21h

            call writeFile

        .retu:
            ret
    encReadFile endp


    decOpenFile proc
        mov ah,3DH
        lea dx,enFileName
        mov al,0
        int 21H
        mov enfHandle,AX      
        ret
    decOpenFile endp

    decReadFile proc
        mov cx, 5        

        .encReadChar:
            mov ah,3FH
            mov bx,enfHandle
            lea dx,bytesBuffer
            
            push cx

            mov cx,1

            int 21H
            cmp ax,0
            jz .retDec
            mov dl,bytesBuffer

            pop cx
            dec cx
            
            cmp cx, 4
            je .ebl0
            cmp cx, 3
            je .ebh0 
            cmp cx, 2
            je .ebl1
            cmp cx, 1
            je .ebh1

            
            .ebl0:
                mov bl, dl
                push bx
                jmp .repDec
            .ebh0:
                pop bx
                mov bh, dl
                mov v0, bx
                jmp .repDec
            .ebl1:
                mov bl, dl
                push bx
                jmp .repDec
            .ebh1:
                pop bx
                mov bh, dl
                mov v1, bx

                mov sum, 0F1B8h
                call decrypt                

                mov ah, 02h     
                ; print v0
                mov bx, v0
                mov dl, bh
                int 21h
                mov dl, bl
                int 21h

                ; print v1
                mov bx, v1
                mov dl, bh             
                int 21h
                mov dl, bl
                int 21h

                mov cx, 5
        .repDec:
            jmp .encReadChar
        .retDec:
            pop cx
            ret
    decReadFile endp

    closeFile proc
        mov ah,3EH        
        mov bx,fHandle     
        int 21H
        ret
    closeFile endp
    
    decCloseFile proc
        mov ah,3EH        
        mov bx,enfHandle     
        int 21H
        ret
    decCloseFile endp

    createFile proc
        mov ah, 3CH
        mov cx, 007fh
        lea dx, enFileName

        int 21H
        mov enfHandle, ax
        ret
    createFile endp

    writeFile proc
        mov ah, 40h
        mov bx, enfHandle
        lea dx, v0
        mov cx, 2
        int 21H
        mov ah, 40h
        lea dx, v1
        int 21h
        ret
    writeFile endp

    encrypt proc
        mov cx, 8
        
        encLoop:
            mov bx, delta
            mov ax, sum
            add ax, bx
            mov sum, ax
            
            mov ax, v1

            call shiftLeft4

            mov bx, k0
            add ax, bx
            mov dx, ax
            mov ax, v1
            mov bx, sum
            add ax, bx
            xor dx, ax
            mov ax, v1
            call shiftRight5
            mov bx, k1
            add ax, bx
            xor dx, ax

            mov ax, v0
            add ax, dx
            mov v0, ax 
                        
            mov ax, v0
            call shiftLeft4
            mov bx, k2
            add ax, bx
            mov dx, ax

            mov ax, v0
            mov bx, sum
            add ax, bx
            xor dx, ax

            mov ax, v0
            call shiftRight5
            mov bx, k3
            add ax, bx
            xor dx, ax
            
            mov ax, v1
            add ax, dx
            mov v1, ax
        loop encLoop
        ret
    encrypt endp

    decrypt proc
        mov cx, 8
        
        decLoop:
            mov ax, v0
            call shiftLeft4
            mov bx, k2
            add ax, bx
            mov dx, ax
            
            mov ax, v0
            mov bx, sum
            add ax, bx
            xor dx, ax
            
            mov ax, v0
            call shiftRight5
            mov bx, k3
            add ax, bx
            xor dx, ax
            
            mov ax, v1
            sub ax, dx
            mov v1, ax
                        
            mov ax, v1
            call shiftLeft4
            mov bx, k0
            add ax, bx
            mov dx, ax
            
            mov ax, v1
            mov bx, sum
            add ax, bx
            xor dx, ax
            
            mov ax, v1
            call shiftRight5
            mov bx, k1
            add ax, bx
            xor dx, ax
            
            mov ax, v0
            sub ax, dx
            mov v0, ax 
            
            
            mov bx, delta
            mov ax, sum
            sub ax, bx
            mov sum, ax 
        
        loop decLoop
        ret
    decrypt endp
    
    ;shr ax, 5
    shiftRight5 proc
        shr ax, 1
        shr ax, 1
        shr ax, 1
        shr ax, 1
        shr ax, 1
        ret
    shiftRight5 endp

    ;shr ax, 4
    shiftLeft4 proc
        shl ax, 1
        shl ax, 1
        shl ax, 1
        shl ax, 1
        ret
    shiftLeft4 endp

    ;shr ax, 4
    shiftRight4 proc
        shr ax, 1
        shr ax, 1
        shr ax, 1
        shr ax, 1
        ret
    shiftRight4 endp

    ;shl ax, 5
    shiftLeft5 proc
        shl ax, 1
        shl ax, 1
        shl ax, 1
        shl ax, 1
        shl ax, 1
        ret
    shiftLeft5 endp

    newScreen proc
        mov ax, 03h; limpiar pantalla
        int 10h

        lea dx, t1; imprimir titulo
        mov ah, 9
        int 21H
        lea dx, t2
        mov ah, 9
        int 21H
        lea dx, t3
        mov ah, 9
        int 21H

        ret
    newScreen endp

    encToFile proc

    encToFile endp

    printChevron proc
        lea dx, chev; Imprimir >
        mov ah, 9
        int 21H

        ret
    printChevron endp    
END
