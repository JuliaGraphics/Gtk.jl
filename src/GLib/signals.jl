# id = VERSION >= v"0.4-"get, :event, Nothing, (ArgsT...)) do ptr, evt_args..., closure
#    stuff
# end
function signal_connect(cb::Function, w::GObject, sig::AbstractStringLike,
        ::Type{RT}, param_types::Tuple, after::Bool = false, user_data::CT = w) where {CT, RT}
    signal_connect_generic(cb, w, sig, RT, param_types, after, user_data)
end

function signal_connect_generic(cb::Function, w::GObject, sig::AbstractStringLike,
        ::Type{RT}, param_types::Tuple, after::Bool = false, user_data::CT = w) where {CT, RT}  #TODO: assert that length(param_types) is correct
    callback = cfunction_(cb, RT, tuple(Ptr{GObject}, param_types..., Ref{CT}))
    ref, deref = gc_ref_closure(user_data)
    return ccall((:g_signal_connect_data, libgobject), Culong,
                 (Ptr{GObject}, Ptr{UInt8}, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}, GEnum),
                 w,
                 bytestring(sig),
                 callback,
                 ref,
                 deref,
                 after * GConnectFlags.AFTER)
end

# id = signal_connect(widget, :event) do obj, evt_args...
#    stuff
# end
function signal_connect(cb::Function, w::GObject, sig::AbstractStringLike, after::Bool = false)
    _signal_connect(cb, w, sig, after, false, nothing, nothing)
end
function _signal_connect(cb::Function, w::GObject, sig::AbstractStringLike, after::Bool, gtk_call_conv::Bool, param_types, user_data)
    @assert sizeof_gclosure > 0
    closuref = ccall((:g_closure_new_object, libgobject), Ptr{Nothing}, (Cuint, Ptr{GObject}), sizeof_gclosure::Int + GLib.WORD_SIZE * 2, w)
    closure_env = convert(Ptr{Ptr{Nothing}}, closuref + sizeof_gclosure)
    if gtk_call_conv
        env = Any[param_types, user_data]
        ref_env, deref_env = gc_ref_closure(env)
        unsafe_store!(closure_env, ref_env, 2)
        ccall((:g_closure_add_invalidate_notifier, libgobject), Nothing,
            (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), closuref, ref_env, deref_env)
    else
        unsafe_store!(convert(Ptr{Int}, closure_env), 0, 2)
    end
    ref_cb, deref_cb = gc_ref_closure(cb)
    unsafe_store!(closure_env, ref_cb, 1)
    ccall((:g_closure_add_invalidate_notifier, libgobject), Nothing,
        (Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}), closuref, ref_cb, deref_cb)
    ccall((:g_closure_set_marshal, libgobject), Nothing,
        (Ptr{Nothing}, Ptr{Nothing}), closuref, JuliaClosureMarshal::Ptr{Nothing})
    return ccall((:g_signal_connect_closure, libgobject), Culong,
        (Ptr{GObject}, Ptr{UInt8}, Ptr{Nothing}, Cint), w, bytestring(sig), closuref, after)
