//
//  AppDelegate.h
//  VIC20
//
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CPU6502;
@class VIC6561;
@class VIC20DisplayView;
@class RAM;

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    CPU6502 *cpu;
    VIC6561 *vicChip;
    VIC20DisplayView *displayView;
    RAM *systemRAM;
}

@property IBOutlet NSWindow *window;

// Display management
- (void)setupDisplay;
- (void)startEmulation;
- (void)stopEmulation;

@end

