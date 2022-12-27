### Getting and Setting Properties

struct GValue
    g_type::GType
    field2::UInt64
    field3::UInt64
    GValue() = new(0, 0, 0)
end
const GV = Union{Mutable{GValue}, Ptr{GValue}}
Base.zero(::Type{GValue}) = GValue()
function gvalue(::Type{T}) where T
    v = mutable(GValue())
    v[] = T
    v
end
function gvalue(x)
    T = typeof(x)
    v = gvalue(T)
    v[T] = x
    v
end
function gvalues(xs...)
    v = zeros(GValue, length(xs))
    for (i, x) in enumerate(xs)
        T = typeof(x)
        gv = mutable(v, i)
        gv[] = T  # init type
        gv[T] = x # init value
    end
    finalizer((v) -> for i = 1:length(v)
            ccall((:g_value_unset, libgobject), Nothing, (Ptr{GValue},), pointer(v, i))
        end, v)
    v
end

function setindex!(dest::GV, src::GV)
    ccall((:g_value_transform, libgobject), Cint, (Ptr{GValue}, Ptr{GValue}), src, dest) != 0
    src
end

setindex!(::Type{Nothing}, v::GV) = v
setindex!(v::GLib.GV, x) = setindex!(v, x, typeof(x))
setindex!(gv::GV, x, i::Int) = setindex!(mutable(gv, i), x)

getindex(gv::GV, i::Int, ::Type{T}) where {T} = getindex(mutable(gv, i), T)
getindex(gv::GV, i::Int) = getindex(mutable(gv, i))
getindex(v::GV, i::Int, ::Type{Nothing}) = nothing

let handled = Set()
global make_gvalue, getindex
function make_gvalue(pass_x, as_ctype, to_gtype, with_id, cm::Module, allow_reverse::Bool = true, fundamental::Bool = false)
    with_id === :error && return
    if isa(with_id, Tuple)
        with_id = with_id::Tuple{Symbol, Any}
        with_id = :(ccall($(Expr(:tuple, Meta.quot(Symbol(string(with_id[1], "_get_type"))), with_id[2])), GType, ()))
    end
    if pass_x !== Union{} && !(pass_x in handled)
        Core.eval(cm, quote
            function Base.setindex!(v::GLib.GV, ::Type{T}) where T <: $pass_x
                ccall((:g_value_init, GLib.libgobject), Nothing, (Ptr{GLib.GValue}, Csize_t), v, $with_id)
                v
            end
            function Base.setindex!(v::GLib.GV, x, ::Type{T}) where T <: $pass_x
                $(  if to_gtype == :string
                        :(x = GLib.bytestring(x))
                    elseif to_gtype == :pointer || to_gtype == :boxed
                        :(x = GLib.mutable(x))
                    elseif to_gtype == :gtype
                        :(x = GLib.g_type(x))
                    end)
                ccall(($(string("g_value_set_", to_gtype)), GLib.libgobject), Nothing, (Ptr{GLib.GValue}, $as_ctype), v, x)
                if isa(v, GLib.MutableTypes.MutableX)
                    finalizer((v::GLib.MutableTypes.MutableX) -> ccall((:g_value_unset, GLib.libgobject), Nothing, (Ptr{GLib.GValue},), v), v)
                end
                v
            end
        end)
    end
    if to_gtype == :static_string
        to_gtype = :string
    end
    if pass_x !== Union{} && !(pass_x in handled)
        push!(handled, pass_x)
        Core.eval(cm, quote
            function Base.getindex(v::GLib.GV, ::Type{T}) where T <: $pass_x
                x = ccall(($(string("g_value_get_", to_gtype)), GLib.libgobject), $as_ctype, (Ptr{GLib.GValue},), v)
                $(  if to_gtype == :string
                        :(x = GLib.bytestring(x))
                    elseif pass_x == Symbol
                        :(x = Symbol(x))
                    end)
                return Base.convert(T, x)
            end
        end)
    end
    if fundamental || allow_reverse
        fn = Core.eval(cm, quote
            function(v::GLib.GV)
                x = ccall(($(string("g_value_get_", to_gtype)), GLib.libgobject), $as_ctype, (Ptr{GLib.GValue},), v)
                $(if to_gtype == :string; :(x = GLib.bytestring(x)) end)
                $(if pass_x !== Union{}
                    :(return Base.convert($pass_x, x))
                else
                    :(return x)
                end)
            end
        end)
        allow_reverse && pushfirst!(gvalue_types, [pass_x, Core.eval(cm, :(() -> $with_id)), fn])
        return fn
    end
    return nothing
end
end #let

macro make_gvalue(pass_x, as_ctype, to_gtype, with_id, opt...)
    esc(:(make_gvalue($pass_x, $as_ctype, $to_gtype, $with_id, $__module__, $(opt...))))
end

function make_gvalue_from_fundamental_type(i,cm)
  (name, ctype, juliatype, g_value_fn) = fundamental_types[i]
  return make_gvalue(juliatype, ctype, g_value_fn, fundamental_ids[i], cm, false, true)
end

const gvalue_types = Any[]
const fundamental_fns = tuple(Function[ make_gvalue_from_fundamental_type(i, @__MODULE__) for
                              i in 1:length(fundamental_types)]...)
