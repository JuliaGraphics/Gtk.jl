immutable GdkRectangle
    x::Int32
    y::Int32
    width::Int32
    height::Int32
    GdkRectangle(x,y,w,h) = new(x,y,w,h)
end
make_gvalue(GdkRectangle, Ptr{GdkRectangle}, :boxed, (:gdk_rectangle,:libgdk))
convert(::Type{GdkRectangle}, rect::Ptr{GdkRectangle}) = unsafe_load(rect)

immutable GdkPoint
    x::Int32
    y::Int32
    GdkPoint(x,y) = new(x,y)
end
# GdkPoint is not a GBoxed type

gdk_window(w::GtkWidgetI) = ccall((:gtk_widget_get_window,libgtk),Ptr{Void},(Ptr{GObject},),w)

baremodule GdkEventMask
    import Base.<<
    const EXPOSURE_MASK          = 1 << 1
    const POINTER_MOTION_MASK    = 1 << 2
    const POINTER_MOTION_HINT_MASK = 1 << 3
    const BUTTON_MOTION_MASK     = 1 << 4
    const BUTTON1_MOTION_MASK    = 1 << 5
    const BUTTON2_MOTION_MASK    = 1 << 6
    const BUTTON3_MOTION_MASK    = 1 << 7
    const BUTTON_PRESS_MASK      = 1 << 8
    const BUTTON_RELEASE_MASK    = 1 << 9
    const KEY_PRESS_MASK         = 1 << 10
    const KEY_RELEASE_MASK       = 1 << 11
    const ENTER_NOTIFY_MASK      = 1 << 12
    const LEAVE_NOTIFY_MASK      = 1 << 13
    const FOCUS_CHANGE_MASK      = 1 << 14
    const STRUCTURE_MASK         = 1 << 15
    const PROPERTY_CHANGE_MASK   = 1 << 16
    const VISIBILITY_NOTIFY_MASK = 1 << 17
    const PROXIMITY_IN_MASK      = 1 << 18
    const PROXIMITY_OUT_MASK     = 1 << 19
    const SUBSTRUCTURE_MASK      = 1 << 20
    const SCROLL_MASK            = 1 << 21
    const ALL_EVENTS_MASK        = 0x3FFFFE
end

baremodule GdkModifierType
    import Base: <<, |
    const SHIFT_MASK    = 1 << 0
    const LOCK_MASK     = 1 << 1
    const CONTROL_MASK  = 1 << 2
    const MOD1_MASK     = 1 << 3
    const MOD2_MASK     = 1 << 4
    const MOD3_MASK     = 1 << 5
    const MOD4_MASK     = 1 << 6
    const MOD5_MASK     = 1 << 7
    const BUTTON1_MASK  = 1 << 8
    const BUTTON2_MASK  = 1 << 9
    const BUTTON3_MASK  = 1 << 10
    const BUTTON4_MASK  = 1 << 11
    const BUTTON5_MASK  = 1 << 12
    const BUTTONS_MASK  =
            GdkModifierType.BUTTON1_MASK |
            GdkModifierType.BUTTON2_MASK |
            GdkModifierType.BUTTON3_MASK |
            GdkModifierType.BUTTON4_MASK |
            GdkModifierType.BUTTON5_MASK

    const MODIFIER_RESERVED_13_MASK  = 1 << 13
    const MODIFIER_RESERVED_14_MASK  = 1 << 14
    const MODIFIER_RESERVED_15_MASK  = 1 << 15
    const MODIFIER_RESERVED_16_MASK  = 1 << 16
    const MODIFIER_RESERVED_17_MASK  = 1 << 17
    const MODIFIER_RESERVED_18_MASK  = 1 << 18
    const MODIFIER_RESERVED_19_MASK  = 1 << 19
    const MODIFIER_RESERVED_20_MASK  = 1 << 20
    const MODIFIER_RESERVED_21_MASK  = 1 << 21
    const MODIFIER_RESERVED_22_MASK  = 1 << 22
    const MODIFIER_RESERVED_23_MASK  = 1 << 23
    const MODIFIER_RESERVED_24_MASK  = 1 << 24
    const MODIFIER_RESERVED_25_MASK  = 1 << 25

    # The next few modifiers are used by XKB, so we skip to the end.
    # Bits 15 - 25 are currently unused. Bit 29 is used internally.

    const SUPER_MASK    = 1 << 26
    const HYPER_MASK    = 1 << 27
    const META_MASK     = 1 << 28

    const MODIFIER_RESERVED_29_MASK  = 1 << 29

    const RELEASE_MASK  = 1 << 30

    # Combination of SHIFT_MASK..BUTTON5_MASK + SUPER_MASK
    # + HYPER_MASK + META_MASK + RELEASE_MASK */
    const MODIFIER_MASK = 0x5c001fff
end

