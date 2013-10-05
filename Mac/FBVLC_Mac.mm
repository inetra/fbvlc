#import "FBVLC_Mac.h"
#import <AppKit/AppKit.h>
#import <OpenGL/gl.h>

@interface VLCOpenGLLayer : CAOpenGLLayer {
    GLfloat m_angle;
}
@end

@implementation VLCOpenGLLayer
    
- (id) init {
    if (self = [super init]) {
        m_angle = 0;
    }
    return self;
}

- (void)drawInCGLContext:(CGLContextObj)ctx pixelFormat:(CGLPixelFormatObj)pf forLayerTime:(CFTimeInterval)t displayTime:(const CVTimeStamp *)ts {
    m_angle += 1;
    GLsizei width = CGRectGetWidth([self bounds]), height = CGRectGetHeight([self bounds]);
    GLfloat halfWidth = width / 2, halfHeight = height / 2;
    
    glViewport(0, 0, width, height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glScalef(1.0f, -1.0f, 1.0f);
    glOrtho(0, width, 0, height, -1.0, 1.0);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    
    glRotatef(m_angle, 0.0, 0.0, 1.0);
    
    // Clear the stage.
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    // Draw UL Quadrant 25% Red
    glBegin(GL_QUADS);
    glColor4f(1.0, 0.0, 0.0, 0.25);
    glVertex3f(0, 0, -1.0f);
    glVertex3f(halfWidth, 0, -1.0f);
    glVertex3f(halfWidth, halfHeight, -1.0f);
    glVertex3f(0, halfHeight, -1.0f);
    glEnd();
    
    // Draw UR Quadrant 50% Green
    glBegin(GL_QUADS);
    glColor4f(0.0, 1.0, 0.0, 0.5);
    glVertex3f(halfWidth, 0, -1.0f);
    glVertex3f(width, 0, -1.0f);
    glVertex3f(width, halfHeight, -1.0f);
    glVertex3f(halfWidth, halfHeight, -1.0f);
    glEnd();
    
    // Draw LR Quadrant 75% Blue
    glBegin(GL_QUADS);
    glColor4f(0.0, 0.0, 1.0, 0.75);
    glVertex3f(halfWidth, halfHeight, -1.0f);
    glVertex3f(width, halfHeight, -1.0f);
    glVertex3f(width, height, -1.0f);
    glVertex3f(halfWidth, height, -1.0f);
    glEnd();
    
    // Draw Center Quadrant 100% Magenta
    glBegin(GL_QUADS);
    glColor4f(1.0, 0.0, 1.0, 1.0);
    glVertex3f(width / 4, height / 4, -1.0f);
    glVertex3f(3 * width / 4, height / 4, -1.0f);
    glVertex3f(3 * width / 4, 3 * height / 4, -1.0f);
    glVertex3f(width / 4,   3 * height / 4, -1.0f);
    glEnd();
    
    [super drawInCGLContext:ctx pixelFormat:pf forLayerTime:t displayTime:ts];
}

@end

////////////////////////////////////////////////////////////////////////////////
//FBVLC_Mac class
////////////////////////////////////////////////////////////////////////////////
FBVLC_Mac::FBVLC_Mac() : m_layer(0)
{
    updateBgComponents();
}

FBVLC_Mac::~FBVLC_Mac()
{
    if (m_layer) {
        [(CALayer*)m_layer removeFromSuperlayer];
        [(CALayer*)m_layer release];
        m_layer = 0;
    }
}

void FBVLC_Mac::updateBgComponents()
{
    uint8_t r = 0, g = 0, b = 0;
    HtmlColor2RGB(get_options().get_bg_color(), &r, &g, &b);
    m_bgComponents[0] = r / 255.f;
    m_bgComponents[1] = g / 255.f;
    m_bgComponents[2] = b / 255.f;
    m_bgComponents[3] = 1.f;
}

void FBVLC_Mac::on_option_change(vlc_player_option_e option)
{
    FBVLC::on_option_change(option);

    switch (option) {
        case po_bg_color: {
            updateBgComponents();
            if ( GetWindow() )
                GetWindow()->InvalidateWindow();
            break;
        }
        default:
            break;
    }
}

bool FBVLC_Mac::onCoreGraphicsDraw(FB::CoreGraphicsDraw *evt, FB::PluginWindowMacCG*)
{
    return false;
    const std::vector<char>& fb = vlc::vmem::frame_buf();
    const unsigned media_width = vlc::vmem::width(); //   720 | 448
    const unsigned media_height = vlc::vmem::height(); // 304 | 336

    FB::Rect bounds(evt->bounds);
    //FB::Rect clip(evt->clip);
    CGFloat width = bounds.right - bounds.left, height = bounds.bottom - bounds.top;

    CGContextRef cgContext(evt->context);

    CGContextSaveGState(cgContext);

    CGFloat scale;
    if (width/media_width < height/media_height) { // 1,94 < 2,96 | 4,60 < 2,67
        // Horizontal
        scale = width/media_width; //
        CGContextTranslateCTM(cgContext, 0, height - (height - media_height*scale)/2);
    } else {
        // Vertical
        scale = height/media_height;
        CGContextTranslateCTM(cgContext, (width - media_width*scale)/2, height);
    }
    CGContextScaleCTM(cgContext, scale, -scale);

    CGColorSpaceRef cSpace = CGColorSpaceCreateDeviceRGB();
    CGContextSetFillColorSpace(cgContext, cSpace);

    CGColorRef bgColor = CGColorCreate(cSpace, m_bgComponents);
    CGContextSetFillColorWithColor(cgContext, bgColor);
    CGRect cgBounds = {
        { 0, 0 },
        { media_width, media_height }
    };
    
    if ( fb.size() &&
        fb.size() >= media_width * media_height * vlc::DEF_PIXEL_BYTES )
    {
        CGContextRef bmpCtx =
            CGBitmapContextCreate((void*)fb.data(), media_width, media_height, 8,
                                  media_width * vlc::DEF_PIXEL_BYTES, cSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
        CGImageRef img = CGBitmapContextCreateImage(bmpCtx);

        CGContextDrawImage(cgContext, cgBounds, img);

        CGImageRelease(img);
        CGContextRelease(bmpCtx);
    } else {
        CGContextFillRect(cgContext, cgBounds);
    }

    CGColorRelease(bgColor);
    CGColorSpaceRelease(cSpace);
    CGContextRestoreGState(cgContext);

    return true; // This is handled
}

void FBVLC_Mac::on_frame_ready ( const std::vector<char>& frame_buf ) {
    update_window();
}

void FBVLC_Mac::on_frame_cleanup() {
    update_window();
}

void FBVLC_Mac::update_window()
{
    FB::PluginWindowMac* w = dynamic_cast<FB::PluginWindowMac*>(GetWindow());
    if ( w ) {
        //w->InvalidateWindow();
    }
}

// This is for CoreAnimation ?

#include <stdio.h>

bool FBVLC_Mac::onWindowAttached(FB::AttachedEvent* evt, FB::PluginWindowMac* wnd) {
    if (FB::PluginWindowMac::DrawingModelCoreAnimation != wnd->getDrawingModel() && FB::PluginWindowMac::DrawingModelInvalidatingCoreAnimation != wnd->getDrawingModel())
        return false;
        
    // Setup CAOpenGL drawing.
    VLCOpenGLLayer* layer = [VLCOpenGLLayer new];
    layer.asynchronous = (FB::PluginWindowMac::DrawingModelInvalidatingCoreAnimation == wnd->getDrawingModel()) ? NO : YES;
    layer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    layer.needsDisplayOnBoundsChange = YES;
    m_layer = layer;
    if (FB::PluginWindowMac::DrawingModelInvalidatingCoreAnimation == wnd->getDrawingModel())
        wnd->StartAutoInvalidate(1.0/30.0);
    [(CALayer*) wnd->getDrawingPrimitive() addSublayer:layer];
    
    // Draw Label
    CATextLayer* txtlayer = [CATextLayer layer];
    txtlayer.string = (FB::PluginWindowMac::DrawingModelInvalidatingCoreAnimation == wnd->getDrawingModel()) ? @"CoreAnimation (Invalidating)" : @"CoreAnimation";
    txtlayer.fontSize = 14;
    txtlayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    txtlayer.needsDisplayOnBoundsChange = YES;
    [(CALayer*) wnd->getDrawingPrimitive() addSublayer:txtlayer];
    return true;
}

bool FBVLC_Mac::onWindowDetached(FB::DetachedEvent* evt, FB::PluginWindowMac* wnd) {
    return true;
}
