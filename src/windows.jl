@gtktype Window 
# probably want to auto generate property accessors
@gtkmethods Window set_title, set_default_size, set_resizable
@gtkmethods Widget set_size_request
function GtkWindow(title=nothing, w=-1, h=-1, resizable=true, toplevel=true)
    window = Window(
        toplevel?GtkWindowType.TOPLEVEL:GtkWindowType.POPUP)
    if title !== nothing
        set_title(window,title)
    end
    if resizable
        set_default_size(window,w,h)
    else
        set_resizable(window, false)
        set_size_request(window, w,h)
    end
    show(window)
    window
end

#GtkScrolledWindow
#GtkSeparator — A separator widget
