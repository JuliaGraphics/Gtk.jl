# Text Widgets

There are two basic widgets available for rendering simple text. The one is for
displaying non-editable text `GtkLabel` the other is for editable text `GtkEntry`.

## Label

A `GtkLabel` is the most basic text widget that has already been used behind the
scene in any previous example involving a `GtkButton`. 
A `GtkLabel` is constructed by calling
```julia
label = @GtkLabel("My text")
```
The text of a label can be changed using
```julia
GAccessor.text(label,"My other text")
```
Furthermore, a label has limited support for adding formatted text. This is done
using the `markup` function:
```julia
GAccessor.markup(label,"<b>My bold text</b>")
```
The syntax for this markup text is explained [here](https://developer.gnome.org/pango/stable/PangoMarkupFormat.html)

TODO line wrap / multi line

## Entry

TODO
