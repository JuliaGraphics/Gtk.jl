### Getting and Setting Properties

immutable GValue
    g_type::GType
    field2::UInt64
    field3::UInt64
    GValue() = new(0,0,0)
end
typealias GV Union{Mutable{GValue}, Ptr{GValue}}
Base.zero(::Type{GValue}) = GValue()
function gvalue{T}(::Type{T})
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
    for (i,x) in enumerate(xs)
        T = typeof(x)
        gv = mutable(v,i)
        gv[] = T  # init type
        gv[T] = x # init value
    end
    finalizer(v, (v)->for i = 1:length(v)
            ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},),pointer(v,i))
        end)
    v
end

function setindex!(dest::GV, src::GV)
    ccall((:g_value_transform,libgobject),Cint,(Ptr{GValue},Ptr{GValue}),src,dest) != 0
    src
end

setindex!(::Type{Void},v::GV) = v
setindex!(v::GLib.GV, x) = setindex!(v, x, typeof(x))
setindex!(gv::GV, x, i::Int) = setindex!(mutable(gv,i), x)

getindex{T}(gv::GV, i::Int, ::Type{T}) = getindex(mutable(gv,i), T)
getindex(gv::GV, i::Int) = getindex(mutable(gv,i))
getindex(v::GV,i::Int, ::Type{Void}) = nothing

let handled=Set()
global make_gvalue, getindex
function make_gvalue(pass_x,as_ctype,to_gtype,with_id,allow_reverse::Bool=true,fundamental::Bool=false)
    with_id === :error && return
    if isa(with_id,Tuple)
        with_id = with_id::TupleType(Symbol,Any)
        with_id = :(ccall($(Expr(:tuple, Meta.quot(Symbol(string(with_id[1],"_get_type"))), with_id[2])),GType,()))
    end
    if pass_x !== Union{} && !(pass_x in handled)
        eval(current_module(),quote
            function Base.setindex!{T<:$pass_x}(v::GLib.GV, ::Type{T})
                ccall((:g_value_init,GLib.libgobject),Void,(Ptr{GLib.GValue},Csize_t), v, $with_id)
                v
            end
            function Base.setindex!{T<:$pass_x}(v::GLib.GV, x, ::Type{T})
                $(  if to_gtype == :string
                        :(x = GLib.bytestring(x))
                    elseif to_gtype == :pointer || to_gtype == :boxed
                        :(x = GLib.mutable(x))
                    elseif to_gtype == :gtype
                        :(x = GLib.g_type(x))
                    end)
                ccall(($(string("g_value_set_",to_gtype)),GLib.libgobject),Void,(Ptr{GLib.GValue},$as_ctype), v, x)
                if isa(v, GLib.MutableTypes.MutableX)
                    finalizer(v, (v::GLib.MutableTypes.MutableX)->ccall((:g_value_unset,GLib.libgobject),Void,(Ptr{GLib.GValue},), v))
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
        eval(current_module(),quote
            function Base.getindex{T<:$pass_x}(v::GLib.GV,::Type{T})
                x = ccall(($(string("g_value_get_",to_gtype)),GLib.libgobject),$as_ctype,(Ptr{GLib.GValue},), v)
                $(  if to_gtype == :string
                        :(x = GLib.bytestring(x))
                    elseif pass_x == Symbol
                        :(x = Symbol(x))
                    end)
                return Base.convert(T,x)
            end
        end)
    end
    if fundamental || allow_reverse
        fn = eval(current_module(),quote
            function(v::GLib.GV)
                x = ccall(($(string("g_value_get_",to_gtype)),GLib.libgobject),$as_ctype,(Ptr{GLib.GValue},), v)
                $(if to_gtype == :string; :(x = GLib.bytestring(x)) end)
                $(if pass_x !== Union{}
                    :(return Base.convert($pass_x,x))
                else
                    :(return x)
                end)
            end
        end)
        allow_reverse && unshift!(gvalue_types, [pass_x, eval(current_module(),:(()->$with_id)), fn])
        return fn
    end
    return nothing
end
end #let

const gvalue_types = Any[]
const fundamental_fns = tuple(Function[begin
        (name, ctype, juliatype, g_value_fn) = fundamental_types[i]
        make_gvalue(juliatype, ctype, g_value_fn, fundamental_ids[i], false, true)
    end for i in 1:length(fundamental_types)]...)
make_gvalue(Symbol, Ptr{UInt8}, :static_string, :(g_type(AbstractString)), false)
make_gvalue(Type, GType, :gtype, (:g_gtype,:libgobject))
make_gvalue(Ptr{GBoxed}, Ptr{GBoxed}, :gboxed, :(g_type(GBoxed)), false)

function getindex(gv::GV, ::Type{Any})
    gtyp = unsafe_load(gv).g_type
    if gtyp == 0
        error("Invalid GValue type")
    end
    if gtyp == g_type(Void)
        return nothing
    end
    # first pass: fast loop for fundamental types
    for (i,id) in enumerate(fundamental_ids)
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
    for (i,id) in enumerate(fundamental_ids)
        if g_isa(gtyp,id)
            return fundamental_fns[i](gv)
        end
    end
    typename = g_type_name(gtyp)
    error("Could not convert GValue of type $typename to Julia type")
end
#end

function getproperty{T}(w::GObject, name::AbstractStringLike, ::Type{T})
    v = gvalue(T)
    ccall((:g_object_get_property,libgobject), Void,
        (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, GLib.bytestring(name), v)
    val = v[T]
    ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},), v)
    return val
