# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental:"codeReordering".}


import strformat

import ../../core/log
import ../../core/util

logChannels ["cop0"]


type 
    Cop0RegisterIndex* = 0..31

    Cop0RegisterArray* = array[Cop0RegisterIndex, uint32]

    Cop0RegistersParts* = object
        r0, r1, r2: uint32
        BPC: uint32
        r4: uint32
        BDA: uint32
        JUMPDEST: uint32
        DCIC: uint32
        BadVaddr: uint32
        BDAM: uint32
        r10: uint32
        BPCM: uint32
        SR: Cop0SystemStatusRegister
        CAUSE: uint32
        EPC: uint32
        PRID: uint32
        r16, r17, r18, r19, r20, r21, r22, r23: uint32
        r24, r25, r26, r27, r28, r29, r30, r31: uint32
    
    Cop0* {.union.} = object
        regs*: Cop0RegisterArray
        parts*: Cop0RegistersParts

    Cop0RegisterName {.pure.} = enum
        r0, r1, r2, BPC, r4, BDA, JUMPDEST, DCIC,
        BadVaddr, BDAM, r10, BPCM, SR, CAUSE, EPC, PRID,
        r16, r17, r18, r19, r20, r21, r22, r23,
        r24, r25, r26, r27, r28, r29, r30, r31

type
    InterruptEnableMode {.pure.} = enum
        Disabled = 0
        Enabled

    KernelMode {.pure.} = enum
        Kernel = 0
        User

    SwappedCacheMode {.pure.} = enum
        Normal = 0
        Swapped

    BootExceptionVectorLocation {.pure.} = enum
        RAM_KSEG0
        ROM_KSEG1

    Unused8 = uint8

    CoprocessorEnableMode {.pure.} = enum
        KernelOnly = 0
        KernelAndUser

    Cop0SystemStatusRegister* {.packed.} = object
        IEc     {.bitsize: 1.}: InterruptEnableMode # Current Interrupt Enable
        KUc     {.bitsize: 1.}: KernelMode          # Current Kernel/User Mode
        IEp     {.bitsize: 1.}: InterruptEnableMode # Previous Interrupt Enable
        KUp     {.bitsize: 1.}: KernelMode          # Previous Kernel/User Mode
        IEo     {.bitsize: 1.}: InterruptEnableMode # Old Interrupt Enable
        KUo     {.bitsize: 1.}: KernelMode          # Old Kernel/User Mode
        U_06_07 {.bitsize: 2.}: Unused8
        Im      {.bitsize: 8.}: uint8               # 8bit Interrupt Mask
        Isc     {.bitsize: 1.}: bool                # Isolate Cache
        Swc     {.bitsize: 1.}: SwappedCacheMode    # Swapped cache mode
        PZ      {.bitsize: 1.}: bool                # If set, parity bits are written as 0
        CM      {.bitsize: 1.}: bool                # Shows the result of the last load operation with the D-cache
                                                    #   isolated. It gets set if the cache really contained data
                                                    #   for the addressed memory location.
        PE      {.bitsize: 1.}: bool                # Cache parity error
        TS      {.bitsize: 1.}: bool                # TLB shutdown. Gets set if a programm address simultaneously
                                                    #   matches 2 TLB entries. (initial value on reset allows to 
                                                    #   detect extended CPU version?)
        BEV     {.bitsize: 1.}: BootExceptionVectorLocation
        U_23_24 {.bitsize: 2.}: Unused8
        RE      {.bitsize: 1.}: bool                # Reverse Endianess
        U_26_27 {.bitsize: 2.}: Unused8
        CU0     {.bitsize: 1.}: CoprocessorEnableMode
        CU1     {.bitsize: 1.}: CoprocessorEnableMode
        CU2     {.bitsize: 1.}: CoprocessorEnableMode
        CU3     {.bitsize: 1.}: CoprocessorEnableMode


proc GetCop0RegisterAlias*(r: Cop0RegisterIndex): string =
    const COP0_REGISTER_TO_ALIAS = [
        "$0"      , "$1"  , "$2" , "BPC" , "$4" , "BDA"  , "JUMPDEST", "DCIC", 
        "BadVaddr", "BDAM", "$10", "BPCM", "SR" , "CAUSE", "EPC"     , "PRID", 
        "$16"     , "$17" , "$18", "$19" , "$20", "$21"  , "$22"     , "$23", 
        "$24"     , "$25" , "$26", "$27" , "$28", "$29"  , "$30"     , "$31"]
    COP0_REGISTER_TO_ALIAS[r]
    

proc ReadRegisterDebug*(self: var Cop0, r: Cop0RegisterIndex): uint32 = 
    case r.Cop0RegisterName:
    of r0, r1, r2, r4, r10:
        # TODO: raise a Reserved Instruction Exception (excode=0Ah)
        NOT_IMPLEMENTED
    of r16 .. r31:
        # TODO: return garbage, but don't trigger exception
        NOT_IMPLEMENTED
    else:
        return self.regs[r]


proc WriteRegisterDebug*(self: var Cop0, r: Cop0RegisterIndex, v: uint32) =
    self.regs[r] = v

    case r.Cop0RegisterName:
    of SR:
        let sr = self.parts.SR
        notice fmt"Cop0 Status Register set to: {v:08x}h"
        notice fmt"- IEc (Current)    : {sr.IEc}"
        notice fmt"- KUc (Current)    : {sr.KUc}"
        notice fmt"- IEp (Previous)   : {sr.IEp}"
        notice fmt"- KUp (Previous)   : {sr.KUp}"
        notice fmt"- IEo (Old)        : {sr.IEo}"
        notice fmt"- KUo (Old)        : {sr.KUo}"
        notice fmt"- Interrupt Mask   : {sr.Im:08x}h"
        notice fmt"- Isolate Cache    : {sr.Isc}"
        notice fmt"- Swapped Cache    : {sr.Swc}"
        notice fmt"- PZ               : {sr.PZ}"
        notice fmt"- CM               : {sr.CM}"
        notice fmt"- PE (Parity Error): {sr.PE}"
        notice fmt"- TS (TLB Shutdown): {sr.TS}"
        notice fmt"- BEV (Exc. Vector): {sr.BEV}"
        notice fmt"- RE (Endianess)   : {sr.RE}"
        notice fmt"- CU0 (COP0 Mode)  : {sr.CU0}"
        notice fmt"- CU1 (COP1 Mode)  : {sr.CU1}"
        notice fmt"- CU2 (COP2 Mode)  : {sr.CU2}"
        notice fmt"- CU3 (COP3 Mode)  : {sr.CU3}"

        warn fmt"cop0reg[SR] set to: {v:08x}h. Side-effects are not implemented."
    else:
        NOT_IMPLEMENTED


proc WriteRegister*(self: var Cop0, r: Cop0RegisterIndex, v: uint32) =
    let 
        alias = GetCop0RegisterAlias(r)
        prev_value = self.regs[r]

    trace fmt"write cop0reg[{alias}] {alias}=${r} value={v:08x}h (was={prev_value:08x}h)"
    self.WriteRegisterDebug(r, v)


proc ReadRegister*(self: var Cop0, r: Cop0RegisterIndex): uint32 = 
    let alias = GetCop0RegisterAlias(r)
    trace fmt"read cop0reg[{alias}] {alias}=${r} value={self.regs[r]:08x}h"
    ReadRegisterDebug(self, r)


proc Reset*(self: Cop0) =
    warn "Reset: COP0 State not fully initialized."