
immutable MatrixStrided{T} <: AbstractArray{T,2}
    p::Ptr{T}
    nbytes::Int
    rowstride::Int
    MatrixStrided(p::Ptr, nbytes::Integer, rowstride::Integer) = new(p,nbytes,rowstride)
end
MatrixStrided{T}(p::Ptr{T}, width::Integer, height::Integer, rowstride::Integer) =
    MatrixStrided{T}(p, rowstride * (height-1) + width * sizeof(T), rowstride)

function getindex{T,N}(a::ArrayStrided{T,N},indices::NTuple{N,Int})
    i = indices[1]*sizeof(T)
    for j = 2:N
        i += (indices[j]-1)*bytestrides[j]
    end
    @assert i <= a.nbytes
    unsafe_load(a,i)
end

