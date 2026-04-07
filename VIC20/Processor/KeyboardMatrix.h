//
//  KeyboardMatrix.h
//  VIC20
//  VIC-20 Keyboard Matrix Scanner
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

// Type definitions for GNUstep compatibility 
#ifndef VIC20_UINT_TYPES_DEFINED
#define VIC20_UINT_TYPES_DEFINED
typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int uint32;
#endif

@class VIA6522;

// VIC-20 Keyboard Layout Constants
#define VIC_KEY_ROWS    8
#define VIC_KEY_COLS    8

// Special key codes
#define VIC_KEY_RUN_STOP    0x3F
#define VIC_KEY_RESTORE     0x40
#define VIC_KEY_SHIFT_LOCK  0x41
#define VIC_KEY_COMMODORE   0x42

@interface KeyboardMatrix : NSObject
{
    // Key matrix state (8x8)
    BOOL keyMatrix[VIC_KEY_ROWS][VIC_KEY_COLS];
    
    // VIA chip references for matrix scanning
    __weak VIA6522 *via1;
    __weak VIA6522 *via2;
    
    // Current scan state
    uint8 currentRow;
    uint8 matrixOutput;
    
    // Key mapping tables
    NSDictionary *keyCodeToMatrix;
    NSDictionary *charToMatrix;
    
    // Modifier states
    BOOL shiftPressed;
    BOOL commodorePressed;
    BOOL ctrlPressed;
}

// Initialization
- (instancetype)initWithVIA1:(VIA6522 *)v1 VIA2:(VIA6522 *)v2;

// Key events
- (void)keyDown:(NSEvent *)event;
- (void)keyUp:(NSEvent *)event;
- (void)flagsChanged:(NSEvent *)event;

// Matrix scanning (called by VIA)
- (uint8)scanMatrix:(uint8)rowSelect;
- (void)updateMatrixOutput;

// Direct key control
- (void)setKey:(uint8)row col:(uint8)col pressed:(BOOL)pressed;
- (BOOL)isKeyPressed:(uint8)row col:(uint8)col;

// Utility methods
- (void)pressKey:(unichar)character;
- (void)releaseKey:(unichar)character;
- (void)typeString:(NSString *)text;

// Debug
- (void)dumpMatrix;
- (NSString *)getMatrixStatus;

@end