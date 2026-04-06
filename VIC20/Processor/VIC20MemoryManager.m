//
//  VIC20MemoryManager.m
//  VIC20
//  VIC-20 Memory Management System
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import "VIC20MemoryManager.h"
#import "VIC6560.h"
#import "VIA6522.h"
#import "KeyboardMatrix.h"

@implementation VIC20MemoryManager

- (instancetype)initWithVIC:(VIC6561 *)vicChip VIA1:(VIA6522 *)v1 VIA2:(VIA6522 *)v2
{
    self = [super init];
    if (self) {
        vic = vicChip;
        via1 = v1;
        via2 = v2;
        
        [self allocateMemoryBanks];
        [self initializeDefaultConfiguration];
        
        screenMemoryBase = 0x1E00;  // Default screen location
        debugMemoryAccess = NO;
    }
    return self;
}

- (void)dealloc
{
    [self deallocateMemoryBanks];
}

- (void)allocateMemoryBanks
{
    // Allocate base RAM (always present)
    baseRAM = calloc(1, VIC20_RAM_SIZE);
    
    // Allocate color RAM (always present)
    colorRAM = calloc(1, VIC20_COLOR_RAM_SIZE);
    
    // Allocate ROM regions
    characterROM = calloc(1, VIC20_CHAR_ROM_SIZE);
    basicROM = calloc(1, VIC20_BASIC_ROM_SIZE);
    kernalROM = calloc(1, VIC20_KERNAL_ROM_SIZE);
    
    // Expansion RAM (allocated on demand)
    expansion2K = NULL;
    expansion3K = NULL;
    expansion8K_1 = NULL;
    expansion8K_2 = NULL;
    expansion8K_3 = NULL;
    
    // Cartridge
    cartridgeROM = NULL;
    cartridgeSize = 0;
    cartridgeType = VIC20_CARTRIDGE_NONE;
}

- (void)deallocateMemoryBanks
{
    if (baseRAM) { free(baseRAM); baseRAM = NULL; }
    if (colorRAM) { free(colorRAM); colorRAM = NULL; }
    if (characterROM) { free(characterROM); characterROM = NULL; }
    if (basicROM) { free(basicROM); basicROM = NULL; }
    if (kernalROM) { free(kernalROM); kernalROM = NULL; }
    
    if (expansion2K) { free(expansion2K); expansion2K = NULL; }
    if (expansion3K) { free(expansion3K); expansion3K = NULL; }
    if (expansion8K_1) { free(expansion8K_1); expansion8K_1 = NULL; }
    if (expansion8K_2) { free(expansion8K_2); expansion8K_2 = NULL; }
    if (expansion8K_3) { free(expansion8K_3); expansion8K_3 = NULL; }
    
    if (cartridgeROM) { free(cartridgeROM); cartridgeROM = NULL; }
}

- (void)initializeDefaultConfiguration
{
    // Default: no memory expansions
    memoryConfig.expansion_2K = NO;
    memoryConfig.expansion_3K = NO;
    memoryConfig.expansion_8K_1 = NO;
    memoryConfig.expansion_8K_2 = NO;
    memoryConfig.expansion_8K_3 = NO;
}

#pragma mark - Memory Access

