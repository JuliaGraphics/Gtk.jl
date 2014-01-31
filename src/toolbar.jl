### GtkToolItem

@gtktype GtkToolItem
GtkToolItem() = GtkToolItem(
    ccall((:gtk_tool_item_new,libgtk),Ptr{GObject},()))

### GtkToolbar

baremodule GtkToolbarStyle
    const GTK_TOOLBAR_ICONS = 0
    const GTK_TOOLBAR_TEXT = 1
    const GTK_TOOLBAR_BOTH = 2
    const GTK_TOOLBAR_BOTH_HORIZ = 3
end

@gtktype GtkToolbar
GtkToolbar() = GtkToolbar(
    ccall((:gtk_toolbar_new,libgtk),Ptr{GObject},()))
    
setindex!(toolbar::GtkToolbar, item::GtkToolItemI, pos::Integer) =
    ccall((:gtk_toolbar_insert,libgtk),Void,(Ptr{GObject},Ptr{GObject},Cint),
           toolbar,item,int32(pos))

getindex(toolbar::GtkToolbar, pos::Integer) =
    ccall((:gtk_toolbar_get_nth_item,libgtk),Ptr{GObject},(Ptr{GObject},Cint),
           toolbar,int32(pos))

function push!(toolbar::GtkToolbar, item::GtkToolItemI) 
    toolbar[-1] = item
    toolbar
end

function unshift!(toolbar::GtkToolbar, item::GtkToolItemI) 
    toolbar[0] = item
    toolbar
end

length(toolbar::GtkToolbar) = 
  ccall((:gtk_toolbar_get_n_items,libgtk),Cint,(Ptr{GObject},),toolbar)
  
### GtkToolButton
@gtktype GtkToolButton
GtkToolButton(stock_id::String) = GtkToolButton(
    ccall((:gtk_tool_button_new_from_stock,libgtk),Ptr{GObject},(Ptr{Uint8},), bytestring(stock_id)))
