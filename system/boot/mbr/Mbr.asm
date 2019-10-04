format binary as 'aex'

USE16
ORG 0x7C00

define LOADER_ADDR_OFFS  0x8200
define LOADER_STACK      0x8000
define LOADER_STACK_SIZE 0x0000

    JMP    near Mbr.main

Mbr:

.BPB.OEM                                db    'Particle'    ;O3
.BPB.bytesPerSector                     dw    0x0200        ;O11
.BPB.sectorsPerCluster                  db    0x01          ;O13
.BPB.reservedSectors                    dw    0x0040        ;O14
.BPB.numberOfFats                       db    0x02          ;O16
.BPB.rootDirectoryEntries               dw    0x00E0        ;O17
.BPB.totalSectors                       dw    0x0B40        ;O19
.BPB.mediaDescriptor                    db    0xF8          ;O21
.BPB.sectorsPerFat                      dw    0x0009        ;O22
.BPB.sectorsPerTrack                    dw    0x0024        ;O24
.BPB.headsPerCilynder                   dw    0x0002        ;O26
.BPB.hiddenSectors                      dd    0x00000000    ;O28
.BPB.totalSectorsX                      dd    0x00000000    ;O32
.XBPB.driveNumber                       db    ?             ;O36
.XBPB.reserved                          db    0x00          ;O37
.XBPB.bootSignature                     db    0x29          ;O38
.XBPB.serialNumber                      dd    0x67452301    ;O39
.XBPB.volumeLabel                       db    'Part V '     ;O43
                                        dd    0
.XBPB.fileSystem                        db    'FAT12   '    ;O54

.DAP:
.DAP.size                               db    0x10
.DAP.reserved                           db    0x00
.DAP.sizeOfRead                         dw    0x003F
.DAP.addressPointer                     dw    0x0000, LOADER_ADDR_OFFS
.DAP.startAbsoluteBlock                 dq    0x0000000000000001

.loaderIntegrityError                   db    'FATAL: Error Reading The Loader.',0xA,0xD
.floppyReadError                        db    'FATAL: Error Reading The Floppy.',0xA,0xD
.floppyExtendedReadError                db    'FATAL: Error Reading The Floppy in DAP.',0xA,0xD
.diskReadError                          db    'FATAL: Eroor Reading The Disk.',0xA,0xD
.diskExtendedReadError                  db    'FATAL: Error Reading The Disk in DAP.',0xA,0xD
.jumpToLoaderError                      db    'FATAL: Error Tansfering Control To Loader.',0xA,0xD
.rebootAfterError                       db    '<ANY> REBOOT',0xA,0xD

.main:
    cli
    xor    ax, ax
    mov    ds, ax
    mov    es, ax
    mov    fs, ax
    mov    gs, ax
    
    mov    ax, LOADER_STACK
    mov    ss, ax
    mov    sp, LOADER_STACK_SIZE
    mov    bp, sp
    cld
    sti
    
    jmp    0:.cmain
.cmain:
    mov    [.XBPB.driveNumber], dl
    
    mov    ax, 0x0003
    int    0x10
    
    mov    ax, 0x0041
    mov    bx, 0x55AA
    int    0x13
    jc     .clmain.J0
    
    sub    bx, 0xAA55
    jnz    .clmain.J0
    
    and    cx, 0x0001
    jz     .clmain.J0
    
    mov    ax, 0x0042
    mov    si, .DAP
    int    0x13
    jc     .clmain.E0
    
.clmain.J1:
    mov    bx, LOADER_ADDR_OFFS
    cmp    WORD[bx], 'eP'
    jne    .clmain.E2
    cmp    WORD[bx+2], 'iI'
    jne    .clmain.E2
    
    jmp    WORD[bx+8]
    
    mov    si, .jumpToLoaderError
    jmp    .clmain.J2
.clmain.J0:
    mov    dh, 0x00
    mov    cx, 0x0002
    mov    bx, LOADER_ADDR_OFFS
    mov    ax, 0x023F
    int    0x13
    jc     .clmain.E1
    
    jmp    .clmain.J1
.clmain.J2:
    call   .print
    mov    si, .rebootAfterError
    call   .print
    xor    ax, ax
    int    0x16
    int    0x19
.clmain.E0:
    and    dl, 0x80
    jz     .clmain.J3
    mov    si, .diskExtendedReadError
    jmp    .clmain.J2
.clmain.J3:
    mov    si, .floppyExtendedReadError
    jmp    .clmain.J2
.clmain.E1:
    and    dl, 0x80
    jz     .clmain.J4
    mov    si, .diskReadError
    jmp    .clmain.J2
.clmain.J4:
    mov    si, .floppyReadError
    jmp    .clmain.J2
.clmain.E2:
    mov    si, .loaderIntegrityError
    jmp    .clmain.J2

.print:
    mov    ah, 0x0E
.print.L0:
    lodsb
    and    al, al
    jz     .print.J0
    int    0x10
    jmp    .print.L0
.print.J0:
    ret

times 0x01FE-($-$$) db 0
.magic                                  dw    0xAA55





























