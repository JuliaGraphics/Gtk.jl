

### Adding and removing objects

Many widgets in Gtk can act as containers: for example, windows contain other widgets. New objects are created in "isolation," and attached to their parent containers using `push!`.

For example, let's add a frame:
```jl
    f = @Frame("A frame")
```
If you check your window, you won't see anything. That's because the frame has not yet been associated with any container. Let's do that and see what happens:
```jl
    push!(win, f)
    showall(win)
```

![window](doc/figures/frame.png)

Note the `showall`, which is required to get the display to update with your changes. In some of the examples below, we'll omit this step, but you should call `showall` any time you want to see the window in its current state.

Let's add a button:
```jl
    ok = @Button("OK")
    push!(f, ok)
    showall(win)
```

![window](doc/figures/okbutton.png)

We can remove our `ok` button from the frame:
```jl
    delete!(f, ok)
```
(You can verify that it doesn't show in the window anymore.) However, `ok` still exists, and you can put it somewhere else if you wish.

"Container" objects can also be initialized to contain a child:
```jl
    ok = @Button("OK")
    frame = @Frame(ok, "A frame")
    win = @Window(frame, "My window")
```
This only works to add a single (or the first) child of a container.








#### Inspecting and manipulating the graphics hierarchy

We can get the parent object:
```jl
    julia> parent(hbox)
    GtkFrameLeaf(name=...
```

Calling `parent` on a top-level object yields an error, but you can check to see if the object has a parent using `hasparent`.

Likewise, it's possible to get the children:
```jl
    for child in hbox
        println(get_gtk_property(child,:label,String))
    end
```




### Specific graphical elements

#### Scales

Above we showed how to create a `Scale` (slider) object.
If you examine the `Scale`'s [properties](https://developer.gnome.org/gtk3/stable/GtkScale.html#GtkScale.properties),
you might be surprised to not see any that deal with its value or range of acceptable values.
This is because a `Scale` contains another more basic type, `Adjustment`, responsible for holding these properties:
```jl
    sc = @Scale(false,0:10)   # range in integer steps, from 0 to 10
    adj = @Adjustment(sc)
    set_gtk_property!(adj,:upper,11)         # now this scale goes to 11!
    set_gtk_property!(adj,:value,7)
    win = @Window(sc,"Scale") |> showall
```
![scale](doc/figures/scale.png)







#### Menus

In Gtk, the core element is the `MenuItem`.
Let's say we want to create a file menu; we might begin by creating the item:
```jl
    file = @MenuItem("_File")
```
The underscore in front of the "F" means that we will be able to select this item using `Alt+F`.
The file menu will have items inside of it, of course, so let's create a submenu associated with this item:
```jl
    filemenu = @Menu(file)
```
Now let's populate it with entries:
```jl
    new_ = @MenuItem("New")
    push!(filemenu, new_)
    open_ = @MenuItem("Open")
    push!(filemenu, open_)
    push!(filemenu, @SeparatorMenuItem())
    quit = @MenuItem("Quit")
    push!(filemenu, quit)
```
Finally, let's place our file item inside another type of menu, the `MenuBar`:
```jl
    mb = @MenuBar()
    push!(mb, file)  # notice this is the "File" item, not filemenu
    win = @Window(mb, "Menus", 200, 40)
    showall(mb)
```
![menu](doc/figures/menu.png)

#### Popup menus

We can create a canvas that, when right clicked, reveals a context menu:

```jl
    using Gtk.ShortNames, Base.Graphics
    # Fill a canvas with red
    c = @Canvas()
    win = @Window(c, "Canvas")
    draw(c) do widget
        ctx = getgc(c)
        set_source_rgb(ctx, 1, 0, 0)
        paint(ctx)
    end
    # Define the popup menu
    popupmenu = @Menu()
    printcolor = @MenuItem("Print color")
    push!(popupmenu, printcolor)
    push!(popupmenu, @MenuItem("Do nothing"))
    # This next line is crucial: otherwise your popup menu shows as a thin bar
    showall(popupmenu)
    # Associate actions with right-click and selection
    c.mouse.button3press = (widget,event) -> popup(popupmenu, event)
    signal_connect(printcolor, :activate) do widget
        println("Red!")
    end
    showall(win)
```
![popupmenu](doc/figures/popup.png)
