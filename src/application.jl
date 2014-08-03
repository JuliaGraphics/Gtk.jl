if gtk_version == 3

@Giface GAction Gtk.libgio g_action
@Giface GActionGroup Gtk.libgio g_action_group

### GActionMap ###

@Giface GActionMap Gtk.libgio g_action_map

push!(action_map::GActionMap, action::GAction) = 
  ccall((:g_action_map_add_action, libgio), Void, (Ptr{GObject}, Ptr{GObject}), action_map, action)

### GApplication

@Gtype GApplication Gtk.libgio g_application

### GSimpleAction ###

@Gtype GSimpleAction Gtk.libgio g_simple_action
GSimpleActionLeaf(name::String) = GSimpleActionLeaf(
  ccall((:g_simple_action_new, libgio), Ptr{GObject}, (Ptr{Uint8}, Ptr{Void}), bytestring(name), C_NULL) )
  


### GtkApplication ###

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

add_accelerator(app::GtkApplication, accelerator::String, action_name::String, parameter=C_NULL) =
    ccall((:gtk_application_add_accelerator, libgtk), Void, (Ptr{GObject}, Ptr{Uint8}, Ptr{Uint8}, Ptr{Uint8}), 
           app, bytestring(accelerator), bytestring(action_name), parameter)


remove_accelerator(app::GtkApplication, action_name::String, parameter=C_NULL) =
    ccall((:gtk_application_remove_accelerator, libgtk), Void, (Ptr{GObject}, Ptr{Uint8}, Ptr{Uint8}), 
           bytestring(action_name), parameter)

set_menubar(app::GtkApplication, menubar::GObject) =
    ccall((:gtk_application_set_menubar, libgtk), Void, (Ptr{GObject}, Ptr{GObject}), app, menubar)

set_app_menu(app::GtkApplication, app_menu::GObject) =
    ccall((:gtk_application_set_app_menu, libgtk), Void, (Ptr{GObject}, Ptr{GObject}), app, app_menu)

run(app::GtkApplication) = 
    ccall((:g_application_run, libgio), Cint, (Ptr{GObject}, Cint, Ptr{Uint8}), app, 0, C_NULL)

### GtkApplicationWindow ###

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
