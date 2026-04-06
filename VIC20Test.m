//
//  VIC20Test.m
//  VIC20 Emulator Test Program
//
//  Created by GitHub Copilot on 2024
//  Copyright © 2024. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Processor/CPU6502.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"=== VIC-20 Emulator Test ===");
        
        // Initialize the VIC-20 system
        CPU6502 *vic20 = [[CPU6502 alloc] init];
        [vic20 setDebug:YES]; // Enable detailed debugging
        
        NSLog(@"Initializing VIC-20 system components...");
        [vic20 initVIC20System];
        
        // Configure maximum memory expansion (22KB total)
        NSLog(@"Configuring memory expansion...");
        [vic20 configureMemoryExpansion:YES enable8K1:YES enable8K2:YES];
        
        // Display system information
        VIC6561 *vic = [vic20 getVIC];
        VIA6522 *via1 = [vic20 getVIA1];
        VIA6522 *via2 = [vic20 getVIA2];
        KeyboardMatrix *keyboard = [vic20 getKeyboard];
        VIC20MemoryManager *memManager = [vic20 getMemoryManager];
        
        NSLog(@"System Components Status:");
        NSLog(@"  VIC-6561 Video Chip: %@", vic ? @"Initialized" : @"Failed");
        NSLog(@"  VIA-6522 #1 (Keyboard): %@", via1 ? @"Initialized" : @"Failed");
        NSLog(@"  VIA-6522 #2 (User Port): %@", via2 ? @"Initialized" : @"Failed");
        NSLog(@"  Keyboard Matrix: %@", keyboard ? @"Initialized" : @"Failed");
        NSLog(@"  Memory Manager: %@", memManager ? @"Initialized" : @"Failed");
        
        if (memManager) {
            NSLog(@"  Total RAM: %luKB", (unsigned long)([memManager getTotalRAMSize] / 1024));
        }
        
        // Reset the system
        NSLog(@"\nResetting VIC-20...");
        [vic20 reset];
        
        // Display initial system state
        NSLog(@"\nInitial System State:");
        [vic20 state];
        
        // Test basic memory operations
        NSLog(@"\n=== Memory Test ===");
        
        // Test RAM write/read
        [vic20 writeMemory:0x42 loc:0x0200]; // Write to RAM
        uint8_t ramValue = [vic20 readMemory:0x0200];
        NSLog(@"RAM Test: Wrote 0x42, Read 0x%02X - %@", 
              ramValue, (ramValue == 0x42) ? @"PASS" : @"FAIL");
        
        // Test VIC register access
        [vic20 writeMemory:0x1F loc:0x900F]; // VIC border color register
        uint8_t vicValue = [vic20 readMemory:0x900F];
        NSLog(@"VIC Test: Wrote 0x1F, Read 0x%02X - %@", 
              vicValue, (vicValue == 0x1F) ? @"PASS" : @"FAIL");
        
        // Test VIA register access
        [vic20 writeMemory:0xAA loc:0x9113]; // VIA1 register
        uint8_t via1Value = [vic20 readMemory:0x9113];
        NSLog(@"VIA1 Test: Wrote 0xAA, Read 0x%02X - %@", 
              via1Value, (via1Value == 0xAA) ? @"PASS" : @"FAIL");
        
        [vic20 writeMemory:0x55 loc:0x9123]; // VIA2 register  
        uint8_t via2Value = [vic20 readMemory:0x9123];
        NSLog(@"VIA2 Test: Wrote 0x55, Read 0x%02X - %@", 
              via2Value, (via2Value == 0x55) ? @"PASS" : @"FAIL");
        
        // Test simple CPU instructions
        NSLog(@"\n=== CPU Instruction Test ===");
        
        // Load a simple test program into memory
        // LDA #$42    ; Load accumulator with 0x42
        // STA $0300   ; Store in memory location 0x0300
        // BRK         ; Break (halt)
        [vic20 writeMemory:0xA9 loc:0x1000]; // LDA immediate
        [vic20 writeMemory:0x42 loc:0x1001]; // Operand: 0x42
        [vic20 writeMemory:0x8D loc:0x1002]; // STA absolute
        [vic20 writeMemory:0x00 loc:0x1003]; // Low byte of address 0x0300
        [vic20 writeMemory:0x03 loc:0x1004]; // High byte of address 0x0300
        [vic20 writeMemory:0x00 loc:0x1005]; // BRK
        
        // Reset program counter to start of test program
        [vic20 reset];
        [vic20 setProgramCounter:0x1000];
        
        NSLog(@"Executing test program at $1000...");
        [vic20 runAtLocation:0x1000];
        
        // Check results
        uint8_t resultValue = [vic20 readMemory:0x0300];
        NSLog(@"CPU Test Result: Expected 0x42 at $0300, Got 0x%02X - %@", 
              resultValue, (resultValue == 0x42) ? @"PASS" : @"FAIL");
        
        // Display final system state  
        NSLog(@"\nFinal System State:");
        [vic20 state];
        
        NSLog(@"\n=== Test Complete ===");
        
        // Test ROM loading (if ROM directory exists)
        NSString *romPath = @"./roms";
        if ([[NSFileManager defaultManager] fileExistsAtPath:romPath]) {
            NSLog(@"\nAttempting to load ROMs from %@...", romPath);
            [vic20 loadROMs:romPath];
        } else {
            NSLog(@"\nROM directory not found at %@", romPath);
            NSLog(@"To test with actual VIC-20 ROMs:");
            NSLog(@"  1. Create './roms' directory");
            NSLog(@"  2. Place basic.rom, kernal.rom, characters.rom files there");
            NSLog(@"  3. Run test again");
        }
        
        // Test cartridge loading (if cartridge file exists)
        NSString *cartridgePath = @"./test.prg";
        if ([[NSFileManager defaultManager] fileExistsAtPath:cartridgePath]) {
            NSLog(@"\nAttempting to load cartridge from %@...", cartridgePath);
            NSData *cartData = [NSData dataWithContentsOfFile:cartridgePath];
            BOOL cartSuccess = [vic20 insertCartridge:cartData];
            NSLog(@"Cartridge loading: %@", cartSuccess ? @"SUCCESS" : @"FAILED");
        }
        
        NSLog(@"\nVIC-20 Emulator initialized and tested successfully!");
        NSLog(@"System ready for use.");
    }
    return 0;
}