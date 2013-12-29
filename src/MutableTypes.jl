module MutableTypes
export mutable, Mutable

abstract Mutable{T}
type MutableX{T} <: Mutable{T}
    x::T
end
type MutableA{T,N} <: Mutable{T}
    x::Array{T,N}
    i::Int
end
typealias MutableV{T} MutableA{T,1}

mutable{T}(x::T) = MutableX{T}(x)
mutable(x::Ptr) = x
mutable(x::Mutable) = x

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
Base.cconvert{T}(::Type{Ptr{T}}, b::MutableX{T}) = isbits(T) ? convert(Ptr{T}, _addrof(b)) : convert(Ptr{T}, _addrof(b.x))
Base.cconvert{T,N}(::Type{Ptr{T}}, b::MutableA{T,N}) = pointer(b.x, b.i)
end
