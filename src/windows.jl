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

#if VERSION >= v"0.4-"
#GtkDialogLeaf(title::StringLike, parent::GtkContainer, flags::Integer, buttons::=>...; kwargs...) =
#    GtkDialogLeaf(title, parent, flags, buttons; kwargs...)
#end
function GtkDialogLeaf(title::StringLike, parent::GtkContainer, flags::Integer, buttons; kwargs...)
    w = GtkDialogLeaf(ccall((:gtk_dialog_new_with_buttons,libgtk), Ptr{GObject},
                (Ptr{Uint8},Ptr{GObject},Cint,Ptr{Void}),
                title, parent, flags, C_NULL); kwargs...)
    for (k,v) in buttons
        push!(w, k, v)
    end
    w
end

GtkAboutDialogLeaf() = GtkAboutDialogLeaf(
    ccall((:gtk_about_dialog_new,libgtk),Ptr{GObject},()))

function GtkMessageDialogLeaf(message::StringLike, buttons, flags::Integer, typ::Integer, parent = GtkNullContainer(); kwargs...)
    w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new,libgtk), Ptr{GObject},
        (Ptr{GObject},Cint,Cint,Cint,Ptr{Uint8}),
        parent, flags, typ, GtkButtonsType.NONE, C_NULL); kwargs...)
    setproperty!(w, :text, message)
    for (k,v) in buttons
        push!(w, k, v)
    end
    w
end

ask_dialog(message::String, parent = GtkNullContainer()) =
        ask_dialog(message, "No", "Yes", parent)

function ask_dialog(message::String, no_text, yes_text, parent = GtkNullContainer())
    dlg = @GtkMessageDialog(message, ((no_text,0), (yes_text,1)),
            GtkDialogFlags.DESTROY_WITH_PARENT, GtkMessageType.QUESTION, parent)
    response = run(dlg)
    destroy(dlg)
    response == 1
end

for (func, flag) in (
        (:info_dialog, :(GtkMessageType.INFO)),
        (:warn_dialog, :(GtkMessageType.WARNING)),
        (:error_dialog, :(GtkMessageType.ERROR)))
    @eval function $func(message::String, parent = GtkNullContainer())
        w = GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new,libgtk), Ptr{GObject},
            (Ptr{GObject},Cint,Cint,Cint,Ptr{Uint8}),
            parent, GtkDialogFlags.DESTROY_WITH_PARENT,
            $flag, GtkButtonsType.CLOSE, C_NULL))
        setproperty!(w, :text, message)
        run(w)
        destroy(w)
    end
end

#TODO: GtkSeparator — A separator widget
