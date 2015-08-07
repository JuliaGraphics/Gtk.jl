module GLib

if false
function include(x)
    println("including $x")
    @time Base.include(x)
end
end

import Base: convert, copy, show, showall, showcompact, size, length, getindex, setindex!, get,
             start, next, done, eltype, isempty, endof, ndims, stride, strides,
             empty!, append!, reverse!, unshift!, pop!, shift!, push!, splice!,
             sigatomic_begin, sigatomic_end

export GInterface, GType, GObject, GBoxed, @Gtype, @Gabstract, @Giface
export GEnum, GError, GValue, gvalue, make_gvalue, g_type
export GList, glist_iter, _GSList, _GList, gobject_ref, gobject_move_ref
export signal_connect, signal_emit, signal_handler_disconnect
export signal_handler_block, signal_handler_unblock
export setproperty!, getproperty
export GConnectFlags

module Compat
    export @assign_if_unassigned
    macro assign_if_unassigned(expr)
        # BinDeps often fails and generates corrupt deps.jl files
        # (https://github.com/JuliaLang/BinDeps.jl/issues/146),
        # but most of the time, we don't care
        @assert expr.head === :(=)
        left = expr.args[1]
        right = expr.args[2]
        quote
            if !isdefined(current_module(), $(QuoteNode(left)))
                global const $(esc(left)) = $(esc(right))
            end
        end
    end
    if VERSION >= v"0.4-"
        export TupleType, int, int8, int32, uint32, uint64, dlopen, dlsym_e, unsafe_convert
        TupleType(types...) = Tuple{types...}
        int(v) = Int(v)
        int8(v) = Int8(v)
        int32(v) = Int32(v)
        uint32(v) = UInt32(v)
        uint64(v) = UInt64(v)
        const unsafe_convert = Base.unsafe_convert
        import Base.Libdl: dlopen, dlsym_e
    else
        export TupleType, unsafe_convert
        const TupleType = tuple
        const unsafe_convert = Base.cconvert
    end
    if VERSION < v"0.3-"
        export QuoteNode
        QuoteNode(x) = Base.qn(x)
    end
end
importall .Compat

# local function, handles Symbol and makes UTF8-strings easier
typealias StringLike Union(String,Symbol)
bytestring(s) = Base.bytestring(s)
bytestring(s::Symbol) = s
bytestring(s::Ptr{Uint8},own::Bool) = UTF8String(pointer_to_array(s,int(ccall(:strlen,Csize_t,(Ptr{Uint8},),s)),own))

include(joinpath("..","..","deps","ext_glib.jl"))

ccall((:g_type_init,libgobject),Void,())

include("MutableTypes.jl")
using .MutableTypes
include("glist.jl")
include("gtype.jl")
include("gvalues.jl")
include("gerror.jl")
include("signals.jl")

export @g_type_delegate
macro g_type_delegate(eq)
    @assert isa(eq,Expr) && eq.head == :(=) && length(eq.args) == 2
    new = eq.args[1]
    real = eq.args[2]
    newleaf = esc(symbol(string(new,current_module().suffix)))
    realleaf = esc(symbol(string(real,current_module().suffix)))
    new = esc(new)
    macroreal = QuoteNode(symbol(string('@',real)))
    quote
        const $newleaf = $realleaf
        macro $new(args...)
            Expr(:macrocall, $macroreal, map(esc,args)...)
        end
    end
end

end
