# Getting Started

We start this tutorial with a very simple example that creats an empty window of size 400x200 pixels
and adds a button to it
```julia
using Gtk

win = GtkWindow("My First Gtk.jl Program", 400, 200)

b = GtkButton("Click Me")
push!(win,b)

showall(win)
```
We will now go through this example step by step. First the package is loaded `using Gtk` statement. Then a window is created using the `GtkWindow` constructor. It gets as input the window title, the window width, and the window height. Then a button is created using the `GtkButton` constructor. In order to insert the button into the window we call
```julia
push!(win,b)
```
Finally, `showall(win)` will render the entire application on the screen.

## Extended Example

We will now extend the example to let the button actually do something. To this end we first define a callback function that will be executed when the user clicks the button. Our callback function is supposed to change the window title of the application
```julia
function on_button_clicked(w)
  println("The button has been clicked")
end
```
What happens when the user clicks the button is that a "clicked" signal is emitted. In order to connect this signal to our function `on_button_clicked` we have to call
```julia
signal_connect(on_button_clicked, b, "clicked")
```
Our full extended example thus looks like:
```julia
using Gtk

win = GtkWindow("My First Gtk.jl Program", 400, 200)

b = GtkButton("Click Me")
push!(win,b)

function on_button_clicked(w)
  println("The button has been clicked")
end
signal_connect(on_button_clicked, b, "clicked")

showall(win)
```
