//
//  VIC20DisplayView.m
//  VIC20
//
//  VIC-20 Display View Implementation
//  Custom NSView for rendering VIC-20 video output
//

#import "VIC20DisplayView.h"
#import "VIC6560.h"

@implementation VIC20DisplayView

@synthesize vicChip;
@synthesize maintainAspectRatio;

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    maintainAspectRatio = YES;
    refreshTimer = nil;
    displayImage = nil;
    
    // Calculate initial display rect
    [self calculateDisplayRect];
    
    // Set up view properties
    // [self setWantsLayer:YES];
    // self.layer.backgroundColor = [[NSColor blackColor] CGColor];
    
    // Enable layer-backed rendering for better performance
    // self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

- (void)dealloc
{
    [self stopDisplay];
}

#pragma mark - Display Control

- (void)startDisplay
{
    if (refreshTimer && [refreshTimer isValid]) {
        return; // Already running
    }
    
    // Start refresh timer at approximately 60 FPS (VIC-20 PAL is ~50Hz, NTSC is ~60Hz)
    NSTimeInterval refreshRate = 1.0/60.0;
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:refreshRate
                                                    target:self
                                                  selector:@selector(timerRefresh:)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)stopDisplay
{
    if (refreshTimer && [refreshTimer isValid]) {
        [refreshTimer invalidate];
    }
    refreshTimer = nil;
}

- (void)setRefreshRate:(NSTimeInterval)refreshRate
{
    if (refreshTimer && [refreshTimer isValid]) {
        [refreshTimer invalidate];
    }
    
    refreshTimer = [NSTimer scheduledTimerWithTimeInterval:refreshRate
                                                    target:self
                                                  selector:@selector(timerRefresh:)
                                                  userInfo:nil
                                                   repeats:YES];
}

- (void)timerRefresh:(NSTimer *)timer
{
    [self refreshDisplay];
}

- (void)refreshDisplay
{
    if (!vicChip) {
        return;
    }
    
    // Render the current frame
    [vicChip renderFrame];
    
    // Get the display buffer and create NSImage
    NSBitmapImageRep *displayBuffer = [vicChip getDisplayBuffer];
    if (displayBuffer) {
        displayImage = [[NSImage alloc] init];
        [displayImage addRepresentation:displayBuffer];
        
        // Trigger redraw
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setNeedsDisplay:YES];
        });
    }
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    // Fill background with black
    [[NSColor blackColor] setFill];
    NSRectFill(dirtyRect);
    
    if (!displayImage) {
        // Draw a placeholder when no VIC output is available
        [[NSColor darkGrayColor] setFill];
        NSRect placeholderRect = NSMakeRect(self.bounds.size.width/4, 
                                          self.bounds.size.height/4,
                                          self.bounds.size.width/2, 
                                          self.bounds.size.height/2);
        NSRectFill(placeholderRect);
        
        // Draw text
        NSString *placeholderText = @"VIC-20 Display\nNo Signal";
        NSDictionary *attributes = @{
            NSForegroundColorAttributeName: [NSColor whiteColor],
            NSFontAttributeName: [NSFont systemFontOfSize:16]
        };
        
        NSSize textSize = [placeholderText sizeWithAttributes:attributes];
        NSPoint textPoint = NSMakePoint(
            (self.bounds.size.width - textSize.width) / 2,
            (self.bounds.size.height - textSize.height) / 2
        );
        
        [placeholderText drawAtPoint:textPoint withAttributes:attributes];
        return;
    }
    
    // Calculate display rectangle maintaining aspect ratio if requested
    [self calculateDisplayRect];
    
    // Draw the VIC display image
    [displayImage drawInRect:displayRect
                    fromRect:NSZeroRect
                   operation:NSCompositingOperationSourceOver
                    fraction:1.0];

    // Draw border if display doesn't fill the entire view
    if (!NSEqualRects(displayRect, self.bounds)) {
        [[NSColor darkGrayColor] setStroke];
        NSBezierPath *border = [NSBezierPath bezierPathWithRect:displayRect];
        [border setLineWidth:2.0];
        [border stroke];
    }
}

- (void)calculateDisplayRect
{
    NSRect bounds = self.bounds;
    
    if (!maintainAspectRatio) {
        displayRect = bounds;
        return;
    }
    
    // VIC-20 aspect ratio (22x23 characters at 8x8 pixels = 176x184)
    float vicWidth = VIC_SCREEN_WIDTH_PIXELS;
    float vicHeight = VIC_SCREEN_HEIGHT_PIXELS;
    float vicAspectRatio = vicWidth / vicHeight;
    
    float viewWidth = bounds.size.width;
    float viewHeight = bounds.size.height;
    float viewAspectRatio = viewWidth / viewHeight;
    
    if (viewAspectRatio > vicAspectRatio) {
        // View is wider than VIC aspect ratio, fit to height
        float height = viewHeight;
        float width = height * vicAspectRatio;
        displayRect = NSMakeRect(
            (viewWidth - width) / 2,
            0,
            width,
            height
        );
    } else {
        // View is taller than VIC aspect ratio, fit to width  
        float width = viewWidth;
        float height = width / vicAspectRatio;
        displayRect = NSMakeRect(
            0,
            (viewHeight - height) / 2,
            width,
            height
        );
    }
}

#pragma mark - Configuration

- (void)setMaintainAspectRatio:(BOOL)maintain
{
    maintainAspectRatio = maintain;
    [self calculateDisplayRect];
    [self setNeedsDisplay:YES];
}

- (void)setDisplayFilter:(NSImageInterpolation)filter
{
    // Store filter preference for future use in drawing
    // For authentic retro look, use NSImageInterpolationNone
}

- (void)setVicChip:(VIC6561 *)chip
{
    vicChip = chip;
    [self setNeedsDisplay:YES];
}

#pragma mark - View Management

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    
    if (self.window) {
        [self startDisplay];
    } else {
        [self stopDisplay];
    }
}

- (BOOL)acceptsFirstResponder
{
    return YES; // Allow the view to receive keyboard events for future keyboard input
}

- (void)setFrameSize:(NSSize)newSize
{
    [super setFrameSize:newSize];
    [self calculateDisplayRect];
}

@end
