abstract GTKWidget
typealias GtkWidget Ptr{GTKWidget}

# All GTKWidgets are expected to have a handle field
# of type GtkWidget corresponding to the Gtk object
# and an all field which has type GdkRectangle
# corresponding to the rectangle allocated to the object
convert(::Type{GtkWidget},w::GTKWidget) = w.handle
width(w::GTKWidget) = w.all.width
height(w::GTKWidget) = w.all.height
show(io::IO, w::GTKWidget) = print(io, typeof(w))

typealias Enum Int32
baremodule GtkWindowType
    const GTK_WINDOW_TOPLEVEL = 0
    const GTK_WINDOW_POPUP = 1
end
baremodule GConnectFlags
    const G_CONNECT_AFTER = 1
    const G_CONNECT_SWAPPED = 2
end

const gc_preserve = ObjectIdDict() # reference counted closures
const gc_preserve_gtk = ObjectIdDict() # gtk objects

function gc_unref(x::ANY)
    global gc_preserve
    count = get(gc_preserve, x, 0)-1
    if count <= 0
        delete!(gc_preserve, x)
    end
    nothing
end
gc_unref(x::Any, ::Ptr{Void}) = gc_unref(x)
gc_unref_closure(T::Type) = cfunction(gc_unref, Void, (T, Ptr{Void}))

function gc_unref(x::GTKWidget)
    global gc_preserve_gtk
    delete!(gc_preserve_gtk, x)
    nothing
end
gc_unref(::GtkWidget, x::GTKWidget) = gc_unref(x)

function gc_ref(x::ANY)
    global gc_preserve
    gc_preserve[x] = (get(gc_preserve, x, 0)::Int)+1
    x
end

function gc_ref(x::GTKWidget)
    global gc_preserve_gtk
    if !contains(gc_preserve_gtk, x)
        on_signal_destroy(x, gc_unref, x)
        gc_preserve_gtk[x] = x
    end
    x
end
