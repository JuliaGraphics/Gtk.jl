## Tests
using Gtk.ShortNames, Gtk.GConstants, Gtk.Graphics
import Gtk.deleteat!

## Window
w = @Window("Window", 400, 300) |> showall
@assert width(w) == 400
@assert height(w) == 300
@assert size(w) == (400, 300)
G_.gravity(w,10) #GRAVITY_STATIC
sleep(0.1)
## Check Window positions
pos = G_.position(w)
if G_.position(w) != pos
    warn("The Window Manager did move the Gtk Window in show")
end
G_.position(w, 100, 100)
sleep(0.1)
if G_.position(w) == pos
    warn("The Window Manager did not move the Gtk Window when requested")
end
@assert getproperty(w, "title", AbstractString) == "Window"
setproperty!(w, :title, "Window 2")
@assert getproperty(w, :title, AbstractString) == "Window 2"
destroy(w); yield()
@assert !getproperty(w, :visible, Bool)
w=WeakRef(w)
gc(); yield(); gc()
@assert w.value === nothing

## Frame
w = @Window(
    @Frame(),
    "Frame", 400, 400)
@assert size(w) == (400, 400)
showall(w)
destroy(w)

## Initially Hidden Canvas
nb = @Notebook()
vbox = @Box(:v)
c = @Canvas()
push!(nb, vbox, "A")
push!(nb, c, "B")
w = @Window("TestDataViewer",600,600)
push!(w,nb)
showall(w)
destroy(w)

# Labelframe
f = @Frame("Label")
w = @Window(f, "Labelframe", 400, 400)
setproperty!(f,:label,"new label")
@assert getproperty(f,:label,AbstractString) == "new label"
showall(w)
destroy(w)

## notebook
nb = @Notebook()
w = push!(@Window("Notebook"),nb)
push!(nb, @Button("o_ne"), "tab _one")
push!(nb, @Button("t_wo"), "tab _two")
push!(nb, @Button("th_ree"), "tab t_hree")
push!(nb, "fo_ur", "tab _four")
showall(w)
@assert length(nb) == 4
setproperty!(nb,:page,2)
@assert getproperty(nb,:page,Int) == 2
showall(w)
destroy(w)

## Panedwindow
w = @Window("Panedwindow", 400, 400)
pw = @Paned(:h)
pw2 = @Paned(:v)
push!(w, pw)
push!(pw, @Button("one"))
push!(pw, pw2)
push!(pw2,@Button("two"))
push!(pw2,@Button("three"))
showall(w)
destroy(w)

## example of last in first covered
## Create this GUI, then shrink window with the mouse
f = @Box(:v)
w = @Window(f, "Last in, first covered", 400, 400)

g1 = @Box(:h)
g2 = @Box(:h)
push!(f,g1)
push!(f,g2)

b11 = @Button("first")
push!(g1, b11)
b12 = @Button("second")
push!(g1, b12)
b21 = @Button("first")
push!(g2, b21)
b22 = @Button("second")
push!(g2, b22)

## Iteration and toplevel
strs = ["first", "second"]
i = 1
for child in g1
    @assert getproperty(child,:label,AbstractString) == strs[i]
    @assert toplevel(child) == w
    i += 1
end
setproperty!(g1,:pack_type,b11,0) #GTK_PACK_START
setproperty!(g1,:pack_type,b12,0) #GTK_PACK_START
setproperty!(g1,:pack_type,b21,1) #GTK_PACK_END
setproperty!(g1,:pack_type,b22,1) #GTK_PACK_END

## Now shrink window
showall(w)
destroy(w)

## ButtonBox
bb = @ButtonBox(:h)
w = @Window(bb, "ButtonBox")
cancel = @Button("Cancel")
ok = @Button("OK")
push!(bb, cancel)
push!(bb, ok)

# Expander
delete!(w, bb)
ex = @Expander(bb, "Some buttons")
push!(w, ex)
showall(w)
destroy(w)

## Grid
grid = @Table(3,3)
w = @Window(grid, "Grid", 400, 400)
grid[2,2] = @Button("2,2")
grid[2,3] = @Button("2,3")
grid[1,1] = "grid"
showall(w)
destroy(w)


