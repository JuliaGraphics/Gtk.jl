using Gtk;
@gimport Clutter Actor
actor = Clutter.Actor_new()
display(actor)
@assert isa(actor,Gtk.GObject)
@assert isa(actor,Clutter.Actor)

