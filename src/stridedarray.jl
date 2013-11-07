
immutable ArrayStrided{T,N} <: AbstractArray{T,N}
    p::Ptr{T}
    nbytes::Int
    bytestrides::NTuple{N,Int}
    function ArrayStrided(p::Ptr, nbytes::Integer, bytestrides::NTuple{N,Int})
        a = new(p,nbytes,bytestrides)
    end
end
ArrayStrided{T,N}(p::Ptr{T}, nbytes::Int, bytestrides::NTuple{N,Int}) =
    ArrayStrided{T,N}(p, nbytes, bytestrides)
ArrayStrided{T,N}(p::Ptr{T}, bytestrides::NTuple{N,Int}) =
    ArrayStrided{T,N}(p, rowstride * (height-1) + width * sizeof(T), bytestrides)
typealias VectorStrided{T} ArrayStrided{T,1}
typealias MatrixStrided{T} ArrayStrided{T,2}

function getindex{T,N}(a::ArrayStrided{T,N},indices::NTuple{N,Int})
    i = indices[1]*sizeof(T)
    for j = 2:N
        i += (indices[j]-1)*bytestrides[j]
    end
    @assert i <= a.nbytes
    unsafe_load(a,i)
end

ArrayStrided(p, (width,height))

