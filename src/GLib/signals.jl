# id = signal_connect(widget, :event, Void, (ArgsT...)) do ptr, evt_args..., closure
#    stuff
# end
function signal_connect(cb::Function,w::GObject,sig::StringLike,
        RT::Type,param_types::Tuple,after::Bool=false,closure=w) #TODO: assert that length(param_types) is correct
    if isgeneric(cb) && !isbits(closure)
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
function signal_connect(cb::Function,w::GObject,sig::StringLike,after::Bool=false)
    _signal_connect(cb, w, sig, after, false,nothing,nothing)
end
function _signal_connect(cb::Function,w::GObject,sig::StringLike,after::Bool,gtk_call_conv::Bool,param_types,closure)
    @assert sizeof_gclosure > 0
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
        (Ptr{Void}, Ptr{Void}), closuref, JuliaClosureMarshal::Ptr{Void})
    return ccall((:g_signal_connect_closure,libgobject), Culong,
        (Ptr{GObject}, Ptr{Uint8}, Ptr{Void}, Cint), w, bytestring(sig), closuref, after)
end
function GClosureMarshal(closuref, return_value, n_param_values,
                         param_values, invocation_hint, marshal_data)
    @assert sizeof_gclosure > 0
    g_siginterruptible() do
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
                gtyp = unsafe_load(gv).g_type
                # avoid auto-unboxing for some builtin types in gtk_calling_convention mode
                if g_isa(gtyp,g_type(GObject))
                    params[i] = ccall((:g_value_get_object,libgobject), Ptr{GObject}, (Ptr{GValue},), gv)
                elseif g_isa(gtyp,g_type(GBoxed))
                    params[i] = ccall((:g_value_get_boxed,libgobject), Ptr{Void}, (Ptr{GValue},), gv)
                elseif g_isa(gtyp,g_type(String))
                    params[i] = ccall((:g_value_get_string,libgobject), Ptr{Void}, (Ptr{GValue},), gv)
                else
                    params[i] = gv[Any]
                end
                if i > 1
                    params[i] = convert(param_types[i-1], params[i])
                end
            end
            push!(params, closure)
        else
            for i = 1:n_param_values
                params[i] = mutable(param_values,i)[Any]
            end
        end
        retval = cb(params...) # widget, args...
        if return_value != C_NULL && retval !== nothing
            gtyp = unsafe_load(return_value).g_type
            if gtyp != g_type(Void) && gtyp != 0
                return_value[] = gvalue(retval)
            end
        end
    end
    return nothing
end

# Signals API for the cb pointer
# Gtk 2
#   https://developer.gnome.org/gtk2/stable/GObject.html#GObject-destroy
#   https://developer.gnome.org/gtk2/stable/GtkWidget.html#GtkWidget-accel-closures-changed
# Gtk 3
#   https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-accel-closures-changed


signal_handler_disconnect(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_disconnect,libgobject), Void, (Ptr{GObject}, Culong), w, handler_id)

signal_handler_block(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_block,libgobject), Void, (Ptr{GObject}, Culong), w, handler_id)

signal_handler_unblock(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_unblock,libgobject), Void, (Ptr{GObject}, Culong), w, handler_id)

function signal_emit(w::GObject, sig::StringLike, RT::Type, args...)
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

g_sigatom_flag = false
function g_sigatom(f::Base.Callable)
    global g_sigatom_flag
    @assert !g_sigatom_flag
    try
        g_sigatom_flag = true
        sigatomic_begin()
        f()
    catch err
        @assert g_sigatom_flag
        sigatomic_end()
        g_sigatom_flag = false
        Base.display_error(err, catch_backtrace())
        println()
        rethrow(err)
    end
    @assert g_sigatom_flag
    g_sigatom_flag = false
    sigatomic_end()
end

function g_siginterruptible(f::Base.Callable)
    global g_sigatom_flag
    prev = g_sigatom_flag
    try
        if prev
            g_sigatom_flag = false
            sigatomic_end()
        end
        f()
    catch err
        try
            Base.display_error(err, catch_backtrace())
            println()
        end
    end
    if prev
        sigatomic_begin()
        g_sigatom_flag = true
    end
end

type _GPollFD
  @windows ? fd::Int : fd::Cint
  events::Cushort
  revents::Cushort
  _GPollFD(fd, ev) = new(fd, ev, 0)
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

expiration = uint64(0)
if VERSION < v"0.3-"
    isempty_workqueue() = isempty(Base.Workqueue) || (length(Base.Workqueue) == 1 && Base.Workqueue[1] == Base.roottask)
    function uv_loop_alive(evt)
        ccall(:uv_stop,Void,(Ptr{Void},),evt)
        ccall(:uv_run,Cint,(Ptr{Void},Cint),evt,2) != 0
    end
else
    isempty_workqueue() = isempty(Base.Workqueue)
    uv_loop_alive(evt) = ccall(:uv_loop_alive,Cint,(Ptr{Void},),evt) != 0
