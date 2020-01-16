## Overview
Toplevel which can contain other widgets

A GtkWindow is a toplevel window which can contain other widgets. Windows normally have decorations that are under the control of the windowing system and allow the user to manipulate the window (resize it, move it, close it,...).


### Functions
GtkWidget *	gtk_window_new () <br>
void	gtk_window_set_title ()<br>
void	gtk_window_set_wmclass ()<br>
void	gtk_window_set_resizable ()<br>
gboolean	gtk_window_get_resizable ()<br>
void	gtk_window_add_accel_group ()<br>
void	gtk_window_remove_accel_group ()<br>
gboolean	gtk_window_activate_focus ()<br>
gboolean	gtk_window_activate_default ()<br>
void	gtk_window_set_modal ()<br>
void	gtk_window_set_default_size ()<br>
void	gtk_window_set_default_geometry ()<br>
void	gtk_window_set_geometry_hints ()<br>
void	gtk_window_set_gravity ()<br>
GdkGravity	gtk_window_get_gravity ()<br>
void	gtk_window_set_position ()<br>
void	gtk_window_set_transient_for ()<br>
void	gtk_window_set_attached_to ()<br>
void	gtk_window_set_destroy_with_parent ()<br>
void	gtk_window_set_hide_titlebar_when_maximized ()<br>
void	gtk_window_set_screen ()<br>
GdkScreen *	gtk_window_get_screen ()<br>
gboolean	gtk_window_is_active ()<br>
gboolean	gtk_window_is_maximized ()<br>
gboolean	gtk_window_has_toplevel_focus ()<br>
GList *	gtk_window_list_toplevels ()<br>
void	gtk_window_add_mnemonic ()<br>
void	gtk_window_remove_mnemonic ()<br>
gboolean	gtk_window_mnemonic_activate ()<br>
gboolean	gtk_window_activate_key ()<br>
gboolean	gtk_window_propagate_key_event ()<br>
GtkWidget *	gtk_window_get_focus ()<br>
void	gtk_window_set_focus ()<br>
GtkWidget *	gtk_window_get_default_widget ()<br>
void	gtk_window_set_default ()<br>
void	gtk_window_present ()<br>
void	gtk_window_present_with_time ()<br>
void	gtk_window_close ()<br>
void	gtk_window_iconify ()<br>
void	gtk_window_deiconify ()<br>
void	gtk_window_stick ()<br>
void	gtk_window_unstick ()<br>
void	gtk_window_maximize ()<br>
void	gtk_window_unmaximize ()<br>
void	gtk_window_fullscreen ()<br>
void	gtk_window_fullscreen_on_monitor ()<br>
void	gtk_window_unfullscreen ()<br>
void	gtk_window_set_keep_above ()<br>
void	gtk_window_set_keep_below ()<br>
void	gtk_window_begin_resize_drag ()<br>
void	gtk_window_begin_move_drag ()<br>
void	gtk_window_set_decorated ()<br>
void	gtk_window_set_deletable ()<br>
void	gtk_window_set_mnemonic_modifier ()<br>
void	gtk_window_set_type_hint ()<br>
void	gtk_window_set_skip_taskbar_hint ()<br>
void	gtk_window_set_skip_pager_hint ()<br>
void	gtk_window_set_urgency_hint ()<br>
void	gtk_window_set_accept_focus ()<br>
void	gtk_window_set_focus_on_map ()<br>
void	gtk_window_set_startup_id ()<br>
void	gtk_window_set_role ()<br>
gboolean	gtk_window_get_decorated ()<br>
gboolean	gtk_window_get_deletable ()<br>
GList *	gtk_window_get_default_icon_list ()<br>
const gchar *	gtk_window_get_default_icon_name ()<br>
void	gtk_window_get_default_size ()<br>
gboolean	gtk_window_get_destroy_with_parent ()<br>
gboolean	gtk_window_get_hide_titlebar_when_maximized ()<br>
GdkPixbuf *	gtk_window_get_icon ()<br>
GList *	gtk_window_get_icon_list ()<br>
const gchar *	gtk_window_get_icon_name ()<br>
GdkModifierType	gtk_window_get_mnemonic_modifier ()<br>
gboolean	gtk_window_get_modal ()<br>
void	gtk_window_get_position ()<br>
const gchar *	gtk_window_get_role ()<br>
void	gtk_window_get_size ()<br>
const gchar *	gtk_window_get_title ()<br>
GtkWindow *	gtk_window_get_transient_for ()<br>
GtkWidget *	gtk_window_get_attached_to ()<br>
GdkWindowTypeHint	gtk_window_get_type_hint ()<br>
gboolean	gtk_window_get_skip_taskbar_hint ()<br>
gboolean	gtk_window_get_skip_pager_hint ()<br>
gboolean	gtk_window_get_urgency_hint ()<br>
gboolean	gtk_window_get_accept_focus ()<br>
gboolean	gtk_window_get_focus_on_map ()<br>
GtkWindowGroup *	gtk_window_get_group ()<br>
gboolean	gtk_window_has_group ()<br>
GtkWindowType	gtk_window_get_window_type ()<br>
void	gtk_window_move ()<br>
gboolean	gtk_window_parse_geometry ()<br>
void	gtk_window_reshow_with_initial_size ()<br>
void	gtk_window_resize ()<br>
void	gtk_window_resize_to_geometry ()<br>
void	gtk_window_set_default_icon_list ()<br>
void	gtk_window_set_default_icon ()<br>
gboolean	gtk_window_set_default_icon_from_file ()<br>
void	gtk_window_set_default_icon_name ()<br>
void	gtk_window_set_icon ()<br>
void	gtk_window_set_icon_list ()<br>
gboolean	gtk_window_set_icon_from_file ()<br>
void	gtk_window_set_icon_name ()<br>
void	gtk_window_set_auto_startup_notification ()<br>
gdouble	gtk_window_get_opacity ()<br>
void	gtk_window_set_opacity ()<br>
gboolean	gtk_window_get_mnemonics_visible ()<br>
void	gtk_window_set_mnemonics_visible ()<br>
gboolean	gtk_window_get_focus_visible ()<br>
void	gtk_window_set_focus_visible ()<br>
void	gtk_window_set_has_resize_grip ()<br>
gboolean	gtk_window_get_has_resize_grip ()<br>
gboolean	gtk_window_resize_grip_is_visible ()<br>
gboolean	gtk_window_get_resize_grip_area ()<br>
GtkApplication *	gtk_window_get_application ()<br>
void	gtk_window_set_application ()<br>
void	gtk_window_set_has_user_ref_count ()<br>
void	gtk_window_set_titlebar ()<br>
GtkWidget *	gtk_window_get_titlebar ()<br>
void	gtk_window_set_interactive_debugging ()<br>

