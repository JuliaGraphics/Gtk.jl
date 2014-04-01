# Gtk linked list

# an _LList is expected to have a data::Ptr{T} and next::Ptr{_LList{T}} element
# they are expected to be allocated and freed by GLib (e.g. with malloc/free)
abstract _LList{T}

immutable _GSList{T} <: _LList{T}
    data::Ptr{T}
    next::Ptr{_GSList{T}}
    _GSList() = new(0,0)
end
immutable _GList{T} <: _LList{T}
    data::Ptr{T}
    next::Ptr{_GList{T}}
    prev::Ptr{_GList{T}}
    _GList() = new(0,0,0)
end
type GList{L<:_LList}
    handle::Ptr{L}
    function GList(handle)
        # this function assumes the caller will take care of holding a pointer to the returned object
        # until it wants to be garbage collected
        l = new(handle)
        finalizer(l, (list)->ccall((:g_list_free,libglib),Void,(Ptr{Void},),list.handle))
        l
    end
end
GList{T}(list::Type{T}) = GList{_GList{T}}(C_NULL)
GList{L<:_LList}(list::Ptr{L}) = GList{L}(list)

typealias LList{L<:_LList} Union(Ptr{L}, GList{L})

eltype{L<:_LList}(::LList{L}) = eltype(L())
eltype{T}(::_LList{T}) = Ptr{T}

convert{L<:_LList}(::Type{Ptr{L}}, list::GList) = list.handle
length{L}(list::LList{L}) = int(ccall((:g_list_length,libglib),Cuint,(Ptr{L},),list))

start{L}(list::LList{L}) = convert(Ptr{L},list)
next{T}(::LList,s::Ptr{T}) = (convert(eltype(s),unsafe_load(s).data), unsafe_load(s).next)
done(::LList,s::Ptr) = (s==C_NULL)

_listdatatype{T}(::_LList{T}) = Ptr{T}
function getindex{L}(list::LList{L}, i::Integer)
    convert(eltype(list),
        ccall((:g_list_nth_data,libglib),_listdatatype(L()),(Ptr{L},Cuint),list,i-1))
end

function glist_iter{L<:_LList}(list::Ptr{L})
    # this function pairs every list element with the list head, to forestall garbage collection
    (GList(list),list)
end
function next{L<:_LList}(::LList,s::(LList,Ptr{L}))
    (convert(eltype(s[2]),unsafe_load(s[2]).data), (s[1],unsafe_load(s[2]).next))
end
done{L<:_LList}(::LList,s::(LList,Ptr{L})) = done(s[1],s[2])