end

setproperty!{T}(w::GObject, name::AbstractStringLike, ::Type{T}, value) = setproperty!(w, name, convert(T,value))
function setproperty!(w::GObject, name::AbstractStringLike, value)
    ccall((:g_object_set_property, libgobject), Void,
        (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, GLib.bytestring(name), gvalue(value))
    w
end

@deprecate getindex(w::GObject, name::AbstractStringLike, T::Type) getproperty(w,name,T)
@deprecate setindex!(w::GObject, value, name::AbstractStringLike, T::Type) setproperty!(w,name,T,value)
@deprecate setindex!(w::GObject, value, name::AbstractStringLike) setproperty!(w,name,value)


function show(io::IO, w::GObject)
    const READABLE   = 0x00000001
    const DEPRECATED = 0x80000000
    print(io,typeof(w),'(')
    if unsafe_convert(Ptr{GObject},w) == C_NULL
        print(io,"<NULL>)")
        return
    end
    n = mutable(Cuint)
    props = ccall((:g_object_class_list_properties,libgobject),Ptr{Ptr{GParamSpec}},
        (Ptr{Void},Ptr{Cuint}),G_OBJECT_GET_CLASS(w),n)
    v = gvalue(String)
    first = true
    for i = 1:unsafe_load(n)
        param = unsafe_load(unsafe_load(props,i))
        if !first
            print(io,", ")
        else
            first = false
        end
        print(io,GLib.bytestring(param.name))
        if (param.flags & READABLE) != 0 &&
           (param.flags & DEPRECATED) == 0 &&
           (ccall((:g_value_type_transformable,libgobject),Cint,
                (Int,Int),param.value_type,g_type(AbstractString)) != 0)
            ccall((:g_object_get_property,libgobject), Void,
                (Ptr{GObject}, Ptr{UInt8}, Ptr{GValue}), w, param.name, v)
            str = ccall((:g_value_get_string,libgobject),Ptr{UInt8},(Ptr{GValue},), v)
            value = (str == C_NULL ? "NULL" : GLib.bytestring(str))
            if param.value_type == g_type(AbstractString) && str != C_NULL
                print(io,"=\"",value,'"')
            else
                print(io,'=',value)
            end
        end
    end
    print(io,')')
    ccall((:g_value_unset,libgobject),Ptr{Void},(Ptr{GValue},), v)
end

#immutable GTypeQuery
#  g_type::Int
#  type_name::Ptr{UInt8}
#  class_size::Cuint
#  instance_size::Cuint
#  GTypeQuery() = new(0,0,0,0)
#end
#function gsizeof(gtyp)
#    q = mutable(GTypeQuery)
#    ccall((:g_type_query,libgobject),Void,(Int,Ptr{GTypeQuery},),gtyp,q)
#    q[].instance_size
#end
