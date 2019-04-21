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

%macro print_string 1
    push %1
    push format_string
    call printf 
    add dword esp, 8 ;pop printf arguments 
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
 
 %define stack_size 5
 %define stack_byte_size 20

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
    jc %%save_ca
    mov byte [carry],0
    jmp %%no_carry
    %%save_ca:
    mov byte [carry], 1
    %%no_carry:
    mov byte [eax], dl ;the first cell's value is the data (the sum)
    inc eax ;the address of 4 bytes of the pointer 
    mov [put], eax 
    
    mov eax, [%1]
    next_node %1
    free_node eax
%endmacro

%macro pow_start 0
    inc dword [numOp]
    cmp dword [stp], 2
    jl insufficient_error   
    dec dword [stp] ;now will point on the top number
    getAddress first_element
    dec dword [stp]
    getAddress second_element
    ;push the first_element address into the stack
    mov edx, [stp]
    mov ecx, [first_element] ;the address of the first node in the heap is in ecx
    inc dword [stp]
    mov eax, [second_element] ;eax hold sthe address of the Y
    mov dword [save_address], eax 
    mov byte bl, [eax] ;bl hold the number Y
    inc eax ;to get the pointer to the next node
     ;check if Y is grater than 200
    cmp dword [eax], 0
    jnz error_Power;Y greater then 200
    mov dword [second_element] ,0 ;to zero the value of secound element
    add byte [second_element], bl ;[second_element] is Y 
    cmp byte [second_element], 0xc8 ;Y greater then 200
    ja error_Power
    pushad
    push dword [save_address]
    call free 
    add esp, 4
    popad
    mov [stackOp + edx*4], ecx ;make the first_element be on top of the stack
    
%endmacro

section	.rodata			; we define (global) read-only variables in .rodata section
    format_string_no_newline: db "%s", 0	; format string
	format_string: db "%s", 10, 0	; format string
    format_hex_nweline:  db "%X",10, 0
    format_hex:  db "%X", 0
    format_hex_with_zero:  db "%02X", 0
   
	
section .data
    numOp: dd 0 ;number of operations in the program 
    Insufficient_string: db "Error: Insufficient Number of Arguments on Stack",0
    over_flow_string: db "Error: Operand Stack Overflow",0
    calc_string: db "calc: ",0
    over_200_string: db "Error: Y is greater than 200",0
    empty_string: db "",0
    input_string: db "User is trying to insert: ", 0
    insert_string: db "the result inserted to the stack is: ", 0
    stp: dd 0 ;points to the first free location in the stack 
    bytes_to_malloc: dd stack_size    
    index: dd 0 ;index in buffer_hex 
    carry: db 0 ;byte of the carry
    first_element: dd 0
    second_element: dd 0
    first_digit_not_zero: dd 0
    put: dd 0 ;the next address to put in a new pointer (for creating the numbers)
    isDebug: dd 0 ;0-not debug, 1-debug
    save_address: dd 0
    
section .bss
    stackOp:resb stack_byte_size ; this is the stack of our operands - 4 bytes for each block - 5 blocks  
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
    startFunc
    mov eax, 0
    mov eax, [ebp+8] ;check if debug mode , the second argument 
    cmp eax, 2
    jnz keep_main
    mov dword [isDebug], 1 ;in debug mode there are two arguments 1-path 2-"-d" 
keep_main:    
    sub esp, 8 ;stack allignment
    call myCalc ;calling the main function 
    add esp, 8
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
    push calc_string ;print calc:
    push format_string_no_newline
    call printf 
    add dword esp, 8 ;pop printf arguments
    push buffer  ;get input from user  
    call gets
    add dword esp, 4 ;pop gets argument 
    cmp byte [buffer], 'q'
    jz end_func
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
    jmp push_number 
end_func:
    jmp free_rest_of_stack
    cont_finish:
    push dword [numOp] ;print num of opartion
    push format_hex_nweline
    call printf
    add esp, 8
    endFunc
    ret 
initialize_buffer:
    cmp ecx, 80
    jz con
    mov dword [buffer + ecx], 0
    inc ecx
    jmp initialize_buffer

free_rest_of_stack:
    cmp dword [stp], 0
    jz cont_finish
    getAddress save_address
    dec dword [stp]
    jmp free_num_finish
    
free_num_finish:
    cmp dword [save_address], 0
    jz free_rest_of_stack
    mov eax ,[save_address] ;eax gets the adress of the first_element
    inc eax
    mov eax ,[eax] ;eax has the adrees of the next node
    push eax
    push dword [save_address]
    call free 
    add esp, 4
    pop eax
    mov dword [save_address] ,eax ;save_address is next node
    jmp free_num_finish
    

push_number:
    cmp dword [isDebug], 1
    jnz keep
    push input_string
    push format_string
    call printf
    add esp, 8
    push buffer
    push format_string
    call printf
    add esp,8
