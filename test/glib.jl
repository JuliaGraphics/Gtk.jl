using Gtk, Gtk.GLib

@testset "glib" begin

ccall((:gtk_init, Gtk.libgtk), Nothing,(Ptr{Nothing},Ptr{Nothing}),C_NULL,C_NULL)

hnd = ccall((:gtk_window_new, Gtk.libgtk),Ptr{GObject},(Cint,),0)

wrap = convert(GObject, hnd)
#detect type and create wrapper (if neccessary) at runtime
@test isa(wrap, GtkWindowLeaf)

wrap2 = convert(GObject, hnd)
@test wrap == wrap2

repr = Base.print_to_string(wrap) #should display properties
@test endswith(repr,')')
@test occursin("name=\"\"",repr)
@test occursin("visible=FALSE",repr)
@test occursin("title=NULL",repr)
@test occursin("type=GTK_WINDOW_TOPLEVEL",repr)

@test isa(convert(Gtk.GLib.GBoxedUnkown, Gtk.GLib.GBoxedUnkown(C_NULL)), Gtk.GLib.GBoxedUnkown)

x=[1]
function g_timeout_add_cb(user_data)
    x = unsafe_pointer_to_objref(user_data)
    x[1] = 2
    Cint(false)
end
Gtk.GLib.g_timeout_add(1,g_timeout_add_cb, x)
sleep(10/1000)
@test x[1] == 2

x=[1]
Gtk.GLib.g_idle_add(g_timeout_add_cb, x)
sleep(10/1000)
@test x[1] == 2

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
