module GLib
import Base: convert, show, showall, showcompact, run, size, length, getindex, setindex!,
             insert!, push!, unshift!, shift!, pop!, splice!, delete!,
             start, next, done, parent, isempty, empty!, first, last, in,
             eltype, copy
import Base.Graphics: width, height, getgc
export GObject, GObjectI, GType, @Gtype, @Gabstract, make_gvalue
export Enum, GError, GValue, gvalue
export GSList, gslist,gslist2, gc_ref, gc_ref_closure
export signal_connect, signal_emit, signal_handler_disconnect
export signal_handler_block, signal_handler_unblock
export bytestring, GConnectFlags
include(joinpath("..","deps","ext.jl"))
bytestring(s) = Base.bytestring(s)
bytestring(s::Symbol) = s
bytestring(s::Ptr{Uint8},own::Bool) = UTF8String(pointer_to_array(s,int(ccall(:strlen,Csize_t,(Ptr{Uint8},),s)),own))

ccall((:g_type_init,libgobject),Void,())
include("MutableTypes.jl")
using MutableTypes
include("gslist.jl")
include("gtype.jl")
include("gvalues.jl")
include("gerror.jl")
include("signals.jl")
sizeof_gclosure = 0
init()
end

