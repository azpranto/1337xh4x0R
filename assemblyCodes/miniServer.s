.intel_syntax noprefix
.global _start

_start:
    #socket sys_call
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall


    #struct in rsp
    push 0
    push 0x0000000050000002
    push rax                   #stored returned fd from socket for listen syscall

    #bind sys_call
    mov rdi, rax
    lea rsi, [rsp+8]           #has extra housing for fd in stack
    mov rdx, 16                #we are using only 2 bytes from the stack
    mov rax, 49
    syscall

    #listen sys_call
    mov rdi, [rsp]
    mov rsi, 0
    mov rax, 50
    syscall

    mov r10, rdi

loopStart:
    mov rdi, r10

    #accept sys_call
      #rdi already stores the fd (after syscall rdi stays the same)
    mov rsi, 0                 #usually need a struct to store client's ip addr, 0 to ignore that
    mov rdx, 0                 #size of rsi/struct
    mov rax, 43
    syscall

    mov r8, rax

    #fork process
    mov rax, 57
    syscall

    cmp rax, 0
    je POSTProcess

parentProcess:
    #closing new fd
    mov rax, 3
    mov rdi, r8
    syscall

    jmp loopStart


GETProcess:
    xor rcx, rcx

loop:
    cmp BYTE PTR [rsp], '/'
    je lenCount
    cmp rcx, rax
    je continue
    inc rsp
    inc rcx
    jmp loop
lenCount:
    xor rcx, rcx
loop2:
    cmp BYTE PTR [rsp+rcx], ' '
    je continue
    inc rcx
    jmp loop2


continue:
    mov BYTE PTR [rsp+rcx], 0
    #open sys_call
    mov rax, 2
    mov rdi, rsp
    mov rsi, 0
    mov rdx, 0
    syscall       #returns fd 5

    sub rsp, 1024
    #read syscall for response
    mov rdi, rax
    mov rsi, rsp
    mov rdx, 1024
    mov rax, 0
    syscall

    mov r9, rax

     #closing new fd
    mov rax, 3
    syscall

    #write syscall if get accepted
    mov rdi, r8
    lea rsi, [rip+response]
    # add rax, 19
    mov rdx, 19
    mov rax, 1
    syscall
    
    #write syscall for results
    mov rdi, r8
    mov rsi, rsp
    mov rdx, r9
    mov rax, 1
    syscall

    #closing new fd
    mov rax, 3
      #rdi already holds the new fd
    syscall

    mov rdi, rax
    mov rax, 60
    syscall



POSTProcess:

    #closing new fd
    mov rax, 3
    pop rdi
    syscall

    #read syscall for request
    sub rsp, 2024
    mov rdi, r8               #new fd after getting accepted
    mov rsi, rsp
    mov rdx, 2024
    mov rax, 0
    syscall

    cmp BYTE PTR [rsp], 'G'
    je GETProcess

    mov r10, rax
    mov r13, rsp
    xor rcx, rcx

post_loop:
    cmp BYTE PTR [rsp], '/'
    je PlenCount
    cmp rcx, rax
    je continue3
    inc rsp
    inc rcx
    jmp post_loop
PlenCount:
    xor rcx, rcx
Ploop2:
    cmp BYTE PTR [rsp+rcx], ' '
    je continue3
    inc rcx
    jmp Ploop2


continue3:
    mov BYTE PTR [rsp+rcx], 0

    #open sys_call
    mov rax, 2
    mov rdi, rsp
    mov rsi, 65
    mov rdx, 0x1FF
    syscall

    mov r9, rax

    inc rsp
    mov rbx, rsp
    xor rcx, rcx

respCount:
    cmp DWORD PTR [rbx], 0x0a0d0a0d
    je continue2
    inc rbx
    jmp respCount

continue2:
    #write syscall to write down the body
    lea rsi, [rbx+4]

    mov r12, rsi        
    sub r12, r13
    mov rdx, r10        
    sub rdx, r12

    mov rdi, rax
    mov rax, 1
    syscall

    #closing fd
    mov rdi, r9
    mov rax, 3
    syscall

    #write syscall if get accepted
    mov rdi, r8
    lea rsi, [rip+response]
    mov rdx, 19
    mov rax, 1
    syscall
    
    mov rdi, 0
    mov rax, 60
    syscall

    response:
        .asciz "HTTP/1.0 200 OK\r\n\r\n"