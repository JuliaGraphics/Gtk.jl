using Gtk, Gtk.GLib

ccall((:gtk_init, Gtk.libgtk), Void,(Ptr{Void},Ptr{Void}),C_NULL,C_NULL)

hnd = ccall((:gtk_window_new, Gtk.libgtk),Ptr{GObject},(Cint,),0)

wrap = convert(GObject, hnd)
#detect type and create wrapper (if neccessary) at runtime
@assert string(typeof(wrap)) == "GtkWindowLeaf"

wrap2 = convert(GObject, hnd)
@assert wrap == wrap2

repr = Base.print_to_string(wrap) #should display properties
@assert beginswith(repr,"GtkWindowLeaf(")
@assert endswith(repr,')')
@assert contains(repr,"name=\"\"")
@assert contains(repr,"visible=FALSE")
@assert contains(repr,"title=NULL")
@assert contains(repr,"type=GTK_WINDOW_TOPLEVEL")

module Test
    import Gtk
    using Gtk.GLib
    const suffix = :Test
    @Gtype GtkWidget Gtk.libgtk gtk_widget
end

@assert Test.GtkWidgetTest != Gtk.GtkWidgetLeaf
@assert Test.GtkWidget == Gtk.GtkWidget
nothing
