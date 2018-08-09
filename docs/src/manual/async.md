# Asynchronous UI

Here is an example of an asynchronous update of the user interface. Since
Julia has currently no possibility of multithreading we use a second process
to offload the work. The example is just a proof of principle.

```julia
using Gtk

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
 @Gtk.sigatom begin
   @async begin
    s = @fetchfrom id begin
      sleep(4)
      return "I am back"
    end
    @Gtk.sigatom begin
      stop(sp)
      set_gtk_property!(ent,:text,s)
    end
  end
 end
end

win = GtkWindow(grid, "Progress Bar", 200, 200)
showall(win)
```