keep:
    cmp dword [stp], 5
    jz overflow_error ; if stack is full print error
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
    push dword [bytes_to_malloc] 
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
    mov byte [carry], 0 ;initialize carry
    inc dword [numOp]   ;count num of operations 
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
    
    
addition_loop: ;the addition calc is in edx -dl 
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
    jmp last_digit_addition
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
    jmp last_digit_addition
    
;Function 
make_addition: ;add two bytes the result is in dl 
    
    startFunc
    mov ebx, [ebp + 8] ;ebx is the address of the first element
    mov dword edx, 0 ;initialize to 0 in order to get the number
    mov byte dl, [ebx] ;taking the first byte in this address = the number itself 
    mov ebx, [ebp + 12]
    add byte dl, [ebx] ;the sum of the first two elements 
    jc save_carry_and_add_carry
    add byte dl, [carry] ;add carry 
    jc save_carry ;we wiil save the carry of this action if ecsist
    mov byte [carry], 0
    jmp end_make_addition
save_carry_and_add_carry:
    add byte dl, [carry]
save_carry:
    mov byte [carry], 1 
end_make_addition: 
    endFunc
    ret

last_digit_addition: ;
   mov ebx, [put]
   mov dword [ebx], 0;last pointer to the zero byte 
   inc dword [stp]; increse the number of numbers in the stack
   jmp print_debug
   
pop_print:
    inc dword [numOp]   ;count num of operations 
    cmp dword [stp], 0
    jz insufficient_error  ;there is no element in the satck 
    dec dword [stp] ;so it will point to the place of the last emlement
    mov eax, [stp]
    mov ebx, [stackOp + eax*4] ;ebx is the address of the operand on the top of the stack
    mov dword [save_address] ,ebx
    call print_num
    jmp free_num 
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
free_num:
    cmp dword [save_address], 0
    jz next_line
    mov eax ,[save_address] ;eax gets the adress of the first_element
    inc eax
    mov eax ,[eax] ;eax has the adrees of the next node
    push eax
    push dword [save_address]
    call free 
    add esp, 4
    pop eax
    mov dword [save_address] ,eax ;save_address is next node
    jmp free_num

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
    inc dword [numOp]   ;count num of operations 
    cmp dword [stp], 0
    jz insufficient_error
    cmp dword [stp], stack_size
    jz overflow_error
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
    jz last_digit_addition
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
    pow_start
      
loop_shl:
    mov byte [carry], 0 ;rest carry
    cmp dword [second_element], 0 ;finished going threw Y
    jz print_debug
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
    mov dword [put], ebx ;put will be the adress wich points to first_element
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
    mov ebx, [put] ;stackop adrress
    mov [ebx] , eax ;push pointer to first digit of the number into the stack operand  
    ;put the number 1 in the byte
    mov byte [eax], 1
    ;point next pointer to zero
    inc eax;now its the adress of the next four bytes
    mov dword [eax], 0
    jmp prep_next_pow
    
  
neg_power:
    pow_start ;initialize first_element to be the adrress and secound to be the Y number
    mov dword [put], ecx ;put now will save the address of the prev byte in order to change next address to zero after free
    mov dword [second_element] ,0 ;to zero the value of secound element
    add byte [second_element], bl ;[second_element] is Y 
   
    loop_shr:
    mov byte [carry] ,0 ;rest carry
    cmp dword [second_element] ,0
    jz print_debug
    call shr_fanction
    mov dword [first_element] , ecx ;restore begin of number
    dec dword [second_element]
    jmp loop_shr

    
shr_fanction:
    cmp dword [first_element], 0 
    jnz continue_1
    ret
continue_1:
    push dword [first_element]
    push dword [put]
    mov eax, [first_element]
    mov dword [put], eax ;make prev be current
    next_node first_element ;advance curr to next
    call shr_fanction
    pop eax ;restore adress of put
    mov [put], eax ;restore address of put
    pop eax
    mov [first_element], eax ;restore address of first_element

    mov dword edx, 0;rest edx
    mov byte dl, [carry] ; dl will save the carry that was needed to be add after we will shl
    mov eax, [first_element];eax is the adrress of the firstbyte of the first element
    mov byte bl, [eax]; bl is the value of the element
    shr bl,1 ;power of two
    save_carry_mac
    cmp byte dl, 0 ;if there is no carry no need to add
    jz contintue_2
    add byte dl, 0X7F ;make dl be 128
    add byte bl,dl ;add the carry of the prev node to the number 
contintue_2:
    mov byte dl, bl ;dl will save the number after addtion
    mov byte [eax] ,bl ;save bl to the place in the node
    inc eax ;now will get next adrees
    cmp dword [eax], 0
    jz check_free
contintue_3:
    ret


