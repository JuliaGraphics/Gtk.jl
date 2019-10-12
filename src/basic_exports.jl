# generic interface:
export new, width, height, #minsize, maxsize
    reveal, configure, draw, cairo_context,
    visible, destroy, stop, depth, isancestor,
    hide, grab_focus,
    hasparent, toplevel, set_gtk_property!, get_gtk_property,
    selected, hasselection, unselect!, selectall!, unselectall!,
    pagenumber, present, fullscreen, unfullscreen,
    maximize, unmaximize, complete, user_action,
    keyval, prev, up, down, popup,
    convert_iter_to_child_iter, convert_child_iter_to_iter,
    pulse,
    buffer, cells, search, place_cursor, select_range, selection_bounds,
    create_mark
    #property, margin, padding, align
    #raise, focus, destroy, enabled

export open_dialog, open_dialog_native, save_dialog, save_dialog_native
export info_dialog, ask_dialog, warn_dialog, error_dialog, input_dialog
export response

# GLib-imported event handling
export signal_connect, signal_handler_disconnect,
    signal_handler_block, signal_handler_unblock,
    signal_emit, g_timeout_add, g_idle_add

# Gtk-specific event handling
export add_events, signal_emit,
    on_signal_destroy, on_signal_button_press,
    on_signal_button_release, on_signal_motion

# Gdk info and manipulation
export screen_size

export @guarded, @sigatom, @idle_add

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
