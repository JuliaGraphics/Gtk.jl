## Tests
using Gtk.ShortNames, Gtk.GConstants, Base.Graphics

## Window
w = Window_new("Window", 400, 300)
@assert width(w) == 400
@assert height(w) == 300
@assert size(w) == (400, 300)
G_.gravity(w,10) #GRAVITY_STATIC
sleep(0.1)
pos = G_.position(w)
@assert G_.position(w) == pos
G_.position(w, 100, 100)
sleep(0.1)
@assert G_.position(w) != pos
@assert getproperty(w,"title",String) == "Window"
setproperty!(w,:title,"Window 2")
@assert getproperty(w,:title,String) == "Window 2"
destroy(w)
@assert !getproperty(w,:visible,Bool)
w=WeakRef(w)
gc(); gc(); sleep(.1); gc(); gc()
@assert w.value === nothing || w.value.handle == C_NULL

## Frame
w = Window_new(
    Frame_new(),
    "Frame", 400, 400)
@assert size(w) == (400, 400)
destroy(w)

# Labelframe
f = Frame_new("Label")
w = Window_new(f, "Labelframe", 400, 400)
setproperty!(f,:label,"new label")
@assert getproperty(f,:label,String) == "new label"
destroy(w)

## notebook
nb = Notebook_new()
w = push!(Window_new("Notebook"),nb)
push!(nb, Button_new("o_ne"), "tab _one")
push!(nb, Button_new("t_wo"), "tab _two")
push!(nb, Button_new("th_ree"), "tab t_hree")
push!(nb, "fo_ur", "tab _four")
showall(w)
@assert length(nb) == 4
setproperty!(nb,:page,2)
@assert getproperty(nb,:page,Int) == 2
destroy(w)

## Panedwindow
w = Window_new("Panedwindow", 400, 400)
pw = Paned_new(:h)
pw2 = Paned_new(:v)
push!(w, pw)
push!(pw, Button_new("one"))
push!(pw, pw2)
push!(pw2,Button_new("two"))
push!(pw2,Button_new("three"))
destroy(w)

## example of last in first covered
## Create this GUI, then shrink window with the mouse
f = Box_new(:v)
w = Window_new(f, "Last in, first covered", 400, 400)

g1 = Box_new(:h)
g2 = Box_new(:h)
push!(f,g1)
push!(f,g2)

b11 = Button_new("first")
push!(g1, b11)
b12 = Button_new("second")
push!(g1, b12)
b21 = Button_new("first")
push!(g2, b21)
b22 = Button_new("second")
push!(g2, b22)

## Iteration and toplevel
strs = ["first", "second"]
i = 1
for child in g1
    @assert getproperty(child,:label,String) == strs[i]
    @assert toplevel(child) == w
    i += 1
end
setproperty!(g1,:pack_type,b11,0) #GTK_PACK_START
setproperty!(g1,:pack_type,b12,0) #GTK_PACK_START
setproperty!(g1,:pack_type,b21,1) #GTK_PACK_END
setproperty!(g1,:pack_type,b22,1) #GTK_PACK_END

## Now shrink window
destroy(w)

## ButtonBox
bb = ButtonBox_new(:h)
w = Window_new(bb, "ButtonBox")
cancel = Button_new("Cancel")
ok = Button_new("OK")
push!(bb, cancel)
push!(bb, ok)

# Expander
delete!(w, bb)
ex = Expander_new(bb, "Some buttons")
push!(w, ex)
destroy(w)

## Grid
grid = Table_new(3,3)
w = Window_new(grid, "Grid", 400, 400)
grid[2,2] = Button_new("2,2")
grid[2,3] = Button_new("2,3")
grid[1,1] = "grid"
destroy(w)


## Widgets

## button, label
w = Window_new("Widgets")
f = Box_new(:v); push!(w,f)
l = Label_new("label"); push!(f,l)
b = Button_new("button"); push!(f,b)

setproperty!(l,:label,"new label")
@assert getproperty(l,:label,String) == "new label"
setproperty!(b,:label,"new label")
@assert getproperty(b,:label,String) == "new label"

