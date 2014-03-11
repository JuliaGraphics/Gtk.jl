@gtktype GtkWindow
function new(::Type{GtkWindow}, title::Union(Nothing,StringLike)=nothing, w::Real=-1, h::Real=-1, resizable::Bool=true, toplevel::Bool=true)
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
    widget = new(GtkWindow,hnd)
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

@gtktype GtkScrolledWindow
function new(::Type{GtkScrolledWindow})
    hnd = ccall((:gtk_scrolled_window_new,libgtk),Ptr{GObject},(Ptr{GObject},Ptr{GObject}),
                C_NULL,C_NULL)
    new(GtkScrolledWindow,hnd)
end

function new(::Type{GtkDialog}, title::StringLike, parent::GtkContainer, flags::Integer, button_text_response...)
    n = length(button_text_response)
    if !iseven(n)
        error("button_text_response must consist of text/response pairs")
    end
    w = new(GtkDialog,ccall((:gtk_dialog_new_with_buttons,libgtk), Ptr{GObject},
                (Ptr{Uint8},Ptr{GObject},Cint,Ptr{Void}),
                title, parent, flags, C_NULL))
    for i = 1:2:n
        push!(w, button_text_response[i], button_text_response[i+1])
    end
    w
end

@gtktype GtkAboutDialog
new(::Type{GtkAboutDialog}) = new(GtkAboutDialog,
    ccall((:gtk_about_dialog_new,libgtk),Ptr{GObject},()))
    
@gtktype GtkMessageDialog
function new(::Type{GtkMessageDialog}, parent::GtkContainer, flags::Integer, typ::Integer, 
                          message::StringLike, button_text_response...)
    n = length(button_text_response)
    if !iseven(n)
        error("button_text_response must consist of text/response pairs")
    end
    w = new(GtkMessageDialog,ccall((:gtk_message_dialog_new,libgtk), Ptr{GObject},
                (Ptr{GObject},Cint,Cint,Cint,Ptr{Uint8}),
                parent, flags, typ, 0, bytestring(message) ))
    for i = 1:2:n
        push!(w, button_text_response[i], button_text_response[i+1])
    end
    w
end

#GtkSeparator — A separator widget
