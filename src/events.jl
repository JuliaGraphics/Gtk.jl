
gtk_doevent(timer,::Int32) = gtk_doevent(timer)
function gtk_doevent(timer=nothing)
    try
        while (ccall((:gtk_events_pending,libgtk), Cint, ())) == true
            #println("event! $(time())")
            quit = ccall((:gtk_main_iteration,libgtk), Cint, ()) == true
            if quit
                #TODO: emit_event("gtk quit")
                break
            end
        end
    catch err
        Base.display_error(err, catch_backtrace())
        println()
    end
end

function __init__()
    GError() do error_check
        ccall((:gtk_init_with_args,libgtk), Bool,
            (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Ptr{Void}, Ptr{Uint8}, Ptr{GError}),
            C_NULL, C_NULL, "Julia Gtk Bindings", C_NULL, C_NULL, error_check)
    end
    global timeout
    timeout = Base.TimeoutAsyncWork(gtk_doevent)
    Base.start_timer(timeout,.1,.005)
end

add_events(widget::GtkWidget, mask::Integer) = ccall((:gtk_widget_add_events,libgtk),Void,(Ptr{GObject},Enum),widget,mask)

# widget[:event] = function(ptr, obj)
#    stuff
# end
#function setindex!(w::GObject,cb::Function,sig::StringLike,vargs...)
#    signal_connect(cb,w,sig,vargs...)
#end


function on_signal_resize(resize_cb::Function, widget::GtkWidget, vargs...)
    signal_connect(resize_cb, widget, "size-allocate", Void, (Ptr{GdkRectangle},), vargs...)
end

function on_signal_destroy(destroy_cb::Function, widget::GObject, vargs...)
    signal_connect(destroy_cb, widget, "destroy", Void, (), vargs...)
end

function on_signal_button_press(press_cb::Function, widget::GtkWidget, vargs...)
    add_events(widget, GdkEventMask.BUTTON_PRESS)
    signal_connect(press_cb, widget, "button-press-event", Cint, (Ptr{GdkEventButton},), vargs...)
end
function on_signal_button_release(release_cb::Function, widget::GtkWidget, vargs...)
    add_events(widget, GdkEventMask.BUTTON_RELEASE)
    signal_connect(release_cb, widget, "button-release-event", Cint, (Ptr{GdkEventButton},), vargs...)
end

type Gtk_signal_motion{T}
    closure::T
    callback::Ptr{Void}
    include::Uint32
    exclude::Uint32
end
function notify_motion(p::Ptr{GObject}, eventp::Ptr{GdkEventMotion}, closure::Gtk_signal_motion)
    event = unsafe_load(eventp)
    if event.state & closure.include == closure.include &&
       event.state & closure.exclude == 0
        ret = ccall(closure.callback, Cint, (Ptr{GObject}, Ptr{GdkEventMotion}, Any), p, eventp, closure.closure)
    else
        ret = int32(false)
    end
    ccall((:gdk_event_request_motions,libgdk), Void, (Ptr{GdkEventMotion},), eventp)
    ret
end
function on_signal_motion{T}(move_cb::Function, widget::GtkWidget,
        include=0, exclude=GdkModifierType.BUTTONS, after::Bool=false, closure::T=w)
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
    else #if 0 != include & (GdkModifierType.BUTTON4|GdkModifierType.BUTTON5)
        mask |= GdkEventMask.BUTTON_MOTION
    end
    add_events(widget, mask)
    @assert Base.isstructtype(T)
    closure = Gtk_signal_motion{T}(
        closure,
        cfunction(move_cb, Cint, (Ptr{GObject}, Ptr{GdkEventMotion}, T)),
        uint32(include),
        uint32(exclude)
        )
    signal_connect(notify_motion, widget, "motion-notify-event", Cint, (Ptr{GdkEventMotion},), after, closure)
end

function reveal(c::GtkWidget, immediate::Bool=true)
    #region = ccall((:gdk_region_rectangle,libgdk),Ptr{Void},(Ptr{GdkRectangle},),&allocation(c))
    #ccall((:gdk_window_invalidate_region,libgdk),Void,(Ptr{Void},Ptr{Void},Bool),
    #    gdk_window(c), region, true)
    ccall((:gtk_widget_queue_draw,libgtk), Void, (Ptr{GObject},), c)
    if immediate
        ccall((:gdk_window_process_updates,libgdk), Void, (Ptr{Void}, Int32), gdk_window(c), true)
    end
end

const default_mouse_cb = (w, event)->nothing

type MouseHandler
    button1press::Function
    button1release::Function
    button2press::Function
    button2release::Function
    button3press::Function
    button3release::Function
    motion::Function
    button1motion::Function
    widget::GtkWidget

    MouseHandler() = new(default_mouse_cb, default_mouse_cb, default_mouse_cb,
                         default_mouse_cb, default_mouse_cb, default_mouse_cb,
                         default_mouse_cb, default_mouse_cb)
end

function mousedown_cb(ptr::Ptr, eventp::Ptr, this::MouseHandler)
    event = unsafe_load(eventp)
    if event.button == 1
        this.button1press(this.widget, event)
    elseif event.button == 2
        this.button2press(this.widget, event)
    elseif event.button == 3
        this.button3press(this.widget, event)
    end
    int32(false)
end

function mouseup_cb(ptr::Ptr, eventp::Ptr, this::MouseHandler)
    event = unsafe_load(eventp)
    if event.button == 1
        this.button1release(this.widget, event)
    elseif event.button == 2
        this.button2release(this.widget, event)
    elseif event.button == 3
        this.button3release(this.widget, event)
    end
    int32(false)
end

function mousemove_cb(ptr::Ptr, eventp::Ptr, this::MouseHandler)
    event = unsafe_load(eventp)
    this.motion(this.widget, event)
    if event.state & GdkModifierType.BUTTON1 != 0
        this.button1motion(this.widget, event)
    end
    int32(false)
end
