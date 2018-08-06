macro version_stub(min_ver, code)
    name = code.args[2]
    if isa(name, Expr) # Expr(:<: , name, super)
        name = name.args[1]
    end
    quote
        if libgtk_version >= VersionNumber($(esc(min_ver)))
            $(esc(code))
        else
            mutable struct $(esc(name)) end
            $(esc(name))(x...) = error(string($(QuoteNode(name)), " is not available until Gtk", $esc(min_ver)))
        end
    end
end

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

@version_stub 3 mutable struct GdkFrameTimings <: GBoxed
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
            ccall((:gdk_pixbuf_format_copy, Gtk.libgdk_pixbuf), Nothing, (Ptr{GdkPixbufFormat},), ref))
        finalizer(x, x::GdkPixbufFormat->begin
                    ccall((:gdk_pixbuf_format_free, Gtk.libgdk_pixbuf), Nothing, (Ptr{GdkPixbufFormat},), x.handle)
                end)
        path
    end
end

@version_stub 3 mutable struct GtkCssSection <: GBoxed
    handle::Ptr{GtkCssSection}
    function GtkCssSection(ref::Ptr{GtkCssSection}, own::Bool = false)
        own || ccall((:gtk_css_section_ref, Gtk.libgtk), Nothing, (Ptr{GtkCssSection},), ref)
        x = new(ref)
        finalizer(x, x::GtkCssSection->begin
                    ccall((:gtk_css_section_unref, Gtk.libgtk), Nothing, (Ptr{GtkCssSection},), x.handle)
                end)
        path
    end
end

@version_stub 3 mutable struct GtkGradient <: GBoxed
    handle::Ptr{GtkGradient}
    function GtkGradient(ref::Ptr{GtkGradient}, own::Bool = false)
        own || ccall((:gtk_gradient_ref, Gtk.libgtk), Nothing, (Ptr{GtkGradient},), ref)
        x = new(ref)
        finalizer(x, x::GtkGradient->begin
                    ccall((:gtk_gradient_unref, Gtk.libgtk), Nothing, (Ptr{GtkGradient},), x.handle)
                end)
        path
    end
end

mutable struct GtkIconSet <: GBoxed
    handle::Ptr{GtkIconSet}
    function GtkIconSet(ref::Ptr{GtkIconSet}, own::Bool = false)
        own || ccall((:gtk_icon_set_ref, Gtk.libgtk), Nothing, (Ptr{GtkIconSet},), ref)
        x = new(ref)
        finalizer(x, x::GtkIconSet->begin
                    ccall((:gtk_icon_set_unref, Gtk.libgtk), Nothing, (Ptr{GtkIconSet},), x.handle)
                end)
        path
    end
end

mutable struct GtkIconSource <: GBoxed
    handle::Ptr{GtkIconSource}
    function GtkIconSource(ref::Ptr{GtkIconSource}, own::Bool = false)
        x = new( own ? ref :
            ccall((:gtk_icon_source_copy, Gtk.libgtk), Nothing, (Ptr{GtkIconSource},), ref))
        finalizer(x, x::GtkIconSource->begin
                    ccall((:gtk_icon_source_free, Gtk.libgtk), Nothing, (Ptr{GtkIconSource},), x.handle)
                end)
        path
    end
end

mutable struct GtkPaperSize <: GBoxed
    handle::Ptr{GtkPaperSize}
    function GtkPaperSize(ref::Ptr{GtkPaperSize}, own::Bool = false)
        x = new( own ? ref :
            ccall((:gtk_paper_size_copy, Gtk.libgtk), Nothing, (Ptr{GtkPaperSize},), ref))
        finalizer(x, x::GtkPaperSize->begin
                    ccall((:gtk_paper_size_free, Gtk.libgtk), Nothing, (Ptr{GtkPaperSize},), x.handle)
                end)
        path
    end
end

