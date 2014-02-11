### GtkToolItem

@gtktype GtkToolItem
GtkToolItem() = GtkToolItem(
    ccall((:gtk_tool_item_new,libgtk),Ptr{GObject},()))

### GtkToolbar

baremodule GtkToolbarStyle
    const ICONS=0
    const TEXT=1
    const BOTH=2
    const BOTH_HORIZ=3
end

@gtktype GtkToolbar
GtkToolbar() = GtkToolbar(
    ccall((:gtk_toolbar_new,libgtk),Ptr{GObject},()))
    
insert!(toolbar::GtkToolbar, pos::Integer, item::GtkToolItemI) =
    ccall((:gtk_toolbar_insert,libgtk),Void,(Ptr{GObject},Ptr{GObject},Cint),
           toolbar,item,pos)

getindex(toolbar::GtkToolbar, pos::Integer) = convert(GObject,
    ccall((:gtk_toolbar_get_nth_item,libgtk),Ptr{GObject},(Ptr{GObject},Cint), toolbar,pos))

function push!(toolbar::GtkToolbar, items::GtkToolItemI...)
    for item in items
        insert!(toolbar, -1, item)
    end
    toolbar
end

function unshift!(toolbar::GtkToolbar, items::GtkToolItemI...) 
    for item in reverse(items)
        insert!(toolbar, 0, item)
    end
    toolbar
end

length(toolbar::GtkToolbar) = 
  ccall((:gtk_toolbar_get_n_items,libgtk),Cint,(Ptr{GObject},),toolbar)
  
### GtkToolButton
@gtktype GtkToolButton
GtkToolButton(stock_id::String) = GtkToolButton(
    ccall((:gtk_tool_button_new_from_stock,libgtk),Ptr{GObject},(Ptr{Uint8},), bytestring(stock_id)))

@gtktype GtkToggleToolButton
GtkToggleToolButton(stock_id::String) = GtkToggleToolButton(
    ccall((:gtk_toggle_tool_button_new_from_stock,libgtk),Ptr{GObject},(Ptr{Uint8},), bytestring(stock_id)))
GtkToggleToolButton() = GtkToggleToolButton(
    ccall((:gtk_toggle_tool_button_new,libgtk),Ptr{GObject},()))

#TODO GtkRadioToolButton (needs _GSList as argument)

@gtktype GtkMenuToolButton
GtkMenuToolButton(stock_id::String) = GtkMenuToolButton(
    ccall((:gtk_menu_tool_button_new_from_stock,libgtk),Ptr{GObject},(Ptr{Uint8},), bytestring(stock_id)))
    
### GtkSeparatorToolItem
@gtktype GtkSeparatorToolItem
GtkSeparatorToolItem() = GtkSeparatorToolItem(
    ccall((:gtk_separator_tool_item_new,libgtk),Ptr{GObject},()))
    

