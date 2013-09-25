### Getting and Setting Properties
const gchararray_id = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),"gchararray")
const gdouble_id = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),"gdouble")
const gint64_id = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),"gint64")
const guint64_id = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),"guint64")
const gboolean_id = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),"gboolean")

GValue() = zeros(Int64,3)
function GValue(::Type{ByteString})
    v = GValue()
    ccall((:g_value_init,libgobject),Void,(Ptr{Void},Int), v, gchararray_id)
    v
end
function GValue(::Type{Uint64})
    v = GValue()
    ccall((:g_value_init,libgobject),Void,(Ptr{Void},Int), v, guint64_id)
    v
end
function GValue(::Type{Int64})
    v = GValue()
    ccall((:g_value_init,libgobject),Void,(Ptr{Void},Int), v, gint64_id)
    v
end
function GValue(::Type{Float64})
    v = GValue()
    ccall((:g_value_init,libgobject),Void,(Ptr{Void},Int), v, gdouble_id)
    v
end
function GValue(::Type{Bool})
    v = GValue()
    ccall((:g_value_init,libgobject),Void,(Ptr{Void},Int), v, gboolean_id)
    v
end

function GValue(s::String)
    v = GValue(ByteString)
    ccall((:g_value_set_string,libgobject),Void,(Ptr{Void},Ptr{Uint8}), v, bytestring(s))
    v
end
function GValue(s::Symbol)
    v = GValue(ByteString)
    ccall((:g_value_set_static_string,libgobject),Void,(Ptr{Void},Ptr{Uint8}), v, s)
    v
end
function GValue(i::Unsigned)
    v = GValue(Uint64)
    ccall((:g_value_set_uint64,libgobject),Void,(Ptr{Void},Uint64), v, i)
    v
end
function GValue(i::Signed)
    v = GValue(Int64)
    ccall((:g_value_set_int64,libgobject),Void,(Ptr{Void},Int64), v, i)
    v
end
function GValue(i::FloatingPoint)
    v = GValue(Float64)
    ccall((:g_value_set_double,libgobject),Void,(Ptr{Void},Cdouble), v, i)
    v
end
function GValue(i::Bool)
    v = GValue(Bool)
    ccall((:g_value_set_boolean,libgobject),Void,(Ptr{Void},Cint), v, i)
    v
end

