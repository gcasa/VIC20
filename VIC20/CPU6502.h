//
//  CPU6502.h
//  VIC20
//
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ZEROPAGE    0x0000  // 0x0000 - 0x00FF
#define STACKBASE   0x0100  // 0x0100 - 0x01FF
#define RESETVECTOR 0xFFFC  // 0xFFFC - 0xFFFD
#define IRQVECTOR   0xFFFE  // 0xFFFE - 0xFFFF

@interface CPU6502 : NSObject
{
    uint8 A;
    uint8 X;
    uint8 Y;
    uint16 PC;
    uint8 P;
    uint8 SP;
}

- (void) reset;
- (void) interrupt;

- (void) fetch;
- (void) execute;
- (void) step;
    
- (void) state;
- (void) tick;

@end
