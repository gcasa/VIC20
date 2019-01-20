//
//  ROM.m
//  VIC20
//
//  Created by Gregory Casamento on 8/31/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import "ROM.h"

@implementation ROM

- (void) write: (NSData *)data atLocation: (uint16)loc
{
    NSLog(@"Writing to read only memory");
}

@end
