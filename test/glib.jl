using Gtk, Gtk.GLib

@testset "glib" begin

ccall((:gtk_init, Gtk.libgtk), Void,(Ptr{Void},Ptr{Void}),C_NULL,C_NULL)

hnd = ccall((:gtk_window_new, Gtk.libgtk),Ptr{GObject},(Cint,),0)

wrap = convert(GObject, hnd)
#detect type and create wrapper (if neccessary) at runtime
@test isa(wrap, GtkWindowLeaf)

wrap2 = convert(GObject, hnd)
@test wrap == wrap2

repr = Base.print_to_string(wrap) #should display properties
@test endswith(repr,')')
@test contains(repr,"name=\"\"")
@test contains(repr,"visible=FALSE")
@test contains(repr,"title=NULL")
@test contains(repr,"type=GTK_WINDOW_TOPLEVEL")

@test isa(convert(Gtk.GLib.GBoxedUnkown, Gtk.GLib.GBoxedUnkown(C_NULL)), Gtk.GLib.GBoxedUnkown)

end

# TODO
# module Test2   ### fails inside @testset
#     import Gtk
#     using Gtk.GLib
#     const suffix = :Test2
#     @Gtype GtkWidget Gtk.libgtk gtk_widget
# end
#
# @test Test2.GtkWidgetTest2 != Gtk.GtkWidgetLeaf
# @test Test2.GtkWidget == Gtk.GtkWidget
# nothing
