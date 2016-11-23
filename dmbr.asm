; /***************** I'm MBR - nasm *****************/
; IN: DL = boot drive

start:
    xor     ax, ax
    cld                                   ; CLD ʹ�����־λ DF(Direction Flag) ��λ, ��DF=0, ÿ�β�����si,di����

    cli                                   ; ��ֹ�ж�
    mov     ds, ax
    mov     es, ax
    mov     ss, ax
    mov     sp, 0x7c00
    sti                                   ; �����ж�

    cmp word [0x7c00+0x1fe],0xaa55        ; ���MBR������־
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
    rep movsb                             ; ����read��Ŵ�0x100�ֽڵ�0x7b00����������Ӳ�̵�0x7c00��ɸ���
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
    dw 1                ; Ҫ��ȡ��������
    dw 0x7c00           ; ����������ƫ��
    dw 0x0000           ; ��������ַ
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

print_1char:    lodsb                          ; ��DS:SIָ��Ĵ洢��Ԫ�е�����װ��AL��Ȼ�����DF��־��/��SI
                cmp   al, 0                    ; end of string?
                je    print_ret

                mov   bx, 7                    ; BHҳ�룬BLǰ��ɫ������7Ϊ��ɫ��������������ʾ������color /?�鿴��ɫ��
                mov   ah, 0x0E                 ; via TTY mode
                int   0x10                     ; via TTY mode��ʾ�ַ�(AL�洢Ҫ��ʾ���ַ�)
                jmp   print_1char

print_ret:      push  si                       ; ��ʱsi�Ѿ�ָ���ַ������ָ����
                ret