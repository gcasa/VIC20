//
//  VIC20DisplayView.h
//  VIC20
//
//  VIC-20 Display View
//  Custom NSView for rendering VIC-20 video output
//

#import <Cocoa/Cocoa.h>

@class VIC6561;

@interface VIC20DisplayView : NSView
{
    VIC6561 *vicChip;
    NSTimer *refreshTimer;
    NSImage *displayImage;
    BOOL maintainAspectRatio;
    NSRect displayRect;
}

@property (nonatomic, strong) VIC6561 *vicChip;
@property (nonatomic) BOOL maintainAspectRatio;

// Display control
- (void)startDisplay;
- (void)stopDisplay;
- (void)refreshDisplay;
- (void)setRefreshRate:(NSTimeInterval)refreshRate;

// Display configuration
- (void)setMaintainAspectRatio:(BOOL)maintain;
- (void)setDisplayFilter:(NSImageInterpolation)filter;

@end