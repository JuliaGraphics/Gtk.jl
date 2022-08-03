# Asynchronous UI

It is possible to perform background computation without interfering with user interface
responsiveness either using separate processes or using multithreading. Use of a separate
process includes slightly more overhead but is also more robust.

Here is an example using a separate process to offload the work.

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
        counter = @fetchfrom id begin
            stop_time = time() + 3
            counter = 0
            while time() < stop_time
                counter += 1
            end
            counter
        end
        stop(sp)
        set_gtk_property!(ent, :text, "I counted to $counter in a separate process!")
    end
end

win = GtkWindow(grid, "Distributed", 200, 200)
showall(win)
```

And here is an example using threads. Notice that this example will freeze the UI during
computation unless Julia is run with two or more threads (`julia -t2` on the command line).

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
        stop_time = time() + 3
        counter = 0
        while time() < stop_time
            counter += 1
        end
        stop(sp)
        set_gtk_property!(ent, :text, "I counted to $counter in a thread!")
    end
end

win = GtkWindow(grid, "Threads", 200, 200)
showall(win)
```
