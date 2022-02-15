mutable struct GClosure <: GBoxed
    handle::Ptr{GClosure}
    function GClosure(ref::Ptr{GClosure}, own::Bool = false)
        own || ccall((:g_closure_ref, Gtk.GLib.libgobject), Nothing, (Ptr{GClosure},), ref)
        x = new(ref)
        finalizer(x::GClosure->begin
                    ccall((:g_closure_unref, Gtk.GLib.libgobject), Nothing, (Ptr{GClosure},), x.handle)
                end, x)
        path
    end
end

mutable struct GdkFrameTimings <: GBoxed
    handle::Ptr{GdkFrameTimings}
    function GdkFrameTimings(ref::Ptr{GdkFrameTimings}, own::Bool = false)
        own || ccall((:gdk_frame_timings_ref, Gtk.libgdk), Nothing, (Ptr{GdkFrameTimings},), ref)
        x = new(ref)
        finalizer(x, x::GdkFrameTimings->begin
                    ccall((:gdk_frame_timings_unref, Gtk.libgdk), Nothing, (Ptr{GdkFrameTimings},), x.handle)
                end)
        path
    end
end

mutable struct GdkPixbufFormat <: GBoxed
    handle::Ptr{GdkPixbufFormat}
    function GdkPixbufFormat(ref::Ptr{GdkPixbufFormat}, own::Bool = false)
        x = new( own ? ref :
            ccall((:gdk_pixbuf_format_copy, Gtk.libgdkpixbuf), Nothing, (Ptr{GdkPixbufFormat},), ref))
        finalizer(x, x::GdkPixbufFormat->begin
                    ccall((:gdk_pixbuf_format_free, Gtk.libgdkpixbuf), Nothing, (Ptr{GdkPixbufFormat},), x.handle)
                end)
        path
    end
end
