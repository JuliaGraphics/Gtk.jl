# Gtk linked list

## Type hierarchy information

### an _LList is expected to have a data::Ptr{T} and next::Ptr{_LList{T}} element
### they are expected to be allocated and freed by GLib (e.g. with malloc/free)
abstract _LList{T}

immutable _GSList{T} <: _LList{T}
    data::Ptr{T}
    next::Ptr{_GSList{T}}
end
immutable _GList{T} <: _LList{T}
    data::Ptr{T}
    next::Ptr{_GList{T}}
    prev::Ptr{_GList{T}}
end
eltype{T}(::Type{_LList{T}}) = T
eltype{L<:_LList}(::Type{L}) = eltype(super(L))
_listdatatype{T}(::Type{_LList{T}}) = T
_listdatatype{L<:_LList}(::Type{L}) = _listdatatype(super(L))

type GList{L<:_LList,T} <: AbstractVector{T}
    handle::Ptr{L}
    transfer_full::Bool
    function GList(handle, transfer_full::Bool) # if transfer_full == true, then also free the elements when finalizing the list
        # this function assumes the caller will take care of holding a pointer to the returned object
        # until it wants to be garbage collected
        @assert T == eltype(L)
        l = new(handle, transfer_full)
        finalizer(l, empty!)
        l
    end
end
GList{T}(list::Type{T}) = GList(convert(Ptr{_GList{T}}, C_NULL), true)
GList{L<:_LList}(list::Ptr{L},transfer_full::Bool=false) = GList{L, eltype(L)}(list, transfer_full)

typealias LList{L<:_LList} Union(Ptr{L}, GList{L})
eltype{L<:_LList}(::LList{L}) = eltype(L)

deref{L<:_LList}(item::Ptr{L}) = deref_to(L, unsafe_load(item).data) # extract something from the glist (automatically determine type)
deref_to{T}(::Type{T}, x::Ptr) = unsafe_pointer_to_objref(x)::T # helper for extracting something from the glist (to type T)
deref_to{L<:_LList}(::Type{L}, x::Ptr) = convert(eltype(L),deref_to(_listdatatype(L), x))
ref_to{T}(::Type{T}, x) = pointer_from_objref(gc_ref(x)) # create a reference to something for putting in the glist
ref_to{L<:_LList}(::Type{L}, x) = ref_to(_listdatatype(L), x)
empty!(li::Ptr{_LList}) = gc_unref(deref(li)) # delete an item in a glist
empty!{L<:_LList}(li::Ptr{L}) = empty!(convert(Ptr{super(L)}, li))

## Standard Iteration protocol
start{L}(list::LList{L}) = convert(Ptr{L},list)
next{T}(::LList,s::Ptr{T}) = (deref(s), unsafe_load(s).next) # return (value, state)
done(::LList,s::Ptr) = (s==C_NULL)

function glist_iter{L<:_LList}(list::Ptr{L}, transfer_full::Bool=false)
    # this function pairs every list element with the list head, to forestall garbage collection
    (GList(list, transfer_full), list)
end
function next{L<:_LList}(::LList,s::(LList,Ptr{L}))
    (deref(s[2]), (s[1],unsafe_load(s[2]).next))
end
done{L<:_LList}(::LList,s::(LList,Ptr{L})) = done(s[1],s[2])

## Standard Array-like declarations
show{L,T}(io::IO, list::GList{L,T}) = print(io, "GList{$L => $T}(length=$(length(list)), transfer_full=$(list.transfer_full))")
show{L,T}(io::IO, list::Type{GList{L,T}}) = print(io, "GList{$L => $T}")
convert{L<:_LList}(::Type{Ptr{L}}, list::GList) = list.handle
endof(list::LList) = length(list)
ndims(list::LList) = 1
strides(list::LList) = (1,)
stride(list::LList,k::Integer) = (k>1 ? length(list) : 1)
size(list::LList) = (length(list),)
isempty{L}(list::LList{L}) = (convert(Ptr{L},list) == C_NULL)

shift!(list::GList) = splice!(list,nth_first(list))
pop!(list::GList) = splice!(list,nth_last(list))
deleteat!(list::GList,i::Integer) = deleteat!(list,nth(list,i))
splice!(list::GList, item::Ptr) =
    (x=deref(item); deleteat!(list,item); x)
setindex!(list::GList,x,i::Real) = setindex!(list,x,nth(list,i))

## More Array-like declarations, this time involving ccall

