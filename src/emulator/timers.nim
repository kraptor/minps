# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../core/[log, util]
import address

logChannels ["timers"]


const
    TIMERS_MAX_SIZE = 0x32 # 0x1f801132 - 0x1f801100

    # device regions (in kuseg when possible)
    TIMERS_START* = (Address 0x1F801100).toKUSEG()
    TIMERS_END* = KusegAddress TIMERS_START.uint32 + TIMERS_MAX_SIZE

type
    TimerSyncEnableMode = enum
        FreeRun    = 0
        Syncronize = 1

    TimerSyncMode {.pure.} = enum
        PauseDuringBlank                        = 0
        ResetAtBlank                            = 1
        ResetAtBlank_PauseOutsideOfBlank        = 2
        PauseUntilBlankOnce_ThenSwitchToFreeRun = 3

    Timer2SyncMode {.pure.} = enum
        StopAtCurrentValue     = 0
        FreeRun                = 1
        FreeRun_Bis            = 2
        StopAtCurrentValue_Bis = 3

    TimerResetMode {.pure.} = enum
        After0xFFFF = 0
        AfterTarget = 1

    TimerIRQRepeatMode {.pure.} = enum
        OneShot = 0
        Repeat  = 1

    TimerIRQToggleMode {.pure.} = enum
        ShortBit10  = 0
        ToggleBit10 = 1

    TimerInterruptRequest {.pure.} = enum
        Yes = 0
        No = 1

    TimerModeParts* {.packed.} = object
        sync_enable       {.bitsize: 1.}: TimerSyncEnableMode
        sync_mode         {.bitsize: 2.}: TimerSyncMode
        reset_counter     {.bitsize: 1.}: TimerResetMode
        irq_at_target     {.bitsize: 1.}: bool # IRQ when counter = target
        irq_at_wrap       {.bitsize: 1.}: bool # IRQ when counter = 0xFFFF
        irq_repeat_mode   {.bitsize: 1.}: TimerIRQRepeatMode
        irq_toggle_mode   {.bitsize: 1.}: TimerIRQToggleMode
        clock_source      {.bitsize: 2.}: uint8
        interrupt_request {.bitsize: 1.}: TimerInterruptRequest # set after writing
        reached_target    {.bitsize: 1.}: bool # reached target value
        reached_wrap      {.bitsize: 1.}: bool # reached 0xFFFF
        UNKNOWN_13_15     {.bitsize: 3.}: uint8 # always zero??
        GARBAGE_16_31     {.bitsize:16.}: uint16

    TimerMode* {.union.} = object
        parts: TimerModeParts
        value: uint32

    Timer2ModeParts* {.packed.} = object
        sync_enable       {.bitsize: 1.}: TimerSyncEnableMode
        sync_mode         {.bitsize: 2.}: Timer2SyncMode
        reset_counter     {.bitsize: 1.}: TimerResetMode
        irq_at_target     {.bitsize: 1.}: bool # IRQ when counter = target
        irq_at_wrap       {.bitsize: 1.}: bool # IRQ when counter = 0xFFFF
        irq_repeat_mode   {.bitsize: 1.}: TimerIRQRepeatMode
        irq_toggle_mode   {.bitsize: 1.}: TimerIRQToggleMode
        clock_source      {.bitsize: 2.}: uint8
        interrupt_request {.bitsize: 1.}: TimerInterruptRequest # set after writing
        reached_target    {.bitsize: 1.}: bool # reached target value
        reached_wrap      {.bitsize: 1.}: bool # reached 0xFFFF
        UNKNOWN_13_15     {.bitsize: 3.}: uint8 # always zero??
        GARBAGE_16_31     {.bitsize:16.}: uint16
        
    Timer2Mode* {.union.} = object
        parts: Timer2ModeParts
        value: uint32

    Timer = object
        value         : uint16
        garbage       : uint16
        mode          : TimerMode
        target_value  : uint16
        target_garbage: uint16

    Timer2 = object
        value         : uint16
        garbage       : uint16
        mode          : Timer2Mode
        target_value  : uint16
        target_garbage: uint16

    Timers* = ref object
        timer0: Timer # HBlank timer
        timer1: Timer # VBlank timer
        timer2: Timer2


proc New*(T: type Timers): Timers =
    debug "Creating Timers..."
    logIndent:
        result = Timers()
        debug "Timers created!"


proc Reset*(self: Timers) =
    debug "Resetting Timers..."
    logIndent:
        self.timer0.reset()
        self.timer1.reset()
        self.timer2.reset()
        debug("Spu Timers.")


proc Read8 *(self: Timers, address: KusegAddress): uint8  {.inline.} = Read[uint8 ](self, address)
proc Read16*(self: Timers, address: KusegAddress): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: Timers, address: KusegAddress): uint32 {.inline.} = Read[uint32](self, address)

proc Read*[T: uint8|uint16|uint32](self: Timers, address: KusegAddress): T =
    assert is_aligned[T](address)
    
    NOT_IMPLEMENTED fmt"TIMERS Read[{$T}]: address={address}"


proc Write8 *(self: Timers, address: KusegAddress, value: uint8 ) {.inline.} = Write[uint8 ](self, address, value)
proc Write16*(self: Timers, address: KusegAddress, value: uint16) {.inline.} = Write[uint16](self, address, value)
proc Write32*(self: Timers, address: KusegAddress, value: uint32) {.inline.} = Write[uint32](self, address, value)