counter = 0
id = signal_connect(b, "clicked") do widget
    global counter
    counter::Int += 1
end
# For testing callbacks
click(b::Button) = ccall((:gtk_button_clicked,Gtk.libgtk),Void,(Ptr{Gtk.GObject},),b)

@assert counter == 0
click(b)
@assert counter == 1
signal_handler_block(b, id)
click(b)
@assert counter == 1
signal_handler_unblock(b, id)
click(b)
@assert counter == 2
signal_handler_disconnect(b, id)
click(b)
@assert counter == 2

destroy(w)

## Button with custom icon (& Pixbuf)
icon = Array(Gtk.RGB, 40, 20)
fill!(icon, Gtk.RGB(0,0xff,0))
icon[5:end-5, 3:end-3] = Gtk.RGB(0,0,0xff)
b = Button_new(Image_new(Pixbuf_new(data=icon, has_alpha=false)))
w = Window_new(b, "Icon button", 60, 40)
destroy(w)

## checkbox
w = Window_new("Checkbutton")
check = CheckButton_new("check me"); push!(w,check)
setproperty!(check,:active,true)
@assert getproperty(check,:active,String) == "TRUE"
setproperty!(check,:label,"new label")
@assert getproperty(check,:label,String) == "new label"
#ctr = 0
#tk_bind(check, "command", cb)
#tcl(check, "invoke")
#@assert ctr == 1
destroy(w)

## radio
choices = ["choice one", "choice two", "choice three", RadioButton_new("choice four"), Label_new("choice five")]
w = Window_new("Radio")
f = Box_new(:v); push!(w,f)
r = Array(RadioButton,3)
r[1] = RadioButton_new(choices[1]); push!(f,r[1])
r[2] = RadioButton_new(r[1],choices[2]); push!(f,r[2])
r[3] = RadioButton_new(r[2],choices[3],active=true); push!(f,r[3])
@assert [getproperty(b,:active,Bool) for b in r] == [false, false, true]
setproperty!(r[1],:active,true)
@assert [getproperty(b,:active,Bool) for b in r] == [true, false, false]
destroy(w)

r = RadioButtonGroup_new(choices,2)
@assert length(r) == 5
@assert sum([getproperty(b,:active,Bool) for b in r]) == 1
itms = Array(Any,length(r))
for (i,e) in enumerate(r)
    itms[i] = try
            getproperty(e,:label,String)
        catch
            e[1]
        end
end
@assert setdiff(choices, itms) == [choices[4],]
@assert setdiff(itms, choices) == ["choice four",]
@assert getproperty(getproperty(r,:active),:label,String) == choices[2]
w = Window_new(r,"RadioGroup")
destroy(w)

## ToggleButton
tb = ToggleButton_new("Off")
w = Window_new(tb, "ToggleButton")
function toggled(ptr,evt,widget)
    state = getproperty(widget,:label,String)
    if state == "Off"
        setproperty!(widget,:label,"On")
    else
        setproperty!(widget,:label,"Off")
    end
    int32(true)
end
on_signal_button_press(toggled, tb)
press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(tb), 0, 0, 0, 0, C_NULL, 0, 1, C_NULL, 0, 0)
signal_emit(tb, "button-press-event", Bool, press)
release=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_RELEASE, Gtk.gdk_window(tb), 0, 0, 0, 0, C_NULL, 0, 1, C_NULL, 0, 0)
signal_emit(tb, "button-release-event", Bool, release)
## next time just use "gtk_button_clicked", mkay?
destroy(w)

## ToggleButton repeat 1
tb = ToggleButton_new("Off")
w = Window_new(tb, "ToggleButton")
on_signal_button_press(tb) do ptr, evt, widget
    state = getproperty(widget,:label,String)
    if state == "Off"
        setproperty!(widget,:label,"On")
    else
        setproperty!(widget,:label,"Off")
    end
    true
