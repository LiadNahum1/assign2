%macro startFunc 0
	push ebp
	mov ebp, esp	
	;pushad		
%endmacro

%macro endFunc 0
    ;popad			
	mov esp, ebp	
	pop ebp
%endmacro

%macro getAddress 1
    mov eax, [stp]
    mov ebx, [stackOp + eax*4] ;ebx is the address of the operand on the top of the stack
    mov dword [%1], ebx 
%endmacro

%macro free_node 1
    push %1
    call free 
    add esp, 4
%endmacro 

%macro next_node 1
    inc dword [%1] ;next byte of the element 
    mov ebx, [%1] ;save the next adrress
    mov ebx, [ebx] ;address of the next node 
    mov [%1], ebx ;move it back to the element
%endmacro 

%macro save_carry_mac 0
    jc %%car ;if the addition created carry
    mov byte [carry], 0 ;if not zero carry saver
    jmp %%after_car
    %%car:
    mov byte [carry], 1 ;else make it 1 and contionu with your code
    %%after_car:
%endmacro


;add rest number and free the mallocs
%macro add_rest_number 1
    push dword [bytes_to_malloc]  
    call malloc ; eax is the pointer that malloc returns 
    add esp, 4 
    mov ebx, [put] ;ebx hold the adrress of the last 4 bytes of the last node
    mov [ebx] , eax ;push pointer to first digit of the number into the stack operand 
    
    mov edx, 0
    mov ebx, [%1]
    mov byte dl, [ebx]
    add byte dl, [carry]
    mov byte [carry],0
    mov byte [eax], dl ;the first cell's value is the data (the sum)
    inc eax ;the address of 4 bytes of the pointer 
    mov [put], eax 
    
    mov eax, [%1]
    next_node %1
    free_node eax
%endmacro

section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string
    format_hex:  db "%X", 0
    format_hex_with_zero:  db "%02X", 0
	
section .data
    numOp: dd 0 ;number of operations in the program 
    Insufficient_string: db 'Error: Insufficient Number of Arguments on Stack'
    stp: dd 0 ;points to the first free location in the stack 
    calc_string: db 'calc:'
    empty_string: db ''
    bytes_to_malloc: dd 5
    over_flow_string: db 'Error: Operand Stack Overflow'
    
    index: dd 0 ;index in buffer_hex 
    carry: db 0 ;byte of the carry
    first_element: dd 0
    second_element: dd 0
    first_digit_not_zero: dd 0
    put: dd 0 ;the next address to put in a new pointer (for creating the numbers)
section .bss
    stackOp:resb 20 ; this is the stack of our operands - 4 bytes for each block - 5 blocks  
    buffer:resb 80 ;this is the buffer of the input from the user
    buffer_hex: resb 40 ;2 characters are one byte in hex 

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
    ;push dword [buffer_hex] ;return value TODO:CHECK
    ;mov ebx, [stackOp]
    ;push dword [ebx]
    ;push format_string 
    ;call printf
    ;exit system call
    mov eax, 1 ;;SYS_EXIT
    mov ebx, 0 
    mov ecx, 0 
    mov edx, 0
    int 0x80

myCalc:
    startFunc  
start_loop:
    mov ecx, 0
    jmp initialize_buffer
con:
    push calc_string
    push format_string
    call printf 
    add dword esp, 8 ;pop printf arguments 
    push buffer  ;get input from user  
    call gets
    add dword esp, 4 ;pop gets argument 
    cmp byte [buffer], 'q'
    jz end_func
    inc dword [numOp]   ;count num of operations 
    cmp byte [buffer], '+'
    jz addition 
%macro addEAX10 0	 ; if ZF == 0, add 10 to EAX
	     jnz %%skip
	     add eax, 10
    %%skip:
%endmacro
    cmp byte [buffer], 'p'
    jz pop_print
    cmp byte [buffer], 'd'
    jz duplicate
    cmp byte [buffer], '^'
    jz pos_power
    cmp byte [buffer], 'v'
    jz neg_power
    cmp byte [buffer], 'n'
    jz n1bits
    cmp byte [buffer], 's'
    jz square_root 
    jmp push_number 
end_func:
    endFunc
    ret 
