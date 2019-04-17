# Gtk linked list

## Type hierarchy information

### an _LList is expected to have a data::Ptr{T} and next::Ptr{_LList{T}} element
### they are expected to be allocated and freed by GLib (e.g. with malloc/free)
abstract type _LList{T} end

struct _GSList{T} <: _LList{T}
    data::Ptr{T}
    next::Ptr{_GSList{T}}
end
struct _GList{T} <: _LList{T}
    data::Ptr{T}
    next::Ptr{_GList{T}}
    prev::Ptr{_GList{T}}
end
eltype(::Type{_LList{T}}) where {T} = T
eltype(::Type{L}) where {L <: _LList} = eltype(supertype(L))

mutable struct GList{L <: _LList, T} <: AbstractVector{T}
    handle::Ptr{L}
    transfer_full::Bool
    function GList{L,T}(handle, transfer_full::Bool) where {L<:_LList,T}
        # if transfer_full == true, then also free the elements when finalizing the list
        # this function assumes the caller will take care of holding a pointer to the returned object
        # until it wants to be garbage collected
        @assert T == eltype(L)
        l = new{L,T}(handle, transfer_full)
        finalizer(empty!, l)
        return l
    end
end
GList(list::Type{T}) where {T} = GList(convert(Ptr{_GList{T}}, C_NULL), true)
GList(list::Ptr{L}, transfer_full::Bool = false) where {L <: _LList} = GList{L, eltype(L)}(list, transfer_full)

const  LList{L <: _LList} = Union{Ptr{L}, GList{L}}
eltype(::LList{L}) where {L <: _LList} = eltype(L)

_listdatatype(::Type{_LList{T}}) where {T} = T
_listdatatype(::Type{L}) where {L <: _LList} = _listdatatype(supertype(L))
deref(item::Ptr{L}) where {L <: _LList} = deref_to(L, unsafe_load(item).data) # extract something from the glist (automatically determine type)
deref_to(::Type{T}, x::Ptr) where {T} = unsafe_pointer_to_objref(x)::T # helper for extracting something from the glist (to type T)
deref_to(::Type{L}, x::Ptr) where {L <: _LList} = convert(eltype(L), deref_to(_listdatatype(L), x))
ref_to(::Type{T}, x) where {T} = gc_ref(x) # create a reference to something for putting in the glist
ref_to(::Type{L}, x) where {L <: _LList} = ref_to(_listdatatype(L), x)
empty!(li::Ptr{_LList}) = gc_unref(deref(li)) # delete an item in a glist
empty!(li::Ptr{L}) where {L <: _LList} = empty!(convert(Ptr{supertype(L)}, li))

## Standard Iteration protocol
start_(list::LList{L}) where {L} = unsafe_convert(Ptr{L}, list)
next_(::LList, s) = (deref(s), unsafe_load(s).next) # return (value, state)
done_(::LList, s) = (s == C_NULL)
iterate(list::LList, s=start_(list)) = done_(list, s) ? nothing : next_(list, s)


const  LListPair{L} = Tuple{LList, Ptr{L}}
function glist_iter(list::Ptr{L}, transfer_full::Bool = false) where L <: _LList
    # this function pairs every list element with the list head, to forestall garbage collection
    return (GList(list, transfer_full), list)
end
function next_(::LList, s::LListPair{L}) where L <: _LList
    return (deref(s[2]), (s[1], unsafe_load(s[2]).next))
end
done_(::LList, s::LListPair{L}) where {L <: _LList} = done_(s[1], s[2])

## Standard Array-like declarations
show(io::IO, ::MIME"text/plain", list::GList{L, T}) where {L, T} = show(io, list)
show(io::IO, list::GList{L, T}) where {L, T} = print(io, "GList{$L => $T}(length = $(length(list)), transfer_full = $(list.transfer_full))")

unsafe_convert(::Type{Ptr{L}}, list::GList) where {L <: _LList} = list.handle
endof(list::LList) = length(list)
ndims(list::LList) = 1
strides(list::LList) = (1,)
stride(list::LList, k::Integer) = (k > 1 ? length(list) : 1)
size(list::LList) = (length(list),)
isempty(list::LList{L}) where {L} = (unsafe_convert(Ptr{L}, list) == C_NULL)
Base.IteratorSize(::Type{L}) where {L <: LList} = Base.HasLength()

popfirst!(list::GList) = splice!(list, nth_first(list))
pop!(list::GList) = splice!(list, nth_last(list))
deleteat!(list::GList, i::Integer) = deleteat!(list, nth(list, i))

function splice!(list::GList, item::Ptr) 
    x = deref(item)
    deleteat!(list, item)
    x
end

setindex!(list::GList, x, i::Real) = setindex!(list, x, nth(list, i))

## More Array-like declarations, this time involving ccall

