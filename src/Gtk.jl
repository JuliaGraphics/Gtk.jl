# julia Gtk interface

module Gtk
using Cairo

import Base: convert, show, showall, size, getindex, setindex!, push!, delete!, start, next, done
import Base.Graphics: width, height, getgc

# generic interface:
export Window, Canvas, #TopLevel=Window
    width, height, size, #minsize, maxsize
    reveal, configure, draw, cairo_context,
    length, add!, delete!, visible

    #property, margin, padding, align
    #raise, focus, destroy, enabled

# Gtk objects
export GtkCanvas, GtkBox, GtkButtonBox, GtkPaned, GtkLayout, GtkNotebook,
    GtkExpander, GtkOverlay,
    GtkLabel

# Gtk3 objects
export GtkGrid, GtkOrientable

# Gtk2 objects
export GtkTable, GtkAlignment

# Gtk-specific event handling
export gtk_doevent, GdkEventMask, GdkModifierType,
    signal_connect, signal_disconnect,
    on_signal_destroy, on_signal_button_press,
    on_signal_button_release, on_signal_motion

# Tk-compatibility (missing):
#export Frame, Labelframe, Notebook, Panedwindow
#export Button
#export Checkbutton, Radio, Combobox
#export Slider, Spinbox
#export Entry, set_validation, Text
#export Treeview, selected_nodes, node_insert, node_move, node_delete, node_open
#export tree_headers, tree_column_widths, tree_key_header, tree_key_width
#export Sizegrip, Separator, Progressbar, Image, Scrollbar
#export Menu, menu_add
#export GetOpenFile, GetSaveFile, ChooseDirectory, Messagebox
#export scrollbars_add
#export get_value, set_value,
#       get_items, set_items,
#       get_editable, set_editable,
#       set_position


const gtk_version = 2 # This is the only configuration option

if gtk_version == 3
    const libgtk = "libgtk-3"
    const libgdk = "libgdk-3"
elseif gtk_version == 2
    if OS_NAME == :Darwin
        const libgtk = "libgtk-quartz-2.0"
        const libgdk = "libgdk-quartz-2.0"
    elseif OS_NAME == :Windows
        const libgtk = "libgtk-win32-2.0-0"
        const libgdk = "libgdk-win32-2.0-0"
    else
        const libgtk = "libgtk-x11-2.0"
        const libgdk = "libgdk-x11-2.0"
    end
else
    error("Unsupported Gtk version $gtk_version")
end
if OS_NAME == :Windows
    const libgobject = "libgobject-2.0-0"
    const libglib = "libglib-2.0-0"
else
    const libgobject = "libgobject-2.0"
    const libglib = "libglib-2.0"
end


include("gtktypes.jl")
include("gdk.jl")
include("events.jl")
include("windows.jl")
include("layout.jl")
include("displays.jl")
include("buttons.jl")
include("input.jl")
include("text.jl")
include("menus.jl")
include("selectors.jl")
include("misc.jl")
include("cairo.jl")
include("container.jl")

init()
end
