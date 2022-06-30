# Copyright (c) 2022 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

{.experimental: "codeReordering" .}

import strformat

import ../core/[log, util]
import address

logChannels ["dma"]


const
    DMA_MAP_MAX_SIZE* =  0x1f8010f4 - 0x1f801080

    # DMA registers memory mapped regions (in kuseg)
    DMA_MAP_START* = (Address 0x1F801080).toKUSEG()
    DMA_MAP_END* = KusegAddress DMA_MAP_START.uint32 + DMA_MAP_MAX_SIZE


type
    DmaBaseAddress {.packed.} = object
        value        {.bitsize: 24.}: uint32
        UNUSED_25_31 {.bitsize:  8.}: uint8

    DmaBlockControl {.packed.} = object
        blocks {.bitsize: 16.}: uint16 # BC or BS, depending on SyncMode
        amount {.bitsize: 16.}: uint16 # amount of blocks (depends on SyncMode)

    DmaTransferDirection = enum
        ToRam   = 0
        FromRam = 1

    DmaTransferStep = enum
        Forward   = 0 # +4
        Backwards = 1 # -4

    DmaSyncMode = enum
        Immediate  = 0 # start immediately, transfer all in one go (CDROM, OTC)
        Blocks     = 1 # sync blocks to DMA request (MDEC, SPU, GPU data)
        LinkedList = 2 # GPU command lists
        UNKNOWN    = 3 # reserved/unused

    # TODO: For DMA6/OTC there are some restrictions, D6_CHCR 
    #       has only three read/write-able bits: Bit24,28,30. 
    #       All other bits are read-only: Bit1 is always 1 (
    #       step=backward), and the other bits are always 0.
    DmaChannelControl {.packed.} = object
        direction            {.bitsize:  1.}: DmaTransferDirection
        step                 {.bitsize:  1.}: DmaTransferStep
        UNUSED_02_07         {.bitsize:  6.}: uint8
        chop_enable          {.bitsize:  1.}: bool
        sync_mode            {.bitsize:  2.}: DmaSyncMode
        UNUSED_11_15         {.bitsize:  5.}: uint8
        chop_dma_window_size {.bitsize:  3.}: uint8 # 1 shl N words
        UNUSED_19_19         {.bitsize:  1.}: bool
        chop_cpu_window_size {.bitsize:  3.}: uint8 # 1 shl N clocks
        UNUSED_23_23         {.bitsize:  1.}: bool
        started_busy         {.bitsize:  1.}: bool # Start/Busy
        UNUSED_25_27         {.bitsize:  3.}: bool
        start_trigger        {.bitsize:  1.}: bool # Start/Trigger
        UNKNOWN_29_29        {.bitsize:  1.}: bool # TODO: pause?
        UNKNOWN_30_30        {.bitsize:  1.}: bool
        UNKNOWN_31_31        {.bitsize:  1.}: bool

    DmaChannelRegister {.packed.} = object
        base_address   : DmaBaseAddress
        block_control  : DmaBlockControl # unused in SyncMode=2
        channel_control: DmaChannelControl

    DmaChannelRegisters = array[7, DmaChannelRegister]
    
    DmaPriority {.packed.} = object
        priority {.bitsize:  3.}: uint8
        enabled  {.bitsize:  1.}: bool


    DmaControlRegisterParts {.packed.} = object
        dma0_mdecin : DmaPriority
        dma1_mdecout: DmaPriority
        dma2_gpu    : DmaPriority
        dma3_cdrom  : DmaPriority
        dma4_spu    : DmaPriority
        dma5_pio    : DmaPriority
        dma6_otc    : DmaPriority
        UNKNOWN_29_30 {.bitsize:  3.}: uint8 # priority offset?
        UNKNOWN_31_31 {.bitsize:  1.}: bool
                
    DmaControlRegister {.union.} = object
        value*: uint32
        parts*: DmaControlRegisterparts

    DmaInterruptRegister = object
        UNKNOWN_00_05          {.bitsize: 6.}: uint8 # R/W
        UNUSED_06_14           {.bitsize: 9.}: uint32 # TODO: always ZERO
        force_irq              {.bitsize: 1.}: bool
        dma0_irq_enable        {.bitsize: 1.}: bool
        dma1_irq_enable        {.bitsize: 1.}: bool
        dma2_irq_enable        {.bitsize: 1.}: bool
        dma3_irq_enable        {.bitsize: 1.}: bool
        dma4_irq_enable        {.bitsize: 1.}: bool
        dma5_irq_enable        {.bitsize: 1.}: bool
        dma6_irq_enable        {.bitsize: 1.}: bool
        dma0_irq_master_enable {.bitsize: 1.}: bool
        dma1_irq_master_enable {.bitsize: 1.}: bool
        dma2_irq_master_enable {.bitsize: 1.}: bool
        dma3_irq_master_enable {.bitsize: 1.}: bool
        dma4_irq_master_enable {.bitsize: 1.}: bool
        dma5_irq_master_enable {.bitsize: 1.}: bool
        dma6_irq_master_enable {.bitsize: 1.}: bool
        dma0_irq_flag          {.bitsize: 1.}: bool
        dma1_irq_flag          {.bitsize: 1.}: bool
        dma2_irq_flag          {.bitsize: 1.}: bool
        dma3_irq_flag          {.bitsize: 1.}: bool
        dma4_irq_flag          {.bitsize: 1.}: bool
        dma5_irq_flag          {.bitsize: 1.}: bool
        dma6_irq_flag          {.bitsize: 1.}: bool
        ro_irq_master_flag     {.bitsize: 1.}: bool # TODO: readonlyIF b15=1 OR (b23=1 AND (b16-22 AND b24-30)>0) THEN b31=1 ELSE b31=0
        

    DmaDevice* = ref object
        channels*: DmaChannelRegisters
        DPCR*: DmaControlRegister
        DICR*: DmaInterruptRegister 
        UNKNOWN_F8: uint32 # 1F8010F8h
        UNKNOWN_FC: uint32 # 1F8010FCh
    

