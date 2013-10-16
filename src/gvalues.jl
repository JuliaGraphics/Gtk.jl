### Getting and Setting Properties

g_type_from_name(name::String) = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),name)
# NOTE: in general you should not cache these, except for built-in values, like these
const gvoid_id = g_type_from_name("void")
const gstring_id = g_type_from_name("gchararray")
const gdouble_id = g_type_from_name("gdouble")
const gint64_id = g_type_from_name("gint64")
const guint64_id = g_type_from_name("guint64")
const gboolean_id = g_type_from_name("gboolean")
const gobject_id = g_type_from_name("GObject")

immutable GValue
    field1::Csize_t
    field2::Uint64
    field3::Uint64
    GValue() = new(0,0,0)
end
Base.zero(::Type{GValue}) = GValue()
type GValue1
    v::GValue
    GValue1() = new(GValue())
end
function gvalues(xs...)
    v = zeros(GValue, length(xs))
    for (i,x) in enumerate(xs)
        gvalue(typeof(x), v, i)
        gvalue(x, v, i)
    end
    v
end
getindex{T}(gv::GValue1,::Type{T}) = getindex(gv,1,T)

gvalue(::Type{Void},vargs...) = GValue1()
getindex(v::GValue1,i,::Type{Void}) = nothing
getindex(v::Vector{GValue1},i,::Type{Void}) = nothing

for (pass_x,as_ctype,to_gtype,with_id) in (
    (String,          Ptr{Uint8},      :string,          :gstring_id),
    (Symbol,          Ptr{Uint8},      :static_string,   :gstring_id),
    (Unsigned,        Uint64,          :uint64,          :guint64_id),
    (Signed,          Int64,           :int64,           :gint64_id),
    (FloatingPoint,   Float64,         :double,          :gdouble_id),
    (Bool,            Cint,            :boolean,         :gboolean_id),
    (GtkObject,       Ptr{GtkObject},  :object,          :gobject_id),
    )
   eval(quote
        # Since we aren't creating a GValue type, everything is done through the methods and the Array type
        # with minimal support from the Julia type system
        function gvalue{T<:$pass_x}(::Type{T}, v=GValue1(), i=1)
            if isa(v,GValue1)
                i == 1 || error("GValue1 only has one element")
                ccall((:g_value_init,libgobject),Void,(Ptr{GValue1},Csize_t), &v, $with_id)
            else
                isa(v, Vector{GValue}) && 1 <= i <= length(v) || error("Invalid array specifications for GValue")
                ccall((:g_value_init,libgobject),Void,(Ptr{GValue},Csize_t), pointer(v,i), $with_id)
            end
            v
        end
        function gvalue{T<:$pass_x}(x::T, v=gvalue(T), i=1)
            $(if to_gtype == :string; :(x = bytestring(x)) end)
            if isa(v,GValue1)
                i == 1 || error("GValue1 only has one element")
                ccall(($(string("g_value_set_",to_gtype)),libgobject),Void,(Ptr{GValue1},$as_ctype), &v, x)
            else
                isa(v, Vector{GValue}) && 1 <= i <= length(v) || error("Invalid array specifications for GValue")
                ccall(($(string("g_value_set_",to_gtype)),libgobject),Void,(Ptr{GValue},$as_ctype), pointer(v,i), x)
            end
            v
        end
        $(if to_gtype == :static_string; to_gtype = :string; nothing end)
        function getindex{T<:$pass_x}(v::GValue1,i,::Type{T})
            i == 1 || error("GValue1 only has one element")
            x = ccall(($(string("g_value_get_",to_gtype)),libgobject),$as_ctype,(Ptr{GValue1},),&v)
            $(if to_gtype == :string; :(x = bytestring(x)) end)
            $(if pass_x == Symbol; :(x = symbol(x)) end)
            ccall((:g_value_unset,libgobject),Void,(Ptr{GValue1},),&v)
            return convert(T,x)
        end
        function getindex{T<:$pass_x}(v::Vector{GValue},i::Int,::Type{T})
            1 <= i <= length(v) || error("Invalid array specifications for GValue")
            x = ccall(($(string("g_value_get_",to_gtype)),libgobject),$as_ctype,(Ptr{GValue},),pointer(v,i))
            $(if to_gtype == :string; :(x = bytestring(x)) end)
            $(if pass_x == Symbol; :(x = symbol(x)) end)
            ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},),pointer(v,i))
            return convert(T,x)
        end
    end)
