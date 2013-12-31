# Usage

Begin with
```
using Gtk
```
or, if you prefer more generic names,
```
using Gtk.ShortNames
```
For example, `GtkWindow` becomes `Window`, `GtkFrame` becomes `Frame`, etc. In the remainder of the documentation, we'll use the short names.

In addition to this expository document, there is a [function reference](function_reference.md).

## Creating and destroying a window

A new window can be created as
```
win = Window("My window")
```

![window](figures/mywindow.png)

You can optionally specify its width, height, whether it should be resizable, and whether it is a "toplevel" window or a "popup":
```
popup = Window("SomeDialog", 400, 200, false, false)
```
would create a fixed-size popup window (which, among other things, does not have any decorations).

The window can be "closed" by
```
destroy(popup)
```
`destroy` deletes any widget, not just windows.

## Object properties

If you're following along, you probably noticed that creating `win` caused quite a lot of output:
```
GtkWindow(name="", parent, width-request=-1, height-request=-1, visible=TRUE, sensitive=TRUE, app-paintable=FALSE, can-focus=FALSE, has-focus=FALSE, is-focus=FALSE, can-default=FALSE, has-default=FALSE, receives-default=FALSE, composite-child=FALSE, style, events=0, no-show-all=FALSE, has-tooltip=FALSE, tooltip-markup=NULL, tooltip-text=NULL, window, double-buffered=TRUE, halign=GTK_ALIGN_FILL, valign=GTK_ALIGN_FILL, margin-left=0, margin-right=0, margin-top=0, margin-bottom=0, margin=0, hexpand=FALSE, vexpand=FALSE, hexpand-set=FALSE, vexpand-set=FALSE, expand=FALSE, border-width=0, resize-mode=GTK_RESIZE_QUEUE, child, type=GTK_WINDOW_TOPLEVEL, title="My window", role=NULL, resizable=TRUE, modal=FALSE, window-position=GTK_WIN_POS_NONE, default-width=-1, default-height=-1, destroy-with-parent=FALSE, hide-titlebar-when-maximized=FALSE, icon, icon-name=NULL, screen, type-hint=GDK_WINDOW_TYPE_HINT_NORMAL, skip-taskbar-hint=FALSE, skip-pager-hint=FALSE, urgency-hint=FALSE, accept-focus=TRUE, focus-on-map=TRUE, decorated=TRUE, deletable=TRUE, gravity=GDK_GRAVITY_NORTH_WEST, transient-for, attached-to, opacity=1.000000, has-resize-grip=TRUE, resize-grip-visible=TRUE, application, ubuntu-no-proxy=FALSE, is-active=FALSE, has-toplevel-focus=FALSE, startup-id, mnemonics-visible=TRUE, focus-visible=TRUE, )
```
This shows you a list of properties of the object. For example, notice that the `title` property is set to `"My window"`. We can change the title in the following way:
```
win[:title] = "New title"
```
and now we have:

![window](figures/newtitle.png)

To get the property, you have to specify the return type as a second argument:
```
julia> win[:title, String]
"New title"
```
This is necessary because Gtk, a C library, maintains the state; you have to specify what type of Julia object you want to create from the pointers it passes back.

To access particular properties, you can either use symbols, like `:title`, or strings, like `"title"`. When using symbols, you'll need to convert `-` into `_`:

```
julia> win[:double_buffered, Bool]
true
```

Some properties have convenience methods, for example:
```
julia> visible(win)
true

julia> visible(win, false)

julia> visible(win)
false

julia> visible(win, true)
```
This sequence makes the window disappear and then reappear.


## Adding and removing objects

Many widgets in Gtk can act as containers: for example, windows contain other widgets. New objects are created in "isolation," and attached to their parent containers using `push!`. 

For example, let's add a frame:
```
f = Frame("A frame")
```
If you check your window, you won't see anything. That's because the frame has not yet been associated with any container. Let's do that and see what happens:
```
push!(win, f)
```

![window](figures/frame.png)

Let's add a button:
```
ok = Button("OK")
push!(f, ok)
```

![window](figures/okbutton.png)

We can remove our `ok` button from the frame:
```
delete!(f, ok)
```
(You can verify that it doesn't show in the window anymore.) However, `ok` still exists, and you can put it somewhere else if you wish.

## Layout

A frame can contain only one child widget. If we want several buttons inside the frame, we have to create a layout that can hold multiple objects. Layouts also organize the arrangement of widgets in a specified geometry.

To support multiple buttons, let's add a box and then fill it with two buttons:
```
hbox = BoxLayout(:h)  # :h makes a horizontal layout, :v a vertical layout
push!(f, hbox)
cancel = Button("Cancel")
push!(hbox, cancel)
push!(hbox, ok)
```
You might see something like this:

![window](figures/twobuttons1.png)

This may not be exactly what you'd like. Perhaps you'd like the `ok` button to fill the available space, and to insert some blank space between them:

```
hbox[ok,:expand] = true
hbox[:spacing] = 10
```
The first line sets the `expand` property of the `ok` button within the `hbox` container.

Note that these aren't even, and that's true even if we set the `cancel` button's `expand` property to `true`. `ButtonBox` is created specifically for this purpose, so let's use it instead:

```
destroy(hbox)
ok = Button("OK")
cancel = Button("Cancel")
hbox = ButtonBox(:h)
push!(f, hbox)
push!(hbox, cancel)
push!(hbox, ok)
```

Now we get this:

![window](figures/twobuttons2.png)

which may be closer to what you had in mind.

More generally, you can arrange items in a grid:
```
win = Window("A new window")
g = Grid()   # gtk3-only (use Table() for gtk2)
a = Entry()
a[:text] = "This is Gtk!"
b = CheckButton("Check me!")
c = Scale(false, 0:11)
g[1,1] = a
g[1,2] = b
g[2,1:2] = c
g[:column_homogeneous] = true  # g[:homogeoneous] for gtk2
g[:column_spacing] = 15
push!(win, g)
showall(win)
```
![window](figures/grid.png)

The `g[r,c] = x` assigns the location to the indicated row(s) and column(s).
A range is used to indicate a span of grid cells.
By default, each row/column will use only as much space as required,
but you can force them to be of the same size as shown.

### Inspecting and manipulating the graphics hierarchy

We can get the parent object:
```
julia> parent(hbox)
GtkFrame(name=...
```

Calling `parent` on a top-level object yields an error, but you can check to see if the object has a parent using `hasparent`.

Likewise, it's possible to get the children:
```
for child in hbox
    println(child[:label,String])
end
```

## Additional graphical elements

### Menus

In Gtk, the core element is the `MenuItem`.
Let's say we want to create a file menu; we might begin by creating the item:
```
file = MenuItem("_File")
```
The underscore in front of the "F" means that we will be able to select this item using `Alt+F`.
The file menu will have items inside of it, of course, so let's create a submenu associated with this item:
```
filemenu = Menu(file)
```
Now let's populate it with entries:
```
new_ = MenuItem("New")
push!(filemenu, new_)
open_ = MenuItem("Open")
push!(filemenu, open_)
push!(filemenu, SeparatorMenuItem())
quit = MenuItem("Quit")
push!(filemenu, quit)
```
Finally, let's place our file item inside another type of menu, the `MenuBar`:
```
mb = MenuBar()
push!(mb, file)  # notice this is the "File" item, not filemenu
win = Window(mb, "Menus", 200, 40)
```
![menu](figures/menu.png)

