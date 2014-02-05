#ifndef __SerialMacros_H
#define __SerialMacros_H



#define S3C2410_URXH      (0x24)
#define S3C2410_UTXH      (0x20)
#define S3C2410_ULCON     (0x00)
#define S3C2410_UCON      (0x04)
#define S3C2410_UFCON     (0x08)
#define S3C2410_UMCON     (0x0C)
#define S3C2410_UTRSTAT   (0x10)
#define S3C2410_UERSTAT   (0x14)
#define S3C2410_UFSTAT    (0x18)
#define S3C2410_UMSTAT    (0x1C)
#define S3C2410_UBRDIV    (0x28)
#define S3C2410_UDIVSLOT  (0x2C)
#define S3C2410_UINTMSK   (0x38)

#define S3C2410_LCON_CFGMASK      ((0xF<<3)|(0x3))

#define S3C2410_LCON_CS5      (0x0)
#define S3C2410_LCON_CS6      (0x1)
#define S3C2410_LCON_CS7      (0x2)
#define S3C2410_LCON_CS8      (0x3)
#define S3C2410_LCON_CSMASK   (0x3)

#define S3C2410_LCON_PNONE    (0x0)
#define S3C2410_LCON_PEVEN    (0x5 << 3)
#define S3C2410_LCON_PODD     (0x4 << 3)
#define S3C2410_LCON_PMASK    (0x7 << 3)

#define S3C2410_LCON_STOPB    (1<<2)
#define S3C2410_LCON_IRM          (1<<6)

#define S3C2440_UCON_CLKMASK      (3<<10)
#define S3C2440_UCON_PCLK     (0<<10)
#define S3C2440_UCON_UCLK     (1<<10)
#define S3C2440_UCON_PCLK2    (2<<10)
#define S3C2440_UCON_FCLK     (3<<10)
#define S3C2443_UCON_EPLL     (3<<10)
#define S3C2410_UFCON_FIFOMODE    (1<<0)


#define S3C2410_UFSTAT_TXFULL     (1<<24)
#define S3C2410_UFSTAT_RXFULL     (1<<8)
#define S3C2410_UFSTAT_TXMASK     (255<<16)
#define S3C2410_UFSTAT_TXSHIFT    (16)
#define S3C2410_UFSTAT_RXMASK     (255<<0)
#define S3C2410_UFSTAT_RXSHIFT    (0)

/* UFSTAT S3C2443 same as S3C2440 */
#define S3C2440_UFSTAT_TXFULL     (1<<24)
#define S3C2440_UFSTAT_RXFULL     (1<<8)
#define S3C2440_UFSTAT_TXSHIFT    (16)
#define S3C2440_UFSTAT_RXSHIFT    (0)
#define S3C2440_UFSTAT_TXMASK     (255<<16)
#define S3C2440_UFSTAT_RXMASK     (255)

#define S3C2410_UTRSTAT_TXE   (1<<2)
#define S3C2410_UTRSTAT_TXFE      (1<<1)
#define S3C2410_UTRSTAT_RXDR      (1<<0)

#define S3C2410_UERSTAT_OVERRUN   (1<<0)
#define S3C2410_UERSTAT_FRAME     (1<<2)
#define S3C2410_UERSTAT_BREAK     (1<<3)
#define S3C2443_UERSTAT_PARITY    (1<<1)

    .macro fifo_level rd, rx
        ldr \rd, [\rx, # S3C2410_UFSTAT]
        and \rd, \rd, #S3C2440_UFSTAT_TXMASK
    .endm

    .macro  fifo_full rd, rx
        ldr \rd, [\rx, # S3C2410_UFSTAT]
        tst \rd, #S3C2440_UFSTAT_TXFULL
    .endm

    .macro addruart, rx
        ldr     \rx, =0x82500000
    .endm

    .macro  senduart,rd,rx
        strb    \rd, [\rx, # S3C2410_UTXH]
    .endm

    .macro  busyuart, rd, rx
        ldr \rd, [\rx, # S3C2410_UFCON]
        tst \rd, #S3C2410_UFCON_FIFOMODE    @ fifo enabled?
        beq 1001f               @
        @ FIFO enabled...
1003:
        fifo_full \rd, \rx
        bne 1003b
        b   1002f

1001:
        @ busy waiting for non fifo
        ldr \rd, [\rx, # S3C2410_UTRSTAT]
        tst \rd, #S3C2410_UTRSTAT_TXFE
        beq 1001b

1002:       @ exit busyuart
    .endm

    .macro  waituart,rd,rx
        ldr \rd, [\rx, # S3C2410_UFCON]
        tst \rd, #S3C2410_UFCON_FIFOMODE    @ fifo enabled?
        beq 1001f               @
        @ FIFO enabled...
1003:
        fifo_level \rd, \rx
        teq \rd, #0
        bne 1003b
        b   1002f
1001:
        @ idle waiting for non fifo
        ldr \rd, [\rx, # S3C2410_UTRSTAT]
        tst \rd, #S3C2410_UTRSTAT_TXFE
        beq 1001b

1002:       @ exit busyuart
    .endm

#endif /* __SerialMacros_H */