- (uint8)readMemory:(uint16)address
{
    if (debugMemoryAccess) {
        NSLog(@"Read from $%04X", address);
    }
    
    // VIC registers ($9000-$900F)
    if (address >= VIC20_VIC_BASE && address < (VIC20_VIC_BASE + VIC20_VIC_SIZE)) {
        return [vic readVICRegister:address];
    }
    
    // VIA1 registers ($9110-$911F) 
    if (address >= VIC20_VIA1_BASE && address < (VIC20_VIA1_BASE + VIC20_VIA_SIZE)) {
        uint8 regAddr = address - VIC20_VIA1_BASE;
        return [via1 readRegister:regAddr];
    }
    
    // VIA2 registers ($9120-$912F)
    if (address >= VIC20_VIA2_BASE && address < (VIC20_VIA2_BASE + VIC20_VIA_SIZE)) {
        uint8 regAddr = address - VIC20_VIA2_BASE;
        return [via2 readRegister:regAddr];
    }
    
    // Color RAM ($9400-$97FF - only 1KB, but mirrored)
    if (address >= VIC20_COLOR_RAM_BASE && address < (VIC20_COLOR_RAM_BASE + 0x0400)) {
        uint16 offset = (address - VIC20_COLOR_RAM_BASE) & 0x03FF;
        return colorRAM[offset] | 0xF0;  // Upper 4 bits always read as 1
    }
    
    // Handle different memory regions
    
    // Base RAM ($0000-$0FFF)
    if (address < VIC20_RAM_SIZE) {
        return baseRAM[address];
    }
    
    // Expansion RAM regions
    if (memoryConfig.expansion_2K && address >= 0x0400 && address < 0x0C00) {
        if (expansion2K) {
            return expansion2K[address - 0x0400];
        }
    }
    
    if (memoryConfig.expansion_3K && address >= 0x0C00 && address < 0x1800) {
        if (expansion3K) {
            return expansion3K[address - 0x0C00];
        }
    }
    
    if (memoryConfig.expansion_8K_1 && address >= 0x2000 && address < 0x4000) {
        if (expansion8K_1) {
            return expansion8K_1[address - 0x2000];
        }
    }
    
    if (memoryConfig.expansion_8K_2 && address >= 0x4000 && address < 0x6000) {
        if (expansion8K_2) {
            return expansion8K_2[address - 0x4000];
        }
    }
    
    // $6000-$7FFF: Cartridge game area or 8K RAM expansion
    if (address >= 0x6000 && address < 0x8000) {
        if (cartridgeType == VIC20_CARTRIDGE_GAME || cartridgeType == VIC20_CARTRIDGE_16K) {
            if (cartridgeROM) {
                return cartridgeROM[address - 0x6000];
            }
        } else if (memoryConfig.expansion_8K_3 && expansion8K_3) {
            return expansion8K_3[address - 0x6000];
        }
    }
    
    // Character ROM ($8000-$8FFF)
    if (address >= VIC20_CHAR_ROM_BASE && address < (VIC20_CHAR_ROM_BASE + VIC20_CHAR_ROM_SIZE)) {
        return characterROM[address - VIC20_CHAR_ROM_BASE];
    }
    
    // $A000-$BFFF: BASIC ROM or Cartridge
    if (address >= VIC20_BASIC_ROM_BASE && address < (VIC20_BASIC_ROM_BASE + VIC20_BASIC_ROM_SIZE)) {
        if (cartridgeType == VIC20_CARTRIDGE_8K || cartridgeType == VIC20_CARTRIDGE_16K) {
            if (cartridgeROM) {
                uint16 offset = (cartridgeType == VIC20_CARTRIDGE_16K) ? 0x2000 : 0;
                return cartridgeROM[offset + (address - VIC20_BASIC_ROM_BASE)];
            }
        } else {
            return basicROM[address - VIC20_BASIC_ROM_BASE];
        }
    }
    
    // 4K Cartridge area ($B000-$BFFF)
    if (address >= 0xB000 && address < 0xC000) {
        if (cartridgeType == VIC20_CARTRIDGE_4K && cartridgeROM) {
            return cartridgeROM[address - 0xB000];
        } else if (cartridgeType != VIC20_CARTRIDGE_8K && cartridgeType != VIC20_CARTRIDGE_16K) {
            // Fall back to BASIC ROM
            return basicROM[address - VIC20_BASIC_ROM_BASE];
        }
    }
    
    // KERNAL ROM ($E000-$FFFF)
    if (address >= VIC20_KERNAL_ROM_BASE) {
        return kernalROM[address - VIC20_KERNAL_ROM_BASE];
    }
    
    // Unmapped region - return 0xFF (floating bus)
    return 0xFF;
}

