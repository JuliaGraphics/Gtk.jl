# Custom/Composed Widgets

In practice one usually has to customize a widget to ones own needs. 
Furthermore, it is also useful to group widgets together to break up
a comple user interface into manageble parts. Both use cases are discussed next.

## Custom Widgets

You can subclass an existing Gtk type in Julia using the following code pattern:

```julia
type MyButton <: Gtk.GtkButton
    handle::Ptr{Gtk.GObject}
    other_fields
    function MyButton(label)
        btn = @GtkButton(label)
        Gtk.gobject_move_ref(new(btn), btn)
    end
end
```

This creates a `MyButton` type which inherits its behavior from `GtkButton`. The `gobject_move_ref` call transfers ownership of the `GObject` handle from `GtkButton` to `MyButton` in a gc-safe manner. Afterwards, the `btn` object is invalid and converting from the `Ptr{GtkObject}` to `GtkObject` will return the `MyButton` object.

Lets use this pattern to create a button that is initialized with a default text "My Button".
The code would look like this.

```julia
type MyButton <: Gtk.GtkButton
    handle::Ptr{Gtk.GObject}

    function MyButton()
        btn = @GtkButton("My Button")
        Gtk.gobject_move_ref(new(btn.handle), btn)
    end
end
```

We can now add this button to e.g. a window or any layout container just as if `MyButton` would be be a regular `GtkWidget`.

```julia
btn = MyButton()
win = @GtkWindow("Custom Widget",400,200)
push!(win, btn)
showall(win)
```

## Composed Widgets

TODO
