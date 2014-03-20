## Tests
using Gtk.ShortNames, Gtk.GConstants, Base.Graphics

## Window
w = WindowLeaf("Window", 400, 300)
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
w = WindowLeaf(
    FrameLeaf(),
    "Frame", 400, 400)
@assert size(w) == (400, 400)
destroy(w)

# Labelframe
f = FrameLeaf("Label")
w = WindowLeaf(f, "Labelframe", 400, 400)
setproperty!(f,:label,"new label")
@assert getproperty(f,:label,String) == "new label"
destroy(w)

## notebook
nb = NotebookLeaf()
w = push!(WindowLeaf("Notebook"),nb)
push!(nb, ButtonLeaf("o_ne"), "tab _one")
push!(nb, ButtonLeaf("t_wo"), "tab _two")
push!(nb, ButtonLeaf("th_ree"), "tab t_hree")
push!(nb, "fo_ur", "tab _four")
showall(w)
@assert length(nb) == 4
setproperty!(nb,:page,2)
@assert getproperty(nb,:page,Int) == 2
destroy(w)

## Panedwindow
w = WindowLeaf("Panedwindow", 400, 400)
pw = PanedLeaf(:h)
pw2 = PanedLeaf(:v)
push!(w, pw)
push!(pw, ButtonLeaf("one"))
push!(pw, pw2)
push!(pw2,ButtonLeaf("two"))
push!(pw2,ButtonLeaf("three"))
destroy(w)

## example of last in first covered
## Create this GUI, then shrink window with the mouse
f = BoxLeaf(:v)
w = WindowLeaf(f, "Last in, first covered", 400, 400)

g1 = BoxLeaf(:h)
g2 = BoxLeaf(:h)
push!(f,g1)
push!(f,g2)

b11 = ButtonLeaf("first")
push!(g1, b11)
b12 = ButtonLeaf("second")
push!(g1, b12)
b21 = ButtonLeaf("first")
push!(g2, b21)
b22 = ButtonLeaf("second")
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
bb = ButtonBoxLeaf(:h)
w = WindowLeaf(bb, "ButtonBox")
cancel = ButtonLeaf("Cancel")
ok = ButtonLeaf("OK")
push!(bb, cancel)
push!(bb, ok)

# Expander
delete!(w, bb)
ex = ExpanderLeaf(bb, "Some buttons")
push!(w, ex)
destroy(w)

## Grid
grid = TableLeaf(3,3)
w = WindowLeaf(grid, "Grid", 400, 400)
grid[2,2] = ButtonLeaf("2,2")
grid[2,3] = ButtonLeaf("2,3")
grid[1,1] = "grid"
destroy(w)


## Widgets

## button, label
w = WindowLeaf("Widgets")
f = BoxLeaf(:v); push!(w,f)
l = LabelLeaf("label"); push!(f,l)
b = ButtonLeaf("button"); push!(f,b)

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
b = ButtonLeaf(ImageLeaf(PixbufLeaf(data=icon, has_alpha=false)))
w = WindowLeaf(b, "Icon button", 60, 40)
destroy(w)

## checkbox
w = WindowLeaf("Checkbutton")
check = CheckButtonLeaf("check me"); push!(w,check)
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
choices = ["choice one", "choice two", "choice three", RadioButtonLeaf("choice four"), LabelLeaf("choice five")]
w = WindowLeaf("Radio")
f = BoxLeaf(:v); push!(w,f)
r = Array(RadioButton,3)
r[1] = RadioButtonLeaf(choices[1]); push!(f,r[1])
r[2] = RadioButtonLeaf(r[1],choices[2]); push!(f,r[2])
r[3] = RadioButtonLeaf(r[2],choices[3],active=true); push!(f,r[3])
@assert [getproperty(b,:active,Bool) for b in r] == [false, false, true]
setproperty!(r[1],:active,true)
@assert [getproperty(b,:active,Bool) for b in r] == [true, false, false]
destroy(w)

r = RadioButtonGroupLeaf(choices,2)
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
w = WindowLeaf(r,"RadioGroup")
destroy(w)

## ToggleButton
tb = ToggleButtonLeaf("Off")
w = WindowLeaf(tb, "ToggleButton")
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
tb = ToggleButtonLeaf("Off")
w = WindowLeaf(tb, "ToggleButton")
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
tb = ToggleButtonLeaf("Off")
w = WindowLeaf(tb, "ToggleButton")
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
b = LinkButtonLeaf("https://github.com/JuliaLang/Gtk.jl", "Gtk.jl")
w = WindowLeaf(b, "LinkButton")
destroy(w)

## VolumeButton
b = VolumeButtonLeaf(0.3)
w = WindowLeaf(b, "VolumeButton", 50, 50)
destroy(w)

## combobox
combo = ComboBoxTextLeaf()
choices = ["Strawberry", "Vanilla", "Chocolate"]
for c in choices
    push!(combo, c)
end
w = WindowLeaf(combo, "ComboBoxText")
destroy(w)
combo = ComboBoxTextLeaf(true)
for c in choices
    push!(combo, c)
end
w = WindowLeaf(combo, "ComboBoxText with entry")
destroy(w)

## slider/scale
sl = ScaleLeaf(true, 1:10)
w = WindowLeaf(sl, "Scale")
G_.value(sl, 3)
@assert G_.value(sl) == 3
adj = AdjustmentLeaf(sl)
@assert getproperty(adj,:value,Float64) == 3
setproperty!(adj,:upper,11)
destroy(w)

