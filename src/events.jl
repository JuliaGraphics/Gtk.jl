
gtk_doevent(timer,::Int32) = gtk_doevent(timer)
function gtk_doevent(timer=nothing)
    try
        sigatomic_begin()
        while (ccall((:gtk_events_pending,libgtk), Cint, ())) == true
            quit = ccall((:gtk_main_iteration,libgtk), Cint, ()) == true
            if quit
                #TODO: emit_event("gtk quit")
                break
            end
        end
    catch err
        try
            Base.display_error(err, catch_backtrace())
            println()
        end
    end
    sigatomic_end()
end

gtk_yield(src,cond,data) = gtk_yield(data)
function gtk_yield(data)
    yield()
    int32(true)
end

function gtk_main()
    try
        sigatomic_begin()
        ccall((:gtk_main,libgtk),Void,())
    catch err
        Base.display_error(err, catch_backtrace())
        println()
        rethrow(err)
    finally
        sigatomic_end()
    end
end

function gtk_quit()
    ccall((:gtk_quit,libgtk),Void,())
end

type _GPollFD
  @windows ? fd::Int : fd::Cint
  events::Cushort
  revents::Cushort
end

type _GSourceFuncs
    prepare::Ptr{Void}
    check::Ptr{Void}
    dispatch::Ptr{Void}
    finalize::Ptr{Void}
    closure_callback::Ptr{Void}
    closure_marshal::Ptr{Void}
end
function new_gsource(source_funcs::_GSourceFuncs)
    sizeof_gsource = WORD_SIZE
    gsource = C_NULL
    while gsource == C_NULL
        sizeof_gsource += WORD_SIZE
        gsource = ccall((:g_source_new,GLib.libglib),Ptr{Void},(Ptr{_GSourceFuncs},Int),&source_funcs,sizeof_gsource)
    end
    gsource
end

event_processing = false
event_pending = false
expiration = 0
function uv_prepare(src::Ptr{Void},timeout::Ptr{Cint})
    global event_pending, event_processing, expiration, uv_pollfd
    local tmout_ms::Cint
    if event_processing
        tmout_ms = -1
    elseif event_pending::Bool || !isempty(Base.Workqueue)
        tmout_ms = 0
    else
        tmout_ms = ccall(:uv_backend_timeout,Cint,(Ptr{Void},),Base.eventloop())
        tmout_min::Cint = (uv_pollfd::_GPollFD).fd == -1 ? 100 : 2500
        if tmout_ms < 0 || tmout_ms > tmout_min
            tmout_ms = tmout_min
        end
    end
    unsafe_store!(timeout, tmout_ms)
    if tmout_ms > 0
        now = ccall((:g_source_get_time,GLib.libglib),Int64,(Ptr{Void},),src)
        expiration = convert(Int64,now + tmout_ms*1000)
    else
        expiration = convert(Int64,0)
    end
    int32(tmout_ms == 0)
end
function uv_check(src::Ptr{Void})
    global event_pending, event_processing, expiration
    if expiration::Int64 == 0
        timeout_expired = true
    else
        now = ccall((:g_source_get_time,GLib.libglib),Int64,(Ptr{Void},),src)
        timeout_expired = (expiration::Int64 <= now);
    end
    event_pending = event_pending || uv_pollfd.revents != 0 || !isempty(Base.Workqueue) || timeout_expired
    int32(!event_processing::Bool && event_pending::Bool)
end
function uv_dispatch{T}(src::Ptr{Void},callback::Ptr{Void},data::T)
    global event_processing, event_pending
    event_processing = true
    event_pending = false
    ret::Cint = true
    try
        sigatomic_end()
        ret = ccall(callback,Cint,(T,),data)
    catch err
        try
            Base.display_error(err, catch_backtrace())
            println()
        end
    end
    sigatomic_begin()
    event_processing = false
    ret
end

function __init__()
    GError() do error_check
        ccall((:gtk_init_with_args,libgtk), Bool,
            (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Ptr{Void}, Ptr{Uint8}, Ptr{GError}),
            C_NULL, C_NULL, "Julia Gtk Bindings", C_NULL, C_NULL, error_check)
    end
    if true # enable glib main-loop backend instead of libuv
        global uv_sourcefuncs = _GSourceFuncs(
            cfunction(uv_prepare,Cint,(Ptr{Void},Ptr{Cint})),
            cfunction(uv_check,Cint,(Ptr{Void},)),
            cfunction(uv_dispatch,Cint,(Ptr{Void},Ptr{Void},Int)),
            C_NULL, C_NULL, C_NULL)
        src = new_gsource(uv_sourcefuncs)
        ccall((:g_source_set_can_recurse,GLib.libglib),Void,(Ptr{Void},Cint),src,true)
        ccall((:g_source_set_name,GLib.libglib),Void,(Ptr{Void},Ptr{Uint8}),src,"uv loop")
        ccall((:g_source_set_callback,GLib.libglib),Void,(Ptr{Void},Ptr{Void},Uint,Ptr{Void}),
            src,cfunction(gtk_yield,Cint,(Uint,)),1,C_NULL)

        uv_fd = @windows ? -1 : ccall(:uv_backend_fd,Cint,(Ptr{Void},),Base.eventloop())
        global uv_pollfd = _GPollFD(uv_fd, typemax(Cushort), 0)
        if (uv_pollfd::_GPollFD).fd != -1
            ccall((:g_source_add_poll,GLib.libglib),Void,(Ptr{Void},Ptr{_GPollFD}),src,&(uv_pollfd::_GPollFD))
        end

        ccall((:g_source_attach,GLib.libglib),Cuint,(Ptr{Void},Ptr{Void}),src,C_NULL)
        ccall((:g_source_unref,GLib.libglib),Void,(Ptr{Void},),src)

        # if g_main_depth > 0, a glib main-loop is already running,
        # so we don't need to start a new one
        if ccall((:g_main_depth,GLib.libglib),Cint,()) == 0
            #this swaps the libuv scheduler with the gtk_main_task scheduler
            global gtk_main_task = @task gtk_main()
            schedule(current_task())
            yieldto(gtk_main_task)
            # now the gtk_main_task is our default task
        end
    else
        global timeout
        timeout = Base.Timer(gtk_doevent)
        Base.start_timer(timeout,0.25,0.05)
    end
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