end
press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(tb), 0, 0, 0, 0, C_NULL, 0, 1, C_NULL, 0, 0)
signal_emit(tb, "button-press-event", Bool, press)
release=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_RELEASE, Gtk.gdk_window(tb), 0, 0, 0, 0, C_NULL, 0, 1, C_NULL, 0, 0)
signal_emit(tb, "button-release-event", Bool, release)
## next time just use "gtk_button_clicked", mkay?
destroy(w)

## ToggleButton repeat 2
tb = ToggleButton_new("Off")
w = Window_new(tb, "ToggleButton")
signal_connect(tb, :button_press_event) do widget, evt
    state = getproperty(widget,:label,String)
    if state == "Off"
        setproperty!(widget,:label,"On")
    else
        setproperty!(widget,:label,"Off")
    end
    true
end
press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(tb), 0, 0, 0, 0, C_NULL, 0, 1, C_NULL, 0, 0)
signal_emit(tb, "button-press-event", Bool, press)
release=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_RELEASE, Gtk.gdk_window(tb), 0, 0, 0, 0, C_NULL, 0, 1, C_NULL, 0, 0)
signal_emit(tb, "button-release-event", Bool, release)
## next time just use "gtk_button_clicked", mkay?
destroy(w)

## LinkButton
b = LinkButton_new("https://github.com/JuliaLang/Gtk.jl", "Gtk.jl")
w = Window_new(b, "LinkButton")
destroy(w)

## VolumeButton
b = VolumeButton_new(0.3)
w = Window_new(b, "VolumeButton", 50, 50)
destroy(w)

## combobox
combo = ComboBoxText_new()
choices = ["Strawberry", "Vanilla", "Chocolate"]
for c in choices
    push!(combo, c)
end
w = Window_new(combo, "ComboBoxText")
destroy(w)
combo = ComboBoxText_new(true)
for c in choices
    push!(combo, c)
end
w = Window_new(combo, "ComboBoxText with entry")
destroy(w)

## slider/scale
sl = Scale_new(true, 1:10)
w = Window_new(sl, "Scale")
G_.value(sl, 3)
@assert G_.value(sl) == 3
adj = Adjustment_new(sl)
@assert getproperty(adj,:value,Float64) == 3
setproperty!(adj,:upper,11)
destroy(w)

## spinbutton
sp = SpinButton_new(1:10)
w = Window_new(sp, "SpinButton")
G_.value(sp, 3)
@assert G_.value(sp) == 3
destroy(w)

## progressbar
pb = ProgressBar_new()
w = Window_new(pb, "Progress bar")
setproperty!(pb,:fraction,0.7)
@assert getproperty(pb,:fraction,Float64) == 0.7
destroy(w)

## spinner
s = Spinner_new()
w = Window_new(s, "Spinner")
setproperty!(s,:active,true)
@assert getproperty(s,:active,Bool) == true
setproperty!(s,:active,false)
@assert getproperty(s,:active,Bool) == false
destroy(w)

## Entry
e = Entry_new()
w = Window_new(e, "Entry")
setproperty!(e,:text,"initial")
setproperty!(e,:sensitive,false)
destroy(w)

## Statusbar
vbox = Box_new(:v)
w = Window_new(vbox, "Statusbar")
sb = Statusbar_new()
push!(vbox, sb)
ctxid = Gtk.context_id(sb, "Statusbar example")
bpush = Button_new("push item")
bpop = Button_new("pop item")
push!(vbox, bpush)
push!(vbox, bpop)
sb_count = 1
function cb_sbpush(ptr,evt,id)
    global sb_count
    push!(sb, id, string("Item ", sb_count))
    sb_count += 1
    int32(false)
end
function cb_sbpop(ptr,evt,id)
    pop!(sb, id)
    int32(false)
end
on_signal_button_press(cb_sbpush, bpush, false, ctxid)
on_signal_button_press(cb_sbpop, bpop, false, ctxid)
destroy(w)

## Canvas & AspectFrame
c = Canvas()
f = AspectFrame_new(c, "AspectFrame", 0.5, 1, 0.5)
w = Window_new(f, "Canvas")
c.draw = function(_)
    ctx = getgc(c)
    set_source_rgb(ctx, 1.0, 0.0, 0.0)
    paint(ctx)
