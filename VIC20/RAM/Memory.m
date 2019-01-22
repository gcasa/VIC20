//
//  Memory.m
//  VIC20
//
//  Created by Gregory Casamento on 8/31/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import "Memory.h"

@implementation Memory

- (id) initWithSize: (NSUInteger)size
{
    if((self = [super init]) != nil)
    {
        memory = calloc((size_t)size, (size_t)size);
    }
    return self;
}
    
- (id) initWithData: (NSData *)data atLocation: (uint16)loc
{
    if([self initWithSize:[data length]] != nil)
    {
        [self write: data atLocation: loc];
    }
    return self;
}

- (id) initWithData: (NSData *)data
{
    return [self initWithData:data atLocation:0];
}
    
- (id) initWithContentsOfFile:(NSString *)file atLocation: (uint16)loc
{
    NSData *dataForFile = [[NSData alloc] initWithContentsOfFile:file];
    if((self = [self initWithData:dataForFile atLocation:loc]) != nil)
    {
        // load the file into memory...
        NSLog(@"Loaded");
    }
    return self;
}

- (id) initWithContentsOfFile:(NSString *)file
{
    return [self initWithContentsOfFile:file atLocation:0];
}

- (void) loadProgramFile: (NSString *)fileName atLocation: (uint16)loc
{
    NSString *expandedFileName = [fileName stringByExpandingTildeInPath];
    NSData *dataForFile = [[NSData alloc] initWithContentsOfFile: expandedFileName];
    NSInteger len = [dataForFile length];
    uint8 *bytes = (uint8 *)[dataForFile bytes];
    for(int i = loc; i < (loc + len); i++)
    {
        memory[i] = (uint8)bytes[i - loc];
    }
}

- (void) write: (uint8)data loc: (uint16)loc
{
    memory[loc] = data;
}

- (uint8) read: (uint16)address
{
    return memory[address];
}

- (void) write: (NSData *)data atLocation: (uint16)loc
{
    uint8 *bytes = (uint8 *)[data bytes];
    uint16 i = 0, k = 0;
    for(i = loc; i < ([data length] + loc); i++)
    {
        memory[i] = bytes[k];
        k++;
    }
}

- (NSData *)readAtLocation: (uint16)loc length: (uint16)len
{
    NSData *data = [[NSData alloc] initWithBytes:memory length:len];
    return data;
}

@end
