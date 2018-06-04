module MutableTypes
using Compat
export mutable, Mutable, deref

abstract type Mutable{T} end
type MutableX{T} <: Mutable{T}
    x::T
    (::Type{MutableX{T}}){T}() = new{T}()
    (::Type{MutableX{T}}){T}(x) = new{T}(x)
end
immutable MutableA{T, N} <: Mutable{T}
    x::Array{T, N}
    i::Int
end
const  MutableV{T} = MutableA{T, 1}

mutable{T}(x::T) = MutableX{T}(x)
mutable(x::Mutable) = x
mutable{T}(x::Type{T}) = MutableX{T}()

function mutable{T, N}(x::Array{T, N}, i = 1)
    if isbits(T)
        MutableA{T, N}(x, i)
    else
        mutable(x[i])
    end
end
mutable{T <: Ptr, N}(x::Array{T, N}, i = 1) = mutable(x[i])
mutable{T}(x::Ptr{T}, i = 1) = x + (i - 1) * sizeof(T)
mutable{T}(x::T, i) = (i == 1 ? mutable(x) : error("Object only has one element"))

_addrof{T}(b::T) = pointer_from_objref(b)
Base.cconvert{P <: Ptr, T}(::Type{P}, b::MutableX{T}) = isbits(T) ? convert(P, _addrof(b)) : convert(P, _addrof(b.x))
Base.cconvert{P <: Ptr, T, N}(::Type{P}, b::MutableA{T, N}) = convert(P, pointer(b.x, b.i))

deref(b::Ptr) = unsafe_load(b)
deref(b::MutableX) = b.x
deref(b::MutableA) = b.x[b.i]

Base.unsafe_load(b::Mutable) = deref(b)
Base.getindex(b::Mutable) = deref(b)

Base.unsafe_store!(b::MutableX, x) = (b.x = x)
Base.unsafe_store!(b::MutableA, x) = (b.x[b.i] = x)
Base.setindex!{T}(b::MutableX{T}, x::T) = (b.x = x)
Base.setindex!{T, N}(b::MutableA{T, N}, x::T) = (b.x[b.i] = x)

end