### Non-modifying functions
length{L<:_GSList}(list::LList{L}) = int(ccall((:g_slist_length,libglib),Cuint,(Ptr{L},),list))
length{L<:_GList}(list::LList{L}) = int(ccall((:g_list_length,libglib),Cuint,(Ptr{L},),list))
copy{L<:_GSList}(list::GList{L}) = typeof(list)(ccall((:g_slist_copy,libglib),Ptr{L},(Ptr{L},),list), false)
copy{L<:_GList}(list::GList{L}) = typeof(list)(ccall((:g_list_copy,libglib),Ptr{L},(Ptr{L},),list), false)
check_undefref(p::Ptr) = (p==C_NULL ? error(UndefRefError()) : p)
nth_first{L<:_GSList}(list::LList{L}) =
    check_undefref(ccall((:g_slist_first,libglib),Ptr{L},(Ptr{L},Cuint),list))
nth_first{L<:_GList}(list::LList{L}) =
    check_undefref(ccall((:g_list_first,libglib),Ptr{L},(Ptr{L},),list))
nth_last{L<:_GSList}(list::LList{L}) =
    check_undefref(ccall((:g_slist_last,libglib),Ptr{L},(Ptr{L},),list))
nth_last{L<:_GList}(list::LList{L}) =
    check_undefref(ccall((:g_list_last,libglib),Ptr{L},(Ptr{L},),list))
nth{L<:_GSList}(list::LList{L}, i::Integer) =
    check_undefref(ccall((:g_slist_nth,libglib),Ptr{L},(Ptr{L},Cuint),list,i-1))
nth{L<:_GList}(list::LList{L}, i::Integer) =
    check_undefref(ccall((:g_list_nth,libglib),Ptr{L},(Ptr{L},Cuint),list,i-1))
getindex{L<:_GSList}(list::LList{L}, i::Integer) =
    deref_to(L, check_undefref(ccall((:g_list_nth_data,libglib),Ptr{_listdatatype(L)},(Ptr{L},Cuint),list,i-1)))
getindex{L<:_GList}(list::LList{L}, i::Integer) =
    deref_to(L, check_undefref(ccall((:g_slist_nth_data,libglib),Ptr{_listdatatype(L)},(Ptr{L},Cuint),list,i-1)))
function get{L<:_GSList}(list::LList{L}, i::Integer, default)
    p = ccall((:g_list_nth_data,libglib),Ptr{_listdatatype(L)},(Ptr{L},Cuint),list,i-1)
    p == C_NULL && return default
    deref_to(L, p)
end
function get{L<:_GList}(list::LList{L}, i::Integer, default)
    p = ccall((:g_slist_nth_data,libglib),Ptr{_listdatatype(L)},(Ptr{L},Cuint),list,i-1)
    p == C_NULL && return default
    deref_to(L, p)
end

### Modifying functions (!) are only allowed on a GList
function empty!{L<:_GSList}(list::GList{L})
    if list.handle != C_NULL
        if list.transfer_full
            s = start(list)
            while !done(list,s)
                empty!(s)
                s = next(list,s)[2]
            end
        end
        ccall((:g_slist_free,libglib),Void,(Ptr{L},),list)
        list.handle = C_NULL
    end
    list
end
function empty!{L<:_GList}(list::GList{L})
    if list.handle != C_NULL
        if list.transfer_full
            s = start(list)
            while !done(list,s)
                empty!(s)
                s = next(list,s)[2]
            end
        end
        ccall((:g_list_free,libglib),Void,(Ptr{L},),list)
        list.handle = C_NULL
    end
    list
end
function append!{L<:_GSList}(l1::GList{L}, l2::GList{L})
    (l1.transfer_full&l2.transfer_full) && error("cannot combine two lists with transfer_full=true")
    l1.handle = ccall((:g_slist_concat,libglib),Ptr{L},(Ptr{L},Ptr{L}),l1,l2)
    l1
end
function append!{L<:_GList}(l1::GList{L}, l2::GList{L})
    (l1.transfer_full&l2.transfer_full) && error("cannot combine two lists with transfer_full=true")
    l1.handle = ccall((:g_list_concat,libglib),Ptr{L},(Ptr{L},Ptr{L}),l1,l2)
    l1
end
reverse!{L<:_GSList}(list::GList{L}) =
    (list.handle = ccall((:g_slist_reverse,libglib),Ptr{L},(Ptr{L},),list); list)
reverse!{L<:_GList}(list::GList{L}) =
    (list.handle = ccall((:g_list_reverse,libglib),Ptr{L},(Ptr{L},),list); list)
insert!{L<:_GSList}(list::GList{L}, i::Integer, item) =
    (list.handle = ccall((:g_slist_insert,libglib),Ptr{L},(Ptr{L},Ptr{_listdatatype(L)},Cint),list,ref_to(L,item),i-1); list)
