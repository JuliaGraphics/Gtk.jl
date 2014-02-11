function push!(w::GtkContainerI, child)
    if isa(child,String)
        child = GtkLabel(child)
    end
    ccall((:gtk_container_add,libgtk), Void, (Ptr{GObject},Ptr{GObject},), w, child)
    show(child)
    w
end
function delete!(w::GtkContainerI, child::GtkWidgetI)
    ccall((:gtk_container_remove,libgtk), Void,(Ptr{GObject},Ptr{GObject},), w, child)
    w
end
function empty!(w::GtkContainerI)
    for child in w
        delete!(w,child)
    end
    w
end

start(w::GtkContainerI) = glist_iter(ccall((:gtk_container_get_children,libgtk), Ptr{_GSList{GObject}}, (Ptr{GObject},), w))
next(w::GtkContainerI, list) = next(list[1],list)
done(w::GtkContainerI, list) = done(list[1],list)
length(w::GtkContainerI) = length(start(w)[1])
getindex(w::GtkContainerI, i::Integer) = convert(GtkWidgetI,start(w)[1][i])::GtkWidgetI

function start(w::GtkBinI)
    child = ccall((:gtk_bin_get_child,libgtk), Ptr{GObject}, (Ptr{GObject},), w)
    if child != C_NULL
        return convert(GtkWidgetI,child)
    else
        return false
    end
end
next(w::GtkBinI,i) = (i,false)
done(w::GtkBinI,s::Bool) = true
done(w::GtkBinI,s::GtkWidgetI) = false
length(w::GtkBinI) = done(w,start(w)) ? 0 : 1
function getindex(w::GtkBinI, i::Integer)
    i!=1 && error(BoundsError())
    c = start(w)
    c == false && error(BoundsError())
    c::GtkWidgetI
end

immutable GtkNullContainer <: GtkContainerI end
function push!(::GtkNullContainer, w::GtkWidgetI)
    p = ccall((:gtk_widget_get_parent,libgtk), Ptr{GObject}, (Ptr{GObject},), w)
    if p != C_NULL
        p = ccall((:gtk_container_remove,libgtk), Ptr{GObject}, (Ptr{GObject},Ptr{GObject},), p, w)
    end
    w
end
convert(::Type{Ptr{GObject}},::GtkNullContainer) = convert(Ptr{GObject},C_NULL)
