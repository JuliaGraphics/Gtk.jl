module GLib

import Base: convert, show, showall, showcompact, size, length, getindex, setindex!,
             start, next, done, eltype

export GObject, GType, @Gtype, @Gabstract
export Enum, GError, GValue, gvalue, make_gvalue, g_type
export GList, glist_iter, _GSList, _GList, gc_ref, gc_unref, gc_move_ref, gc_ref_closure
export signal_connect, signal_emit, signal_handler_disconnect
export signal_handler_block, signal_handler_unblock
export setproperty!, getproperty
export GConnectFlags

include(joinpath("..","..","deps","ext_glib.jl"))

# local function, handles Symbol and makes UTF8-strings easier
typealias StringLike Union(String,Symbol)
bytestring(s) = Base.bytestring(s)
bytestring(s::Symbol) = s
bytestring(s::Ptr{Uint8},own::Bool) = UTF8String(pointer_to_array(s,int(ccall(:strlen,Csize_t,(Ptr{Uint8},),s)),own))

function concrete_subtypes(T::DataType...)
    queue = [T...]
    subt = Set{DataType}()
    while !isempty(queue)
        x = pop!(queue)
        if isa(x,DataType)
            if x.abstract
                for s in Base.subtypes(x)
                    push!(queue, s)
                end
            else
                push!(subt, x)
            end
        end
    end
    return subt
end

ccall((:g_type_init,libgobject),Void,())

include("MutableTypes.jl")
using .MutableTypes
include("Interfaces.jl")
using .Interfaces
include("glist.jl")
include("gtype.jl")
include("gvalues.jl")
include("gerror.jl")
include("signals.jl")

end
