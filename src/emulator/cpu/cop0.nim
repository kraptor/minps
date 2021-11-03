# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental:"codeReordering".}


import strformat

import ../../core/log
import ../../core/util

logChannels ["cop0"]

const
    PRID_RESET_VALUE = Cop0PRIDRegister(
        Revision: 0x2,
        Implementation: 0,
        NotUsed: 0
    )

type 
    Cop0RegisterIndex* = 0..31

    Cop0RegisterArray* = array[Cop0RegisterIndex, uint32]

    Cop0RegistersParts* = object
        r0, r1, r2: uint32
        BPC       : uint32 # Breakpoint on Execute Address Register
        r4        : uint32
        BDA       : uint32 # Breakpoint on Data Access Address Register
        JUMPDEST  : uint32
        DCIC      : Cop0DCICRegister # Debug and Cache Invalidate Control Register
        BadVaddr  : uint32
        BDAM      : uint32 # Breakpoint on Data Access Mask Register
        r10       : uint32 #
        BPCM      : uint32 # Breakpoint on Execute Mas Register
        SR        : Cop0SystemStatusRegister # System Status Register
        CAUSE     : Cop0CauseRegister # Exception Cause Register
        EPC       : uint32 # Return address from exception
        PRID      : Cop0PRIDRegister # Processor ID
        r16, r17, r18, r19, r20, r21, r22, r23: uint32
        r24, r25, r26, r27, r28, r29, r30, r31: uint32
    
    Cop0* {.union.} = object
        regs  *: Cop0RegisterArray
        parts *: Cop0RegistersParts

    Cop0RegisterName* {.pure.} = enum
        r0, r1, r2, BPC, r4, BDA, JUMPDEST, DCIC,
        BadVaddr, BDAM, r10, BPCM, SR, CAUSE, EPC, PRID,
        r16, r17, r18, r19, r20, r21, r22, r23,
        r24, r25, r26, r27, r28, r29, r30, r31

type
    InterruptEnableMode* {.pure.} = enum
        Disabled = 0
        Enabled

    KernelUserMode* {.pure.} = enum
        Kernel = 0
        User

    SwappedCacheMode {.pure.} = enum
        Normal = 0
        Swapped

    BootExceptionVectorLocation* {.pure.} = enum
        RAM_KSEG0
        ROM_KSEG1

    Unused8 = uint8

    CoprocessorEnableMode {.pure.} = enum
        KernelOnly = 0
        KernelAndUser

    Cop0SystemStatusRegister* {.packed.} = object   # APU Status Register
        IEc     *{.bitsize: 1.}: InterruptEnableMode # Current Interrupt Enable
        KUc     *{.bitsize: 1.}: KernelUserMode      # Current Kernel/User Mode
        IEp     *{.bitsize: 1.}: InterruptEnableMode # Previous Interrupt Enable
        KUp     *{.bitsize: 1.}: KernelUserMode      # Previous Kernel/User Mode
        IEo     *{.bitsize: 1.}: InterruptEnableMode # Old Interrupt Enable
        KUo     *{.bitsize: 1.}: KernelUserMode      # Old Kernel/User Mode
        U_06_07 *{.bitsize: 2.}: Unused8
        Im      *{.bitsize: 8.}: uint8               # 8bit Interrupt Mask
        Isc     *{.bitsize: 1.}: bool                # Isolate Cache
        Swc     *{.bitsize: 1.}: SwappedCacheMode    # Swapped cache mode
        PZ      *{.bitsize: 1.}: bool                # If set, parity bits are written as 0
        CM      *{.bitsize: 1.}: bool                # Shows the result of the last load operation with the D-cache
                                                     #   isolated. It gets set if the cache really contained data
                                                     #   for the addressed memory location.
        PE      *{.bitsize: 1.}: bool                # Cache parity error
        TS      *{.bitsize: 1.}: bool                # TLB shutdown. Gets set if a programm address simultaneously
                                                     #   matches 2 TLB entries. (initial value on reset allows to 
                                                     #   detect extended CPU version?)
        BEV     *{.bitsize: 1.}: BootExceptionVectorLocation
        U_23_24  {.bitsize: 2.}: Unused8
        RE      *{.bitsize: 1.}: bool                # Reverse Endianess
        U_26_27  {.bitsize: 2.}: Unused8
        CU0     *{.bitsize: 1.}: CoprocessorEnableMode
        CU1     *{.bitsize: 1.}: CoprocessorEnableMode
        CU2     *{.bitsize: 1.}: CoprocessorEnableMode
        CU3     *{.bitsize: 1.}: CoprocessorEnableMode


