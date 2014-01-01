using Gtk;
@gimport Clutter Actor
actor = Clutter.Actor()
display(actor)
@assert isa(actor,Gtk.GObject)

