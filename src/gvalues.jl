### Getting and Setting Properties
g_type_from_name(name::Symbol) = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),name)
#immutable GTypeQuery
#  g_type::Int
#  type_name::Ptr{Uint8}
#  class_size::Cuint
#  instance_size::Cuint
#  GTypeQuery() = new(0,0,0,0)
#end
#function gsizeof(name::Symbol)
#    q = mutable(GTypeQuery)
#    ccall((:g_type_query,libgobject),Void,(Int,Ptr{GTypeQuery},),g_type_from_name(name),q)
#    q[].instance_size
#end

const fundamental_types = (
    #(:name,      Ctype,      JuliaType,     g_value_fn)
    #(:invalid,    Void,       Void,          :error),
    #(:void,       Nothing,    Nothing,       :error),
    #(:GInterface,
    (:gchar,      Int8,       Int8,          :schar),
    (:guchar,     Uint8,      Uint8,         :uchar),
    (:gboolean,   Cint,       Bool,          :boolean),
    (:gint,       Cint,       None,          :int),
    (:guint,      Cuint,      None,          :uint),
    (:glong,      Clong,      None,          :long),
    (:gulong,     Culong,     None,          :ulong),
    (:gint64,     Int64,      Signed,        :int64),
    (:guint64,    Uint64,     Unsigned,      :uint64),
    (:GEnum,      Enum,       None,          :enum),
    (:GFlags,     Enum,       None,          :flags),
    (:gfloat,     Float32,    Float32,       :float),
    (:gdouble,    Float64,    FloatingPoint, :double),
    (:gchararray, Ptr{Uint8}, String,        :string),
    (:gpointer,   Ptr{Void},  Ptr,           :pointer),
    (:GBoxed,     Ptr{Void},  None,          :boxed),
    #(:GParam,
    (:GObject,    Ptr{GObject}, GObject,     :object),
    #(:GType,      Ptr{GType},
    #(:GVariant,
    )
# NOTE: in general do not cache ids, except for the fundamental values
const fundamental_ids = tuple([g_type_from_name(name) for (name,c,j,f) in fundamental_types]...)
const gboxed_id = g_type_from_name(:GBoxed)
const gobject_id = g_type_from_name(:GObject)
const gstring_id = g_type_from_name(:gchararray)
const gvoid_id = g_type_from_name(:void)

immutable GValue
    g_type::Csize_t
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
    v = gvalue(typeof(x))
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

function setindex!(dest::GV, src::GV)
    bool(ccall((:g_value_transform,libgobject),Cint,(Ptr{GValue},Ptr{GValue}),src,dest))
    src
end


setindex!(::Type{Void},v::GV) = v
setindex!(gv::GV, i::Int, x) = setindex!(mutable(gv,i), x)
getindex{T}(gv::GV, i::Int, ::Type{T}) = getindex(mutable(gv,i), T)
getindex(gv::Union(Mutable{GValue}, Ptr{GValue}), i::Int) = getindex(mutable(gv,i))

const gvalue_types = {}
function getindex(gv::Union(Mutable{GValue}, Ptr{GValue}))
    g_type = unsafe_load(gv).g_type
    if g_type == 0
        error("Invalid GValue type")
    end
    if g_type == gvoid_id
        return nothing
    end
    # first pass: fast loop for fundamental types
    for (i,id) in enumerate(fundamental_ids)
        if id == g_type  # if g_type == id
            T = fundamental_types[i][3]
            if T === None
                fundamental_types[i][2]
            end
            return gv[T]
        end
    end
    # second pass: user defined (sub)types
    for (typ, expr) in gvalue_types
        if bool(ccall((:g_type_is_a,libgobject),Cint,(Int,Int),g_type,expr())) # if g_type <: expr()
            return gv[typ]
        end
    end
    # last pass: check for derived fundamental types which have not been overridden by the user
    for (i,id) in enumerate(fundamental_ids)
        if bool(ccall((:g_type_is_a,libgobject),Cint,(Int,Int),g_type,id)) # if g_type <: id
            T = fundamental_types[i][3]
            if T === None
                fundamental_types[i][2]
            end
            return gv[T]
        end
    end
    typename = bytestring(ccall((:g_type_name,libgobject),Ptr{Uint8},(Int,),g_type))
    error("Could not convert GValue of type $typename to Julia type")
end

function make_gvalue(pass_x,as_ctype,to_gtype,with_id,allow_reverse::Bool=true)
    if pass_x !== None
        @eval begin
            function setindex!{T<:$pass_x}(v::GV, ::Type{T})
                ccall((:g_value_init,libgobject),Void,(Ptr{GValue},Csize_t), v, $with_id)
                v
            end
            function setindex!{T<:$pass_x}(v::GV, x::T)
                $(if to_gtype == :string; :(x = bytestring(x)) end)
                $(if to_gtype == :pointer || to_gtype == :boxed; :(x = mutable(x)) end)
                ccall(($(string("g_value_set_",to_gtype)),libgobject),Void,(Ptr{GValue},$as_ctype), v, x)
                if isa(v, MutableTypes.MutableX)
                    finalizer(v, (v::MutableTypes.MutableX)->ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},), v))
                end
                v
            end
        end
    else
        pass_x = as_ctype
    end
    if to_gtype == :static_string
        to_gtype = :string
    end
    @eval begin
        function getindex{T<:$pass_x}(v::GV,::Type{T})
            x = ccall(($(string("g_value_get_",to_gtype)),libgobject),$as_ctype,(Ptr{GValue},), v)
            $(if to_gtype == :string; :(x = bytestring(x)) end)
            $(if pass_x == Symbol; :(x = symbol(x)) end)
            return convert(T,x)
        end
    end
    if allow_reverse
        unshift!(gvalue_types, [pass_x, @eval ()->$with_id])
    end
end
for (i,(name, ctype, juliatype, g_value_fn)) in enumerate(fundamental_types)
    make_gvalue(juliatype, ctype, g_value_fn, fundamental_ids[i], false)
end
make_gvalue(Symbol, Ptr{Uint8}, :static_string, :gstring_id, false)

getindex(v::GV,i::Int,::Type{Void}) = nothing

function getindex{T}(w::GObject, name::Union(String,Symbol), ::Type{T})
    v = gvalue(T)
    ccall((:g_object_get_property,libgobject), Void,
        (Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, bytestring(name), v)
    val = v[T]
    ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},), v)
    return val
end

function getindex{T}(w::GtkWidgetI, child::GtkWidgetI, name::Union(String,Symbol), ::Type{T})
    v = gvulue(T)
    ccall((:gtk_container_child_get_property,libgtk), Void,
        (Ptr{GObject}, Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, child, bytestring(name), v)
    val = v[T]
    ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},), v)
    return val
end

setindex!{T}(w::GObject, value, name::Union(String,Symbol), ::Type{T}) = setindex!(w, convert(T,value), name)
function setindex!(w::GObject, value, name::Union(String,Symbol))
    v = gvalue(value)
    ccall((:g_object_set_property, libgobject), Void, 
        (Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, bytestring(name), v)
    w
end

#setindex!{T}(w::GtkWidgetI, value, child::GtkWidgetI, ::Type{T}) = error("missing Gtk property-name to set")
setindex!{T}(w::GtkWidgetI, value, child::GtkWidgetI, name::Union(String,Symbol), ::Type{T}) = setindex!(w, convert(T,value), child, name)
function setindex!(w::GtkWidgetI, value, child::GtkWidgetI, name::Union(String,Symbol))
    v = gvalue(value)
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