## Widgets

## button, label
w = @Window("Widgets")
f = @Box(:v); push!(w,f)
l = @Label("label"); push!(f,l)
b = @Button("button"); push!(f,b)

setproperty!(l,:label,"new label")
@assert getproperty(l,:label,AbstractString) == "new label"
setproperty!(b,:label,"new label")
@assert getproperty(b,:label,AbstractString) == "new label"

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
showall(w)
destroy(w)

## Button with custom icon (& Pixbuf)
icon = Array(Gtk.RGB, 40, 20)
fill!(icon, Gtk.RGB(0,0xff,0))
icon[5:end-5, 3:end-3] = Gtk.RGB(0,0,0xff)
b = @Button(@Image(@Pixbuf(data=icon, has_alpha=false)))
w = @Window(b, "Icon button", 60, 40)
showall(w)
destroy(w)

## checkbox
w = @Window("Checkbutton")
check = @CheckButton("check me"); push!(w,check)
setproperty!(check,:active,true)
@assert getproperty(check,:active,AbstractString) == "TRUE"
setproperty!(check,:label,"new label")
@assert getproperty(check,:label,AbstractString) == "new label"
#ctr = 0
#tk_bind(check, "command", cb)
#tcl(check, "invoke")
#@assert ctr == 1
showall(w)
destroy(w)

## radio
choices = ["choice one", "choice two", "choice three", @RadioButton("choice four"), @Label("choice five")]
w = @Window("Radio")
f = @Box(:v); push!(w,f)
r = Array(RadioButton,3)
r[1] = @RadioButton(choices[1]); push!(f,r[1])
r[2] = @RadioButton(r[1],choices[2]); push!(f,r[2])
r[3] = @RadioButton(r[2],choices[3],active=true); push!(f,r[3])
@assert [getproperty(b,:active,Bool) for b in r] == [false, false, true]
setproperty!(r[1],:active,true)
@assert [getproperty(b,:active,Bool) for b in r] == [true, false, false]
showall(w)
destroy(w)

r = @RadioButtonGroup(choices,2)
@assert length(r) == 5
@assert sum([getproperty(b,:active,Bool) for b in r]) == 1
itms = Array(Any,length(r))
for (i,e) in enumerate(r)
    itms[i] = try
            getproperty(e,:label,AbstractString)
        catch
            e[1]
        end
end
@assert setdiff(choices, itms) == [choices[4],]
@assert setdiff(itms, choices) == ["choice four",]
@assert getproperty(getproperty(r,:active),:label,AbstractString) == choices[2]
w = @Window(r,"RadioGroup")|>showall
destroy(w)

## ToggleButton
tb = @ToggleButton("Off")
w = @Window(tb, "ToggleButton")|>showall
function toggled(ptr,evt,widget)
    state = getproperty(widget,:label,AbstractString)
    if state == "Off"
        setproperty!(widget,:label,"On")
    else
        setproperty!(widget,:label,"Off")
    end
    convert(Int32,true)
end
on_signal_button_press(toggled, tb)
press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(tb), Int8(0), UInt32(0), 0.0, 0.0, convert(Ptr{Float64},C_NULL), UInt32(0), UInt32(1), C_NULL, 0.0, 0.0)
signal_emit(tb, "button-press-event", Bool, press)
release=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_RELEASE, Gtk.gdk_window(tb), Int8(0), UInt32(0), 0.0, 0.0, convert(Ptr{Float64},C_NULL), UInt32(0), UInt32(1), C_NULL, 0.0, 0.0)
signal_emit(tb, "button-release-event", Bool, release)
## next time just use "gtk_button_clicked", mkay?
destroy(w)

## ToggleButton repeat 1
tb = @ToggleButton("Off")
w = @Window(tb, "ToggleButton")|>showall
# TODO: uncomment these next lines
on_signal_button_press(tb) do ptr, evt, widget
    state = getproperty(widget,:label,AbstractString)
    if state == "Off"
        setproperty!(widget,:label,"On")
    else
        setproperty!(widget,:label,"Off")
    end
    Int32(true)
