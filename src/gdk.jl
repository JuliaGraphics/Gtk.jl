immutable GdkRectangle
    x::Int32
    y::Int32
    width::Int32
    height::Int32
    GdkRectangle(x,y,w,h) = new(x,y,w,h)
end
immutable GdkPoint
    x::Int32
    y::Int32
    GdkPoint(x,y) = new(x,y)
end
gdk_window(w::GtkWidgetI) = ccall((:gtk_widget_get_window,libgtk),Ptr{Void},(Ptr{GObject},),w)

const _gpx = Cint[-1]
const _gpy = Cint[-1]
const _gpmask = Cint[-1]
function get_pointer(w::GtkWidgetI)
    ccall((:gdk_window_get_pointer,libgtk), Ptr{Void},
          (Ptr{Void}, Ptr{Cint}, Ptr{Cint}, Ptr{Cint}),
          gdk_window(w), _gpx, _gpy, _gpmask)
    _gpx[1], _gpy[1], _gpmask[1]
end

baremodule GdkEventMask
    import Base.<<
    const GDK_EXPOSURE_MASK		    = 1 << 1
    const GDK_POINTER_MOTION_MASK   = 1 << 2
    const GDK_POINTER_MOTION_HINT_MASK = 1 << 3
    const GDK_BUTTON_MOTION_MASK    = 1 << 4
    const GDK_BUTTON1_MOTION_MASK   = 1 << 5
    const GDK_BUTTON2_MOTION_MASK   = 1 << 6
    const GDK_BUTTON3_MOTION_MASK   = 1 << 7
    const GDK_BUTTON_PRESS_MASK		= 1 << 8
    const GDK_BUTTON_RELEASE_MASK   = 1 << 9
    const GDK_KEY_PRESS_MASK		= 1 << 10
    const GDK_KEY_RELEASE_MASK		= 1 << 11
    const GDK_ENTER_NOTIFY_MASK		= 1 << 12
    const GDK_LEAVE_NOTIFY_MASK		= 1 << 13
    const GDK_FOCUS_CHANGE_MASK		= 1 << 14
    const GDK_STRUCTURE_MASK		= 1 << 15
    const GDK_PROPERTY_CHANGE_MASK  = 1 << 16
    const GDK_VISIBILITY_NOTIFY_MASK = 1 << 17
    const GDK_PROXIMITY_IN_MASK	 	= 1 << 18
    const GDK_PROXIMITY_OUT_MASK    = 1 << 19
    const GDK_SUBSTRUCTURE_MASK		= 1 << 20
    const GDK_SCROLL_MASK           = 1 << 21
    const GDK_ALL_EVENTS_MASK		= 0x3FFFFE
end

baremodule GdkModifierType
    import Base: <<, |
    const GDK_SHIFT_MASK    = 1 << 0
    const GDK_LOCK_MASK     = 1 << 1
    const GDK_CONTROL_MASK  = 1 << 2
    const GDK_MOD1_MASK     = 1 << 3
    const GDK_MOD2_MASK     = 1 << 4
    const GDK_MOD3_MASK     = 1 << 5
    const GDK_MOD4_MASK     = 1 << 6
    const GDK_MOD5_MASK     = 1 << 7
    const GDK_BUTTON1_MASK  = 1 << 8
    const GDK_BUTTON2_MASK  = 1 << 9
    const GDK_BUTTON3_MASK  = 1 << 10
    const GDK_BUTTON4_MASK  = 1 << 11
    const GDK_BUTTON5_MASK  = 1 << 12
    const GDK_BUTTONS_MASK  =
            GdkModifierType.GDK_BUTTON1_MASK |
            GdkModifierType.GDK_BUTTON2_MASK |
            GdkModifierType.GDK_BUTTON3_MASK |
            GdkModifierType.GDK_BUTTON4_MASK |
            GdkModifierType.GDK_BUTTON5_MASK

    const GDK_MODIFIER_RESERVED_13_MASK  = 1 << 13
    const GDK_MODIFIER_RESERVED_14_MASK  = 1 << 14
    const GDK_MODIFIER_RESERVED_15_MASK  = 1 << 15
    const GDK_MODIFIER_RESERVED_16_MASK  = 1 << 16
    const GDK_MODIFIER_RESERVED_17_MASK  = 1 << 17
    const GDK_MODIFIER_RESERVED_18_MASK  = 1 << 18
    const GDK_MODIFIER_RESERVED_19_MASK  = 1 << 19
    const GDK_MODIFIER_RESERVED_20_MASK  = 1 << 20
    const GDK_MODIFIER_RESERVED_21_MASK  = 1 << 21
    const GDK_MODIFIER_RESERVED_22_MASK  = 1 << 22
    const GDK_MODIFIER_RESERVED_23_MASK  = 1 << 23
    const GDK_MODIFIER_RESERVED_24_MASK  = 1 << 24
    const GDK_MODIFIER_RESERVED_25_MASK  = 1 << 25

    # The next few modifiers are used by XKB, so we skip to the end.
    # Bits 15 - 25 are currently unused. Bit 29 is used internally.

    const GDK_SUPER_MASK    = 1 << 26
    const GDK_HYPER_MASK    = 1 << 27
    const GDK_META_MASK     = 1 << 28

    const GDK_MODIFIER_RESERVED_29_MASK  = 1 << 29

    const GDK_RELEASE_MASK  = 1 << 30

    # Combination of GDK_SHIFT_MASK..GDK_BUTTON5_MASK + GDK_SUPER_MASK
    # + GDK_HYPER_MASK + GDK_META_MASK + GDK_RELEASE_MASK */
    const GDK_MODIFIER_MASK = 0x5c001fff
