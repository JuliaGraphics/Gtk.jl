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
    function GClosure(ref::Ptr{GClosure})
        ccall((:g_closure_ref,Gtk.GLib.libgobject),Void,(Ptr{Void},),ref)
        x = new(ref)
        finalizer(x,x::GClosure->begin 
                    ccall((:g_closure_unref,Gtk.GLib.libgobject),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GdkFrameTimings<:GBoxed
    handle::Ptr{GdkFrameTimings}
    function GdkFrameTimings(ref::Ptr{GdkFrameTimings})
        ccall((:gdk_frame_timings_ref,Gtk.libgdk),Void,(Ptr{Void},),ref)
        x = new(ref)
        finalizer(x,x::GdkFrameTimings->begin 
                    ccall((:gdk_frame_timings_unref,Gtk.libgdk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

type GdkPixbufFormat<:GBoxed
    handle::Ptr{GdkPixbufFormat}
    function GdkPixbufFormat(ref::Ptr{GdkPixbufFormat})
        x = new(ref)
        finalizer(x,x::GdkPixbufFormat->begin 
                    ccall((:gdk_pixbuf_format_free,Gtk.libgdk_pixbuf),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GtkCssSection<:GBoxed
    handle::Ptr{GtkCssSection}
    function GtkCssSection(ref::Ptr{GtkCssSection})
        ccall((:gtk_css_section_ref,Gtk.libgtk),Void,(Ptr{Void},),ref)
        x = new(ref)
        finalizer(x,x::GtkCssSection->begin 
                    ccall((:gtk_css_section_unref,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GtkGradient<:GBoxed
    handle::Ptr{GtkGradient}
    function GtkGradient(ref::Ptr{GtkGradient})
        ccall((:gtk_gradient_ref,Gtk.libgtk),Void,(Ptr{Void},),ref)
        x = new(ref)
        finalizer(x,x::GtkGradient->begin 
                    ccall((:gtk_gradient_unref,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

type GtkIconSet<:GBoxed
    handle::Ptr{GtkIconSet}
    function GtkIconSet(ref::Ptr{GtkIconSet})
        ccall((:gtk_icon_set_ref,Gtk.libgtk),Void,(Ptr{Void},),ref)
        x = new(ref)
        finalizer(x,x::GtkIconSet->begin 
                    ccall((:gtk_icon_set_unref,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

type GtkIconSource<:GBoxed
    handle::Ptr{GtkIconSource}
    function GtkIconSource(ref::Ptr{GtkIconSource})
        x = new(ref)
        finalizer(x,x::GtkIconSource->begin 
                    ccall((:gtk_icon_source_free,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

type GtkPaperSize<:GBoxed
    handle::Ptr{GtkPaperSize}
    function GtkPaperSize(ref::Ptr{GtkPaperSize})
        x = new(ref)
        finalizer(x,x::GtkPaperSize->begin 
                    ccall((:gtk_paper_size_free,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

type GtkRecentInfo<:GBoxed
    handle::Ptr{GtkRecentInfo}
    function GtkRecentInfo(ref::Ptr{GtkRecentInfo})
        ccall((:gtk_recent_info_ref,Gtk.libgtk),Void,(Ptr{Void},),ref)
        x = new(ref)
        finalizer(x,x::GtkRecentInfo->begin 
                    ccall((:gtk_recent_info_unref,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GtkSelectionData<:GBoxed
    handle::Ptr{GtkSelectionData}
    function GtkSelectionData(ref::Ptr{GtkSelectionData})
        x = new(ref)
        finalizer(x,x::GtkSelectionData->begin 
                    ccall((:gtk_selection_data_free,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GtkSymbolicColor<:GBoxed
    handle::Ptr{GtkSymbolicColor}
    function GtkSymbolicColor(ref::Ptr{GtkSymbolicColor})
        ccall((:gtk_symbolic_color_ref,Gtk.libgtk),Void,(Ptr{Void},),ref)
        x = new(ref)
        finalizer(x,x::GtkSymbolicColor->begin 
                    ccall((:gtk_symbolic_color_unref,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

type GtkTargetList<:GBoxed
    handle::Ptr{GtkTargetList}
    function GtkTargetList(ref::Ptr{GtkTargetList})
        ccall((:gtk_target_list_ref,Gtk.libgtk),Void,(Ptr{Void},),ref)
        x = new(ref)
        finalizer(x,x::GtkTargetList->begin 
                    ccall((:gtk_target_list_unref,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

type GtkTextAttributes<:GBoxed
    handle::Ptr{GtkTextAttributes}
    function GtkTextAttributes(ref::Ptr{GtkTextAttributes})
        ccall((:gtk_text_attributes_ref,Gtk.libgtk),Void,(Ptr{Void},),ref)
        x = new(ref)
        finalizer(x,x::GtkTextAttributes->begin 
                    ccall((:gtk_text_attributes_unref,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

type GtkTreeRowReference<:GBoxed
    handle::Ptr{GtkTreeRowReference}
    function GtkTreeRowReference(ref::Ptr{GtkTreeRowReference})
        x = new(ref)
        finalizer(x,x::GtkTreeRowReference->begin 
                    ccall((:gtk_tree_row_reference_free,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end

@version_stub 3 type GtkWidgetPath<:GBoxed
    handle::Ptr{GtkWidgetPath}
    function GtkWidgetPath(ref::Ptr{GtkWidgetPath})
        x = new(ref)
        finalizer(x,x::GtkWidgetPath->begin 
                    ccall((:gtk_widget_path_free,Gtk.libgtk),Void,(Ptr{Void},),x.handle)
                end)
        path
    end
end
