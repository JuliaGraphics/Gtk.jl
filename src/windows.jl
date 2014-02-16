@gtktype GtkWindow
function GtkWindow(title=nothing, w=-1, h=-1, resizable=true, toplevel=true)
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
    widget = GtkWindow(hnd)
    show(widget)
    widget
end

resize!(win::GtkWindowI, w::Integer, h::Integer) = ccall((:gtk_window_resize,libgtk),Void,(Ptr{GObject},Int32,Int32),win,w,h)

present(win::GtkWindowI) = ccall((:gtk_window_present,libgtk),Void,(Ptr{GObject},),win)

function push!(win::GtkWindowI, accel_group::GtkAccelGroup)
  ccall((:gtk_window_add_accel_group,libgtk),Void,(Ptr{GObject},Ptr{GObject}),win,accel_group)
  win
end
  
function splice!(win::GtkWindowI, accel_group::GtkAccelGroup)
  ccall((:gtk_window_remove_accel_group,libgtk),Void,(Ptr{GObject},Ptr{GObject}),win,accel_group)
  accel_group
end

@gtktype GtkScrolledWindow
function GtkScrolledWindow()
    hnd = ccall((:gtk_scrolled_window_new,libgtk),Ptr{GObject},(Ptr{GObject},Ptr{GObject}),
                C_NULL,C_NULL)
    GtkScrolledWindow(hnd)
end

function GtkDialog(title::String, parent::GtkContainerI, flags::Integer, button_text_response...)
    n = length(button_text_response)
    if !iseven(n)
        error("button_text_response must consist of text/response pairs")
    end
    w = GtkDialog(ccall((:gtk_dialog_new_with_buttons,libgtk), Ptr{GObject},
                (Ptr{Uint8},Ptr{GObject},Cint,Ptr{Void}),
                title, parent, flags, C_NULL))
    for i = 1:2:n
        push!(w, button_text_response[i], button_text_response[i+1])
    end
    w
end

@gtktype GtkAboutDialog
GtkAboutDialog() = GtkAboutDialog(
    ccall((:gtk_about_dialog_new,libgtk),Ptr{GObject},()))
    
@gtktype GtkMessageDialog
function GtkMessageDialog(parent::GtkContainerI, flags::Integer, typ::Integer, 
                          message::String, button_text_response...)
    n = length(button_text_response)
    if !iseven(n)
        error("button_text_response must consist of text/response pairs")
    end
    w = GtkMessageDialog(ccall((:gtk_message_dialog_new,libgtk), Ptr{GObject},
                (Ptr{GObject},Cint,Cint,Cint,Ptr{Uint8}),
                parent, flags, typ, 0, bytestring(message) ))
    for i = 1:2:n
        push!(w, button_text_response[i], button_text_response[i+1])
    end
    w
end

#GtkSeparator — A separator widget