insert!{L<:_GList}(list::GList{L}, i::Integer, item) =
    (list.handle = ccall((:g_list_insert,libglib),Ptr{L},(Ptr{L},Ptr{_listdatatype(L)},Cint),list,ref_to(L,item),i-1); list)
insert!{L<:_GSList}(list::GList{L}, i::Ptr{L}, item) =
    (list.handle = ccall((:g_slist_insert_before,libglib),Ptr{L},(Ptr{L},Ptr{L},Ptr{_listdatatype(L)}),list,i,ref_to(L,item)); list)
insert!{L<:_GList}(list::GList{L}, i::Ptr{L}, item) =
    (list.handle = ccall((:g_list_insert_before,libglib),Ptr{L},(Ptr{L},Ptr{L},Ptr{_listdatatype(L)}),list,i,ref_to(L,item)); list)
unshift!{L<:_GSList}(list::GList{L}, item) =
    (list.handle = ccall((:g_slist_prepend,libglib),Ptr{L},(Ptr{L},Ptr{_listdatatype(L)}),list,ref_to(L,item)); list)
unshift!{L<:_GList}(list::GList{L}, item) =
    (list.handle = ccall((:g_list_prepend,libglib),Ptr{L},(Ptr{L},Ptr{_listdatatype(L)}),list,ref_to(L,item)); list)
push!{L<:_GSList}(list::GList{L}, item) =
    (list.handle = ccall((:g_slist_append,libglib),Ptr{L},(Ptr{L},Ptr{_listdatatype(L)}),list,ref_to(L,item)); list)
push!{L<:_GList}(list::GList{L}, item) =
    (list.handle = ccall((:g_list_append,libglib),Ptr{L},(Ptr{L},Ptr{_listdatatype(L)}),list,ref_to(L,item)); list)
deleteat!{L<:_GSList}(list::GList{L}, i::Ptr{L}) =
    (list.transfer_full&&empty!(i); list.handle = ccall((:g_slist_delete_link,libglib),Ptr{L},(Ptr{L},Ptr{L}),list,i); list)
deleteat!{L<:_GList}(list::GList{L}, i::Ptr{L}) =
    (list.transfer_full&&empty!(i); list.handle = ccall((:g_list_delete_link,libglib),Ptr{L},(Ptr{L},Ptr{L}),list,i); list)
function setindex!{L<:_GSList}(list::GList{L}, item, i::Ptr{L})
    list.transfer_full && empty!(i)
    idx = unsafe_load(i)
    idx = L(ref_to(L,item), idx.next)
    unsafe_store!(i,idx)
    list
end
function setindex!{L<:_GList}(list::GList{L}, item, i::Ptr{L})
    list.transfer_full && empty!(i)
    idx = unsafe_load(i)
    idx = L(ref_to(L,item), idx.next, idx.prev)
    unsafe_store!(i,idx)
    list
end


### Store most pointers without doing anything special
ref_to{P<:Ptr}(::Type{P}, x) = x
deref_to{P<:Ptr}(::Type{P}, x::Ptr) = x
empty!{P<:Ptr}(li::Ptr{_LList{P}}) = nothing

### Store numbers directly inside the pointer bits (assuming convert(N,x) exists)
ref_to{N<:Number}(::Type{N}, x) = x
deref_to{N<:Number}(::Type{N}, x::Ptr) = x
empty!{N<:Number}(li::Ptr{_LList{N}}) = nothing

### Handle storing pointers to numbers
eltype{N<:Number}(::Type{_LList{Ptr{N}}}) = N
deref_to{N<:Number}(::Type{Ptr{N}}, p::Ptr) = unsafe_load(p)
ref_to{N<:Number}(::Type{Ptr{N}}, x) = unsafe_store!(convert(Ptr{N},c_malloc(N.size)), x)
empty!{N<:Number}(li::Ptr{_GSList{Ptr{N}}}) = c_free(unsafe_load(li).data)
empty!{N<:Number}(li::Ptr{_GList{Ptr{N}}}) = c_free(unsafe_load(li).data)

### Store (byte)strings as pointers
deref_to{S<:ByteString}(::Type{S}, p::Ptr) = bytestring(convert(Ptr{Uint8},p))
function ref_to{S<:ByteString}(::Type{S}, x)
    s = bytestring(x)
    l = sizeof(s)
    p = convert(Ptr{Uint8},c_malloc(l+1))
    unsafe_copy!(p,convert(Ptr{Uint8},pointer(s)),l)
    unsafe_store!(p,'\0',l+1)
    return p
end
empty!{S<:ByteString}(li::Ptr{_GSList{S}}) = c_free(unsafe_load(li).data)
empty!{S<:ByteString}(li::Ptr{_GList{S}}) = c_free(unsafe_load(li).data)
