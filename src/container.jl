typealias GtkContainer Union(GtkLayouts,GtkWindows)

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
start(list::GList) = (list,list)
function next(list::GList,s)
    nx = s[1].next==C_NULL ? () : (unsafe_load(s[1].next),s[2])
    return (s[1].data, nx)
end
done(list::GList,s::(GList,GList)) = false
done(list::GList,s) = true
length(list::GList) = ccall((:g_list_length,libglib),Cuint,(Ptr{GList},),list)

start(w::GtkContainer) = start(glist(ccall((:gtk_container_get_children,libgtk), Ptr{GList}, (Ptr{GtkWidget},), w)))
function next(w::GtkContainer,i)
    d,s = next(i[2],i)
    (convert(GtkWidget,convert(Ptr{GtkWidget},d)), s)
end
done(w::GtkContainer,s::(GList,GList)) = false
done(w::GtkContainer,s) = true
function length(w::GtkContainer)
    s = start(w)
    if done(s)
        return 0
    else
        return length(s[2])
    end
end

