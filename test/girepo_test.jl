using Gtk;

gtk = Gtk.GINamespace(:Gtk)

window = gtk[:Window]
@assert isa(window, Gtk.GIObjectInfo)

wnew = Gtk.find_method(window,:new)
move = Gtk.find_method(window,:move)

args = Gtk.get_args(move)
@assert length(args) == 2

argx = args[1]
@assert Gtk.get_name(argx) == :x
@assert Gtk.extract_type(argx) == Int32

window = Gtk.test_call(wnew, 0)

wshow = Gtk.find_method(gtk[:Widget], :show)

Gtk.test_call(wshow, window)
