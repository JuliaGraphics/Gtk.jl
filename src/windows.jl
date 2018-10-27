function GtkWindowLeaf(title::Union{Nothing, AbstractStringLike} = nothing, w::Real = -1, h::Real = -1, resizable::Bool = true, toplevel::Bool = true)
    hnd = ccall((:gtk_window_new, libgtk), Ptr{GObject}, (GEnum,),
        toplevel ? GtkWindowType.TOPLEVEL : GtkWindowType.POPUP)
    if title !== nothing
        ccall((:gtk_window_set_title, libgtk), Nothing, (Ptr{GObject}, Ptr{UInt8}), hnd, title)
    end
    if resizable
        ccall((:gtk_window_set_default_size, libgtk), Nothing, (Ptr{GObject}, Int32, Int32), hnd, w, h)
    else
        ccall((:gtk_window_set_resizable, libgtk), Nothing, (Ptr{GObject}, Bool), hnd, false)
        ccall((:gtk_widget_set_size_request, libgtk), Nothing, (Ptr{GObject}, Int32, Int32), hnd, w, h)
    end
    widget = GtkWindowLeaf(hnd)
    show(widget)
    widget
end

resize!(win::GtkWindow, w::Integer, h::Integer) = ccall((:gtk_window_resize, libgtk), Nothing, (Ptr{GObject}, Int32, Int32), win, w, h)

present(win::GtkWindow) = ccall((:gtk_window_present, libgtk), Nothing, (Ptr{GObject},), win)

fullscreen(win::GtkWindow) = ccall((:gtk_window_fullscreen, libgtk), Nothing, (Ptr{GObject},), win)
unfullscreen(win::GtkWindow) = ccall((:gtk_window_unfullscreen, libgtk), Nothing, (Ptr{GObject},), win)

maximize(win::GtkWindow) = ccall((:gtk_window_maximize, libgtk), Nothing, (Ptr{GObject},), win)
unmaximize(win::GtkWindow) = ccall((:gtk_window_unmaximize, libgtk), Nothing, (Ptr{GObject},), win)

function push!(win::GtkWindow, accel_group::GtkAccelGroup)
  ccall((:gtk_window_add_accel_group, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}), win, accel_group)
  win
end

function splice!(win::GtkWindow, accel_group::GtkAccelGroup)
  ccall((:gtk_window_remove_accel_group, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}), win, accel_group)
  accel_group
end

GtkScrolledWindowLeaf() = GtkScrolledWindowLeaf(
    ccall((:gtk_scrolled_window_new, libgtk), Ptr{GObject}, (Ptr{GObject}, Ptr{GObject}),
                C_NULL, C_NULL))

#if VERSION >= v"0.4-"
#GtkDialogLeaf(title::AbstractStringLike, parent::GtkContainer, flags::Integer, buttons::Pair...; kwargs...) =
#    GtkDialogLeaf(title, parent, flags, buttons; kwargs...)
#end
function GtkDialogLeaf(title::AbstractStringLike, parent::GtkContainer, flags::Integer, buttons; kwargs...)
    w = GtkDialogLeaf(ccall((:gtk_dialog_new_with_buttons, libgtk), Ptr{GObject},
                (Ptr{UInt8}, Ptr{GObject}, Cint, Ptr{Nothing}),
                title, parent, flags, C_NULL); kwargs...)
    for (k, v) in buttons
        push!(w, k, v)
    end
    w
end

GtkAboutDialogLeaf() = GtkAboutDialogLeaf(
    ccall((:gtk_about_dialog_new, libgtk), Ptr{GObject}, ()))

function GtkMessageDialogLeaf(message::AbstractStringLike, buttons, flags::Integer, typ::Integer, parent = GtkNullContainer(); kwargs...)
    w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new, libgtk), Ptr{GObject},
        (Ptr{GObject}, Cint, Cint, Cint, Ptr{UInt8}),
        parent, flags, typ, GtkButtonsType.NONE, C_NULL); kwargs...)
    set_gtk_property!(w, :text, message)
    for (k, v) in buttons
        push!(w, k, v)
    end
    w
end

ask_dialog(message::AbstractString, parent = GtkNullContainer()) =
        ask_dialog(message, "No", "Yes", parent)

function ask_dialog(message::AbstractString, no_text, yes_text, parent = GtkNullContainer())
    dlg = GtkMessageDialog(message, ((no_text, 0), (yes_text, 1)),
            GtkDialogFlags.DESTROY_WITH_PARENT, GtkMessageType.QUESTION, parent)
    response = run(dlg)
    destroy(dlg)
    response == 1
end

for (func, flag) in (
        (:info_dialog, :(GtkMessageType.INFO)),
        (:warn_dialog, :(GtkMessageType.WARNING)),
        (:error_dialog, :(GtkMessageType.ERROR)))
    @eval function $func(message::AbstractString, parent = GtkNullContainer())
        w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new, libgtk), Ptr{GObject},
            (Ptr{GObject}, Cint, Cint, Cint, Ptr{UInt8}),
            parent, GtkDialogFlags.DESTROY_WITH_PARENT,
            $flag, GtkButtonsType.CLOSE, C_NULL))
        set_gtk_property!(w, :text, message)
        run(w)
        destroy(w)
    end
end

function input_dialog(message::AbstractString, entry_default::AbstractString, buttons = (("Cancel", 0), ("Accept", 1)), parent = GtkNullContainer())
    widget = GtkMessageDialog(message, buttons, GtkDialogFlags.DESTROY_WITH_PARENT, GtkMessageType.INFO, parent)
    box = content_area(widget)
    entry = GtkEntry(; text = entry_default)
    push!(box, entry)
    showall(widget)
    resp = run(widget)
    entry_text = get_gtk_property(entry, :text, String)
    destroy(widget)
    return resp, entry_text
end

function content_area(widget::GtkDialog)
    boxp = ccall((:gtk_dialog_get_content_area, libgtk), Ptr{GObject},
                 (Ptr{GObject},), widget)
    convert(GtkBoxLeaf, boxp)
end

#TODO: GtkSeparator — A separator widget

# this could be in a new file, but needs to be defined after GConstants
get_default_mod_mask() = ccall((:gtk_accelerator_get_default_mod_mask , libgtk),typeof(GConstants.GdkModifierType.CONTROL),())