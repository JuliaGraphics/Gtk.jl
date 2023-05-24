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
after some initial delay and because it is possible to
press multiple keys at once.
This version reports the time elapsed
between the _initial_ key press and the key release.

```julia
using Gtk

const start_times = Dict{UInt32, UInt32}()

w = GtkWindow("Key Press/Release Example")

id1 = signal_connect(w, "key-press-event") do widget, event
    k = event.keyval
    if k ∉ keys(start_times)
        start_times[k] = event.time # save the initial key press time
        println("You pressed key ", k, " which is '", Char(k), "'.")
    else
        println("repeating key ", k)
    end
end

id2 = signal_connect(w, "key-release-event") do widget, event
    k = event.keyval
    start_time = pop!(start_times, k) # remove the key from the dictionary
    duration = event.time - start_time # key press duration in milliseconds
    println("You released key ", k, " after time ", duration, " msec.")
end
```