end

baremodule GdkEventType
  const GDK_NOTHING           = -1
  const GDK_DELETE            = 0
  const GDK_DESTROY           = 1
  const GDK_EXPOSE            = 2
  const GDK_MOTION_NOTIFY     = 3
  const GDK_BUTTON_PRESS      = 4
  const GDK_2BUTTON_PRESS     = 5
  const GDK_DOUBLE_BUTTON_PRESS = GDK_2BUTTON_PRESS
  const GDK_3BUTTON_PRESS     = 6
  const GDK_TRIPLE_BUTTON_PRESS = GDK_3BUTTON_PRESS
  const GDK_BUTTON_RELEASE    = 7
  const GDK_KEY_PRESS         = 8
  const GDK_KEY_RELEASE       = 9
  const GDK_ENTER_NOTIFY      = 10
  const GDK_LEAVE_NOTIFY      = 11
  const GDK_FOCUS_CHANGE      = 12
  const GDK_CONFIGURE         = 13
  const GDK_MAP               = 14
  const GDK_UNMAP             = 15
  const GDK_PROPERTY_NOTIFY   = 16
  const GDK_SELECTION_CLEAR   = 17
  const GDK_SELECTION_REQUEST = 18
  const GDK_SELECTION_NOTIFY  = 19
  const GDK_PROXIMITY_IN      = 20
  const GDK_PROXIMITY_OUT     = 21
  const GDK_DRAG_ENTER        = 22
  const GDK_DRAG_LEAVE        = 23
  const GDK_DRAG_MOTION       = 24
  const GDK_DRAG_STATUS       = 25
  const GDK_DROP_START        = 26
  const GDK_DROP_FINISHED     = 27
  const GDK_CLIENT_EVENT      = 28
  const GDK_VISIBILITY_NOTIFY = 29
  const GDK_SCROLL            = 31
  const GDK_WINDOW_STATE      = 32
  const GDK_SETTING           = 33
  const GDK_OWNER_CHANGE      = 34
  const GDK_GRAB_BROKEN       = 35
  const GDK_DAMAGE            = 36
  const GDK_TOUCH_BEGIN       = 37
  const GDK_TOUCH_UPDATE      = 38
  const GDK_TOUCH_END         = 39
  const GDK_TOUCH_CANCEL      = 40
end

baremodule GdkScrollDirection
  const GDK_SCROLL_UP    = 0
  const GDK_SCROLL_DOWN  = 1
  const GDK_SCROLL_LEFT  = 2
  const GDK_SCROLL_RIGHT = 3
end

