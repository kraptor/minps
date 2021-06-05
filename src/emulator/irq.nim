# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../core/[log, util]
import address

logChannels ["irq"]


const
    IC_MAX_SIZE = 4

    # device regions (in kuseg when possible)
    IC_START* = (Address 0x1F80_1070).toKUSEG()
    IC_END* = KusegAddress IC_START.uint32 + IC_MAX_SIZE

type
    InterruptRegisterParts {.packed.} = object
        IRQ0_VBLANK               {.bitsize:  1.}: bool
        IRQ1_GPU                  {.bitsize:  1.}: bool
        IRQ2_CDROM                {.bitsize:  1.}: bool
        IRQ3_DMA                  {.bitsize:  1.}: bool
        IRQ4_TIMER0               {.bitsize:  1.}: bool
        IRQ5_TIMER1               {.bitsize:  1.}: bool
        IRQ6_TIMER2               {.bitsize:  1.}: bool
        IRQ7_CONTROLLER_MC        {.bitsize:  1.}: bool
        IRQ8_SIO                  {.bitsize:  1.}: bool
        IRQ9_SPU                  {.bitsize:  1.}: bool
        IRQ10_CONTROLLER_LIGHTPEN {.bitsize:  1.}: bool
        UNUSED_11_15              {.bitsize:  5.}: uint8
        GARBAGE                   {.bitsize: 16.}: uint16

    InterruptRegister {.union.} = object
        value: uint32
        parts: InterruptRegisterParts

    InterruptControl* = ref object
        I_STAT: InterruptRegister
        I_MASK: InterruptRegister


proc New*(T: type InterruptControl): InterruptControl =
    debug "Creating InterruptControl..."
    logIndent:
        result = InterruptControl()
        debug "InterruptControl created!"


proc Reset*(self: InterruptControl) =
    debug "Resetting InterruptControl..."
    logIndent:
        # TODO: reset Expansion 1 devices here if it's ever implemented
        debug("InterruptControl Resetted.")


proc Read*[T: uint8|uint16|uint32](self: InterruptControl, address: KusegAddress): T =
    assert is_aligned[T](address)

    when T is uint32:
        case address.uint32:
        of 0x1F80_1074: 
            warn fmt"IC/I_MASK read: value={self.I_MASK:08x}"
            return self.I_MASK.value
        else:
            discard

    NOT_IMPLEMENTED fmt"InterruptControl Read[{$T}]: address={address}"


proc Write*[T: uint8|uint16|uint32](self: InterruptControl, address: KusegAddress, value: T) =
    assert is_aligned[T](address)

    when T is uint32:
        case address.uint32:
        of 0x1F80_1070: 
            self.I_STAT.value = value
            warn fmt"IC/I_STAT set to value: {value:08x}h. Side.effects not implemented."
            notice fmt"- IRQ0  (vblank) Active: {self.I_STAT.parts.IRQ0_VBLANK}"
            notice fmt"- IRQ1  (GPU)    Active: {self.I_STAT.parts.IRQ1_GPU}"
            notice fmt"- IRQ2  (CDROM)  Active: {self.I_STAT.parts.IRQ2_CDROM}"
            notice fmt"- IRQ3  (DMA)    Active: {self.I_STAT.parts.IRQ3_DMA}"
            notice fmt"- IRQ4  (TIMER0) Active: {self.I_STAT.parts.IRQ4_TIMER0}"
            notice fmt"- IRQ5  (TIMER1) Active: {self.I_STAT.parts.IRQ5_TIMER1}"
            notice fmt"- IRQ6  (TIMER2) Active: {self.I_STAT.parts.IRQ6_TIMER2}"
            notice fmt"- IRQ7  (CNT_MC) Active: {self.I_STAT.parts.IRQ7_CONTROLLER_MC}"
            notice fmt"- IRQ8  (SIO)    Active: {self.I_STAT.parts.IRQ8_SIO}"
            notice fmt"- IRQ9  (SPU)    Active: {self.I_STAT.parts.IRQ9_SPU}"
            notice fmt"- IRQ10 (CNT_LP) Active: {self.I_STAT.parts.IRQ10_CONTROLLER_LIGHTPEN}"
            return
        of 0x1F80_1074: 
            self.I_MASK.value = value    
            warn fmt"IC/I_MASK set to value: {value:08x}h. Side-effects not implemented."
            notice fmt"- IRQ0  (vblank) Masked: {not self.I_MASK.parts.IRQ0_VBLANK}"
            notice fmt"- IRQ1  (GPU)    Masked: {not self.I_MASK.parts.IRQ1_GPU}"
            notice fmt"- IRQ2  (CDROM)  Masked: {not self.I_MASK.parts.IRQ2_CDROM}"
            notice fmt"- IRQ3  (DMA)    Masked: {not self.I_MASK.parts.IRQ3_DMA}"
            notice fmt"- IRQ4  (TIMER0) Masked: {not self.I_MASK.parts.IRQ4_TIMER0}"
            notice fmt"- IRQ5  (TIMER1) Masked: {not self.I_MASK.parts.IRQ5_TIMER1}"
            notice fmt"- IRQ6  (TIMER2) Masked: {not self.I_MASK.parts.IRQ6_TIMER2}"
            notice fmt"- IRQ7  (CNT_MC) Masked: {not self.I_MASK.parts.IRQ7_CONTROLLER_MC}"
            notice fmt"- IRQ8  (SIO)    Masked: {not self.I_MASK.parts.IRQ8_SIO}"
            notice fmt"- IRQ9  (SPU)    Masked: {not self.I_MASK.parts.IRQ9_SPU}"
            notice fmt"- IRQ10 (CNT_LP) Masked: {not self.I_MASK.parts.IRQ10_CONTROLLER_LIGHTPEN}"
            return
        else:
            discard
    
    NOT_IMPLEMENTED fmt"InterruptControl Write[{$T}]: address={address} value={value:08x}h"