end
press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(tb), Int8(0), UInt32(0), 0.0, 0.0, convert(Ptr{Float64},C_NULL), UInt32(0), UInt32(1), C_NULL, 0.0, 0.0)
signal_emit(tb, "button-press-event", Bool, press)
release=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_RELEASE, Gtk.gdk_window(tb), Int8(0), UInt32(0), 0.0, 0.0, convert(Ptr{Float64},C_NULL), UInt32(0), UInt32(1), C_NULL, 0.0, 0.0)
signal_emit(tb, "button-release-event", Bool, release)
# next time just use "gtk_button_clicked", mkay?
destroy(w)

## ToggleButton repeat 2
tb = @ToggleButton("Off")
w = @Window(tb, "ToggleButton")|>showall
signal_connect(tb, :button_press_event) do widget, evt
    state = getproperty(widget,:label,AbstractString)
    if state == "Off"
        setproperty!(widget,:label,"On")
    else
        setproperty!(widget,:label,"Off")
    end
    Int32(true)
end
press=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(tb), Int8(0), UInt32(0), 0.0, 0.0, convert(Ptr{Float64},C_NULL), UInt32(0), UInt32(1), C_NULL, 0.0, 0.0)
signal_emit(tb, "button-press-event", Bool, press)
release=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_RELEASE, Gtk.gdk_window(tb), Int8(0), UInt32(0), 0.0, 0.0, convert(Ptr{Float64},C_NULL), UInt32(0), UInt32(1), C_NULL, 0.0, 0.0)
signal_emit(tb, "button-release-event", Bool, release)
## next time just use "gtk_button_clicked", mkay?
destroy(w)

## LinkButton
b = @LinkButton("https://github.com/JuliaLang/Gtk.jl", "Gtk.jl")
w = @Window(b, "LinkButton")|>showall
destroy(w)

## VolumeButton
b = @VolumeButton(0.3)
w = @Window(b, "VolumeButton", 50, 50)|>showall
destroy(w)

## combobox
combo = @ComboBoxText()
choices = ["Strawberry", "Vanilla", "Chocolate"]
for c in choices
    push!(combo, c)
end
w = @Window(combo, "ComboBoxText")|>showall
lsl = ListStoreLeaf(combo)
@assert length(lsl) == 3
empty!(combo)
@assert length(lsl) == 0
destroy(w)

combo = @ComboBoxText(true)
for c in choices
    push!(combo, c)
end
w = @Window(combo, "ComboBoxText with entry")|>showall
destroy(w)

## slider/scale
sl = @Scale(true, 1:10)
w = @Window(sl, "Scale")|>showall
G_.value(sl, 3)
@assert G_.value(sl) == 3
adj = @Adjustment(sl)
@assert getproperty(adj,:value,Float64) == 3
setproperty!(adj,:upper,11)
destroy(w)

## spinbutton
sp = @SpinButton(1:10)
w = @Window(sp, "SpinButton")|>showall
G_.value(sp, 3)
@assert G_.value(sp) == 3
destroy(w)

## progressbar
pb = @ProgressBar()
w = @Window(pb, "Progress bar")|>showall
setproperty!(pb,:fraction,0.7)
@assert getproperty(pb,:fraction,Float64) == 0.7
destroy(w)

## spinner
s = @Spinner()
w = @Window(s, "Spinner")|>showall
setproperty!(s,:active,true)
@assert getproperty(s,:active,Bool) == true
setproperty!(s,:active,false)
@assert getproperty(s,:active,Bool) == false
destroy(w)

## Entry
e = @Entry()
w = @Window(e, "Entry")|>showall
setproperty!(e,:text,"initial")
setproperty!(e,:sensitive,false)

activated = false
signal_connect(e, :activate) do widget
    global activated
    activated = true
end
signal_emit(e, :activate, Void)
@assert activated

destroy(w)

## Statusbar
vbox = @Box(:v)
w = @Window(vbox, "Statusbar")
sb = @Statusbar()
push!(vbox, sb)
ctxid = Gtk.context_id(sb, "Statusbar example")
bpush = @Button("push item")
bpop = @Button("pop item")
push!(vbox, bpush)
push!(vbox, bpop)
showall(w)
sb_count = 1
function cb_sbpush(ptr,evt,id)
    global sb_count
    push!(sb, id, string("Item ", sb_count))
    sb_count += 1
    convert(Int32,false)
