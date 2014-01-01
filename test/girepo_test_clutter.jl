using Gtk;

c = Gtk.GINamespace(:Clutter)
act = c[:Actor]
act_new = act[:new]
actor = Gtk.test_call(act_new)
@assert isa(actor,g.GObject)
show(actor)

