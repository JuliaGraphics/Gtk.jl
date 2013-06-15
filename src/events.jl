
gtk_doevent(::Int32) = gtk_doevent()
function gtk_doevent()
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
function init()
    if !ccall((:gtk_init_check,libgtk), Bool, (Ptr{Void}, Ptr{Void}), C_NULL, C_NULL)
        error( "Failed to initialize GTK" )
    end
    global timeout
    timeout = Base.TimeoutAsyncWork(gtk_doevent)
    Base.start_timer(timeout,int64(100),int64(10))
end

function signal_connect{T}(w::GTKWidget,sig::ASCIIString,closure::T,cb::Ptr{Void},gconnectflags)
    if isa(closure, GTKWidget)
        unref = C_NULL
    else
        unref = gc_unref_closure(T)
        gc_ref(closure)
    end
    ccall((:g_signal_connect_data,libgobject), Culong,
        (GtkWidget, Ptr{Uint8}, Ptr{Void}, Any, Ptr{Void}, Enum),
        w, sig, cb, closure, unref, gconnectflags)
end
# Signals API for the cb pointer
# GTK 2
#   https://developer.gnome.org/gtk2/stable/GtkObject.html#GtkObject-destroy
#   https://developer.gnome.org/gtk2/stable/GtkWidget.html#GtkWidget-accel-closures-changed
# GTK 3
#   https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-accel-closures-changed


function signal_disconnect(w::GTKWidget, handler_id::Culong)
    ccall(:g_signal_handler_disconnect, Void, (GtkWidget, Culong), w, handler_id)
end

function on_signal_resize{T}(widget::GTKWidget, resize_cb::Function, closure::T)
    signal_connect(widget, "size-allocate", closure,
        cfunction(resize_cb, Void, (GtkWidget, Ptr{GdkRectangle}, T)), 0)
end
function notify_resize(::GtkWidget, size::Ptr{GdkRectangle}, widget::GTKWidget)
    widget.all = unsafe_load(size)
    nothing
end

function on_signal_destroy{T}(widget::GTKWidget, destroy_cb::Function, closure::T)
    signal_connect(widget, "destroy", closure,
        cfunction(destroy_cb, Void, (GtkWidget, T)), 0)
end

function on_signal_button_press{T}(widget::GTKWidget, press_cb::Function, closure::T)
    ccall((:gtk_widget_add_events,libgtk),Void,(GtkWidget,Cint),
        widget,GdkEventMask.GDK_BUTTON_PRESS_MASK)
    signal_connect(widget, "button-press-event", closure,
        cfunction(press_cb, Cint, (GtkWidget, Ptr{GdkEventButton}, T)), 0)
end
function on_signal_button_release{T}(widget::GTKWidget, release_cb::Function, closure::T)
    ccall((:gtk_widget_add_events,libgtk),Void,(GtkWidget,Cint),
        widget,GdkEventMask.GDK_BUTTON_RELEASE_MASK)
    signal_connect(widget, "button-release-event", closure,
        cfunction(release_cb, Cint, (GtkWidget, Ptr{GdkEventButton}, T)), 0)
end

type GTK_signal_motion{T}
    closure::T
    callback::Ptr{Void}
    include::Uint32
    exclude::Uint32
end
function notify_motion{T}(p::GtkWidget, eventp::Ptr{GdkEventMotion}, closure::GTK_signal_motion{T})
    event = unsafe_load(eventp)
    if event.state & closure.include == closure.include &&
       event.state & closure.exclude == 0
        ret = ccall(closure.callback, Cint, (GtkWidget, Ptr{GdkEventMotion}, Any), p, eventp, closure.closure)
    else
        ret = int32(false)
    end
    ccall((:gdk_event_request_motions,libgdk), Void, (Ptr{GdkEventMotion},), eventp)
    ret