end
function cb_sbpop(ptr,evt,id)
    pop!(sb, id)
    convert(Int32,false)
end
on_signal_button_press(cb_sbpush, bpush, false, ctxid)
on_signal_button_press(cb_sbpop, bpop, false, ctxid)
destroy(w)

## Canvas & AspectFrame
c = Canvas()
f = @AspectFrame(c, "AspectFrame", 0.5, 1, 0.5)
w = @Window(f, "Canvas")|>showall
c.draw = function(_)
    ctx = getgc(c)
    set_source_rgb(ctx, 1.0, 0.0, 0.0)
    paint(ctx)
end
draw(c)
destroy(w)

## Menus
file = @MenuItem("_File")
filemenu = @Menu(file)
new_ = @MenuItem("New")
idnew = signal_connect(new_, :activate) do widget
    println("New!")
end
push!(filemenu, new_)
open_ = @MenuItem("Open")
push!(filemenu, open_)
push!(filemenu, @SeparatorMenuItem())
quit = @MenuItem("Quit")
push!(filemenu, quit)
mb = @MenuBar()
push!(mb, file)  # notice this is the "File" item, not filemenu
win = @Window(mb, "Menus", 200, 40)|>showall
destroy(win)

## Popup menu
contrast = @MenuItem("Adjust contrast...")
popupmenu = @Menu()
push!(popupmenu, contrast)
c = Canvas()
win = @Window(c, "Popup")|>showall
showall(popupmenu)
c.mouse.button3press = (widget,event) -> popup(popupmenu, event)
destroy(win)

## Text
#w = @Window("Text")
#pack_stop_propagate(w)
#f = @Frame(w); pack(f, {:expand=>true, :fill=>"both"})
#txt = Text(w)
#scrollbars_add(f, txt)
#set_value(txt, "new text\n")
#@assert get_value(txt) == "new text\n"
#destroy(w)

## tree. Listbox
#w = @Window("Listbox")
#pack_stop_propagate(w)
#f = @Frame(w); pack(f, {:expand=>true, :fill=>"both"})
#tr = Treeview(f, choices)
#scrollbars_add(f, tr)
#set_value(tr, 2)
#@assert get_value(tr)[1] == choices[2]
#set_items(tr, choices[1:2])
#destroy(w)


## tree grid
#w = @Window("Array")
#pack_stop_propagate(w)
#f = @Frame(w); pack(f, {:expand=>true, :fill=>"both"})
#tr = Treeview(f, hcat(choices, choices))
#tree_key_header(tr, "right"); tree_key_width(tr, 50)
#tree_headers(tr, ["left"], [50])
#scrollbars_add(f, tr)
#set_value(tr, 2)
#@assert get_value(tr)[1] == choices[2]
#destroy(w)

## Selectors
import Gtk.GtkFileChooserAction, Gtk.GtkResponseType
dlg = @FileChooserDialog("Select file", @Null(), GtkFileChooserAction.OPEN,
                        (("_Cancel", GtkResponseType.CANCEL),
                         ("_Open", GtkResponseType.ACCEPT)))
destroy(dlg)

## List view
ls=@ListStore(Int32,Bool)
push!(ls,(33,true))
push!(ls,(44,true))
insert!(ls, 2, (35, false))
tv=@TreeView(TreeModel(ls))
r1=@CellRendererText()
r2=@CellRendererToggle()
c1=@TreeViewColumn("A", r1, Dict([("text",0)]))
c2=@TreeViewColumn("B", r2, Dict([("active",1)]))
push!(tv,c1)
push!(tv,c2)
w = @Window(tv, "List View")|>showall


## selection
selmodel = Gtk.G_.selection(tv)
@assert hasselection(selmodel) == false
select!(selmodel, Gtk.iter_from_index(ls, 1))
@assert hasselection(selmodel) == true
iter = selected(selmodel)
@assert ls[iter, 1] == 33
deleteat!(ls, iter)
@assert isvalid(ls, iter) == false

