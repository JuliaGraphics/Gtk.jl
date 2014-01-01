using Gtk;
Clutter = Gtk._ns(:Clutter);  
Gtk.ensure_name(Clutter, :Actor); 
actor = Clutter.Actor()
@assert isa(actor,Gtk.GObject)
show(actor)

