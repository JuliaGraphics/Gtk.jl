macro version_stub(min_ver, code)
    name = code.args[2]
    if isa(name,Expr) # Expr(:<:, name, super)
        name = name.args[1]
    end
    quote
        if gtk_version >= $(esc(min_ver))
            $(esc(code))
        else
            type $(esc(name)) end
            $(esc(name))(x...) = error(string($(QuoteNode(name))," is not available until Gtk", $esc(min_ver)))
        end
    end
end

type GClosure<:GBoxed
    handle::Ptr{GClosure}
    function GClosure(ref::Ptr{GClosure},own::Bool=false)
        own || ccall((:g_closure_ref,Gtk.GLib.libgobject),Void,(Ptr{GClosure},),ref)
        x = new(ref)
        finalizer(x,x::GClosure->begin
                    ccall((:g_closure_unref,Gtk.GLib.libgobject),Void,(Ptr{GClosure},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GdkFrameTimings<:GBoxed
    handle::Ptr{GdkFrameTimings}
    function GdkFrameTimings(ref::Ptr{GdkFrameTimings},own::Bool=false)
        own || ccall((:gdk_frame_timings_ref,Gtk.libgdk),Void,(Ptr{GdkFrameTimings},),ref)
        x = new(ref)
        finalizer(x,x::GdkFrameTimings->begin
                    ccall((:gdk_frame_timings_unref,Gtk.libgdk),Void,(Ptr{GdkFrameTimings},),x.handle)
                end)
        path
    end
end

type GdkPixbufFormat<:GBoxed
    handle::Ptr{GdkPixbufFormat}
    function GdkPixbufFormat(ref::Ptr{GdkPixbufFormat},own::Bool=false)
        x = new( own ? ref :
            ccall((:gdk_pixbuf_format_copy,Gtk.libgdk_pixbuf),Void,(Ptr{GdkPixbufFormat},),ref))
        finalizer(x,x::GdkPixbufFormat->begin
                    ccall((:gdk_pixbuf_format_free,Gtk.libgdk_pixbuf),Void,(Ptr{GdkPixbufFormat},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GtkCssSection<:GBoxed
    handle::Ptr{GtkCssSection}
    function GtkCssSection(ref::Ptr{GtkCssSection},own::Bool=false)
        own || ccall((:gtk_css_section_ref,Gtk.libgtk),Void,(Ptr{GtkCssSection},),ref)
        x = new(ref)
        finalizer(x,x::GtkCssSection->begin
                    ccall((:gtk_css_section_unref,Gtk.libgtk),Void,(Ptr{GtkCssSection},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GtkGradient<:GBoxed
    handle::Ptr{GtkGradient}
    function GtkGradient(ref::Ptr{GtkGradient},own::Bool=false)
        own || ccall((:gtk_gradient_ref,Gtk.libgtk),Void,(Ptr{GtkGradient},),ref)
        x = new(ref)
        finalizer(x,x::GtkGradient->begin
                    ccall((:gtk_gradient_unref,Gtk.libgtk),Void,(Ptr{GtkGradient},),x.handle)
                end)
        path
    end
end

type GtkIconSet<:GBoxed
    handle::Ptr{GtkIconSet}
    function GtkIconSet(ref::Ptr{GtkIconSet},own::Bool=false)
        own || ccall((:gtk_icon_set_ref,Gtk.libgtk),Void,(Ptr{GtkIconSet},),ref)
        x = new(ref)
        finalizer(x,x::GtkIconSet->begin
                    ccall((:gtk_icon_set_unref,Gtk.libgtk),Void,(Ptr{GtkIconSet},),x.handle)
                end)
        path
    end
end

type GtkIconSource<:GBoxed
    handle::Ptr{GtkIconSource}
    function GtkIconSource(ref::Ptr{GtkIconSource},own::Bool=false)
        x = new( own ? ref :
            ccall((:gtk_icon_source_copy,Gtk.libgtk),Void,(Ptr{GtkIconSource},),ref))
        finalizer(x,x::GtkIconSource->begin
                    ccall((:gtk_icon_source_free,Gtk.libgtk),Void,(Ptr{GtkIconSource},),x.handle)
                end)
        path
    end
end

type GtkPaperSize<:GBoxed
    handle::Ptr{GtkPaperSize}
    function GtkPaperSize(ref::Ptr{GtkPaperSize},own::Bool=false)
        x = new( own ? ref :
            ccall((:gtk_paper_size_copy,Gtk.libgtk),Void,(Ptr{GtkPaperSize},),ref))
        finalizer(x,x::GtkPaperSize->begin
                    ccall((:gtk_paper_size_free,Gtk.libgtk),Void,(Ptr{GtkPaperSize},),x.handle)
                end)
        path
    end
end

type GtkRecentInfo<:GBoxed
    handle::Ptr{GtkRecentInfo}
    function GtkRecentInfo(ref::Ptr{GtkRecentInfo},own::Bool=false)
        own || ccall((:gtk_recent_info_ref,Gtk.libgtk),Void,(Ptr{GtkRecentInfo},),ref)
        x = new(ref)
        finalizer(x,x::GtkRecentInfo->begin
                    ccall((:gtk_recent_info_unref,Gtk.libgtk),Void,(Ptr{GtkRecentInfo},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GtkSelectionData<:GBoxed
    handle::Ptr{GtkSelectionData}
    function GtkSelectionData(ref::Ptr{GtkSelectionData},own::Bool=false)
        x = new( own ? ref :
            ccall((:gtk_selection_data_copy,Gtk.libgtk),Void,(Ptr{GtkSelectionData},),ref))
        finalizer(x,x::GtkSelectionData->begin
                    ccall((:gtk_selection_data_free,Gtk.libgtk),Void,(Ptr{GtkSelectionData},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GtkSymbolicColor<:GBoxed
    handle::Ptr{GtkSymbolicColor}
    function GtkSymbolicColor(ref::Ptr{GtkSymbolicColor},own::Bool=false)
        own || ccall((:gtk_symbolic_color_ref,Gtk.libgtk),Void,(Ptr{GtkSymbolicColor},),ref)
        x = new(ref)
        finalizer(x,x::GtkSymbolicColor->begin
                    ccall((:gtk_symbolic_color_unref,Gtk.libgtk),Void,(Ptr{GtkSymbolicColor},),x.handle)
                end)
        path
    end
end

type GtkTargetList<:GBoxed
    handle::Ptr{GtkTargetList}
    function GtkTargetList(ref::Ptr{GtkTargetList},own::Bool=false)
        own || ccall((:gtk_target_list_ref,Gtk.libgtk),Void,(Ptr{GtkTargetList},),ref)
        x = new(ref)
        finalizer(x,x::GtkTargetList->begin
                    ccall((:gtk_target_list_unref,Gtk.libgtk),Void,(Ptr{GtkTargetList},),x.handle)
                end)
        path
    end
end

type GtkTextAttributes<:GBoxed
    handle::Ptr{GtkTextAttributes}
    function GtkTextAttributes(ref::Ptr{GtkTextAttributes},own::Bool=false)
        own || ccall((:gtk_text_attributes_ref,Gtk.libgtk),Void,(Ptr{GtkTextAttributes},),ref)
        x = new(ref)
        finalizer(x,x::GtkTextAttributes->begin
                    ccall((:gtk_text_attributes_unref,Gtk.libgtk),Void,(Ptr{GtkTextAttributes},),x.handle)
                end)
        path
    end
end

type GtkTreeRowReference<:GBoxed
    handle::Ptr{GtkTreeRowReference}
    function GtkTreeRowReference(ref::Ptr{GtkTreeRowReference},own::Bool=false)
        x = new( own ? ref :
            ccall((:gtk_tree_row_reference_copy,Gtk.libgtk),Void,(Ptr{GtkTreeRowReference},),ref))
        finalizer(x,x::GtkTreeRowReference->begin
                    ccall((:gtk_tree_row_reference_free,Gtk.libgtk),Void,(Ptr{GtkTreeRowReference},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GtkWidgetPath<:GBoxed
    handle::Ptr{GtkWidgetPath}
    function GtkWidgetPath(ref::Ptr{GtkWidgetPath},own::Bool=false)
        x = new( own ? ref :
            ccall((:gtk_widget_path_copy,Gtk.libgtk),Void,(Ptr{GtkWidgetPath},),ref))
        finalizer(x,x::GtkWidgetPath->begin
                    ccall((:gtk_widget_path_free,Gtk.libgtk),Void,(Ptr{GtkWidgetPath},),x.handle)
                end)
        path
    end
end
