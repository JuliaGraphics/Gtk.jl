module MutableTypes
export mutable, Mutable

abstract Mutable{T}
type MutableX{T} <: Mutable{T}
    x::T
    MutableX() = new()
    MutableX(x) = new(x)
end
immutable MutableA{T,N} <: Mutable{T}
    x::Array{T,N}
    i::Int
end
typealias MutableV{T} MutableA{T,1}

mutable{T}(x::T) = MutableX{T}(x)
mutable(x::Ptr) = x
mutable(x::Mutable) = x
mutable{T}(x::Type{T}) = MutableX{T}()

function mutable{T,N}(x::Array{T,N}, i)
    if isbits(T)
        MutableA{T,N}(x, i)
    else
        mutable(x[i])
    end
end
mutable{T<:Ptr,N}(x::Array{T,N}, i) = mutable(x[i])
mutable{T}(x::Ptr{T}, i) = mutable(x+(i-1)*sizeof(T))
mutable{T}(x::T, i) = (i == 1 ? mutable(x) : error("Object only has one element"))

_addrof{T}(b::T) = ccall(:jl_value_ptr,Ptr{T},(Ptr{Any},),&b)
Base.cconvert{P<:Ptr,T}(::Type{P}, b::MutableX{T}) = isbits(T) ? convert(P, _addrof(b)) : convert(P, _addrof(b.x))
Base.cconvert{P<:Ptr,T,N}(::Type{P}, b::MutableA{T,N}) = convert(P, pointer(b.x, b.i))

Base.unsafe_load(b::MutableX) = b.x
Base.unsafe_load(b::MutableA) = b.x[b.i]

Base.unsafe_store!(b::MutableX, x) = (b.x = x)
Base.unsafe_store!(b::MutableA, x) = (b.x[b.i] = x)

Base.getindex(b::MutableX) = b.x
Base.getindex(b::MutableA) = b.x[b.i]

Base.setindex!(b::MutableX, x) = (b.x = x)
Base.setindex!(b::MutableA, x) = (b.x[b.i] = x)

end
