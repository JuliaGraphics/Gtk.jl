# Text Widgets
---
There are two basic widgets available for rendering simple text. The one is for displaying non-editable text GtkLabel the other is for editable text GtkEntry.

## Label
A GtkLabel is the most basic text widget that has already been used behind the scene in any previous example involving a GtkButton. A GtkLabel is constructed by calling

>label = GtkLabel("My text")

The text of a label can be changed using

>GAccessor.text(label,"My other text")

Furthermore, a label has limited support for adding formatted text. This is done using the markup function:

>GAccessor.markup(label,"""<b>My bold text</b>\n<br>
                          <a href=\"https://www.gtk.org\"<br>
                         title=\"Our website\">GTK+ website</a>""")
                         
The syntax for this markup text is borrowed from html and explained here.

A label can be made selectable using

>GAccessor.selectable(label,true)

This can be used if the user should be allowed to copy the text.

The justification of a label can be changed in the following way:

>GAccessor.justify(label,Gtk.GConstants.GtkJustification.RIGHT)

Possible values of the enum GtkJustification are LEFT,RIGHT,CENTER, and FILL.

Automatic line wrapping can be enabled using

>GAccessor.text(label,repeat("Very long text! ",20))<br>
>GAccessor.line_wrap(label,true)

Note that this will only happen, if the size of the widget is limited using layout constraints.

## Entry
The entry widget allows the user to enter text. The entered text can be read and write using

>ent = GtkEntry()<br>
>set_gtk_property!(ent,:text,"My String")<br>
>str = get_gtk_property(ent,:text,String)

The maximum number of characters can be limited using set_gtk_property!(ent,:max_length,10).

Sometimes you might want to make the widget non-editable. This can be done by a call

>GAccessor.editable(GtkEditable(ent),false)<br>
>set_gtk_property!(ent,:editable,false)

If you want to use the entry to retrieve passwords you can hide the visibility of the entered text. This can be achieve by calling

>set_gtk_property!(ent,:visibility,false)

To get notified by changes to the entry one can listen the "changed" event.

TODO: setting progress and setting icons in entry

## Search Entry
A special variant of the entry that can be used as a search box is GtkSearchEntry. It is equipped with a button to clear the entry.

## Examples
### GtkLabel
>using Gtk
>
>win = GtkWindow("My First Gtk.jl Program", 400, 200)<br>
>label = GtkLabel("Hello World")<br>
>push!(win,label)<br>
>
>showall(win)

![alt text](https://github.com/mikolajhojda/Gtk.jl/blob/master/docs/src/assets/gtklabel.png)

#### GAccessor.text
>using Gtk
>
>win = GtkWindow("My First Gtk.jl Program", 400, 200)<br>
>label = GtkLabel("Hello World")<br>
>GAccessor.text(label,"My other text")<br>
>push!(win,label)
>
>showall(win)

![alt text](https://github.com/mikolajhojda/Gtk.jl/blob/master/docs/src/assets/GAccessor.text.png)

#### markup function
>using Gtk
>
>win = GtkWindow("My First Gtk.jl Program", 400, 200)<br>
>label = GtkLabel("Hello World")<br>
>GAccessor.markup(label,"""<b>My bold text</b>\n<br>
>                          <a href=\"https://www.gtk.org\"<br>
>                         title=\"Our website\">GTK+ website</a>""")<br>
>push!(win,label)
>
>showall(win)

![alt text](https://github.com/mikolajhojda/Gtk.jl/blob/master/docs/src/assets/markup%20function.png)

#### Automatic line wrapping
>using Gtk
>
>win = GtkWindow("My First Gtk.jl Program", 400, 200)<br>
>label = GtkLabel("Hello World")<br>
>GAccessor.text(label,repeat("Very long text! ",20))<br>
>GAccessor.line_wrap(label,true)<br>
>push!(win,label)
>
>showall(win)

![alt text](https://github.com/mikolajhojda/Gtk.jl/blob/master/docs/src/assets/automatic%20line%20wrapping.png)

### GtkEntry
>using Gtk
>
>win = GtkWindow("My First Gtk.jl Program", 400, 200)<br>
>ent = GtkEntry()<br>
>set_gtk_property!(ent,:text,"My String")<br>
>str = get_gtk_property(ent,:text,String)<br>
>push!(win,ent)
>
>showall(win)

![alt text](https://github.com/mikolajhojda/Gtk.jl/blob/master/docs/src/assets/gtkentry.png)
