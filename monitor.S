/*
 * Copyright 2014, winocm. <winocm@icloud.com>
 */
/*
 * TrustZone stub.
 *
 * S3C uart setup print from the Linux kernel.
 *
 * $ arm-none-eabi-gcc monitor.S -nostdlib -Ttext=0x5FE00000 -o monitor -DPAGETABLE_OFFSET=0x84000000
 */

#include "asm_help.h"
#include "SerialMacros.h"

#define EXC_PREFETCH        0
#define EXC_UNDEF           1
#define EXC_ABORT           2

#define _1KB                1024
#define _1MB                (1024 * _1KB)
#define EXCPT_STACK_SIZE    (1 * _1KB)
#define PAGE_SIZE           4096
#define PTE_MASK_CODE       0x40E
#define PTE_MASK            0xC12               /* Cacheable, writethru */
#define STACK_SIZE          (2 * _1KB)
#define L1_SIZE             (4 * PAGE_SIZE)

    .code 32
    .arm
    .text

/* 
 * Secure mode entrypoint, entered in from first start. We're assuming the following 
 * is true:
 *
 * - MMU disabled.
 * - Caches disabled.
 */
EnterARM(start)
    b       _reset_secure_tramp
    nop                                            /* Unused, undefined. */
    b       _reset_secure_sp_tramp                 /* Trampoline to set up monitor SP */
    nop                                            /* Unused, prefetch abort. */
    nop                                            /* Unused, data abort. */
    nop                                            /* Unused, address line exception. */
    nop                                            /* Unused, IRQ. */
    nop                                            /* Unused, FIQ. */

EnterARM(reset_secure_tramp)
    /* No interrupts. Supervisor mode. */
    cpsid   aif, #(MODE_SVC)

    /* Relocate ourselves if necessary. */
    ldr     r0, =_start
    adr     r1, _start
    cmp     r0, r1
    beq     .Lrelocdone

    /* XXX use __end */
    movs    r3, #(1 * 1024 * 1024)
.Lrelocate:
    ldr     r2, [r1], #4
    str     r2, [r0], #4
    subs    r3, r3, #4
    bgt     .Lrelocate
    ldr     r0, =_start
    bx      r0

.Lrelocdone:
    /* Write the first trampoline MVBAR to switch to monitor mode. */
    adr     r0, _start
    mcr     p15, 0, r0, c12, c0, 1
    isb     sy

    /* Force a switch. (LOL BAD EMULATORS) */
    smc     #0

    /* We're back from the monitor trampoline SP-setup. Set up the rest of the registers now. */
    ldr     sp, =_secure_stackptr_svc_end

    /* Now, print out some messages. :) */
    ldr     r0, =_tzboot_welcome
    bl      _puts

    /* Time to set up the page tables. Map all memory as writethrough. */
    ldr     r0, =_tzboot_ptsetup
    bl      _puts

    /* XXX write linker script */
    ldr     r0, =(PAGETABLE_OFFSET)

    /* Map all pages in memory. */
    mov     r5, r0
    mov     r1, #(L1_SIZE)

    /* Zero out page table base. */
    mov     r2, #((L1_SIZE) >> 2)
    mov     r6, #0
    mov     r7, #0
    mov     r8, #0
    mov     r9, #0
.Lptzero:
    stmia   r5!, {r6-r9}
    subs    r2, r2, #1
    bne     .Lptzero

    /* Now create the page tables. */
    mov     r5, r0
    movw    r2, #(PTE_MASK)
    mov     r3, #0
