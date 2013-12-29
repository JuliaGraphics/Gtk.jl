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
const gpointer_id = g_type_from_name("gpointer")

immutable GValue
    field1::Csize_t
    field2::Uint64
    field3::Uint64
    GValue() = new(0,0,0)
end
typealias GV Union(Mutable{GValue}, Vector{GValue}, Ptr{GValue})
Base.zero(::Type{GValue}) = GValue()
function gvalue{T}(::Type{T})
    v = mutable(GValue())
    v[] = T
    v
end
function gvalue(x)
    v = mutable(gvalue(typeof(x)))
    v[] = x
    v
end
function gvalues(xs...)
    v = zeros(GValue, length(xs))
    for (i,x) in enumerate(xs)
        gv = mutable(v,i)
        gv[] = typeof(x) # init type
        gv[] = x # init value
    end
    finalizer(v, (v)->for i = 1:length(v)
            ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},),pointer(v,i))
        end)
    v
end

setindex!(gv::GV, i::Int, x) = setindex!(mutable(gv,i), x)
setindex!(::Type{Void},v::GV) = v
getindex{T}(gv::GV,::Type{T}) = getindex(gv,1,T)

for (pass_x,as_ctype,to_gtype,with_id) in (
    (String,          Ptr{Uint8},      :string,          :gstring_id),
    (Symbol,          Ptr{Uint8},      :static_string,   :gstring_id),
    (Unsigned,        Uint64,          :uint64,          :guint64_id),
    (Signed,          Int64,           :int64,           :gint64_id),
    (FloatingPoint,   Float64,         :double,          :gdouble_id),
    (Bool,            Cint,            :boolean,         :gboolean_id),
    (Ptr,             Ptr{Void},       :pointer,         :gpointer_id),
    (GObject,         Ptr{GObject},    :object,          :gobject_id),
    (GdkEventI,       Ptr{Void},       :boxed,           :(ccall((:gdk_event_get_type,libgdk),Int,()))),
    )
   @eval begin
        function setindex!{T<:$pass_x}(v::GV, ::Type{T})
            ccall((:g_value_init,libgobject),Void,(Ptr{GValue},Csize_t), v, $with_id)
            v
        end
        function setindex!{T<:$pass_x}(v::GV, x::T)
            $(if to_gtype == :string; :(x = bytestring(x)) end)
            ccall(($(string("g_value_set_",to_gtype)),libgobject),Void,(Ptr{GValue},$as_ctype), v, x)
            if isa(v, MutableTypes.MutableX)
                finalizer(v, (v::MutableTypes.MutableX)->ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},), v))
            end
            v
        end
        $(if to_gtype == :static_string; to_gtype = :string; nothing end)
        function getindex{T<:$pass_x}(v::GV,i::Int,::Type{T})
            x = ccall(($(string("g_value_get_",to_gtype)),libgobject),$as_ctype,(Ptr{GValue},), v)
            $(if to_gtype == :string; :(x = bytestring(x)) end)
            $(if pass_x == Symbol; :(x = symbol(x)) end)
            return convert(T,x)
        end
    end
end

getindex(v::GV,i::Int,::Type{Void}) = nothing

function getindex{T}(w::GObject, name::Union(String,Symbol), ::Type{T})
    v = mutable(gvalue(T))
    ccall((:g_object_get_property,libgobject), Void,
        (Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, bytestring(name), v)
    val = v[T]
    ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},), v)
    return val
end

function getindex{T}(w::GtkWidgetI, child::GtkWidgetI, name::Union(String,Symbol), ::Type{T})
    v = mutable(gvulue(T))
    ccall((:gtk_container_child_get_property,libgtk), Void,
        (Ptr{GObject}, Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, child, bytestring(name), v)
    val = v[T]
    ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},), v)
    return val
end

setindex!{T}(w::GObject, value, name::Union(String,Symbol), ::Type{T}) = setindex!(w, convert(T,value), name)
function setindex!(w::GObject, value, name::Union(String,Symbol))
    v = mutable(gvalue(value))
    ccall((:g_object_set_property, libgobject), Void, 
        (Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, bytestring(name), v)
    w
end

#setindex!{T}(w::GtkWidgetI, value, child::GtkWidgetI, ::Type{T}) = error("missing Gtk property-name to set")
setindex!{T}(w::GtkWidgetI, value, child::GtkWidgetI, name::Union(String,Symbol), ::Type{T}) = setindex!(w, convert(T,value), child, name)
function setindex!(w::GtkWidgetI, value, child::GtkWidgetI, name::Union(String,Symbol))
    v = mutable(gvalue(value))
    ccall((:gtk_container_child_set_property,libgtk), Void, 
        (Ptr{GObject}, Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, child, bytestring(name), v)
    w
end

G_TYPE_FROM_CLASS(w::Ptr{Void}) = unsafe_load(convert(Ptr{Csize_t},w))
G_OBJECT_GET_CLASS(w::GObject) = unsafe_load(convert(Ptr{Ptr{Void}},w.handle))
G_OBJECT_CLASS_TYPE(w::GObject) = G_TYPE_FROM_CLASS(G_OBJECT_GET_CLASS(w))

immutable GParamSpec
  g_type_instance::Ptr{Void}
  name::Ptr{Uint8}
  flags::Cint
  value_type::Csize_t
  owner_type::Csize_t
end

function show(io::IO, w::GObject)
    print(io,typeof(w),'(')
    n = Array(Cuint,1)
    props = ccall((:g_object_class_list_properties,libgobject),Ptr{Ptr{GParamSpec}},
        (Ptr{Void},Ptr{Cuint}),G_OBJECT_GET_CLASS(w),n)
    v = mutable(gvalue(ByteString))
    for i = 1:n[1]
        param = unsafe_load(unsafe_load(props,i))
        print(io,bytestring(param.name))
        const READABLE=1
        if (param.flags&1)==READABLE &&
                bool(ccall((:g_value_type_transformable,libgobject),Cint,
                (Int,Int),param.value_type,gstring_id))
            ccall((:g_object_get_property,libgobject), Void,
                (Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, param.name, v)
            str = ccall((:g_value_get_string,libgobject),Ptr{Uint8},(Ptr{GValue},), v)
            value = (str == C_NULL ? "NULL" : bytestring(str))
            ccall((:g_value_reset,libgobject),Ptr{Void},(Ptr{GValue},), v)
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
    ccall((:g_value_unset,libgobject),Ptr{Void},(Ptr{GValue},), v)
end
