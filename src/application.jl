if libgtk_version >= v"3"
    GtkApplicationLeaf(id::AbstractString, flags) = GtkApplicationLeaf(
        ccall((:gtk_application_new, libgtk), Ptr{GObject}, (Ptr{UInt8}, Cuint), bytestring(id), flags) )

    function push!(app::GtkApplication, win::GtkWindow)
        ccall((:gtk_application_add_window, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}), app, win)
        app
    end

    function splice!(app::GtkApplication, win::GtkWindow)
        ccall((:gtk_application_remove_window, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}), app, win)
        app
    end

    app_menu(app::GtkApplication, app_menu::GObject) =
        ccall((:gtk_application_new, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}), app, app_menu)

    GtkApplicationWindowLeaf(app::GtkApplication) = GtkApplicationWindowLeaf(
        ccall((:gtk_application_window_new, libgtk), Ptr{GObject}, (Ptr{GObject},), app) )
end
