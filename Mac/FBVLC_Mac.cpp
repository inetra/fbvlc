#include "FBVLC_Mac.h"

////////////////////////////////////////////////////////////////////////////////
//FBVLC_Mac class
////////////////////////////////////////////////////////////////////////////////
FBVLC_Mac::FBVLC_Mac()
{
    updateBgComponents();
}

FBVLC_Mac::~FBVLC_Mac()
{
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
    FB::PluginWindow* w = GetWindow();
    if ( w ) {
        w->InvalidateWindow();
    }
}
