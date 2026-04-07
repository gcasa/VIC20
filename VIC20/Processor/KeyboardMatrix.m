//
//  KeyboardMatrix.m
//  VIC20
//  VIC-20 Keyboard Matrix Scanner
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import "KeyboardMatrix.h"
#import "VIA6522.h"

@implementation KeyboardMatrix

- (instancetype)initWithVIA1:(VIA6522 *)v1 VIA2:(VIA6522 *)v2
{
    self = [super init];
    if (self) {
        via1 = v1;
        via2 = v2;
        [self initializeKeyMapping];
        [self resetMatrix];
    }
    return self;
}

- (void)resetMatrix
{
    // Clear all keys
    for (int row = 0; row < VIC_KEY_ROWS; row++) {
        for (int col = 0; col < VIC_KEY_COLS; col++) {
            keyMatrix[row][col] = NO;
        }
    }
    
    currentRow = 0xFF;
    matrixOutput = 0xFF;
    shiftPressed = NO;
    commodorePressed = NO;
    ctrlPressed = NO;
}

- (void)initializeKeyMapping
{
    // VIC-20 Keyboard Matrix Layout
    // Row 0: 1 3 5 7 9 + £ DEL
    // Row 1: ← W R Y I P * RET
    // Row 2: CTRL A D G J L ; HOME
    // Row 3: STP S F H K : = SH-R
    // Row 4: C= Z C B M . SH-L SPC
    // Row 5: Q E T U O @ ↑ F1
    // Row 6: 2 4 6 8 0 - CLR F3
    // Row 7: SH-LOCK X V N , / SH-R F5
    
    NSMutableDictionary *tempKeyCodeMap = [NSMutableDictionary dictionary];
    NSMutableDictionary *tempCharMap = [NSMutableDictionary dictionary];
    
    // Number row
    [tempCharMap setObject:@[@0, @0] forKey:@"1"];
    [tempCharMap setObject:@[@6, @0] forKey:@"2"];
    [tempCharMap setObject:@[@0, @1] forKey:@"3"]; 
    [tempCharMap setObject:@[@6, @1] forKey:@"4"];
    [tempCharMap setObject:@[@0, @2] forKey:@"5"];
    [tempCharMap setObject:@[@6, @2] forKey:@"6"];
    [tempCharMap setObject:@[@0, @3] forKey:@"7"];
    [tempCharMap setObject:@[@6, @3] forKey:@"8"];
    [tempCharMap setObject:@[@0, @4] forKey:@"9"];
    [tempCharMap setObject:@[@6, @4] forKey:@"0"];
    
    // QWERTY row  
    [tempCharMap setObject:@[@5, @0] forKey:@"Q"];
    [tempCharMap setObject:@[@1, @1] forKey:@"W"];  
    [tempCharMap setObject:@[@5, @1] forKey:@"E"];
    [tempCharMap setObject:@[@1, @2] forKey:@"R"];
    [tempCharMap setObject:@[@5, @2] forKey:@"T"];
    [tempCharMap setObject:@[@1, @3] forKey:@"Y"];
    [tempCharMap setObject:@[@5, @3] forKey:@"U"];
    [tempCharMap setObject:@[@1, @4] forKey:@"I"];
    [tempCharMap setObject:@[@5, @4] forKey:@"O"];
    [tempCharMap setObject:@[@1, @5] forKey:@"P"];
    
    // ASDF row
    [tempCharMap setObject:@[@2, @1] forKey:@"A"];
    [tempCharMap setObject:@[@3, @1] forKey:@"S"];
    [tempCharMap setObject:@[@2, @2] forKey:@"D"];
    [tempCharMap setObject:@[@3, @2] forKey:@"F"]; 
    [tempCharMap setObject:@[@2, @3] forKey:@"G"];
    [tempCharMap setObject:@[@3, @3] forKey:@"H"];
    [tempCharMap setObject:@[@2, @4] forKey:@"J"];
    [tempCharMap setObject:@[@3, @4] forKey:@"K"];
    [tempCharMap setObject:@[@2, @5] forKey:@"L"];
    
    // ZXCV row
    [tempCharMap setObject:@[@4, @1] forKey:@"Z"];
    [tempCharMap setObject:@[@7, @1] forKey:@"X"];
    [tempCharMap setObject:@[@4, @2] forKey:@"C"];
    [tempCharMap setObject:@[@7, @2] forKey:@"V"];
    [tempCharMap setObject:@[@4, @3] forKey:@"B"];
    [tempCharMap setObject:@[@7, @3] forKey:@"N"];
    [tempCharMap setObject:@[@4, @4] forKey:@"M"];
    
    // Special characters
    [tempCharMap setObject:@[@0, @5] forKey:@"+"];
    [tempCharMap setObject:@[@6, @5] forKey:@"-"];
    [tempCharMap setObject:@[@1, @6] forKey:@"*"];
    [tempCharMap setObject:@[@3, @5] forKey:@":"]; 
    [tempCharMap setObject:@[@2, @6] forKey:@";"];
    [tempCharMap setObject:@[@3, @6] forKey:@"="];
    [tempCharMap setObject:@[@5, @5] forKey:@"@"];
    [tempCharMap setObject:@[@7, @4] forKey:@","];
    [tempCharMap setObject:@[@4, @5] forKey:@"."];
    [tempCharMap setObject:@[@7, @5] forKey:@"/"];
    
    // Space and control keys
    [tempCharMap setObject:@[@4, @7] forKey:@" "];  // Space
    
    // Function keys and special keys (using NSEvent keyCodes)
    [tempKeyCodeMap setObject:@[@0, @7] forKey:@(51)];  // Delete/Backspace
    [tempKeyCodeMap setObject:@[@1, @7] forKey:@(36)];  // Return
    [tempKeyCodeMap setObject:@[@2, @7] forKey:@(115)]; // Home  
    [tempKeyCodeMap setObject:@[@6, @6] forKey:@(71)];  // Clear
    [tempKeyCodeMap setObject:@[@5, @6] forKey:@(126)]; // Up arrow
    [tempKeyCodeMap setObject:@[@1, @0] forKey:@(123)]; // Left arrow
    
    // Modifier keys
    [tempKeyCodeMap setObject:@[@4, @6] forKey:@(56)];  // Left Shift
    [tempKeyCodeMap setObject:@[@3, @7] forKey:@(60)];  // Right Shift
    [tempKeyCodeMap setObject:@[@2, @0] forKey:@(59)];  // Ctrl
    [tempKeyCodeMap setObject:@[@4, @0] forKey:@(55)];  // Commodore (Cmd)
    
    // Function keys
    [tempKeyCodeMap setObject:@[@5, @7] forKey:@(122)]; // F1
    [tempKeyCodeMap setObject:@[@6, @7] forKey:@(120)]; // F3
    [tempKeyCodeMap setObject:@[@7, @7] forKey:@(96)];  // F5
    
    // Run/Stop
    [tempKeyCodeMap setObject:@[@3, @0] forKey:@(53)];  // Escape = Run/Stop
    
    keyCodeToMatrix = [tempKeyCodeMap copy];
    charToMatrix = [tempCharMap copy];
}

