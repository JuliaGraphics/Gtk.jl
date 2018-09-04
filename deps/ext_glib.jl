const _depspath = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(_depspath)
    include(_depspath)
end

const KERNEL = Base.Sys.KERNEL

if !isdefined(@__MODULE__, :libgobject)
    if KERNEL == :Windows || KERNEL == :NT
        const libgobject = "libgobject-2.0-0"
    else
        const libgobject = "libgobject-2.0"
    end
end
if !isdefined(@__MODULE__, :libglib)
    if KERNEL == :Windows || KERNEL == :NT
        const libglib = "libglib-2.0-0"
    else
        const libglib = "libglib-2.0"
    end
end
