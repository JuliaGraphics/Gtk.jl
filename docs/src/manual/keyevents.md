# Key Events

In order to capture a keyboard event one can connect to the `key-press-event` from the active window. An example is given by
```
using Gtk

win = GtkWindow("Key Press Example")

signal_connect(win, "key-press-event") do widget, event
  println("You pressed key ", event.keyval)
end
```

You can then check if `event.keyval` has a certain value and invoke an action in that case.
