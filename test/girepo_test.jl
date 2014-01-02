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

@gimport Gtk Window(move,set_title,get_title), Widget(show)
w = Window_new(0)
show(w) #NB: currently doesn't extend Base.show
move(w,100,100)

#string passing
set_title(w,"GI test")
@assert get_title(w) == "GI test"
