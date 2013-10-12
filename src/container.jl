push!(w::GtkContainer, child) = (ccall((:gtk_container_add,libgtk), Void,
    (Ptr{GtkObject},Ptr{GtkObject},), w, child); show(child); w)
delete!(w::GtkContainer, child::GtkWidget) = (ccall((:gtk_container_remove,libgtk), Void,
    (Ptr{GtkObject},Ptr{GtkObject},), w, child); w)
empty!(w::GtkContainer) =
    for child in w
        delete!(w,child)
    end

type GSList
    data::Ptr{Void}
    next::Ptr{GSList}
end
function gslist(list::Ptr{GSList},own::Bool=false)
    if list == C_NULL
        return ()
    end
    l = unsafe_load(list)
    own ? finalizer(l, (l)->ccall(:g_list_free,Void,(Ptr{GSList},),list)) : nothing
    l
end
start(list::GSList) = list
function next(list::GSList,s)
    nx = s.next==C_NULL ? () : unsafe_load(s.next)
    return (s.data, nx)
end
done(list::GSList,s::GSList) = false
done(list::GSList,s) = true
length(list::GSList) = int(ccall((:g_list_length,libglib),Cuint,(Ptr{GSList},),&list))
getindex(list::GSList, i::Integer) = ccall((:g_list_nth_data,libglib),Ptr{Void},(Ptr{GSList},Cuint),&list,i-1)



function start(w::GtkContainer)
    list = gslist(ccall((:gtk_container_get_children,libgtk), Ptr{GSList}, (Ptr{GtkObject},), w), true)
    (list,list)
end
function next(w::GtkContainer,i)
    d,s = next(i[1],i[2])
    (convert(GtkWidget,convert(Ptr{GtkObject},d)), (i[1],s))
end
done(w::GtkContainer,s::(GSList,GSList)) = false
done(w::GtkContainer,s::(Any,())) = true
length(w::GtkContainer) = length(start(w)[2])
getindex(w::GtkContainer, i::Integer) = convert(GtkWidget,convert(Ptr{GtkObject},start(w)[2][i]))::GtkWidget

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
