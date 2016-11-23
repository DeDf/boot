; /***************** I'm XP32 NTFS DBR - nasm *****************/
; IN: DL = boot drive

%define offset 0x7C54

start:
    xor ax, ax
    mov ds, ax
    mov ah,0x42
    mov si,_bios_LBA_address_packet+offset
    int 0x13
    jmp word 0x0:0xD26A

_bios_LBA_address_packet:
    db 0x10             ; packet_size
    db 0                ; Reserved
    dw 0x10             ; 要读取的扇区数
    dw 0xD000           ; 缓冲区段内偏移
    dw 0x0000           ; 缓冲区段址
_bios_LBA_low  dw 0x3F
_bios_LBA_high dw 0
    dw 0,0