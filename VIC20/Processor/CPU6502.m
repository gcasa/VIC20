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

- (id) init
{
    if (([super init]) != nil)
    {
        A = 0;
        X = 0;
        Y = 0;
        PC = 0;
        P = 0;
        SP  = 0;
        ram = [[RAM alloc] initWithSize: 64*1024];
    }
    return nil;
}

- (void) reset
{
    A = 0;
    X = 0;
    Y = 0;
    PC = 0;
    P = 0;
    SP  = 0;
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
    NSLog(@"A = %08x, X = %08x, Y = %08x, PC = %08x, P = %08x, SP = %08x", A, X, Y, PC, P, SP);
}

- (void) tick
{
    
}

@end
