function push!(w::GtkContainer, child)
    ccall((:gtk_container_add, libgtk), Void, (Ptr{GObject}, Ptr{GObject},), w, child)
    w
end
function delete!(w::GtkContainer, child::GtkWidget)
    ccall((:gtk_container_remove, libgtk), Void, (Ptr{GObject}, Ptr{GObject},), w, child)
    w
end
function empty!(w::GtkContainer)
    for child in w
        delete!(w, child)
    end
    w
end
function append!(w::GtkContainer, children)
    for child in children
        push!(w, child)
    end
    w
end
Base.:|>(parent::GtkContainer, child::Union{GObject, AbstractString}) = push!(parent, child)

start(w::GtkContainer) = glist_iter(ccall((:gtk_container_get_children, libgtk), Ptr{_GList{GObject}}, (Ptr{GObject},), w))
next(w::GtkContainer, list) = next(list[1], list)
done(w::GtkContainer, list) = done(list[1], list)
length(w::GtkContainer) = length(start(w)[1])
getindex(w::GtkContainer, i::Integer) = convert(GtkWidget, start(w)[1][i])::GtkWidget

function start(w::GtkBin)
    child = ccall((:gtk_bin_get_child, libgtk), Ptr{GObject}, (Ptr{GObject},), w)
    if child != C_NULL
        return convert(GtkWidget, child)
    else
        return false
    end
end
next(w::GtkBin, i) = (i, false)
done(w::GtkBin, s::Bool) = true
done(w::GtkBin, s::GtkWidget) = false
length(w::GtkBin) = done(w, start(w)) ? 0 : 1
function getindex(w::GtkBin, i::Integer)
    i != 1 && error(BoundsError())
    c = start(w)
    c == false && error(BoundsError())
    c::GtkWidget
end

immutable GtkNullContainer <: GtkContainer end
const GtkNullContainerLeaf = GtkNullContainer
macro GtkNullContainer(args...)
    :( GtkNullContainer($(args...)) )
end
function push!(::GtkNullContainer, w::GtkWidget)
    p = ccall((:gtk_widget_get_parent, libgtk), Ptr{GObject}, (Ptr{GObject},), w)
    if p != C_NULL
        p = ccall((:gtk_container_remove, libgtk), Ptr{GObject}, (Ptr{GObject}, Ptr{GObject},), p, w)
    end
    w
end
unsafe_convert(::Type{Ptr{GObject}}, ::GtkNullContainer) = convert(Ptr{GObject}, C_NULL)
