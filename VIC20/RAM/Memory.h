//
//  Memory.h
//  VIC20
//
//  Created by Gregory Casamento on 8/31/18.
//  Copyright © 2018 Open Logic. All rights reserved.
//

#import <Foundation/Foundation.h>

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
