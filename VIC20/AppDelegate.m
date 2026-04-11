//
//  AppDelegate.m
//  VIC20
//
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import "AppDelegate.h"
#import "CPU6502.h"
#import "VIC6560.h"
#import "VIC20DisplayView.h"
#import "RAM.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Initialize system components
    [self setupSystemComponents];
    
    // Setup display
    [self setupDisplay];
    
    // Start emulation
    [self startEmulation];
}

- (void)setupSystemComponents
{
    // Create system RAM (64K)
    systemRAM = [[RAM alloc] initWithSize:64*1024];
    
    // Initialize VIC chip with system RAM
    vicChip = [[VIC6561 alloc] initWithRAM:systemRAM];
    
    // Initialize CPU with system RAM and VIC chip
    cpu = [[CPU6502 alloc] initWithRAM: systemRAM VIC:vicChip];

    // Load character ROM data into VIC chip
    [vicChip loadDefaultCharacterSet];
    
    // Load program if available
    NSString *pathForResource = [[NSBundle mainBundle] pathForResource:@"temp" ofType:@"img"];
    if (pathForResource) {
        [cpu loadProgramFile:pathForResource atLocation:1000];
    }
}

- (void)setupDisplay
{
    if (!window) {
        // Create window if not loaded from nib
        NSRect windowFrame = NSMakeRect(100, 100, 704, 576); // 4x scale of VIC display
        window = [[NSWindow alloc] initWithContentRect:windowFrame
                                             styleMask:(NSWindowStyleMaskTitled | 
                                                       NSWindowStyleMaskClosable | 
                                                       NSWindowStyleMaskMiniaturizable | 
                                                       NSWindowStyleMaskResizable)
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
        
        [window setTitle:@"VIC-20 Emulator"];
        [window center];
        [window makeKeyAndOrderFront:nil];
    }
    
    // Create display view
    NSRect contentRect = [[window contentView] bounds];
    displayView = [[VIC20DisplayView alloc] initWithFrame:contentRect];
    [displayView setVicChip:vicChip];
    [displayView setMaintainAspectRatio:YES];
    [displayView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    
    // Add display view to window
    [[window contentView] addSubview:displayView];
    
    // Configure window
    [window setAcceptsMouseMovedEvents:YES];
    [window setDelegate:self];
    
    // Set minimum window size to maintain readability
    NSSize minSize = NSMakeSize(VIC_SCREEN_WIDTH_PIXELS * 2, VIC_SCREEN_HEIGHT_PIXELS * 2);
    [window setMinSize:minSize];
    
    // Set initial background color
    [window setBackgroundColor:[NSColor blackColor]];
}

- (void)startEmulation
{
    // Start VIC display
    [displayView startDisplay];
    
    // Start CPU execution (this should be done in a separate thread for real emulation)
    if (cpu) {
        [cpu runAtLocation:1000];
    }
}

- (void)stopEmulation
{
    // Stop display refresh
    [displayView stopDisplay];
    
    // Stop CPU (would need to implement pause/stop functionality in CPU6502)
    // [cpu stop];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Stop emulation
    [self stopEmulation];
}

#pragma mark - NSWindowDelegate

- (BOOL)windowShouldClose:(NSWindow *)sender
{
    [NSApp terminate:self];
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self stopEmulation];
}

#pragma mark - Menu Actions

- (IBAction)reset:(id)sender
{
    // Reset emulator
    [self stopEmulation];
    [self setupSystemComponents];
    [displayView setVicChip:vicChip];
    [self startEmulation];
}

- (IBAction)togglePause:(id)sender
{
    // Toggle pause/resume (would need CPU pause functionality)
    static BOOL isPaused = NO;
    
    if (isPaused) {
        [self startEmulation];
        isPaused = NO;
    } else {
        [self stopEmulation];
        isPaused = YES;
    }
}

@end
