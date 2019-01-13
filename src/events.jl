gtk_main() = GLib.g_sigatom() do
    ccall((:gtk_main, libgtk), Nothing, ())
end

function gtk_quit()
    ccall((:gtk_main_quit, libgtk), Nothing, ())
end

function __init__()
    GError() do error_check
        ccall((:gtk_init_with_args, libgtk), Bool,
            (Ptr{Nothing}, Ptr{Nothing}, Ptr{UInt8}, Ptr{Nothing}, Ptr{UInt8}, Ptr{GError}),
            C_NULL, C_NULL, "Julia Gtk Bindings", C_NULL, C_NULL, error_check)
    end

    # if g_main_depth > 0, a glib main-loop is already running,
    # so we don't need to start a new one
    if ccall((:g_main_depth, GLib.libglib), Cint, ()) == 0
        global gtk_main_task = schedule(Task(gtk_main))
    end
end


add_events(widget::GtkWidget, mask::Integer) = ccall((:gtk_widget_add_events, libgtk), Nothing, (Ptr{GObject}, GEnum), widget, mask)

# widget[:event] = function(ptr, obj)
#    stuff
# end
#function setindex!(w::GObject, cb::Function, sig::AbstractStringLike, vargs...)
#    signal_connect(cb, w, sig, vargs...)
#end


function on_signal_resize(resize_cb::Function, widget::GtkWidget, vargs...)
    signal_connect(resize_cb, widget, "size-allocate", Nothing, (Ptr{GdkRectangle},), vargs...)
end

function on_signal_destroy(destroy_cb::Function, widget::GObject, vargs...)
    signal_connect(destroy_cb, widget, "destroy", Nothing, (), vargs...)
end

function on_signal_button_press(press_cb::Function, widget::GtkWidget, vargs...)
    add_events(widget, GdkEventMask.BUTTON_PRESS)
    signal_connect(press_cb, widget, "button-press-event", Cint, (Ptr{GdkEventButton},), vargs...)
end
function on_signal_button_release(release_cb::Function, widget::GtkWidget, vargs...)
    add_events(widget, GdkEventMask.BUTTON_RELEASE)
    signal_connect(release_cb, widget, "button-release-event", Cint, (Ptr{GdkEventButton},), vargs...)
end

mutable struct Gtk_signal_motion{T}
    closure::T
    callback::Ptr{Nothing}
    include::UInt32
    exclude::UInt32
end
function notify_motion(p::Ptr{GObject}, eventp::Ptr{GdkEventMotion}, closure::Gtk_signal_motion{T}) where T
    event = unsafe_load(eventp)
    if event.state & closure.include == closure.include &&
       event.state & closure.exclude == 0
        if isbitstype(T)
            ret = ccall(closure.callback, Cint, (Ptr{GObject}, Ptr{GdkEventMotion}, T), p, eventp, closure.closure)
        else
            ret = ccall(closure.callback, Cint, (Ptr{GObject}, Ptr{GdkEventMotion}, Any), p, eventp, closure.closure)
        end
    else
        ret = Int32(false)
    end
    ccall((:gdk_event_request_motions, libgdk), Nothing, (Ptr{GdkEventMotion},), eventp)
    ret
end
function on_signal_motion(move_cb::Function, widget::GtkWidget,
        include = 0, exclude = GdkModifierType.BUTTONS, after::Bool = false, closure::T = w) where T
    exclude &= ~include
    mask = GdkEventMask.POINTER_MOTION_HINT
    if     0 == include & GdkModifierType.BUTTONS
        mask |= GdkEventMask.POINTER_MOTION
    elseif 0 != include & GdkModifierType.BUTTON1
        mask |= GdkEventMask.BUTTON1_MOTION
    elseif 0 != include & GdkModifierType.BUTTON2
        mask |= GdkEventMask.BUTTON2_MOTION
    elseif 0 != include & GdkModifierType.BUTTON3
        mask |= GdkEventMask.BUTTON3_MOTION
    else #if 0 != include & (GdkModifierType.BUTTON4 | GdkModifierType.BUTTON5)
        mask |= GdkEventMask.BUTTON_MOTION
    end
    add_events(widget, mask)
    @assert Base.isstructtype(T)
    if isbitstype(T)
        cb = cfunction_(move_cb, Cint, (Ptr{GObject}, Ptr{GdkEventMotion}, T))
    else
        cb = cfunction_(move_cb, Cint, (Ptr{GObject}, Ptr{GdkEventMotion}, Ref{T}))
    end
    closure = Gtk_signal_motion{T}(
        closure, cb,
        UInt32(include),
        UInt32(exclude)
        )
    signal_connect(notify_motion, widget, "motion-notify-event", Cint, (Ptr{GdkEventMotion},), after, closure)
