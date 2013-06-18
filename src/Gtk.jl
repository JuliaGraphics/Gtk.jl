# julia Gtk interface

module Gtk
using Cairo

import Base: convert, show
import Base.Graphics: width, height, getgc

export GTKCanvas, Window, Canvas,
    width, height, reveal, configure, draw, cairo_context,
    gtk_doevent, GdkEventMask, GdkModifierType
export signal_connect, signal_disconnect,
    on_signal_destroy, on_signal_button_press,
    on_signal_button_release, on_signal_motion
#export Toplevel, Frame, Labelframe, Notebook, Panedwindow
#export Label, Button
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
#       get_width, set_width,
#       get_height, set_height,
#       get_size, set_size,
#       get_enabled, set_enabled,
#       get_editable, set_editable,
#       get_visible, set_visible,
#       set_position,
#       raise, focus, update, destroy


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
else
    const libgobject = "libgobject-2.0"
end

include("gtktypes.jl")
include("gdk.jl")
include("events.jl")
include("container.jl")
include("cairo.jl")

init()
end
