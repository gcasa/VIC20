//
//  Memory.h
//  VIC20
//
//  Created by Gregory Casamento on 8/31/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import <Foundation/Foundation.h>

// Type definitions for GNUstep compatibility 
#ifndef VIC20_UINT_TYPES_DEFINED
#define VIC20_UINT_TYPES_DEFINED
typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int uint32;
#endif

@interface Memory : NSObject
{
    uint8 *memory;
}
    
- (id) initWithSize: (NSUInteger)size;
- (id) initWithData: (NSData *)data atLocation: (uint16)loc;
- (id) initWithData: (NSData *)data;
- (id) initWithContentsOfFile:(NSString *)file atLocation: (uint16)loc;
- (id) initWithContentsOfFile: (NSString *)file;
- (void) loadProgramFile: (NSString *)fileName atLocation: (uint16)loc;

- (void) write: (uint8)data loc: (uint16)loc;
- (uint8) read: (uint16)address;
- (void) write: (NSData *)data atLocation: (uint16)loc;
- (NSData *) readAtLocation: (uint16)loc length: (uint16)len;
@end