initialize_buffer:
    cmp ecx, 80
    jz con
    mov dword [buffer + ecx], 0
    inc ecx
    jmp initialize_buffer
push_number:
    cmp dword [stp], 6
    jz overflow_error ; if stack is full print error
    dec dword [numOp] ;;number is not operation
    mov ecx, 0; start counter to convertion action
    mov dword [index],0 ;restart index counter
    jmp delete_zero
start_push:
    mov ecx, 0
count_number: ; check the number length to start adding from the end
    cmp byte [buffer_hex + ecx], 'q' ;end of buufer number
    jz create_loop_first ;if number ended start createing
    inc ecx ;count++
    jmp count_number
create_loop_first: ;difinge put as the address in the stack
    mov eax, [stp]
    mov dword [put], stackOp
    mov ebx, 4
    mul ebx ;stp*4 will be in eax
    add [put], eax ;[put] - is stckOP + stp*4 
create_loop_next:
    dec ecx ;so it will be rhe place on the buffer 
    cmp ecx, 0
    jl last_digit
    push ecx
    push dword [bytes_to_malloc] ;TODO CHECK IF RIGHT 
    call malloc ; eax is the pointer that malloc returns 
    add esp, 4 
    pop ecx 
    mov ebx, [put] ;stackop adrress
    mov [ebx] , eax ;push pointer to first digit of the number into the stack operand 
    mov byte bl , [buffer_hex + ecx] ; ebx is the digit
    mov byte [eax], bl  ;the first cell's value is the data (digit)  
    inc eax ;the address of 4 bytes of the pointer 
    mov [put], eax 
    jmp create_loop_next
last_digit: ;
   mov ebx, [put]
   mov dword [ebx], 0;last pointer to the zero byte 
   inc dword [stp]; increse the number of numbers in the stack
   jmp start_loop  

addition:
    cmp dword [stp], 2
    jl insufficient_error ;there is not enough element in the satck 
    dec dword [stp] ;now will point on the top number
    getAddress first_element
    dec dword [stp]
    getAddress second_element

    ;next lines will preper were to put the argumant we create
    mov eax, [stp]
    mov dword [put], stackOp
    mov ebx, 4
    mul ebx ;stp*4 will be in eax
    add [put], eax ;[put] - is stckOP + stp*4
    ;inc dword [stp] ;the result of the addition will be pushed into the stack TODO: no need because last digit is already do that 
    
addition_loop: ;the addition calc is in edx -dl TODO
    cmp dword [first_element], 0 
    jz add_rest_second
    cmp dword [second_element], 0
    jz add_rest_first
    push dword [bytes_to_malloc]  
    call malloc ; eax is the pointer that malloc returns 
    add esp, 4 

    mov ebx, [put] 
    mov [ebx] , eax ;push pointer to first digit of the number into the stack operand 
    push dword [second_element]
    push dword [first_element]
    call make_addition ;add to bytes save the result in dl and save carry if there is 
    add esp, 8
    mov byte [eax], dl ;the first cell's value is the data (the sum)
    inc eax ;the address of 4 bytes of the pointer 
    mov [put], eax
    
    ;move forward to the next byte in each element 
    mov eax, [first_element]
    next_node first_element
    free_node eax ;free node we already calculate 
    
    mov eax, [second_element]
    next_node second_element
    free_node eax ;free node we already calculate 
    jmp addition_loop

    
add_rest_second:
    cmp dword [second_element], 0 
    jz check_carry
    add_rest_number second_element
    jmp add_rest_second
    
add_rest_first:
    cmp dword [first_element], 0 
    jz check_carry
    add_rest_number first_element
    jmp add_rest_first

check_carry:
    cmp byte [carry], 1 ;if there is a carry after we add all bytes between the two numbers 
    jz add_carry_node
    jmp last_digit
add_carry_node:
    push dword [bytes_to_malloc]  
    call malloc ; eax is the pointer that malloc returns 
    add esp, 4 
    mov ebx, [put] 
    mov [ebx] , eax ;push pointer to first digit of the number into the stack operand 
    mov byte  dl, 1
    mov byte [eax], dl ;the first cell's value is the data (the sum)
    inc eax ;the address of 4 bytes of the pointer 
    mov [put], eax
    jmp last_digit 
    