type 
    JumpRedirectionMode* {.pure.} = enum
        Disabled
        Enabled01
        Enabled02
        Enabled03

    Cop0DCICRegister* {.packed.} = object # Debug and Cache Invalidate Control Register
        DB      {.bitsize: 1.}: bool # Any break - Debug flag, set to true when detected any debug condition
        PC      {.bitsize: 1.}: bool # BPC Code Break - Set on PC debug condition
        DA      {.bitsize: 1.}: bool # BDA Data Break - Set on Data address debug condition
        R       {.bitsize: 1.}: bool # BDA Data READ Break
        W       {.bitsize: 1.}: bool # BDA Data WRITE Break
        T       {.bitsize: 1.}: bool # Jump Break
        ZERO_06_11      {.bitsize: 6.}: uint8 # Always read as zero. Writes are ignored.
        JumpRedirection {.bitsize: 2.}: JumpRedirectionMode
        UNKNOWN_14_15   {.bitsize: 2.}: uint8 
        ZERO_16_22      {.bitsize: 7.}: uint8
        DE      {.bitsize: 1.}: bool # Debug Enable - Super-Master Enable 1 for bit 24 - 29
        PCE     {.bitsize: 1.}: bool # Execution Breakpoint - Program Counter Breakpoint Enable
        DAE     {.bitsize: 1.}: bool # Data Access Breakpoint Enable
        DR      {.bitsize: 1.}: bool # Data Read Enable - Break on data read
        DW      {.bitsize: 1.}: bool # Data Write Enable
        TE      {.bitsize: 1.}: bool # Trace Enable - Break on any jump
        KD      {.bitsize: 1.}: bool # Kernel Debug Enable
        UD      {.bitsize: 1.}: bool # User Debug Enable
        TR      {.bitsize: 1.}: bool # Trap Enable

type
    ExceptionCode* {.pure.} = enum
        Interrupt                  = 0x00 # Interrupt
        TLB_Modification           = 0x01 # TLB Modification
        TLB_Load                   = 0x02 # TLB load
        TLB_Store                  = 0x03 # TLB store
        AddressError_Load          = 0x04 # Address error, data load or instruction fetch
        AddressError_Store         = 0x05 # Address error, data store
        BusError_InstructionFetch  = 0x06 # Bus error on Instruction fetch
        BusError_DataLoadStore     = 0x07 # Bus error on Data load/store
        Syscall                    = 0x08 # Generated unconditionally by syscall instruction
        Breakpoint                 = 0x09 # Breakpoint
        ReservedInstruction        = 0x0A # Reserved Instruction
        CoprocesorUnusable         = 0x0B # Coprocesor unusable
        ArithmeticOverflow         = 0x0C # Arithmetic overflow

    SoftwareInterruptCode* {.pure.} = enum
        None = 0b00
        Sw1  = 0b01
        Sw2  = 0b10
        Sw1AndSw2 = 0b11

    CoprocessorErrorCode* {.pure.} = enum
        Cop0, Cop1, Cop2, Cop3

    Cop0CauseRegister* {.packed.} = object
        RESERVED_00_01      {.bitsize:  1.}: uint8
        exception_code     *{.bitsize:  5.}: ExceptionCode
        RESERVED_06_07      {.bitsize:  1.}: uint8
        software_interrutps*{.bitsize:  2.}: SoftwareInterruptCode
        interrupt_pending  *{.bitsize:  6.}: uint8
        UNUSED_16_27       *{.bitsize: 12.}: uint16
        coprocessor_error  *{.bitsize:  2.}: CoprocessorErrorCode
        branch_taken       *{.bitsize:  1.}: bool
        branch_delay       *{.bitsize:  1.}: bool

