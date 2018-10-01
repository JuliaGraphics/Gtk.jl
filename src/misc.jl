#https://developer.gnome.org/gtk2/stable/MiscObjects.html

#GtkAdjustment — A GObject representing an adjustable bounded value
#GtkArrow — Displays an arrow
#GtkCalendar — Displays a calendar and allows the user to select a date
#GtkDrawingArea — A widget for custom user interface elements

#GtkHandleBox — a widget for detachable window portions
#GtkIMContextSimple — An input method context supporting table-based input methods
#GtkIMMulticontext — An input method context supporting multiple, loadable input methods
#GtkSizeGroup — Grouping widgets so they request the same size
#GtkTooltip — Add tips to your widgets
#GtkViewport — An adapter which makes widgets scrollable
#GtkAccessible — Accessibility support for widgets

#GtkEventBox — A widget used to catch events for widgets which do not have their own window
Gtk.@gtktype GtkEventBox	
GtkEventBoxLeaf() =  GtkEventBoxLeaf(ccall((:gtk_event_box_new ,libgtk), Ptr{GObject},	()))
