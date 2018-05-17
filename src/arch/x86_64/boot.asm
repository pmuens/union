global start
extern kmain

section .text
bits 32
start:
    mov esp, stack_top
    ; check if processor supports necessary features
    call check_multiboot
    call check_cpuid
    call check_long_mode
    ; point first p4 entry to first p3 entry
    mov eax, p3_table
    or eax, 0b11
    mov dword [p4_table + 0], eax
    ; point first p3 entry to first p2 entry
    mov eax, p2_table
    or eax, 0b11
    mov dword [p3_table + 0], eax
    ; point each p2 entry to a page
    mov ecx, 0                 ; counter variable
.map_p2_table:
    mov eax, 0x200000          ; 2MiB
    mul ecx
    or eax, 0b10000011
    mov [p2_table + ecx * 8], eax
    inc ecx
    cmp ecx, 512
    jne .map_p2_table
    ; move page table address to cr3
    mov eax, p4_table
    mov cr3, eax
    ; enable PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax
    ; set the long mode bit
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    ; enable paging
    mov eax, cr0
    or eax, 1 << 31
    or eax, 1 << 16
    mov cr0, eax
    ; load the GDT
    lgdt [gdt64.pointer]
    ; update selectors
    mov ax, gdt64.data
    mov ss, ax
    mov ds, ax
    mov es, ax
    ; jump to long mode
    jmp gdt64.code:kmain
    hlt

check_multiboot:
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot:
    mov al, "0"
    jmp error

check_cpuid:
    ; check if CPUID is supported by attempting to flip the ID bit (bit 21)
    ; in the FLAGS register. If we can flip it, CPUID is available.
    ; copy FLAGS in to EAX via stack
    pushfd
    pop eax
    ; copy to ECX as well for comparing later on
    mov ecx, eax
    ; flip the ID bit
    xor eax, 1 << 21
    ; copy EAX to FLAGS via the stack
    push eax
    popfd
    ; copy FLAGS back to EAX (with the flipped bit if CPUID is supported)
    pushfd
    pop eax
    ; restore FLAGS from the old version stored in ECX (i.e. flipping the
    ; ID bit back if it was ever flipped).
    push ecx
    popfd
    ; compare EAX and ECX. If they are equal then that means the bit
    ; wasn't flipped, and CPUID isn't supported.
    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, "1"
    jmp error

check_long_mode:
    ; test if extended processor info in available
    mov eax, 0x80000000        ; implicit argument for cpuid
    cpuid                      ; get highest supported argument
    cmp eax, 0x80000001        ; it needs to be at least 0x80000001
    jb .no_long_mode           ; if it's less, the CPU is too old for long mode

    ; use extended info to test if long mode is available
    mov eax, 0x80000001        ; argument for extended processor info
    cpuid                      ; returns various feature bits in ecx and edx
    test edx, 1 << 29          ; test if the LM-bit is set in the D-register
    jz .no_long_mode           ; If it's not set, there is no long mode
    ret
.no_long_mode:
    mov al, "2"
    jmp error

; prints `ERR: ` and the given error code to screen and hangs.
; parameter: error code (in ascii) in al
error:
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mov byte  [0xb800a], al
    hlt

section .bss
align 4096
p4_table:
    resb 4096
p3_table:
    resb 4096
p2_table:
    resb 4096
stack_bottom:
    resb 64
stack_top:

section .rodata
gdt64:
    dq 0
.code: equ $ - gdt64
    dq (1 << 44) | (1 << 47) | (1 << 41) | (1 << 43) | (1 << 53)
.data: equ $ - gdt64
    dq (1 << 44) | (1 << 47) | (1 << 41)
.pointer:
    dw .pointer - gdt64 - 1
    dq gdt64