setindex!(w::GtkWidget, value, name) = setindex!(w, value, bytestring(name))
setindex!{T}(w::GtkWidget, value, name, ::Type{T}) = setindex!(w, convert(T,value), name)
function setindex!(w::GtkWidget, value, name::Union(ByteString,Symbol))
    v = GValue(value)
    ccall((:g_object_set_property, libgobject), Void, 
        (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, name, v)
    ccall((:g_value_unset,libgobject),Void,(Ptr{Void},),v)
    w
end

getindex{T}(w::GtkWidget, name, ::Type{T}) = getindex(w, bytestring(name), T)
function getindex{T<:String}(w::GtkWidget, name::Union(ByteString,Symbol), ::Type{T})
    v = GValue(ByteString)
    ccall((:g_object_get_property,libgobject), Void,
        (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, name, v)
    str = convert(T,bytestring(ccall((:g_value_get_string,libgobject),Ptr{Uint8},(Ptr{Void},),v)))
    ccall((:g_value_unset,libgobject),Void,(Ptr{Void},),v)
    return str
end
function getindex{T<:Signed}(w::GtkWidget, name::Union(ByteString,Symbol), ::Type{T})
    v = GValue(Int64)
    ccall((:g_object_get_property,libgobject), Void,
        (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, name, v)
    i = convert(T,ccall((:g_value_get_int64,libgobject),Int64,(Ptr{Void},),v))
    ccall((:g_value_unset,libgobject),Void,(Ptr{Void},),v)
    return i
end
function getindex{T<:Unsigned}(w::GtkWidget, name::Union(ByteString,Symbol), ::Type{T})
    v = GValue(Uint64)
    ccall((:g_object_get_property,libgobject), Void,
        (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, name, v)
    i = convert(T,ccall((:g_value_get_uint64,libgobject),Uint64,(Ptr{Void},),v))
    ccall((:g_value_unset,libgobject),Void,(Ptr{Void},),v)
    return i
end
function getindex{T<:FloatingPoint}(w::GtkWidget, name::Union(ByteString,Symbol), ::Type{T})
    v = GValue(Float64)
    ccall((:g_object_get_property,libgobject), Void,
        (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, name, v)
    i = convert(T,ccall((:g_value_get_double,libgobject),Float64,(Ptr{Void},),v))
    ccall((:g_value_unset,libgobject),Void,(Ptr{Void},),v)
    return i
end
function getindex(w::GtkWidget, name::Union(ByteString,Symbol), ::Type{Bool})
    v = GValue(Bool)
    ccall((:g_object_get_property,libgobject), Void,
        (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, name, v)
    i = bool(ccall((:g_value_get_boolean,libgobject),Cint,(Ptr{Void},),v))
    ccall((:g_value_unset,libgobject),Void,(Ptr{Void},),v)
    return i
end
getindex{T}(w::GtkWidget, name::Union(ByteString,Symbol), ::Type{T}) = error("don't know how to represent gproperty of type $T in Julia")

#function setindex!{T<:Number}(w::GtkWidget, value, name::StringLike, ::Type{T})
#    ccall((:g_object_set, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},T,Ptr{Void}...), w, name, value, C_NULL)
#end
#function setindex!{T<:String}(w::GtkWidget, value, name::StringLike, ::Type{T})
#    ccall((:g_object_set, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},Ptr{Uint8},Ptr{Void}...), w, name, gc_ref(bytestring(value)), C_NULL) #TODO: is the gc root necessary?
#end
#function setindex!{T<:GtkWidget}(w::GtkWidget, value, name::StringLike, ::Type{T})
#    ccall((:g_object_set, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},Ptr{T},Ptr{Void}...), w, name, value, C_NULL)
#end
#function getindex{T<:Number}(w::GtkWidget, name::StringLike, ::Type{T})
#    value = Array(T, 1)
#    ccall((:g_object_get, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},Ptr{T},Ptr{Void}...), w, name, value, C_NULL)
#    value[1]
#end
#function getindex{T<:String}(w::GtkWidget, name::StringLike, ::Type{T})
#    value = Array(Ptr{Uint8}, 1)
#    ccall((:g_object_get, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},Ptr{Ptr{Uint8}},Ptr{Void}...), w, name, value, C_NULL)
#    s = bytestring(value[1])
#    ccall((:g_free, libglib), Void, (Ptr{Void},), value[1])
#    s
#end
#function getindex{T<:GtkWidget}(w::GtkWidget, name::StringLike, ::Type{T})
#    value = Array(Ptr{GtkWidget}, 1)
#    ccall((:g_object_get, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},Ptr{Ptr{T}},Ptr{Void}...), w, name, value, C_NULL)
#    gc_ref(value[1])
#    ccall((:g_object_unref, libglib), Void, (Ptr{Void},), value[1])
#    convert(GtkWidget, value[1])::T
#end

immutable GParamSpec
  g_type_instance::Ptr{Void}
  name::Ptr{Uint8}
  flags::Cint
  value_type::Csize_t
  owner_type::Csize_t
end

function show(io::IO, w::GtkWidget)
    print(io,typeof(w),'(')
    clss = unsafe_load(convert(Ptr{Ptr{Void}},w.handle))
    n = Array(Cuint,1)
    props = ccall((:g_object_class_list_properties,libgobject),Ptr{Ptr{GParamSpec}},
        (Ptr{Void},Ptr{Cuint}),clss,n)
    v = GValue(ByteString)
    for i = 1:n[1]
        param = unsafe_load(unsafe_load(props,i))
        print(io,bytestring(param.name))
        const READABLE=1
        if (param.flags&1)==READABLE &&
                bool(ccall((:g_value_type_transformable,libgobject),Cint,
                (Int,Int),param.value_type,gchararray_id))
            ccall((:g_object_get_property,libgobject), Void,
                (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, param.name, v)
            str = ccall((:g_value_get_string,libgobject),Ptr{Uint8},(Ptr{Void},),v)
            value = (str == C_NULL ? "NULL" : bytestring(str))
            ccall((:g_value_reset,libgobject),Ptr{Void},(Ptr{Void},), v)
            if param.value_type == gchararray_id && str != C_NULL
                print(io,"=\"",value,'"')
            else
                print(io,'=',value)
            end
        end
        if i != n
            print(io,", ")
        end
    end
    print(')')
    ccall((:g_value_unset,libgobject),Ptr{Void},(Ptr{Void},), v)
end
