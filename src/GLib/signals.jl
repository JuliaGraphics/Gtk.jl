sizeof_gclosure = 0
function init()
    global sizeof_gclosure = WORD_SIZE
    closure = C_NULL
    while closure == C_NULL
        sizeof_gclosure += WORD_SIZE
        closure = ccall((:g_closure_new_simple,libgobject),Ptr{Void},(Int,Ptr{Void}),sizeof_gclosure,C_NULL)
    end
    ccall((:g_closure_sink,libgobject),Void,(Ptr{Void},),closure)
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
