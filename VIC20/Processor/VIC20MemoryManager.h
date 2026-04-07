//
//  VIC20MemoryManager.h
//  VIC20
//  VIC-20 Memory Management System
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import <Foundation/Foundation.h>

// Type definitions for GNUstep compatibility 
#ifndef VIC20_UINT_TYPES_DEFINED
#define VIC20_UINT_TYPES_DEFINED
typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int uint32;
#endif

@class VIC6561, VIA6522, KeyboardMatrix;

// Memory regions
#define VIC20_RAM_BASE          0x0000
#define VIC20_RAM_SIZE          0x1000  // 4KB base RAM
#define VIC20_RAM_EXPANSION_2K  0x0400  // 2KB expansion at $0400
#define VIC20_RAM_EXPANSION_3K  0x0C00  // 3KB expansion at $0C00
#define VIC20_RAM_EXPANSION_8K_1 0x2000 // 8KB expansion at $2000
#define VIC20_RAM_EXPANSION_8K_2 0x4000 // 8KB expansion at $4000
#define VIC20_RAM_EXPANSION_8K_3 0x6000 // 8KB expansion at $6000

#define VIC20_CHAR_ROM_BASE     0x8000
#define VIC20_CHAR_ROM_SIZE     0x1000  // 4KB

#define VIC20_VIC_BASE          0x9000
#define VIC20_VIC_SIZE          0x0010  // 16 bytes

#define VIC20_COLOR_RAM_BASE    0x9400
#define VIC20_COLOR_RAM_SIZE    0x0400  // 1KB

#define VIC20_VIA1_BASE         0x9110
#define VIC20_VIA2_BASE         0x9120
#define VIC20_VIA_SIZE          0x0010  // 16 bytes each

#define VIC20_BASIC_ROM_BASE    0xA000
#define VIC20_BASIC_ROM_SIZE    0x2000  // 8KB

#define VIC20_CARTRIDGE_8K_BASE 0xA000  // Can replace BASIC
#define VIC20_CARTRIDGE_4K_BASE 0xB000
#define VIC20_CARTRIDGE_GAME_BASE 0x6000

#define VIC20_KERNAL_ROM_BASE   0xE000
#define VIC20_KERNAL_ROM_SIZE   0x2000  // 8KB

// Memory expansion configuration
typedef struct {
    BOOL expansion_2K;   // $0400-$0BFF
    BOOL expansion_3K;   // $0C00-$17FF  
    BOOL expansion_8K_1; // $2000-$3FFF
    BOOL expansion_8K_2; // $4000-$5FFF
    BOOL expansion_8K_3; // $6000-$7FFF (conflicts with cartridge)
} VIC20MemoryConfig;

// Cartridge types
typedef enum {
    VIC20_CARTRIDGE_NONE = 0,
    VIC20_CARTRIDGE_8K,    // $A000-$BFFF (replaces BASIC)
    VIC20_CARTRIDGE_4K,    // $B000-$BFFF
    VIC20_CARTRIDGE_GAME,  // $6000-$7FFF
    VIC20_CARTRIDGE_16K    // $6000-$7FFF + $A000-$BFFF
} VIC20CartridgeType;

@interface VIC20MemoryManager : NSObject
{
    // Memory banks
    uint8 *baseRAM;         // $0000-$0FFF (4KB)
    uint8 *expansion2K;     // $0400-$0BFF (2KB) 
    uint8 *expansion3K;     // $0C00-$17FF (3KB)
    uint8 *expansion8K_1;   // $2000-$3FFF (8KB)
    uint8 *expansion8K_2;   // $4000-$5FFF (8KB)
    uint8 *expansion8K_3;   // $6000-$7FFF (8KB)
    
    uint8 *characterROM;    // $8000-$8FFF (4KB)
    uint8 *colorRAM;        // $9400-$97FF (1KB)
    uint8 *basicROM;        // $A000-$BFFF (8KB)
    uint8 *kernalROM;       // $E000-$FFFF (8KB)
    
    // Cartridge memory
    uint8 *cartridgeROM;
    NSUInteger cartridgeSize;
    VIC20CartridgeType cartridgeType;
    
    // Memory configuration
    VIC20MemoryConfig memoryConfig;
    
    // I/O chip references
    VIC6561 *vic;
    VIA6522 *via1;
    VIA6522 *via2;
    KeyboardMatrix *keyboard;
    
    // Screen memory location
    uint16 screenMemoryBase;
    
    // Debug
    BOOL debugMemoryAccess;
}

// Initialization
- (instancetype)initWithVIC:(VIC6561 *)vicChip VIA1:(VIA6522 *)v1 VIA2:(VIA6522 *)v2;

// Memory access
- (uint8)readMemory:(uint16)address;
- (void)writeMemory:(uint8)value address:(uint16)address;

// ROM loading
- (BOOL)loadCharacterROM:(NSData *)romData;
- (BOOL)loadBasicROM:(NSData *)romData;
- (BOOL)loadKernalROM:(NSData *)romData;

// Cartridge management
- (BOOL)insertCartridge:(NSData *)cartridgeData type:(VIC20CartridgeType)type;
- (void)removeCartridge;

// Memory expansion
- (void)setMemoryConfiguration:(VIC20MemoryConfig)config;
- (VIC20MemoryConfig)getMemoryConfiguration;
- (NSUInteger)getTotalRAMSize;

// I/O integration
- (void)setKeyboard:(KeyboardMatrix *)kbd;
- (void)setScreenMemoryBase:(uint16)base;

// Utility
- (void)reset;
- (void)clearRAM;
- (NSData *)saveMemorySnapshot;
- (BOOL)loadMemorySnapshot:(NSData *)snapshot;

// Debug
- (NSString *)getMemoryMapStatus;
- (void)dumpMemoryRegion:(uint16)start length:(uint16)length;
- (void)setDebugMemoryAccess:(BOOL)debug;

@end