end
destroy(w)

## Menus
file = MenuItem_new("_File")
filemenu = Menu_new(file)
new_ = MenuItem_new("New")
idnew = signal_connect(new_, :activate) do widget
    println("New!")
end
push!(filemenu, new_)
open_ = MenuItem_new("Open")
push!(filemenu, open_)
push!(filemenu, SeparatorMenuItem_new())
quit = MenuItem_new("Quit")
push!(filemenu, quit)
mb = MenuBar_new()
push!(mb, file)  # notice this is the "File" item, not filemenu
win = Window_new(mb, "Menus", 200, 40)
destroy(win)

## Popup menu
contrast = MenuItem_new("Adjust contrast...")
popupmenu = Menu_new()
push!(popupmenu, contrast)
c = Canvas()
win = Window_new(c, "Popup")
c.mouse.button3press = (widget,event) -> popup(popupmenu, event)
destroy(win)

## Text
#w = Window_new("Text")
#pack_stop_propagate(w)
#f = Frame_new(w); pack(f, {:expand=>true, :fill=>"both"})
#txt = Text(w)
#scrollbars_add(f, txt)
#set_value(txt, "new text\n")
#@assert get_value(txt) == "new text\n"
#destroy(w)

## tree. Listbox
#w = Window_new("Listbox")
#pack_stop_propagate(w)
#f = Frame_new(w); pack(f, {:expand=>true, :fill=>"both"})
#tr = Treeview(f, choices)
#scrollbars_add(f, tr)
#set_value(tr, 2)
#@assert get_value(tr)[1] == choices[2]
#set_items(tr, choices[1:2])
#destroy(w)


## tree grid
#w = Window_new("Array")
#pack_stop_propagate(w)
#f = Frame_new(w); pack(f, {:expand=>true, :fill=>"both"})
#tr = Treeview(f, hcat(choices, choices))
#tree_key_header(tr, "right"); tree_key_width(tr, 50)
#tree_headers(tr, ["left"], [50])
#scrollbars_add(f, tr)
#set_value(tr, 2)
#@assert get_value(tr)[1] == choices[2]
#destroy(w)

## Selectors
import Gtk.GtkFileChooserAction, Gtk.GtkResponseType
dlg = FileChooserDialog_new("Select file", Null_new(), GtkFileChooserAction.OPEN,
                        "_Cancel", GtkResponseType.CANCEL,
                        "_Open", GtkResponseType.ACCEPT)
destroy(dlg)

## List view
ls=ListStore_new(Int32,Bool)
push!(ls,(33,true))
tv=TreeView_new(ls)
r1=CellRendererText_new()
r2=CellRendererToggle_new()
c1=TreeViewColumn_new("A", r1,{"text" => 0})
c2=TreeViewColumn_new("B", r2,{"active" => 1})
push!(tv,c1)
push!(tv,c2)
w = Window_new(tv, "List View")
destroy(w)

## Tree view
ts=TreeStore_new(String)
iter1 = push!(ts,("one",))
iter2 = push!(ts,("two",),iter1)
iter3 = push!(ts,("three",),iter2)
tv=TreeView_new(ts)
r1=CellRendererText_new()
c1=TreeViewColumn_new("A", r1, {"text" => 0})
push!(tv,c1)
w = Window_new(tv, "Tree View")
destroy(w)

## Toolbar
tb1 = ToolButton_new("gtk-open")
tb2 = ToolButton_new("gtk-new")
tb3 = ToolButton_new("gtk-media-next")
toolbar = Toolbar_new()
push!(toolbar,tb1)
unshift!(toolbar,tb2)
push!(toolbar,tb3)
push!(toolbar,SeparatorToolItem_new(), ToggleToolButton_new("gtk-open"), MenuToolButton_new("gtk-new"))
G_.style(toolbar,GtkToolbarStyle.BOTH)
w = Window_new(toolbar, "Toolbar")
showall(w)
destroy(w)
