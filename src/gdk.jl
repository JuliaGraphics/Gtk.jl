struct GdkRectangle <: GBoxed
    x::Int32
    y::Int32
    width::Int32
    height::Int32
    GdkRectangle(x, y, w, h) = new(x, y, w, h)
end
@make_gvalue(GdkRectangle, Ptr{GdkRectangle}, :boxed, (:gdk_rectangle, :libgdk))
convert(::Type{GdkRectangle}, rect::Ptr{GdkRectangle}) = unsafe_load(rect)

struct GdkPoint
    x::Int32
    y::Int32
    GdkPoint(x, y) = new(x, y)
end
# GdkPoint is not a GBoxed type

struct GdkRGBA
	r::Cdouble
	g::Cdouble
	b::Cdouble
    a::Cdouble
    GdkRGBA(r, g, b, a) = new(r, g, b, a)
end
@make_gvalue(GdkRGBA, Ptr{GdkRGBA}, :boxed, (:gdk_rgba,:libgdk))
convert(::Type{GdkRGBA}, rgba::Ptr{GdkRGBA}) = unsafe_load(rgba)

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
    const KP_Enter = 0xff8d
end

abstract type GdkEvent <: GBoxed end
@make_gvalue(GdkEvent, Ptr{GdkEvent}, :boxed, (:gdk_event, :libgdk))
function convert(::Type{GdkEvent}, evt::Ptr{GdkEvent})
    e = unsafe_load(convert(Ptr{GdkEventAny}, evt))
    if     e.event_type == GdkEventType.KEY_PRESS ||
           e.event_type == GdkEventType.KEY_RELEASE
        return unsafe_load(convert(Ptr{GdkEventKey}, evt))
    elseif e.event_type == GdkEventType.BUTTON_PRESS ||
           e.event_type == GdkEventType.DOUBLE_BUTTON_PRESS ||
           e.event_type == GdkEventType.TRIPLE_BUTTON_PRESS ||
           e.event_type == GdkEventType.BUTTON_RELEASE
        return unsafe_load(convert(Ptr{GdkEventButton}, evt))
    elseif e.event_type == GdkEventType.SCROLL
        return unsafe_load(convert(Ptr{GdkEventScroll}, evt))
    elseif e.event_type == GdkEventType.MOTION_NOTIFY
        return unsafe_load(convert(Ptr{GdkEventMotion}, evt))
    elseif e.event_type == GdkEventType.ENTER_NOTIFY ||
           e.event_type == GdkEventType.LEAVE_NOTIFY
        return unsafe_load(convert(Ptr{GdkEventCrossing}, evt))
    else
        return unsafe_load(convert(Ptr{GdkEventAny}, evt))
    end
end

struct GdkEventAny <: GdkEvent
    event_type::GEnum
    gdk_window::Ptr{Nothing}
    send_event::Int8
end

struct GdkEventButton <: GdkEvent
    event_type::GEnum
    gdk_window::Ptr{Nothing}
    send_event::Int8
    time::UInt32
    x::Float64
    y::Float64
    axes::Ptr{Float64}
    state::UInt32
    button::UInt32
    gdk_device::Ptr{Nothing}
    x_root::Float64
    y_root::Float64
end

struct GdkEventScroll <: GdkEvent
    event_type::GEnum
    gdk_window::Ptr{Nothing}
    send_event::Int8
    time::UInt32
    x::Float64
    y::Float64
    state::UInt32
    direction::GEnum
    gdk_device::Ptr{Nothing}
    x_root::Float64
    y_root::Float64
    delta_x::Float64
    delta_y::Float64
end

struct GdkEventKey <: GdkEvent
    event_type::GEnum
    gdk_window::Ptr{Nothing}
    send_event::Int8
    time::UInt32
    state::UInt32
    keyval::UInt32
    length::Int32
    string::Ptr{UInt8}
    hardware_keycode::UInt16
    group::UInt8
    flags::UInt32
end
GdkEventKey() = (uz32 = UInt32(0); GdkEventKey(GEnum(0), C_NULL, Int8(0), uz32, uz32, uz32, Int32(0), C_NULL, UInt16(0), 0x00, uz32))

is_modifier(evt::GdkEventKey) = (evt.flags & 0x0001) > 0

struct GdkEventMotion <: GdkEvent
  event_type::GEnum
  gdk_window::Ptr{Nothing}
  send_event::Int8
  time::UInt32
  x::Float64
  y::Float64
  axes::Ptr{Float64}
  state::UInt32
  is_hint::Int16
  gdk_device::Ptr{Nothing}
  x_root::Float64
  y_root::Float64
end

struct GdkEventCrossing <: GdkEvent
  event_type::GEnum
  gdk_window::Ptr{Nothing}
  send_event::Int8
  gdk_subwindow::Ptr{Nothing}
  time::UInt32
  x::Float64
  y::Float64
  x_root::Float64
  y_root::Float64
  mode::GEnum
  detail::GEnum
  focus::Cint
  state::UInt32
end

keyval(name::AbstractString) =
  ccall((:gdk_keyval_from_name, libgdk), Cuint, (Ptr{UInt8},), bytestring(name))

screen_size() = screen_size(ccall((:gdk_screen_get_default, libgdk),
                                          Ptr{Nothing}, ()))

function screen_size(screen::Ptr{Nothing})
    return (ccall((:gdk_screen_get_width, libgdk), Cint, (Ptr{Nothing},), screen),
            ccall((:gdk_screen_get_height, libgdk), Cint, (Ptr{Nothing},), screen))
end

function get_origin(window)
    window_x, window_y = mutable(Cint), mutable(Cint)
	ccall(
        (:gdk_window_get_origin, libgdk), Cint,
        (Ptr{GObject}, Ptr{Cint}, Ptr{Cint}),
        window, window_x, window_y
    )
	return (window_x[], window_y[])
end