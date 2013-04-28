abstract GTKWidget
typealias GtkWidget Ptr{GTKWidget}

# All GTKWidgets are expected to have a handle field
# of type GtkWidget corresponding to the Gtk object
# and an all field which has type GdkRectangle
# corresponding to the rectangle allocated to the object
convert(::Type{GtkWidget},w::GTKWidget) = w.handle
width(w::GTKWidget) = w.all.width
height(w::GTKWidget) = w.all.height

typealias Enum Int32
baremodule GtkWindowType
    const GTK_WINDOW_TOPLEVEL = 0
    const GTK_WINDOW_POPUP = 1
end
baremodule GConnectFlags
    const G_CONNECT_AFTER = 1
    const G_CONNECT_SWAPPED = 2
end

const gtk_gc_preserve = ObjectIdDict()

function gc_unpreserve(w::GtkWidget, widget::GTKWidget)
    delete!(gtk_gc_preserve, widget)
    nothing
end
function gc_preserve(widget::GTKWidget)
    global gtk_gc_preserve
    on_signal_destroy(widget, gc_unpreserve)
    gtk_gc_preserve[widget] = widget
    widget
end
