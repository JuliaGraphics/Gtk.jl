
gtk_doevent(timer,::Int32) = gtk_doevent()
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
        error( "Failed to initialize Gtk" )
    end
    global timeout
    timeout = Base.TimeoutAsyncWork(gtk_doevent)
    Base.start_timer(timeout,.1,.005)
end

# id = signal_connect(widget, :event, Void, ()) do ptr, obj
#    stuff
# end
function signal_connect(cb::Function,w::GtkObject,sig::Union(String,Symbol),
        RT::Type,param_types::Tuple,gconnectflags=0,closure=w) #TODO: assert that length(param_types) is correct
    ccall((:g_signal_connect_data,libgobject), Culong,
        (Ptr{GtkObject}, Ptr{Uint8}, Ptr{Void}, Any, Ptr{Void}, Enum),
            w,
            bytestring(sig),
            cfunction(cb,RT,tuple(Ptr{GtkObject},param_types...,typeof(closure))),
            closure,
            gc_ref_closure(w),
            gconnectflags)
end

# widget[:event, Void, ()] = function(ptr, obj)
#    stuff
# end
#function setindex!(w::GtkObject,cb::Function,
#        sig::Union(String,Symbol),RT::Type,param_types::Tuple,vargs...)
#    signal_connect(w,sig,cb,RT,param_types,vargs...)
#end

# Signals API for the cb pointer
# Gtk 2
#   https://developer.gnome.org/gtk2/stable/GtkObject.html#GtkObject-destroy
#   https://developer.gnome.org/gtk2/stable/GtkWidget.html#GtkWidget-accel-closures-changed
# Gtk 3
#   https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-accel-closures-changed


signal_handler_disconnect(w::GtkObject, handler_id::Culong) =
    ccall(:g_signal_handler_disconnect, Void, (Ptr{GtkObject}, Culong), w, handler_id)

signal_handler_block(w::GtkObject, handler_id::Culong) =
    ccall(:g_signal_handler_block, Void, (Ptr{GtkObject}, Culong), w, handler_id)

signal_handler_unblock(w::GtkObject, handler_id::Culong) =
    ccall(:g_signal_handler_unblock, Void, (Ptr{GtkObject}, Culong), w, handler_id)

function signal_emit(w::GtkObject, sig::Union(String,Symbol), RT::Type, args...)
    i = isa(sig, String) ? search(sig, "::") : (0:-1)
    if !isempty(i)
        detail = @quark_str sig[last(i)+1:end]
        sig = sig[1:first(i)-1]
    else
        detail = uint32(0)
    end
    signal_id = ccall((:g_signal_lookup,libgobject),Cuint,(Ptr{Uint8},Csize_t), sig, G_OBJECT_CLASS_TYPE(w))
    return_value = gvalue(RT)
    ccall((:g_signal_emitv,libgobject),Void,(Ptr{GValue},Cuint,Uint32,Ptr{GValue1}),gvalues(w, args...),signal_id,detail,&return_value)
    return_value[RT]
end

function on_signal_resize(resize_cb::Function, widget::GtkWidget, vargs...)
    signal_connect(resize_cb, widget, "size-allocate", Void, (Ptr{GdkRectangle},), vargs...)
end
function notify_resize(::Ptr{GtkObject}, size::Ptr{GdkRectangle}, widget::GtkWidget)
    widget.all = unsafe_load(size)
    nothing
end

function on_signal_destroy(destroy_cb::Function, widget::GtkObject, vargs...)
    signal_connect(destroy_cb, widget, "destroy", Void, (), vargs...)
end

function on_signal_button_press(press_cb::Function, widget::GtkWidget, vargs...)
    ccall((:gtk_widget_add_events,libgtk),Void,(Ptr{GtkObject},Cint),
        widget,GdkEventMask.GDK_BUTTON_PRESS_MASK)
    signal_connect(press_cb, widget, "button-press-event", Cint, (Ptr{GdkEventButton},), vargs...)
end
function on_signal_button_release(release_cb::Function, widget::GtkWidget, vargs...)
    ccall((:gtk_widget_add_events,libgtk),Void,(Ptr{GtkObject},Cint),
        widget,GdkEventMask.GDK_BUTTON_RELEASE_MASK)
    signal_connect(release_cb, widget, "button-release-event", Cint, (Ptr{GdkEventButton},), vargs...)
end

type Gtk_signal_motion{T}
    closure::T
    callback::Ptr{Void}
    include::Uint32
    exclude::Uint32
end
function notify_motion(p::Ptr{GtkObject}, eventp::Ptr{GdkEventMotion}, closure::Gtk_signal_motion)
    event = unsafe_load(eventp)
    if event.state & closure.include == closure.include &&
       event.state & closure.exclude == 0
        ret = ccall(closure.callback, Cint, (Ptr{GtkObject}, Ptr{GdkEventMotion}, Any), p, eventp, closure.closure)
    else
        ret = int32(false)
    end
    ccall((:gdk_event_request_motions,libgdk), Void, (Ptr{GdkEventMotion},), eventp)
    ret
end
function on_signal_motion{T}(move_cb::Function, widget::GtkWidget,
        include=0, exclude=GdkModifierType.GDK_BUTTONS_MASK, gconnectflags=0,closure::T=w)
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
    ccall((:gtk_widget_add_events,libgtk),Void,(Ptr{GtkObject},Cint), widget, mask)
    @assert Base.isstructtype(T)
    closure = Gtk_signal_motion{T}(
        closure,
        cfunction(move_cb, Cint, (Ptr{GtkObject}, Ptr{GdkEventMotion}, T)),
        uint32(include),
        uint32(exclude)
        )
    signal_connect(notify_motion, widget, "motion-notify-event", Cint, (Ptr{GdkEventMotion},), gconnectflags, closure)
end

function reveal(c::GtkWidget, immediate::Bool=true)
    #region = ccall((:gdk_region_rectangle,libgdk),Ptr{Void},(Ptr{GdkRectangle},),&c.all)
    #ccall((:gdk_window_invalidate_region,libgdk),Void,(Ptr{Void},Ptr{Void},Bool),
    #    gdk_window(c), region, true)
    ccall((:gtk_widget_queue_draw,libgtk), Void, (Ptr{GtkObject},), c)
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
    widget::GtkWidget

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
