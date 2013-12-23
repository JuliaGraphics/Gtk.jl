## Tests
using Gtk.ShortNames

## Window
w = Window("Window", 400, 400)
G_.gravity(w,10) #GDK_GRAVITY_STATIC
G_.position(w, 100, 100)
# @assert G_.position(w) == (100,100)    # for some reason this often fails (though it works interactively)
@assert w["title",String] == "Window"
w[:title] = "Window 2"
@assert w[:title,String] == "Window 2"
@assert size(w) == (400, 400)
destroy(w)
@assert !w[:visible,Bool]
w=WeakRef(w)
gc(); gc(); sleep(.1); gc()
@assert w.value.handle == C_NULL

## Frame
w = Window(
    Frame(),
    "Frame", 400, 400)
@assert size(w) == (400, 400)
destroy(w)

# Labelframe
f = Frame("Label")
w = Window(f, "Labelframe", 400, 400)
f[:label] = "new label"
@assert f[:label,String] == "new label"
destroy(w)

## notebook
nb = Notebook()
w = push!(Window("Notebook"),nb)
push!(nb, Button("o_ne"), "tab _one")
push!(nb, Button("t_wo"), "tab _two")
push!(nb, Button("th_ree"), "tab t_hree")
push!(nb, "fo_ur", "tab _four")
showall(w)
@assert length(nb) == 4
nb[:page] = 2
@assert nb[:page,Int] == 2
destroy(w)

## Panedwindow
w = Window("Panedwindow", 400, 400)
pw = Paned(:h)
pw2 = Paned(:v)
push!(w, pw)
push!(pw, Button("one"))
push!(pw, pw2)
push!(pw2,Button("two"))
push!(pw2,Button("three"))
destroy(w)

## example of last in first covered
## Create this GUI, then shrink window with the mouse
f = BoxLayout(:v)
w = Window(f, "Last in, first covered", 400, 400)

g1 = BoxLayout(:h)
g2 = BoxLayout(:h)
push!(f,g1)
push!(f,g2)

b11 = Button("first")
push!(g1, b11)
b12 = Button("second")
push!(g1, b12)
b21 = Button("first")
push!(g2, b21)
b22 = Button("second")
push!(g2, b22)

## Iteration
strs = ["first", "second"]
i = 1
for child in g1
    @assert child[:label,String] == strs[i]
    i += 1
end

g1[b11,:pack_type] = 0 #GTK_PACK_START
g1[b12,:pack_type] = 0 #GTK_PACK_START
g2[b21,:pack_type] = 1 #GTK_PACK_END
g2[b22,:pack_type] = 1 #GTK_PACK_END
## Now shrink window
destroy(w)


## Grid
grid = Table(3,3)
w = Window(grid, "Grid", 400, 400)
grid[2,2] = Button("2,2")
grid[2,3] = Button("2,3")
grid[1,1] = "grid"
destroy(w)


## Widgets

## button, label
w = Window("Widgets")
f = BoxLayout(:v); push!(w,f)
l = Label("label"); push!(f,l)
b = Button("button"); push!(f,b)

l[:label] = "new label"
@assert l[:label,String] == "new label"
b[:label] = "new label"
@assert b[:label,String] == "new label"
#local ctr = 0
#function cb(path)
#    global ctr
#    ctr = ctr + 1
#end
#end
#tk_bind(b, "command", cb)
#tcl(b, "invoke")
#@assert ctr == 2
#img = Image(Pkg.dir("Tk", "examples", "weather-overcast.gif"))
#map(u-> tk_configure(u, {:image=>img, :compound=>"left"}), (l,b))
destroy(w)

## checkbox
w = Window("Checkbutton")
check = CheckButton("check me"); push!(w,check)
check[:active] = true
@assert check[:active,Bool] == true
check[:label] = "new label"
@assert check[:label,String] == "new label"
#ctr = 0
#tk_bind(check, "command", cb)
#tcl(check, "invoke")
#@assert ctr == 1
destroy(w)

