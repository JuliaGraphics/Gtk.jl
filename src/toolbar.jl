### GtkToolItem

@gtktype GtkToolItem
new(::Type{GtkToolItem}) = new(GtkToolItem,
    ccall((:gtk_tool_item_new,libgtk),Ptr{GObject},()))

### GtkToolbar

@gtktype GtkToolbar
new(::Type{GtkToolbar}) = new(GtkToolbar,
    ccall((:gtk_toolbar_new,libgtk),Ptr{GObject},()))
    
insert!(toolbar::GtkToolbar, pos::Integer, item::GtkToolItem) =
    ccall((:gtk_toolbar_insert,libgtk),Void,(Ptr{GObject},Ptr{GObject},Cint),
           toolbar,item,pos)

getindex(toolbar::GtkToolbar, pos::Integer) = convert(GObject,
    ccall((:gtk_toolbar_get_nth_item,libgtk),Ptr{GObject},(Ptr{GObject},Cint), toolbar,pos))

function push!(toolbar::GtkToolbar, items::GtkToolItem...)
    for item in items
        insert!(toolbar, -1, item)
    end
    toolbar
end

function unshift!(toolbar::GtkToolbar, items::GtkToolItem...) 
    for item in reverse(items)
        insert!(toolbar, 0, item)
    end
    toolbar
end

length(toolbar::GtkToolbar) = 
  ccall((:gtk_toolbar_get_n_items,libgtk),Cint,(Ptr{GObject},),toolbar)
  
### GtkToolButton
@gtktype GtkToolButton
new(::Type{GtkToolButton}, stock_id::String) = new(GtkToolButton,
    ccall((:gtk_tool_button_new_from_stock,libgtk),Ptr{GObject},(Ptr{Uint8},), bytestring(stock_id)))

@gtktype GtkToggleToolButton
new(::Type{GtkToggleToolButton}, stock_id::String) = new(GtkToggleToolButton,
    ccall((:gtk_toggle_tool_button_new_from_stock,libgtk),Ptr{GObject},(Ptr{Uint8},), bytestring(stock_id)))
new(::Type{GtkToggleToolButton}) = new(GtkToggleToolButton,
    ccall((:gtk_toggle_tool_button_new,libgtk),Ptr{GObject},()))

#TODO GtkRadioToolButton (needs _GSList as argument)

@gtktype GtkMenuToolButton
new(::Type{GtkMenuToolButton}, stock_id::String) = new(GtkMenuToolButton,
    ccall((:gtk_menu_tool_button_new_from_stock,libgtk),Ptr{GObject},(Ptr{Uint8},), bytestring(stock_id)))
    
### GtkSeparatorToolItem
@gtktype GtkSeparatorToolItem
new(::Type{GtkSeparatorToolItem}) = new(GtkSeparatorToolItem,
    ccall((:gtk_separator_tool_item_new,libgtk),Ptr{GObject},()))
    