baremodule GdkEventType
  const NOTHING           = -1
  const DELETE            = 0
  const DESTROY           = 1
  const EXPOSE            = 2
  const MOTION_NOTIFY     = 3
  const BUTTON_PRESS      = 4
  const DOUBLE_BUTTON_PRESS = 5
  const TRIPLE_BUTTON_PRESS = 6
  const BUTTON_RELEASE    = 7
  const KEY_PRESS         = 8
  const KEY_RELEASE       = 9
  const ENTER_NOTIFY      = 10
  const LEAVE_NOTIFY      = 11
  const FOCUS_CHANGE      = 12
  const CONFIGURE         = 13
  const MAP               = 14
  const UNMAP             = 15
  const PROPERTY_NOTIFY   = 16
  const SELECTION_CLEAR   = 17
  const SELECTION_REQUEST = 18
  const SELECTION_NOTIFY  = 19
  const PROXIMITY_IN      = 20
  const PROXIMITY_OUT     = 21
  const DRAG_ENTER        = 22
  const DRAG_LEAVE        = 23
  const DRAG_MOTION       = 24
  const DRAG_STATUS       = 25
  const DROP_START        = 26
  const DROP_FINISHED     = 27
  const CLIENT_EVENT      = 28
  const VISIBILITY_NOTIFY = 29
  const SCROLL            = 31
  const WINDOW_STATE      = 32
  const SETTING           = 33
  const OWNER_CHANGE      = 34
  const GRAB_BROKEN       = 35
  const DAMAGE            = 36
  const TOUCH_BEGIN       = 37
  const TOUCH_UPDATE      = 38
  const TOUCH_END         = 39
  const TOUCH_CANCEL      = 40
end

baremodule GdkScrollDirection
  const UP    = 0
  const DOWN  = 1
  const LEFT  = 2
  const RIGHT = 3
end

baremodule GdkKeySyms
  const VoidSymbol = 0xffffff
  const BackSpace = 0xff08
  const Tab = 0xff09
  const Linefeed = 0xff0a
  const Clear = 0xff0b
  const Return = 0xff0d
  const Pause = 0xff13
  const Scroll_Lock = 0xff14
  const Sys_Req = 0xff15
  const Escape = 0xff1b
  const Delete = 0xffff
  const Home = 0xff50
  const Left = 0xff51
  const Up = 0xff52
  const Right = 0xff53
  const Down = 0xff54
  const Page_Up = 0xff55
  const Next = 0xff56
  const Page_Down = 0xff56
  const End = 0xff57
  const Insert = 0xff63
  const Num_Lock = 0xff7f
  const F1 = 0xffbe
  const F2 = 0xffbf
  const F3 = 0xffc0
  const F4 = 0xffc1
  const F5 = 0xffc2
  const F6 = 0xffc3
  const F7 = 0xffc4
  const F8 = 0xffc5
  const F9 = 0xffc6
  const F10 = 0xffc7
  const F11 = 0xffc8
  const F12 = 0xffc9
  const Shift_L = 0xffe1
  const Shift_R = 0xffe2
  const Control_L = 0xffe3
  const Control_R = 0xffe4
  const Caps_Lock = 0xffe5
  const Shift_Lock = 0xffe6
  const Meta_L = 0xffe7
  const Meta_R = 0xffe8
  const Alt_L = 0xffe9
  const Alt_R = 0xffea
  const Super_L = 0xffeb
  const Super_R = 0xffec
  const Hyper_L = 0xffed
  const Hyper_R = 0xffee
end

abstract GdkEventI
make_gvalue(GdkEventI, Ptr{GdkEventI}, :boxed, (:gdk_event,:libgdk))
function convert(::Type{GdkEventI}, evt::Ptr{GdkEventI})
    e = unsafe_load(convert(Ptr{GdkEventAny},evt))
    if     e.event_type == GdkEventType.KEY_PRESS ||
           e.event_type == GdkEventType.KEY_RELEASE
        return unsafe_load(convert(Ptr{GdkEventKey},evt))
    elseif e.event_type == GdkEventType.BUTTON_PRESS ||
           e.event_type == GdkEventType.DOUBLE_BUTTON_PRESS ||
           e.event_type == GdkEventType.TRIPLE_BUTTON_PRESS ||
           e.event_type == GdkEventType.BUTTON_RELEASE
        return unsafe_load(convert(Ptr{GdkEventButton},evt))
    elseif e.event_type == GdkEventType.SCROLL
        return unsafe_load(convert(Ptr{GdkEventScroll},evt))
    elseif e.event_type == GdkEventType.MOTION_NOTIFY
        return unsafe_load(convert(Ptr{GdkEventMotion},evt))
    elseif e.event_type == GdkEventType.ENTER_NOTIFY ||
           e.event_type == GdkEventType.LEAVE_NOTIFY
        return unsafe_load(convert(Ptr{GdkEventCrossing},evt))
    else
        return unsafe_load(convert(Ptr{GdkEventAny},evt))
    end
end

immutable GdkEventAny <: GdkEventI
    event_type::Enum
    gdk_window::Ptr{Void}
    send_event::Int8
end

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

is_modifier(evt::GdkEventKey) = (evt.flags & 0x0001) > 0

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
