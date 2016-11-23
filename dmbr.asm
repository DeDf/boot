; /***************** I'm MBR - nasm *****************/
; IN: DL = boot drive

start:
    xor     ax, ax
    cld                                   ; CLD 使方向标志位 DF(Direction Flag) 复位, 即DF=0, 每次操作后si,di递增

    cli                                   ; 禁止中断
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, 0x7c00
    sti                                   ; 允许中断

    cmp word [0x7c00+0x1fe],0xaa55        ; 检查MBR结束标志
    jne invalid_partition_code

; /* search for active partition */

    mov  di, 0x7c00+0x1be                 ; start of partition table

test_next_for_active:

    test byte [di],0x80
    jnz  active_partition_found
    add  di, 0x10                         ; next table
    cmp  di, 0x7c00+0x1fe                 ; table end?
    jb   test_next_for_active

    call print
    db 'no active partition found!',0
    jmp $

active_partition_found:

    call print
    db 'loading active partition~',0

    mov ax, di
    mov si, read+0x7c00
    mov di, 0x7b00
    mov cx, 0x100
    rep movsb                             ; 复制read标号处0x100字节到0x7b00，避免后面读硬盘到0x7c00造成覆盖
    mov di, ax
    jmp word 0x0:0x7b00

read:
    mov ax,[di+8]
    mov [_bios_LBA_low -read+0x7b00],ax
    mov ax,[di+8+2]
    mov [_bios_LBA_high-read+0x7b00],ax

    mov ah,0x42
    mov si,_bios_LBA_address_packet-read+0x7b00

    int 0x13
    jmp word 0x0:0x7c00

_bios_LBA_address_packet:
    db 0x10             ; packet_size
    db 0                ; Reserved
    dw 1                ; 要读取的扇区数
    dw 0x7c00           ; 缓冲区段内偏移
    dw 0x0000           ; 缓冲区段址
_bios_LBA_low  dw 0
_bios_LBA_high dw 0
    dw 0,0

;*****************************************************************

invalid_partition_code:
    call print
    db 'partition signature != 55AA',0
    jmp $

; /* PRINT -  print 'text after the call'. */

print:          pop   si                       ; this is the first char

print_1char:    lodsb                          ; 把DS:SI指向的存储单元中的数据装入AL，然后根据DF标志增/减SI
                cmp   al, 0                    ; end of string?
                je    print_ret

                mov   bx, 7                    ; BH页码，BL前景色（这里7为白色，可以在命令提示下输入color /?查看颜色）
                mov   ah, 0x0E                 ; via TTY mode
                int   0x10                     ; via TTY mode显示字符(AL存储要显示的字符)
                jmp   print_1char

print_ret:      push  si                       ; 此时si已经指向字符串后的指令了
                ret