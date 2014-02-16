const GtkTypeMap = (ASCIIString=>Symbol)[
    "GObject" => :GObjectI,
    "GtkWidget" => :GtkWidgetI,
    "GtkContainer" => :GtkContainerI,
    "GtkBin" => :GtkBinI,
    "GtkBox" => :GtkBoxI,
    "GdkPixbuf" => :GdkPixbufI,
    "GtkStatusIcon" => :GtkStatusIconI,
    "GtkTextBuffer" => :GtkTextBufferI,
    "GtkTextMark" => :GtkTextMarkI,
    "GtkTextTag" => :GtkTextTagI,
    "GtkCanvas" => :GtkCanvasI,
    "GtkComboBoxText" => :GtkComboBoxTextI,
    "GtkEditable" => :GtkEditableI,
    "GtkEntry" => :GtkEntryI,
    "GtkEntryCompletion" => :GtkEntryCompletionI,
    "GtkImage" => :GtkImageI,
    "GtkLabel" => :GtkLabelI,
    "GtkProgressBar" => :GtkProgressBarI,
    "GtkScale" => :GtkScaleI,
    "GtkRange" => :GtkScaleI, #GtkRangeI,
    "GtkAdjustment" => :GtkAdjustmentI,
    "GtkSpinButton" => :GtkSpinButtonI,
    "GtkSpinner" => :GtkSpinnerI,
    "GtkTextView" => :GtkTextViewI,
    "GtkLayout" => :GtkLayoutI,
    "GtkNotebook" => :GtkNotebookI,
    "GtkPaned" => :GtkPanedI,
    "GtkTable" => :GtkTableI,
    "GtkButtonBox" => :GtkButtonBoxI,
    "GtkStatusbar" => :GtkStatusbarI,
    "GtkAlignment" => :GtkAlignmentI,
    "GtkAspectFrame" => :GtkAspectFrameI,
    "GtkButton" => :GtkButtonI,
    "GtkCheckButton" => :GtkCheckButtonI,
    "GtkExpander" => :GtkExpanderI,
    "GtkFrame" => :GtkFrameI,
    "GtkLinkButton" => :GtkLinkButtonI,
    "GtkRadioButton" => :GtkRadioButtonI,
    "GtkToggleButton" => :GtkToggleButtonI,
    "GtkVolumeButton" => :GtkVolumeButtonI,
    "GtkFontButton" => :GtkFontButtonI,
    "GtkWindow" => :GtkWindowI,
    "GtkDialog" => :GtkDialogI,
    "GtkFileChooserDialog" => :GtkFileChooserDialogI,
    "GtkFileChooser" => :GtkFileChooserDialogI,
    "GtkAboutDialog" => :GtkAboutDialogI,
    "GtkMessageDialog" => :GtkMessageDialogI,
    "GtkBuilder" => :GtkBuilderI,
    "GtkListStore" => :GtkListStoreI,
    "GtkTreeStore" => :GtkTreeStoreI,
    "GtkTreeModelSort" => :GtkTreeModelSortI,
    "GtkTreeModelFilter" => :GtkTreeModelFilterI,
    "GtkCellArea" => :GtkCellAreaI,
    "GtkCellAreaBox" => :GtkCellAreaBoxI,
    "GtkCellAreaContext" => :GtkCellAreaContextI,
    "GtkCellRenderer" => :GtkCellRendererI,
    "GtkCellEditable" => :GtkCellEditableI,
    "GtkCellRendererAccel" => :GtkCellRendererAccelI,
    "GtkCellRendererCombo" => :GtkCellRendererComboI,
    "GtkCellRendererPixbuf" => :GtkCellRendererPixbufI,
    "GtkCellRendererProgress" => :GtkCellRendererProgressI,
    "GtkCellRendererSpin" => :GtkCellRendererSpinI,
    "GtkCellRendererText" => :GtkCellRendererTextI,
    "GtkCellRendererToggle" => :GtkCellRendererToggleI,
    "GtkCellRendererSpinner" => :GtkCellRendererSpinnerI,
    "GtkTreeViewColumn" => :GtkTreeViewColumnI,
    "GtkTreeView" => :GtkTreeViewI,
    "GtkCellView" => :GtkCellViewI,
    "GtkIconView" => :GtkIconViewI,
    "GtkTreeSelection" => :GtkTreeSelectionI,
    "GtkTreeSortable" => :GtkTreeSortableI,
    "GtkTreeModel" => :GtkTreeModelI,
    "GtkTreeModelFilter" => :GtkTreeModelFilterI,
    "GtkScrolledWindow" => :GtkScrolledWindowI,
    "GtkToolbar" => :GtkToolbarI,
    "GtkToolItem" => :GtkToolItemI,
    "GtkToolButton" => :GtkToolButtonI,
    "GtkToggleToolButton" => :GtkToggleToolButtonI,
    "GtkSeparatorToolItem" => :GtkSeparatorToolItemI,
    "GtkMenuToolButton" => :GtkMenuToolButtonI,
    "GtkCssProvider" => :GtkCssProviderI,
    "GtkStyleProvider" => :GtkStyleProviderI,  
    "GtkStyleContext" => :GtkStyleContextI,
    "GtkFontChooser" => :GtkFontChooserI,
    "GtkAccelGroup" => :GtkAccelGroupI,
    "GtkMenu" => :GtkMenuI,
    "GtkMenuItem" => :GtkMenuItemI,
    ]
