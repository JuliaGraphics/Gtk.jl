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

GtkMenuItemLeaf() = GtkMenuItemLeaf(ccall((:gtk_menu_item_new, libgtk), Ptr{GObject}, ()))
GtkMenuItemLeaf(label::AbstractString) =
    GtkMenuItemLeaf(ccall((:gtk_menu_item_new_with_mnemonic, libgtk), Ptr{GObject},
                (Ptr{UInt8},), bytestring(label)))

GtkSeparatorMenuItemLeaf() = GtkSeparatorMenuItemLeaf(ccall((:gtk_separator_menu_item_new, libgtk), Ptr{GObject}, ()))

GtkMenuLeaf() = GtkMenuLeaf(ccall((:gtk_menu_new, libgtk), Ptr{GObject}, ()))
function GtkMenuLeaf(item::GtkMenuItem)
    menu = GtkMenuLeaf()
#     GAccessor.submenu(item, menu)
    ccall((:gtk_menu_item_set_submenu, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}),
          item, menu)
    menu
end

GtkMenuBarLeaf() = GtkMenuBarLeaf(ccall((:gtk_menu_bar_new, libgtk), Ptr{GObject}, ()))

popup(menu::GtkMenuShell, event::GdkEventButton) =
    ccall((:gtk_menu_popup, libgtk), Nothing,
          (Ptr{GObject}, Ptr{GObject}, Ptr{GObject}, Ptr{GObject}, Ptr{Nothing}, Cuint, UInt32),
          menu, GtkNullContainerLeaf(), GtkNullContainerLeaf(), GtkNullContainerLeaf(), C_NULL, event.button, event.time)
