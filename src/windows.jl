function GtkWindowLeaf(title::Union(Nothing,StringLike)=nothing, w::Real=-1, h::Real=-1, resizable::Bool=true, toplevel::Bool=true)
    hnd = ccall((:gtk_window_new,libgtk),Ptr{GObject},(Enum,),
        toplevel?GtkWindowType.TOPLEVEL:GtkWindowType.POPUP)
    if title !== nothing
        ccall((:gtk_window_set_title,libgtk),Void,(Ptr{GObject},Ptr{Uint8}),hnd,title)
    end
    if resizable
        ccall((:gtk_window_set_default_size,libgtk),Void,(Ptr{GObject},Int32,Int32),hnd,w,h)
    else
        ccall((:gtk_window_set_resizable,libgtk),Void,(Ptr{GObject},Bool),hnd,false)
        ccall((:gtk_widget_set_size_request,libgtk),Void,(Ptr{GObject},Int32,Int32),hnd,w,h)
    end
    widget = GtkWindowLeaf(hnd)
    show(widget)
    widget
end

resize!(win::GtkWindow, w::Integer, h::Integer) = ccall((:gtk_window_resize,libgtk),Void,(Ptr{GObject},Int32,Int32),win,w,h)

present(win::GtkWindow) = ccall((:gtk_window_present,libgtk),Void,(Ptr{GObject},),win)

function push!(win::GtkWindow, accel_group::GtkAccelGroup)
  ccall((:gtk_window_add_accel_group,libgtk),Void,(Ptr{GObject},Ptr{GObject}),win,accel_group)
  win
end

function splice!(win::GtkWindow, accel_group::GtkAccelGroup)
  ccall((:gtk_window_remove_accel_group,libgtk),Void,(Ptr{GObject},Ptr{GObject}),win,accel_group)
  accel_group
end

GtkScrolledWindowLeaf() = GtkScrolledWindowLeaf(
    ccall((:gtk_scrolled_window_new,libgtk),Ptr{GObject},(Ptr{GObject},Ptr{GObject}),
                C_NULL,C_NULL))

function GtkDialogLeaf(title::StringLike, parent::GtkContainer, flags::Integer, buttons)
    w = GtkDialogLeaf(ccall((:gtk_dialog_new_with_buttons,libgtk), Ptr{GObject},
                (Ptr{Uint8},Ptr{GObject},Cint,Ptr{Void}),
                title, parent, flags, C_NULL))
    for (k,v) in buttons
        push!(w, k, v)
    end
    w
end

GtkAboutDialogLeaf() = GtkAboutDialogLeaf(
    ccall((:gtk_about_dialog_new,libgtk),Ptr{GObject},()))

function GtkMessageDialogLeaf(message::StringLike, buttons, flags::Integer, typ::Integer, parent = GtkNullContainer())
    w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new,libgtk), Ptr{GObject},
        (Ptr{GObject},Cint,Cint,Cint,Ptr{Uint8}),
        parent, flags, typ, GtkButtonsType.NONE, C_NULL))
    setproperty!(w, :text, bytestring(message))
    for (k,v) in buttons
        push!(w, k, v)
    end
    w
end

ask_dialog(message::String, parent = GtkNullContainer()) =
        ask_dialog(message, "Yes", "No", parent)

function ask_dialog(message::String, yes_text, no_text, parent = GtkNullContainer())
    dlg = @GtkMessageDialog(message, ((yes_text,1), (no_text,2)),
            GtkDialogFlags.DESTROY_WITH_PARENT, GtkMessageType.QUESTION, parent)
    response = run(dlg)
    destroy(dlg)
    response == 1
end

for (func, flag) in (
        (:info_dialog, GtkMessageType.INFO),
        (:warn_dialog, GtkMessageType.WARNING),
        (:error_dialog, GtkMessageType.ERROR))
    @eval function $func(message::String, parent = GtkNullContainer())
        w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new,libgtk), Ptr{GObject},
            (Ptr{GObject},Cint,Cint,Cint,Ptr{Uint8}),
            parent, GtkDialogFlags.DESTROY_WITH_PARENT,
            $flag, GtkButtonsType.CLOSE, C_NULL))
        setproperty!(w, :text, bytestring(message))
        run(w)
        destroy(w)
    end
end
