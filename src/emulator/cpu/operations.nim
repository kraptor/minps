# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental:"codeReordering".}

import bitops
import strformat

import ../../core/log
import ../../core/util

import cpu
import cop0
import instruction
import disassembler

import ../mmu
import ../address
import ../bios/syscalls


logChannels ["cpu", "ops"]


type
    OperationProc = proc(cpu: Cpu): Cycles {.gcsafe.}


proc ExecuteNotImplemented(cpu: Cpu): Cycles {.used.} = 
    logIndent:
        trace fmt"{cpu.inst}"
        trace fmt"{cpu.inst.value:032b}"
    NOT_IMPLEMENTED fmt"Opcode not implemented: {cpu.inst.opcode}"


proc ExecuteCop0NotImplemented(cpu: Cpu): Cycles {.used.} =
    logIndent:
        trace fmt"{cpu.inst}"
        trace fmt"{cpu.inst.value:032b}"        
    NOT_IMPLEMENTED fmt"Cop0 Opcode not implemented: {cpu.inst.rs.Cop0Opcode}"


proc ExecuteFunctionNotImplemented(cpu: Cpu): Cycles {.used.} = 
    logIndent:
        trace fmt"{cpu.inst}"
        trace fmt"{cpu.inst.value:032b}"
    NOT_IMPLEMENTED fmt"Function Opcode not implemented: {cpu.inst.function}"


const OPCODES = block:
    var o: array[Opcode.high.ord, OperationProc] 
    for x in o.mitems: x = ExecuteNotImplemented
    o[ord Opcode.LUI    ] = Op_LUI
    o[ord Opcode.ORI    ] = Op_ORI
    o[ord Opcode.SW     ] = Op_Store[uint32]
    o[ord Opcode.Special] = Op_Special
    o[ord Opcode.ADDIU  ] = Op_ADDIU
    o[ord Opcode.J      ] = Op_J
    o[ord Opcode.COP0   ] = Op_COP0
    o[ord Opcode.BNE    ] = Op_BNE
    o[ord Opcode.ADDI   ] = Op_ADDI
    o[ord Opcode.LW     ] = Op_LW
    o[ord Opcode.SH     ] = Op_Store[uint16]
    o[ord Opcode.JAL    ] = Op_JAL
    o[ord Opcode.ANDI   ] = Op_ANDI
    o[ord Opcode.SB     ] = Op_Store[uint8]
    o[ord Opcode.LB     ] = Op_LB
    o[ord Opcode.BEQ    ] = Op_BEQ
    o[ord Opcode.BGTZ   ] = Op_BGTZ
    o[ord Opcode.BLEZ   ] = Op_BLEZ
    o[ord Opcode.LBU    ] = Op_LBU
    o[ord Opcode.BCONDZ ] = Op_BCONDZ
    o[ord Opcode.SLTI   ] = Op_SLTI
    o[ord Opcode.SLTIU  ] = Op_SLTIU
    o # return the array


const FUNCTIONS = block:
    var f: array[Function.high.ord, OperationProc]
    for x in f.mitems: x = ExecuteFunctionNotImplemented
    f[ord Function.SLL    ] = Function_SLL
    f[ord Function.OR     ] = Function_OR
    f[ord Function.SLTU   ] = Function_SLTU
    f[ord Function.ADDU   ] = Function_ADDU
    f[ord Function.JR     ] = Function_JR
    f[ord Function.AND    ] = Function_AND
    f[ord Function.ADD    ] = Function_ADD
    f[ord Function.JALR   ] = Function_JALR
    f[ord Function.SUBU   ] = Function_SUBU
    f[ord Function.SRA    ] = Function_SRA
    f[ord Function.DIV    ] = Function_DIV
    f[ord Function.MFLO   ] = Function_MFLO
    f[ord Function.MFHI   ] = Function_MFHI
    f[ord Function.SRL    ] = Function_SRL
    f[ord Function.DIVU   ] = Function_DIVU
    f[ord Function.SLT    ] = Function_SLT
    f[ord Function.Syscall] = Function_Syscall
    f # return the array


const COP0_OPCODES = block:
    var o: array[Cop0Opcode.high.ord, OperationProc]
    for x in o.mitems: x = ExecuteCop0NotImplemented
    o[ord Cop0Opcode.MTC] = Op_MTC0
    o[ord Cop0Opcode.MFC] = Op_MFC0
    o


# Utility functions to support operations
proc BranchWithDelaySlotTo*(cpu: Cpu, target: Address) =
    cpu.inst_is_branch = true
    cpu.pc_next = target
    trace fmt"CPU will branch to: {target} after the delay slot."


