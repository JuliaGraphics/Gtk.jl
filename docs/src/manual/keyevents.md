# Key Events

### Key press events

To capture a keyboard event,
one can connect to the `key-press-event` from the active window,
as given in the following example.

```julia
using Gtk

win = GtkWindow("Key Press Example")

signal_connect(win, "key-press-event") do widget, event
  k = event.keyval
  println("You pressed key ", k, " which is '", Char(k), "'.")
end
```

You can then check if `event.keyval` has a certain value
and invoke an action in that case.


### Key release events

The following example captures the events
for both a key press and a key release
and reports the time duration between the two.
There some state handling here
because of the likely event
that your keyboard is set to "repeat" a pressed key
after some initial delay.
This version reports the time elapsed
between the _initial_ key press and the key release.

```julia
using Gtk

time0 = nothing

w = GtkWindow("Key Press/Release Example")

id1 = signal_connect(w, "key-press-event") do widget, event
    k = event.keyval
    global time0
    if isnothing(time0)
        time0 = event.time # archive the initial key press time
        println("You pressed key ", k, " which is '", Char(k), "'.")
    else
        println("repeating key ", k)
    end
end

id2 = signal_connect(w, "key-release-event") do widget, event
    k = event.keyval
    duration = event.time - time0 # key press duration in msec
    println("You released key ", k, " after time ", duration, " msec.")
    global time0 = nothing # revert to original state for next press
end
```