#pragma mark - Key Events

- (void)keyDown:(NSEvent *)event
{
    NSUInteger keyCode = [event keyCode];
    NSString *chars = [[event charactersIgnoringModifiers] uppercaseString];
    
    // Try keycode mapping first
    NSArray *matrixPos = keyCodeToMatrix[@(keyCode)];
    if (matrixPos) {
        uint8 row = [matrixPos[0] unsignedCharValue];
        uint8 col = [matrixPos[1] unsignedCharValue];
        [self setKey:row col:col pressed:YES];
        return;
    }
    
    // Try character mapping
    if ([chars length] > 0) {
        unichar character = [chars characterAtIndex:0];
        NSArray *charPos = charToMatrix[[NSString stringWithFormat:@"%C", character]];
        if (charPos) {
            uint8 row = [charPos[0] unsignedCharValue]; 
            uint8 col = [charPos[1] unsignedCharValue];
            [self setKey:row col:col pressed:YES];
        }
    }
    
    [self updateMatrixOutput];
}

- (void)keyUp:(NSEvent *)event
{
    NSUInteger keyCode = [event keyCode];
    NSString *chars = [[event charactersIgnoringModifiers] uppercaseString];
    
    // Try keycode mapping first
    NSArray *matrixPos = keyCodeToMatrix[@(keyCode)];
    if (matrixPos) {
        uint8 row = [matrixPos[0] unsignedCharValue];
        uint8 col = [matrixPos[1] unsignedCharValue];
        [self setKey:row col:col pressed:NO];
        return;
    }
    
    // Try character mapping
    if ([chars length] > 0) {
        unichar character = [chars characterAtIndex:0];
        NSArray *charPos = charToMatrix[[NSString stringWithFormat:@"%C", character]];
        if (charPos) {
            uint8 row = [charPos[0] unsignedCharValue];
            uint8 col = [charPos[1] unsignedCharValue];
            [self setKey:row col:col pressed:NO];
        }
    }
    
    [self updateMatrixOutput];
}

- (void)flagsChanged:(NSEvent *)event
{
    NSUInteger flags = [event modifierFlags];
    
    // Update modifier states
    BOOL newShift = (flags & NSEventModifierFlagShift) != 0;
    BOOL newCmd = (flags & NSEventModifierFlagCommand) != 0;
    BOOL newCtrl = (flags & NSEventModifierFlagControl) != 0;
    
    if (newShift != shiftPressed) {
        shiftPressed = newShift;
        [self setKey:4 col:6 pressed:shiftPressed];  // Left shift
    }
    
    if (newCmd != commodorePressed) {
        commodorePressed = newCmd;
        [self setKey:4 col:0 pressed:commodorePressed];  // Commodore key
    }
    
    if (newCtrl != ctrlPressed) {
        ctrlPressed = newCtrl;
        [self setKey:2 col:0 pressed:ctrlPressed];  // Ctrl
    }
    
    [self updateMatrixOutput];
}