proc RaiseException*(cpu: Cpu, exception_code: ExceptionCode) =
    #[ 
        When an exception happens, we need to update the following
        cop0 registers:
            - cop0.CAUSE: update the exception code
            - cop0.SR: update IEc/KUc/IEp/KUp/IEo/KUo by shifting
                their values to the left: IEc = IEp, KUc = KUp, etc.
            - cop0.EPC: the PC when the exception happens, should
                be adjusted when PC is withing a GTE instruction or
                a in a Delay Slot.
        Afterwards, we should jump to the corresponding exception 
        vector, depending on the value of bit cop0.SR.BEV.
    ]#
    
    cpu.cop0.CAUSE.exception_code = exception_code
    cpu.cop0.CAUSE.branch_delay = cpu.inst_in_delay
    
    # TODO: adjust this if GTE instruction.
    cpu.cop0.EPC = 
        if cpu.inst_in_delay:
            cpu.inst_pc - 4
        else:
            cpu.inst_pc

    # Shift enable/mode and kerne/user mode bits
    const 
        mask = 0b111111'u32
        
    var sr = cast[uint32](cpu.cop0.SR)
    let new_mode = (sr shl 2) and mask

    sr.clearMask(mask)
    cpu.cop0.SR = sr or new_mode

    const
        RAM_VECTOR = 0x8000_0000.Address
        ROM_VECTOR = 0xBFC0_0180.Address
    
    let 
        BEV = cpu.cop0.SR.BEV
        exception_vector = if BEV == RAM_KSEG0: RAM_VECTOR else: ROM_VECTOR
        
    # jump direcly to the exception vector
    cpu.pc = exception_vector
    # cpu.pc_next = exception_vector + 4
    # cpu.inst = Instruction.New(cpu.mmu.Read32(cpu.pc))
    # cpu.inst_pc = cpu.pc


proc Execute*(cpu: Cpu): Cycles =
    # TODO: return number of cycles
    
    debug fmt"Execute: {cpu.inst.DisasmAsText(cpu)}"
    if cpu.echo_intructions:
        echo fmt"{cpu.inst_pc} - Execute: {cpu.inst.DisasmAsText(cpu)}"
    logIndent:
        result = OPCODES[ord cpu.inst.opcode] cpu


proc Op_Special(cpu: Cpu): Cycles =
    result = FUNCTIONS[ord cpu.inst.function] cpu


proc Op_COP0(cpu: Cpu): Cycles = 
    result = COP0_OPCODES[ord cpu.inst.rs.Cop0Opcode] cpu


proc Op_LUI(cpu: Cpu): Cycles = 
    let
        rt = cpu.inst.rt
        value = cpu.inst.imm16.zero_extend shl 16

    cpu.WriteRegister(rt, value)
    result = 1
    

proc Op_ORI(cpu: Cpu): Cycles =
    let
        rt = cpu.inst.rt
        rs = cpu.inst.rs
        value = cpu.ReadRegister(rs) or cpu.inst.imm16.zero_extend

    cpu.WriteRegister(rt, value)
    result = 1


proc Op_Store[T: uint8|uint16|uint32](cpu: Cpu): Cycles =
    let
        base = cpu.ReadRegister(cpu.inst.rs)
        offset = cpu.inst.imm16.sign_extend
        address = Address offset + base
        value = cast[T](cpu.ReadRegister(cpu.inst.rt))

    if unlikely(not is_aligned[T](address)):
        NOT_IMPLEMENTED fmt"Store[{$T}] Address is not aligned: {address}"

    if unlikely(cpu.cop0.IsolateCacheEnabled):
        # TODO: implement cache in CPU for writes
        warn fmt"Store[{$T}] Attempt to write with Disable Cache enabled!"
        return

    # TODO: account for write to memory cycles?
    Write[T](cpu.mmu, address, value)
    result = 1


proc Op_LW(cpu: Cpu): Cycles =
    let
        base = cpu.ReadRegister(cpu.inst.rs)
        offset = cpu.inst.imm16.sign_extend
        address = Address offset + base

    if unlikely(not is_aligned[uint32](address)):
        NOT_IMPLEMENTED fmt"Address is not aligned: {address}"

    if unlikely(cpu.cop0.IsolateCacheEnabled):
        # TODO: does IsolateCache affect loads??
        NOT_IMPLEMENTED

    let value = cpu.mmu.Read32(address)

    # loads are delayed by 1 cycle, so we initiate the load here
    cpu.BeginLoad(cpu.inst.rt, value)
    result = 1


