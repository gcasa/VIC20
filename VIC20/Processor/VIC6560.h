//
//  VIC6560.h
//  VIC20
//  VIC chip
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

@class RAM;

// VIC-6561 Register addresses (relative to VIC base)
#define VIC_REG_INTERLACE_MODE    0x00  // Interlace mode control
#define VIC_REG_HORZ_CENTER       0x01  // Horizontal centering
#define VIC_REG_VERT_CENTER       0x02  // Vertical centering  
#define VIC_REG_VIDEO_COLUMNS     0x03  // Video matrix columns (bit 7) + TV type
#define VIC_REG_VIDEO_ROWS        0x04  // Video matrix rows + character size
#define VIC_REG_CHAR_SIZE         0x05  // Character size control
#define VIC_REG_LIGHT_PEN_X       0x06  // Light pen X position
#define VIC_REG_LIGHT_PEN_Y       0x07  // Light pen Y position
#define VIC_REG_PADDLE_X          0x08  // Paddle X value
#define VIC_REG_PADDLE_Y          0x09  // Paddle Y value
#define VIC_REG_FREQ_VOICE1_LO    0x0A  // Voice 1 frequency (low)
#define VIC_REG_FREQ_VOICE2_LO    0x0B  // Voice 2 frequency (low)
#define VIC_REG_FREQ_VOICE3_LO    0x0C  // Voice 3 frequency (low)
#define VIC_REG_FREQ_NOISE_LO     0x0D  // Noise frequency (low)
#define VIC_REG_VOLUME_COLOR      0x0E  // Volume + auxiliary color
#define VIC_REG_SCREEN_COLOR      0x0F  // Screen color + reverse + freq high bits

// VIC Colors
#define VIC_COLOR_BLACK      0x0
#define VIC_COLOR_WHITE      0x1
#define VIC_COLOR_RED        0x2
#define VIC_COLOR_CYAN       0x3
#define VIC_COLOR_PURPLE     0x4
#define VIC_COLOR_GREEN      0x5
#define VIC_COLOR_BLUE       0x6
#define VIC_COLOR_YELLOW     0x7
#define VIC_COLOR_ORANGE     0x8
#define VIC_COLOR_LIGHT_ORANGE 0x9
#define VIC_COLOR_PINK       0xA
#define VIC_COLOR_LIGHT_CYAN 0xB
#define VIC_COLOR_LIGHT_PURPLE 0xC
#define VIC_COLOR_LIGHT_GREEN 0xD
#define VIC_COLOR_LIGHT_BLUE 0xE
#define VIC_COLOR_LIGHT_YELLOW 0xF

// Screen dimensions
#define VIC_SCREEN_WIDTH_CHARS   22
#define VIC_SCREEN_HEIGHT_CHARS  23
#define VIC_CHAR_WIDTH_PIXELS    8
#define VIC_CHAR_HEIGHT_PIXELS   8
#define VIC_SCREEN_WIDTH_PIXELS  (VIC_SCREEN_WIDTH_CHARS * VIC_CHAR_WIDTH_PIXELS)
#define VIC_SCREEN_HEIGHT_PIXELS (VIC_SCREEN_HEIGHT_CHARS * VIC_CHAR_HEIGHT_PIXELS)

// Memory locations
#define VIC_SCREEN_MATRIX_BASE   0x1E00  // Default screen matrix location
#define VIC_COLOR_MATRIX_BASE    0x9600  // Color matrix base
#define VIC_CHAR_ROM_BASE        0x8000  // Character ROM base

@interface VIC6561 : NSObject
{
    // VIC Registers (16 bytes)
    uint8 registers[16];
    
    // Memory interface
    RAM *systemRAM;
    
    // Video state
    uint16 screenMatrixBase;
    uint16 colorMatrixBase;
    uint16 characterROMBase;
    
    // Display buffer
    NSBitmapImageRep *displayBuffer;
    NSColor *colorPalette[16];
    
    // Sound state
    uint16 voice1Frequency;
    uint16 voice2Frequency;
    uint16 voice3Frequency;
    uint16 noiseFrequency;
    uint8 volume;
    BOOL soundEnabled[4];  // 3 voices + 1 noise
    
    // Timing
    NSUInteger cycles;
    NSUInteger scanLine;
    BOOL vBlankFlag;
    
    // Input
    uint8 lightPenX;
    uint8 lightPenY;
    uint8 paddleX;
    uint8 paddleY;
    
    // Configuration
    BOOL PALMode;  // PAL vs NTSC timing
    uint8 screenColumns;
    uint8 screenRows;
    BOOL doubleHeight;
    uint8 auxiliaryColorIndex;  // Current auxiliary color index
}

// Initialization
- (instancetype)initWithRAM:(RAM *)ram;

// Register access
- (void)writeRegister:(uint8)address value:(uint8)value;
- (uint8)readRegister:(uint8)address;

// Video operations
- (void)renderFrame;
- (void)renderScanline:(NSUInteger)line;
- (NSBitmapImageRep *)getDisplayBuffer;
- (void)updateColorPalette;

// Sound operations
- (void)updateSound;
- (void)generateTone:(int)voice frequency:(uint16)freq enabled:(BOOL)enabled;
- (void)setVolume:(uint8)vol;

// Memory interface
- (uint8)readVideoMatrix:(uint16)offset;
- (uint8)readColorMatrix:(uint16)offset;
- (uint8)readCharacterROM:(uint16)offset;

// Timing and interrupts
- (void)tick;
- (BOOL)isVBlank;
- (void)setVBlank:(BOOL)vblank;

// Input handling
- (void)setLightPen:(uint8)x y:(uint8)y;
- (void)setPaddle:(uint8)x y:(uint8)y;

// Configuration
- (void)setPALMode:(BOOL)palMode;
- (void)setScreenSize:(uint8)columns rows:(uint8)rows;

// Integration helpers
- (void)loadCharacterROM:(NSData *)romData;
- (void)loadDefaultCharacterSet;
- (NSImage *)createDisplayImage;
- (void)refreshDisplay;

// CPU Integration
- (void)writeVICRegister:(uint16)address value:(uint8)value;
- (uint8)readVICRegister:(uint16)address;

// Debug helpers
- (NSString *)getRegisterStatus;
- (void)dumpVideoMatrix;

@end