- (void)writeMemory:(uint8)value address:(uint16)address
{
    if (debugMemoryAccess) {
        NSLog(@"Write $%02X to $%04X", value, address);
    }
    
    // VIC registers ($9000-$900F)
    if (address >= VIC20_VIC_BASE && address < (VIC20_VIC_BASE + VIC20_VIC_SIZE)) {
        [vic writeVICRegister:address value:value];
        return;
    }
    
    // VIA1 registers ($9110-$911F)
    if (address >= VIC20_VIA1_BASE && address < (VIC20_VIA1_BASE + VIC20_VIA_SIZE)) {
        uint8 regAddr = address - VIC20_VIA1_BASE;
        [via1 writeRegister:regAddr value:value];
        
        // Handle keyboard matrix scanning
        if (regAddr == VIA_REG_ORA_IRA && keyboard) {
            // VIA1 Port A controls keyboard row selection
            uint8 matrixResult = [keyboard scanMatrix:value];
            [via2 setPortBInput:matrixResult];
        }
        return;
    }
    
    // VIA2 registers ($9120-$912F)
    if (address >= VIC20_VIA2_BASE && address < (VIC20_VIA2_BASE + VIC20_VIA_SIZE)) {
        uint8 regAddr = address - VIC20_VIA2_BASE;
        [via2 writeRegister:regAddr value:value];
        return;
    }
    
    // Color RAM ($9400-$97FF)
    if (address >= VIC20_COLOR_RAM_BASE && address < (VIC20_COLOR_RAM_BASE + 0x0400)) {
        uint16 offset = (address - VIC20_COLOR_RAM_BASE) & 0x03FF;
        colorRAM[offset] = value & 0x0F;  // Only lower 4 bits writable
        return;
    }
    
    // ROM regions are not writable
    if (address >= VIC20_CHAR_ROM_BASE && address < 0x9000) return;  // Character ROM
    if (address >= VIC20_BASIC_ROM_BASE && address < 0xC000) {
        // Check if cartridge overrides this area
        if (cartridgeType != VIC20_CARTRIDGE_NONE) return;
        return; // BASIC ROM
    }
    if (address >= VIC20_KERNAL_ROM_BASE) return;  // KERNAL ROM
    
    // Write to RAM regions
    
    // Base RAM ($0000-$0FFF)
    if (address < VIC20_RAM_SIZE) {
        baseRAM[address] = value;
        return;
    }
    
    // Expansion RAM regions
    if (memoryConfig.expansion_2K && address >= 0x0400 && address < 0x0C00) {
        if (expansion2K) {
            expansion2K[address - 0x0400] = value;
        }
        return;
    }
    
    if (memoryConfig.expansion_3K && address >= 0x0C00 && address < 0x1800) {
        if (expansion3K) {
            expansion3K[address - 0x0C00] = value;
        }
        return;
    }
    
    if (memoryConfig.expansion_8K_1 && address >= 0x2000 && address < 0x4000) {
        if (expansion8K_1) {
            expansion8K_1[address - 0x2000] = value;
        }
        return;
    }
    
    if (memoryConfig.expansion_8K_2 && address >= 0x4000 && address < 0x6000) {
        if (expansion8K_2) {
            expansion8K_2[address - 0x4000] = value;
        }
        return;
    }
    
    // $6000-$7FFF: Only writable if it's RAM expansion (not cartridge)
    if (address >= 0x6000 && address < 0x8000) {
        if (cartridgeType == VIC20_CARTRIDGE_NONE && memoryConfig.expansion_8K_3 && expansion8K_3) {
            expansion8K_3[address - 0x6000] = value;
        }
        return;
    }
}

#pragma mark - ROM Loading

- (BOOL)loadCharacterROM:(NSData *)romData
{
    if (!romData || [romData length] < VIC20_CHAR_ROM_SIZE) {
        return NO;
    }
    
    memcpy(characterROM, [romData bytes], VIC20_CHAR_ROM_SIZE);
    
    // Also load into VIC chip
    if (vic) {
        [vic loadCharacterROM:romData];
    }
    
    return YES;
}

- (BOOL)loadBasicROM:(NSData *)romData
{
    if (!romData || [romData length] < VIC20_BASIC_ROM_SIZE) {
        return NO;
    }
    
    memcpy(basicROM, [romData bytes], VIC20_BASIC_ROM_SIZE);
    return YES;
}

