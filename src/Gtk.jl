# julia Gtk interface

module Gtk
using Cairo

import Base: convert, show
import Base.Graphics: width, height, getgc

export GTKCanvas, Window, Canvas,
    width, height, reveal, cairo_context,
    gtk_doevent

export signal_connect, signal_disconnect,
    on_signal_destroy, on_signal_redraw

const gtk_version = 2 # This is the only configuration option

if gtk_version == 3
    const libgtk = "libgtk-3"
elseif gtk_version == 2
    if OS_NAME == :Darwin
        const libgtk = "libgtk-quartz-2.0"
    elseif OS_NAME == :Windows
        const libgtk = "libgtk-win32-2.0-0"
    else
        const libgtk = "libgtk-x11-2.0"
    end
else
    error("Unsupported Gtk version $gtk_version")
end

include("gtktypes.jl")
include("gdk.jl")
include("events.jl")
include("window.jl")
include("cairo.jl")

init()
end
