using GI

gtk = GI.GINamespace(:Gtk)

window = gtk[:Window]
@assert isa(window, GI.GIObjectInfo)

wnew = GI.find_method(window,:new)
wmove = GI.find_method(window,:move)

args = GI.get_args(wmove)
@assert length(args) == 2

argx = args[1]
@assert GI.get_name(argx) == :x
@assert GI.extract_type(argx) == Int32

GI.ensure_name(gtk, :Window)
GI.ensure_method(gtk, :Window, :move)

@gimport Gtk init, main, Window(move,set_title,get_title), Widget(show)
init(0,C_NULL)
w = Window_new(0)
show(w) #NB: currently doesn't extend Base.show
move(w,100,100)

#string passing
set_title(w,"GI test")
@assert get_title(w) == "GI test"
main()
