# julia Gtk interface

module Gtk

include("GLib/GLib.jl")
using .GLib
using .GLib.MutableTypes
using Cairo

import .GLib: bytestring
import Base: convert, show, showall, run, size, length, getindex, setindex!,
             insert!, push!, unshift!, shift!, pop!, splice!, delete!,
             start, next, done, parent, isempty, empty!, first, last, in,
             eltype, copy
import Base.Graphics: width, height, getgc
import Cairo: destroy

# generic interface:
export width, height, #minsize, maxsize
    reveal, configure, draw, cairo_context,
    visible, destroy,
    hasparent, toplevel

    #property, margin, padding, align
    #raise, focus, destroy, enabled

# Gtk objects
export GtkWindow, GtkCanvas, GtkBox, GtkButtonBox, GtkPaned, GtkLayout, GtkNotebook,
    GtkExpander, GtkOverlay, GtkFrame, GtkAspectFrame,
    GtkLabel, GtkButton, GtkCheckButton, GtkRadioButton, GtkRadioButtonGroup,
    GtkToggleButton, GtkLinkButton, GtkVolumeButton,
    GtkEntry, GtkScale, GtkAdjustment, GtkSpinButton, GtkComboBoxText, GdkPixbuf,
    GtkImage, GtkProgressBar, GtkSpinner, GtkStatusbar, GtkStatusIcon,
    GtkTextBuffer, GtkTextView, GtkTextMark, GtkTextTag,
    GtkMenuItem, GtkSeparatorMenuItem, GtkMenu, GtkMenuBar,
    GtkFileChooserDialog, GtkNullContainer

# Gtk3 objects
export GtkGrid

# Gtk2 objects
export GtkTable, GtkAlignment

# Gtk-specific event handling
export gtk_doevent, GdkEventMask, GdkModifierType, GdkEventType,
    signal_connect, signal_handler_disconnect,
    signal_handler_block, signal_handler_unblock,
    add_events, signal_emit,
    on_signal_destroy, on_signal_button_press,
    on_signal_button_release, on_signal_motion,
    popup

# Selectors
export GtkFileChooserAction, GtkStock, GtkResponse

# Constants
export GdkKeySyms, GdkScrollDirection, GtkJustification

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

typealias Index Union(Integer,AbstractVector{TypeVar(:I,Integer)})

include(joinpath("..","deps","ext.jl"))

include("gtktypes.jl")
include("gdk.jl")
include("events.jl")
include("container.jl")
include("windows.jl")
include("layout.jl")
include("displays.jl")
include("lists.jl")
include("buttons.jl")
include("input.jl")
include("text.jl")
include("menus.jl")
include("selectors.jl")
include("misc.jl")
include("cairo.jl")

function Base.subtypes(T::DataType, b::Bool)
    if b == false
        return subtypes(T)
    elseif T.abstract
        queue = DataType[T,]
        subt = DataType[]
        while !isempty(queue)
            for x in subtypes(pop!(queue))
                if isa(x,DataType)
                    if x.abstract
                        push!(queue, x)
                    else
                        push!(subt, x)
                    end
                end
            end
        end
        return subt
    else
        return DataType[]
    end
end
for container in subtypes(GtkContainerI,true)
    @eval $(symbol(string(container)))(child::GtkWidgetI,vargs...) = push!($container(vargs...),child)
end
for orientable in tuple(:GtkPaned, :GtkScale, [sym.name.name for sym in subtypes(GtkBoxI,true)]...)
    @eval $orientable(orientation::Symbol,vargs...) = $orientable(
            (orientation==:v ? true :
            (orientation==:h ? false :
            error("invalid $($orientable) orientation $orientation"))),vargs...)
end

export GAccessor
let cachedir = joinpath(splitdir(@__FILE__)[1], "..", "gen", "gbox$(gtk_version)")
    fastcachedir = "$(cachedir)_julia$(VERSION.major)_$(VERSION.minor)"
    if isfile(fastcachedir) && true
        open(fastcachedir) do cache
            eval(deserialize(cache))
        end
    else
        map(eval, include(cachedir).args)
    end
