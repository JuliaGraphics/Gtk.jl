const _depspath = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(_depspath)
    include(_depspath)
end

const KERNEL = Base.Sys.KERNEL

if KERNEL == :Windows
    @assign_if_unassigned libgobject = "libgobject-2.0-0"
    @assign_if_unassigned libglib = "libglib-2.0-0"
else
    @assign_if_unassigned libgobject = "libgobject-2.0"
    @assign_if_unassigned libglib = "libglib-2.0"
end