proc Op_LB(cpu: Cpu): Cycles =
    let
        base = cpu.ReadRegister(cpu.inst.rs)
        offset = cpu.inst.imm16.sign_extend
        address = Address offset + base

    if unlikely(not is_aligned[uint8](address)):
        NOT_IMPLEMENTED fmt"Address is not aligned: {address}"

    if unlikely(cpu.cop0.IsolateCacheEnabled):
        # TODO: does IsolateCache affect loads??
        NOT_IMPLEMENTED

    let value = cpu.mmu.Read8(address).sign_extend

    # loads are delayed by 1 cycle, so we initiate the load here
    cpu.BeginLoad(cpu.inst.rt, value)
    result = 1


proc Op_LBU(cpu: Cpu): Cycles =
    let
        base = cpu.ReadRegister(cpu.inst.rs)
        offset = cpu.inst.imm16.sign_extend
        address = Address offset + base

    if unlikely(not is_aligned[uint8](address)):
        NOT_IMPLEMENTED fmt"Address is not aligned: {address}"

    if unlikely(cpu.cop0.IsolateCacheEnabled):
        # TODO: does IsolateCache affect loads??
        NOT_IMPLEMENTED

    let value = cpu.mmu.Read8(address).zero_extend

    # loads are delayed by 1 cycle, so we initiate the load here
    cpu.BeginLoad(cpu.inst.rt, value)
    result = 1


proc Function_SLL(cpu: Cpu): Cycles =
    let 
        rd = cpu.inst.rd
        rt = cpu.inst.rt
        value = cpu.ReadRegister(rt) shl cpu.inst.shamt

    cpu.WriteRegister(rd, value)
    result = 1


