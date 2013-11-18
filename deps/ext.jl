const gtk_version = 3 # This is the only configuration option

if gtk_version == 3
    const libgtk = "libgtk-3"
    const libgdk = "libgdk-3"
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
    const libgobject = "libgobject-2.0-0"
    const libglib = "libglib-2.0-0"
else
    const libgobject = "libgobject-2.0"
    const libglib = "libglib-2.0"
end
