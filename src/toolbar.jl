### GtkToolItem

GtkToolItemLeaf() = GtkToolItemLeaf(
    ccall((:gtk_tool_item_new, libgtk), Ptr{GObject}, ()))

### GtkToolbar

GtkToolbarLeaf() = GtkToolbarLeaf(
    ccall((:gtk_toolbar_new, libgtk), Ptr{GObject}, ()))

insert!(toolbar::GtkToolbar, pos::Integer, item::GtkToolItem) =
    ccall((:gtk_toolbar_insert, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}, Cint),
           toolbar, item, pos)

getindex(toolbar::GtkToolbar, pos::Integer) = convert(GObject,
    ccall((:gtk_toolbar_get_nth_item, libgtk), Ptr{GObject}, (Ptr{GObject}, Cint), toolbar, pos))

function push!(toolbar::GtkToolbar, items::GtkToolItem...)
    for item in items
        insert!(toolbar, -1, item)
    end
    toolbar
end

function pushfirst!(toolbar::GtkToolbar, items::GtkToolItem...)
    for item in reverse(items)
        insert!(toolbar, 0, item)
    end
    toolbar
end

length(toolbar::GtkToolbar) =
  ccall((:gtk_toolbar_get_n_items, libgtk), Cint, (Ptr{GObject},), toolbar)

### GtkToolButton
GtkToolButtonLeaf(stock_id::AbstractString) = GtkToolButtonLeaf(
    ccall((:gtk_tool_button_new_from_stock, libgtk), Ptr{GObject}, (Ptr{UInt8},), bytestring(stock_id)))

GtkToggleToolButtonLeaf(stock_id::AbstractString) = GtkToggleToolButtonLeaf(
    ccall((:gtk_toggle_tool_button_new_from_stock, libgtk), Ptr{GObject}, (Ptr{UInt8},), bytestring(stock_id)))
GtkToggleToolButtonLeaf() = GtkToggleToolButtonLeaf(
    ccall((:gtk_toggle_tool_button_new, libgtk), Ptr{GObject}, ()))

#TODO GtkRadioToolButton (needs _GSList as argument)

GtkMenuToolButtonLeaf(stock_id::AbstractString) = GtkMenuToolButtonLeaf(
    ccall((:gtk_menu_tool_button_new_from_stock, libgtk), Ptr{GObject}, (Ptr{UInt8},), bytestring(stock_id)))

### GtkSeparatorToolItem
GtkSeparatorToolItemLeaf() = GtkSeparatorToolItemLeaf(
    ccall((:gtk_separator_tool_item_new, libgtk), Ptr{GObject}, ()))
