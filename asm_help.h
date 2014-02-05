/*
 * Copyright 2013, winocm. <winocm@icloud.com>
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification,
 * are permitted provided that the following conditions are met:
 * 
 *   Redistributions of source code must retain the above copyright notice, this
 *   list of conditions and the following disclaimer.
 * 
 *   Redistributions in binary form must reproduce the above copyright notice, this
 *   list of conditions and the following disclaimer in the documentation and/or
 *   other materials provided with the distribution.
 * 
 *   If you are going to use this software in any form that does not involve
 *   releasing the source to this project or improving it, let me know beforehand.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/*
 * ASM helper functions
 */

#ifndef _ARM_ASM_HELP_H_
#define _ARM_ASM_HELP_H_

/*
 * LLVM-AS is a horrible sin upon humanity.
 */
#define LoadConstantToReg(_Data, _Reg)  \
  ldr  _Reg, [pc, #0]   ;               \
  b    1f               ;               \
  .long (_Data)         ;               \
1:

/*
 * Procedure enter and exit for both ARM and thumb states.
 */
#define EnterARM(function)              \
    .code 32                        ;   \
    .globl _ ##function             ;   \
    .align  4                       ;   \
    _##function:                    ;   \

#define EnterThumb(function)        ;   \
    .code 16                        ;   \
    .thumb_func _ ##function        ;   \
    .globl _ ##function             ;   \
    .align  4                       ;   \
    _##function:                    ;   \

#define EnterARM_NoAlign(function)      \
    .code 32                        ;   \
    .globl _ ##function             ;   \
    _##function:                    ;   \

#define EnterThumb_NoAlign(function)    \
    .code 16                        ;   \
    .thumb_func _ ##function        ;   \
    .globl _ ##function             ;   \
    _##function:                    ;   \

/* AArch64 stuff */
#ifdef _ARM_ARCH_8
#undef EnterARM
#undef EnterThumb
#undef EnterARM_NoAlign
#undef EnterThumb_NoAlign

#define EnterAArch64(function)          \
    .align 6                        ;   \
    .globl _ ##function             ;   \
    _##function:                    ;

#define EnterAArch64_NoAlign(function)  \
    .align 6                        ;   \
    .globl _ ##function             ;   \
    _##function:                    ;

#define EnterARM_NoAlign    EnterAArch64_NoAlign
#define EnterThumb_NoAlign  EnterAArch64_NoAlign
#define EnterARM            EnterAArch64
#define EnterThumb          EnterAArch64
#endif

/*
 * CPSR definitions.
 */

#define MODE_USR            0x10
#define MODE_FIQ            0x11
#define MODE_IRQ            0x12
#define MODE_SVC            0x13
#define MODE_ABT            0x17
#define MODE_UND            0x1B
#define MODE_SYS            0x1F
#define MODE_MON            0x16

#define NS_BIT              0x01
#define MMUEN_BIT           0x01

#endif