@make_gvalue(Symbol, Ptr{UInt8}, :static_string, :(g_type(AbstractString)), false)
@make_gvalue(Type, GType, :gtype, (:g_gtype, :libgobject))
@make_gvalue(Ptr{GBoxed}, Ptr{GBoxed}, :gboxed, :(g_type(GBoxed)), false)

function getindex(gv::GV, ::Type{Any})
    gtyp = unsafe_load(gv).g_type
    if gtyp == 0
        error("Invalid GValue type")
    end
    if gtyp == g_type(Nothing)
        return nothing
    end
    # first pass: fast loop for fundamental types
    for (i, id) in enumerate(fundamental_ids)
        if id == gtyp  # if g_type == id
            return fundamental_fns[i](gv)
        end
    end
    # second pass: user defined (sub)types
    for (typ, typefn, getfn) in gvalue_types
        if g_isa(gtyp, typefn())
            return getfn(gv)
        end
    end
    # last pass: check for derived fundamental types (which have not been overridden by the user)
    for (i, id) in enumerate(fundamental_ids)
        if g_isa(gtyp, id)
            return fundamental_fns[i](gv)
        end
    end
    typename = g_type_name(gtyp)
    error("Could not convert GValue of type $typename to Julia type")
end
#end

get_gtk_property(w::GObject, name::AbstractString, ::Type{T}) where T = get_gtk_property(w, String(name)::String, T)
get_gtk_property(w::GObject, name::Symbol, ::Type{T}) where T = get_gtk_property(w, String(name), T)
function get_gtk_property(w::GObject, name::String, ::Type{T}) where T
    v = gvalue(T)
    ccall((:g_object_get_property, libgobject), Nothing,
        (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, name, v)
    val = v[T]
    ccall((:g_value_unset, libgobject), Nothing, (Ptr{GValue},), v)
    return val
end

set_gtk_property!(w::GObject, name, ::Type{T}, value) where T = set_gtk_property!(w, name, convert(T, value))
set_gtk_property!(w::GObject, name::AbstractString, value) = set_gtk_property!(w::GObject, String(name)::String, value)
set_gtk_property!(w::GObject, name::Symbol, value) = set_gtk_property!(w::GObject, String(name), value)
function set_gtk_property!(w::GObject, name::String, value)
    ccall((:g_object_set_property, libgobject), Nothing,
        (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, name, gvalue(value))

    w
end

struct FieldRef{T}
    obj::T
    field::Symbol

    global function getproperty(obj::T, field::Symbol) where {T <: GObject}
        isdefined(obj, field) && return getfield(obj, field)
        new{T}(obj, field)
    end

    FieldRef(obj::T, field::Symbol) where T = new{T}(obj, field)
end

getindex(f::FieldRef, ::Type{T}) where {T} = get_gtk_property(f.obj, f.field,T)

function setindex!(f::FieldRef, value::T, ::Type{T}) where {T}
    isdefined(f.obj,f.field) && return setfield!(f.obj, f.field, value)
    set_gtk_property!(f.obj, f.field, value)
    return f
end
setindex!(f::FieldRef, value::K, ::Type{T}) where {K, T} = setindex!(f, convert(T,value), T)

function show(io::IO, w::GObject)
    READABLE   = 0x00000001
    DEPRECATED = 0x80000000
    print(io, typeof(w), '(')
    if unsafe_convert(Ptr{GObject}, w) == C_NULL
        print(io, "<NULL>)")
        return
    end
    n = mutable(Cuint)
    props = ccall((:g_object_class_list_properties, libgobject), Ptr{Ptr{GParamSpec}},
        (Ptr{Nothing}, Ptr{Cuint}), G_OBJECT_GET_CLASS(w), n)
    v = gvalue(String)
    first = true
    for i = 1:unsafe_load(n)
        param = unsafe_load(unsafe_load(props, i))
        if !first
            print(io, ", ")
        else
            first = false
        end
        print(io, GLib.bytestring(param.name))
        if (param.flags & READABLE) != 0 &&
           (param.flags & DEPRECATED) == 0 &&
           (ccall((:g_value_type_transformable, libgobject), Cint,
                (Int, Int), param.value_type, g_type(AbstractString)) != 0)
            ccall((:g_object_get_property, libgobject), Nothing,
                (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, param.name, v)
            str = ccall((:g_value_get_string, libgobject), Ptr{UInt8}, (Ptr{GValue},), v)
            value = (str == C_NULL ? "NULL" : GLib.bytestring(str))
            if param.value_type == g_type(AbstractString) && str != C_NULL
                print(io, "=\"", value, '"')
            else
                print(io, '=', value)
            end
        end
    end
    print(io, ')')
    ccall((:g_value_unset, libgobject), Ptr{Nothing}, (Ptr{GValue},), v)
end

#immutable GTypeQuery
#  g_type::Int
#  type_name::Ptr{UInt8}
#  class_size::Cuint
#  instance_size::Cuint
#  GTypeQuery() = new(0, 0, 0, 0)
#end
#function gsizeof(gtyp)
#    q = mutable(GTypeQuery)
#    ccall((:g_type_query, libgobject), Nothing, (Int, Ptr{GTypeQuery},), gtyp, q)
#    q[].instance_size
#end
