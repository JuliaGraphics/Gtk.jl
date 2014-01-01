
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

sizeof_gclosure = 0
function init()
    GError() do error_check
        ccall((:gtk_init_with_args,libgtk), Bool,
            (Ptr{Void}, Ptr{Void}, Ptr{Uint8}, Ptr{Void}, Ptr{Uint8}, Ptr{GError}),
            C_NULL, C_NULL, "Julia Gtk Bindings", C_NULL, C_NULL, error_check)
    end
    global sizeof_gclosure = WORD_SIZE
    closure = C_NULL
    while closure == C_NULL
        sizeof_gclosure += WORD_SIZE
        closure = ccall((:g_closure_new_simple,libgobject),Ptr{Void},(Int,Ptr{Void}),sizeof_gclosure,C_NULL)
    end
    ccall((:g_closure_sink,libgobject),Void,(Ptr{Void},),closure)
    global timeout
    timeout = Base.TimeoutAsyncWork(gtk_doevent)
    Base.start_timer(timeout,.1,.005)
end

# id = signal_connect(widget, :event, Void, (ArgsT...)) do ptr, evt_args..., closure
#    stuff
# end
function signal_connect(cb::Function,w::GObject,sig::Union(String,Symbol),
        RT::Type,param_types::Tuple,after::Bool=false,closure=w) #TODO: assert that length(param_types) is correct
    if isgeneric(cb)
        callback = cfunction(cb,RT,tuple(Ptr{GObject},param_types...,typeof(closure)))
        return ccall((:g_signal_connect_data,libgobject), Culong,
            (Ptr{GObject}, Ptr{Uint8}, Ptr{Void}, Any, Ptr{Void}, Enum),
                w,
                bytestring(sig),
                callback,
                closure,
                gc_ref_closure(closure),
                after*GConnectFlags.AFTER)
    end
    # oops, Julia doesn't support this natively yet -- fake it instead
    return _signal_connect(cb, w, sig, after, true,param_types,closure)
end

# id = signal_connect(widget, :event) do obj, evt_args...
#    stuff
# end
function signal_connect(cb::Function,w::GObject,sig::Union(String,Symbol),after::Bool=false)
    _signal_connect(cb, w, sig, after, false,nothing,nothing)
end
function _signal_connect(cb::Function,w::GObject,sig::Union(String,Symbol),after::Bool,gtk_call_conv::Bool,param_types,closure)
    closuref = ccall((:g_closure_new_object,libgobject), Ptr{Void}, (Cuint, Ptr{GObject}), sizeof_gclosure::Int+WORD_SIZE*2, w)
    closure_env = convert(Ptr{Any},closuref+sizeof_gclosure)
    unsafe_store!(closure_env, cb, 1)
    if gtk_call_conv
        env = Any[param_types,closure]
        unsafe_store!(closure_env, env, 2)
        ccall((:g_closure_add_invalidate_notifier,libgobject), Void,
            (Ptr{Void}, Any, Ptr{Void}), closuref, env, gc_ref_closure(env))
    else
        unsafe_store!(convert(Ptr{Int},closure_env), 0, 2)
    end
    ccall((:g_closure_add_invalidate_notifier,libgobject), Void,
        (Ptr{Void}, Any, Ptr{Void}), closuref, cb, gc_ref_closure(cb))
    ccall((:g_closure_set_marshal,libgobject), Void,
        (Ptr{Void}, Ptr{Void}), closuref, JuliaClosureMarshal)
    return ccall((:g_signal_connect_closure,libgobject), Culong,
        (Ptr{GObject}, Ptr{Uint8}, Ptr{Void}, Cint), w, bytestring(sig), closuref, after)
end
function GClosureMarshal(closuref, return_value, n_param_values,
                         param_values, invocation_hint, marshal_data)
    try
        closure_env = convert(Ptr{Any},closuref+sizeof_gclosure)
        cb = unsafe_load(closure_env, 1)
        gtk_calling_convention = (0 != unsafe_load(convert(Ptr{Int},closure_env), 2))
        params = Array(Any, n_param_values)
        if gtk_calling_convention
            # compatibility mode, if we must
            param_types,closure = unsafe_load(closure_env, 2)::Array{Any,1}
            length(param_types)+1 == n_param_values || error("GCallback called with the wrong number of parameters")
            for i = 1:n_param_values
                gv = mutable(param_values,i)
                g_type = unsafe_load(gv).g_type
                # avoid auto-unboxing for some builtin types in gtk_calling_convention mode
                if bool(ccall((:g_type_is_a,libgobject),Cint,(Int,Int),g_type,gobject_id))
                    params[i] = ccall((:g_value_get_object,libgobject), Ptr{GObject}, (Ptr{GValue},), gv)
                elseif bool(ccall((:g_type_is_a,libgobject),Cint,(Int,Int),g_type,gboxed_id))
                    params[i] = ccall((:g_value_get_boxed,libgobject), Ptr{Void}, (Ptr{GValue},), gv)
                elseif bool(ccall((:g_type_is_a,libgobject),Cint,(Int,Int),g_type,gstring_id))
                    params[i] = ccall((:g_value_get_string,libgobject), Ptr{Void}, (Ptr{GValue},), gv)
                else
                    params[i] = gv[]
                end
                if i > 1
                    params[i] = convert(param_types[i-1], params[i])
                end
            end
            push!(params, closure)
        else
            for i = 1:n_param_values
                params[i] = mutable(param_values,i)[]
            end
        end
        retval = cb(params...) # widget, args...
        if return_value != C_NULL && retval !== nothing
            g_type = unsafe_load(return_value).g_type
            if g_type != gvoid_id && g_type != 0
                return_value[] = gvalue(retval)
            end
        end
    catch e
        Base.display_error(e,catch_backtrace())
    end
    return nothing
