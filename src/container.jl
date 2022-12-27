function push!(w::GtkContainer, child)
    ccall((:gtk_container_add, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject},), w, child)
    w
end
function delete!(w::GtkContainer, child::GtkWidget)
    ccall((:gtk_container_remove, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject},), w, child)
    w
end

function Base.deleteat!(w::GtkContainer, i::Integer)
    i isa Bool && Base.depwarn("passing Bool as an index is deprecated", :deleteat!)
    delete!(w, w[i])
    w
end
function Base.deleteat!(w::GtkContainer, iterator)
    for child in [w[i] for i in iterator]
        delete!(w, child)
    end
    w
end
Base.firstindex(w::GtkContainer) = 1
Base.lastindex(w::GtkContainer) = length(w)
function _remove_widget(w, con)
    ccall((:gtk_container_remove, Gtk.libgtk), Nothing, (Ref{GObject}, Ref{GtkWidget}), con, w)
end

function empty!(c::GtkContainer)
    remove_widget_c = @cfunction(_remove_widget, Nothing, (Ptr{GtkWidget}, Ptr{GObject}))

    ccall((:gtk_container_foreach, Gtk.libgtk), Nothing, (Ptr{GObject}, Ptr{Cvoid}, Ptr{GObject}), c, remove_widget_c, c)
    c
end
function append!(w::GtkContainer, children)
    for child in children
        push!(w, child)
    end
    w
end
Base.:|>(parent::GtkContainer, child::Union{GObject, AbstractString}) = push!(parent, child)

start_(w::GtkContainer) = glist_iter(ccall((:gtk_container_get_children, libgtk), Ptr{_GList{GObject}}, (Ptr{GObject},), w))
iterate(w::GtkContainer, list=start_(w)) = iterate(list[1], list)
length(w::GtkContainer) = length(start_(w)[1])
Base.keys(w::GtkContainer) = Base.OneTo(length(w))
getindex(w::GtkContainer, i::Integer) = convert(GtkWidget, start_(w)[1][i])::GtkWidget

function start_(w::GtkBin)
    child = ccall((:gtk_bin_get_child, libgtk), Ptr{GObject}, (Ptr{GObject},), w)
    if child != C_NULL
        return convert(GtkWidget, child)
    else
        return false
    end
end
next_(w::GtkBin, i) = (i, false)
done_(w::GtkBin, s::Bool) = true
done_(w::GtkBin, s::GtkWidget) = false
iterate(w::GtkBin, s=start_(w)) = done_(w, s) ? nothing : next_(w, s)
length(w::GtkBin) = done_(w, start_(w)) ? 0 : 1
function getindex(w::GtkBin, i::Integer)
    i != 1 && error(BoundsError())
    c = start_(w)
    c == false && error(BoundsError())
    c::GtkWidget
end

struct GtkNullContainer <: GtkContainer end
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
