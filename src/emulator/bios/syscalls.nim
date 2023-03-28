# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

import ../../core/log
import ../cpu/cpu
import ../address


logChannels {LogChannel.bios, LogChannel.syscall}


type
    SyscallFunction = enum
        NoFunction = 0
        EnterCriticalSection = 1
        ExitCriticalSection = 2
        ChangeThreadSubFunction = 3


proc SyscallFunctionName*(cpu: Cpu): string =
    case cpu.ReadRegisterDebug(4):
    of ord NoFunction: return "NoFunction()"
    of ord EnterCriticalSection: return "EnterCriticalSection()"
    of ord ExitCriticalSection: return "ExitCriticalSection()"
    of ord ChangeThreadSubFunction: return "ChangeThreadSubFunction(" & $cpu.ReadRegisterDebug(5).Address & ")"
    else:
        return "DeliverEvent(F0000010h, 4000h)"


proc logSyscallName*(cpu: Cpu) =
    logEcho "BIOS/SYS " & SyscallFunctionName(cpu)
