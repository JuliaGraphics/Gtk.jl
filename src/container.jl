typealias GtkContainer Union(GtkLayouts,GtkWindows,GtkContainerLike)

push!(w::GtkContainer, child) = (ccall((:gtk_container_add,libgtk), Void,
    (Ptr{GtkWidget},Ptr{GtkWidget},), w, child); w)
delete!(w::GtkContainer, child) = (ccall((:gtk_container_remove,libgtk), Void,
    (Ptr{GtkWidget},Ptr{GtkWidget},), w, child); w)

type GList
    data::Ptr{Void}
    next::Ptr{GList}
    prev::Ptr{GList}
end
function glist(list::Ptr{GList},)
    if list == C_NULL
        return ()
    end
    l = unsafe_load(list)
    finalizer(l, (l)->ccall(:g_list_free,Void,(Ptr{GList},),list))
    l
end
start(list::GList) = list
function next(list::GList,s)
    nx = s.next==C_NULL ? () : unsafe_load(s.next)
    return (s.data, nx)
end
done(list::GList,s::GList) = false
done(list::GList,s) = true
length(list::GList) = int(ccall((:g_list_length,libglib),Cuint,(Ptr{GList},),&list))
getindex(list::GList, i::Integer) = ccall((:g_list_nth_data,libglib),Ptr{Void},(Ptr{GList},Cuint),&list,i-1)

function start(w::GtkContainer)
    list = glist(ccall((:gtk_container_get_children,libgtk), Ptr{GList}, (Ptr{GtkWidget},), w))
    (list,list)
end
function next(w::GtkContainer,i)
    d,s = next(i[2],i[1])
    (convert(GtkWidget,convert(Ptr{GtkWidget},d)), (i[2],s))
end
done(w::GtkContainer,s::(GList,GList)) = false
done(w::GtkContainer,s::(Any,())) = true
length(w::GtkContainer) = length(start(w)[2])
getindex(w::GtkContainer, i::Integer) = convert(GtkWidget,convert(Ptr{GtkWidget},start(w)[2][i]))::GtkWidget

const gtkbintypes = [
    :GtkWindow,:GtkAlignment,:GtkFrame,:GtkAspectFrame,
    :GtkButtonBox,:GtkPaned,:GtkLayout,:GtkExpander,
    :GtkButton,:GtkCheckButton,:GtkToggleButton,:GtkRadioButton,:GtkLinkButton,:GtkVolumeButton
]
if gtk_version==3
    push!(gtkbintypes,:GtkFixed)
end
const gtkcontainertypes = [
    :GtkNotebook,:GtkBox,:GtkOrientable,:GtkTable
]
if gtk_version==3
    push!(gtkcontainertypes,:GtkGrid)
    push!(gtkcontainertypes,:GtkOverlay)
end
append!(gtkcontainertypes,gtkbintypes)
const gtkwidgettypes = [
    :GtkLabel
]
append!(gtkwidgettypes,gtkcontainertypes)
for container in gtkcontainertypes
    @eval $container(child::GtkWidget,vargs...) = push!($container(vargs...),child)
end

typealias GtkBin @eval Union($(gtkbintypes...))
function start(w::GtkBin)
    child = ccall((:gtk_bin_get_child,libgtk), Ptr{GtkWidget}, (Ptr{GtkWidget},), w)
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
 