type
    Cop0PRIDRegister* {.packed.} = object
        Revision       *{.bitsize: 8.}: uint8
        Implementation *{.bitsize: 8.}: uint8
        NotUsed        *{.bitsize:16.}: uint16


proc PRID *(cop0: var Cop0): var Cop0PRIDRegister = cop0.parts.PRID


proc CAUSE *(cop0: var Cop0): var Cop0CauseRegister = cop0.parts.CAUSE
proc SR    *(cop0: var Cop0): var Cop0SystemStatusRegister = cop0.parts.SR
proc `SR=` *(cop0: var Cop0, v: uint32) = cop0.parts.SR = cast[Cop0SystemStatusRegister](v)
proc EPC   *(cop0: var Cop0): uint32 = cop0.parts.EPC
proc `EPC=`*(cop0: var Cop0, v: uint32) = cop0.parts.EPC = v

proc IsolateCacheEnabled*(cop0: var Cop0): bool = cop0.parts.SR.Isc


proc GetCop0RegisterAlias*(r: Cop0RegisterIndex): string =
    const COP0_REGISTER_TO_ALIAS = [
        "$0"      , "$1"  , "$2" , "BPC" , "$4" , "BDA"  , "JUMPDEST", "DCIC", 
        "BadVaddr", "BDAM", "$10", "BPCM", "SR" , "CAUSE", "EPC"     , "PRID", 
        "$16"     , "$17" , "$18", "$19" , "$20", "$21"  , "$22"     , "$23", 
        "$24"     , "$25" , "$26", "$27" , "$28", "$29"  , "$30"     , "$31"]
    COP0_REGISTER_TO_ALIAS[r]


proc ReadRegisterDebug*(self: var Cop0, r: Cop0RegisterName): uint32 =
    ReadRegisterDebug(self, r.ord)


proc ReadRegisterDebug*(self: var Cop0, r: Cop0RegisterIndex): uint32 = 
    case r.Cop0RegisterName:
    of r0, r1, r2, r4, r10:
        # TODO: raise a Reserved Instruction Exception (excode=0Ah)
        NOT_IMPLEMENTED fmt"cop0[{r.Cop0RegisterName}] read."
    of r16 .. r31:
        # TODO: return garbage, but don't trigger exception
        NOT_IMPLEMENTED fmt"cop0[{r.Cop0RegisterName}] read."
    else:
        warn fmt"cop0[{r.Cop0RegisterName}] read."
        return self.regs[r]


proc WriteRegisterDebug*(self: var Cop0, r: Cop0RegisterName, v: uint32) =
    WriteRegisterDebug(self, r.ord, v)


