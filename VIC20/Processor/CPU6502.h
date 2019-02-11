//
//  CPU6502.h
//  VIC20
//
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RAM, ROM;

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
    
    // Memory...
    RAM *ram;
    NSUInteger cycles;
    BOOL debug;
    
    // Current instruction
    NSNumber *currentInstruction;
}

// Initialize with memory...
- (id) initWithSize: (NSUInteger)size;

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

@end
