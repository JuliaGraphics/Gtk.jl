@gtktype Widget
@gtktype Container
@gtktype Bin
@gtktype Window
@gtktype Dialog
@gtktype Box
@gtktype MenuShell
@gtktype MenuItem

convert(::Type{Ptr{GObjectI}},w::String) = convert(Ptr{GObjectI},GtkLabel(w))
eltype{T<:GObjectI}(::GSList{T}) = T

destroy(w::GtkWidgetI) = ccall((:gtk_widget_destroy,libgtk), Void, (Ptr{GObjectI},), w)
parent(w::GtkWidgetI) = convert(GtkWidgetI, ccall((:gtk_widget_get_parent,libgtk), Ptr{GObjectI}, (Ptr{GObjectI},), w))
hasparent(w::GtkWidgetI) = ccall((:gtk_widget_get_parent,libgtk), Ptr{Void}, (Ptr{GObjectI},), w) != C_NULL
function toplevel(w::GtkWidgetI)
    p = convert(Ptr{GObjectI}, w)
    pp = p
    while pp != C_NULL
        p = pp
        pp = ccall((:gtk_widget_get_parent,libgtk), Ptr{GObjectI}, (Ptr{GObjectI},), p)
    end
    convert(GtkWidgetI, p)
end
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

function getindex{T}(w::GtkWidgetI, child::GtkWidgetI, name::Union(String,Symbol), ::Type{T})
    v = gvulue(T)
    ccall((:gtk_container_child_get_property,libgtk), Void,
        (Ptr{GObject}, Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, child, bytestring(name), v)
    val = v[T]
    ccall((:g_value_unset,libgobject),Void,(Ptr{GValue},), v)
    return val
end
#setindex!{T}(w::GtkWidgetI, value, child::GtkWidgetI, ::Type{T}) = error("missing Gtk property-name to set")
setindex!{T}(w::GtkWidgetI, value, child::GtkWidgetI, name::Union(String,Symbol), ::Type{T}) = setindex!(w, convert(T,value), child, name)
function setindex!(w::GtkWidgetI, value, child::GtkWidgetI, name::Union(String,Symbol))
    v = gvalue(value)
    ccall((:gtk_container_child_set_property,libgtk), Void, 
        (Ptr{GObject}, Ptr{GObject}, Ptr{Uint8}, Ptr{GValue}), w, child, bytestring(name), v)
    w
end
