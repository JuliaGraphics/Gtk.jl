# Gtk singly-linked list (also usable for double-linked list)
type GSList{T}
    data::Ptr{T}
    next::Ptr{GSList{T}}
end
eltype{T}(::GSList{T}) = Ptr{T}
function gslist{T}(list::Ptr{GSList{T}},own::Bool=false)
    # this function assumes the caller will take care of garbage management
    # if own = false, then you must ensure the list is not destroyed
    # if own = true, then you must hold a reference to the returned list
    if list == C_NULL
        return ()
    end
    l = unsafe_load(list)
    own ? finalizer(l, (l)->ccall((:g_list_free,libglib),Void,(Ptr{GSList{T}},),list)) : nothing
    l
end
function gslist2{T}(list::Ptr{GSList{T}})
    # this function pairs every list element with the list head, to forestall garbage collection
    # it assumes the user owns the list, if not, you are better off just using gslist
    list = gslist(list,true)
    (list,list)
end
start(list::GSList) = list
function next(list::GSList,s::GSList)
    nx = s.next==C_NULL ? () : unsafe_load(s.next)
    return (convert(eltype(s),s.data), nx)
end
function next(list::GSList,s::(GSList,GSList))
    s2 = s[2]
    nx = s2.next==C_NULL ? () : unsafe_load(s2.next)
    return (convert(eltype(s2),s2.data), (s[1],nx))
end
done(list::GSList,s::GSList) = false
done(list::GSList,s) = true
done(w::GSList,s::(GSList,GSList)) = false
done(w::GSList,s::(Any,())) = true
length(list::GSList) = int(ccall((:g_list_length,libglib),Cuint,(Ptr{typeof(list)},),&list))
getindex{T}(list::GSList{T}, i::Integer) =
    convert(eltype(list),
        ccall((:g_list_nth_data,libglib),Ptr{T},(Ptr{typeof(list)},Cuint),&list,i-1))
done(::(),::()) = true