### Non-modifying functions
length(list::LList{L}) where {L <: _GSList} = Int(ccall((:g_slist_length, libglib), Cuint, (Ptr{L},), list))
length(list::LList{L}) where {L <: _GList} = Int(ccall((:g_list_length, libglib), Cuint, (Ptr{L},), list))
copy(list::GList{L}) where {L <: _GSList} = typeof(list)(ccall((:g_slist_copy, libglib), Ptr{L}, (Ptr{L},), list), false)
copy(list::GList{L}) where {L <: _GList} = typeof(list)(ccall((:g_list_copy, libglib), Ptr{L}, (Ptr{L},), list), false)
check_undefref(p::Ptr) = (p == C_NULL ? error(UndefRefError()) : p)
nth_first(list::LList{L}) where {L <: _GSList} =
    check_undefref(ccall((:g_slist_first, libglib), Ptr{L}, (Ptr{L},), list))
nth_first(list::LList{L}) where {L <: _GList} =
    check_undefref(ccall((:g_list_first, libglib), Ptr{L}, (Ptr{L},), list))
nth_last(list::LList{L}) where {L <: _GSList} =
    check_undefref(ccall((:g_slist_last, libglib), Ptr{L}, (Ptr{L},), list))
nth_last(list::LList{L}) where {L <: _GList} =
    check_undefref(ccall((:g_list_last, libglib), Ptr{L}, (Ptr{L},), list))
nth(list::LList{L}, i::Integer) where {L <: _GSList} =
    check_undefref(ccall((:g_slist_nth, libglib), Ptr{L}, (Ptr{L}, Cuint), list, i - 1))
nth(list::LList{L}, i::Integer) where {L <: _GList} =
    check_undefref(ccall((:g_list_nth, libglib), Ptr{L}, (Ptr{L}, Cuint), list, i - 1))
function getindex(list::LList{_GSList{T}}, i::Integer) where T
    p = check_undefref(ccall((:g_slist_nth_data, libglib), Ptr{T}, (Ptr{_GSList{T}}, Cuint), list, i - 1))
    return deref_to(_GSList{T}, p)
end
function getindex(list::LList{_GList{T}}, i::Integer) where T
    p = check_undefref(ccall((:g_list_nth_data, libglib), Ptr{T}, (Ptr{_GList{T}}, Cuint), list, i - 1))
    return deref_to(_GList{T}, p)
end
function get(list::LList{_GSList{T}}, i::Integer, default) where T
    p = ccall((:g_slist_nth_data, libglib), Ptr{T}, (Ptr{_GSList{T}}, Cuint), list, i - 1)
    p == C_NULL && return default
    return deref_to(_GSList{T}, p)
end
function get(list::LList{_GList{T}}, i::Integer, default) where T
    p = ccall((:g_list_nth_data, libglib), Ptr{T}, (Ptr{_GList{T}}, Cuint), list, i - 1)
    p == C_NULL && return default
    return deref_to(_GList{T}, p)
end

### Modifying functions (!) are only allowed on a GList
function empty!(list::GList{L}) where L <: _GSList
    if list.handle != C_NULL
        if list.transfer_full
            s = start_(list)
            while !done_(list, s)
                empty!(s)
                s = next_(list, s)[2]
            end
        end
        ccall((:g_slist_free, libglib), Nothing, (Ptr{L},), list)
        list.handle = C_NULL
    end
    return list
end
function empty!(list::GList{L}) where L <: _GList
    if list.handle != C_NULL
        if list.transfer_full
            s = start_(list)
            while !done_(list, s)
                empty!(s)
                s = next_(list, s)[2]
            end
        end
        ccall((:g_list_free, libglib), Nothing, (Ptr{L},), list)
        list.handle = C_NULL
    end
    return list
end
function append!(l1::GList{L}, l2::GList{L}) where L <: _GSList
    (l1.transfer_full & l2.transfer_full) && error("cannot combine two lists with transfer_full = true")
    l1.handle = ccall((:g_slist_concat, libglib), Ptr{L}, (Ptr{L}, Ptr{L}), l1, l2)
    return l1
end
function append!(l1::GList{L}, l2::GList{L}) where L <: _GList
    (l1.transfer_full & l2.transfer_full) && error("cannot combine two lists with transfer_full = true")
    l1.handle = ccall((:g_list_concat, libglib), Ptr{L}, (Ptr{L}, Ptr{L}), l1, l2)
    return l1
end
function reverse!(list::GList{L}) where L <: _GSList
    list.handle = ccall((:g_slist_reverse, libglib), Ptr{L}, (Ptr{L},), list)
    return list
end
function reverse!(list::GList{L}) where L <: _GList
    list.handle = ccall((:g_list_reverse, libglib), Ptr{L}, (Ptr{L},), list)
    return list
end
function insert!(list::GList{_GSList{T}}, i::Integer, item) where T
    list.handle = ccall((:g_slist_insert, libglib), Ptr{_GSList{T}},
        (Ptr{_GSList{T}}, Ptr{T}, Cint),
        list, ref_to(_GSList{T}, item), i - 1)
    return list
