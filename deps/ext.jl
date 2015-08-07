const gtk_version = 3 # This is the only configuration option

const _depspath = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(_depspath)
    include(_depspath)
end

if gtk_version == 3
    if OS_NAME == :Windows
        @assign_if_unassigned libgtk = "libgtk-3-0"
        @assign_if_unassigned libgdk = "libgdk-3-0"
    else
        @assign_if_unassigned libgtk = "libgtk-3"
        @assign_if_unassigned libgdk = "libgdk-3"
    end
elseif gtk_version == 2
    if OS_NAME == :Darwin
        @assign_if_unassigned libgtk = "libgtk-quartz-2.0"
        @assign_if_unassigned libgdk = "libgdk-quartz-2.0"
    elseif OS_NAME == :Windows
        @assign_if_unassigned libgtk = "libgtk-win32-2.0-0"
        @assign_if_unassigned libgdk = "libgdk-win32-2.0-0"
    else
        @assign_if_unassigned libgtk = "libgtk-x11-2.0"
        @assign_if_unassigned libgdk = "libgdk-x11-2.0"
    end
else
    error("Unsupported Gtk version $gtk_version")
end

if OS_NAME == :Windows
    @assign_if_unassigned libgdk_pixbuf = "libgdk_pixbuf-2.0-0"
    @assign_if_unassigned libgio = "libgio-2.0-0"
else
    @assign_if_unassigned libgdk_pixbuf = "libgdk_pixbuf-2.0"
    @assign_if_unassigned libgio = "libgio-2.0"
end
