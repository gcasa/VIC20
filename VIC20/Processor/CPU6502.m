//
//  CPU6502.m
//  VIC20
//
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import "CPU6502.h"
#import "RAM.h"
#import "ROM.h"

@implementation CPU6502

+ (NSDictionary *)buildDictForInstruction: (NSNumber *)opcode
                                     name: (NSString *)name
                                paramters: (NSNumber *)parameters
                                   cycles: (NSNumber *)cycles
                                   method: (NSString *)methodName
{
    NSDictionary *insDict = [NSDictionary dictionaryWithObjectsAndKeys:@"opcpde", opcode,
                             @"name", name,
                             @"paramters", parameters,
                             @"cycles", cycles,
                             @"methodName", methodName, nil];
    return insDict;
}

+ (void) buildInstructionMap
{
    
}

+ (void) initialize
{
    instructionMap = [NSDictionary dictionary];
    [self buildInstructionMap];
}

- (id) initWithSize: (NSUInteger)size
{
    if (([super init]) != nil)
    {
        [self reset];
        ram = [[RAM alloc] initWithSize: size];
    }
    return nil;
}

- (void) reset
{
    // Initialize registers...
    a  = 0x00;
    x  = 0x00;
    y  = 0x00;
    pc = 0x00;
    p  = 0x00;
    sp = 0x00;
    sr = 0xFF;
    
    // Initialize flags...
    s  = 0x00;
    b  = 0x00;
    d  = 0x00;
    i  = 0x00;
    z  = 0x00;
    c  = 0x00;
}

- (void) interrupt
{
    
}

- (void) fetch
{
    
}

- (void) execute
{
    
}

- (void) step
{
    
}

- (void) state
{
    NSLog(@"A = %08x, X = %08x, Y = %08x, PC = %08x, P = %08x, SP = %08x", a, x, y, pc, p, sp);
}

- (void) tick
{
    
}

// Instruction interpretation....
- (void) executeOperation: (uint8)operation
{
    
}



@end