.Lptcreate:
    orr     r4, r3, r2
    str     r4, [r0], #4
    adds    r3, r3, #(_1MB)
    subs    r1, r1, #4
    bgt     .Lptcreate

    /* Code region has different attributes. */
    movw    r2, #(PTE_MASK_CODE)
    mov     r4, pc
    lsr     r4, pc, #20
    lsl     r6, r4, #2
    lsl     r4, r4, #20
    orr     r3, r4, r2
    str     r3, [r5, r6]

    /* Identity page table created, set up MMU (TTBR0/TTBR1) now. */
    mcr     p15, 0, r5, c2, c0, 0
    mcr     p15, 0, r5, c2, c0, 1

    /* Set up DACR and TTBCR. */
    mov     r0, #1
    mcr     p15, 0, r0, c3, c0, 0
    mov     r0, #0
    mcr     p15, 0, r0, c2, c0, 2
    isb     sy

    /* Invalidate uTLB */
    mcr     p15, 0, r0, c8, c7, 0
    isb     sy

    ldr     r0, =_tzboot_mmuen
    bl      _puts

    /* We're good for MMU setup, now initialize it proper. */
    mrc     p15, 0, r0, c1, c0, 0
    orr     r0, r0, #(MMUEN_BIT)
    mcr     p15, 0, r0, c1, c0, 0
    isb     sy

    ldr     r0, =_tzboot_exchldr
    bl      _puts

    /* Now, set up proper exception handlers. */
    ldr     r0, =_real_vector_table
    mcr     p15, 0, r0, c12, c0, 0
    mcr     p15, 0, r0, c12, c0, 1
    isb     sy

    /* Set up the rest of the exception handler stacks. */
    ldr     r0, =_tzboot_stksetup
    bl      _puts
    cps     #(MODE_UND)
    ldr     sp, =_secure_stackptr_und_end
    cps     #(MODE_IRQ)
    ldr     sp, =_secure_stackptr_irq_end
    cps     #(MODE_ABT)
    ldr     sp, =_secure_stackptr_abt_end
    cps     #(MODE_SVC)

    /* Done with everything. Drop down to non-secure world by toggling it. */
    ldr     r0, =_tzboot_exiting
    bl      _puts
    mrc     p15, 0, r0, c1, c1, 0
    orr     r0, r0, #(NS_BIT)
    mcr     p15, 0, r0, c1, c1, 0

    /* Test it, does it work? */
    smc     #0 

    /* We're back in the non-secure world now. */
    cpsid   if, #(MODE_SVC)
    ldr     r0, =_tzboot_nswelcome
    bl      _puts

.Lbootimag:
#error need a non-secure image load here.

    /* xxx todo */
    b       .

_tzboot_welcome:
    .asciz  "[!] tzboot, a TrustZone trampoline thing by @winocm\n"
_tzboot_ptsetup:
    .asciz  "[!] Setting up page tables...\n"
_tzboot_mmuen:
    .asciz  "[!] Enabling MMU...\n"
_tzboot_stksetup:
    .asciz  "[!] Setting up stacks...\n"
_tzboot_exchldr:
    .asciz  "[!] Setting up exception vectors...\n"
_tzboot_exiting:
    .asciz  "[!] Exiting secure world...\n"
_tzboot_nswelcome:
    .asciz  "[!] Welcome to NON-SECURE land! Attempting to boot non-secure image now.\n"

/*
 * This routine is entered from the initial MVBAR setup tramp to force a switch
 * to monitor mode. This is done because QEMU-TrustZone can't seem to switch CPSR
 * modes to TZ very easily.
 *
 * XXX do real CPUs do this?
 */
EnterARM(reset_secure_sp_tramp)
    /* Set up the stack pointer for trusted mode. */
    ldr     sp, =_secure_stackptr_mon_end

    /* Exception return. */
    movs    pc, lr

/* 
 * Exception handlers:
 */
EnterARM(real_secure_reset_tramp)
    b       .

EnterARM(real_secure_undef_tramp)
    /* Store GPRs r0-r12 on the stack. */
    stmfd   sp!, {r0-r12}

    /* Store the SPSR on the stack. */
    mrs     r0, spsr
    stmfd   sp!, {r0}

    /* Switch modes and save the banked SP/LRs on the stack. */
    mrs     r1, cpsr
    msr     cpsr_c, r0
    mov     r2, sp
    mov     r3, lr
    msr     cpsr_c, r1
    stmfd   sp!, {r2-r3}

    /* Go to the exception handling routine. */
    mov     r0, sp
    mov     r1, #(EXC_UNDEF)
    bl      _do_exception

EnterARM(real_secure_smc_tramp)
    /* Save argument registers on stack so we can use them as scratch. */
    stmfd   sp!, {r0-r12,lr}
    cpsid   if

    /* Transfer to C-level SMC handler. */
    mov     r1, sp
    mov     r0, r12
    bl      _do_smc

    /* Exception return. */
    mrc     p15, 0, r0, c1, c1, 0
    orr     r0, r0, #(NS_BIT)
    mcr     p15, 0, r0, c1, c1, 0

    ldmfd   sp!, {r0-r12,lr}
    movs    pc, lr

