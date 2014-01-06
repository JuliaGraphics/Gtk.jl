#https://developer.gnome.org/gtk2/stable/MenusAndCombos.html

#GtkMenu — A menu widget
#GtkMenuBar — A subclass widget for GtkMenuShell which holds GtkMenuItem widgets
#GtkMenuItem — The widget used for item in menus
#GtkImageMenuItem — A menu item with an icon
#GtkRadioMenuItem — A choice from multiple check menu items
#GtkCheckMenuItem — A menu item with a check box
#GtkSeparatorMenuItem — A separator used in menus
#GtkTearoffMenuItem — A menu item used to tear off and reattach its menu
#GtkToolShell — Interface for containers containing GtkToolItem widgets
#GtkToolbar — Create bars of buttons and other widgets
#GtkToolItem — The base class of widgets that can be added to GtkToolShell
#GtkToolPalette — A tool palette with categories
#GtkToolItemGroup — A sub container used in a tool palette
#GtkSeparatorToolItem — A toolbar item that separates groups of other toolbar items
#GtkToolButton — A GtkToolItem subclass that displays buttons
#GtkMenuToolButton — A GtkToolItem containing a button with an additional dropdown menu
#GtkToggleToolButton — A GtkToolItem containing a toggle button
#GtkRadioToolButton — A toolbar item that contains a radio button

@gtktype GtkMenuItem
GtkMenuItem() = GtkMenuItem(ccall((:gtk_menu_item_new,libgtk),Ptr{GObject},()))
GtkMenuItem(label::String) =
    GtkMenuItem(ccall((:gtk_menu_item_new_with_mnemonic,libgtk),Ptr{GObject},
                (Ptr{Uint8},), bytestring(label)))


@gtktype GtkSeparatorMenuItem
GtkSeparatorMenuItem() = GtkSeparatorMenuItem(ccall((:gtk_separator_menu_item_new,libgtk),Ptr{GObject},()))


@gtktype GtkMenu
GtkMenu() = GtkMenu(ccall((:gtk_menu_new,libgtk),Ptr{GObject},()))
function GtkMenu(item::GtkMenuItem)
    menu = GtkMenu()
#     GAccessor.submenu(item, menu)
    ccall((:gtk_menu_item_set_submenu,libgtk),Void,(Ptr{GObject},Ptr{GObject}),
          item, menu)
    menu
end


@gtktype GtkMenuBar
GtkMenuBar() = GtkMenuBar(ccall((:gtk_menu_bar_new,libgtk),Ptr{GObject},()))


popup(menu::GtkMenuShellI, event::GdkEventButton) =
    ccall((:gtk_menu_popup,libgtk), Void,
          (Ptr{GObject},Ptr{GObject},Ptr{GObject},Ptr{GObject},Ptr{Void},Cuint,Uint32),
          menu, GtkNullContainer(), GtkNullContainer(), GtkNullContainer(), C_NULL, event.button, event.time)
