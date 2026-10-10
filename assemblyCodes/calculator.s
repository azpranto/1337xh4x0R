.intel_syntax noprefix
.global _start

_start:
    mov rdi, [rsp+16]
    mov rsi, [rsp+24]
    mov rdx, [rsp+32]

    cmp BYTE PTR [rsp], 3
    je unaryCheck

    mov r9, 0
    cmp BYTE PTR [rsi], 0x2b
    jne funcSub

continue:
    call atoi
    mov rdi, rdx
    mov rsi, rax

continueS:
    call atoi
    cmp r9, 1
    je funcSubed
    cmp r9, 2
    je funcMuled
    cmp r9, 3
    je funcAnded
    cmp r9, 4
    je funcOred
    cmp r9, 5
    je funcXored
    cmp r9, 6
    je funcNeged
    cmp r9, 7
    je funcNoted

continue2:
    add rsi, rax

continue3:
    mov rdi, rsi
    sub rsp, 0x80
    mov rsi, rsp

    call itoa

    mov rdi, 1
    mov rdx, rcx
    mov rax, 1
    syscall

    mov rdi, 0
    mov rax, 60
    syscall

atoi:
    xor rcx, rcx
    xor rax, rax
    cmp BYTE PTR [rdi], 0x2d
    je nigaMark

atoi_loop:
    cmp BYTE PTR [rdi], 0
    je done
    movzx r8, BYTE PTR [rdi]
    sub r8b, 0x30
    imul rax, 10
    add rax, r8
    inc rdi
    jmp atoi_loop

nigaMark:
    mov rcx, 1
    inc rdi
    jmp atoi_loop

nigaDone:
    neg rax
    xor rcx, rcx
    jmp done

done:
    cmp rcx, 1
    je nigaDone
    ret

errFinish:
    mov rdi, -1
    mov rax, 60
    syscall

funcSub:
    cmp BYTE PTR [rsi], 0x2d
    jne funcMul
    mov r9, 1
    jmp continue

funcMul:
    cmp BYTE PTR [rsi], 0x2a
    jne funcAnd
    mov r9, 2
    jmp continue

funcAnd:
    cmp BYTE PTR [rsi], 0x26
    jne funcOr
    mov r9, 3
    jmp continue

funcOr:
    cmp BYTE PTR [rsi], 0x7c
    jne funcXor
    mov r9, 4
    jmp continue

funcXor:
    cmp BYTE PTR [rsi], 0x5e
    jne errFinish
    mov r9, 5
    jmp continue

unaryCheck:
    cmp BYTE PTR [rdi], 0x2d
    jne notCheck
    mov r9, 6
    mov rdi, rsi
    jmp continueS

notCheck:
    cmp BYTE PTR [rdi], 0x7e
    jne errFinish
    mov r9, 7
    mov rdi, rsi
    jmp continueS



funcSubed:
    neg rax
    jmp continue2

funcMuled:
    imul rsi, rax
    jmp continue3

funcAnded:
    and rsi, rax
    jmp continue3

funcOred:
    or rsi, rax
    jmp continue3

funcXored:
    xor rsi, rax
    jmp continue3

funcNeged:
    neg rax
    mov rsi, rax
    jmp continue3

funcNoted:
    not rax
    mov rsi, rax
    jmp continue3




itoa:
    mov r8, 10
    xor rcx, rcx
    mov rax, rdi
    push 0
    cmp rax, 0
    jl isNiga
    cmp rax, 0
    jne itoa_loop
    mov BYTE PTR [rsi], 0x30
    mov rcx, 1
    pop r8  
    ret
itoa_loop:
    cmp rax, 0
    je popLoop
    xor rdx, rdx
    div r8
    add rdx, 0x30
    push rdx
    jmp itoa_loop

isNiga:
    neg rax
    mov BYTE PTR [rsi], 0x2d
    inc rcx
    jmp itoa_loop

popLoop:
    pop rdi
    cmp rdi, 0
    je doneBro
    mov BYTE PTR [rsi+rcx], dil
    inc rcx
    jmp popLoop

doneBro:
    ret