end

function getindex{T}(w::GtkObject, name::Union(String,Symbol), ::Type{T})
    v = gvalue(T)
    ccall((:g_object_get_property,libgobject), Void,
        (Ptr{GtkObject}, Ptr{Uint8}, Ptr{GValue1}), w, staticstring(name), &v)
    v[T]
end

function getindex{T}(w::GtkWidget, child::GtkWidget, name::Union(String,Symbol), ::Type{T})
    v = gvalue(T)
    ccall((:gtk_container_child_get_property,libgtk), Void,
        (Ptr{GtkObject}, Ptr{GtkObject}, Ptr{Uint8}, Ptr{GValue1}), w, child, staticstring(name), &v)
    v[T]
end

setindex!{T}(w::GtkObject, value, name::Union(String,Symbol), ::Type{T}) = setindex!(w, convert(T,value), name)
function setindex!(w::GtkObject, value, name::Union(String,Symbol))
    v = gvalue(value)
    ccall((:g_object_set_property, libgobject), Void, 
        (Ptr{GtkObject}, Ptr{Uint8}, Ptr{GValue1}), w, staticstring(name), &v)
    ccall((:g_value_unset,libgobject),Void,(Ptr{GValue1},),&v)
    w
end

#setindex!{T}(w::GtkWidget, value, child::GtkWidget, ::Type{T}) = error("missing Gtk property-name to set")
setindex!{T}(w::GtkWidget, value, child::GtkWidget, name::Union(String,Symbol), ::Type{T}) = setindex!(w, convert(T,value), child, name)
function setindex!(w::GtkWidget, value, child::GtkWidget, name::Union(String,Symbol))
    v = gvalue(value)
    ccall((:gtk_container_child_set_property,libgtk), Void, 
        (Ptr{GtkObject}, Ptr{GtkObject}, Ptr{Uint8}, Ptr{GValue1}), w, child, staticstring(name), &v)
    ccall((:g_value_unset,libgobject),Void,(Ptr{GValue1},),&v)
    w
end

G_TYPE_FROM_CLASS(w::Ptr{Void}) = unsafe_load(convert(Ptr{Csize_t},w))
G_OBJECT_GET_CLASS(w::GtkObject) = unsafe_load(convert(Ptr{Ptr{Void}},w.handle))
G_OBJECT_CLASS_TYPE(w::GtkObject) = G_TYPE_FROM_CLASS(G_OBJECT_GET_CLASS(w))

immutable GParamSpec
  g_type_instance::Ptr{Void}
  name::Ptr{Uint8}
  flags::Cint
  value_type::Csize_t
  owner_type::Csize_t
end

function show(io::IO, w::GtkObject)
    print(io,typeof(w),'(')
    n = Array(Cuint,1)
    props = ccall((:g_object_class_list_properties,libgobject),Ptr{Ptr{GParamSpec}},
        (Ptr{Void},Ptr{Cuint}),G_OBJECT_GET_CLASS(w),n)
    v = gvalue(ByteString)
    for i = 1:n[1]
        param = unsafe_load(unsafe_load(props,i))
        print(io,bytestring(param.name))
        const READABLE=1
        if (param.flags&1)==READABLE &&
                bool(ccall((:g_value_type_transformable,libgobject),Cint,
                (Int,Int),param.value_type,gstring_id))
            ccall((:g_object_get_property,libgobject), Void,
                (Ptr{GtkObject}, Ptr{Uint8}, Ptr{GValue1}), w, param.name, &v)
            str = ccall((:g_value_get_string,libgobject),Ptr{Uint8},(Ptr{GValue1},),&v)
            value = (str == C_NULL ? "NULL" : bytestring(str))
            ccall((:g_value_reset,libgobject),Ptr{Void},(Ptr{GValue1},), &v)
            if param.value_type == gstring_id && str != C_NULL
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
    ccall((:g_value_unset,libgobject),Ptr{Void},(Ptr{GValue1},), &v)
end
