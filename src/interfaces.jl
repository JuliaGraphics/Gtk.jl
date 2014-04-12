# Interfaces for any recent Gtk version
@Giface GTypePlugin Gtk.GLib.libgobject g_type_plugin
@Giface GtkBuildable Gtk.libgtk gtk_buildable
@Giface GtkCellEditable Gtk.libgtk gtk_cell_editable
@Giface GtkCellLayout Gtk.libgtk gtk_cell_layout
@Giface GtkOrientable Gtk.libgtk gtk_orientable
@Giface GtkPrintOperationPreview Gtk.libgtk gtk_print_operation_preview
@Giface GtkRecentChooser Gtk.libgtk gtk_recent_chooser
@Giface GtkToolShell Gtk.libgtk gtk_tool_shell
@Giface GtkTreeDragDest Gtk.libgtk gtk_tree_drag_dest
@Giface GtkTreeDragSource Gtk.libgtk gtk_tree_drag_source

if gtk_version == 3
    @Giface GtkActionable Gtk.libgtk gtk_actionable
    @Giface GtkAppChooser Gtk.libgtk gtk_app_chooser
    @Giface GtkColorChooser Gtk.libgtk gtk_color_chooser
    @Giface GtkFontChooser Gtk.libgtk gtk_font_chooser
    @Giface GtkScrollable Gtk.libgtk gtk_scrollable
else
    type GtkActionable end
    GtkActionable(x...) = error("GtkActionable is not available until Gtk3")
    type GtkAppChooser end
    GtkAppChooser(x...) = error("GtkAppChooser is not available until Gtk3")
    type GtkColorChooser end
    GtkColorChooser(x...) = error("GtkColorChooser is not available until Gtk3")
    type GtkFontChooser end
    GtkFontChooser(x...) = error("GtkFontChooser is not available until Gtk3")
    type GtkScrollable end
    GtkScrollable(x...) = error("GtkScrollable is not available until Gtk3")
end

# Gtk-2
@Giface GtkActivatable Gtk.libgtk gtk_activatable