;Function 
make_addition: ;add two bytes the result is in dl 
    
    startFunc
    mov ebx, [ebp + 8] ;ebx is the address of the first element
    mov dword edx, 0 ;initialize to 0 in order to get the number
    mov byte dl, [ebx] ;taking the first byte in this address = the number itself 
    mov ebx, [ebp + 12]
    add byte dl, [ebx] ;the sum of the first two elements 
    jc save_carry
    mov byte [carry], 0
    add byte dl, [carry] ;add carry 
    jc save_carry ;we wiil save the carry of this action if ecsist
    mov byte [carry], 0
    jmp end_make_addition
save_carry:
    mov byte [carry], 1 
end_make_addition: 
    endFunc
    ret
  
    
pop_print: ;TODO FREE ;TODO check the printing when bytes are not the last and lower than F 
    cmp dword [stp], 0
    jz insufficient_error  ;there is no element in the satck 
    dec dword [stp] ;so it will point to the place of the last emlement
    mov eax, [stp]
    mov ebx, [stackOp + eax*4] ;ebx is the address of the operand on the top of the stack
    call print_num
    jmp next_line 
print_num:
    mov dword edx, 0 ;initialize to 0 in order to get the number
    mov byte dl, [ebx] ;taking the first byte in this address 
    inc ebx  ;the address of the start of the address of the next node
    mov ebx, [ebx] ;the address of the next node
    cmp ebx, 0 
    jz no_need 
    push edx
    call print_num 
    pop edx
    jnz check_if_needed_patching 
print:
check_if_needed_patching: ;check if we need to patch the printing with zero - not the last digit 
    cmp dl, 0xf
    ja no_need
    jmp need 
no_need:
    push edx
    push format_hex 
    call printf
    add esp, 8 
    ret
need:
    push edx
    push format_hex_with_zero
    call printf
    add esp, 8 
    ret
    
next_line:
    push empty_string
    push format_string
    call printf
    add esp, 8
    jmp start_loop
    
duplicate:
    dec dword [stp] ;now will point on the top number
    getAddress first_element
    inc dword [stp]
    ;next lines will preper were to put the argumant we create
    mov eax, [stp]
    mov dword [put], stackOp
    mov ebx, 4
    mul ebx ;stp*4 will be in eax
    add [put], eax ;[put] - is stckOP + stp*4
duplicate_loop:
    cmp dword [first_element],0
    jz last_digit
    push dword [bytes_to_malloc]  
    call malloc ; eax is the pointer that malloc returns 
    add esp, 4 
    
    mov ebx, [put] 
    mov [ebx] , eax ;push pointer to first digit of the number into the stack operand 
    mov ebx, [first_element]
    mov dl, [ebx]
    mov byte [eax], dl ;the first cell's value is the data (the sum)
    inc eax ;the address of 4 bytes of the pointer 
    mov [put], eax
    next_node first_element ; move the the next byte 
    jmp duplicate_loop
    
    
pos_power:
    dec dword [stp] ;now will point on the top number
    getAddress first_element
    dec dword [stp]
    getAddress second_element
    ;push the first_element address into the stack
    mov edx, [stp]
    mov ecx, [first_element] ;the address of the first node in the heap is in ecx
   
    inc dword [stp]
    mov eax, [second_element] ;eax hold the address of the Y
    mov byte bl, [eax] ;bl hold thw number Y
    inc eax ;to get the pointer to the next node
    cmp dword [eax], 0
    jnz error_Power;Y greater then 200
    mov dword [second_element] ,0 ;to zero the value of secound element
    add byte [second_element], bl ;[second_element] is Y 
    cmp byte [second_element], 0xc8 ;Y greater then 200
    ja error_Power
   
   
    mov [stackOp + edx*4], ecx ;make the first_element be on top of the stack
   
   
   loop_shl:
    mov byte [carry], 0 ;rest carry
    cmp dword [second_element], 0 ;finished going threw Y
    jz start_loop
    loop_on_number:
    cmp dword [first_element], 0 ;end of number [first_element] is the address of the current node
    jz end_of_digit_shl    
    mov dword edx, 0;rest edx
    mov byte dl, [carry] ; dl will save the carry that was needed to be add after we will shl
    mov eax, [first_element];eax is the adrress of the firstbyte of the first element
    mov byte bl, [eax]; bl is the value of the element
    shl bl,1 ;power of two
    save_carry_mac
    add byte bl,dl ;add the carry of the prev node to the number 
    mov byte [eax] ,bl ;save bl to the place in the node
    ;prepre next node with saving the address of the pointer in order to alloc new node later
    inc dword [first_element] ;next byte of the element 
    mov ebx, [first_element] ;save the next adrress
    mov dword [put], ebx
    mov ebx, [ebx] ;address of the next node 
    mov [first_element], ebx ;move it back to the element
    jmp loop_on_number
