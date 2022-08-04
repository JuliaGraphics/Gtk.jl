# Asynchronous UI

It is possible to perform background computation without interfering with user interface
responsiveness either using multithreading or using separate processes. Use of a separate
process includes slightly more overhead but also enusres user interface responsiveness more
robustly.

Here is an example using [threads](https://docs.julialang.org/en/v1/manual/multi-threading/).
Notice that this example will freeze the UI during computation unless Julia is run with two
or more threads (`julia -t2` on the command line).

```julia
using Gtk

btn = GtkButton("Start")
sp = GtkSpinner()
ent = GtkEntry()

grid = GtkGrid()
grid[1,1] = btn
grid[2,1] = sp
grid[1:2,2] = ent

signal_connect(btn, "clicked") do widget
    start(sp)
    Threads.@spawn begin

        # Do work
        stop_time = time() + 3
        counter = 0
        while time() < stop_time
            counter += 1
        end

        # Interacting with GTK from a thread other than the main thread is
        # generally not allowed, so we register an idle callback instead.
        Gtk.GLib.g_idle_add(nothing) do user_data
            stop(sp)
            set_gtk_property!(ent, :text, "I counted to $counter in a thread!")
            Cint(false)
        end
    end
end

win = GtkWindow(grid, "Threads", 200, 200)
showall(win)
```


Here is an example using a separate process to offload the work. This toy example is
fairly straightforward, but things can get more complex if the offloaded task is more
complex. See the [manual](https://docs.julialang.org/en/v1/manual/distributed-computing/) 
for details.

```julia
using Gtk, Distributed

btn = GtkButton("Start")
sp = GtkSpinner()
ent = GtkEntry()

grid = GtkGrid()
grid[1,1] = btn
grid[2,1] = sp
grid[1:2,2] = ent

id = addprocs(1)[1]

signal_connect(btn, "clicked") do widget
    start(sp)
    @async begin

        # Offload work to a separate process and block until it is done.
        counter = @fetchfrom id begin
            stop_time = time() + 3
            counter = 0
            while time() < stop_time
                counter += 1
            end
            counter
        end

        # We are still in the main thread so it is okay to directly access widgets
        stop(sp)
        set_gtk_property!(ent, :text, "I counted to $counter in a separate process!")
    end
end

win = GtkWindow(grid, "Distributed", 200, 200)
showall(win)
```

