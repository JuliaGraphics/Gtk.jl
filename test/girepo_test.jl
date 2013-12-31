using Gtk;

gtk = Gtk.GINamespace(:Gtk)

window = gtk[:Window]
@assert isa(window, Gtk.GIObjectInfo)

move = Gtk.find_method(window,:move)

args = Gtk.get_args(move)
@assert length(args) == 2

argx = args[1]
@assert Gtk.get_name(argx) == :x
@assert Gtk.extract_type(argx) == Int16 
