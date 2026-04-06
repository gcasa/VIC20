//
//  CPU6502.h
//  VIC20
//
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RAM, ROM, VIC6561, VIA6522, KeyboardMatrix, VIC20MemoryManager;

#define ZEROPAGE    0x0000  // 0x0000 - 0x00FF
#define STACKBASE   0x0100  // 0x0100 - 0x01FF
#define RESETVECTOR 0xFFFC  // 0xFFFC - 0xFFFD
#define IRQVECTOR   0xFFFE  // 0xFFFE - 0xFFFF

struct status {
    unsigned int c:1;
    unsigned int z:1;
    unsigned int unused:1;
    unsigned int i:1;
    unsigned int d:1;
    unsigned int b:1;
    unsigned int v:1;
    unsigned int n:1;
};


@interface CPU6502 : NSObject
{
    // Registers...
    uint8  a;   // Accumulator
    uint8  x;   // X register
    uint8  y;   // Y register
    uint16 pc;  // Program counter
    uint8  sp;  // stack pointer
    union {
        struct status status; // status register...
        uint8 sr;
    } s;
    
    // Memory and I/O...
    RAM *ram;  // Keep for backward compatibility
    VIC6561 *vic;
    VIA6522 *via1;
    VIA6522 *via2;
    KeyboardMatrix *keyboard;
    VIC20MemoryManager *memoryManager;
    
    NSUInteger cycles;
    BOOL debug;
    
    // Current instruction
    NSNumber *currentInstruction;
}

// Initialize with memory...
- (id) initWithSize: (NSUInteger)size;
- (id) initWithRAM: (RAM *)memory VIC: (VIC6561 *)vicChip;
- (id) initVIC20System;  // Complete VIC-20 system initialization

// Reset/Interrupt...
- (void) reset;
- (void) interrupt;

// Instruction fetch and interpret...
- (void) fetch;
- (void) execute;
- (void) executeAtLocation: (uint16)loc;
- (void) executeOperation: (NSNumber *)operation;
- (void) loadProgramFile: (NSString *)fileName atLocation: (uint16)loc;
- (void) runAtLocation: (uint16)loc;

// Memory access (with VIC integration)
- (uint8) readMemory: (uint16)address;
- (void) writeMemory: (uint8)value address: (uint16)address;

// Component access
- (VIC6561 *) getVIC;
- (VIA6522 *) getVIA1;
- (VIA6522 *) getVIA2;
- (KeyboardMatrix *) getKeyboard;
- (VIC20MemoryManager *) getMemoryManager;

// System control
- (void) loadROMs: (NSString *)romPath;
- (BOOL) insertCartridge: (NSData *)cartridgeData;
- (void) configureMemoryExpansion: (BOOL)enable3K enable8K1:(BOOL)enable8K1 enable8K2:(BOOL)enable8K2;

// Run...
- (void) run;
- (void) step;
- (void) state;
- (void) tick;

// Stack...
- (void) push: (uint8)value;
- (uint8) pop;

// Debug
- (void)debugLogWithFormat: (NSString *)formatString,...;

// Helper methods for flag calculations
- (void) updateNZFlags: (uint8)value;
- (void) setCarryFlag: (BOOL)carry;
- (void) setOverflowFlag: (BOOL)overflow;

@end
