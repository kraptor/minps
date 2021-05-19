# Copyright (c) 2021 kraptor
# 
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT


import ../../core/log

logChannels ["cop0"]


type 
    Cop0RegisterIndex* = 0..31


proc GetCop0RegisterAlias*(r: Cop0RegisterIndex): string =
    const COP0_REGISTER_TO_ALIAS = [
        "$0"      , "$1"  , "$2" , "BPC" , "$4" , "BDA"  , "JUMPDEST", "DCIC", 
        "BadVaddr", "BDAM", "$10", "BPCM", "SR" , "CAUSE", "EPC"     , "PRID", 
        "$16"     , "$17" , "$18", "$19" , "$20", "$21"  , "$22"     , "$23", 
        "$24"     , "$25" , "$26", "$27" , "$28", "$29"  , "$30"     , "$31"]
    COP0_REGISTER_TO_ALIAS[r]