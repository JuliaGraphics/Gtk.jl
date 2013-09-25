abstract GtkWidget
abstract GtkContainerLike <: GtkWidget
const GTKWidget = GtkWidget #deprecated name

const jlref_quark = ccall((:g_quark_from_string, libglib), Uint32, (Ptr{Uint8},), "jlref_quark")

# All GtkWidgets are expected to have a 'handle' field
# of type Ptr{GtkWidget} corresponding to the Gtk object
# and an 'all' field which has type GdkRectangle
# corresponding to the rectangle allocated to the object,
# or to override the size, width, and height methods
convert(::Type{Ptr{GtkWidget}},w::GtkWidget) = w.handle
function convert(::Type{GtkWidget},w::Ptr{GtkWidget})
    x = ccall((:g_object_get_qdata, libgobject), Ptr{GtkWidget}, (Ptr{GtkWidget},Uint32), w, jlref_quark)
    x == C_NULL && error("GtkObject didn't have a corresponding Julia object")
    unsafe_pointer_to_objref(x)::GtkWidget
end
convert(::Type{Ptr{GtkWidget}},w::String) = convert(Ptr{GtkWidget},GtkLabel(w))

parent(w::GtkWidget) = convert(GtkWidget, ccall((:gtk_widget_get_parent,libgtk), Ptr{GtkWidget}, (Ptr{GtkWidget},), w))
width(w::GtkWidget) = w.all.width
height(w::GtkWidget) = w.all.height
size(w::GtkWidget) = (w.all.width, w.all.height)
show(io::IO, w::GtkWidget) = print(io,typeof(w))

### Functions and methods common to all GtkWidget objects
#GtkAdjustment(lower,upper,value=lower,step_increment=0,page_increment=0,page_size=0) =
#    ccall((:gtk_adjustment_new,libgtk),Ptr{Void},
#        (Cdouble,Cdouble,Cdouble,Cdouble,Cdouble,Cdouble),
#        value, lower, upper, step_increment, page_increment, page_size)

visible(w::GtkWidget) = bool(ccall((:gtk_widget_get_visible,libgtk),Cint,(Ptr{GtkWidget},),w))
visible(w::GtkWidget, state::Bool) = ccall((:gtk_widget_set_visible,libgtk),Void,(Ptr{GtkWidget},Cint),w,state)
show(w::GtkWidget) = ccall((:gtk_widget_show,libgtk),Void,(Ptr{GtkWidget},),w)
showall(w::GtkWidget) = ccall((:gtk_widget_show_all,libgtk),Void,(Ptr{GtkWidget},),w)

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
function gc_ref(x::ANY)
    global gc_preserve
    gc_preserve[x] = (get(gc_preserve, x, 0)::Int)+1
    x
end
function gc_unref(x::ANY)
    global gc_preserve
    count = get(gc_preserve, x, 0)::Int-1
    if count <= 0
        delete!(gc_preserve, x)
    end
    nothing
end
gc_unref(x::Any, ::Ptr{Void}) = gc_unref(x)

const gc_preserve_gtk = ObjectIdDict() # gtk objects
function gc_ref{T<:GtkWidget}(x::T)
    global gc_preserve_gtk
    if !(x in gc_preserve_gtk)
        #on_signal_destroy(x, gc_unref, x)
        ccall((:g_object_set_qdata_full, libgobject), Void,
            (Ptr{GtkWidget}, Uint32, Any, Ptr{Void}), x, jlref_quark, x, 
            cfunction(gc_unref, Void, (T,)))
        ccall((:g_object_ref,libgobject),Ptr{GtkWidget},(Ptr{GtkWidget},),x)
        finalizer(x, (x)->ccall((:g_object_unref,libgobject),Void,(Ptr{GtkWidget},),x))
        gc_preserve_gtk[x] = x
    end
    x
end


function gc_unref(x::GtkWidget)
    global gc_preserve_gtk
    delete!(gc_preserve_gtk, x)
    x.handle = C_NULL
    nothing
end
gc_unref(::Ptr{GtkWidget}, x::GtkWidget) = gc_unref(x)
gc_unref_closure{T<:GtkWidget}(::Type{T}) = cfunction(gc_unref, Void, (T, Ptr{Void}))

