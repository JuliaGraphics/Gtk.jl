const _depspath = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(_depspath)
    include(_depspath)
end

const KERNEL = Base.Sys.KERNEL

if !isdefined(@__MODULE__, :libgtk)
    if KERNEL == :Windows || KERNEL == :NT
        const libgtk = "libgtk-3-0"
    else
        const libgtk = "libgtk-3"
    end
end
if !isdefined(@__MODULE__, :libgdk)
    if KERNEL == :Windows || KERNEL == :NT
        const libgdk = "libgdk-3-0"
    else
        const libgdk = "libgdk-3"
    end
end

if !isdefined(@__MODULE__, :libgdk_pixbuf)
    if KERNEL == :Windows || KERNEL == :NT
        const libgdk_pixbuf = "libgdk_pixbuf-2.0-0"
    else
        const libgdk_pixbuf = "libgdk_pixbuf-2.0"
    end
end
if !isdefined(@__MODULE__, :libgio)
    if KERNEL == :Windows || KERNEL == :NT
        const libgio = "libgio-2.0-0"
    else
        const libgio = "libgio-2.0"
    end
end