end
function on_signal_motion{T}(widget::GTKWidget, move_cb::Function, closure::T,
        include=0, exclude=GdkModifierType.GDK_BUTTONS_MASK)
    exclude &= ~include
    mask = GdkEventMask.GDK_POINTER_MOTION_HINT_MASK
    if     0 == include & GdkModifierType.GDK_BUTTONS_MASK
        mask |= GdkEventMask.GDK_POINTER_MOTION_MASK
    elseif 0 != include & GdkModifierType.GDK_BUTTON1_MASK
        mask |= GdkEventMask.GDK_BUTTON1_MOTION_MASK
    elseif 0 != include & GdkModifierType.GDK_BUTTON2_MASK
        mask |= GdkEventMask.GDK_BUTTON2_MOTION_MASK
    elseif 0 != include & GdkModifierType.GDK_BUTTON3_MASK
        mask |= GdkEventMask.GDK_BUTTON3_MOTION_MASK
    else #if 0 != include & (GdkModifierType.GDK_BUTTON4_MASK|GdkModifierType.GDK_BUTTON5_MASK)
        mask |= GdkEventMask.GDK_BUTTON_MOTION_MASK
    end
    ccall((:gtk_widget_add_events,libgtk),Void,(GtkWidget,Cint), widget, mask)
    @assert Base.isstructtype(T)
    closure = GTK_signal_motion(
        closure,
        cfunction(move_cb, Cint, (GtkWidget, Ptr{GdkEventMotion}, T)),
        uint32(include),
        uint32(exclude)
        )
    signal_connect(widget, "motion-notify-event", closure,
        cfunction(notify_motion, Cint, (GtkWidget, Ptr{GdkEventMotion}, GTK_signal_motion{T})), 0)
end

function reveal(c::GTKWidget, immediate::Bool=false)
    #region = ccall((:gdk_region_rectangle,libgdk),Ptr{Void},(Ptr{GdkRectangle},),&c.all)
    #ccall((:gdk_window_invalidate_region,libgdk),Void,(Ptr{Void},Ptr{Void},Bool),
    #    gdk_window(c), region, true)
    ccall((:gtk_widget_queue_draw,libgtk), Void, (GtkWidget,), c)
    if immediate
        ccall((:gdk_window_process_updates,libgdk), Void, (Ptr{Void}, Int32), gdk_window(c), true)
    end
end

const default_mouse_cb = (w, x, y)->nothing

type MouseHandler
    button1press::Function
    button1release::Function
    button2press::Function
    button2release::Function
    button3press::Function
    button3release::Function
    motion::Function
    button1motion::Function
    widget::GTKWidget

    MouseHandler() = new(default_mouse_cb, default_mouse_cb, default_mouse_cb,
                         default_mouse_cb, default_mouse_cb, default_mouse_cb,
                         default_mouse_cb, default_mouse_cb)
end

function mousedown_cb(ptr::Ptr, eventp::Ptr, this::MouseHandler)
    event = unsafe_load(eventp)
    if event.button == 1
        this.button1press(this.widget, event.x, event.y)
    elseif event.button == 2
        this.button2press(this.widget, event.x, event.y)
    elseif event.button == 3
        this.button3press(this.widget, event.x, event.y)
    end
    int32(false)
end

function mouseup_cb(ptr::Ptr, eventp::Ptr, this::MouseHandler)
    event = unsafe_load(eventp)
    if event.button == 1
        this.button1release(this.widget, event.x, event.y)
    elseif event.button == 2
        this.button2release(this.widget, event.x, event.y)
    elseif event.button == 3
        this.button3release(this.widget, event.x, event.y)
    end
    int32(false)
end

function mousemove_cb(ptr::Ptr, eventp::Ptr, this::MouseHandler)
    event = unsafe_load(eventp)
    this.motion(this.widget, event.x, event.y)
    if event.state & GdkModifierType.GDK_BUTTON1_MASK != 0
        this.button1motion(this.widget, event.x, event.y)
    end
    int32(false)
end