const GtkBoxedMap = (ASCIIString=>Symbol)[
    "GtkTreePath" => :GtkTreePath,
    ]
cl_to_jl = [
    cindex.VoidType         => :Void,
    cindex.BoolType         => :Bool,
    cindex.Char_U           => :Uint8,
    cindex.UChar            => :Cuchar,
    cindex.Char16           => :Uint16,
    cindex.Char32           => :Uint32,
    cindex.UShort           => :Uint16,
    cindex.UInt             => :Uint32,
    cindex.ULong            => :Culong,
    cindex.ULongLong        => :Culonglong,
    cindex.Char_S           => :Uint8,
    cindex.SChar            => :Uint8,
    cindex.WChar            => :Char,
    cindex.Short            => :Int16,
    cindex.IntType          => :Cint,
    cindex.Long             => :Clong,
    cindex.LongLong         => :Clonglong,
    cindex.Float            => :Cfloat,
    cindex.Double           => :Cdouble,
    cindex.LongDouble       => :Float64,
    cindex.Enum             => :Cint,
    cindex.UInt128          => :Uint128,
    cindex.FirstBuiltin     => :Void,
    ]
c_typdef_to_jl = (ASCIIString=>Any)[
    "va_list"               => :Nothing,
    "size_t"                => :Csize_t,
    "ptrdiff_t"             => :Cptrdiff_t,
    "GError"                => :(Gtk.GError),
    "GdkRectangle"          => :(Gtk.GdkRectangle),
    "GdkPoint"              => :(Gtk.GdkPoint),
    "GdkEventAny"           => :(Gtk.GdkEventAny),
    "GdkEventButton"        => :(Gtk.GdkEventButton),
    "GdkEventScroll"        => :(Gtk.GdkEventScroll),
    "GdkEventKey"           => :(Gtk.GdkEventKey),
    "GdkEventMotion"        => :(Gtk.GdkEventMotion),
    "GdkEventCrossing"      => :(Gtk.GdkEventCrossing),
    "GtkTextIter"           => :(Gtk.GtkTextIter),
    "GtkTreeIter"           => :(Gtk.GtkTreeIter),
    "GList"                 => :(Gtk._GList),
    "GSList"                => :(Gtk._GSList),
    ]
for gtktype in keys(GtkTypeMap)
    c_typdef_to_jl[gtktype] = :(Gtk.GObject)
