.model small

org 100h
.data
    ; name type initializer
    sum DW 0
    delta DW 02ACh
    v0 DW ?
    v1 DW ?
    k0 DW ?
    k1 DW ?
    k2 DW ?
    k3 DW ?
    msgV DB 'Enter text of 4 letters: $'
    msgK DB 0Dh,0Ah,'Enter password of 4 keys: $'    
    encrypting DB 0Dh,0Ah,'Encrypting... $'
    decrypting DB 0Dh,0Ah,'Decrypting... $' 
    encryptedMsg DB 0Dh,0Ah,'Encrypted text: $'
    decryptedMsg DB 0Dh,0Ah,'Decrypted text again: $' 
        
; DB 8-bit integer
; DW 16-bit integer
; DD 32-bit integer or real
; DQ 64-bit integer or real
; DT 80-bit integer (10 byte)

.code  

main proc  
        
    ; "Enter text of 4 letters: "
    mov ah, 09h      ; write string (from "dx")
    lea dx, msgV     ; lea for LoadEffectiveAddress
    int 21h          ; Dos interrupt "do it" 
    
    ; reading v0
    mov ah, 01h      ; read char (stored in "al")
    int 21h
    mov bh, al
    int 21h
    mov bl, al
    mov v0, bx
    
    ; reading v1
    mov ah, 01h      ; read char (stored in "al")
    int 21h
    mov bh, al
    int 21h
    mov bl, al
    mov v1, bx
         
    ; "Enter password of 4 keys: " 
    mov ah, 09h
    lea dx, msgK 
    int 21h
    
    ; reading k[0] 
    mov ah, 01h
    int 21h
    xor bx, bx
    mov bl, al
    mov k0, bx
    
    ; reading k[1] 
    mov ah, 01h
    int 21h
    xor bx, bx
    mov bl, al
    mov k1, bx
    
    ; reading k[2] 
    mov ah, 01h
    int 21h
    xor bx, bx
    mov bl, al
    mov k2, bx
    
    ; reading k[3] 
    mov ah, 01h
    int 21h
    xor bx, bx
    mov bl, al
    mov k3, bx
    
    ; "Encrypting..."
    mov ah, 09h
    mov dx, offset encrypting
    int 21h 
    
    ; encrypt the text
    call encrypt
      
    ; "Encrypted text: "
    mov ah, 09h
    mov dx, offset encryptedMsg
    int 21h
    
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
    
    ; "Decrypting..."
    mov ah, 09h
    mov dx, offset decrypting
    int 21h
    
    ; decrypt the text
    call decrypt
     
    ; "Decrypted text: "
    mov ah, 09h
    mov dx, offset decryptedMsg
    int 21h    
    
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
    
    ; stop the program
    mov ah, 4ch
    int 21h
    
    endp
    
    
; ============================================== encryption procedure ============================================== ;
    encrypt proc
        
        mov cx, 8       ; counter for "loop" instruction
            
encLoop:      
        ; sum += delta  
        mov bx, delta
        mov ax, sum
        add ax, bx
        mov sum, ax
        
        ; v0 += ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1)    
        ; dx = ((v1<<4) + k0)
        mov ax, v1
        shl ax, 4
        mov bx, k0
        add ax, bx
        mov dx, ax
        ; dx ^= (v1 + sum)
        mov ax, v1
        mov bx, sum
        add ax, bx
        xor dx, ax
        ; dx ^= ((v1>>5) + k1)
        mov ax, v1
        shr ax, 5
        mov bx, k1
        add ax, bx
        xor dx, ax
        ; v0 += dx
        mov ax, v0
        add ax, dx
        mov v0, ax 
        
        ; v1 += ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3)
        ; dx = ((v0<<4) + k2)
        mov ax, v0
        shl ax, 4
        mov bx, k2
        add ax, bx
        mov dx, ax
        ; dx ^= (v0 + sum)
        mov ax, v0
        mov bx, sum
        add ax, bx
        xor dx, ax
        ; dx ^= ((v0>>5) + k3)
        mov ax, v0
        shr ax, 5
        mov bx, k3
        add ax, bx
        xor dx, ax
        ; v1 += dx
        mov ax, v1
        add ax, dx
        mov v1, ax 
                  
loop encLoop          ; "loop" use "cx" as its counter     
        
        ret
    encrypt endp
; ============================================= END of encryption proc ============================================= ;           
                                                                       
                                                                       
                                                                       
                                                                       
; ============================================== decryption procedure ============================================== ;
    decrypt proc
        
        mov cx, 8       ; counter for "loop" instruction
            
decLoop:      
        ; v1 -= ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3)
        ; dx = ((v0<<4) + k2)
        mov ax, v0
        shl ax, 4
        mov bx, k2
        add ax, bx
        mov dx, ax
        ; dx ^= (v0 + sum)
        mov ax, v0
        mov bx, sum
        add ax, bx
        xor dx, ax
        ; dx ^= ((v0>>5) + k3)
        mov ax, v0
        shr ax, 5
        mov bx, k3
        add ax, bx
        xor dx, ax
        ; v1 -= dx
        mov ax, v1
        sub ax, dx
        mov v1, ax
        
        ; v0 -= ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1)    
        ; dx = ((v1<<4) + k0)
        mov ax, v1
        shl ax, 4
        mov bx, k0
        add ax, bx
        mov dx, ax
        ; dx ^= (v1 + sum)
        mov ax, v1
        mov bx, sum
        add ax, bx
        xor dx, ax
        ; dx ^= ((v1>>5) + k1)
        mov ax, v1
        shr ax, 5
        mov bx, k1
        add ax, bx
        xor dx, ax
        ; v0 -= dx
        mov ax, v0
        sub ax, dx
        mov v0, ax 
        
        ; sum -= delta  
        mov bx, delta
        mov ax, sum
        sub ax, bx
        mov sum, ax 
        
loop decLoop          ; "loop" use "cx" as its counter     
        
        ret
    decrypt endp
; ============================================= END of decryption proc ============================================= ;    
    
    
    end