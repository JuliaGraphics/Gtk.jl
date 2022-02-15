function _gtksubtype_constructors(name::Symbol, cm::Module)
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

macro gtktype_constructors(name)
    esc(quote
        _gtksubtype_constructors($(QuoteNode(name)), $__module__)
    end)
end

macro gtktype_custom_symname_and_lib(name, symname, lib)
    esc(quote
        @Gtype $name $lib $symname
        _gtksubtype_constructors($(QuoteNode(name)), $__module__)
    end)
end

macro gtktype_custom_symname(name, symname)
    esc(quote
        @gtktype_custom_symname_and_lib $(name) $(symname) libgtk
    end)
end

macro gtktype(name)
    groups = split(string(name), r"(?=[A-Z])")
    symname = Symbol(join([lowercase(s) for s in groups], "_"))
    esc(quote
        @gtktype_custom_symname $name $symname
    end)
end
@gtktype_constructors GtkMenuShell
@gtktype_constructors GtkProgressBar
@gtktype_constructors GtkStatusbar
@gtktype_constructors GtkInfoBar
@gtktype_constructors GtkRange
@gtktype_constructors GtkScale
@gtktype_constructors GtkSpinButton
@gtktype_constructors GtkBox
@gtktype_constructors GtkButtonBox
@gtktype_constructors GtkPaned
@gtktype_constructors GtkLayout
@gtktype_constructors GtkNotebook
@gtktype_constructors GtkCellRendererProgress
@gtktype_constructors GtkTreeView
@gtktype_constructors GtkCellView
@gtktype_constructors GtkIconView
@gtktype_constructors GtkTextView
@gtktype_constructors GtkToolbar
@gtktype_constructors GtkScaleButton
@gtktype_constructors GtkWindow
@gtktype_constructors GtkActionBar
@gtktype_constructors GtkComboBox
@gtktype_constructors GtkFrame
@gtktype_constructors GtkMenuItem
@gtktype_constructors GtkEventBox
@gtktype_constructors GtkFlowBoxChild
@gtktype_constructors GtkHandleBox
@gtktype_constructors GtkListBoxRow
@gtktype_constructors GtkToolItem
@gtktype_constructors GtkOverlay
@gtktype_constructors GtkScrolledWindow
@gtktype_constructors GtkAspectFrame
@gtktype_constructors GtkButton
@gtktype_constructors GtkAlignment
@gtktype_constructors GtkExpander
@gtktype_constructors GtkPopover
@gtktype_constructors GtkRevealer
@gtktype_constructors GtkSearchBar
@gtktype_constructors GtkStackSidebar
@gtktype_constructors GtkViewport

@gtktype_constructors GtkGrid
@gtktype_constructors GtkCellAreaBox

struct GtkRequisition
    width::Int32
    height::Int32
    GtkRequisition(width, height) = new(width, height)
end
