abstract GtkObject
abstract GtkWidget <: GtkObject
abstract GtkContainer <: GtkWidget
abstract GtkBin <: GtkContainer
const GTKWidget = GtkWidget #deprecated name

const jlref_quark = ccall((:g_quark_from_string, libglib), Uint32, (Ptr{Uint8},), "jlref_quark")

# All GtkWidgets are expected to have a 'handle' field
# of type Ptr{GtkObject} corresponding to the Gtk object
# and an 'all' field which has type GdkRectangle
# corresponding to the rectangle allocated to the object,
# or to override the size, width, and height methods
convert(::Type{Ptr{GtkObject}},w::GtkObject) = w.handle
function convert{T<:GtkObject}(::Type{T},w::Ptr{GtkObject})
    x = ccall((:g_object_get_qdata, libgobject), Ptr{GtkObject}, (Ptr{GtkObject},Uint32), w, jlref_quark)
    x == C_NULL && error("GtkObject didn't have a corresponding Julia object")
    unsafe_pointer_to_objref(x)::T
end
convert(::Type{Ptr{GtkObject}},w::String) = convert(Ptr{GtkObject},GtkLabel(w))

destroy(w::GtkWidget) = ccall((:gtk_widget_destroy,libgtk), Void, (Ptr{GtkObject},), w)
parent(w::GtkWidget) = convert(GtkWidget, ccall((:gtk_widget_get_parent,libgtk), Ptr{GtkObject}, (Ptr{GtkObject},), w))
width(w::GtkWidget) = w.all.width
height(w::GtkWidget) = w.all.height
size(w::GtkWidget) = (w.all.width, w.all.height)
show(io::IO, w::GtkObject) = print(io,typeof(w))

### Functions and methods common to all GtkWidget objects
#GtkAdjustment(lower,upper,value=lower,step_increment=0,page_increment=0,page_size=0) =
#    ccall((:gtk_adjustment_new,libgtk),Ptr{Void},
#        (Cdouble,Cdouble,Cdouble,Cdouble,Cdouble,Cdouble),
#        value, lower, upper, step_increment, page_increment, page_size)

visible(w::GtkWidget) = bool(ccall((:gtk_widget_get_visible,libgtk),Cint,(Ptr{GtkObject},),w))
visible(w::GtkWidget, state::Bool) = ccall((:gtk_widget_set_visible,libgtk),Void,(Ptr{GtkObject},Cint),w,state)
show(w::GtkWidget) = ccall((:gtk_widget_show,libgtk),Void,(Ptr{GtkObject},),w)
showall(w::GtkWidget) = ccall((:gtk_widget_show_all,libgtk),Void,(Ptr{GtkObject},),w)

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
function gc_ref{T<:GtkObject}(x::T)
    global gc_preserve_gtk
    addref = function()
        ccall((:g_object_ref,libgobject),Ptr{GtkObject},(Ptr{GtkObject},),x)
        finalizer(x,function(x)
                global gc_preserve_gtk
                ccall((:g_object_unref,libgobject),Void,(Ptr{GtkObject},),x)
                gc_preserve_gtk[WeakRef(x)] = x #convert to a strong-reference
            end)
        wx = WeakRef(x) # record the existence of the object, but allow the finalizer
        gc_preserve_gtk[wx] = wx
    end
    ref = get(gc_preserve_gtk,x,nothing)
    if isa(ref,Nothing)
        ccall((:g_object_set_qdata_full, libgobject), Void,
            (Ptr{GtkObject}, Uint32, Any, Ptr{Void}), x, jlref_quark, x, 
            cfunction(gc_unref, Void, (T,))) # add a circular reference to the Julia object in the GObject
        addref()
    elseif !isa(ref,WeakRef)
        # oops, we previously deleted the link, but now it's back
        addref()
    end
    x
end


function gc_unref(x::GtkObject)
    # this strongly destroys and invalidates the object
    # it is intended to be called by Gtk, not in user code function
    global gc_preserve_gtk
    ccall((:g_object_steal_qdata,libgobject),Ptr{Any},(Ptr{GtkObject},Uint32),x,jlref_quark)
    delete!(gc_preserve_gtk, x)
    x.handle = C_NULL
    nothing
end
gc_unref(::Ptr{GtkObject}, x::GtkWidget) = gc_unref(x)
gc_unref_closure{T<:GtkObject}(::Type{T}) = cfunction(gc_unref, Void, (T, Ptr{Void}))

