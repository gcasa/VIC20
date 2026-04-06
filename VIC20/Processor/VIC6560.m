//
//  VIC6560.m
//  VIC20
//  VIC chip
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import "VIC6560.h"
#import "RAM.h"
#import <AudioToolbox/AudioToolbox.h>

@implementation VIC6561

- (instancetype)initWithRAM:(RAM *)ram
{
    self = [super init];
    if (self) {
        systemRAM = ram;
        
        // Initialize default values
        [self resetRegisters];
        [self initializeColorPalette];
        [self createDisplayBuffer];
        
        // Default configuration
        PALMode = YES;  // Default to PAL timing
        screenColumns = VIC_SCREEN_WIDTH_CHARS;
        screenRows = VIC_SCREEN_HEIGHT_CHARS;
        doubleHeight = NO;
        
        // Memory locations
        screenMatrixBase = VIC_SCREEN_MATRIX_BASE;
        colorMatrixBase = VIC_COLOR_MATRIX_BASE;
        characterROMBase = VIC_CHAR_ROM_BASE;
        
        cycles = 0;
        scanLine = 0;
        vBlankFlag = NO;
    }
    return self;
}

- (void)resetRegisters
{
    // Initialize VIC registers to power-on defaults
    memset(registers, 0, sizeof(registers));
    
    registers[VIC_REG_HORZ_CENTER] = 12;   // Default horizontal centering
    registers[VIC_REG_VERT_CENTER] = 38;   // Default vertical centering
    registers[VIC_REG_VIDEO_COLUMNS] = 150; // 22 columns
    registers[VIC_REG_VIDEO_ROWS] = 46;    // 23 rows
    registers[VIC_REG_CHAR_SIZE] = 0;      // 8x8 characters
    registers[VIC_REG_VOLUME_COLOR] = 0;   // Volume 0, black auxiliary color
    registers[VIC_REG_SCREEN_COLOR] = VIC_COLOR_LIGHT_BLUE; // Light blue screen
}

