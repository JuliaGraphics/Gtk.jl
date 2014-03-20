### GtkToolItem

@gtktype GtkToolItem
GtkToolItemLeaf() = GtkToolItemLeaf(
    ccall((:gtk_tool_item_new,libgtk),Ptr{GObject},()))

### GtkToolbar

@gtktype GtkToolbar
GtkToolbarLeaf() = GtkToolbarLeaf(
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
GtkToolButtonLeaf(stock_id::String) = GtkToolButtonLeaf(
    ccall((:gtk_tool_button_new_from_stock,libgtk),Ptr{GObject},(Ptr{Uint8},), bytestring(stock_id)))

@gtktype GtkToggleToolButton
GtkToggleToolButtonLeaf(stock_id::String) = GtkToggleToolButtonLeaf(
    ccall((:gtk_toggle_tool_button_new_from_stock,libgtk),Ptr{GObject},(Ptr{Uint8},), bytestring(stock_id)))
GtkToggleToolButtonLeaf() = GtkToggleToolButtonLeaf(
    ccall((:gtk_toggle_tool_button_new,libgtk),Ptr{GObject},()))

#TODO GtkRadioToolButton (needs _GSList as argument)

@gtktype GtkMenuToolButton
GtkMenuToolButtonLeaf(stock_id::String) = GtkMenuToolButtonLeaf(
    ccall((:gtk_menu_tool_button_new_from_stock,libgtk),Ptr{GObject},(Ptr{Uint8},), bytestring(stock_id)))
    
### GtkSeparatorToolItem
@gtktype GtkSeparatorToolItem
GtkSeparatorToolItemLeaf() = GtkSeparatorToolItemLeaf(
    ccall((:gtk_separator_tool_item_new,libgtk),Ptr{GObject},()))
    

