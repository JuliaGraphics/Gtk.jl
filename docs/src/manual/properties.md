# Properties

If you're following along, you probably noticed that creating `win` caused quite a lot of output:
```
GtkWindowLeaf(name="", parent, width-request=-1, height-request=-1, visible=TRUE, sensitive=TRUE, app-paintable=FALSE, can-focus=FALSE, has-focus=FALSE, is-focus=FALSE, can-default=FALSE, has-default=FALSE, receives-default=FALSE, composite-child=FALSE, style, events=0, no-show-all=FALSE, has-tooltip=FALSE, tooltip-markup=NULL, tooltip-text=NULL, window, double-buffered=TRUE, halign=GTK_ALIGN_FILL, valign=GTK_ALIGN_FILL, margin-left=0, margin-right=0, margin-top=0, margin-bottom=0, margin=0, hexpand=FALSE, vexpand=FALSE, hexpand-set=FALSE, vexpand-set=FALSE, expand=FALSE, border-width=0, resize-mode=GTK_RESIZE_QUEUE, child, type=GTK_WINDOW_TOPLEVEL, title="My window", role=NULL, resizable=TRUE, modal=FALSE, window-position=GTK_WIN_POS_NONE, default-width=-1, default-height=-1, destroy-with-parent=FALSE, hide-titlebar-when-maximized=FALSE, icon, icon-name=NULL, screen, type-hint=GDK_WINDOW_TYPE_HINT_NORMAL, skip-taskbar-hint=FALSE, skip-pager-hint=FALSE, urgency-hint=FALSE, accept-focus=TRUE, focus-on-map=TRUE, decorated=TRUE, deletable=TRUE, gravity=GDK_GRAVITY_NORTH_WEST, transient-for, attached-to, opacity=1.000000, has-resize-grip=TRUE, resize-grip-visible=TRUE, application, ubuntu-no-proxy=FALSE, is-active=FALSE, has-toplevel-focus=FALSE, startup-id, mnemonics-visible=TRUE, focus-visible=TRUE, )
```
This shows you a list of properties of the object. For example, notice that the `title` property is set to `"My window"`. We can change the title in the following way:
```julia
julia> set_gtk_property!(win, :title, "New title")
```
To get the property, you have to specify the return type as a second argument:
```julia
julia> get_gtk_property(win, :title, String)
"New title"
```
This is necessary because Gtk, a C library, maintains the state; you have to specify what type of Julia object you want to create from the pointers it passes back.

To access particular properties, you can either use symbols, like `:title`, or strings, like `"title"`.
When using symbols, you'll need to convert any Gtk names that use `-` into names with `_`:

```julia
julia> get_gtk_property(win, :double_buffered, Bool)
true
```

Some properties have convenience methods, for example:
```julia
julia> visible(win)
true

julia> visible(win, false)

julia> visible(win)
false

julia> visible(win, true)
```
This sequence makes the window disappear and then reappear.
