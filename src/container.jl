push!(w::GtkContainer, child) = (ccall((:gtk_container_add,libgtk), Void,
    (Ptr{GtkObject},Ptr{GtkObject},), w, child); show(child); w)
delete!(w::GtkContainer, child::GtkWidget) = (ccall((:gtk_container_remove,libgtk), Void,
    (Ptr{GtkObject},Ptr{GtkObject},), w, child); w)
empty!(w::GtkContainer) =
    for child in w
        delete!(w,child)
    end

start(w::GtkContainer) = gslist2(ccall((:gtk_container_get_children,libgtk), Ptr{GSList{GtkObject}}, (Ptr{GtkObject},), w), true)
next(w::GtkContainer, list) = next(list[1],list)
done(w::GtkContainer, list) = next(list[1],list)
length(w::GtkContainer) = length(start(w)[2])
getindex(w::GtkContainer, i::Integer) = convert(GtkWidget,start(w)[2][i])::GtkWidget

function start(w::GtkBin)
    child = ccall((:gtk_bin_get_child,libgtk), Ptr{GtkObject}, (Ptr{GtkObject},), w)
    if child != C_NULL
        return convert(GtkWidget,child)
    else
        return false
    end
end
next(w::GtkBin,i) = (i,false)
done(w::GtkBin,s::Bool) = true
done(w::GtkBin,s::GtkWidget) = false
length(w::GtkBin) = done(w,start(w)) ? 0 : 1
function getindex(w::GtkBin, i::Integer)
    i!=1 && error(BoundsError())
    c = start(w)
    c == false && error(BoundsError())
    c::GtkWidget
end
 
immutable GtkNullContainer <: GtkContainer end
function push!(::GtkNullContainer, w::GtkWidget)
    p = ccall((:gtk_widget_get_parent,libgtk), Ptr{GtkObject}, (Ptr{GtkObject},), w)
    if p != C_NULL
        p = ccall((:gtk_container_remove,libgtk), Ptr{GtkObject}, (Ptr{GtkObject},Ptr{GtkObject},), p, w)
    end
    GtkNullContainer()
end
convert(::Type{Ptr{GtkObject}},::GtkNullContainer) = convert(Ptr{GtkObject},0)
