module MutableTypes

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@optlevel"))
    @eval Base.Experimental.@optlevel 1
end

export mutable, Mutable, deref

abstract type Mutable{T} end
mutable struct MutableX{T} <: Mutable{T}
    x::T
    MutableX{T}() where {T} = new{T}()
    MutableX{T}(x) where {T} = new{T}(x)
end
struct MutableA{T, N} <: Mutable{T}
    x::Array{T, N}
    i::Int
end
const  MutableV{T} = MutableA{T, 1}

mutable(x::T) where {T} = MutableX{T}(x)
mutable(x::Mutable) = x
mutable(x::Type{T}) where {T} = MutableX{T}()

function mutable(x::Array{T, N}, i = 1) where {T, N}
    if isbitstype(T)
        MutableA{T, N}(x, i)
    else
        mutable(x[i])
    end
end
mutable(x::Array{T, N}, i = 1) where {T <: Ptr, N} = mutable(x[i])
mutable(x::Ptr{T}, i = 1) where {T} = x + (i - 1) * sizeof(T)
mutable(x::T, i) where {T} = (i == 1 ? mutable(x) : error("Object only has one element"))

_addrof(b::T) where {T} = pointer_from_objref(b)
Base.cconvert(::Type{P}, b::MutableX{T}) where {P <: Ptr, T} = isbitstype(T) ? convert(P, _addrof(b)) : convert(P, _addrof(b.x))
Base.cconvert(::Type{P}, b::MutableA{T, N}) where {P <: Ptr, T, N} = convert(P, pointer(b.x, b.i))

deref(b::Ptr) = unsafe_load(b)
deref(b::MutableX) = b.x
deref(b::MutableA) = b.x[b.i]

Base.unsafe_load(b::Mutable) = deref(b)
Base.getindex(b::Mutable) = deref(b)

Base.unsafe_store!(b::MutableX, x) = (b.x = x)
Base.unsafe_store!(b::MutableA, x) = (b.x[b.i] = x)
Base.setindex!(b::MutableX{T}, x::T) where {T} = (b.x = x)
Base.setindex!(b::MutableA{T, N}, x::T) where {T, N} = (b.x[b.i] = x)

end
