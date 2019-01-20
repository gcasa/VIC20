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
    
- (id) initWithSize: (uint16)size;
- (id) initWithData: (NSData *)data;
- (id) initWithContentsOfFile: (NSString *)file;
- (void) write: (uint16)data loc: (uint8)loc
- (uint8) read: (uint16)address;
- (void) write: (NSData *)data
- (NSData *) readAtLocation: (uint8)loc length: (uint8)len;
@end
