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
void -	activate-default -	Action
void -	activate-focus -	Action
gboolean -	enable-debugging -	Action
void -	keys-changed -	Run First
void -	set-focus -	Run Last

#### Types and Values
GtkWindow<br>
struct -	GtkWindowClass
enum -	GtkWindowType
enum -	GtkWindowPosition

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
using Gtk

win = GtkWindow("New title")
hbox = GtkBox(:h)
push!(win, hbox)
cancel = GtkButton("Cancel")
ok = GtkButton("OK")
push!(hbox, cancel)
push!(hbox, ok)
showall(win)

![alt text](https://github.com/mikolajhojda/Gtk.jl/blob/master/docs/src/assets/window.png)


using Gtk

win = GtkWindowLeaf(title= "My own title", margin=0)
b = GtkButton("Click Me")
push!(win,b)
showall(win)

![alt text](https://github.com/mikolajhojda/Gtk.jl/blob/master/docs/src/assets/windowproperties.png)