### Properties
gboolean -	accept-focus -	Read / Write<br>
GtkApplication * -	application -	Read / Write<br>
GtkWidget * -	attached-to -	Read / Write / Construct<br>
gboolean -	decorated -	Read / Write<br>
gint -	default-height -	Read / Write<br>
gint -	default-width -	Read / Write<br>
gboolean -  	deletable -	Read / Write<br>
gboolean -	destroy-with-parent -	Read / Write<br>
gboolean -	focus-on-map -	Read / Write<br>
gboolean -	focus-visible -	Read / Write<br>
GdkGravity -	gravity -	Read / Write<br>
gboolean -	has-resize-grip --	Read / Write<br>
gboolean -	has-toplevel-focus -	Read<br>
gboolean -	hide-titlebar-when-maximized -	Read / Write<br>
GdkPixbuf * -	icon -	Read / Write<br>
gchar * -	icon-name -	Read / Write<br>
gboolean -	is-active -	Read<br>
gboolean -	is-maximized -	Read<br>
gboolean -	mnemonics-visible -	Read / Write<br>
gboolean -	modal -	Read / Write<br>
gboolean -	resizable -	Read / Write<br>
gboolean -	resize-grip-visible -	Read<br>
gchar * -	role -	Read / Write<br>
GdkScreen * -	screen -	Read / Write<br>
gboolean -	skip-pager-hint -	Read / Write<br>
gboolean -	skip-taskbar-hint -	Read / Write<br>
gchar * -	startup-id -	Write<br>
gchar * -	title -	Read / Write<br>
GtkWindow * -	transient-for -	Read / Write / Construct<br>
GtkWindowType -	type -	Read / Write / Construct Only<br>
GdkWindowTypeHint -	type-hint -	Read / Write<br>
gboolean -	urgency-hint -	Read / Write<br>
GtkWindowPosition -	window-position -	Read / Write<br>

#### Style Properties
gchar * -	decoration-button-layout -	Read<br>
gint -	decoration-resize-handle -	Read / Write<br>

#### Signals
void -	activate-default -	Action<br>
void -	activate-focus -	Action<br>
gboolean -	enable-debugging -	Action<br>
void -	keys-changed -	Run First<br>
void -	set-focus -	Run Last<br>

#### Types and Values
GtkWindow<br>
struct -	GtkWindowClass<br>
enum -	GtkWindowType<br>
enum -	GtkWindowPosition<br>

#### Object Hierarchy
    +- GObject
    .  +- GInitiallyUnowned
    .  .  +- GtkWidget
    .  .  .  +- GtkContainer
    .  .  .  .  +- GtkBin
    .  .  .  .  .  +- GtkWindow
    .  .  .  .  .  .  +- GtkDialog
    .  .  .  .  .  .  +- GtkApplicationWindow
    .  .  .  .  .  .  +- GtkAssistant
    .  .  .  .  .  .  +- GtkOffscreenWindow
    .  .  .  .  .  .  +- GtkPlug
    .  .  .  .  .  .  +- GtkShortcutsWindow
                        
#### Example
using Gtk<br>

win = GtkWindow("New title")<br>
hbox = GtkBox(:h)<br>
push!(win, hbox)<br>
cancel = GtkButton("Cancel")<br>
ok = GtkButton("OK")<br>
push!(hbox, cancel)<br>
push!(hbox, ok)<br>
showall(win)

![alt text](https://github.com/mikolajhojda/Gtk.jl/blob/master/docs/src/assets/window.png)
