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

x = Ref{Int}(1)

function g_timeout_add_cb()
    x[] = 2
    false
end

g_idle_add(g_timeout_add_cb)
sleep(0.5)
@test x[] == 2

x[] = 1 #reset
g_timeout_add(g_timeout_add_cb, 1)
sleep(0.5)
@test x[] == 2

# do syntax

x[] = 1 #reset
g_idle_add() do
  x[] = 2
  return false # only call once
end
sleep(0.5)
@test x[] == 2

x[] = 1 #reset
g_timeout_add(1) do
  x[] = 2
  return false # only call once
end
sleep(0.5)
@test x[] == 2

# macro syntax

x[] = 1 #reset
@idle_add begin
  x[] = 2
end
sleep(0.5)
@test x[] == 2

# deprecated

function g_timeout_add_cb(user_data)
    user_data[] = 2
    false
end

x[] = 1 #reset
g_idle_add(()->g_timeout_add_cb(x))
sleep(0.5)
@test x[] == 2

x[] = 1 #reset
g_timeout_add(()->g_timeout_add_cb(x), 1)
sleep(0.5)
@test x[] == 2

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