destroy(w)


## Tree view
ts=@TreeStore(AbstractString)
iter1 = push!(ts,("one",))
iter2 = push!(ts,("two",),iter1)
iter3 = push!(ts,("three",),iter2)
tv=@TreeView(TreeModel(ts))
r1=@CellRendererText()
c1=@TreeViewColumn("A", r1, Dict([("text",0)]))
push!(tv,c1)
w = @Window(tv, "Tree View")|>showall


iter = Gtk.iter_from_index(ts, [1])
ts[iter,1] = "ONE"
@assert ts[iter,1] == "ONE"
@assert map(i -> ts[i, 1], Gtk.TreeIterator(ts, iter)) == ["two", "three"]

destroy(w)

## Toolbar
import Gtk.GtkToolbarStyle
tb1 = @ToolButton("gtk-open")
tb2 = @ToolButton("gtk-new")
tb3 = @ToolButton("gtk-media-next")
toolbar = @Toolbar()
push!(toolbar,tb1)
unshift!(toolbar,tb2)
push!(toolbar,tb3)
push!(toolbar,@SeparatorToolItem(), @ToggleToolButton("gtk-open"), @MenuToolButton("gtk-new"))
G_.style(toolbar,GtkToolbarStyle.BOTH)
w = @Window(toolbar, "Toolbar")|>showall
destroy(w)

# Canvas mouse callback stack operations
c = @Canvas()
w = @Window(c)
showall(w)
io = IOBuffer()
c.mouse.button1press = (widget,evt) -> println(io, "cb1_1")
c.mouse.button2press = (widget,evt) -> println(io, "cb2_1")
press1=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(c), Int8(0), UInt32(0), 0.0, 0.0, convert(Ptr{Float64},C_NULL), UInt32(0), UInt32(1), C_NULL, 0.0, 0.0)
press2=Gtk.GdkEventButton(Gtk.GdkEventType.BUTTON_PRESS, Gtk.gdk_window(c), Int8(0), UInt32(0), 0.0, 0.0, convert(Ptr{Float64},C_NULL), UInt32(0), UInt32(2), C_NULL, 0.0, 0.0)
signal_emit(c, "button-press-event", Bool, press1)
signal_emit(c, "button-press-event", Bool, press2)
push!((c.mouse,:button1press), (widget,evt) -> println(io, "cb1_2"))
signal_emit(c, "button-press-event", Bool, press1)
signal_emit(c, "button-press-event", Bool, press2)
push!((c.mouse,:button2press), (widget,evt) -> println(io, "cb2_2"))
signal_emit(c, "button-press-event", Bool, press1)
signal_emit(c, "button-press-event", Bool, press2)
pop!((c.mouse,:button1press))
signal_emit(c, "button-press-event", Bool, press1)
signal_emit(c, "button-press-event", Bool, press2)
str = takebuf_string(io)
@assert str == "cb1_1\ncb2_1\ncb1_2\ncb2_1\ncb1_2\ncb2_2\ncb1_1\ncb2_2\n"

c.mouse.scroll = (widget,event) -> println(io, "scrolling")
scroll = Gtk.GdkEventScroll(Gtk.GdkEventType.SCROLL, Gtk.gdk_window(c), Int8(0), UInt32(0), 0.0, 0.0, UInt32(0), Gtk.GdkScrollDirection.UP, convert(Ptr{Float64},C_NULL), 0.0, 0.0, 0.0, 0.0)
signal_emit(c, "scroll-event", Bool, scroll)
str = takebuf_string(io)
@assert str == "scrolling\n"

destroy(w)

# CSS

## CssProviderLeaf(filename="...")

style_file = joinpath(dirname(Base.source_path()), "style_test.css")

l = @Label "I am some large blue text!"
w = @Window(l)

screen   = Gtk.GAccessor.screen(w)
provider = CssProviderLeaf(filename=style_file)

ccall((:gtk_style_context_add_provider_for_screen, Gtk.libgtk), Void,
      (Ptr{Void}, Ptr{GObject}, Cuint),
      screen, provider, 1)

showall(w)

### add css tests here

destroy(w)
