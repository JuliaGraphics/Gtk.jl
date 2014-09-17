const gtk_version = 3 # This is the only configuration option

const _depspath = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(_depspath)
    include(_depspath)
else
    if gtk_version == 3
        if OS_NAME == :Windows
            const libgtk = "libgtk-3-0"
            const libgdk = "libgdk-3-0"
        else
            const libgtk = "libgtk-3"
            const libgdk = "libgdk-3"
        end
    elseif gtk_version == 2
        if OS_NAME == :Darwin
            const libgtk = "libgtk-quartz-2.0"
            const libgdk = "libgdk-quartz-2.0"
        elseif OS_NAME == :Windows
            const libgtk = "libgtk-win32-2.0-0"
            const libgdk = "libgdk-win32-2.0-0"
        else
            const libgtk = "libgtk-x11-2.0"
            const libgdk = "libgdk-x11-2.0"
        end
    else
        error("Unsupported Gtk version $gtk_version")
    end
    if OS_NAME == :Windows
        const libgdk_pixbuf = "libgdk_pixbuf-2.0-0"
        const libgio = "libgio-2.0-0"
    else
        const libgdk_pixbuf = "libgdk_pixbuf-2.0"
        const libgio = "libgio-2.0"
    end
end
