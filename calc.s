%macro startFunc 0
	push ebp
	mov ebp, esp	
	pushad		
%endmacro
%macro endFunc 0
    popad			
	mov esp, ebp	
	pop ebp
%endmacro
section	.rodata			; we define (global) read-only variables in .rodata section
	format_number: db "%s", 10, 0	; format string
	
section .data
    numOp: dd 0 ;number of operations in the program 
    stp: dd 0 ;points to the current location of the stack 
section .bss
    stackOp:resb 20 ; this is the stack of our operands - 4 bytes for each block - 5 blocks  
    buffer:resb 80 ;this is the buffer of the input from the user
    
section .text
  align 16
    global main 
    extern fprintf
    extern printf 
    extern fflush
    extern malloc 
    extern calloc 
    extern free 
    extern fgets
    extern gets
    extern STDIN
main:
    sub esp, 8 ;stack allignment
    call myCalc ;calling the main function 
    add esp, 8
    ; preparing send to the fprintf
    push eax ;return value TODO:CHECK
    push format_number
    call printf
    ;exit system call
    mov eax, 1 ;;SYS_EXIT
    mov ebx, 0 
    mov ecx, 0 
    mov edx, 0
    int 0x80

myCalc:
    startFunc
    ;get input from user
    push buffer
    call gets
    
    mov dword [numOp], 8
    pop eax
    endFunc
    mov eax, buffer
    ret 
    
    
    
# assign2
