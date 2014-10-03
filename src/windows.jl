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
    for key in keys(buttons)
        push!(w, key, buttons[key])
    end
    w
end

GtkAboutDialogLeaf() = GtkAboutDialogLeaf(
    ccall((:gtk_about_dialog_new,libgtk),Ptr{GObject},()))

function GtkMessageDialogLeaf(parent::GtkContainer, flag::Integer, typ::Integer,
                          button::Integer, message::StringLike)
    GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new,libgtk), Ptr{GObject},
                (Ptr{GObject},Cint,Cint,Cint,Ptr{Uint8}),
                parent, flag, typ, button, bytestring(message) ))
end

function GtkMessageDialogLeaf(parent::GtkContainer, flags::Integer, typ::Integer,
        message::StringLike, buttons)
    w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new,libgtk), Ptr{GObject},
        (Ptr{GObject},Cint,Cint,Cint,Ptr{Uint8}),
        parent, flags, typ, 0, bytestring(message) ))
    for key in keys(buttons)
        push!(w, key, buttons[key])
    end
    w
end

function info_dialog(message::String; parent = GtkNullContainer())
    dlg = @GtkMessageDialog(parent, GtkDialogFlags.DESTROY_WITH_PARENT,
	    GtkMessageType.INFO, GtkButtonsType.CLOSE, message)
    run(dlg)
    destroy(dlg)
end

function ask_dialog(message::String, yes_text="yes", no_text="no"; parent = GtkNullContainer())
    dlg = @GtkMessageDialog(parent, GtkDialogFlags.DESTROY_WITH_PARENT,
	    GtkMessageType.QUESTION, GtkButtonsType.NONE, message)
    push!(dlg, yes_text, 1)
    push!(dlg, no_text, 2)
    response = run(dlg)
    destroy(dlg)
    response == 1
end

function warn_dialog(message::String; parent = GtkNullContainer())
    dlg = @GtkMessageDialog(parent, GtkDialogFlags.DESTROY_WITH_PARENT,
	    GtkMessageType.WARNING, GtkButtonsType.CLOSE, message)
    run(dlg)
    destroy(dlg)
end

function error_dialog(message::String; parent = GtkNullContainer())
    dlg = @GtkMessageDialog(parent, GtkDialogFlags.DESTROY_WITH_PARENT,
	    GtkMessageType.ERROR, GtkButtonsType.CLOSE, message)
    run(dlg)
    destroy(dlg)
end

#GtkSeparator — A separator widget
