## Overview
Toplevel which can contain other widgets

A GtkWindow is a toplevel window which can contain other widgets. Windows normally have decorations that are under the control of the windowing system and allow the user to manipulate the window (resize it, move it, close it,...).

### Properties
gboolean -	accept-focus -	Read / Write<br>
GtkApplication * -	application -	Read / Write<br>
GtkWidget * -	attached-to -	Read / Write / Construct<br>
gboolean -	decorated -	Read / Write<br>
gint -	default-height -	Read / Write<br>
gint -	default-width -	Read / Write<br>
gboolean -  	deletable -	Read / Write<br>
gboolean -	destroy-with-parent -	Read / Write<br>
gboolean -	focus-on-map -	Read / Write<br>
gboolean -	focus-visible -	Read / Write<br>
GdkGravity -	gravity -	Read / Write<br>
gboolean -	has-resize-grip --	Read / Write<br>
gboolean -	has-toplevel-focus -	Read<br>
gboolean -	hide-titlebar-when-maximized -	Read / Write<br>
GdkPixbuf * -	icon -	Read / Write<br>
gchar * -	icon-name -	Read / Write<br>
gboolean -	is-active -	Read<br>
gboolean -	is-maximized -	Read<br>
gboolean -	mnemonics-visible -	Read / Write<br>
gboolean -	modal -	Read / Write<br>
gboolean -	resizable -	Read / Write<br>
gboolean -	resize-grip-visible -	Read<br>
gchar * -	role -	Read / Write<br>
GdkScreen * -	screen -	Read / Write<br>
gboolean -	skip-pager-hint -	Read / Write<br>
gboolean -	skip-taskbar-hint -	Read / Write<br>
gchar * -	startup-id -	Write<br>
gchar * -	title -	Read / Write<br>
GtkWindow * -	transient-for -	Read / Write / Construct<br>
GtkWindowType -	type -	Read / Write / Construct Only<br>
GdkWindowTypeHint -	type-hint -	Read / Write<br>
gboolean -	urgency-hint -	Read / Write<br>
GtkWindowPosition -	window-position -	Read / Write<br>

#### Style Properties
gchar * -	decoration-button-layout -	Read<br>
gint -	decoration-resize-handle -	Read / Write<br>

#### Signals
void -	activate-default -	Action<br>
void -	activate-focus -	Action<br>
gboolean -	enable-debugging -	Action<br>
void -	keys-changed -	Run First<br>
void -	set-focus -	Run Last<br>

#### Types and Values
GtkWindow<br>
struct -	GtkWindowClass<br>
enum -	GtkWindowType<br>
enum -	GtkWindowPosition<br>

#### Object Hierarchy
    +- GObject
    .  +- GInitiallyUnowned
    .  .  +- GtkWidget
    .  .  .  +- GtkContainer
    .  .  .  .  +- GtkBin
    .  .  .  .  .  +- GtkWindow
    .  .  .  .  .  .  +- GtkDialog
    .  .  .  .  .  .  +- GtkApplicationWindow
    .  .  .  .  .  .  +- GtkAssistant
    .  .  .  .  .  .  +- GtkOffscreenWindow
    .  .  .  .  .  .  +- GtkPlug
    .  .  .  .  .  .  +- GtkShortcutsWindow
                        
#### Examples

##### Basic window
using Gtk<br>

win = GtkWindow("New title")<br>
hbox = GtkBox(:h)<br>
push!(win, hbox)<br>
cancel = GtkButton("Cancel")<br>
ok = GtkButton("OK")<br>
push!(hbox, cancel)<br>
push!(hbox, ok)<br>
showall(win)<br>

![alt text](https://github.com/mikolajhojda/Gtk.jl/blob/master/docs/src/assets/window.png)

##### Using window with properties
using Gtk<br>

win = GtkWindowLeaf(title= "My own title", margin=0)<br>
b = GtkButton("Click Me")<br>
push!(win,b)<br>
showall(win)<br>

![alt text](https://github.com/mikolajhojda/Gtk.jl/blob/master/docs/src/assets/windowproperties.png)