## radio
choices = ["choice one", "choice two", "choice three", RadioButton("choice four"), Label("choice five")]
w = Window("Radio")
f = BoxLayout(:v); push!(w,f)
r = Array(RadioButton,3)
r[1] = RadioButton(choices[1]); push!(f,r[1])
r[2] = RadioButton(r[1],choices[2]); push!(f,r[2])
r[3] = RadioButton(r[2],choices[3],true); push!(f,r[3])
@assert [b[:active,Bool] for b in r] == [false, false, true]
r[1][:active] = true
@assert [b[:active,Bool] for b in r] == [true, false, false]
destroy(w)

r = RadioButtonGroup(choices,2)
@assert length(r) == 5
@assert sum([b[:active,Bool] for b in r]) == 1
itms = Array(Any,length(r))
for (i,e) in enumerate(r)
    itms[i] = try
            e[:label,String]
        catch
            e[1]
        end
end
@assert setdiff(choices, itms) == [choices[4],]
@assert setdiff(itms, choices) == ["choice four",]
@assert r[:active][:label,String] == choices[2]
w = Window(r,"RadioGroup")
destroy(w)

## combobox
#combo = Combobox(w, choices); pack(combo)
#set_editable(combo, false)              # default
#set_value(combo, choices[1])
#@assert get_value(combo) == choices[1]
#set_value(combo, 2)                         #  by index
#@assert get_value(combo) == choices[2]
#set_value(combo, nothing)
#@assert get_value(combo) == nothing
#set_items(combo, map(uppercase, choices))
#set_value(combo, 2)
#@assert get_value(combo) == uppercase(choices[2])
#set_items(combo, {:one=>"ONE", :two=>"TWO"})
#set_value(combo, "one")
#@assert get_value(combo) == "one"
#w = Window(combo,"Combobox")
#destroy(w)


## slider
#w = Window("Slider")
#sl = Slider(w, 1:10, {:orient=>"vertical"}); pack(sl)
#set_value(sl, 3)
#@assert get_value(sl) == 3
#tk_bind(sl, "command", cb) ## can't test
#destroy(w)

## spinbox
#w = Window("Spinbox")
#sp = Spinbox(w, 1:10); pack(sp)
#set_value(sp, 3)
#@assert get_value(sp) == 3
#destroy(w)

## progressbar
#w = Window("Progress bar")
#pb = Progressbar(w, {:orient=>"horizontal"}); pack(pb)
#set_value(pb, 50)
#@assert get_value(pb) == 50
#tk_configure(pb, {:mode => "indeterminate"})
#destroy(w)


## Entry
#w = Window("Entry")
#e = Entry(w, "initial"); pack(e)
#set_value(e, "new text")
#@assert get_value(e) == "new text"
#set_visible(e, false)
#set_visible(e, true)
### Validation
#function validatecommand(path, s, S)
#    println("old $s, new $S")
#    s == "invalid" ? tcl("expr", "FALSE") : tcl("expr", "TRUE")     # *must* return logical in this way
#end
#function invalidcommand(path, W)
#    println("called when invalid")
#    tcl(W, "delete", "@0", "end")
#    tcl(W, "insert", "@0", "new text")
#end
#tk_configure(e, {:validate=>"key", :validatecommand=>validatecommand, :invalidcommand=>invalidcommand})
#destroy(w)

## Text
#w = Window("Text")
#pack_stop_propagate(w)
#f = Frame(w); pack(f, {:expand=>true, :fill=>"both"})
#txt = Text(w)
#scrollbars_add(f, txt)
#set_value(txt, "new text\n")
#@assert get_value(txt) == "new text\n"
#destroy(w)

## tree. Listbox
#w = Window("Listbox")
#pack_stop_propagate(w)
#f = Frame(w); pack(f, {:expand=>true, :fill=>"both"})
#tr = Treeview(f, choices)
#scrollbars_add(f, tr)
#set_value(tr, 2)
#@assert get_value(tr)[1] == choices[2]
#set_items(tr, choices[1:2])
#destroy(w)

                   
## tree grid
#w = Window("Array")
#pack_stop_propagate(w)
#f = Frame(w); pack(f, {:expand=>true, :fill=>"both"})
#tr = Treeview(f, hcat(choices, choices))
#tree_key_header(tr, "right"); tree_key_width(tr, 50)
#tree_headers(tr, ["left"], [50])
#scrollbars_add(f, tr)
#set_value(tr, 2)
#@assert get_value(tr)[1] == choices[2]
#destroy(w)
