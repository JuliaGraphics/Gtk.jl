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

push!(widget::GtkDialogI, text::String, response::Integer) =
    ccall((:gtk_dialog_add_button,libgtk), Ptr{GObject},
          (Ptr{GObject},Ptr{Uint8},Cint), widget, text, response)

@GType GtkFileChooserDialog <: GtkDialog
function GtkFileChooserDialog(title::String, parent::GtkContainerI, action::Integer, button_text_response...)
    n = length(button_text_response)
    if !iseven(n)
        error("button_text_response must consist of text/response pairs")
    end
    hnd = ccall((:gtk_file_chooser_dialog_new,libgtk), Ptr{GObject},
                (Ptr{Uint8},Ptr{GObject},Cint,Ptr{Void}),
                title, parent, action, C_NULL)
    for i = 1:2:n
        push!(hnd, button_text_response[i], button_text_response[i+1])
    end
    widget = GtkFileChooserDialog(hnd)
    show(widget)
    widget
end

run(widget::GtkDialogI) = ccall((:gtk_dialog_run,libgtk), Cint, (Ptr{GObject},), widget)

baremodule GtkFileChooserAction
    const OPEN = 0
    const SAVE = 1
    const SELECT_FOLDER = 2
    const CREATE_FOLDER = 3
end

baremodule GtkStock
    const CANCEL = "gtk-cancel"
    const OPEN = "gtk-open"
    const SAVE = "gtk-save"
    const SAVE_AS = "gtk-save-as"
end

baremodule GtkResponse
    const NONE         = -1
    const REJECT       = -2
    const ACCEPT       = -3
    const DELETE_EVENT = -4
    const OK           = -5
    const CANCEL       = -6
    const CLOSE        = -7
    const YES          = -8
    const NO           = -9
    const APPLY        = -10
    const HELP         = -11
end
