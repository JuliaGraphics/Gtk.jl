using Gtk.ShortNames
using Dates

b = Box(:v)
win = Window(b,"test")
ent = Entry()
push!(b,ent)

button = Button("ok")
push!(b,button)
Gtk.showall(win)

function update_(::Timer)
  #Gtk.@sigatom begin
    set_gtk_property!(ent, :text, "$(Dates.now())")
  #end
end
timer = Timer(update_, 0.0, interval=0.1)

signal_connect(button, "clicked") do widget
  #Gtk.@sigatom begin
    set_gtk_property!(button, :label, "$(rand(1:10))")
    Core.println("test")
    #sleep(1.0)
  #end
end
