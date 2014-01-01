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

_Gtk = Gtk._ns(:Gtk)
Gtk.ensure_name(_Gtk, :Window)
Gtk.ensure_method(_Gtk, :Window, :move)
Gtk.ensure_method(_Gtk, :Widget, :show)

w = _Gtk.Window(0)
_Gtk.show(w)
# bug: subtype return not implemented yet
w = _Gtk.Window(w.handle)
_Gtk.move(w,100,100)

#string passing
Gtk.ensure_method(_Gtk, :Window, :set_title)
Gtk.ensure_method(_Gtk, :Window, :get_title)
_Gtk.set_title(w,"GI test")
@assert _Gtk.get_title(w) == "GI test"
