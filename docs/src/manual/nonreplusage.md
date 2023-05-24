# Non REPL Usage

If you're using Gtk from command-line scripts, one problem you may encounter is that Julia quits before you have a chance to see or interact with your windows. In such cases, the following design pattern can be helpful:

```julia
win = Window("gtkwait")

# Put your GUI code here

if !isinteractive()
    c = Condition()
    signal_connect(win, :destroy) do widget
        notify(c)
    end
    @async Gtk.gtk_main()
    wait(c)
end
```

By waiting on a `Condition`, Julia will keep running. This pattern allows for multiple events to trigger the condition, such as a button press, or one of many windows to be closed. Program flow will resume at `wait` line, after which it would terminate in this example.

In the common case we simply wish to wait for a single window to be closed, this can be shortened by using `waitforsignal`:

```julia
win = Window("gtkwait")

# Put your GUI code here

if !isinteractive()
    @async Gtk.gtk_main()
    Gtk.waitforsignal(win,:destroy)
end
```