end
const _ = GAccessor
function _.position(w::GtkWindow,x::Integer,y::Integer)
    ccall((:gtk_window_move,libgtk),Void,(Ptr{GObject},Cint,Cint),w,x,y)
    w
end

# Alternative Interface (`using Gtk.ShortNames`)
module ShortNames
    using ..Gtk
    export Gtk

    # generic interface (keep this synchronized with above)
    export width, height, #minsize, maxsize
        reveal, configure, draw, cairo_context,
        visible, destroy,
        hasparent, toplevel

    # Gtk objects
    const G_ = GAccessor
    const Window = GtkWindow
    const Canvas = GtkCanvas
    const BoxLayout = GtkBox
    const ButtonBox = GtkButtonBox
    const Paned = GtkPaned
    const Layout = GtkLayout
    const Notebook = GtkNotebook
    const Expander = GtkExpander
    const Overlay = GtkOverlay
    const Frame = GtkFrame
    const AspectFrame = GtkAspectFrame
    const Label = GtkLabel
    const Button = GtkButton
    const CheckButton = GtkCheckButton
    const RadioButton = GtkRadioButton
    const RadioButtonGroup = GtkRadioButtonGroup
    const ToggleButton = GtkToggleButton
    const LinkButton = GtkLinkButton
    const VolumeButton = GtkVolumeButton
    const Entry = GtkEntry
    const Scale = GtkScale
    const Adjustment = GtkAdjustment
    const SpinButton = GtkSpinButton
    const ComboBoxText = GtkComboBoxText
    const Pixbuf = GdkPixbuf
    const Image = GtkImage
    const ProgressBar = GtkProgressBar
    const Spinner = GtkSpinner
    const Statusbar = GtkStatusbar
    const StatusIcon = GtkStatusIcon
    const TextBuffer = GtkTextBuffer
    const TextView = GtkTextView
    const Text = GtkTextView
    const TextMark = GtkTextMark
    const TextTag = GtkTextTag
    const MenuItem = GtkMenuItem
    const SeparatorMenuItem = GtkSeparatorMenuItem
    const Menu = GtkMenu
    const MenuBar = GtkMenuBar
    const FileChooserDialog = GtkFileChooserDialog
    const FileChooserAction = GtkFileChooserAction
    const Key = GdkKeySyms
    const Stock = GtkStock
    const Response = GtkResponse
    const EventMask = GdkEventMask
    const ModifierType = GdkModifierType
    const EventType = GdkEventType
    const ScrollDirection = GdkScrollDirection
    const Justification = GtkJustification
    const NullContainer = GtkNullContainer

    export G_, Window, Canvas, BoxLayout, ButtonBox, Paned, Layout, Notebook,
        Expander, Overlay, Frame, AspectFrame,
        Label, Button, CheckButton, RadioButton, RadioButtonGroup,
        ToggleButton, LinkButton, VolumeButton,
        Entry, Scale, Adjustment, SpinButton, ComboBoxText,
        Pixbuf, Image, ProgressBar, Spinner, Statusbar,
        StatusIcon, TextBuffer, TextView, TextMark, TextTag,
        MenuItem, SeparatorMenuItem, Menu, MenuBar,
        NullContainer, Key, ScrollDirection, Justification

    # Gtk 3
    if Gtk.gtk_version >= 3
        const Grid = GtkGrid
        export Grid
    end

    # Gtk 2
    if Gtk.gtk_version >= 2
        const Table = GtkTable
        const Alignment = GtkAlignment
        export Table, Aligment
    end

    # Selectors
    export FileChooserDialog, FileChooserAction, Stock, Response

    # Events
    export gtk_doevent, EventMask, ModifierType, EventType,
        signal_connect, signal_handler_disconnect,
        signal_handler_block, signal_handler_unblock,
        add_events, signal_emit,
        on_signal_destroy, on_signal_button_press,
        on_signal_button_release, on_signal_motion,
        popup
end
using .ShortNames
export Canvas, Window


init()
end