end
for (gtktype,v) in GtkBoxedMap
    GtkTypeMap[gtktype] = v
    c_typdef_to_jl[gtktype] = Expr(:., :Gtk, Meta.quot(v))
end
const reserved_names = Set{Symbol}([symbol(x) for x in split("
    Base Main Core Array Expr Ptr
    type immutable module function macro ccall
    while do for if ifelse nothing quote
    start next end done top tuple convert
    Gtk GAccessor GValue
    ")]...)
for typsym in values(cl_to_jl)
    push!(reserved_names, typsym)
end
for typsym in values(c_typdef_to_jl)
    if isa(typsym, Symbol)
        push!(reserved_names, typsym)
    end
end
const gtklibname = (ASCIIString=>Any)[
    "gtk" => Expr(:., :Gtk, Expr(:quote, :libgtk)),
    "gdk" => Expr(:., :Gtk, Expr(:quote, :libgdk)),
    "gobject" => Expr(:., :Gtk, Expr(:quote, :libgobject)),
    "glib" => Expr(:., :Gtk, Expr(:quote, :libglib)),
    "gdk-pixbuf" => Expr(:., :Gtk, Expr(:quote, :libgdk_pixbuf)),
    "deprecated" => nothing,
    ]

g_type_to_jl(ctype::cindex.Invalid) = :Nothing
g_type_to_jl(ctype::cindex.Unexposed) = :Void
function g_type_to_jl(ctype::cindex.Pointer)
    typ = g_type_to_jl(cindex.pointee_type(ctype))
    if typ == :Nothing
        return :(Ptr{Void})
    end
    :(Ptr{$typ})
end
function g_type_to_jl(ctype::cindex.Typedef)
    decl = cindex.getTypeDeclaration(ctype)
    if isa(decl,cindex.NoDeclFound)
        return :Nothing
    end
    typname = cindex.spelling(decl)
    if typname in keys(c_typdef_to_jl)
        return c_typdef_to_jl[typname]
    end
    decl = g_type_to_jl(cindex.getTypedefDeclUnderlyingType(decl))
    if decl === :Nothing || decl === :Void
        return g_type_to_jl(cindex.getCanonicalType(ctype))
    end
    decl
end
function g_type_to_jl(ctype)
    get(cl_to_jl,typeof(ctype),:Nothing)
end

function g_get_gtype(ctype)
    if is_gbool(ctype)
        return :Bool
    end
    if !isa(ctype, cindex.Pointer)
        return :Nothing
    end
    arg1ty = cindex.pointee_type(ctype)
    if !isa(arg1ty, cindex.Typedef)
        return :Nothing
    end
    arg1ty = get(GtkTypeMap,cindex.spelling(cindex.getTypeDeclaration(arg1ty)),:Void)
    if arg1ty === :Void
        return :Nothing
    end
    return Expr(:., :Gtk, Expr(:quote,arg1ty))
end

function is_gstring(ctype)
    if !isa(ctype, cindex.Pointer)
        return false
    end
    ctype = cindex.pointee_type(ctype)
    if !bool(cindex.isConstQualifiedType(ctype))
        return false
    end
    ctypedecl = cindex.getTypeDeclaration(ctype)
    if cindex.spelling(ctypedecl) != "gchar"
        return false
    end
    true
end

function is_gbool(ctype)
    ctypedecl = cindex.getTypeDeclaration(ctype)
    if cindex.spelling(ctypedecl) != "gboolean"
        return false
    end
    true
end

function gen_get_set(body, gtk_h)
    fdecls = cindex.search(gtk_h, cindex.FunctionDecl)
    count = 0
    for fdecl in fdecls
        fargs = cindex.search(fdecl, cindex.ParmDecl)
        if length(fargs) < 1
            continue
        end
        arg1ty = g_get_gtype(cindex.getCursorType(fargs[1]))
        if arg1ty === :Nothing
            continue
        end
        spell = cindex.spelling(fdecl)
        if beginswith(spell,"gtk_test_") || beginswith(spell,"_")
            continue
        end
        m = match(r"g.+_(get|set)_(.+)", spell)
        if m === nothing
            continue
        end
        method_name = symbol(m.captures[2])
        header_file = cindex.cu_file(fdecl)
        libname = gtklibname[basename(splitdir(header_file)[1])]
        if libname == nothing
            continue
        end
        rettype = g_type_to_jl(cindex.return_type(fdecl))
        argnames = [symbol(cindex.name(arg)) for arg in fargs]
        for i = 1:length(argnames)
            if argnames[i] == method_name || argnames[i] in reserved_names
                argnames[i] = symbol(string(argnames[i],'_'))
            end
        end
        argtypes = [g_type_to_jl(cindex.getCursorType(arg)) for arg in fargs]
        @assert length(argnames) == length(argtypes)
        if any(argtypes .== :Nothing) || any(argtypes .== :Void)
            continue
        end
        if m.captures[1] == "get"
            fbody = :( ccall(($(Meta.quot(symbol(spell))),$libname),$rettype,($(argtypes...),),$(argnames...)) )
            gtype = g_get_gtype(cindex.return_type(fdecl))
            if gtype != :Nothing
                fbody = :( convert($gtype, $fbody) )
            end
            fbody = Expr(:block, fbody)
            fargnames = Symbol[]
            multiret = false
            last_inarg = 1
            for i = 2:length(argnames)
                atype = cindex.getCursorType(fargs[i])
                if !isa(atype, cindex.Pointer) || is_gstring(atype)
                    last_inarg = i
                end
            end
            for i = 2:length(argnames)
                atype = cindex.getCursorType(fargs[i])
                if i > last_inarg
                    atype = cindex.getPointeeType(atype)
                    T = g_type_to_jl(atype)
                    if T !== :Nothing && T !== :Void && T != :(Gtk.GObject)
                        retval = argnames[i]
                        unshift!(fbody.args, :( $retval = Gtk.mutable($T) ))
                        retval = :( $retval[] )
                        gtype = g_get_gtype(atype)
                        if gtype !== :Nothing
                            retval = :( convert($gtype, $retval) )
                            T = gtype
                        end
                        if multiret
                            push!(fbody.args[end].args, retval)
                        elseif rettype !== :Void
                            fbody.args[end] = Expr(:tuple, fbody.args[end], retval)
                            multiret = true
                        else
                            push!(fbody.args, retval)
                            rettype = T
                        end
                        continue
                    end
                end
                push!(fargnames, argnames[i])
            end
            fbody.args[end] = Expr(:return,fbody.args[end])
            push!(body.args, Expr(:function, Expr(:call, method_name, Expr(:(::),argnames[1],arg1ty), fargnames...), fbody))
        elseif m.captures[1] == "set"
            fbody = Expr(:block,
                :( ccall(($(Meta.quot(symbol(spell))),$libname),$rettype,($(argtypes...),),$(argnames...)) ),
                Expr(:return, argnames[1])
            )
            push!(body.args, Expr(:function, Expr(:call, method_name, Expr(:(::),argnames[1],arg1ty), argnames[2:end]...), fbody))
        else
            @assert false
        end
        count += 1
    end
    push!(body.args, quote
        function default_icon_list()
            ccall((:gtk_window_get_default_icon_list,Gtk.libgtk), Ptr{Gtk._GList{Gtk.GdkPixbuf}}, ())
            return list
        end
        function default_icon_list(list::Gtk.GList)
            ccall((:gtk_window_set_default_icon_list,Gtk.libgtk), Void, (Ptr{Gtk._GList},), list)
            return list
        end
        function position(w::Gtk.GtkWindowI,x::Integer,y::Integer)
            ccall((:gtk_window_move,Gtk.libgtk),Void,(Ptr{Gtk.GObjectI},Cint,Cint),w,x,y)
            w
        end
    end)
    count
end