proc Write*[T: uint8|uint16|uint32](self: Timers, address: KusegAddress, value: T) =
    assert is_aligned[T](address)

    when T is uint16:
        case address.uint32:
        of 0x1f801100: # Timer 0 Current Value
            self.timer0.value = value
            warn fmt"TIMERS/0 Current value set to: {value:08x}h. Side.effects not implemented."
            return

        of 0x1f801104: # Timer 0 Mode
            self.timer0.mode.value = value
            warn fmt"TIMERS/0 Mode set to value: {value:08x}h. Side.effects not implemented."
            notice fmt"- Sync. Enable     : {self.timer0.mode.parts.sync_enable}"
            notice fmt"- Sync. Mode       : {self.timer0.mode.parts.sync_mode}"
            notice fmt"- Reset Counter    : {self.timer0.mode.parts.reset_counter}"
            notice fmt"- IRQ at target?   : {self.timer0.mode.parts.irq_at_target}"
            notice fmt"- IRQ at wrap?     : {self.timer0.mode.parts.irq_at_wrap}"
            notice fmt"- IRQ repeat mode  : {self.timer0.mode.parts.irq_repeat_mode}"
            notice fmt"- IRQ toggle mode  : {self.timer0.mode.parts.irq_toggle_mode}"
            notice fmt"- IRQ clock source : {self.timer0.mode.parts.clock_source}"
            notice fmt"- Interrupt request: {self.timer0.mode.parts.interrupt_request}"
            notice fmt"- Reached target?  : {self.timer0.mode.parts.reached_target}"
            notice fmt"- Reached wrap?    : {self.timer0.mode.parts.reached_wrap}"

            # NOTE: TimerInteruptRequest.No = 1
            if self.timer0.mode.parts.interrupt_request == TimerInterruptRequest.No:
                warn fmt"NOT IMPLEMENTED: TIMERS/0 Interrupt request set to 1"

            return

        of 0x1f801108: # Timer 0 Target Value
            self.timer0.target_value = value
            warn fmt"TIMERS/0 Target value set to: {value:08x}h. Side.effects not implemented."
            return

        of 0x1f801110: # Timer 1 Current Value
            self.timer1.value = value
            warn fmt"TIMERS/1 Current value set to: {value:08x}h. Side.effects not implemented."
            return

        of 0x1f801114: # Timer 1 Mode
            self.timer1.mode.value = value
            warn fmt"TIMERS/1 Mode set to value: {value:08x}h. Side.effects not implemented."
            notice fmt"- Sync. Enable     : {self.timer1.mode.parts.sync_enable}"
            notice fmt"- Sync. Mode       : {self.timer1.mode.parts.sync_mode}"
            notice fmt"- Reset Counter    : {self.timer1.mode.parts.reset_counter}"
            notice fmt"- IRQ at target?   : {self.timer1.mode.parts.irq_at_target}"
            notice fmt"- IRQ at wrap?     : {self.timer1.mode.parts.irq_at_wrap}"
            notice fmt"- IRQ repeat mode  : {self.timer1.mode.parts.irq_repeat_mode}"
            notice fmt"- IRQ toggle mode  : {self.timer1.mode.parts.irq_toggle_mode}"
            notice fmt"- IRQ clock source : {self.timer1.mode.parts.clock_source}"
            notice fmt"- Interrupt request: {self.timer1.mode.parts.interrupt_request}"
            notice fmt"- Reached target?  : {self.timer1.mode.parts.reached_target}"
            notice fmt"- Reached wrap?    : {self.timer1.mode.parts.reached_wrap}"

            # NOTE: TimerInteruptRequest.No = 1
            if self.timer1.mode.parts.interrupt_request == TimerInterruptRequest.No:
                warn fmt"NOT IMPLEMENTED: TIMERS/1 Interrupt request set to 1"

            return

        of 0x1f801118: # Timer 1 Target Value
            self.timer1.target_value = value
            warn fmt"TIMERS/1 Target value set to: {value:08x}h. Side.effects not implemented."
            return        

        of 0x1f801120: # Timer 2 Current Value
            self.timer2.value = value
            warn fmt"TIMERS/2 Current value set to: {value:08x}h. Side.effects not implemented."
            return

        of 0x1f801124: # Timer 2 Mode
            self.timer2.mode.value = value
            warn fmt"TIMERS/2 Mode set to value: {value:08x}h. Side.effects not implemented."
            notice fmt"- Sync. Enable     : {self.timer2.mode.parts.sync_enable}"
            notice fmt"- Sync. Mode       : {self.timer2.mode.parts.sync_mode}"
            notice fmt"- Reset Counter    : {self.timer2.mode.parts.reset_counter}"
            notice fmt"- IRQ at target?   : {self.timer2.mode.parts.irq_at_target}"
            notice fmt"- IRQ at wrap?     : {self.timer2.mode.parts.irq_at_wrap}"
            notice fmt"- IRQ repeat mode  : {self.timer2.mode.parts.irq_repeat_mode}"
            notice fmt"- IRQ toggle mode  : {self.timer2.mode.parts.irq_toggle_mode}"
            notice fmt"- IRQ clock source : {self.timer2.mode.parts.clock_source}"
            notice fmt"- Interrupt request: {self.timer2.mode.parts.interrupt_request}"
            notice fmt"- Reached target?  : {self.timer2.mode.parts.reached_target}"
            notice fmt"- Reached wrap?    : {self.timer2.mode.parts.reached_wrap}"

            # NOTE: TimerInteruptRequest.No = 1
            if self.timer2.mode.parts.interrupt_request == TimerInterruptRequest.No:
                warn fmt"NOT IMPLEMENTED: TIMERS/2 Interrupt request set to 1"
            
            return

        of 0x1f801128: # Timer 2 Target Value
            self.timer2.target_value = value
            warn fmt"TIMERS/2 Target value set to: {value:08x}h. Side.effects not implemented."
            return        

        else:
            discard
            
    NOT_IMPLEMENTED fmt"TIMERS Write[{$T}]: address={address} value={value:08x}h"