proc WriteRegisterDebug*(self: var Cop0, r: Cop0RegisterIndex, v: uint32) =
    case r.Cop0RegisterName:
    of Cop0RegisterName.BPC:
        self.regs[r] = v
        notice fmt"Cop0 BPC Register set to: {v:08x}h"
        warn fmt"cop0[{r.GetCop0RegisterAlias}] set to: {v:08x}h. Side-effects are not implemented."
    of Cop0RegisterName.BDA:
        self.regs[r] = v
        notice fmt"Cop0 BDA Register set to: {v:08x}h"
        warn fmt"cop0[{r.GetCop0RegisterAlias}] set to: {v:08x}h. Side-effects are not implemented."
    of Cop0RegisterName.JUMPDEST:
        # JUMPDEST is read-only
        # self.regs[r] = v
        warn fmt"cop0[{r.GetCop0RegisterAlias}] attempted write: value={v:08x}h. Ignored write."
    of Cop0RegisterName.BDAM:
        self.regs[r] = v
        notice fmt"Cop0 BDAM Register set to: {v:08x}h"
        warn fmt"cop0[{r.GetCop0RegisterAlias}] set to: {v:08x}h. Side-effects are not implemented."
    of Cop0RegisterName.BPCM:
        self.regs[r] = v
        notice fmt"Cop0 Breakpoint On Execute Mask Register set to: {v:08x}h."
        warn fmt"cop0[{r.GetCop0RegisterAlias}] set to: {v:08x}h. Side-effects are not implemented."
    of Cop0RegisterName.CAUSE:
        notice fmt"Cop0 Exception Cause Register set to: {v:08x}h."
        # Only bits 8 and 9 are writable
        const WRITE_MASK = (0b11 shl 8)
        self.regs[r] = v and WRITE_MASK
        warn fmt"cop0[{r.GetCop0RegisterAlias}] set to: {v:08x}h. Side-effects are not implemented."
    of Cop0RegisterName.SR:
        self.regs[r] = v
        var sr = self.parts.SR

        # TS bit is always 0 as per documentation
        assert sr.TS == false, "Cop0.SR.TS is read-only. Use cop0.SetTLBShutdown(true) from emu code instead?"
        sr.TS = false

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

        warn fmt"cop0[{r.GetCop0RegisterAlias}] set to: {v:08x}h. Side-effects are not implemented."
    of Cop0RegisterName.DCIC:
        self.regs[r] = v
        var dcic = self.parts.DCIC

        # TODO: use here a mask if this is ever a bottleneck
        dcic.ZERO_06_11 = 0
        dcic.ZERO_16_22 = 0

        notice fmt"Cop0 Debug Register (DCIC) set to: {v:08x}h"
        notice fmt"- DB (Debug)              : {dcic.DB}"
        notice fmt"- PC (Program Counter)    : {dcic.PC}"
        notice fmt"- DA (Data Address)       : {dcic.DA}"
        notice fmt"- R  (Read Reference)     : {dcic.R}"
        notice fmt"- W  (Write Reference)    : {dcic.W}"
        notice fmt"- T  (Trace)              : {dcic.T}"
        # notice fmt"- ZERO_06_11      : {dcic.ZERO_06_11}"
        notice fmt"- Jump Redirection        : {dcic.JumpRedirection}"
        notice fmt"- UNKNOWN_14_15           : {dcic.UNKNOWN_14_15}"
        # notice fmt"- ZERO_16_22      : {dcic.ZERO_16_22}"
        notice fmt"- DE (Debug Enable)       : {dcic.DE}"
        notice fmt"- PCE (PC Break Enable)   : {dcic.PCE}"
        notice fmt"- DAE (DA Break Enable)   : {dcic.DAE}"
        notice fmt"- DR (Data Read Enable)   : {dcic.DR}"
        notice fmt"- DW (Data Write Enable)  : {dcic.DW}"
        notice fmt"- TE (Trace Enable)       : {dcic.TE}"
        notice fmt"- KD (Kernel Debug Enable): {dcic.KD}"
        notice fmt"- UD (User Debug Enable)  : {dcic.UD}"
        notice fmt"- TR (Trap Enable)        : {dcic.TR}"

        warn fmt"cop0[{r.GetCop0RegisterAlias}] set to: {v:08x}h. Side-effects are not implemented."
    else:
        NOT_IMPLEMENTED fmt"Cop0[{r.GetCop0RegisterAlias}] Register write not implemented: {r.Cop0RegisterName}"


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


proc Reset*(self: var Cop0) =
    self.regs.reset()
    self.parts.PRID = PRID_RESET_VALUE
    warn "Reset: COP0 State not fully initialized."
