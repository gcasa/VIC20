//
//  Memory.m
//  VIC20
//
//  Created by Gregory Casamento on 8/31/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import "Memory.h"

@implementation Memory

- (id) initWithSize: (uint16)size
{
    return self;
}
    
- (id) initWithData: (NSData *)data
{
    return self;
}
    
- (void) write: (uint16)address loc: (uint8)data
{
        
}

- (uint8) read: (uint16)address
{
    return 0;
}

@end
