.intel_syntax noprefix
.global _start

_start:
    xor r9, r9
    xor r8, r8
    xor rcx, rcx
    mov rdi, [rsp+16]

count:
    cmp BYTE PTR [rdi+rcx], 0x5c
    je escapeCheck
    cmp BYTE PTR [rdi+rcx], 0x25
    je escapeCheck
    cmp BYTE PTR [rdi+rcx], 0
    jne continue_loop
    call write
    jmp done

continue_loop:
    inc rcx
    jmp count

write:
    mov rsi, rdi
    mov rdi, 1
    mov rdx, rcx
    mov rax, 1
    syscall
    ret

done:
    mov rdi, 0
    mov rax, 60
    syscall

escapeCheck:
    cmp BYTE PTR [rdi+rcx+1], 0x6e
    jne funcBSlash

continue1:
    push rdi
    push rcx
    call write
    pop rcx
    pop rdi
    
    jmp checkByte

continue2:
    xor r8, r8
    lea rdi, [rdi+rcx+1]
    mov rcx, 1
    push rdi
    call write
    pop rdi

continue3:
    xor r8, r8
    lea rdi, [rdi+1]
    xor rcx, rcx
    jmp count

errFinish:
    mov rdi, -1
    mov rax, 60
    syscall

funcBSlash:
    cmp BYTE PTR [rdi+rcx+1], 0x5c
    jne funcPercent
    mov r8, 1
    jmp continue1

funcPercent:
    cmp BYTE PTR [rdi+rcx+1], 0x25
    jne funcInteger
    mov r8, 2
    jmp continue1

funcInteger:
    cmp BYTE PTR [rdi+rcx+1], 0x64
    jne funcString
    mov r8, 3
    jmp continue1

funcString:
    cmp BYTE PTR [rdi+rcx+1], 's'
    jne funcHex
    mov r8, 4
    jmp continue1

funcHex:
    cmp BYTE PTR [rdi+rcx+1], 'x'
    jne errFinish
    mov r8, 5
    jmp continue1

checkByte:
    cmp r8, 0
    jne checkBSlash
    mov BYTE PTR [rdi+rcx+1], 0x0a
    jmp continue2

checkBSlash:
    cmp r8, 1
    jne checkPercent
    mov BYTE PTR [rdi+rcx+1], 0x5c
    jmp continue2

checkPercent:
    cmp r8, 2
    jne checkInteger
    mov BYTE PTR [rdi+rcx+1], 0x25
    jmp continue2

checkInteger:
    cmp r8, 3
    jne checkString
    push rdi
    push rcx
    mov rdi, [rsp+40+r9]
    add r9, 8
    xor rcx, rcx
    call count_char
    call write
    pop rcx
    pop rdi
    lea rdi, [rdi+rcx+1]
    jmp continue3

checkString:
    cmp r8, 4
    jne checkHex
    push rdi
    push rcx
    mov rdi, [rsp+40+r9]
    add r9, 8
    xor rcx, rcx
    call count_char
    call write
    pop rcx
    pop rdi
    lea rdi, [rdi+rcx+1]
    jmp continue3

count_char:
    cmp BYTE PTR [rdi+rcx], 0
    je return
    jmp type_check
count_cont:
    inc rcx
    jmp count_char

type_check:
    cmp r8, 3
    je int_check
    cmp r8, 4
    je string_check
    
int_check:
    cmp BYTE PTR [rdi+rcx], '-'
    je count_cont
    sub BYTE PTR [rdi+rcx], 0x30
    cmp BYTE PTR [rdi+rcx], 10
    jl int_check2
    jmp errFinish

int_check2:
    cmp BYTE PTR [rdi+rcx], 0
    jl errFinish
    add BYTE PTR [rdi+rcx], 0x30
    jmp count_cont

string_check:
    jmp count_cont

checkHex:
    cmp r8, 5
    jne errFinish
    mov al, BYTE PTR [rdi+rcx+2]
    call hexTypeCheck
    movzx rdx, al
    shl rdx, 4
    mov al, BYTE PTR [rdi+rcx+3]
    call hexTypeCheck
    or rdx, rax
    push rdi
    push rcx
    push rdx
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 1
    mov rax, 1
    syscall
    pop rdx
    pop rcx
    pop rdi
    lea rdi, [rdi+rcx+3]
    jmp continue3
    
hexTypeCheck:
hexTypeInt:
    cmp al, 0x30
    jl errFinish
    cmp al, 0x39
    ja hexTypeUCalpha
    sub al, 0x30
    ret

hexTypeUCalpha:
    cmp al, 'A'
    jl errFinish
    cmp al, 'F'
    ja hexTypeLCalpha
    sub al, 'A'
    add al, 10
    ret

hexTypeLCalpha:
    cmp al, 'a'
    jl errFinish
    cmp al, 'f'
    ja errFinish
    sub al, 'a'
    add al, 10
    ret

return:
    ret