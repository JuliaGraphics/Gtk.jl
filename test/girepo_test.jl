using Gtk;

gtk = Gtk.GINamespace(:Gtk)

window = gtk[:Window]

@assert isa(window, Gtk.GIObjectInfo)

meths = Gtk.get_methods(window)

mmove =  meths[find([Gtk.get_name(m) == :move for m in meths])]
@assert length(mmove) == 1
move = mmove[1]

args = Gtk.get_args(move)

@assert length(args) == 2
