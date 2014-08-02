if gtk_version == 3
@gtktype GtkApplication
GtkApplicationLeaf(id::String, flags) = GtkApplicationLeaf(
    ccall((:gtk_application_new, libgtk), Ptr{GObject}, (Ptr{Uint8}, Cuint), bytestring(id), flags) )

function push!(app::GtkApplication, win::GtkWindow)
    ccall((:gtk_application_add_window, libgtk), Void, (Ptr{GObject}, Ptr{GObject}), app, win)
    app
end

function splice!(app::GtkApplication, win::GtkWindow)
    ccall((:gtk_application_remove_window, libgtk), Void, (Ptr{GObject}, Ptr{GObject}), app, win)
    app
end

set_menubar(app::GtkApplication, menubar::GObject) =
    ccall((:gtk_application_set_menubar, libgtk), Void, (Ptr{GObject}, Ptr{GObject}), app, menubar)

set_app_menu(app::GtkApplication, app_menu::GObject) =
    ccall((:gtk_application_set_app_menu, libgtk), Void, (Ptr{GObject}, Ptr{GObject}), app, app_menu)

run(app::GtkApplication) = 
    ccall((:g_application_run, libgio), Cint, (Ptr{GObject}, Cint, Ptr{Uint8}), app, 0, C_NULL)

@gtktype GtkApplicationWindow
GtkApplicationWindowLeaf(app::GtkApplication) = GtkApplicationWindowLeaf(
    ccall((:gtk_application_window_new, libgtk), Ptr{GObject}, (Ptr{GObject},), app) )
else
    type GtkApplication end
    type GtkApplicationWindow end
    GtkApplicationLeaf(x...) = error("GtkApplication is not available until Gtk3.0")
    GtkApplicationWindowLeaf(x...) = error("GtkApplicationWindow is not available until Gtk3.0")
    macro GtkApplication(args...)
        :( GtkApplicationLeaf($(args...)) )
    end
    macro GtkApplicationWindow(args...)
        :( GtkApplicationWindowLeaf($(args...)) )
    end

end