end_of_digit_shl:
    cmp byte [carry], 0
    jnz create_node_pow ;if there was a carry and we need to open a new node
prep_next_pow:
    mov dword [first_element] , ecx
    dec dword [second_element]
    jmp loop_shl
create_node_pow:
    ;malloc a new element
    push ecx
    push dword [bytes_to_malloc]  
    call malloc ; eax is the pointer that malloc returns 
    add esp, 4
    pop ecx
        check:
    mov ebx, [put] ;stackop adrress
    mov [ebx] , eax ;push pointer to first digit of the number into the stack operand  
    ;put the number 1 in the byte
    mov byte [eax], 1
    ;point next pointer to zero
    inc eax;now its the adress of the next four bytes
    mov dword [eax], 0
    jmp prep_next_pow
    
  
neg_power:
    
n1bits:
square_root:
   jmp start_loop
error_Power:
    add dword [stp], 2
    push calc_string
    push format_string
    call printf 
    add dword esp, 8 ;pop printf arguments 
   
insufficient_error:

overflow_error:
    jmp start_loop
    
    
    
    
    ;some help code
delete_zero:
    cmp byte [buffer + ecx], 0 ;if reached end and all zerro
    jz put_zero
    cmp byte [buffer + ecx], '0' ;number starts with zeroes 
    jnz convert_to_hex
    inc ecx 
    jmp delete_zero
put_zero:
    mov byte [buffer_hex], 0;put 0 if the number is all zeros
    inc dword [index]
    jmp end_buffer_hex
    
convert_to_hex:
    mov [first_digit_not_zero], ecx ;the *index* of the first byte that is not zero in the buffer 
length:
    cmp byte [buffer + ecx], 0 ;end of string 
    jz check_even
    inc ecx 
    jmp length 
check_even:
    sub ecx, [first_digit_not_zero]
    shr ecx, 1 ;to check if length of the string is even or odd 
    jc odd_number 
    mov ecx, [first_digit_not_zero] ;even length 
convert: ;assure that the number of bytes that this loop calculate is  even
    cmp byte [buffer + ecx], 0 ;end of string 
    jz end_buffer_hex
    mov ebx, [buffer + ecx] ;gets the number to convert
    push ebx ;push the number as an argumant for function
    call convert_dig
    add esp, 4
    inc ecx ;to check next digit
    mov eax ,edx ;the value of the char returned from function
    mov ebx,16
    mul ebx ;the result of the mult 
    ;the result in eax
    mov ebx, [buffer + ecx]
    push ebx
    call convert_dig
    add esp, 4
    add eax,edx
    mov ebx, [index]
    mov byte [buffer_hex + ebx], al
    inc dword [index] ;inc index of buffer_hex
    inc ecx ; inc index of buffer_string - second increament
    jmp convert
    
convert_dig: ;return value will be in edx
    startFunc
    mov edx, [ebp +8]
    cmp dl , 'A'
    jl d_ten_convert ;0...9
    sub edx, 55
    jmp end_convert_dig
d_ten_convert:
    sub edx, 48
end_convert_dig:
    endFunc
    ret
odd_number:
    mov ecx, [first_digit_not_zero]
    mov ebx, [buffer+ecx] ;gets the first byte to convert
    push ebx ;push the number as an argumant for function
    call convert_dig
    add esp, 4
    mov byte [buffer_hex], dl 
    inc ecx
    inc dword [index]
    jmp convert
end_buffer_hex:
    mov  ebx, [index]
    mov byte [buffer_hex + ebx], 'q'
    jmp start_push
    
