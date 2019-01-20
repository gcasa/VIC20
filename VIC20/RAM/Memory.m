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
    if((self = [super init]) != nil)
    {
        memory = calloc((size_t)size, (size_t)size);
    }
    return self;
}
    
- (id) initWithData: (NSData *)data
{
    if([self initWithSize:[data length]] != nil)
    {
        
    }
    return self;
}
    
- (id) initWithContentsOfFile:(NSString *)file
{
    return self;
}
    
- (void) write: (uint16)data loc: (uint8)loc
{
        
}

- (uint8) read: (uint16)address
{
    return 0;
}

- (void) write: (NSData *)data
{
    
}

- (NSData *)readAtLocation: (uint8)loc length: (uint8)len
{
    
}

@end