end
function GClosureMarshal(closuref::Ptr{Nothing}, return_value::Ptr{GValue}, n_param_values::Cuint,
                         param_values::Ptr{GValue}, invocation_hint::Ptr{Nothing}, marshal_data::Ptr{Nothing})
    @assert sizeof_gclosure > 0
    closure_env = convert(Ptr{Any}, closuref + sizeof_gclosure)
    cb = unsafe_load(closure_env, 1)
    gtk_calling_convention = (0 != unsafe_load(convert(Ptr{Int}, closure_env),  2))
    params = Vector{Any}(undef, n_param_values)
    local retval = nothing
    g_siginterruptible(cb) do
        if gtk_calling_convention
            # compatibility mode, if we must
            param_types, user_data = unsafe_load(closure_env, 2)::Array{Any, 1}
            length(param_types) + 1 == n_param_values || error("GCallback called with the wrong number of parameters")
            for i = 1:n_param_values
                gv = mutable(param_values, i)
                gtyp = unsafe_load(gv).g_type
                # avoid auto-unboxing for some builtin types in gtk_calling_convention mode
                if g_isa(gtyp, g_type(GObject))
                    params[i] = ccall((:g_value_get_object, libgobject), Ptr{GObject}, (Ptr{GValue},), gv)
                elseif g_isa(gtyp, g_type(GBoxed))
                    params[i] = ccall((:g_value_get_boxed, libgobject), Ptr{Nothing}, (Ptr{GValue},), gv)
                elseif g_isa(gtyp, g_type(AbstractString))
                    params[i] = ccall((:g_value_get_string, libgobject), Ptr{Nothing}, (Ptr{GValue},), gv)
                else
                    params[i] = gv[Any]
                end
                if i > 1
                    params[i] = convert(param_types[i - 1], params[i])
                end
            end
            push!(params, user_data)
        else
            for i = 1:n_param_values
                params[i] = mutable(param_values, i)[Any]
            end
        end
        # note: make sure not to leak any of the GValue objects into this task switch, since many of them were alloca'd
        retval = cb(params...) # widget, args...
        if return_value != C_NULL && retval !== nothing
            gtyp = unsafe_load(return_value).g_type
            if gtyp != g_type(Nothing) && gtyp != 0
                try
                    return_value[] = gvalue(retval)
                catch
                    @async begin # make this async to prevent task switches from being present right here
                        blame(cb)
                        println("ERROR: failed to set return value of type $(typeof(retval)); did your callback return an unintentional value?")
                    end
                end
            end
        end
    end
    return nothing
end

function blame(cb)
    warn("Executing ", cb, ":")
end

# Signals API for the cb pointer
# Gtk 2
#   https://developer.gnome.org/gtk2/stable/GObject.html#GObject-destroy
#   https://developer.gnome.org/gtk2/stable/GtkWidget.html#GtkWidget-accel-closures-changed
# Gtk 3
#   https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-accel-closures-changed


signal_handler_disconnect(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_disconnect, libgobject), Nothing, (Ptr{GObject}, Culong), w, handler_id)

signal_handler_block(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_block, libgobject), Nothing, (Ptr{GObject}, Culong), w, handler_id)

signal_handler_unblock(w::GObject, handler_id::Culong) =
    ccall((:g_signal_handler_unblock, libgobject), Nothing, (Ptr{GObject}, Culong), w, handler_id)

function signal_emit(w::GObject, sig::AbstractStringLike, RT::Type, args...)
    i = isa(sig, AbstractString) ? something(findfirst("::", sig), 0:-1) : (0:-1)
    if !isempty(i)
        detail = @quark_str sig[last(i) + 1:end]
        sig = sig[1:first(i)-1]
    else
        detail = UInt32(0)
    end
    signal_id = ccall((:g_signal_lookup, libgobject), Cuint, (Ptr{UInt8}, Csize_t), sig, G_OBJECT_CLASS_TYPE(w))
    return_value = RT === Nothing ? C_NULL : gvalue(RT)
    ccall((:g_signal_emitv, libgobject), Nothing, (Ptr{GValue}, Cuint, UInt32, Ptr{GValue}), gvalues(w, args...), signal_id, detail, return_value)
    RT === Nothing ? nothing : return_value[RT]
end

g_stack = nothing # need to call g_loop_run from only one stack
const g_yielded = Ref(false) # when true, use the `g_doatomic` queue to run sigatom functions
const g_doatomic = [] # (work, notification) scheduler queue
const g_sigatom_flag = Ref(false) # keep track of Base sigatomic state
function g_sigatom(@nospecialize(f)) # calls f, where f never throws (but this function may throw)
    global g_sigatom_flag, g_stack, g_doatomic
    prev = g_sigatom_flag[]
    stk = g_stack
    ct = current_task()
    if g_yielded[]
        @assert g_stack !== nothing && g_stack != ct && !prev
        push!(g_doatomic, (f, ct))
        return wait()
    end

    if !prev
        sigatomic_begin()
        g_sigatom_flag[] = true
    end
    ret = nothing
    try
        if g_stack === ct
            ret = f()
        else
            @assert g_stack === nothing && !prev
            g_stack = ct
            ret = f()
        end
    catch err
        g_stack = stk
        @assert g_sigatom_flag[]
        if !prev
            g_sigatom_flag[] = false
            sigatomic_end() # may throw SIGINT
        end
        Base.println("FATAL ERROR: Gtk state corrupted by error thrown in a callback:")
        Base.display_error(err, catch_backtrace())
        println()
        rethrow(err)
    end
    g_stack = stk
    @assert g_sigatom_flag[]
    if !prev
        g_sigatom_flag[] = false
        sigatomic_end() # may throw SIGINT
    end
    return ret
