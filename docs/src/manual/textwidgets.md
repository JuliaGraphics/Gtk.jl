# Text Widgets

There are two basic widgets available for rendering simple text. The one is for
displaying non-editable text `GtkLabel` the other is for editable text `GtkEntry`.

## Label

A `GtkLabel` is the most basic text widget that has already been used behind the
scene in any previous example involving a `GtkButton`.
A `GtkLabel` is constructed by calling
```julia
label = GtkLabel("My text")
```
The text of a label can be changed using
```julia
GAccessor.text(label,"My other text")
```
Furthermore, a label has limited support for adding formatted text. This is done
using the `markup` function:
```julia
GAccessor.markup(label,"""<b>My bold text</b>\n
                          <a href=\"http://www.gtk.org\"
                          title=\"Our website\">GTK+ website</a>""")
```
The syntax for this markup text is borrowed from html and explained [here](https://developer.gnome.org/pango/stable/PangoMarkupFormat.html).

A label can be made selectable using
```julia
GAccessor.selectable(label,true)
```
This can be used if the user should be allowed to copy the text.

The justification of a label can be changed in the following way:
```julia
GAccessor.justify(label,Gtk.GConstants.GtkJustification.RIGHT)
```
Possible values of the enum `GtkJustification` are `LEFT`,`RIGHT`,`CENTER`, and `FILL`.

Automatic line wrapping can be enabled using
```julia
GAccessor.text(label,repeat("Very long text! ",20))
GAccessor.line_wrap(label,true)
```
Note that this will only happen, if the size of the widget is limited using layout constraints.

## Entry

The entry widget allows the user to enter text. The entered text can be read and write using
```julia
ent = GtkEntry()
set_gtk_property!(ent,:text,"My String")
str = get_gtk_property(ent,:text,String)
```
The maximum number of characters can be limited using `set_gtk_property!(ent,:max_length,10)`.

Sometimes you might want to make the widget non-editable. This can be done by a call
```julia
# using the accessor methods
GAccessor.editable(GtkEditable(ent),false)
# using the property system
set_gtk_property!(ent,:editable,false)
```
If you want to use the entry to retrieve passwords you can hide the visibility of the entered text.
This can be achieve by calling
```julia
set_gtk_property!(ent,:visibility,false)
```
To get notified by changes to the entry one can listen the "changed" event.

TODO: setting progress and setting icons in entry

## Search Entry

A special variant of the entry that can be used as a search box is `GtkSearchEntry`. It is equipped
with a button to clear the entry.

!!! note
    Currently `GtkSearchEntry` is not fully wrapped in Gtk.jl but if you add it using Glade, it can
    be used as an alternative to the ``GtkEntry`


