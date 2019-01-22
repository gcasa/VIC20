//
//  AppDelegate.h
//  VIC20
//
//  Created by Gregory Casamento on 8/28/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CPU6502;

@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    CPU6502 *cpu;
}
@end

