### More about signals and signal-handlers

In addition to the "simple"
interface, `signal_connect`
supports an approach that allows your callback function to be directly
compiled to machine code.  Not only is this more efficient, but it can
occasionally be useful in avoiding problems (see issue #161).

This alternative syntax is as follows:
```
signal_connect(cb, widget, signalname, return_type, parameter_type_tuple, after, user_data=widget)
```
where:

- `cb` is your callback function. This will be compiled with `@cfunction`, and you need to follow its rules. In particular, you should use a generic function
  (i.e., one defined as `function foo(x,y,z) ... end`), and the
  arguments and return type should match the GTK+ documentation for
  the widget and signal ([see
  examples](https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-accel-closures-changed)).
  **In contrast with the simpler
  interface, when writing these
  callbacks you must include the `user_data` argument**.  See examples below.
- `widget` is the widget that will send the signal
- `signalname` is a string or symbol identifying the signal, e.g.,
  `"clicked"` or `"button-press-event"`
- `return_type` is the type of the value returned by your
  callback. Usually `Nothing` (for `void`) or `Cint` (for `gboolean`)
- `parameter_type_tuple` specifies the types of the *middle* arguments
  to the callback function, omitting the first (the widget) and last
  (`user_data`).  For example, for [`"clicked"`](https://developer.gnome.org/gtk3/stable/GtkButton.html#GtkButton-clicked) we have
  `parameter_type_tuple = ()` (because there are no middle arguments)
  and for [`"button-press-event"`](https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-button-press-event) we have `parameter_type_tuple =
  (Ptr{GdkEventButton},)`.
- `after` is a boolean, `true` if you want your callback to run after
  the default handler for your signal. When in doubt, specify `false`.
- `user_data` contains any additional information your callback needs
  to operate.  For example, you can pass other widgets, tuples of
  values, etc.  If omitted, it defaults to `widget`.

The callback's arguments need to match the GTK documentation, with the
exception of the `user_data` argument. (Rather than being a pointer,
`user_data` will automatically be converted back to an object.)

For example, consider a GUI in which pressing a button updates
a counter:

```jl
box = @Box(:h)
button = @Button("click me")
label  = @Label("0")
push!(box, button)
push!(box, label)
win = @Window(box, "Callbacks")
showall(win)

const counter = [0]  # Pack counter value inside array to make it a reference

# "clicked" callback declaration is
#     void user_function(GtkButton *button, gpointer user_data)
# But user_data gets converted into a Julia object automatically
function button_cb(widgetptr::Ptr, user_data)
     widget = convert(Button, widgetptr)  # pointer -> object
     lbl, cntr = user_data                # unpack the user_data tuple
     cntr[] = cntr[]+1                    # increment counter[1]
     set_gtk_property!(lbl, :label, string(cntr[]))
     nothing                              # return type is void
end

signal_connect(button_cb, button, "clicked", Nothing, (), false, (label, counter))
```

You should note that the value of `counter[]` matches the display in
the GUI.

#### Specifying the event type

If your callback function takes an `event` argument, it is important
to declare its type correctly. An easy way to do that is to first
write a callback using the "simple" interface, e.g.,

```jl
    signal_connect(win, "delete-event") do widget, event
        @show typeof(event)
        @show event
    end
```

and then use the reported type in `parameter_type_tuple`.

#### `@guarded`

The "simple" callback interface includes protections against
corrupting Gtk state from errors, but this `@cfunction`-based approach
does not. Consequently, you may wish to use `@guarded` when writing
these functions. ([Canvas](../manual/canvas.md) draw functions and
mouse event-handling are called through this interface, which is why
you should use `@guarded` there.) For functions that should return a
value, you can specify the value to be returned on error as the first
argument. For example:

```jl
    const unhandled = convert(Int32, false)
    @guarded unhandled function my_callback(widgetptr, ...)
        ...
    end
```