- (BOOL)loadKernalROM:(NSData *)romData
{
    if (!romData || [romData length] < VIC20_KERNAL_ROM_SIZE) {
        return NO;
    }
    
    memcpy(kernalROM, [romData bytes], VIC20_KERNAL_ROM_SIZE);
    return YES;
}

#pragma mark - Cartridge Management

- (BOOL)insertCartridge:(NSData *)cartridgeData type:(VIC20CartridgeType)type
{
    if (!cartridgeData || type == VIC20_CARTRIDGE_NONE) {
        return NO;
    }
    
    NSUInteger requiredSize = 0;
    switch (type) {
        case VIC20_CARTRIDGE_4K:
            requiredSize = 0x1000;  // 4KB
            break;
        case VIC20_CARTRIDGE_8K:
        case VIC20_CARTRIDGE_GAME:
            requiredSize = 0x2000;  // 8KB
            break;
        case VIC20_CARTRIDGE_16K:
            requiredSize = 0x4000;  // 16KB
            break;
        default:
            return NO;
    }
    
    if ([cartridgeData length] < requiredSize) {
        return NO;
    }
    
    [self removeCartridge];  // Remove existing cartridge
    
    cartridgeSize = requiredSize;
    cartridgeROM = malloc(cartridgeSize);
    memcpy(cartridgeROM, [cartridgeData bytes], cartridgeSize);
    cartridgeType = type;
    
    return YES;
}

- (void)removeCartridge
{
    if (cartridgeROM) {
        free(cartridgeROM);
        cartridgeROM = NULL;
    }
    cartridgeSize = 0;
    cartridgeType = VIC20_CARTRIDGE_NONE;
}

#pragma mark - Memory Expansion

- (void)setMemoryConfiguration:(VIC20MemoryConfig)config
{
    // Deallocate existing expansions if they're being disabled
    if (!config.expansion_2K && expansion2K) {
        free(expansion2K);
        expansion2K = NULL;
    }
    if (!config.expansion_3K && expansion3K) {
        free(expansion3K);
        expansion3K = NULL;
    }
    if (!config.expansion_8K_1 && expansion8K_1) {
        free(expansion8K_1);
        expansion8K_1 = NULL;
    }
    if (!config.expansion_8K_2 && expansion8K_2) {
        free(expansion8K_2);
        expansion8K_2 = NULL;
    }
    if (!config.expansion_8K_3 && expansion8K_3) {
        free(expansion8K_3);
        expansion8K_3 = NULL;
    }
    
    // Allocate new expansions if they're being enabled
    if (config.expansion_2K && !expansion2K) {
        expansion2K = calloc(1, 0x0800);  // 2KB
    }
    if (config.expansion_3K && !expansion3K) {
        expansion3K = calloc(1, 0x0C00);  // 3KB
    }
    if (config.expansion_8K_1 && !expansion8K_1) {
        expansion8K_1 = calloc(1, 0x2000);  // 8KB
    }
    if (config.expansion_8K_2 && !expansion8K_2) {
        expansion8K_2 = calloc(1, 0x2000);  // 8KB
    }
    if (config.expansion_8K_3 && !expansion8K_3) {
        expansion8K_3 = calloc(1, 0x2000);  // 8KB
    }
    
    memoryConfig = config;
}

- (VIC20MemoryConfig)getMemoryConfiguration
{
    return memoryConfig;
}

- (NSUInteger)getTotalRAMSize
{
    NSUInteger totalRAM = VIC20_RAM_SIZE;  // Base 4KB
    
    if (memoryConfig.expansion_2K) totalRAM += 0x0800;   // +2KB
    if (memoryConfig.expansion_3K) totalRAM += 0x0C00;   // +3KB  
    if (memoryConfig.expansion_8K_1) totalRAM += 0x2000; // +8KB
    if (memoryConfig.expansion_8K_2) totalRAM += 0x2000; // +8KB
    if (memoryConfig.expansion_8K_3) totalRAM += 0x2000; // +8KB
    
    return totalRAM;
}