#pragma mark - Matrix Scanning

- (uint8)scanMatrix:(uint8)rowSelect
{
    currentRow = rowSelect;
    uint8 result = 0xFF;  // Start with all bits high
    
    // Scan each row that's selected (0 = selected)
    for (int row = 0; row < VIC_KEY_ROWS; row++) {
        if ((rowSelect & (1 << row)) == 0) {
            // This row is being scanned
            for (int col = 0; col < VIC_KEY_COLS; col++) {
                if (keyMatrix[row][col]) {
                    result &= ~(1 << col);  // Pull column line low
                }
            }
        }
    }
    
    return result;
}

- (void)updateMatrixOutput
{
    // This would be called when the keyboard matrix changes
    // The VIA would read this through port scanning
    matrixOutput = [self scanMatrix:currentRow];
}

#pragma mark - Direct Key Control

- (void)setKey:(uint8)row col:(uint8)col pressed:(BOOL)pressed
{
    if (row < VIC_KEY_ROWS && col < VIC_KEY_COLS) {
        keyMatrix[row][col] = pressed;
    }
}

- (BOOL)isKeyPressed:(uint8)row col:(uint8)col
{
    if (row < VIC_KEY_ROWS && col < VIC_KEY_COLS) {
        return keyMatrix[row][col];
    }
    return NO;
}

#pragma mark - Utility Methods

- (void)pressKey:(unichar)character
{
    NSString *charString = [[NSString stringWithFormat:@"%C", character] uppercaseString];
    NSArray *matrixPos = charToMatrix[charString];
    if (matrixPos) {
        uint8 row = [matrixPos[0] unsignedCharValue];
        uint8 col = [matrixPos[1] unsignedCharValue];
        [self setKey:row col:col pressed:YES];
        [self updateMatrixOutput];
    }
}

- (void)releaseKey:(unichar)character
{
    NSString *charString = [[NSString stringWithFormat:@"%C", character] uppercaseString];
    NSArray *matrixPos = charToMatrix[charString];
    if (matrixPos) {
        uint8 row = [matrixPos[0] unsignedCharValue];
        uint8 col = [matrixPos[1] unsignedCharValue];
        [self setKey:row col:col pressed:NO];
        [self updateMatrixOutput];
    }
}

- (void)typeString:(NSString *)text
{
    // Simulate typing a string
    for (NSUInteger i = 0; i < [text length]; i++) {
        unichar character = [text characterAtIndex:i];
        [self pressKey:character];
        
        // Small delay for timing using performSelector instead of GCD
        [self performSelector:@selector(releaseKeyForCharacter:) 
                   withObject:@(character) 
                   afterDelay:0.05];
    }
}

- (void)releaseKeyForCharacter:(NSNumber *)characterNumber
{
    unichar character = [characterNumber unsignedShortValue];
    [self releaseKey:character];
}

#pragma mark - Debug

- (void)dumpMatrix
{
    NSLog(@"Keyboard Matrix Status:");
    NSLog(@"Row Select: $%02X, Matrix Output: $%02X", currentRow, matrixOutput);
    
    for (int row = 0; row < VIC_KEY_ROWS; row++) {
        NSMutableString *rowString = [NSMutableString stringWithFormat:@"Row %d: ", row];
        for (int col = 0; col < VIC_KEY_COLS; col++) {
            [rowString appendString:keyMatrix[row][col] ? @"X" : @"."];
        }
        NSLog(@"%@", rowString);
    }
    
    NSLog(@"Modifiers: Shift=%s, Commodore=%s, Ctrl=%s", 
          shiftPressed ? "On" : "Off",
          commodorePressed ? "On" : "Off", 
          ctrlPressed ? "On" : "Off");
}

- (NSString *)getMatrixStatus
{
    NSMutableString *status = [NSMutableString string];
    
    [status appendString:@"Keyboard Matrix Status:\n"];
    [status appendFormat:@"Current Row Select: $%02X\n", currentRow];
    [status appendFormat:@"Matrix Output: $%02X\n", matrixOutput];
    
    int pressedKeys = 0;
    for (int row = 0; row < VIC_KEY_ROWS; row++) {
        for (int col = 0; col < VIC_KEY_COLS; col++) {
            if (keyMatrix[row][col]) {
                pressedKeys++;
            }
        }
    }
    
    [status appendFormat:@"Keys Pressed: %d\n", pressedKeys];
    [status appendFormat:@"Modifiers: Shift=%s, Cmd=%s, Ctrl=%s\n",
     shiftPressed ? "Yes" : "No",
     commodorePressed ? "Yes" : "No",
     ctrlPressed ? "Yes" : "No"];
    
    return status;
}

@end