EnterARM(real_secure_prefetch_tramp)
    sub     lr, lr, #4

    /* Store GPRs r0-r12 on the stack. */
    stmfd   sp!, {r0-r12}

    /* Store the SPSR on the stack. */
    mrs     r0, spsr
    stmfd   sp!, {r0}

    /* Switch modes and save the banked SP/LRs on the stack. */
    mrs     r1, cpsr
    msr     cpsr_c, r0
    mov     r2, sp
    mov     r3, lr
    msr     cpsr_c, r1
    stmfd   sp!, {r2-r3}

    /* Go to the exception handling routine. */
    mov     r0, sp
    mov     r1, #(EXC_PREFETCH)
    bl      _do_exception

EnterARM(real_secure_abort_tramp)
    /* Store GPRs r0-r12 on the stack. */
    stmfd   sp!, {r0-r12}

    /* Store the SPSR on the stack. */
    mrs     r0, spsr
    stmfd   sp!, {r0}

    /* Switch modes and save the banked SP/LRs on the stack. */
    mrs     r1, cpsr
    msr     cpsr_c, r0
    mov     r2, sp
    mov     r3, lr
    msr     cpsr_c, r1
    stmfd   sp!, {r2-r3}

    /* Go to the exception handling routine. */
    mov     r0, sp
    mov     r1, #(EXC_ABORT)
    bl      _do_exception

EnterARM(real_secure_irq_tramp)
    b       .

EnterARM(real_secure_fiq_tramp)
    b       .

/*
 * Support routines.
 */
EnterARM(puts)
    addruart r3
    b        2f
1:  waituart r2, r3
    senduart r1, r3
    busyuart r2, r3
    teq      r1, #'\n'
    moveq    r1, #'\r'
    beq      1b
2:  teq      r0, #0
    ldrneb   r1, [r0], #1
    teqne    r1, #0
    bne      1b
    mov      pc, lr

/*
 * Stub exception handler.
 */
EnterARM(do_exception)
    cpsid   if

    /* Explain why we hung. */
    cmp     r1, #(EXC_PREFETCH)
    ldreq   r0, =.Lexcstr_prefetch
    cmp     r1, #(EXC_ABORT)
    ldreq   r0, =.Lexcstr_abort
    cmp     r1, #(EXC_UNDEF)
    ldreq   r0, =.Lexcstr_undef
    bl      _puts

    /* Halt the system forever. */
.Lwfiloop:
    wfi
    b       .Lwfiloop

.Lexcstr_prefetch:
    .asciz  "System monitor encountered Prefetch Abort, halting.\n"
.Lexcstr_abort:
    .asciz  "System monitor encountered Data Abort, halting.\n"
.Lexcstr_undef:
    .asciz  "System monitor encountered Undefined Instruction, halting.\n"

/* 
 * SMC call handler.
 */
EnterARM(do_smc)
    stmfd    sp!,{lr}
    ldr      r0, =.Ldo_smc
    bl       _puts
    ldmfd    sp!,{pc}

.Ldo_smc:
    .asciz  "[x] System monitor encountered SMC instruction! SECURE WORLD says HELLO.\n"

/*
 * Helper.
 */
EnterARM(memcpy)
	ldr     r3, [r1], #4
	str     r3, [r0], #4
	subs    r2, r2, #4
    bgt     _memcpy
    bx      lr

.align 12
/*
 * The real vector table for this thing.
 */
EnterARM(real_vector_table)
    b       _real_secure_reset_tramp
    b       _real_secure_undef_tramp
    b       _real_secure_smc_tramp
    b       _real_secure_prefetch_tramp
    b       _real_secure_abort_tramp
    nop                                            /* Unused, address line exception. */
    b       _real_secure_irq_tramp
    b       _real_secure_fiq_tramp

/*
 * Stacks and saveareas for register states.
 */
    .data
    .align 4

#define DeclareStack(stackname, size)  \
    .globl _ ##stackname;              \
    _ ##stackname:;                    \
        .rept size;                    \
        .byte 0;                       \
        .endr;                         \
    _ ##stackname ##_end:

DeclareStack(secure_stackptr_svc, STACK_SIZE)
DeclareStack(secure_stackptr_mon, STACK_SIZE)
DeclareStack(secure_stackptr_irq, EXCPT_STACK_SIZE)
DeclareStack(secure_stackptr_abt, EXCPT_STACK_SIZE)
DeclareStack(secure_stackptr_und, EXCPT_STACK_SIZE)

