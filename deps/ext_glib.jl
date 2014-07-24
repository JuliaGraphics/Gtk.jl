const _depspath = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(_depspath)
    include(_depspath)
else
    if OS_NAME == :Windows
        const libgobject = "libgobject-2.0-0"
        const libglib = "libglib-2.0-0"
    else
        const libgobject = "libgobject-2.0"
        const libglib = "libglib-2.0"
    end
end
