# Custom/Composed Widgets

In practice, one usually has to customize a widget to ones own needs.
Furthermore, it is also useful to group widgets together to break up
a complete user interface into manageable parts. Both use cases are discussed next.

## Custom Widgets

You can subclass an existing Gtk type in Julia using the following code pattern:

```julia
mutable struct MyButton <: Gtk.GtkButton
    handle::Ptr{Gtk.GObject}
    other_fields
    function MyButton(label)
        btn = GtkButton(label)
        return Gtk.gobject_move_ref(new(btn), btn)
    end
end
```

This creates a `MyButton` type which inherits its behavior from `GtkButton`. The `gobject_move_ref` call transfers ownership of the `GObject` handle from `GtkButton` to `MyButton` in a gc-safe manner. Afterwards, the `btn` object is invalid and converting from the `Ptr{GtkObject}` to `GtkObject` will return the `MyButton` object.

Lets use this pattern to create a button that is initialized with a default text "My Button".
The code would look like this.

```julia
mutable struct MyButton <: Gtk.GtkButton
    handle::Ptr{Gtk.GObject}

    function MyButton()
        btn = GtkButton("My Button")
        return Gtk.gobject_move_ref(new(btn.handle), btn)
    end
end
```

We can now add this button to e.g. a window or any layout container just as if `MyButton` would be a regular `GtkWidget`.

```julia
btn = MyButton()
win = GtkWindow("Custom Widget",400,200)
push!(win, btn)
showall(win)
```

## Composed Widgets

While a pre-initialized button might look like an artificial use cases, the same pattern can be used to develop composed widgets. In that case one will typically subclass from a layout widget such as `GtkBox` or `GtkGrid`. Lets for instance build a new composed widget consisting of a text box and a button

```julia
mutable struct ComposedWidget <: Gtk.GtkBox
    handle::Ptr{Gtk.GObject}
    btn # handle to child
    tv # handle to child

    function ComposedWidget(label)
        vbox = GtkBox(:v)
        btn = GtkButton(label)
        tv = GtkTextView()
        push!(vbox,btn,tv)
        set_gtk_property!(vbox,:expand,tv,true)
        set_gtk_property!(vbox,:spacing,10)
        w = new(vbox.handle, btn, tv)
        return Gtk.gobject_move_ref(w, vbox)
    end
end

c = ComposedWidget("My Button")
win = GtkWindow("Composed Widget",400,200)
push!(win, c)
showall(win)

```
You will usually store the handles to all subwidgets in the composed type as has been done in the example. This will give you quick access to the child widgets when e.g. callback functions for ComposedWidget are called.