end
macro sigatom(f)
    return quote
        g_sigatom() do
            $(esc(f))
        end
    end
end

function g_siginterruptible(f::Base.Callable, cb) # calls f (which may throw), but this function never throws
    global g_sigatom_flag, g_stack
    prev = g_sigatom_flag[]
    @assert xor(prev, (current_task() !== g_stack))
    try
        if prev
            # also know that current_task() === g_stack
            g_sigatom_flag[] = false
            sigatomic_end() # may throw SIGINT
        end
        f()
    catch err
        bt = catch_backtrace()
        @async begin # make this async to prevent task switches from being present right here
            blame(cb)
            Base.display_error(err, bt)
            println()
        end
    end
    @assert !g_sigatom_flag[]
    if prev
        sigatomic_begin()
        g_sigatom_flag[] = true
    end
    nothing
end

function g_yield(data)
    global g_yielded, g_doatomic
    while true
        g_yielded[] = true
        g_siginterruptible(yield, yield)
        g_yielded[] = false
        run_delayed_finalizers()

        if isempty(g_doatomic)
            return Int32(true)
        else
            f, t = pop!(g_doatomic)
            ret = nothing
            iserror = false
            try
                ret = f()
            catch err
                iserror = true
                ret = err
            end
            schedule(t, ret, error = iserror)
        end
    end
end

mutable struct _GPollFD
  @static Sys.iswindows() ? fd::Int : fd::Cint
  events::Cushort
  revents::Cushort
  _GPollFD(fd, ev) = new(fd, ev, 0)
end

mutable struct _GSourceFuncs
    prepare::Ptr{Nothing}
    check::Ptr{Nothing}
    dispatch::Ptr{Nothing}
    finalize::Ptr{Nothing}
    closure_callback::Ptr{Nothing}
    closure_marshal::Ptr{Nothing}
end
function new_gsource(source_funcs::_GSourceFuncs)
    sizeof_gsource = GLib.WORD_SIZE
    gsource = C_NULL
    while gsource == C_NULL
        sizeof_gsource += GLib.WORD_SIZE
        gsource = ccall((:g_source_new, GLib.libglib), Ptr{Nothing}, (Ptr{_GSourceFuncs}, Int), Ref(source_funcs), sizeof_gsource)
    end
    gsource
end

expiration = UInt64(0)
_isempty_workqueue() = isempty(Base.Workqueue)
uv_loop_alive(evt) = ccall(:uv_loop_alive, Cint, (Ptr{Nothing},), evt) != 0

function uv_prepare(src::Ptr{Nothing}, timeout::Ptr{Cint})
    global expiration, uv_pollfd
    local tmout_ms::Cint
    evt = Base.eventloop()
    if !_isempty_workqueue()
        tmout_ms = 0
    elseif !uv_loop_alive(evt)
        tmout_ms = -1
    elseif uv_pollfd.revents != 0
        tmout_ms = 0
    else
        ccall(:uv_update_time, Nothing, (Ptr{Nothing},), evt)
        tmout_ms = ccall(:uv_backend_timeout, Cint, (Ptr{Nothing},), evt)
        tmout_min::Cint = (uv_pollfd::_GPollFD).fd == -1 ? 100 : 5000
        if tmout_ms < 0 || tmout_ms > tmout_min
            tmout_ms = tmout_min
        end
    end
    timeout != C_NULL && unsafe_store!(timeout, tmout_ms)
    if tmout_ms < 0
        expiration = typemax(UInt64)
    elseif tmout_ms > 0
        now = ccall((:g_source_get_time, GLib.libglib), UInt64, (Ptr{Nothing},), src)
        expiration = convert(UInt64, now + tmout_ms * 1000)
    else #tmout_ms == 0
        expiration = UInt64(0)
    end
    Int32(tmout_ms == 0)
