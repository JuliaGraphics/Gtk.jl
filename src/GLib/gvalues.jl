### Getting and Setting Properties

immutable GValue
    g_type::GType
    field2::Uint64
    field3::Uint64
    GValue() = new(0,0,0)
end
typealias GV Union(Mutable{GValue}, Ptr{GValue})
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
    bool(ccall((:g_value_transform,libgobject),Cint,(Ptr{GValue},Ptr{GValue}),src,dest))
    src
end

setindex!(::Type{Void},v::GV) = v
setindex!(v::GLib.GV, x) = setindex!(v, x, typeof(x))
setindex!(gv::GV, x, i::Int) = setindex!(mutable(gv,i), x)

getindex{T}(gv::GV, i::Int, ::Type{T}) = getindex(mutable(gv,i), T)
getindex(gv::GV, i::Int) = getindex(mutable(gv,i))
getindex(v::GV,i::Int, ::Type{Void}) = nothing

#let
#global make_gvalue, getindex
function make_gvalue(pass_x,as_ctype,to_gtype,with_id,allow_reverse::Bool=true,fundamental::Bool=false)
    with_id === :error && return
    if isa(with_id,Tuple)
        with_id = with_id::(Symbol,Any)
        with_id = :(ccall($(Expr(:tuple, Meta.quot(symbol(string(with_id[1],"_get_type"))), with_id[2])),GType,()))
    end
    if pass_x !== None
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
    if pass_x !== None
        eval(current_module(),quote
            function Base.getindex{T<:$pass_x}(v::GLib.GV,::Type{T})
                x = ccall(($(string("g_value_get_",to_gtype)),GLib.libgobject),$as_ctype,(Ptr{GLib.GValue},), v)
                $(  if to_gtype == :string
                        :(x = GLib.bytestring(x))
                    elseif pass_x == Symbol
                        :(x = symbol(x))
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
                $(if pass_x !== None
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
const gvalue_types = {}
const fundamental_fns = tuple(Function[make_gvalue(juliatype, ctype, g_value_fn, fundamental_ids[i], false, true) for
    (i,(name, ctype, juliatype, g_value_fn)) in enumerate(fundamental_types)]...)
make_gvalue(Symbol, Ptr{Uint8}, :static_string, :(g_type(String)), false)
make_gvalue(Type, GType, :gtype, (:g_gtype,:libgobject))

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

function getproperty{T}(w::GObject, name::StringLike, ::Type{T})
    v = gvalue(T)
    ccall((:g_object_get_property,libgobject), Void,
        (Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, bytestring(name), v)
    val = v[T]
    ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},), v)
    return val
end


setproperty!{T}(w::GObject, name::StringLike, ::Type{T}, value) = setproperty!(w, name, convert(T,value))
function setproperty!(w::GObject, name::StringLike, value)
    ccall((:g_object_set_property, libgobject), Void,
        (Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, bytestring(name), gvalue(value))
    w
end

@deprecate getindex(w::GObject, name::StringLike, T::Type) getproperty(w,name,T)
@deprecate setindex!(w::GObject, value, name::StringLike, T::Type) setproperty!(w,name,T,value)
@deprecate setindex!(w::GObject, value, name::StringLike) setproperty!(w,name,value)


function show(io::IO, w::GObject)
    print(io,typeof(w),'(')
    if convert(Ptr{GObject},w) == C_NULL
        print(io,"<NULL>)")
        return
    end
    n = mutable(Cuint)
    props = ccall((:g_object_class_list_properties,libgobject),Ptr{Ptr{GParamSpec}},
        (Ptr{Void},Ptr{Cuint}),G_OBJECT_GET_CLASS(w),n)
    v = gvalue(ByteString)
    for i = 1:unsafe_load(n)
        param = unsafe_load(unsafe_load(props,i))
        print(io,bytestring(param.name))
        const READABLE=1
        if (param.flags&1)==READABLE &&
                bool(ccall((:g_value_type_transformable,libgobject),Cint,
                (Int,Int),param.value_type,g_type(String)))
            ccall((:g_object_get_property,libgobject), Void,
                (Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, param.name, v)
            str = ccall((:g_value_get_string,libgobject),Ptr{Uint8},(Ptr{GValue},), v)
            value = (str == C_NULL ? "NULL" : bytestring(str))
            if param.value_type == g_type(String) && str != C_NULL
                print(io,"=\"",value,'"')
            else
                print(io,'=',value)
            end
        end
        if i != n
            print(io,", ")
        end
    end
    print(io,')')
    ccall((:g_value_unset,libgobject),Ptr{Void},(Ptr{GValue},), v)
end

#immutable GTypeQuery
#  g_type::Int
#  type_name::Ptr{Uint8}
#  class_size::Cuint
#  instance_size::Cuint
#  GTypeQuery() = new(0,0,0,0)
#end
#function gsizeof(gtyp)
#    q = mutable(GTypeQuery)
#    ccall((:g_type_query,libgobject),Void,(Int,Ptr{GTypeQuery},),gtyp,q)
#    q[].instance_size
#end