end
function uv_prepare(src::Ptr{Void},timeout::Ptr{Cint})
    global expiration, uv_pollfd
    local tmout_ms::Cint
    evt = Base.eventloop()
    if !isempty_workqueue()
        tmout_ms = 0
    elseif !uv_loop_alive(evt)
        tmout_ms = -1
    elseif uv_pollfd.revents != 0
        tmout_ms = 0
    elseif @windows ? (VERSION < v"0.3-") : false # uv_backend_timeout broken on windows before Julia v0.3-rc2
        tmout_ms = 10
    else
        tmout_ms = ccall(:uv_backend_timeout,Cint,(Ptr{Void},),evt)
        tmout_min::Cint = (uv_pollfd::_GPollFD).fd == -1 ? 100 : 5000
        if tmout_ms < 0 || tmout_ms > tmout_min
            tmout_ms = tmout_min
        end
    end
    timeout != C_NULL && unsafe_store!(timeout, tmout_ms)
    if tmout_ms < 0
        expiration = typemax(Uint64)
    elseif tmout_ms > 0
        now = ccall((:g_source_get_time,GLib.libglib),Uint64,(Ptr{Void},),src)
        expiration = convert(Uint64,now + tmout_ms*1000)
    else #tmout_ms == 0
        expiration = uint64(0)
    end
    int32(tmout_ms == 0)
end
function uv_check(src::Ptr{Void})
    global expiration
    ex = expiration::Uint64
    if !isempty_workqueue()
        return int32(1)
    elseif !uv_loop_alive(Base.eventloop())
        return int32(0)
    elseif ex == 0
        return int32(1)
    elseif uv_pollfd.revents != 0
        return int32(1)
    else
        now = ccall((:g_source_get_time,GLib.libglib),Uint64,(Ptr{Void},),src)
        return int32(ex <= now)
    end
end
function uv_dispatch{T}(src::Ptr{Void},callback::Ptr{Void},data::T)
    ret = ccall(callback,Cint,(T,),data)
    ret
end

yield_stack = Task[] # need to make sure we return to g_loop_run_run in the same order we were called
if VERSION < v"0.3-"
    function schedule_and_wait(task::Task)
        task.runnable || schedule(task)
        wait()
    end
else
    function schedule_and_wait(task::Task)
        # unfair scheduler version of Base.schedule_and_wait
        if task.state == :runnable
            yieldto(task)
        else
            wait()
        end
    end
end
function g_yield(data)
    global yield_stack
    ct = current_task()
    push!(yield_stack, ct)
    g_siginterruptible() do
        yield()
    end
    newtask = pop!(yield_stack)
    if newtask != ct
        schedule_and_wait(newtask)
    end
    int32(true)
end

sizeof_gclosure = 0
function __init__()
    ccall((:g_type_init,libgobject),Void,())
    global jlref_quark = quark"julia_ref"
    global sizeof_gclosure = WORD_SIZE
    closure = C_NULL
    while closure == C_NULL
        sizeof_gclosure += WORD_SIZE
        closure = ccall((:g_closure_new_simple,libgobject),Ptr{Void},(Int,Ptr{Void}),sizeof_gclosure,C_NULL)
    end
    ccall((:g_closure_sink,libgobject),Void,(Ptr{Void},),closure)

    global JuliaClosureMarshal = cfunction(GClosureMarshal, Void,
        (Ptr{Void}, Ptr{GValue}, Cuint, Ptr{GValue}, Ptr{Void}, Ptr{Void}))
    global exiting = false
    atexit(()->global exiting = true)

    global uv_sourcefuncs = _GSourceFuncs(
        cfunction(uv_prepare,Cint,(Ptr{Void},Ptr{Cint})),
        cfunction(uv_check,Cint,(Ptr{Void},)),
        cfunction(uv_dispatch,Cint,(Ptr{Void},Ptr{Void},Int)),
        C_NULL, C_NULL, C_NULL)
    src = new_gsource(uv_sourcefuncs)
    ccall((:g_source_set_can_recurse,GLib.libglib),Void,(Ptr{Void},Cint),src,true)
    ccall((:g_source_set_name,GLib.libglib),Void,(Ptr{Void},Ptr{Uint8}),src,"uv loop")
    ccall((:g_source_set_callback,GLib.libglib),Void,(Ptr{Void},Ptr{Void},Uint,Ptr{Void}),
        src,cfunction(g_yield,Cint,(Uint,)),1,C_NULL)

    uv_fd = @windows ? -1 : ccall(:uv_backend_fd,Cint,(Ptr{Void},),Base.eventloop())
    global uv_pollfd = _GPollFD(uv_fd, typemax(Cushort))
    if (uv_pollfd::_GPollFD).fd != -1
        ccall((:g_source_add_poll,GLib.libglib),Void,(Ptr{Void},Ptr{_GPollFD}),src,&(uv_pollfd::_GPollFD))
    end

    ccall((:g_source_attach,GLib.libglib),Cuint,(Ptr{Void},Ptr{Void}),src,C_NULL)
    ccall((:g_source_unref,GLib.libglib),Void,(Ptr{Void},),src)
end