- (void)initializeColorPalette
{
    // VIC-20 color palette
    colorPalette[VIC_COLOR_BLACK] = [NSColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    colorPalette[VIC_COLOR_WHITE] = [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    colorPalette[VIC_COLOR_RED] = [NSColor colorWithRed:0.78 green:0.24 blue:0.24 alpha:1.0];
    colorPalette[VIC_COLOR_CYAN] = [NSColor colorWithRed:0.44 green:0.89 blue:0.89 alpha:1.0];
    colorPalette[VIC_COLOR_PURPLE] = [NSColor colorWithRed:0.78 green:0.44 blue:0.87 alpha:1.0];
    colorPalette[VIC_COLOR_GREEN] = [NSColor colorWithRed:0.35 green:0.78 blue:0.35 alpha:1.0];
    colorPalette[VIC_COLOR_BLUE] = [NSColor colorWithRed:0.22 green:0.33 blue:0.78 alpha:1.0];
    colorPalette[VIC_COLOR_YELLOW] = [NSColor colorWithRed:0.89 green:0.89 blue:0.44 alpha:1.0];
    colorPalette[VIC_COLOR_ORANGE] = [NSColor colorWithRed:0.78 green:0.55 blue:0.22 alpha:1.0];
    colorPalette[VIC_COLOR_LIGHT_ORANGE] = [NSColor colorWithRed:0.87 green:0.67 blue:0.44 alpha:1.0];
    colorPalette[VIC_COLOR_PINK] = [NSColor colorWithRed:0.87 green:0.67 blue:0.67 alpha:1.0];
    colorPalette[VIC_COLOR_LIGHT_CYAN] = [NSColor colorWithRed:0.67 green:0.94 blue:0.94 alpha:1.0];
    colorPalette[VIC_COLOR_LIGHT_PURPLE] = [NSColor colorWithRed:0.87 green:0.67 blue:0.94 alpha:1.0];
    colorPalette[VIC_COLOR_LIGHT_GREEN] = [NSColor colorWithRed:0.67 green:0.87 blue:0.67 alpha:1.0];
    colorPalette[VIC_COLOR_LIGHT_BLUE] = [NSColor colorWithRed:0.67 green:0.73 blue:0.87 alpha:1.0];
    colorPalette[VIC_COLOR_LIGHT_YELLOW] = [NSColor colorWithRed:0.94 green:0.94 blue:0.67 alpha:1.0];
}

- (void)createDisplayBuffer
{
    displayBuffer = [[NSBitmapImageRep alloc] 
                    initWithBitmapDataPlanes:NULL
                    pixelsWide:VIC_SCREEN_WIDTH_PIXELS
                    pixelsHigh:VIC_SCREEN_HEIGHT_PIXELS
                    bitsPerSample:8
                    samplesPerPixel:3
                    hasAlpha:NO
                    isPlanar:NO
                    colorSpaceName:NSCalibratedRGBColorSpace
                    bytesPerRow:0
                    bitsPerPixel:24];
}

#pragma mark - Register Access

- (void)writeRegister:(uint8)address value:(uint8)value
{
    if (address >= 16) return;
    
    registers[address] = value;
    
    // Handle specific register updates
    switch (address) {
        case VIC_REG_VIDEO_COLUMNS:
            screenColumns = (value & 0x80) ? VIC_SCREEN_WIDTH_CHARS : (VIC_SCREEN_WIDTH_CHARS - 1);
            PALMode = !(value & 0x08);  // Bit 3 controls NTSC/PAL
            break;
            
        case VIC_REG_VIDEO_ROWS:
            screenRows = ((value & 0x7E) >> 1) + 1;
            doubleHeight = (value & 0x01) != 0;
            break;
            
        case VIC_REG_FREQ_VOICE1_LO:
        case VIC_REG_FREQ_VOICE2_LO:
        case VIC_REG_FREQ_VOICE3_LO:
        case VIC_REG_FREQ_NOISE_LO:
        case VIC_REG_VOLUME_COLOR:
        case VIC_REG_SCREEN_COLOR:
            [self updateSound];
            break;
    }
}

- (uint8)readRegister:(uint8)address
{
    if (address >= 16) return 0;
    
    switch (address) {
        case VIC_REG_LIGHT_PEN_X:
            return lightPenX;
        case VIC_REG_LIGHT_PEN_Y:
            return lightPenY;
        case VIC_REG_PADDLE_X:
            return paddleX;
        case VIC_REG_PADDLE_Y:
            return paddleY;
        default:
            return registers[address];
    }
}

#pragma mark - Video Operations

- (void)renderFrame
{
    // Clear screen with background color
    uint8 backgroundColor = registers[VIC_REG_SCREEN_COLOR] & 0x0F;
    NSColor *bgColor = colorPalette[backgroundColor];
    
    // Fill entire buffer with background color
    unsigned char *bitmapData = [displayBuffer bitmapData];
    NSInteger bytesPerRow = [displayBuffer bytesPerRow];
    
    CGFloat red, green, blue, alpha;
    [bgColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    for (int y = 0; y < VIC_SCREEN_HEIGHT_PIXELS; y++) {
        for (int x = 0; x < VIC_SCREEN_WIDTH_PIXELS; x++) {
            unsigned char *pixel = bitmapData + y * bytesPerRow + x * 3;
            pixel[0] = (unsigned char)(red * 255);
            pixel[1] = (unsigned char)(green * 255);
            pixel[2] = (unsigned char)(blue * 255);
        }
    }
    
    // Render characters
    for (int row = 0; row < screenRows && row < VIC_SCREEN_HEIGHT_CHARS; row++) {
        for (int col = 0; col < screenColumns && col < VIC_SCREEN_WIDTH_CHARS; col++) {
            [self renderCharacter:row column:col];
        }
    }
}

- (void)renderCharacter:(int)row column:(int)col
{
    // Get character code from screen matrix
    uint16 screenOffset = row * screenColumns + col;
    uint8 charCode = [self readVideoMatrix:screenOffset];
    
    // Get color from color matrix
    uint8 colorCode = [self readColorMatrix:screenOffset] & 0x0F;
    NSColor *charColor = colorPalette[colorCode];
    
    // Get character bitmap from character ROM
    uint16 charROMOffset = charCode * 8;  // 8 bytes per character
    
    // Render 8x8 character
    unsigned char *bitmapData = [displayBuffer bitmapData];
    NSInteger bytesPerRow = [displayBuffer bytesPerRow];
    
    CGFloat red, green, blue, alpha;
    [charColor getRed:&red green:&green blue:&blue alpha:&alpha];
    
    for (int charRow = 0; charRow < VIC_CHAR_HEIGHT_PIXELS; charRow++) {
        uint8 charLine = [self readCharacterROM:charROMOffset + charRow];
        
        int pixelY = row * VIC_CHAR_HEIGHT_PIXELS + charRow;
        if (doubleHeight) pixelY *= 2;
        
        for (int charCol = 0; charCol < VIC_CHAR_WIDTH_PIXELS; charCol++) {
            if (charLine & (0x80 >> charCol)) {  // Pixel is set
                int pixelX = col * VIC_CHAR_WIDTH_PIXELS + charCol;
                
                if (pixelX < VIC_SCREEN_WIDTH_PIXELS && pixelY < VIC_SCREEN_HEIGHT_PIXELS) {
                    unsigned char *pixel = bitmapData + pixelY * bytesPerRow + pixelX * 3;
                    pixel[0] = (unsigned char)(red * 255);
                    pixel[1] = (unsigned char)(green * 255);
                    pixel[2] = (unsigned char)(blue * 255);
                    
                    // Double height mode
                    if (doubleHeight && (pixelY + 1) < VIC_SCREEN_HEIGHT_PIXELS) {
                        pixel = bitmapData + (pixelY + 1) * bytesPerRow + pixelX * 3;
                        pixel[0] = (unsigned char)(red * 255);
                        pixel[1] = (unsigned char)(green * 255);
                        pixel[2] = (unsigned char)(blue * 255);
                    }
                }
            }
        }
    }
}

- (NSBitmapImageRep *)getDisplayBuffer
{
    return displayBuffer;
}

#pragma mark - Sound Operations

- (void)updateSound
{
    // Extract frequencies from registers
    voice1Frequency = registers[VIC_REG_FREQ_VOICE1_LO] | 
                     ((registers[VIC_REG_SCREEN_COLOR] & 0x10) << 4);
    voice2Frequency = registers[VIC_REG_FREQ_VOICE2_LO] | 
                     ((registers[VIC_REG_SCREEN_COLOR] & 0x20) << 3);
    voice3Frequency = registers[VIC_REG_FREQ_VOICE3_LO] | 
                     ((registers[VIC_REG_SCREEN_COLOR] & 0x40) << 2);
    noiseFrequency = registers[VIC_REG_FREQ_NOISE_LO] | 
                    ((registers[VIC_REG_SCREEN_COLOR] & 0x80) << 1);
    
    // Extract volume
    volume = registers[VIC_REG_VOLUME_COLOR] & 0x0F;
    
    // Determine which voices are enabled (non-zero frequency)
    soundEnabled[0] = (voice1Frequency > 0);
    soundEnabled[1] = (voice2Frequency > 0);
    soundEnabled[2] = (voice3Frequency > 0);
    soundEnabled[3] = (noiseFrequency > 0);
    
    // TODO: Generate actual audio output
    // This would require Core Audio implementation for real sound
}

- (void)generateTone:(int)voice frequency:(uint16)freq enabled:(BOOL)enabled
{
    // Placeholder for actual audio generation
    // In a full implementation, this would generate square wave tones
    // using Core Audio or similar audio framework
}

- (void)setVolume:(uint8)vol
{
    volume = vol & 0x0F;
}

#pragma mark - Memory Interface

- (uint8)readVideoMatrix:(uint16)offset
{
    return [systemRAM read:(screenMatrixBase + offset)];
}

- (uint8)readColorMatrix:(uint16)offset
{
    return [systemRAM read:(colorMatrixBase + offset)];
}

- (uint8)readCharacterROM:(uint16)offset
{
    // In a real VIC-20, this would read from character ROM
    // For now, return a simple pattern or load from ROM file
    return [systemRAM read:(characterROMBase + offset)];
}

#pragma mark - Timing and Interrupts

- (void)tick
{
    cycles++;
    
    // VIC timing - approximate values
    NSUInteger cyclesPerLine = PALMode ? 71 : 65;
    NSUInteger linesPerFrame = PALMode ? 312 : 261;
    
    if (cycles >= cyclesPerLine) {
        cycles = 0;
        scanLine++;
        
        if (scanLine >= linesPerFrame) {
            scanLine = 0;
            vBlankFlag = YES;
            // Frame complete - could trigger interrupt here
        }
    }
}

- (BOOL)isVBlank
{
    return vBlankFlag;
}

- (void)setVBlank:(BOOL)vblank
{
    vBlankFlag = vblank;
}

#pragma mark - Input Handling

- (void)setLightPen:(uint8)x y:(uint8)y
{
    lightPenX = x;
    lightPenY = y;
}

- (void)setPaddle:(uint8)x y:(uint8)y
{
    paddleX = x;
    paddleY = y;
}

#pragma mark - Configuration

- (void)setPALMode:(BOOL)palMode
{
    PALMode = palMode;
}

- (void)setScreenSize:(uint8)columns rows:(uint8)rows
{
    screenColumns = MIN(columns, VIC_SCREEN_WIDTH_CHARS);
    screenRows = MIN(rows, VIC_SCREEN_HEIGHT_CHARS);
}

#pragma mark - Integration Helpers

- (void)loadCharacterROM:(NSData *)romData
{
    // Load character ROM data into system memory at character ROM base
    if (romData && [romData length] >= 2048) {  // VIC-20 character ROM is 2KB
        [systemRAM write:romData atLocation:characterROMBase];
    } else {
        // Load default character set if no ROM provided
        [self loadDefaultCharacterSet];
    }
}

- (void)loadDefaultCharacterSet
{
    // Create a basic ASCII-like character set for testing
    // This is a simplified version - real VIC-20 character ROM is more complex
    
    uint8 defaultCharData[2048];
    memset(defaultCharData, 0, sizeof(defaultCharData));
    
    // Define some basic characters (space, letters, numbers)
    // Space (0x20) - all zeros (already set)
    
    // Letter 'A' (0x41 = 65)
    uint8 charA[] = {0x18, 0x24, 0x42, 0x7E, 0x42, 0x42, 0x42, 0x00};
    memcpy(&defaultCharData[65 * 8], charA, 8);
    
    // Letter 'B' (0x42 = 66) 
    uint8 charB[] = {0x7C, 0x42, 0x42, 0x7C, 0x42, 0x42, 0x7C, 0x00};
    memcpy(&defaultCharData[66 * 8], charB, 8);
    
    // Add more characters as needed...
    
    // Store in RAM
    NSData *charROMData = [NSData dataWithBytes:defaultCharData length:sizeof(defaultCharData)];
    [systemRAM write:charROMData atLocation:characterROMBase];
}

- (NSImage *)createDisplayImage
{
    [self renderFrame];
    
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(VIC_SCREEN_WIDTH_PIXELS, VIC_SCREEN_HEIGHT_PIXELS)];
    [image addRepresentation:displayBuffer];
    return image;
}

- (void)refreshDisplay
{
    [self renderFrame];
}

#pragma mark - Debug Helpers

- (NSString *)getRegisterStatus
{
    NSMutableString *status = [NSMutableString string];
    
    [status appendFormat:@"VIC-6561 Register Status:\n"];
    [status appendFormat:@"Horizontal Center: %d\n", registers[VIC_REG_HORZ_CENTER]];
    [status appendFormat:@"Vertical Center: %d\n", registers[VIC_REG_VERT_CENTER]];
    [status appendFormat:@"Screen Columns: %d\n", screenColumns];
    [status appendFormat:@"Screen Rows: %d\n", screenRows];
    [status appendFormat:@"Double Height: %s\n", doubleHeight ? "Yes" : "No"];
    [status appendFormat:@"PAL Mode: %s\n", PALMode ? "Yes" : "No"];
    [status appendFormat:@"Volume: %d\n", volume];
    [status appendFormat:@"Screen Color: %d\n", registers[VIC_REG_SCREEN_COLOR] & 0x0F];
    [status appendFormat:@"Voice 1 Freq: %d\n", voice1Frequency];
    [status appendFormat:@"Voice 2 Freq: %d\n", voice2Frequency];
    [status appendFormat:@"Voice 3 Freq: %d\n", voice3Frequency];
    [status appendFormat:@"Noise Freq: %d\n", noiseFrequency];
    [status appendFormat:@"Scan Line: %lu\n", (unsigned long)scanLine];
    [status appendFormat:@"VBlank: %s\n", vBlankFlag ? "Yes" : "No"];
    
    return status;
}

- (void)dumpVideoMatrix
{
    NSLog(@"Video Matrix Dump:");
    
    for (int row = 0; row < screenRows; row++) {
        NSMutableString *rowString = [NSMutableString string];
        for (int col = 0; col < screenColumns; col++) {
            uint16 offset = row * screenColumns + col;
            uint8 charCode = [self readVideoMatrix:offset];
            [rowString appendFormat:@"%02X ", charCode];
        }
        NSLog(@"Row %2d: %@", row, rowString);
    }
}

// Helper method for CPU integration
- (void)writeVICRegister:(uint16)address value:(uint8)value
{
    // VIC registers are typically mapped at 0x9000-0x900F in VIC-20
    uint8 regAddr = address & 0x0F;
    [self writeRegister:regAddr value:value];
}

- (uint8)readVICRegister:(uint16)address
{
    // VIC registers are typically mapped at 0x9000-0x900F in VIC-20  
    uint8 regAddr = address & 0x0F;
    return [self readRegister:regAddr];
}

@end