proc New*(T: type DmaDevice): DmaDevice =
    debug "Creating DMA Registers device..."
    logIndent:
        result = DmaDevice()
        debug "DMA device created!"


proc Reset*(self: DmaDevice) =
    debug "Resetting DMA Registers device..."
    logIndent:
        self.channels.reset()
        self.DPCR.reset()
        self.DICR.reset()
        self.UNKNOWN_F8.reset()
        self.UNKNOWN_FC.reset()

        self.DPCR.value = 0x07654321


proc Read8 *(self: DmaDevice, address: KusegAddress): uint8  {.inline.} = Read[uint8 ](self, address)
proc Read16*(self: DmaDevice, address: KusegAddress): uint16 {.inline.} = Read[uint16](self, address)
proc Read32*(self: DmaDevice, address: KusegAddress): uint32 {.inline.} = Read[uint32](self, address)

proc Read*[T: uint8|uint16|uint32](self: DmaDevice, address: KusegAddress): T =
    let
        offset {.used.} = cast[uint32](address)

    assert is_aligned[T](address)
    
    NOT_IMPLEMENTED fmt"DMA Registers Read[{$T}]: address={address}"


proc Write8 *(self: DmaDevice, address: KusegAddress, value: uint8 ) {.inline.} = Write[uint8 ](self, address, value)
proc Write16*(self: DmaDevice, address: KusegAddress, value: uint16) {.inline.} = Write[uint16](self, address, value)
proc Write32*(self: DmaDevice, address: KusegAddress, value: uint32) {.inline.} = Write[uint32](self, address, value)

proc Write*[T: uint8|uint16|uint32](self: DmaDevice, address: KusegAddress, value: T) =
    let
        offset = cast[uint32](address - DMA_MAP_START)

    assert is_aligned[T](address)
    
    NOT_IMPLEMENTED fmt"DMA Registers Write[{$T}]: address={address} value={value:08x}h"
