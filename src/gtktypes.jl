abstract GObjectI
typealias GObject GObjectI
abstract GtkWidgetI <: GObjectI
abstract GtkContainerI <: GtkWidgetI
abstract GtkBinI <: GtkContainerI
abstract GtkBoxI <: GtkContainerI

# Alternative object construction style. This would let us share constructors
# by creating const aliases: `const Z = GObject{:Z}`
type GObjectAny{Name} <: GObjectI
    handle::Ptr{GObject}
    GObjectAny(handle::Ptr{GObject}) = gc_ref(new(handle))
end
#type GtkWidgetAny{T} <: GtkWidgetI
#    handle::Ptr{GObject}
#    GtkWidgetAny(handle::Ptr{GObject}) = gc_ref(new(handle))
#end
#type GtkContainerAny{T} <: GtkContainerI
#    handle::Ptr{GObject}
#    GtkContainerAny(handle::Ptr{GObject}) = gc_ref(new(handle))
#end
#type GtkBinAny{T} <: GtkBinI
#    handle::Ptr{GObject}
#    GtkBinAny(handle::Ptr{GObject}) = gc_ref(new(handle))
#end
#type GtkBoxAny{T} <: GtkBoxI
#    handle::Ptr{GObject}
#    GtkBoxAny(handle::Ptr{GObject}) = gc_ref(new(handle))
#end

macro GType(gname)
    if isa(gname,Expr)
        @assert(gname.head == :comparison && length(gname.args) == 3 && gname.args[2] == :<:, "invalid GType expr")
        super = gname.args[3]
        gname = gname.args[1]
    else
        super = :GObject
    end
    gname = gname::Symbol
    quote
        type $(esc(gname)) <: $(esc(symbol(string(super,'I'))))
            handle::Ptr{GObjectI}
            $(esc(gname))(handle::Ptr{GObjectI}) = gc_ref(new(handle))
        end
    end
end

macro quark_str(q)
    :( ccall((:g_quark_from_string, libglib), Uint32, (Ptr{Uint8},), bytestring($q)) )
end
const jlref_quark = quark"julia_ref"

# All GtkWidgets are expected to have a 'handle' field
# of type Ptr{GObjectI} corresponding to the Gtk object
# and an 'all' field which has type GdkRectangle
# corresponding to the rectangle allocated to the object,
# or to override the size, width, and height methods
convert(::Type{Ptr{GObjectI}},w::GObjectI) = w.handle
convert{T<:GObjectI}(::Type{T},w::Ptr{T}) = convert(T,convert(Ptr{GObjectI},w))
function convert{T<:GObjectI}(::Type{T},w::Ptr{GObjectI})
    x = ccall((:g_object_get_qdata, libgobject), Ptr{GObjectI}, (Ptr{GObjectI},Uint32), w, jlref_quark)
    x == C_NULL && error("GObject didn't have a corresponding Julia object")
    unsafe_pointer_to_objref(x)::T
end
convert(::Type{Ptr{GObjectI}},w::String) = convert(Ptr{GObjectI},GtkLabel(w))
eltype{T<:GObjectI}(::GSList{T}) = T

destroy(w::GtkWidgetI) = ccall((:gtk_widget_destroy,libgtk), Void, (Ptr{GObjectI},), w)
parent(w::GtkWidgetI) = convert(GtkWidgetI, ccall((:gtk_widget_get_parent,libgtk), Ptr{GObjectI}, (Ptr{GObjectI},), w))
hasparent(w::GtkWidgetI) = ccall((:gtk_widget_get_parent,libgtk), Ptr{Void}, (Ptr{GObjectI},), w) != C_NULL
function allocation(widget::Gtk.GtkWidgetI)
    allocation_ = Array(GdkRectangle)
    ccall((:gtk_widget_get_allocation,libgtk), Void, (Ptr{GObject},Ptr{GdkRectangle}), widget, allocation_)
    return allocation_[1]
end
if gtk_version > 3
    width(w::GtkWidgetI) = ccall((:gtk_widget_get_allocated_width,libgtk),Cint,(Ptr{GObjectI},),w)
    height(w::GtkWidgetI) = ccall((:gtk_widget_get_allocated_height,libgtk),Cint,(Ptr{GObjectI},),w)
    size(w::GtkWidgetI) = (width(w),height(w))
else
    width(w::GtkWidgetI) = allocation(w).width
    height(w::GtkWidgetI) = allocation(w).height
    size(w::GtkWidgetI) = (a=allocation(w);(a.width,a.height))
end
show(io::IO, w::GObjectI) = print(io,typeof(w))

### Functions and methods common to all GtkWidget objects
#GtkAdjustment(lower,upper,value=lower,step_increment=0,page_increment=0,page_size=0) =
#    ccall((:gtk_adjustment_new,libgtk),Ptr{Void},
#        (Cdouble,Cdouble,Cdouble,Cdouble,Cdouble,Cdouble),
#        value, lower, upper, step_increment, page_increment, page_size)

visible(w::GtkWidgetI) = bool(ccall((:gtk_widget_get_visible,libgtk),Cint,(Ptr{GObjectI},),w))
visible(w::GtkWidgetI, state::Bool) = ccall((:gtk_widget_set_visible,libgtk),Void,(Ptr{GObjectI},Cint),w,state)
show(w::GtkWidgetI) = ccall((:gtk_widget_show,libgtk),Void,(Ptr{GObjectI},),w)
showall(w::GtkWidgetI) = ccall((:gtk_widget_show_all,libgtk),Void,(Ptr{GObjectI},),w)

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
gc_ref_closure{T}(x::T) = (gc_ref(x);cfunction(gc_unref, Void, (T, Ptr{Void})))
gc_unref(x::Any, ::Ptr{Void}) = gc_unref(x)

const gc_preserve_gtk = ObjectIdDict() # gtk objects
function gc_ref{T<:GObjectI}(x::T)
    global gc_preserve_gtk
    addref = function()
        ccall((:g_object_ref,libgobject),Ptr{GObjectI},(Ptr{GObjectI},),x)
        finalizer(x,function(x)
                global gc_preserve_gtk
                ccall((:g_object_unref,libgobject),Void,(Ptr{GObjectI},),x)
                gc_preserve_gtk[WeakRef(x)] = x #convert to a strong-reference
            end)
        wx = WeakRef(x) # record the existence of the object, but allow the finalizer
        gc_preserve_gtk[wx] = wx
    end
    ref = get(gc_preserve_gtk,x,nothing)
    if isa(ref,Nothing)
        ccall((:g_object_set_qdata_full, libgobject), Void,
            (Ptr{GObjectI}, Uint32, Any, Ptr{Void}), x, jlref_quark, x, 
            cfunction(gc_unref, Void, (T,))) # add a circular reference to the Julia object in the GObjectI
        addref()
    elseif !isa(ref,WeakRef)
        # oops, we previously deleted the link, but now it's back
        addref()
    else
        # already gc-protected, nothing to do
    end
    x
end


function gc_unref(x::GObjectI)
    # this strongly destroys and invalidates the object
    # it is intended to be called by Gtk, not in user code function
    global gc_preserve_gtk
    ccall((:g_object_steal_qdata,libgobject),Ptr{Any},(Ptr{GObjectI},Uint32),x,jlref_quark)
    delete!(gc_preserve_gtk, x)
    x.handle = C_NULL
    nothing
end
gc_unref(::Ptr{GObjectI}, x::GObjectI) = gc_unref(x)
gc_ref_closure(x::GObjectI) = C_NULL