end
function uv_check(src::Ptr{Nothing})
    global expiration
    ex = expiration::UInt64
    if !_isempty_workqueue()
        return Int32(1)
    elseif !uv_loop_alive(Base.eventloop())
        return Int32(0)
    elseif ex == 0
        return Int32(1)
    elseif uv_pollfd.revents != 0
        return Int32(1)
    else
        now = ccall((:g_source_get_time, GLib.libglib), UInt64, (Ptr{Nothing},), src)
        return Int32(ex <= now)
    end
end
function uv_dispatch(src::Ptr{Nothing}, callback::Ptr{Nothing}, data::T) where T
    return ccall(callback, Cint, (T,), data)
end

sizeof_gclosure = 0
function __init__gtype__()
    ccall((:g_type_init, libgobject), Nothing, ())
    global jlref_quark = quark"julia_ref"
    global sizeof_gclosure = GLib.WORD_SIZE
    closure = C_NULL
    while closure == C_NULL
        sizeof_gclosure += GLib.WORD_SIZE
        closure = ccall((:g_closure_new_simple, libgobject), Ptr{Nothing}, (Int, Ptr{Nothing}), sizeof_gclosure, C_NULL)
    end
    ccall((:g_closure_sink, libgobject), Nothing, (Ptr{Nothing},), closure)
end

function __init__gmainloop__()
    global uv_sourcefuncs = _GSourceFuncs(
        @cfunction(uv_prepare, Cint, (Ptr{Nothing}, Ptr{Cint})),
        @cfunction(uv_check, Cint, (Ptr{Nothing},)),
        @cfunction(uv_dispatch, Cint, (Ptr{Nothing}, Ptr{Nothing}, Int)),
        C_NULL, C_NULL, C_NULL)
    src = new_gsource(uv_sourcefuncs)
    ccall((:g_source_set_can_recurse, GLib.libglib), Nothing, (Ptr{Nothing}, Cint), src, true)
    ccall((:g_source_set_name, GLib.libglib), Nothing, (Ptr{Nothing}, Ptr{UInt8}), src, "uv loop")
    ccall((:g_source_set_callback, GLib.libglib), Nothing, (Ptr{Nothing}, Ptr{Nothing}, UInt, Ptr{Nothing}),
        src, @cfunction(g_yield, Cint, (UInt,)), 1, C_NULL)

    uv_fd = Sys.iswindows() ? -1 : ccall(:uv_backend_fd, Cint, (Ptr{Nothing},), Base.eventloop())
    global uv_pollfd = _GPollFD(uv_fd, typemax(Cushort))
    if (uv_pollfd::_GPollFD).fd != -1
        ccall((:g_source_add_poll, GLib.libglib), Nothing, (Ptr{Nothing}, Ptr{_GPollFD}), src, Ref(uv_pollfd::_GPollFD))
    end

    ccall((:g_source_attach, GLib.libglib), Cuint, (Ptr{Nothing}, Ptr{Nothing}), src, C_NULL)
    ccall((:g_source_unref, GLib.libglib), Nothing, (Ptr{Nothing},), src)
    nothing
end

function g_timeout_add(interval::Integer, cb::Function, user_data::CT) where CT

    callback = @cfunction($cb, Cint, (Ref{CT},) )
    ref, deref = gc_ref_closure(user_data)
    
    return ccall((:g_timeout_add_full, libglib), Cint,
        (Cint, UInt32, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}),
        0, UInt32(interval), callback, ref, deref)
end

function g_idle_add(cb::Function, user_data::CT) where CT

    callback = @cfunction($cb, Cint, (Ref{CT},) )
    ref, deref = gc_ref_closure(user_data)

    return ccall((:g_idle_add_full , libglib),Cint,
        (Cint, Ptr{Nothing}, Ptr{Nothing}, Ptr{Nothing}),
        0, callback, ref, deref)
end

const exiting = Ref(false)
function __init__()
    if isdefined(GLib, :__init__bindeps__)
        GLib.__init__bindeps__()
    end
    global JuliaClosureMarshal = @cfunction(GClosureMarshal, Nothing,
        (Ptr{Nothing}, Ptr{GValue}, Cuint, Ptr{GValue}, Ptr{Nothing}, Ptr{Nothing}))
    exiting[] = false
    atexit(() -> (exiting[] = true))
    __init__gtype__()
    __init__gmainloop__()
    nothing
end
