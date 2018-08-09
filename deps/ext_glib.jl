const _depspath = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(_depspath)
    include(_depspath)
end

const KERNEL = Base.Sys.KERNEL

if !isdefined(current_module(), :libgobject)
    if KERNEL == :Windows
        const libgobject = "libgobject-2.0-0"
    else
        const libgobject = "libgobject-2.0"
    end
end
if !isdefined(current_module(), :libglib)
    if KERNEL == :Windows
        const libglib = "libglib-2.0-0"
    else
        const libglib = "libglib-2.0"
    end
end
