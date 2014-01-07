module GLib
import Base: convert, show, showall, showcompact, size, length, getindex, setindex!,
             start, next, done, eltype
export GObject, GObjectI, GType, @Gtype, @Gabstract
export Enum, GError, GValue, gvalue, make_gvalue
export GSList, gslist, gslist2, gc_ref, gc_unref, gc_ref_closure
export signal_connect, signal_emit, signal_handler_disconnect
export signal_handler_block, signal_handler_unblock
export GConnectFlags
include(joinpath("..","..","deps","ext_glib.jl"))

# local function, handles Symbol and makes UTF8-strings easier
bytestring(s) = Base.bytestring(s)
bytestring(s::Symbol) = s
bytestring(s::Ptr{Uint8},own::Bool) = UTF8String(pointer_to_array(s,int(ccall(:strlen,Csize_t,(Ptr{Uint8},),s)),own))

ccall((:g_type_init,libgobject),Void,())
include("MutableTypes.jl")
using .MutableTypes
include("gslist.jl")
include("gtype.jl")
include("gvalues.jl")
include("gerror.jl")
include("signals.jl")
init()
end