check_free:
    mov dword eax,[first_element] ;to sea what we have in first_element
    cmp byte dl ,0 ;check if the number in the last node is zero
    jnz contintue_3
    cmp dword ecx ,[first_element] ;if we are in the first element dont delete the number keep the zero
    jz contintue_3
    push ecx ;to save ecx
    free_node eax
    pop ecx
    check:
    mov eax, [put] ;to check valu of put
    inc dword [put] ;now put will point to the address that hold first_element
    mov dword eax, [put]
    mov dword [eax], 0 ; now put will point to zero
    ret
n1bits: 
    inc dword [numOp]   ;count num of operations 
    cmp dword [stp], 0
    jz insufficient_error  ;there is no element in the satck dec dword [stp] ;now will point on the top number
    dec dword [stp] ;now will point on the top number
    getAddress first_element ;the number we count its 1 bits 
    mov ebx, [first_element]
    mov dword [save_address], ebx
    push dword [bytes_to_malloc]  
    call malloc ; eax is the pointer that malloc returns 
    add esp, 4 
    mov ebx, [stp]
    mov [stackOp + ebx*4], eax ;push into the stack counter initialize to zero 
    mov [second_element], eax ;[second_element] is the address of the node
    mov byte [eax], 0 ;initialize the counter of 1 bits 
    inc eax 
    mov dword [eax], 0 ;end of list 
    
    mov dword [put], stackOp 
    mov ebx, 4
    mul ebx ;stp*4 will be in eax
    add [put], eax ;[put] - is stckOP + stp*4 , [put] is the address where saved [second_element]
    
    mov byte [carry], 0
n1bits_loop:
    cmp dword [first_element], 0
    jz end_1bits
    ;initialize [second_element] and [put] 
    mov ebx, [stp]
    mov eax, [stackOp + ebx*4]  
    mov [second_element], eax ;[second_element] is the address of the node
    mov dword [put], stackOp 
    mov ebx, 4
    mul ebx ;stp*4 will be in eax
    add [put], eax ;[put] - is stckOP + stp*4 , [put] is the address where saved [second_element]
    
    mov ebx, [first_element]
    mov ecx, 0
    mov byte cl, [ebx] ; get the number itself 
    mov edx, 0 
    popcnt edx, ecx ;edx - num of 1 bits in cl 
    push edx
    push dword [second_element]
    call add_n1bits
    add esp, 8
add_bits:
    cmp byte [carry], 1
    jz carry_on 
    jmp next
carry_on:
    mov ebx, [second_element] ;address of the node
    mov eax, [ebx]
    inc ebx ;ebx is the address that hold the address for the next node
    mov [put], ebx 
    next_node second_element
    cmp dword [second_element], 0 ;get to the last node, if we do we need to add another node because there is still a carry 
    jz add_node
    
    mov dword edx, 1
    push edx
    push dword [second_element] 
    call add_n1bits
    add esp,8
    jmp add_bits 
add_node:
    push dword [bytes_to_malloc]  
    call malloc ; eax is the pointer that malloc returns 
    add esp, 4 
    mov ebx, [put]
    mov [ebx], eax 
    mov [second_element], eax 
    mov byte [eax], 1 ;there is a carry 
    inc eax
    mov dword [eax], 0 
    jmp next

add_n1bits: ;gets how many 1 bits to add
    startFunc
    mov eax, [ebp+8] ;the address of the counter
    mov edx, 0
    mov edx, [ebp+12] ;argument num of 1 bits to add 
    add byte [eax], dl ;maximun 1 byte
    jc carry_n1bits
    mov byte al, [eax]
    mov dl, [carry]
    add byte [eax], dl ;add carry 
    jc carry_n1bits 
    mov byte [carry], 0
    jmp end_add
carry_n1bits:
    mov byte [carry] ,1
        mov eax, [eax]
end_add:
    endFunc
    ret 
next: 
    next_node first_element
    jmp n1bits_loop
    
end_1bits:
    inc dword [stp]
    jmp free_num_1nbits
    
free_num_1nbits:
    cmp dword [save_address], 0
    jz print_debug
    mov eax ,[save_address] ;eax gets the adress of the first_element
    inc eax
    mov eax ,[eax] ;eax has the adrees of the next node
    push eax
    push dword [save_address]
    call free 
    add esp, 4
    pop eax
    mov dword [save_address] ,eax ;save_address is next node
    jmp free_num_1nbits

error_Power:
    inc dword [stp]
    print_string over_200_string
    jmp start_loop
insufficient_error:
    print_string Insufficient_string
    jmp start_loop
overflow_error:
    print_string over_flow_string
    jmp start_loop

print_debug:
    cmp dword [isDebug], 0
    jz start_loop
    print_string insert_string
    dec dword [stp] ;so it will point to the place of the last emlement
    mov eax, [stp]
    mov ebx, [stackOp + eax*4] ;ebx is the address of the operand on the top of the stack
    call print_num
    inc dword [stp]
    jmp next_line
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
    mov [first_digit_not_zero], ecx ;the index of the first byte that is not zero in the buffer 
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
