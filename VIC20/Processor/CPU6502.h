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

@interface CPU6502 : NSObject
{
    // Registers...
    uint8 a;
    uint8 x;
    uint8 y;
    uint16 pc;
    uint8 p;
    uint8 sp;
    uint8 sr;
    
    // Flags...
    BOOL s;
    BOOL v;
    BOOL b;
    BOOL d;
    BOOL i;
    BOOL z;
    BOOL c;
    
    // Memory...
    RAM *ram;
    
    // Current instruction
    NSNumber *currentInstruction;
}

- (id) initWithSize: (NSUInteger)size;

- (void) reset;
- (void) interrupt;

- (void) fetch;
- (void) execute;
- (void) step;
    
- (void) state;
- (void) tick;

@end
