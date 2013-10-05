#ifndef H_FBVLCPLUGIN_MAC
#define H_FBVLCPLUGIN_MAC

#include "../FBVLC.h"

#include "PluginEvents/MacEventCocoa.h"
#include "Mac/PluginWindowMac.h"
#include "Mac/PluginWindowMacCG.h"
#include "Mac/PluginWindowMacCA.h"

////////////////////////////////////////////////////////////////////////////////
//FBVLC_Mac class
////////////////////////////////////////////////////////////////////////////////
FB_FORWARD_PTR(FBVLC_Mac)
class FBVLC_Mac: public FBVLC
{
public:
    FBVLC_Mac();
    virtual ~FBVLC_Mac();

    //mac plugins is always windowless
    virtual bool isWindowless() { return true; }

    BEGIN_PLUGIN_EVENT_MAP()
        EVENTTYPE_CASE(FB::CoreGraphicsDraw, onCoreGraphicsDraw, FB::PluginWindowMacCG)
        EVENTTYPE_CASE(FB::AttachedEvent, onWindowAttached, FB::PluginWindowMac)
        EVENTTYPE_CASE(FB::DetachedEvent, onWindowDetached, FB::PluginWindowMac)
        PLUGIN_EVENT_MAP_CASCADE(FBVLC)
    END_PLUGIN_EVENT_MAP()

private:
    /** BEGIN EVENTDEF -- DON'T CHANGE THIS LINE **/
    bool onCoreGraphicsDraw(FB::CoreGraphicsDraw *evt, FB::PluginWindowMacCG*);
    /** END EVENTDEF -- DON'T CHANGE THIS LINE **/

    virtual bool onWindowAttached(FB::AttachedEvent *evt, FB::PluginWindowMac*);
    virtual bool onWindowDetached(FB::DetachedEvent *evt, FB::PluginWindowMac*);

    void update_window();
public:
    virtual bool is_fullscreen() { return false; };
    virtual void set_fullscreen(bool fs) { };
    virtual void toggle_fullscreen() { };

protected:
    virtual void on_option_change(vlc_player_option_e );
    virtual void on_frame_ready( const std::vector<char>& frame_buf );
    virtual void on_frame_cleanup();

private:
    void updateBgComponents();

private:
    CGFloat m_bgComponents[4];
    void *m_layer;
};

#endif//H_FBVLCPLUGIN_MAC