end
function insert!(list::GList{_GList{T}}, i::Integer, item) where T
    list.handle = ccall((:g_list_insert, libglib), Ptr{_GList{T}},
        (Ptr{_GList{T}}, Ptr{T}, Cint),
        list, ref_to(_GList{T}, item), i - 1)
    return list
end
function insert!(list::GList{_GSList{T}}, i::Ptr{_GSList{T}}, item) where T
    list.handle = ccall((:g_slist_insert_before, libglib), Ptr{_GSList{T}},
        (Ptr{_GSList{T}}, Ptr{_GSList{T}}, Ptr{T}),
        list, i, ref_to(_GSList{T}, item))
    return list
end
function insert!(list::GList{_GList{T}}, i::Ptr{_GList{T}}, item) where T
    list.handle = ccall((:g_list_insert_before, libglib), Ptr{_GList{T}},
        (Ptr{_GList{T}}, Ptr{_GList{T}}, Ptr{T}),
        list, i, ref_to(_GList{T}, item))
    return list
end
function pushfirst!(list::GList{_GSList{T}}, item) where T
    list.handle = ccall((:g_slist_prepend, libglib), Ptr{_GSList{T}}, (Ptr{_GSList{T}}, Ptr{T}), list, ref_to(_GSList{T}, item))
    return list
end
function pushfirst!(list::GList{_GList{T}}, item) where T
    list.handle = ccall((:g_list_prepend, libglib), Ptr{_GList{T}},
        (Ptr{_GList{T}}, Ptr{T}),
        list, ref_to(_GList{T}, item))
    return list
end
function push!(list::GList{_GSList{T}}, item) where T
    list.handle = ccall((:g_slist_append, libglib), Ptr{_GSList{T}},
        (Ptr{_GSList{T}}, Ptr{T}),
        list, ref_to(_GSList{T}, item))
    return list
end
function push!(list::GList{_GList{T}}, item) where T
    list.handle = ccall((:g_list_append, libglib), Ptr{_GList{T}},
        (Ptr{_GList{T}}, Ptr{T}),
        list, ref_to(_GList{T}, item))
    return list
end
function deleteat!(list::GList{L}, i::Ptr{L}) where L <: _GSList
    list.transfer_full && empty!(i)
    list.handle = ccall((:g_slist_delete_link, libglib), Ptr{L}, (Ptr{L}, Ptr{L}), list, i)
    return list
end
function deleteat!(list::GList{L}, i::Ptr{L}) where L <: _GList
    list.transfer_full && empty!(i)
    list.handle = ccall((:g_list_delete_link, libglib), Ptr{L}, (Ptr{L}, Ptr{L}), list, i)
    return list
end
function setindex!(list::GList{L}, item, i::Ptr{L}) where L <: _GSList
    list.transfer_full && empty!(i)
    idx = unsafe_load(i)
    idx = L(ref_to(L, item), idx.next)
    unsafe_store!(i, idx)
    return list
end
function setindex!(list::GList{L}, item, i::Ptr{L}) where L <: _GList
    list.transfer_full && empty!(i)
    idx = unsafe_load(i)
    idx = L(ref_to(L, item), idx.next, idx.prev)
    unsafe_store!(i, idx)
    return list
end


### Store most pointers without doing anything special
ref_to(::Type{P}, x) where {P <: Ptr} = x
deref_to(::Type{P}, x::Ptr) where {P <: Ptr} = x
empty!(li::Ptr{_LList{P}}) where {P <: Ptr} = nothing

### Store numbers directly inside the pointer bits (assuming convert(N, x) exists)
ref_to(::Type{N}, x) where {N <: Number} = x
deref_to(::Type{N}, x::Ptr) where {N <: Number} = x
empty!(li::Ptr{_LList{N}}) where {N <: Number} = nothing

### Handle storing pointers to numbers
eltype(::Type{_LList{Ptr{N}}}) where {N <: Number} = N
deref_to(::Type{Ptr{N}}, p::Ptr) where {N <: Number} = unsafe_load(p)
ref_to(::Type{Ptr{N}}, x) where {N <: Number} = unsafe_store!(convert(Ptr{N}, g_malloc(N.size)), x)
empty!(li::Ptr{_GSList{Ptr{N}}}) where {N <: Number} = g_free(unsafe_load(li).data)
empty!(li::Ptr{_GList{Ptr{N}}}) where {N <: Number} = g_free(unsafe_load(li).data)

### Store (byte)strings as pointers
deref_to(::Type{S}, p::Ptr) where {S <: String} = bytestring(convert(Ptr{UInt8}, p))
function ref_to(::Type{S}, x) where S <: String
    s = bytestring(x)
    l = sizeof(s)
    p = convert(Ptr{UInt8}, g_malloc(l + 1))
    unsafe_copy!(p, convert(Ptr{UInt8}, pointer(s)), l)
    unsafe_store!(p, '\0', l + 1)
    return p
end
empty!(li::Ptr{_GSList{S}}) where {S <: String} = g_free(unsafe_load(li).data)
empty!(li::Ptr{_GList{S}}) where {S <: String} = g_free(unsafe_load(li).data)
