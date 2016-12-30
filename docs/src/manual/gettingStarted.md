# Getting Started

We start this tutorial with a very simple example that creats an empty window of size 400x200 pixels
and adds a button to it
```@example 1
using Gtk

win = @GtkWindow("My First Gtk.jl Program", 400, 200)

b = @GtkButton("Click Me")
push!(win,b)

showall(win)
```
We will now go through this example step by step. First the package is loaded `using Gtk` statement. Then a window is created using the `@GtkWindow` macro. It gets as input the window title, the window width, and the window height. Then a button is created using the `@GtkButton` macro. In order to insert the button into the window we call 
```julia
push!(win,b)
```
Finally, `showall(win)` will render the entire application on the screen.



