immutable GdkRectangle <: GBoxed
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

gdk_window(w::GtkWidget) = ccall((:gtk_widget_get_window,libgtk),Ptr{Void},(Ptr{GObject},),w)

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

baremodule GdkAtoms
    const NONE = 0x0000
    const PRIMARY = 0x0001
    const SECONDARY = 0x0002
    const ARC = 0x0003
    const ATOM = 0x0004
    const BITMAP = 0x0005
    const CARDINAL = 0x0006
    const COLORMAP = 0x0007
    const CURSOR = 0x0008
    const CUT_BUFFER0 = 0x0009
    const CUT_BUFFER1 = 0x000a
    const CUT_BUFFER2 = 0x000b
    const CUT_BUFFER3 = 0x000c
    const CUT_BUFFER4 = 0x000d
    const CUT_BUFFER5 = 0x000e
    const CUT_BUFFER6 = 0x000f
    const CUT_BUFFER7 = 0x0010
    const DRAWABLE = 0x0011
    const FONT = 0x0012
    const INTEGER = 0x0013
    const PIXMAP = 0x0014
    const POINT = 0x0015
    const RECTANGLE = 0x0016
    const RESOURCE_MANAGER = 0x0017
    const RGB_COLOR_MAP = 0x0018
    const RGB_BEST_MAP = 0x0019
    const RGB_BLUE_MAP = 0x001a
    const RGB_DEFAULT_MAP = 0x001b
    const RGB_GRAY_MAP = 0x001c
    const RGB_GREEN_MAP = 0x001d
    const RGB_RED_MAP = 0x001e
    const STRING = 0x001f
    const VISUALID = 0x0020
    const WINDOW = 0x0021
    const WM_COMMAND = 0x0022
    const WM_HINTS = 0x0023
    const WM_CLIENT_MACHINE = 0x0024
    const WM_ICON_NAME = 0x0025
    const WM_ICON_SIZE = 0x0026
    const WM_NAME = 0x0027
    const WM_NORMAL_HINTS = 0x0028
    const WM_SIZE_HINTS = 0x0029
    const WM_ZOOM_HINTS = 0x002a
    const MIN_SPACE = 0x002b
    const NORM_SPACE = 0x002c
    const MAX_SPACE = 0x002d
    const END_SPACE = 0x002e
    const SUPERSCRIPT_X = 0x002f
    const SUPERSCRIPT_Y = 0x0030
    const SUBSCRIPT_X = 0x0031
    const SUBSCRIPT_Y = 0x0032
    const UNDERLINE_POSITION = 0x0033
    const UNDERLINE_THICKNESS = 0x0034
    const STRIKEOUT_ASCENT = 0x0035
    const STRIKEOUT_DESCENT = 0x0036
    const ITALIC_ANGLE = 0x0037
    const X_HEIGHT = 0x0038
    const QUAD_WIDTH = 0x0039
    const WEIGHT = 0x003a
    const POINT_SIZE = 0x003b
    const RESOLUTION = 0x003c
    const COPYRIGHT = 0x003d
    const NOTICE = 0x003e
    const FONT_NAME = 0x003f
    const FAMILY_NAME = 0x0040
    const FULL_NAME = 0x0041
    const CAP_HEIGHT = 0x0042
    const WM_CLASS = 0x0043
    const WM_TRANSIENT_FOR = 0x0044
    const CLIPBOARD = 0x0045
    const GDK_SELECTION = 0x0046
    const TARGETS = 0x0047
    const DELETE = 0x0048
    const SAVE_TARGETS = 0x0049
    const UTF8_STRING = 0x004a
    const TEXT = 0x004b
    const COMPOUND_TEXT = 0x004c
end

abstract GdkEvent <: GBoxed
make_gvalue(GdkEvent, Ptr{GdkEvent}, :boxed, (:gdk_event,:libgdk))
function convert(::Type{GdkEvent}, evt::Ptr{GdkEvent})
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

immutable GdkEventAny <: GdkEvent
    event_type::GEnum
    gdk_window::Ptr{Void}
    send_event::Int8
end

immutable GdkEventButton <: GdkEvent
    event_type::GEnum
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

immutable GdkEventScroll <: GdkEvent
    event_type::GEnum
    gdk_window::Ptr{Void}
    send_event::Int8
    time::Uint32
    x::Float64
    y::Float64
    state::Uint32
    direction::GEnum
    gdk_device::Ptr{Void}
    x_root::Float64
    y_root::Float64
    delta_x::Float64
    delta_y::Float64
end

immutable GdkEventKey <: GdkEvent
    event_type::GEnum
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

immutable GdkEventMotion <: GdkEvent
  event_type::GEnum
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

immutable GdkEventCrossing <: GdkEvent
  event_type::GEnum
  gdk_window::Ptr{Void}
  send_event::Int8
  gdk_subwindow::Ptr{Void}
  time::Uint32
  x::Float64
  y::Float64
  x_root::Float64
  y_root::Float64
  mode::GEnum
  detail::GEnum
  focus::Cint
  state::Uint32
end

keyval(name::String) =
  ccall((:gdk_keyval_from_name,libgdk),Cuint,(Ptr{Uint8},),bytestring(name))