end

function on_signal_scroll(scroll_cb::Function, widget::GtkWidget, vargs...)
    add_events(widget, GdkEventMask.SCROLL)
    signal_connect(scroll_cb, widget, "scroll-event", Cint, (Ptr{GdkEventScroll},), vargs...)
end

function reveal(c::GtkWidget, immediate::Bool = true)
    #region = ccall((:gdk_region_rectangle, libgdk), Ptr{Nothing}, (Ptr{GdkRectangle},), & allocation(c))
    #ccall((:gdk_window_invalidate_region, libgdk), Nothing, (Ptr{Nothing}, Ptr{Nothing}, Bool),
    #    gdk_window(c), region, true)
    ccall((:gtk_widget_queue_draw, libgtk), Nothing, (Ptr{GObject},), c)
    if immediate
        ccall((:gdk_window_process_updates, libgdk), Nothing, (Ptr{Nothing}, Int32), gdk_window(c), true)
    end
end

const default_mouse_cb = (w, event) -> nothing

const MHStack = Vector{Tuple{Symbol, Function}}

mutable struct MouseHandler
    button1press::Function
    button1release::Function
    button2press::Function
    button2release::Function
    button3press::Function
    button3release::Function
    motion::Function
    button1motion::Function
    button2motion::Function
    button3motion::Function
    scroll::Function
    stack::MHStack
    ids::Vector{Culong}
    widget::GtkWidget

    MouseHandler(ids::Vector{Culong}) =
        new(default_mouse_cb, default_mouse_cb, default_mouse_cb,
            default_mouse_cb, default_mouse_cb, default_mouse_cb,
            default_mouse_cb, default_mouse_cb, default_mouse_cb,
            default_mouse_cb, default_mouse_cb,
            Vector{Tuple{Symbol, Function}}(), ids)
end
MouseHandler() = MouseHandler(Culong[])

const MHPair = Tuple{MouseHandler, Symbol}

function mousedown_cb(ptr::Ptr, eventp::Ptr, this::MouseHandler)
    event = unsafe_load(eventp)
    if      event.button == 1
        this.button1press(this.widget, event)
    elseif  event.button == 2
        this.button2press(this.widget, event)
    elseif  event.button == 3
        this.button3press(this.widget, event)
    end
    Int32(false)
end

function mouseup_cb(ptr::Ptr, eventp::Ptr, this::MouseHandler)
    event = unsafe_load(eventp)
    if     event.button == 1
        this.button1release(this.widget, event)
    elseif event.button == 2
        this.button2release(this.widget, event)
    elseif event.button == 3
        this.button3release(this.widget, event)
    end
    Int32(false)
end

function mousemove_cb(ptr::Ptr, eventp::Ptr, this::MouseHandler)
    event = unsafe_load(eventp)
    this.motion(this.widget, event)
    if event.state & GdkModifierType.BUTTON1 != 0
        this.button1motion(this.widget, event)
    elseif event.state & GdkModifierType.BUTTON2 != 0
        this.button2motion(this.widget, event)
    elseif event.state & GdkModifierType.BUTTON3 != 0
        this.button3motion(this.widget, event)
    end
    Int32(false)
end

function mousescroll_cb(ptr::Ptr, eventp::Ptr, this::MouseHandler)
    event = unsafe_load(eventp)
    this.scroll(this.widget, event)
    Int32(false)
end

function push!(mh_evt::MHPair, func::Function)
    mh, evt = mh_evt
    push!(mh.stack, (evt, getfield(mh, evt)))
    setfield!(mh, evt, func)
    mh
end

function pop!(mh_evt::MHPair)
    mh, evt = mh_evt
    idx = findlast(x -> (x[1] == evt), mh.stack)
    if idx != 0
        _, func = mh.stack[idx]
        setfield!(mh, evt, func)
        deleteat!(mh.stack, idx)
    end
    mh
end


function waitforsignal(widget,signal)
  c = Condition()
  signal_connect(widget, signal) do w
      notify(c)
  end
  wait(c)
end