proc Function_SRA(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        rt = cpu.inst.rt
        value = cast[int32](cpu.ReadRegister(rt)) shr cpu.inst.shamt

    cpu.WriteRegister(rd, cast[uint32](value))
    result = 1


proc Function_SRL(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        rt = cpu.inst.rt
        value = cpu.ReadRegister(rt) shr cpu.inst.shamt

    cpu.WriteRegister(rd, value)
    result = 1


proc Function_SLTU(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        rs_value = cpu.ReadRegister(cpu.inst.rs)
        rt_value = cpu.ReadRegister(cpu.inst.rt)
            
    let value = if rs_value < rt_value: 1'u32  else: 0'u32
    cpu.WriteRegister(rd, value)
    result = 1


proc Function_SLT(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        rs_value = cast[int32](cpu.ReadRegister(cpu.inst.rs))
        rt_value = cast[int32](cpu.ReadRegister(cpu.inst.rt))
            
    let value = if rs_value < rt_value: 1'u32  else: 0'u32
    cpu.WriteRegister(rd, value)
    result = 1


proc Function_SUBU(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        rs_value = cpu.ReadRegister(cpu.inst.rs)
        rt_value = cpu.ReadRegister(cpu.inst.rt)

    let value = rs_value - rt_value
    cpu.WriteRegister(rd, value)
    result = 1
    

proc Function_ADDU(cpu: Cpu): Cycles =
    let 
        rd = cpu.inst.rd
        rs_value = cpu.ReadRegister(cpu.inst.rs)
        rt_value = cpu.ReadRegister(cpu.inst.rt)

    let value = rs_value + rt_value
    cpu.WriteRegister(rd, value)
    result = 1


proc Op_ADDIU(cpu: Cpu): Cycles =
    let
        rt = cpu.inst.rt
        rs = cpu.inst.rs

    let value = cpu.ReadRegister(rs) + cpu.inst.imm16.sign_extend
    cpu.WriteRegister(rt, value)
    result = 1


proc Op_J(cpu: Cpu): Cycles =
    let target = (cpu.inst.target shl 2) or (0xF000_0000'u32 and cpu.pc + 4)
    cpu.BranchWithDelaySlotTo(cast[Address](target))
    result = 1


proc Op_JAL(cpu: Cpu): Cycles =
    let target = (cpu.inst.target shl 2) or (0xF000_0000'u32 and cpu.pc + 4)
    cpu.BranchWithDelaySlotTo(cast[Address](target))
    cpu.WriteRegister(31, cpu.inst_pc + 8)
    result = 1


proc Function_JALR(cpu: Cpu): Cycles =
    let target = cpu.ReadRegister(cpu.inst.rs)

    if unlikely(not is_aligned[uint32](target)):
        NOT_IMPLEMENTED "JALR: raise Address Error Exception"

    if unlikely(cpu.inst.rs == cpu.inst.rt):
        NOT_IMPLEMENTED "JALR: undefined behaviour"

    cpu.BranchWithDelaySlotTo(cast[Address](target))
    cpu.WriteRegister(cpu.inst.rd, cpu.inst_pc + 8)
    result = 1


proc Op_BCONDZ(cpu: Cpu): Cycles =
    let 
        is_bgez = (cpu.inst.value shr 16) and 0b1
        is_link = ((cpu.inst.value shr 20) and 0b1) != 0
        ge_zero = cast[int32](cpu.ReadRegister(cpu.inst.rs)) >= 0
        test = if is_bgez == 1: ge_zero else: not ge_zero

    if test:
        let
            offset = (cpu.inst.imm16 shl 2).sign_extend
            base = cpu.pc # cp.pc here is already the pc at the DS = cpu.inst_pc + 4
            target = base + offset

        # NOTE: target is always 32-bit aligned because offset is shifted by 2
        cpu.BranchWithDelaySlotTo(target)

        if is_link:
            cpu.WriteRegister(31, cpu.inst_pc + 8)

    result = 1


proc Function_JR(cpu: Cpu): Cycles =
    let target = cpu.ReadRegister(cpu.inst.rs)

    if unlikely(not is_aligned[uint32](target)):
        NOT_IMPLEMENTED "JR: raise Address Error Exception"

    cpu.BranchWithDelaySlotTo(cast[Address](target))
    result = 1


proc Function_OR(cpu: Cpu): Cycles = 
    let
        rd = cpu.inst.rd
        rs = cpu.inst.rs
        rt = cpu.inst.rt
        value = cpu.ReadRegister(rs) or cpu.ReadRegister(rt)

    cpu.WriteRegister(rd, value)
    result = 1


proc Function_AND(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        rs = cpu.inst.rs
        rt = cpu.inst.rt
        value = cpu.ReadRegister(rs) and cpu.ReadRegister(rt)

    cpu.WriteRegister(rd, value)
    result = 1


proc Op_MTC0(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        rt = cpu.inst.rt
        value = cpu.ReadRegister(rt)

    cpu.cop0.WriteRegister(rd, value)
    result = 1


proc Op_MFC0(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        rt = cpu.inst.rt
        value = cpu.cop0.ReadRegister(rd)

    # TODO: implement LOAD DELAY
    cpu.WriteRegister(rt, value)
    result = 1


proc Op_BNE(cpu: Cpu): Cycles =
    let
        rs = cpu.inst.rs
        rt = cpu.inst.rt

    if cpu.ReadRegister(rs) != cpu.ReadRegister(rt):
        let 
            offset = (cpu.inst.imm16 shl 2).sign_extend
            address = cpu.pc + offset
        cpu.BranchWithDelaySlotTo(address)

    result = 1


proc Op_BEQ(cpu: Cpu): Cycles =
    let
        rs = cpu.inst.rs
        rt = cpu.inst.rt       

    if cpu.ReadRegister(rs) == cpu.ReadRegister(rt):
        let 
            offset = (cpu.inst.imm16 shl 2).sign_extend
            address = cpu.pc + offset
        cpu.BranchWithDelaySlotTo(address)

    result = 1


proc Op_BGTZ(cpu: Cpu): Cycles =
    let
        rs = cpu.inst.rs

    if cast[int32](cpu.ReadRegister(rs)) > 0:
        let 
            offset = (cpu.inst.imm16 shl 2).sign_extend
            address = cpu.pc + offset
        cpu.BranchWithDelaySlotTo(address)

    result = 1


proc Op_BLEZ(cpu: Cpu): Cycles =
    let
        rs = cpu.inst.rs

    if cast[int32](cpu.ReadRegister(rs)) <= 0:
        let 
            offset = (cpu.inst.imm16 shl 2).sign_extend
            address = cpu.pc + offset
        cpu.BranchWithDelaySlotTo(address)

    result = 1


proc Op_ADDI(cpu: Cpu): Cycles =
    let
        rt = cpu.inst.rt
        rs = cpu.inst.rs
        
    try:
        let value = cast[int32](cpu.ReadRegister(rs)) + cast[int32](cpu.inst.imm16.sign_extend)
        cpu.WriteRegister(rt, cast[uint32](value))
    except:
        NOT_IMPLEMENTED "Arithmetic ADDI Exception not handled."

    result = 1


proc Function_ADD(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        rs = cpu.inst.rs
        rt = cpu.inst.rt

    try:
        let value = cast[int32](cpu.ReadRegister(rs)) + cast[int32](cpu.ReadRegister(rt))
        cpu.WriteRegister(rd, cast[uint32](value))
    except:
        NOT_IMPLEMENTED "Arithmetic ADD Exception not handled."

    result = 1


proc Op_ANDI(cpu: Cpu): Cycles =
    let
        rt = cpu.inst.rt
        rs = cpu.inst.rs
        value = cpu.ReadRegister(rs) and cpu.inst.imm16.zero_extend
        
    cpu.WriteRegister(rt, value)
    result = 1


proc Op_SLTI(cpu: Cpu): Cycles =
    let
        rt = cpu.inst.rt
        rs = cpu.inst.rs
        test = cast[int32](cpu.ReadRegister(rs)) < cast[int32](cpu.inst.imm16.sign_extend)
        value = if test: 1'u32 else: 0'u32
        
    cpu.WriteRegister(rt, value)
    result = 1


proc Op_SLTIU(cpu: Cpu): Cycles =
    let
        rt = cpu.inst.rt
        rs = cpu.inst.rs
        test = cpu.ReadRegister(rs) < cpu.inst.imm16.sign_extend
        value = if test: 1'u32 else: 0'u32
        
    cpu.WriteRegister(rt, value)
    result = 1


proc Function_DIV(cpu: Cpu): Cycles =
    let 
        rs = cpu.inst.rs
        num = cast[int32](cpu.ReadRegister(rs))
        rt = cpu.inst.rt
        den = cast[int32](cpu.ReadRegister(rt))
        
    #[ Division by 0, -1 cases:
        Opcode  Rs (num)        Rt(den)      Hi/Remainder  Lo/Result
        div     0..+7FFFFFFFh    0      -->  Rs(num)       -1
        div     -80000000h..-1   0      -->  Rs(num)       +1
        div     -80000000h      -1      -->  0             -80000000h
    ]#

    const 
        timing_cycles = 36
        minus_inf = -0x8000_0000

    if den == 0: # division by 0
        if num >= 0: 
            # Positive division by 0
            # num in [0 .. +7FFF_FFFFh]
            # cpu.WriteLoRegister(cast[uint32](-1) , timing_cycles)
            cpu.WriteLoRegister(cast[uint32](-1) , timing_cycles)
            cpu.WriteHiRegister(cast[uint32](num), timing_cycles)
        else: 
            # Negative division by 0
            # num in [-8000_0000h .. -1]
            cpu.WriteLoRegister(1, timing_cycles)
            cpu.WriteHiRegister(cast[uint32](num), timing_cycles)

    elif num == minus_inf and den == -1:
        # 0x8000_0000 division by -1
        # non-representable 32-bit value
        cpu.WriteLoRegister(cast[uint32](minus_inf), timing_cycles)
        cpu.WriteHiRegister(0, timing_cycles)

    else:
        let (quotent, remainder) = divmod(num, den)
        cpu.WriteLoRegister(cast[uint32](quotent)  , timing_cycles)
        cpu.WriteHiRegister(cast[uint32](remainder), timing_cycles)

    result = 1


proc Function_DIVU(cpu: Cpu): Cycles =
    let 
        num = cpu.ReadRegister(cpu.inst.rs)
        den = cpu.ReadRegister(cpu.inst.rt)
        
    #[ Division by 0 case:
        Opcode  Rs (num)        Rt(den)      Hi/Remainder  Lo/Result
        divu    0..FFFFFFFFh    0       -->  Rs            FFFFFFFFh
    ]#

    const 
        timing_cycles = 36

    if den == 0: # division by 0
        cpu.WriteLoRegister(0xFFFF_FFFF'u32, timing_cycles)
        cpu.WriteHiRegister(num, timing_cycles)
    else:
        let (quotent, remainder) = divmod(num, den)
        cpu.WriteLoRegister(quotent, timing_cycles)
        cpu.WriteHiRegister(remainder, timing_cycles)

    result = 1


proc Function_MFLO(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        (value, remaining_cycles) = cpu.ReadLoRegister()

    cpu.WriteRegister(rd, value)
    result = 1 + remaining_cycles


proc Function_MFHI(cpu: Cpu): Cycles =
    let
        rd = cpu.inst.rd
        (value, remaining_cycles) = cpu.ReadHiRegister()

    cpu.WriteRegister(rd, value)
    result = 1 + remaining_cycles


proc Function_Syscall(cpu: Cpu): Cycles =
    # TODO: display BIOS function depending on register $4
    cpu.logSyscallName()
    cpu.RaiseException(ExceptionCode.Syscall)
    result = 1