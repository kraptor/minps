# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering".}

import strformat

import ../core/[log, util]
import address

logChannels ["spu"]


const
    SPU_MAX_SIZE = 1024

    # device regions (in kuseg when possible)
    SPU_START* = (Address 0x1F801C00).toKUSEG()
    SPU_END* = KusegAddress SPU_START.uint32 + SPU_MAX_SIZE

type
    SpuData {.union.} = object
        u8 : array[SPU_MAX_SIZE, uint8]
        u16: array[SPU_MAX_SIZE div 2, uint16]
        u32: array[SPU_MAX_SIZE div 4, uint32]

    StereoVolume {.packed.} = object
        left: uint16
        right: uint16       

    VoiceRegister {.packed.} = object
        volume: StereoVolume
        sample_rate: uint16
        start_addr: uint16
        adsr: uint32
        adsr_volume: uint16
        adpcm_repeat_Address: uint16

    ReverbConfiguration {.packed.} = object
        dAPF1  : uint16 # Reverb APF Offset 1
        dAPF2  : uint16 # Reverb APF Offset 2
        vIIR   : uint16 # Reverb Reflection Volume 1
        vCOMB1 : uint16 # Reverb Comb Volume 1
        vCOMB2 : uint16 # Reverb Comb Volume 2
        vCOMB3 : uint16 # Reverb Comb Volume 3
        vCOMB4 : uint16 # Reverb Comb Volume 4
        vWALL  : uint16 # Reverb Reflection Volume 2
        vAPF1  : uint16 # Reverb APF Volume 1
        vAPF2  : uint16 # Reverb APF Volume 2
        mSAME  : uint32 # Reverb Same Side Reflection Address 1 Left/Right
        mCOMB1 : uint32 # Reverb Comb Address 1 Left/Right
        mCOMB2 : uint32 # Reverb Comb Address 2 Left/Right
        dSAME  : uint32 # Reverb Same Side Reflection Address 2 Left/Right
        mDIFF  : uint32 # Reverb Different Side Reflection Address 1 Left/Right
        mCOMB3 : uint32 # Reverb Comb Address 3 Left/Right
        mCOMB4 : uint32 # Reverb Comb Address 4 Left/Right
        dDIFF  : uint32 # Reverb Different Side Reflection Address 2 Left/Right
        mAPF1  : uint32 # Reverb APF Address 1 Left/Right
        mAPF2  : uint32 # Reverb APF Address 2 Left/Right
        vIN    : uint32 # Reverb Input Volume Left/Right

    InternalRegisters {.packed.} = object
        current_volume: array[24, StereoVolume] # Voice 0..23 Current Volume Left/Right
        UNKNOWN_1E60  : array[0x20, uint8]      # Unknown? (R/W)
        UNKNOWN_1E80  : array[0x180, uint8]     # Unknown? (Read: FFh-filled) (Unused or Write only?)

    SpuControlRegisters* {.packed.} = object
        voice                       : array[24, VoiceRegister] 
        main_volume                 : StereoVolume
        reverb_output_volume        : StereoVolume
        voice_key_ON                : uint32
        voice_key_OFF               : uint32
        voice_channel_fm            : uint32
        voice_channel_noise_mode    : uint32
        voice_channel_reverb_mode   : uint32
        voice_channel_ON_OFF        : uint32
        UNKNOWN_1DA0                : uint16
        sound_ram_reverb_start_addr : uint16
        sound_ram_irq_addr          : uint16
        sound_ram_data_transfer_addr: uint16
        sound_ram_data_transfer_fifo: uint16
        spu_control_register_SPUCNT : uint16
        sound_ram_data_transfer_ctl : uint16
        spu_status_register_SPUSTAT : uint16
        cd_volume                   : StereoVolume
        extern_volume               : StereoVolume
        current_main_volume         : StereoVolume
        UNKNOWN_1DBC                : uint32
        spu_reverv_configuration    : ReverbConfiguration
        spu_internal_registers      : InternalRegisters        

    SpuObject* {.union.} = object
        data*: SpuData
        regs*: SpuControlRegisters

    Spu* = ref SpuObject


proc New*(T: type Spu): Spu =
    debug "Creating Spu..."
    logIndent:
        result = Spu()
        debug "Spu created!"


proc Reset*(self: Spu) =
    debug "Resetting Spu..."
    logIndent:
        self.data.reset()
        # self.regs.reset() not needed, both "data" and "regs" point to same memory
        debug("Spu Resetted.")


proc Read8 *(self: Spu, address: KusegAddress): uint8  {.inline.} = Read[uint8 ](self, address)
proc Read16*(self: Spu, address: KusegAddress): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: Spu, address: KusegAddress): uint32 {.inline.} = Read[uint32](self, address)

proc Read*[T: uint8|uint16|uint32](self: Spu, address: KusegAddress): T =
    let
        offset {.used.} = cast[uint32](address)

    assert is_aligned[T](address)

    # when T is uint32:
    #     return self.data.u32[offset shr 2]
    
    NOT_IMPLEMENTED fmt"SPU Read[{$T}]: address={address}"


proc Write8 *(self: Spu, address: KusegAddress, value: uint8 ) {.inline.} = Write[uint8 ](self, address, value)
proc Write16*(self: Spu, address: KusegAddress, value: uint16) {.inline.} = Write[uint16](self, address, value)
proc Write32*(self: Spu, address: KusegAddress, value: uint32) {.inline.} = Write[uint32](self, address, value)

proc Write*[T: uint8|uint16|uint32](self: Spu, address: KusegAddress, value: T) =
    let
        offset = cast[uint32](address - SPU_START)

    assert is_aligned[T](address)
    
    when T is uint16:
        self.data.u16[offset shr 1] = value 
        
        case cast[uint32](address):
        of 0x1f801d80: warn fmt"SPU Main Volume [left] set to: {value}. Not implemented."; return
        of 0x1f801d82: warn fmt"SPU Main Volume [right] set to: {value}. Not implemented."; return
        of 0x1f801d84: warn fmt"SPU Reverb Output Volume [left] set to: {value}. Not implemented."; return
        of 0x1f801d86: warn fmt"SPU Reverb Output Volume [right] set to: {value}. Not implemented."; return
        else:
            discard

    NOT_IMPLEMENTED fmt"SPU Write[{$T}]: address={address} value={value:08x}h"