#pragma mark - I/O Integration

- (void)setKeyboard:(KeyboardMatrix *)kbd
{
    keyboard = kbd;
}

- (void)setScreenMemoryBase:(uint16)base
{
    screenMemoryBase = base;
}

#pragma mark - Utility

- (void)reset
{
    [self clearRAM];
    screenMemoryBase = 0x1E00;
}

- (void)clearRAM
{
    if (baseRAM) memset(baseRAM, 0, VIC20_RAM_SIZE);
    if (colorRAM) memset(colorRAM, 0, VIC20_COLOR_RAM_SIZE);
    if (expansion2K) memset(expansion2K, 0, 0x0800);
    if (expansion3K) memset(expansion3K, 0, 0x0C00);
    if (expansion8K_1) memset(expansion8K_1, 0, 0x2000);
    if (expansion8K_2) memset(expansion8K_2, 0, 0x2000);
    if (expansion8K_3) memset(expansion8K_3, 0, 0x2000);
}

- (NSData *)saveMemorySnapshot
{
    NSMutableData *snapshot = [NSMutableData data];
    
    // Save memory configuration
    [snapshot appendBytes:&memoryConfig length:sizeof(memoryConfig)];
    
    // Save RAM contents
    [snapshot appendBytes:baseRAM length:VIC20_RAM_SIZE];
    [snapshot appendBytes:colorRAM length:VIC20_COLOR_RAM_SIZE];
    
    // Save expansion RAM if present
    if (expansion2K) {
        [snapshot appendBytes:expansion2K length:0x0800];
    }
    // Add other expansions as needed...
    
    return snapshot;
}

- (BOOL)loadMemorySnapshot:(NSData *)snapshot
{
    // Implementation would restore memory state from snapshot
    // This is a placeholder for save state functionality
    return NO;
}

#pragma mark - Debug

- (NSString *)getMemoryMapStatus
{
    NSMutableString *status = [NSMutableString string];
    
    [status appendString:@"VIC-20 Memory Map:\n"];
    [status appendFormat:@"Base RAM (4KB): $0000-$0FFF ✓\n"];
    
    if (memoryConfig.expansion_2K) {
        [status appendFormat:@"2KB Expansion: $0400-$0BFF ✓\n"];
    }
    if (memoryConfig.expansion_3K) {
        [status appendFormat:@"3KB Expansion: $0C00-$17FF ✓\n"];
    }
    if (memoryConfig.expansion_8K_1) {
        [status appendFormat:@"8KB Expansion 1: $2000-$3FFF ✓\n"];
    }
    if (memoryConfig.expansion_8K_2) {
        [status appendFormat:@"8KB Expansion 2: $4000-$5FFF ✓\n"];
    }
    if (memoryConfig.expansion_8K_3) {
        [status appendFormat:@"8KB Expansion 3: $6000-$7FFF ✓\n"];
    }
    
    if (cartridgeType != VIC20_CARTRIDGE_NONE) {
        [status appendFormat:@"Cartridge: Type %d, Size %luKB\n", 
         cartridgeType, (unsigned long)(cartridgeSize / 1024)];
    }
    
    [status appendFormat:@"Total RAM: %luKB\n", (unsigned long)([self getTotalRAMSize] / 1024)];
    [status appendFormat:@"Screen Memory: $%04X\n", screenMemoryBase];
    
    return status;
}

- (void)dumpMemoryRegion:(uint16)start length:(uint16)length
{
    NSLog(@"Memory dump from $%04X to $%04X:", start, start + length - 1);
    
    for (uint16 addr = start; addr < start + length; addr += 16) {
        NSMutableString *line = [NSMutableString stringWithFormat:@"$%04X: ", addr];
        
        for (int i = 0; i < 16 && (addr + i) < (start + length); i++) {
            uint8 value = [self readMemory:addr + i];
            [line appendFormat:@"%02X ", value];
        }
        
        NSLog(@"%@", line);
    }
}

- (void)setDebugMemoryAccess:(BOOL)debug
{  
    debugMemoryAccess = debug;
}

@end