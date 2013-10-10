### Getting and Setting Properties
const gstring_id = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),"gchararray")
const gdouble_id = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),"gdouble")
const gint64_id = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),"gint64")
const guint64_id = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),"guint64")
const gboolean_id = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),"gboolean")


GValue() = zeros(Int64,3)
macro GValue(pass_x,as_type,as_ctype,to_gtype,with_id)
    quote
        function $(esc(:GValue))(::Type{$as_type})
            v = GValue()
            ccall((:g_value_init,libgobject),Void,(Ptr{Void},Csize_t), v, $with_id)
            v
        end
        function $(esc(:GValue))(x::$pass_x)
            v = GValue($as_type)
            $(if to_gtype == :string; :(x = bytestring(x)) end)
            ccall(($(string("g_value_set_",to_gtype)),libgobject),Void,(Ptr{Void},$as_ctype), v, x)
            v
        end
        $(if to_gtype == :static_string; to_gtype = :string; nothing end)
        # GValue isn't a type, so we can't write methods for it. However, maybe in the future this will be useful
        #function $(esc(:getindex)){T<:$pass_x}(v::GValue, ::Type{T})
        #    x = ccall(($(string("g_value_get_",to_gtype)),libgobject),$as_ctype,(Ptr{Void},),v)
        #    $(if to_gtype == :string; :(x = bytestring(x)) end)
        #    $(if pass_x == :Symbol; :(x = symbol(x)) end)
        #    return convert($pass_x,x)
        #end
        function $(esc(:getindex)){T<:$pass_x}(w::GtkWidget, name::Union(ByteString,Symbol), ::Type{T})
            v = GValue($as_type)
            ccall((:g_object_get_property,libgobject), Void,
                (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, name, v)
            x = ccall(($(string("g_value_get_",to_gtype)),libgobject),$as_ctype,(Ptr{Void},),v)
            $(if to_gtype == :string; :(x = bytestring(x)) end)
            $(if pass_x == :Symbol; :(x = symbol(x)) end)
            ccall((:g_value_unset,libgobject),Void,(Ptr{Void},),v)
            return convert($pass_x,x)
        end
        function $(esc(:getindex)){T<:$pass_x}(w::GtkWidget, child::GtkWidget, name::Union(ByteString,Symbol), ::Type{T})
            v = GValue($as_type)
            ccall((:gtk_container_child_get_property,libgtk), Void,
                (Ptr{GtkWidget}, Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, child, name, v)
            x = ccall(($(string("g_value_get_",to_gtype)),libgobject),$as_ctype,(Ptr{Void},),v)
            $(if to_gtype == :string; :(x = bytestring(x)) end)
            $(if pass_x == :Symbol; :(x = symbol(x)) end)
            ccall((:g_value_unset,libgobject),Void,(Ptr{Void},),v)
            return convert($pass_x,x)
        end
    end
end
GValue(s::String) = GValue(bytestring(s))
@GValue String          ByteString  Ptr{Uint8}      string          gstring_id
@GValue Symbol          ByteString  Ptr{Uint8}      static_string   gstring_id
@GValue Unsigned        Uint64      Uint64          uint64          guint64_id
@GValue Signed          Int64       Int64           int64           gint64_id
@GValue FloatingPoint   Float64     Float64         double          gdouble_id
@GValue Bool            Bool        Cint            boolean         gboolean_id
@GValue GtkWidget       GtkWidget   Ptr{GtkWidget}  object          ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),"GtkWidget")

getindex{T}(w::GtkWidget, name, ::Type{T}) = getindex(w, bytestring(name), T)
getindex{T}(w::GtkWidget, name::Union(ByteString,Symbol), ::Type{T}) =
    error("don't know how to represent gproperty of type $T in Julia") # prevent recursion

getindex{T}(w::GtkWidget, child::GtkWidget, name, ::Type{T}) = getindex(w, child, bytestring(name), T)
getindex{T}(w::GtkWidget, child::GtkWidget, name::Union(ByteString,Symbol), ::Type{T}) =
    error("don't know how to represent gproperty of type $T in Julia") # prevent recursion

setindex!(w::GtkWidget, value, name) = setindex!(w, value, bytestring(name))
setindex!{T}(w::GtkWidget, value, name, ::Type{T}) = setindex!(w, convert(T,value), name)
function setindex!(w::GtkWidget, value, name::Union(ByteString,Symbol))
    v = GValue(value)
    ccall((:g_object_set_property, libgobject), Void, 
        (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, name, v)
    ccall((:g_value_unset,libgobject),Void,(Ptr{Void},),v)
    w
end

setindex!{T}(w::GtkWidget, value, child::GtkWidget, ::Type{T}) = error("missing Gtk property-name to set")
setindex!(w::GtkWidget, value, child::GtkWidget, name) = setindex!(w, value, child, bytestring(name))
setindex!{T}(w::GtkWidget, value, child::GtkWidget, name, ::Type{T}) = setindex!(w, convert(T,value), child, name)
function setindex!(w::GtkWidget, value, child::GtkWidget, name::Union(ByteString,Symbol))
    v = GValue(value)
    ccall((:gtk_container_child_set_property,libgtk), Void, 
        (Ptr{GtkWidget}, Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, child, name, v)
    ccall((:g_value_unset,libgobject),Void,(Ptr{Void},),v)
    w
end

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
                (Int,Int),param.value_type,gstring_id))
            ccall((:g_object_get_property,libgobject), Void,
                (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, param.name, v)
            str = ccall((:g_value_get_string,libgobject),Ptr{Uint8},(Ptr{Void},),v)
            value = (str == C_NULL ? "NULL" : bytestring(str))
            ccall((:g_value_reset,libgobject),Ptr{Void},(Ptr{Void},), v)
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
    ccall((:g_value_unset,libgobject),Ptr{Void},(Ptr{Void},), v)
end
