abstract GtkWidget
const GTKWidget = GtkWidget #deprecated name

const jlref_quark = ccall((:g_quark_from_string, libglib), Uint32, (Ptr{Uint8},), "jlref_quark")
const gchararray_id = ccall((:g_type_from_name,libgobject,Int,(Ptr{Uint8},),"gchararray")
const gdouble_id = ccall((:g_type_from_name,libgobject,Int,(Ptr{Uint8},),"gdouble")
const gint64_id = ccall((:g_type_from_name,libgobject,Int,(Ptr{Uint8},),"gint")
const guint64_id = ccall((:g_type_from_name,libgobject,Int,(Ptr{Uint8},),"guint")

# All GtkWidgets are expected to have a 'handle' field
# of type Ptr{GtkWidget} corresponding to the Gtk object
# and an 'all' field which has type GdkRectangle
# corresponding to the rectangle allocated to the object,
# or to override the size, width, and height methods
convert(::Type{Ptr{GtkWidget}},w::GtkWidget) = w.handle
function convert(::Type{GtkWidget},w::Ptr{GtkWidget})
    x = ccall((:g_object_get_qdata, libgobject), Ptr{GtkWidget}, (Ptr{GtkWidget},), w)
    x == C_NULL && error("GtkObject didn't have a corresponding Julia object")
    unsafe_pointer_to_objref(x)::GtkWidget
end
convert(::Type{Ptr{GtkWidget}},w::String) = convert(Ptr{GtkWidget},GtkLabel(w))

parent(w::GtkWidget) = convert(GtkWidget, ccall((:gtk_widget_get_parent,libgtk), Ptr{GtkWidget}, (Ptr{GtkWidget},), w))
width(w::GtkWidget) = w.all.width
height(w::GtkWidget) = w.all.height
size(w::GtkWidget) = (w.all.width, w.all.height)
show(io::IO, w::GtkWidget) = print(io, typeof(w))

### Getting and Setting Properties
function GValue(s::String)
    v = zeros(Int,3)
    ccall((:g_value_init,libgobject),Void,(Ptr{Void},Int), v, gchararray_id);
    ccall((:g_value_set_string,libgobject),Void,(Ptr{Void},Ptr{Uint8}), v, bytestring(s))
    v
end
function GValue(s::Symbol)
    v = zeros(Int,3)
    ccall((:g_value_init,libgobject),Void,(Ptr{Void},Int), v, gchararray_id);
    ccall((:g_value_set_static_string,libgobject),Void,(Ptr{Void},Ptr{Uint8}), v, s)
    v
end
function GValue(i::Unsigned)
    v = zeros(Int,3)
    ccall((:g_value_init,libgobject),Void,(Ptr{Void},Int), v, guint64_id);
    ccall((:g_value_set_uint64,libgobject),Void,(Ptr{Void},Uint64), v, i)
    v
end
function GValue(i::Signed)
    v = zeros(Int,3)
    ccall((:g_value_init,libgobject),Void,(Ptr{Void},Int), v, gint64_id);
    ccall((:g_value_set_int64,libgobject),Void,(Ptr{Void},Int64), v, i)
    v
end
function GValue(i::FloatingPoint)
    v = zeros(Int,3)
    ccall((:g_value_init,libgobject),Void,(Ptr{Void},Int), v, gdouble_id);
    ccall((:g_value_set_double,libgobject),Void,(Ptr{Void},Cdouble), v, i)
    v
end
setindex!(w::GtkWidget, value, name::String) = ccall((:g_object_set_property, libgobject), Void, 
    (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, bytestring(name), GValue(value))
setindex!(w::GtkWidget, value, name::Symbol) = ccall((:g_object_set_property, libgobject), Void, 
    (Ptr{GtkWidget}, Ptr{Uint8}, Ptr{Void}), w, name, GValue(value))

typealias StringLike Union(String,Symbol)
#function setindex!{T<:Number}(w::GtkWidget, value, name::StringLike, ::Type{T})
#    ccall((:g_object_set, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},T,Ptr{Void}...), w, name, value, C_NULL)
#end
#function setindex!{T<:String}(w::GtkWidget, value, name::StringLike, ::Type{T})
#    ccall((:g_object_set, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},Ptr{Uint8},Ptr{Void}...), w, name, gc_ref(bytestring(value)), C_NULL) #TODO: is the gc root necessary?
#end
#function setindex!{T<:GtkWidget}(w::GtkWidget, value, name::StringLike, ::Type{T})
#    ccall((:g_object_set, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},Ptr{T},Ptr{Void}...), w, name, value, C_NULL)
#end
function getindex!{T<:Number}(w::GtkWidget, name::StringLike, ::Type{T})
    value = Array(T, 1)
    ccall((:g_object_get, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},Ptr{T},Ptr{Void}...), w, name, value, C_NULL)
    value[1]
end
function getindex!{T<:String}(w::GtkWidget, name::StringLike, ::Type{T})
    value = Array(Ptr{Uint8}, 1)
    ccall((:g_object_get, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},Ptr{Ptr{Uint8}},Ptr{Void}...), w, name, value, C_NULL)
    s = bytestring(value[1])
    ccall((:g_free, libglib), Void, (Ptr{Void},), value[1])
    s
end
function getindex!{T<:GtkWidget}(w::GtkWidget, name::StringLike, ::Type{T})
    value = Array(Ptr{GtkWidget}, 1)
    ccall((:g_object_get, libgobject), Void, (Ptr{GtkWidget},Ptr{Uint8},Ptr{Ptr{T}},Ptr{Void}...), w, name, value, C_NULL)
    gc_ref(value[1])
    ccall((:g_object_unref, libglib), Void, (Ptr{Void},), value[1])
    convert(GtkWidget, value[1])::T
end

### Miscellaneous types
typealias Enum Int32
baremodule GtkWindowType
    const TOPLEVEL = 0
    const POPUP = 1
end
baremodule GConnectFlags
    const AFTER = 1
    const SWAPPED = 2
    get(s::Symbol) =
        if s === :after
            AFTER
        elseif s === :swapped
            SWAPPED
        else
            Main.Base.error(Main.Base.string("invalid GConnectFlag ",s))
        end
end
baremodule GtkPositionType
    const LEFT = 0
    const RIGHT = 1
    const TOP = 2
    const BOTTOM = 3
    get(s::Symbol) =
        if s === :left
            LEFT
        elseif s === :right
            RIGHT
        elseif s === :top
            TOP
        elseif s === :bottom
            BOTTOM
        else
            Main.Base.error(Main.Base.string("invalid GtkPositionType ",s))
        end
end

### Garbage collection [prevention]
const gc_preserve = ObjectIdDict() # reference counted closures
const gc_preserve_gtk = ObjectIdDict() # gtk objects

function gc_ref(x::ANY)
    global gc_preserve
    gc_preserve[x] = (get(gc_preserve, x, 0)::Int)+1
    x
end

function gc_ref(x::GtkWidget)
    global gc_preserve_gtk
    if !contains(gc_preserve_gtk, x)
        #on_signal_destroy(x, gc_unref, x)
        ccall((:g_object_set_qdata_full, libgobject), Void,
            (Ptr{GtkWidget}, Uint32, Any, Ptr{Void}), x, jlref_quark, x, 
            cfunction(gc_unref, Void, (Any,)))
        ccall((:g_object_ref,libgobject),Ptr{GtkWidget},(Ptr{GtkWidget},),x)
        finalize(x, (x)->ccall((:g_object_unref,libgobject),Void,(Ptr{GtkWidget},),x))
        gc_preserve_gtk[x] = x
    end
    x
end

function gc_unref(x::ANY)
    global gc_preserve
    count = get(gc_preserve, x, 0)-1
    if count <= 0
        delete!(gc_preserve, x)
    end
    nothing
end
gc_unref(x::Any, ::Ptr{Void}) = gc_unref(x)
gc_unref_closure(T::Type) = cfunction(gc_unref, Void, (T, Ptr{Void}))

function gc_unref(x::GtkWidget)
    global gc_preserve_gtk
    delete!(gc_preserve_gtk, x)
    x.handle = C_NULL
    nothing
end
gc_unref(::Ptr{GtkWidget}, x::GtkWidget) = gc_unref(x)

#GtkAdjustment(lower,upper,value=lower,step_increment=0,page_increment=0,page_size=0) =
#    ccall((:gtk_adjustment_new,libgtk),Ptr{Void},
#        (Cdouble,Cdouble,Cdouble,Cdouble,Cdouble,Cdouble),
#        value, lower, upper, step_increment, page_increment, page_size)