## spinbutton
sp = SpinButtonLeaf(1:10)
w = WindowLeaf(sp, "SpinButton")
G_.value(sp, 3)
@assert G_.value(sp) == 3
destroy(w)

## progressbar
pb = ProgressBarLeaf()
w = WindowLeaf(pb, "Progress bar")
setproperty!(pb,:fraction,0.7)
@assert getproperty(pb,:fraction,Float64) == 0.7
destroy(w)

## spinner
s = SpinnerLeaf()
w = WindowLeaf(s, "Spinner")
setproperty!(s,:active,true)
@assert getproperty(s,:active,Bool) == true
setproperty!(s,:active,false)
@assert getproperty(s,:active,Bool) == false
destroy(w)

## Entry
e = EntryLeaf()
w = WindowLeaf(e, "Entry")
setproperty!(e,:text,"initial")
setproperty!(e,:sensitive,false)
destroy(w)

## Statusbar
vbox = BoxLeaf(:v)
w = WindowLeaf(vbox, "Statusbar")
sb = StatusbarLeaf()
push!(vbox, sb)
ctxid = Gtk.context_id(sb, "Statusbar example")
bpush = ButtonLeaf("push item")
bpop = ButtonLeaf("pop item")
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
f = AspectFrameLeaf(c, "AspectFrame", 0.5, 1, 0.5)
w = WindowLeaf(f, "Canvas")
c.draw = function(_)
    ctx = getgc(c)
    set_source_rgb(ctx, 1.0, 0.0, 0.0)
    paint(ctx)
end
destroy(w)

## Menus
file = MenuItemLeaf("_File")
filemenu = MenuLeaf(file)
new_ = MenuItemLeaf("New")
idnew = signal_connect(new_, :activate) do widget
    println("New!")
end
push!(filemenu, new_)
open_ = MenuItemLeaf("Open")
push!(filemenu, open_)
push!(filemenu, SeparatorMenuItemLeaf())
quit = MenuItemLeaf("Quit")
push!(filemenu, quit)
mb = MenuBarLeaf()
push!(mb, file)  # notice this is the "File" item, not filemenu
win = WindowLeaf(mb, "Menus", 200, 40)
destroy(win)

## Popup menu
contrast = MenuItemLeaf("Adjust contrast...")
popupmenu = MenuLeaf()
push!(popupmenu, contrast)
c = Canvas()
win = WindowLeaf(c, "Popup")
c.mouse.button3press = (widget,event) -> popup(popupmenu, event)
destroy(win)

## Text
#w = WindowLeaf("Text")
#pack_stop_propagate(w)
#f = FrameLeaf(w); pack(f, {:expand=>true, :fill=>"both"})
#txt = Text(w)
#scrollbars_add(f, txt)
#set_value(txt, "new text\n")
#@assert get_value(txt) == "new text\n"
#destroy(w)

## tree. Listbox
#w = WindowLeaf("Listbox")
#pack_stop_propagate(w)
#f = FrameLeaf(w); pack(f, {:expand=>true, :fill=>"both"})
#tr = Treeview(f, choices)
#scrollbars_add(f, tr)
#set_value(tr, 2)
#@assert get_value(tr)[1] == choices[2]
#set_items(tr, choices[1:2])
#destroy(w)


## tree grid
#w = WindowLeaf("Array")
#pack_stop_propagate(w)
#f = FrameLeaf(w); pack(f, {:expand=>true, :fill=>"both"})
#tr = Treeview(f, hcat(choices, choices))
#tree_key_header(tr, "right"); tree_key_width(tr, 50)
#tree_headers(tr, ["left"], [50])
#scrollbars_add(f, tr)
#set_value(tr, 2)
#@assert get_value(tr)[1] == choices[2]
#destroy(w)

## Selectors
import Gtk.GtkFileChooserAction, Gtk.GtkResponseType
dlg = FileChooserDialogLeaf("Select file", NullLeaf(), GtkFileChooserAction.OPEN,
                        "_Cancel", GtkResponseType.CANCEL,
                        "_Open", GtkResponseType.ACCEPT)
destroy(dlg)

## List view
ls=ListStoreLeaf(Int32,Bool)
push!(ls,(33,true))
tv=TreeViewLeaf(ls)
r1=CellRendererTextLeaf()
r2=CellRendererToggleLeaf()
c1=TreeViewColumnLeaf("A", r1,{"text" => 0})
c2=TreeViewColumnLeaf("B", r2,{"active" => 1})
push!(tv,c1)
push!(tv,c2)
w = WindowLeaf(tv, "List View")
destroy(w)

## Tree view
ts=TreeStoreLeaf(String)
iter1 = push!(ts,("one",))
iter2 = push!(ts,("two",),iter1)
iter3 = push!(ts,("three",),iter2)
tv=TreeViewLeaf(ts)
r1=CellRendererTextLeaf()
c1=TreeViewColumnLeaf("A", r1, {"text" => 0})
push!(tv,c1)
w = WindowLeaf(tv, "Tree View")
destroy(w)

## Toolbar
tb1 = ToolButtonLeaf("gtk-open")
tb2 = ToolButtonLeaf("gtk-new")
tb3 = ToolButtonLeaf("gtk-media-next")
toolbar = ToolbarLeaf()
push!(toolbar,tb1)
unshift!(toolbar,tb2)
push!(toolbar,tb3)
push!(toolbar,SeparatorToolItemLeaf(), ToggleToolButtonLeaf("gtk-open"), MenuToolButtonLeaf("gtk-new"))
G_.style(toolbar,GtkToolbarStyle.BOTH)
w = WindowLeaf(toolbar, "Toolbar")
showall(w)
destroy(w)