baremodule GdkKeySyms
  const GDK_KEY_VoidSymbol = 0xffffff
  const GDK_KEY_BackSpace = 0xff08
  const GDK_KEY_Tab = 0xff09
  const GDK_KEY_Linefeed = 0xff0a
  const GDK_KEY_Clear = 0xff0b
  const GDK_KEY_Return = 0xff0d
  const GDK_KEY_Pause = 0xff13
  const GDK_KEY_Scroll_Lock = 0xff14
  const GDK_KEY_Sys_Req = 0xff15
  const GDK_KEY_Escape = 0xff1b
  const GDK_KEY_Delete = 0xffff
  const GDK_KEY_Home = 0xff50
  const GDK_KEY_Left = 0xff51
  const GDK_KEY_Up = 0xff52
  const GDK_KEY_Right = 0xff53
  const GDK_KEY_Down = 0xff54
  const GDK_KEY_Page_Up = 0xff55
  const GDK_KEY_Next = 0xff56
  const GDK_KEY_Page_Down = 0xff56
  const GDK_KEY_End = 0xff57
  const GDK_KEY_Insert = 0xff63
  const GDK_KEY_Num_Lock = 0xff7f
  const GDK_KEY_F1 = 0xffbe
  const GDK_KEY_F2 = 0xffbf
  const GDK_KEY_F3 = 0xffc0
  const GDK_KEY_F4 = 0xffc1
  const GDK_KEY_F5 = 0xffc2
  const GDK_KEY_F6 = 0xffc3
  const GDK_KEY_F7 = 0xffc4
  const GDK_KEY_F8 = 0xffc5
  const GDK_KEY_F9 = 0xffc6
  const GDK_KEY_F10 = 0xffc7
  const GDK_KEY_F11 = 0xffc8
  const GDK_KEY_F12 = 0xffc9
  const GDK_KEY_Shift_L = 0xffe1
  const GDK_KEY_Shift_R = 0xffe2
  const GDK_KEY_Control_L = 0xffe3
  const GDK_KEY_Control_R = 0xffe4
  const GDK_KEY_Caps_Lock = 0xffe5
  const GDK_KEY_Shift_Lock = 0xffe6
  const GDK_KEY_Meta_L = 0xffe7
  const GDK_KEY_Meta_R = 0xffe8
  const GDK_KEY_Alt_L = 0xffe9
  const GDK_KEY_Alt_R = 0xffea
  const GDK_KEY_Super_L = 0xffeb
  const GDK_KEY_Super_R = 0xffec
  const GDK_KEY_Hyper_L = 0xffed
  const GDK_KEY_Hyper_R = 0xffee
end

abstract GdkEventI

immutable GdkEventButton <: GdkEventI
    event_type::Enum
    gdk_window::Ptr{Void}
    send_event::Int8
    time::Uint32
    x::Float64
    y::Float64
    axes::Ptr{Float64}
    state::Uint32
    button::Uint32
    gdk_device::Ptr{Void}
    x_root::Float64
    y_root::Float64
end

immutable GdkEventScroll <: GdkEventI
    event_type::Enum
    gdk_window::Ptr{Void}
    send_event::Int8
    time::Uint32
    x::Float64
    y::Float64
    state::Uint32
    direction::Enum
    gdk_device::Ptr{Void}
    x_root::Float64
    y_root::Float64
    delta_x::Float64
    delta_y::Float64
end

immutable GdkEventKey <: GdkEventI
    event_type::Enum
    gdk_window::Ptr{Void}
    send_event::Int8
    time::Uint32
    state::Uint32
    keyval::Uint32
    length::Int32
    string::Ptr{Uint8}
    hardware_keycode::Uint16
    group::Uint8
    flags::Uint32
end

is_modifier(evt::GdkEventKey) = (evt.flags & uint32(1)) > 0

immutable GdkEventMotion <: GdkEventI
  event_type::Enum
  gdk_window::Ptr{Void}
  send_event::Int8
  time::Uint32
  x::Float64
  y::Float64
  axes::Ptr{Float64}
  state::Uint32
  is_hint::Int16
  gdk_device::Ptr{Void}
  x_root::Float64
  y_root::Float64
end

immutable GdkEventCrossing <: GdkEventI
  event_type::Enum
  gdk_window::Ptr{Void}
  send_event::Int8
  gdk_subwindow::Ptr{Void}
  time::Uint32
  x::Float64
  y::Float64
  x_root::Float64
  y_root::Float64
  mode::Enum
  detail::Enum
  focus::Cint
  state::Uint32
end

# Expand this dictionary as more event types get added
const eventTdict = [
    "button-press-event" => GdkEventButton,
    "button-release-event" => GdkEventButton,
    "enter-notify-event" => GdkEventCrossing,
    "key-press-event" => GdkEventKey,
    "key-release-event" => GdkEventKey,
    "leave-notify-event" => GdkEventCrossing,
    "motion-notify-event" => GdkEventMotion,
    "scroll-event" => GdkEventScroll]
kv = collect(eventTdict)
for (k,v) in kv
    eventTdict[replace(k, "-", "_")] = v
end