mutable struct GtkRecentInfo <: GBoxed
    handle::Ptr{GtkRecentInfo}
    function GtkRecentInfo(ref::Ptr{GtkRecentInfo}, own::Bool = false)
        own || ccall((:gtk_recent_info_ref, Gtk.libgtk), Nothing, (Ptr{GtkRecentInfo},), ref)
        x = new(ref)
        finalizer(x, x::GtkRecentInfo->begin
                    ccall((:gtk_recent_info_unref, Gtk.libgtk), Nothing, (Ptr{GtkRecentInfo},), x.handle)
                end)
        path
    end
end

@version_stub 3 mutable struct GtkSelectionData <: GBoxed
    handle::Ptr{GtkSelectionData}
    function GtkSelectionData(ref::Ptr{GtkSelectionData}, own::Bool = false)
        x = new( own ? ref :
            ccall((:gtk_selection_data_copy, Gtk.libgtk), Nothing, (Ptr{GtkSelectionData},), ref))
        finalizer(x, x::GtkSelectionData->begin
                    ccall((:gtk_selection_data_free, Gtk.libgtk), Nothing, (Ptr{GtkSelectionData},), x.handle)
                end)
        path
    end
end

@version_stub 3 mutable struct GtkSymbolicColor <: GBoxed
    handle::Ptr{GtkSymbolicColor}
    function GtkSymbolicColor(ref::Ptr{GtkSymbolicColor}, own::Bool = false)
        own || ccall((:gtk_symbolic_color_ref, Gtk.libgtk), Nothing, (Ptr{GtkSymbolicColor},), ref)
        x = new(ref)
        finalizer(x, x::GtkSymbolicColor->begin
                    ccall((:gtk_symbolic_color_unref, Gtk.libgtk), Nothing, (Ptr{GtkSymbolicColor},), x.handle)
                end)
        path
    end
end

mutable struct GtkTargetList <: GBoxed
    handle::Ptr{GtkTargetList}
    function GtkTargetList(ref::Ptr{GtkTargetList}, own::Bool = false)
        own || ccall((:gtk_target_list_ref, Gtk.libgtk), Nothing, (Ptr{GtkTargetList},), ref)
        x = new(ref)
        finalizer(x, x::GtkTargetList->begin
                    ccall((:gtk_target_list_unref, Gtk.libgtk), Nothing, (Ptr{GtkTargetList},), x.handle)
                end)
        path
    end
end

mutable struct GtkTextAttributes <: GBoxed
    handle::Ptr{GtkTextAttributes}
    function GtkTextAttributes(ref::Ptr{GtkTextAttributes}, own::Bool = false)
        own || ccall((:gtk_text_attributes_ref, Gtk.libgtk), Nothing, (Ptr{GtkTextAttributes},), ref)
        x = new(ref)
        finalizer(x, x::GtkTextAttributes->begin
                    ccall((:gtk_text_attributes_unref, Gtk.libgtk), Nothing, (Ptr{GtkTextAttributes},), x.handle)
                end)
        path
    end
end

mutable struct GtkTreeRowReference <: GBoxed
    handle::Ptr{GtkTreeRowReference}
    function GtkTreeRowReference(ref::Ptr{GtkTreeRowReference}, own::Bool = false)
        x = new( own ? ref :
            ccall((:gtk_tree_row_reference_copy, Gtk.libgtk), Nothing, (Ptr{GtkTreeRowReference},), ref))
        finalizer(x, x::GtkTreeRowReference->begin
                    ccall((:gtk_tree_row_reference_free, Gtk.libgtk), Nothing, (Ptr{GtkTreeRowReference},), x.handle)
                end)
        path
    end
end

@version_stub 3 mutable struct GtkWidgetPath <: GBoxed
    handle::Ptr{GtkWidgetPath}
    function GtkWidgetPath(ref::Ptr{GtkWidgetPath}, own::Bool = false)
        x = new( own ? ref :
            ccall((:gtk_widget_path_copy, Gtk.libgtk), Nothing, (Ptr{GtkWidgetPath},), ref))
        finalizer(x, x::GtkWidgetPath->begin
                    ccall((:gtk_widget_path_free, Gtk.libgtk), Nothing, (Ptr{GtkWidgetPath},), x.handle)
                end)
        path
    end
end