end
JuliaClosureMarshal = cfunction(GClosureMarshal, Void,
    (Ptr{Void}, Ptr{GValue}, Cuint, Ptr{GValue}, Ptr{Void}, Ptr{Void}))


add_events(widget::GtkWidgetI, mask::Integer) = ccall((:gtk_widget_add_events,libgtk),Void,(Ptr{GObject},Enum),widget,mask)

# widget[:event] = function(ptr, obj)
#    stuff
# end
#function setindex!(w::GObject,cb::Function,sig::Union(String,Symbol),vargs...)
#    signal_connect(cb,w,sig,vargs...)
#end

# Signals API for the cb pointer
# Gtk 2
#   https://developer.gnome.org/gtk2/stable/GObject.html#GObject-destroy
#   https://developer.gnome.org/gtk2/stable/GtkWidget.html#GtkWidget-accel-closures-changed
# Gtk 3
#   https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-accel-closures-changed


signal_handler_disconnect(w::GObject, handler_id::Culong) =
    ccall(:g_signal_handler_disconnect, Void, (Ptr{GObject}, Culong), w, handler_id)

signal_handler_block(w::GObject, handler_id::Culong) =
    ccall(:g_signal_handler_block, Void, (Ptr{GObject}, Culong), w, handler_id)

signal_handler_unblock(w::GObject, handler_id::Culong) =
    ccall(:g_signal_handler_unblock, Void, (Ptr{GObject}, Culong), w, handler_id)

function signal_emit(w::GObject, sig::Union(String,Symbol), RT::Type, args...)
    i = isa(sig, String) ? search(sig, "::") : (0:-1)
    if !isempty(i)
        detail = @quark_str sig[last(i)+1:end]
        sig = sig[1:first(i)-1]
    else
        detail = uint32(0)
    end
    signal_id = ccall((:g_signal_lookup,libgobject),Cuint,(Ptr{Uint8},Csize_t), sig, G_OBJECT_CLASS_TYPE(w))
    return_value = RT===Void ? C_NULL : gvalue(RT)
    ccall((:g_signal_emitv,libgobject),Void,(Ptr{GValue},Cuint,Uint32,Ptr{GValue}),gvalues(w, args...),signal_id,detail,return_value)
    return_value[RT]
end

function on_signal_resize(resize_cb::Function, widget::GtkWidgetI, vargs...)
    signal_connect(resize_cb, widget, "size-allocate", Void, (Ptr{GdkRectangle},), vargs...)
end

function on_signal_destroy(destroy_cb::Function, widget::GObject, vargs...)
    signal_connect(destroy_cb, widget, "destroy", Void, (), vargs...)
end

function on_signal_button_press(press_cb::Function, widget::GtkWidgetI, vargs...)
    add_events(widget, GdkEventMask.BUTTON_PRESS_MASK)
    signal_connect(press_cb, widget, "button-press-event", Cint, (Ptr{GdkEventButton},), vargs...)
end
function on_signal_button_release(release_cb::Function, widget::GtkWidgetI, vargs...)
    add_events(widget, GdkEventMask.BUTTON_RELEASE_MASK)
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
function on_signal_motion{T}(move_cb::Function, widget::GtkWidgetI,
        include=0, exclude=GdkModifierType.BUTTONS_MASK, after::Bool=false, closure::T=w)
    exclude &= ~include
    mask = GdkEventMask.POINTER_MOTION_HINT_MASK
    if     0 == include & GdkModifierType.BUTTONS_MASK
        mask |= GdkEventMask.POINTER_MOTION_MASK
    elseif 0 != include & GdkModifierType.BUTTON1_MASK
        mask |= GdkEventMask.BUTTON1_MOTION_MASK
    elseif 0 != include & GdkModifierType.BUTTON2_MASK
        mask |= GdkEventMask.BUTTON2_MOTION_MASK
    elseif 0 != include & GdkModifierType.BUTTON3_MASK
        mask |= GdkEventMask.BUTTON3_MOTION_MASK
    else #if 0 != include & (GdkModifierType.BUTTON4_MASK|GdkModifierType.BUTTON5_MASK)
        mask |= GdkEventMask.BUTTON_MOTION_MASK
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

function reveal(c::GtkWidgetI, immediate::Bool=true)
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
    widget::GtkWidgetI

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
    if event.state & GdkModifierType.BUTTON1_MASK != 0
        this.button1motion(this.widget, event)
    end
    int32(false)
end
