//
//  AppDelegate.m
//  VIC20
//
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import "AppDelegate.h"
#import "CPU6502.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    NSString *pathForResource = [[NSBundle mainBundle] pathForResource:@"temp" ofType:@"img"];
    cpu = [[CPU6502 alloc] initWithSize: 64*1024];
    [cpu loadProgramFile: pathForResource atLocation: 1000];
    [cpu executeAtLocation: 1000];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


@end
