# Layout

You will usually want to add more than one widget to you application. To this end, Gtk provides several layout widget. Instead of using a precise positioning, the Gtk layout widgets take an approach where widgets are aligned in boxes and tables.

!!! note
    While doing the layout using Julia code is possible for small examples it is in general advised to instead create the layout using Glade in combination with GtkBuilder [Builder and Glade](@ref).

## Box

The most simple layout widget is the `GtkBox`. It can be either be horizontally or vertical aligned. It allow to add an arbitrary number of widgets.
```julia
win = GtkWindow("New title")
hbox = GtkBox(:h)  # :h makes a horizontal layout, :v a vertical layout
push!(win, hbox)
cancel = GtkButton("Cancel")
ok = GtkButton("OK")
push!(hbox, cancel)
push!(hbox, ok)
showall(win)
```
We can address individual "slots" in this container:
```julia
julia> length(hbox)
2

julia> get_gtk_property(hbox[1], :label, String)
"Cancel"

julia> get_gtk_property(hbox[2], :label, String)
"OK"
```

This layout may not be exactly what you'd like. Perhaps you'd like the `ok` button to fill the available space, and to insert some blank space between them:

```julia
set_gtk_property!(hbox,:expand,ok,true)
set_gtk_property!(hbox,:spacing,10)
```
The first line sets the `expand` property of the `ok` button within the `hbox` container.

Note that these aren't evenly-sized, and that doesn't change if we set the `cancel` button's `expand` property to `true`. `ButtonBox` is created specifically for this purpose, so let's use it instead:

```julia
destroy(hbox)
ok = GtkButton("OK")
cancel = GtkButton("Cancel")
hbox = GtkButtonBox(:h)
push!(win, hbox)
push!(hbox, cancel)
push!(hbox, ok)
```

Now we get this:

![window](doc/figures/twobuttons2.png)

which may be closer to what you had in mind.

## Grid

More generally, you can arrange items in a grid:
```julia
win = GtkWindow("A new window")
g = GtkGrid()
a = GtkEntry()  # a widget for entering text
set_gtk_property!(a, :text, "This is Gtk!")
b = GtkCheckButton("Check me!")
c = GtkScale(false, 0:10)     # a slider

# Now let's place these graphical elements into the Grid:
g[1,1] = a    # Cartesian coordinates, g[x,y]
g[2,1] = b
g[1:2,2] = c  # spans both columns
set_gtk_property!(g, :column_homogeneous, true)
set_gtk_property!(g, :column_spacing, 15)  # introduce a 15-pixel gap between columns
push!(win, g)
showall(win)
```

The `g[x,y] = obj` assigns the location to the indicated `x,y` positions in the grid
(note that indexing is Cartesian rather than row/column; most graphics packages address the screen using
Cartesian coordinates where 0,0 is in the upper left).
A range is used to indicate a span of grid cells.
By default, each row/column will use only as much space as required to contain the objects,
but you can force them to be of the same size by setting properties like `column_homogeneous`.
