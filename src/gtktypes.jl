function _gtksubtype_constructors(name::Symbol)
    cm = current_module()
    ename = Symbol(string(name, getfield(cm, :suffix)))
    typ = getfield(cm, ename)
    if GLib.g_isa(typ, GtkOrientable)
        @eval $ename(orientation::Symbol, vargs...) = $ename(
            (orientation == :v ? true :
            (orientation == :h ? false :
            error("invalid $($ename) orientation $orientation"))), vargs...)
    end
    if isdefined(Gtk, :GtkContainer) && GLib.g_isa(typ, GtkContainer)
        @eval $ename(child::GtkWidget, vargs...) = push!($ename(vargs...), child)
    end
end

macro gtktype_custom_symname_and_lib(name, symname, lib)
    quote
        @Gtype $(esc(name)) $(esc(lib)) $(esc(symname))
        _gtksubtype_constructors($(QuoteNode(name)))
    end
end

macro gtktype_custom_symname(name, symname)
    quote
        @gtktype_custom_symname_and_lib $(esc(name)) $(esc(symname)) libgtk
    end
end

macro gtktype(name)
    groups = split(string(name), r"(?=[A-Z])")
    symname = Symbol(join([lowercase(s) for s in groups], "_"))
    quote
        @gtktype_custom_symname $(esc(name)) $(esc(symname))
    end
end
@gtktype GtkWidget
@gtktype GtkContainer
@gtktype GtkBin
@gtktype GtkDialog
@gtktype GtkMenuShell

@gtktype GtkAccelGroup
@gtktype GtkBuilder
@gtktype GtkButton
@gtktype GtkCheckButton
@gtktype GtkToggleButton
@gtktype GtkRadioButton
@gtktype GtkLinkButton
@gtktype GtkVolumeButton
@gtktype GtkFontButton
@gtktype GtkDrawingArea
@gtktype GtkImage
@gtktype GtkProgressBar
@gtktype GtkSpinner
@gtktype GtkStatusbar
@gtktype GtkStatusIcon
#TODO: @gtktype GtkInfoBar
@gtktype GtkEntry
@gtktype GtkEntryCompletion
@gtktype GtkRange
@gtktype GtkScale
@gtktype GtkAdjustment
@gtktype GtkSpinButton
@gtktype GtkTable
@gtktype GtkAlignment
@gtktype GtkFrame
@gtktype GtkAspectFrame
@gtktype GtkBox
@gtktype GtkButtonBox
@gtktype GtkPaned
@gtktype GtkLayout
@gtktype GtkExpander
@gtktype GtkNotebook
@gtktype GtkComboBoxText
@gtktype GtkListStore
@gtktype GtkTreeStore
@gtktype GtkTreeModelFilter
@gtktype GtkCellRenderer
@gtktype GtkCellRendererAccel
@gtktype GtkCellRendererCombo
@gtktype GtkCellRendererPixbuf
@gtktype GtkCellRendererProgress
@gtktype GtkCellRendererSpin
@gtktype GtkCellRendererText
@gtktype GtkCellRendererToggle
@gtktype GtkCellRendererSpinner
@gtktype GtkTreeViewColumn
@gtktype GtkTreeSelection
@gtktype GtkTreeView
@gtktype GtkTreeModelSort
@gtktype GtkCellView
@gtktype GtkIconView
@gtktype GtkMenuItem
@gtktype GtkSeparatorMenuItem
@gtktype GtkMenu
@gtktype GtkMenuBar
@gtktype GtkFileChooserDialog
@gtktype GtkFileFilter
@gtktype GtkLabel
@gtktype GtkTextBuffer
@gtktype GtkTextView
@gtktype GtkTextMark
@gtktype GtkTextTag
@gtktype GtkToolbar
@gtktype GtkToolItem
@gtktype GtkToolButton
@gtktype GtkToggleToolButton
@gtktype GtkMenuToolButton
@gtktype GtkSeparatorToolItem
@gtktype GtkWindow
@gtktype GtkScrolledWindow
@gtktype GtkAboutDialog
@gtktype GtkMessageDialog
@Gtype GApplication libgio g_application
@Gtype GdkPixbuf libgdk_pixbuf gdk_pixbuf
#TODO: @gtktype GtkScaleButton

if libgtk_version >= v"3"
    @gtktype GtkApplication
    @gtktype GtkApplicationWindow
    @gtktype GtkSwitch
    @gtktype GtkGrid
    @gtktype GtkOverlay # this is a GtkBin, although it behaves more like a container
    @gtktype GtkCellArea
    @gtktype GtkCellAreaBox
    @gtktype GtkCellAreaContext
    @gtktype GtkCssProvider
    @gtktype GtkStyleContext

else
    type GtkApplication end
    GtkApplicationLeaf(x...) = error("GtkApplication is not available until Gtk3.0")
    macro GtkApplication(args...)
        :( GtkApplicationLeaf($(args...)) )
    end

    type GtkApplicationWindow end
    GtkApplicationWindowLeaf(x...) = error("GtkApplicationWindow is not available until Gtk3.0")
    macro GtkApplicationWindow(args...)
        :( GtkApplicationWindowLeaf($(args...)) )
    end

    @g_type_delegate GtkSwitch = GtkToggleButton

    type GtkGrid end
    GtkGridLeaf(x...) = error("GtkGrid is not available until Gtk3.0")
    macro GtkGrid(args...)
        :( GtkGridLeaf($(args...)) )
    end

    type GtkOverlay end
    GtkOverlayLeaf(x...) = error("GtkOverlay is not available until Gtk3.2")
    macro GtkOverlay(args...)
        :( GtkOverlayLeaf($(args...)) )
    end

    type GtkCssProvider end
    GtkCssProviderLeaf(x...) = error("GtkStyleContext is not available until Gtk3.0")
    macro GtkCssProvider(args...)
        :( GtkCssProviderLeaf($(args...)) )
    end

    type GtkStyleContext end
    GtkStyleContextLeaf(x...) = error("GtkStyleContext is not available until Gtk3.0")
    macro GtkStyleContext(args...)
        :( GtkStyleContextLeaf($(args...)) )
    end
end

if libgtk_version >= v"3.16.0"
@gtktype_custom_symname GtkGLArea gtk_gl_area
else
type GtkGLArea end
    GtkGLAreaLeaf(x...) = error("GtkGLArea is not fully available until Gtk3.16.0 (though available as separate library)")
    macro GtkGLArea(args...)
        :( GtkGLAreaLeaf($(args...)) )
    end
end
