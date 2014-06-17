#https://developer.gnome.org/gtk2/stable/SelectorWidgets.html

#GtkColorButton — A button to launch a color selection dialog
#GtkColorSelectionDialog — A standard dialog box for selecting a color
#GtkColorSelection — A widget used to select a color
#GtkHSV — A 'color wheel' widget
#GtkFileChooser — File chooser interface used by GtkFileChooserWidget and GtkFileChooserDialog
#GtkFileChooserButton — A button to launch a file selection dialog
#GtkFileChooserDialog — A file chooser dialog, suitable for "File/Open" or "File/Save" commands
#GtkFileChooserWidget — File chooser widget that can be embedded in other widgets
#GtkFileFilter — A filter for selecting a file subset
#GtkFontButton — A button to launch a font selection dialog
#GtkFontSelection — A widget for selecting fonts
#GtkFontSelectionDialog — A dialog box for selecting fonts
#GtkInputDialog — Configure devices for the XInput extension

push!(widget::GtkDialog, text::String, response::Integer) =
    ccall((:gtk_dialog_add_button,libgtk), Ptr{GObject},
          (Ptr{GObject},Ptr{Uint8},Cint), widget, text, response)

@gtktype GtkFileChooserDialog
function GtkFileChooserDialogLeaf(title::String, parent::GtkContainer, action::Integer, button_text_response...)
    n = length(button_text_response)
    if !iseven(n)
        error("button_text_response must consist of text/response pairs")
    end
    w = GtkFileChooserDialogLeaf(ccall((:gtk_file_chooser_dialog_new,libgtk), Ptr{GObject},
                (Ptr{Uint8},Ptr{GObject},Cint,Ptr{Void}),
                title, parent, action, C_NULL))
    for i = 1:2:n
        push!(w, button_text_response[i], button_text_response[i+1])
    end
    w
end

run(widget::GtkDialog) = ccall((:gtk_dialog_run,libgtk), Cint, (Ptr{GObject},), widget)

@gtktype GtkFileFilter
function GtkFileFilterLeaf(; name::Union(ByteString,Nothing) = nothing, pattern::ByteString = "", mimetype::ByteString = "")
    filt = ccall((:gtk_file_filter_new,libgtk), Ptr{GObject}, ())
    if !isempty(pattern)
        name == nothing && (name = pattern)
        for p in split(pattern, ",")
            ccall((:gtk_file_filter_add_pattern,libgtk), Void, (Ptr{GObject}, Ptr{Uint8}), filt, p)
        end
    elseif !isempty(mimetype)
        name == nothing && (name = mimetype)
        for m in split(mimetype, ",")
            ccall((:gtk_file_filter_add_mime_type,libgtk), Void, (Ptr{GObject}, Ptr{Uint8}), filt, m)
        end
    else
        ccall((:gtk_file_filter_add_pixbuf_formats,libgtk), Void, (Ptr{GObject},), filt)
    end
    ccall((:gtk_file_filter_set_name,libgtk), Void, (Ptr{GObject}, Ptr{Uint8}), filt, isempty(name) || name==nothing ? C_NULL : name)
    filt
end
GtkFileFilterLeaf(pattern::ByteString; name::Union(ByteString,Nothing) = nothing) = GtkFileFilterLeaf(; name=name, pattern=pattern)

GtkFileFilterLeaf(filter::GtkFileFilterLeaf) = filter

function makefilters(dlgp::GtkFileChooser, filters::Union(AbstractVector,Tuple))
    for f in filters
        ccall((:gtk_file_chooser_add_filter,libgtk), Void, (Ptr{GObject}, Ptr{GObject}), dlgp, @GtkFileFilter(f))
    end
end

function open_dialog(title::String; parent = nothing, filters::Union(AbstractVector,Tuple) = ASCIIString[], multiple::Bool = false)
    haveparent = parent != nothing
    if !haveparent
        parent = @GtkWindow()
        visible(parent, false)
    end
    dlg = @GtkFileChooserDialog(title, parent, GConstants.GtkFileChooserAction.OPEN,
                                "_Cancel", GConstants.GtkResponseType.CANCEL,
                                "_Open",   GConstants.GtkResponseType.ACCEPT)
    setproperty!(dlg, :select_multiple, multiple)
    dlgp = GtkFileChooser(dlg)
    if !isempty(filters)
        makefilters(dlgp, filters)
    end
    response = run(dlg)
    local selection
    if response == GConstants.GtkResponseType.ACCEPT
        if multiple
            selection = UTF8String[]
            for f in GLib.GList(ccall((:gtk_file_chooser_get_filenames,libgtk), Ptr{_GSList{Uint8}}, (Ptr{GObject},), dlgp))
                push!(selection, GLib.bytestring(f, true))
            end
        else
            selection = bytestring(GAccessor.filename(dlgp))
        end
    else
        if multiple
            selection = UTF8String[]
        else
            selection = utf8("")
        end
    end
    destroy(dlg)
    !haveparent && destroy(parent)
    selection
end

function save_dialog(title::String; parent = nothing, filters::Union(AbstractVector,Tuple) = ASCIIString[])
    haveparent = parent != nothing
    if !haveparent
        parent = @GtkWindow()
        visible(parent, false)
    end
    dlg = @GtkFileChooserDialog(title, parent, GConstants.GtkFileChooserAction.SAVE,
                                "_Cancel", GConstants.GtkResponseType.CANCEL,
                                "_Save",   GConstants.GtkResponseType.ACCEPT)
    dlgp = GtkFileChooser(dlg)
    if !isempty(filters)
        makefilters(dlgp, filters)
    end
    ccall((:gtk_file_chooser_set_do_overwrite_confirmation,libgtk), Void, (Ptr{GObject}, Cint), dlg, true)
    response = run(dlg)
    if response == GConstants.GtkResponseType.ACCEPT
        selection = bytestring(GAccessor.filename(dlgp))
    else
        selection = utf8("")
    end
    destroy(dlg)
    !haveparent && destroy(parent)
    selection
end
