# Signals and Callbacks

A button is not much use if it doesn't do anything.
Gtk+ uses _signals_ as a method for communicating that something of interest has happened.
Most signals will be _emitted_ as a consequence of user interaction: clicking on a button,
closing a window, or just moving the mouse. You _connect_ your signals to particular functions
to make something happen.

Let's try a simple example:
```julia
b = GtkButton("Press me")
win = GtkWindow(b, "Callbacks")
showall(win)

function button_clicked_callback(widget)
    println(widget, " was clicked!")
end

id = signal_connect(button_clicked_callback, b, "clicked")
```

Here, `button_clicked_callback` is a *callback function*, something
designed to be called by GTK+ to implement the response to user
action.  You use the `signal_connect` function to specify when it
should be called: in this case, when widget `b` (your button) emits
the `"clicked"` signal.

Using Julia's `do` syntax, the exact same code could alternatively be
written as
```julia
b = GtkButton("Press me")
win = GtkWindow(b, "Callbacks")
id = signal_connect(b, "clicked") do widget
     println(widget, " was clicked!")
end
```

If you try this, and click on the button, you should see something like the following:
```
julia> GtkButton(action-name=NULL, action-target, related-action, use-action-appearance=TRUE, name="", parent, width-request=-1, height-request=-1, visible=TRUE, sensitive=TRUE, app-paintable=FALSE, can-focus=TRUE, has-focus=TRUE, is-focus=TRUE, can-default=FALSE, has-default=FALSE, receives-default=TRUE, composite-child=FALSE, style, events=0, no-show-all=FALSE, has-tooltip=FALSE, tooltip-markup=NULL, tooltip-text=NULL, window, double-buffered=TRUE, halign=GTK_ALIGN_FILL, valign=GTK_ALIGN_FILL, margin-left=0, margin-right=0, margin-top=0, margin-bottom=0, margin=0, hexpand=FALSE, vexpand=FALSE, hexpand-set=FALSE, vexpand-set=FALSE, expand=FALSE, border-width=0, resize-mode=GTK_RESIZE_PARENT, child, label="Press me", image, relief=GTK_RELIEF_NORMAL, use-underline=TRUE, use-stock=FALSE, focus-on-click=TRUE, xalign=0.500000, yalign=0.500000, image-position=GTK_POS_LEFT, ) was clicked!
```
That's quite a lot of output; let's just print the label of the button:
```julia
id2 = signal_connect(b, "clicked") do widget
    println("\"", get_gtk_property(widget,:label,String), "\" was clicked!")
end
```
Now you get something like this:
```
julia> GtkButton(action-name=NULL, action-target, related-action, use-action-appearance=TRUE, name="", parent, width-request=-1, height-request=-1, visible=TRUE, sensitive=TRUE, app-paintable=FALSE, can-focus=TRUE, has-focus=TRUE, is-focus=TRUE, can-default=FALSE, has-default=FALSE, receives-default=TRUE, composite-child=FALSE, style, events=0, no-show-all=FALSE, has-tooltip=FALSE, tooltip-markup=NULL, tooltip-text=NULL, window, double-buffered=TRUE, halign=GTK_ALIGN_FILL, valign=GTK_ALIGN_FILL, margin-left=0, margin-right=0, margin-top=0, margin-bottom=0, margin=0, hexpand=FALSE, vexpand=FALSE, hexpand-set=FALSE, vexpand-set=FALSE, expand=FALSE, border-width=0, resize-mode=GTK_RESIZE_PARENT, child, label="Press me", image, relief=GTK_RELIEF_NORMAL, use-underline=TRUE, use-stock=FALSE, focus-on-click=TRUE, xalign=0.500000, yalign=0.500000, image-position=GTK_POS_LEFT, ) was clicked!
"Press me" was clicked!
```
Notice that _both_ of the callback functions executed!
Gtk+ allows you to define multiple signal handlers for a given object; even the execution order can be [specified](https://developer.gnome.org/gobject/stable/gobject-Signals.html#gobject-Signals.description).
Callbacks for some [signals](https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-accel-closures-changed) require that you return an `Int32`, with value 0 if you want the next handler to run or 1 if you want to prevent any other handlers from running on this event.

The [`"clicked"` signal callback](https://developer.gnome.org/gtk3/stable/GtkButton.html#GtkButton-clicked) should return `nothing` (`void` in C parlance), so you can't prevent other callbacks from running.
However, we can disconnect the first signal handler:
```julia
signal_handler_disconnect(b, id)
```
Now clicking on the button just yields
```julia
julia> "Press me" was clicked!
```
Alternatively, you can temporarily enable or disable individual handlers with `signal_handler_block` and `signal_handler_unblock`.

The arguments of the callback depend on the signal type.
For example, instead of using the `"clicked"` signal---for which the Julia handler should be defined with just a single argument---we could have used `"button-press-event"`:
```julia
b = GtkButton("Pick a mouse button")
win = GtkWindow(b, "Callbacks")
id = signal_connect(b, "button-press-event") do widget, event
    println("You pressed button ", event.button)
end
```
Note that this signal requires two arguments, here `widget` and `event`, and that `event` contained useful information.
Arguments and their meaning are described along with their corresponding [signals](https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-accel-closures-changed).
**You should omit the final `user_data` argument described in the Gtk documentation**;
keep in mind that you can always address other variables from inside your function block, or define the callback in terms of an anonymous function:
```julia
id = signal_connect((widget, event) -> cb_buttonpressed(widget, event, guistate, drawfunction, ...), b, "button-press-event")
```

In some situations you may want or need to use an [approach that is more analogous to julia's `@cfunction` callback syntax](doc/more_signals.md). One advantage of this alternative approach is that, in cases of error, the backtraces are much more informative.

Warning: it is essential to avoid task switching inside Gtk callbacks,
as this corrupts the Gtk C-stack. For example, use `@async print` or queue a message for yourself.
You can also call `GLib.g_yield()` if you need to block. However, if you are still seeing segfaults in some random method due to there existing a callback that recursively calls the glib main loop (such as making a dialog box) or otherwise causes `g_yield` to be called, wrap the faulting code in `GLib.@sigatom`. This will postpone execution of that code block until it can be run on the proper stack (but will otherwise acts like normal control flow).

These restrictions should be fixed once https://github.com/JuliaLang/julia/pull/13099 is merged.
