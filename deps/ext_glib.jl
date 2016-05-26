const _depspath = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(_depspath)
    include(_depspath)
end

if VERSION >= v"0.5.0-dev+4257"
    const KERNEL = Base.Sys.KERNEL
else
    const KERNEL = Base.OS_NAME
end

if KERNEL == :Windows
    @assign_if_unassigned libgobject = "libgobject-2.0-0"
    @assign_if_unassigned libglib = "libglib-2.0-0"
else
    @assign_if_unassigned libgobject = "libgobject-2.0"
    @assign_if_unassigned libglib = "libglib-2.0"
end
