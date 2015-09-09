# generic interface:
export new, width, height, #minsize, maxsize
    reveal, configure, draw, cairo_context,
    visible, destroy, stop, depth, isancestor,
    hasparent, toplevel, setproperty!, getproperty,
    selected, hasselection, unselect!, selectall!, unselectall!,
    pagenumber, present, complete, user_action,
    keyval, prev, up, down, popup
    #property, margin, padding, align
    #raise, focus, destroy, enabled

export open_dialog, save_dialog
export info_dialog, ask_dialog, warn_dialog, error_dialog

# GLib-imported event handling
export signal_connect, signal_handler_disconnect,
    signal_handler_block, signal_handler_unblock,
    signal_emit

# Gtk-specific event handling
export add_events, signal_emit,
    on_signal_destroy, on_signal_button_press,
    on_signal_button_release, on_signal_motion

export @guarded

# Tk-compatibility (reference of potentially missing functionality):
#export Frame, Labelframe, Notebook, Panedwindow
#export Button
#export Checkbutton, Radio, Combobox
#export Slider, Spinbox
#export Entry, set_validation, Text
#export Treeview, selected_nodes, node_insert, node_move, node_delete, node_open
#export tree_headers, tree_column_widths, tree_key_header, tree_key_width
#export Sizegrip, Separator, Progressbar, Image, Scrollbar
#export Menu, menu_add
#export GetOpenFile, GetSaveFile, ChooseDirectory, Messagebox
#export scrollbars_add
#export get_value, set_value,
#       get_items, set_items,
#       get_editable, set_editable,
#       set_position
