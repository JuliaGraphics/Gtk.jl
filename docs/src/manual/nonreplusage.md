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
    wait(c)
end
```

By waiting on a `Condition`, you force Julia to keep running. However, when the window is closed, then the program can continue (which in this case would simply be to exit).
