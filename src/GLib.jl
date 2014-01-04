module GLib
import Base: convert, show, showall, showcompact, run, size, length, getindex, setindex!,
             insert!, push!, unshift!, shift!, pop!, splice!, delete!,
             start, next, done, parent, isempty, empty!, first, last, in,
             eltype, copy
import Base.Graphics: width, height, getgc
export GObject, GObjectI, GType, @GType, make_gvalue
export Enum, GError, GValue, gvalue
export GSList, gslist,gslist2, gc_ref, gc_ref_closure
export signal_connect, signal_emit
export bytestring, GConnectFlags
include(joinpath("..","deps","ext.jl"))
bytestring(s) = Base.bytestring(s)
bytestring(s::Symbol) = s
bytestring(s::Ptr{Uint8},own::Bool) = UTF8String(pointer_to_array(s,int(ccall(:strlen,Csize_t,(Ptr{Uint8},),s)),own))

ccall((:g_type_init,libgobject),Void,())
include("MutableTypes.jl")
using MutableTypes
include("gslist.jl")
include("gobject.jl")
include("gvalues.jl")
include("gerror.jl")
include("signals.jl")
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
init()
end

