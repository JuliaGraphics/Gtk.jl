# for gtk2, set this var to 2 and edit deps/build.jl as described therein
const gtk_version = 3

const _depspath = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(_depspath)
    include(_depspath)
end

const KERNEL = Base.Sys.KERNEL

if gtk_version == 3
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
elseif gtk_version == 2
    if !isdefined(@__MODULE__, :libgtk)
        if KERNEL == :Darwin
            const libgtk = "libgtk-quartz-2.0"
        elseif KERNEL == :Windows || KERNEL == :NT
            const libgtk = "libgtk-win32-2.0-0"
        else
            const libgtk = "libgtk-x11-2.0"
        end
        if KERNEL == :Darwin
            const libgdk = "libgdk-quartz-2.0"
        elseif KERNEL == :Windows || KERNEL == :NT
            const libgdk = "libgdk-win32-2.0-0"
        else
            const libgdk = "libgdk-x11-2.0"
        end
    end
else
    error("Unsupported Gtk version $gtk_version")
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
