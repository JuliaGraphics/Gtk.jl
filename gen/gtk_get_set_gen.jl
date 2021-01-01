const GtkTypeMap = Set{Symbol}([
    #objects
    :GObject,
    :GdkPixbuf,
    :GtkAboutDialog,
    :GtkAccelGroup,
    :GtkAdjustment,
    :GtkAlignment,
    :GtkAspectFrame,
    :GtkBin,
    :GtkBox,
    :GtkBuilder,
    :GtkButton,
    :GtkButtonBox,
    :GtkCanvas,
    :GtkCellArea,
    :GtkCellAreaBox,
    :GtkCellAreaContext,
    :GtkCellRenderer,
    :GtkCellRendererAccel,
    :GtkCellRendererCombo,
    :GtkCellRendererPixbuf,
    :GtkCellRendererProgress,
    :GtkCellRendererSpin,
    :GtkCellRendererSpinner,
    :GtkCellRendererText,
    :GtkCellRendererToggle,
    :GtkCellView,
    :GtkCheckButton,
    :GtkComboBoxText,
    :GtkContainer,
    :GtkCssProvider,
    :GtkDialog,
    :GtkEntry,
    :GtkEntryCompletion,
    :GtkExpander,
    :GtkFileChooserDialog,
    :GtkFileChooserNative,
    :GtkFontButton,
    :GtkFrame,
    :GtkIconView,
    :GtkImage,
    :GtkLabel,
    :GtkLayout,
    :GtkLinkButton,
    :GtkListStore,
    :GtkMenu,
    :GtkMenuItem,
    :GtkMenuToolButton,
    :GtkMessageDialog,
    :GtkNativeDialog,
    :GtkNotebook,
    :GtkPaned,
    :GtkProgressBar,
    :GtkRadioButton,
    :GtkRange,
    :GtkScale,
    :GtkScrolledWindow,
    :GtkSeparatorToolItem,
    :GtkSpinButton,
    :GtkSpinner,
    :GtkStatusIcon,
    :GtkStatusbar,
    :GtkStyleContext,
    :GtkTable,
    :GtkTextBuffer,
    :GtkTextMark,
    :GtkTextTag,
    :GtkTextView,
    :GtkToggleButton,
    :GtkToggleToolButton,
    :GtkToolButton,
    :GtkToolItem,
    :GtkToolbar,
    :GtkTreeModelFilter,
    :GtkTreeModelFilter,
    :GtkTreeModelSort,
    :GtkTreeSelection,
    :GtkTreeStore,
    :GtkTreeView,
    :GtkTreeViewColumn,
    :GtkVolumeButton,
    :GtkWidget,
    :GtkWindow,

    #interfaces
    :GTypePlugin,
    :GtkActionable,
    :GtkAppChooser,
    :GtkBuildable,
    :GtkCellEditable,
    :GtkCellLayout,
    :GtkColorChooser,
    :GtkEditable,
    :GtkFileChooser,
    :GtkFontChooser,
    :GtkOrientable,
    :GtkPrintOperationPreview,
    :GtkRecentChooser,
    :GtkScrollable,
    :GtkStyleProvider,
    :GtkToolShell,
    :GtkTreeDragDest,
    :GtkTreeDragSource,
    :GtkTreeModel,
    :GtkTreeSortable,
    ])
const GtkBoxedMap = Set{Symbol}([
    :GClosure,
    :GdkFrameTimings,
    :GdkPixbufFormat,
    :GtkCssSection,
    :GtkGradient,
    :GtkIconSet,
    :GtkIconSource,
    :GtkPaperSize,
    :GtkRecentInfo,
    :GtkSelectionData,
    :GtkSymbolicColor,
    :GtkTargetList,
    :GtkTextAttributes,
    :GtkTreePath,
    :GtkTreeRowReference,
    :GtkWidgetPath,
    ])
cl_to_jl = Dict(
    CLVoid             => :Nothing,
    CLBool             => :Bool,
    CLChar_U           => :UInt8,
    CLUChar            => :Cuchar,
    CLChar16           => :UInt16,
    CLChar32           => :UInt32,
    CLUShort           => :UInt16,
    CLUInt             => :UInt32,
    CLULong            => :Culong,
    CLULongLong        => :Culonglong,
    CLChar_S           => :UInt8,
    CLSChar            => :UInt8,
    CLWChar            => :Char,
    CLShort            => :Int16,
    CLInt              => :Cint,
    CLLong             => :Clong,
    CLLongLong         => :Clonglong,
    CLFloat            => :Cfloat,
    CLDouble           => :Cdouble,
    CLLongDouble       => :Float64,
    CLEnum             => :Cint,
    CLUInt128          => :UInt128,
    CLFirstBuiltin     => :Nothing,
    )
c_typdef_to_jl = Dict{String,Any}(
    "va_list"               => :Nothing,
    "size_t"                => :Csize_t,
    "ptrdiff_t"             => :Cptrdiff_t,
    "GError"                => :(Gtk.GError),
    "GdkRectangle"          => :(Gtk.GdkRectangle),
    "GdkPoint"              => :(Gtk.GdkPoint),
    "GdkRGBA"               => :(Gtk.GdkRGBA),
    "GdkEventAny"           => :(Gtk.GdkEventAny),
    "GdkEventButton"        => :(Gtk.GdkEventButton),
    "GdkEventScroll"        => :(Gtk.GdkEventScroll),
    "GdkEventKey"           => :(Gtk.GdkEventKey),
    "GdkEventMotion"        => :(Gtk.GdkEventMotion),
    "GdkEventCrossing"      => :(Gtk.GdkEventCrossing),
    "GtkRequisition"        => :(Gtk.GtkRequisition),
    "GtkTextIter"           => :(Gtk.GtkTextIter),
    "GtkTreeIter"           => :(Gtk.GtkTreeIter),
    "GList"                 => :(Gtk._GList{Nothing}),
    "GSList"                => :(Gtk._GSList{Nothing}),
    )
for gtktype in GtkTypeMap
    c_typdef_to_jl[string(gtktype)] = :(Gtk.GObject)
end
for gtktype in GtkBoxedMap
    push!(GtkTypeMap,gtktype)
    c_typdef_to_jl[string(gtktype)] = Expr(:., :Gtk, QuoteNode(gtktype))
end
const reserved_names = Set{Symbol}([Symbol(x) for x in split("
    Base Main Core Array Expr Ptr
    type immutable module function macro ccall
    while do for if ifelse nothing quote
    start next end done top tuple convert
    Gtk GAccessor GValue unsafe_convert
    ")])
for typsym in values(cl_to_jl)
    push!(reserved_names, typsym)
end
for typsym in values(c_typdef_to_jl)
    if isa(typsym, Symbol)
        push!(reserved_names, typsym)
    end
end
const gtklibname = Dict{String,Any}(
    "gtk" => :(Gtk.libgtk),
    "gdk" => :(Gtk.libgdk),
    "gobject" => :(Gtk.GLib.libgobject),
    "glib" => :(Gtk.GLib.libglib),
    "gdk-pixbuf" => :(Gtk.libgdk_pixbuf),
    "deprecated" => nothing,
    )

g_type_to_jl(ctype::CLInvalid) = :Nothing
g_type_to_jl(ctype::CLUnexposed) = :Nothing
function g_type_to_jl(ctype::CLPointer)
    typ = g_type_to_jl(pointee_type(ctype))
    if typ == :Nothing
        return :(Ptr{Nothing})
    end
    :(Ptr{$typ})
end
function g_type_to_jl(ctype::CLTypedef)
    decl = typedecl(ctype)
    if isa(decl,CLNoDeclFound)
        return :Nothing
    end
    typname = spelling(decl)
    if typname in keys(c_typdef_to_jl)
        return c_typdef_to_jl[typname]
    end
    decl = g_type_to_jl(underlying_type(decl))
    if decl === :Nothing || decl === :Nothing
        return g_type_to_jl(canonical(ctype))
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
    if !isa(ctype, CLPointer)
        return :Nothing
    end
    arg1ty = pointee_type(ctype)
    if !isa(arg1ty, CLTypedef)
        return :Nothing
    end
    arg1ty = Symbol(spelling(typedecl(arg1ty)))
    if !(arg1ty in GtkTypeMap)
        return :Nothing
    end
    return Expr(:., :Gtk, QuoteNode(arg1ty))
end

function is_gstring(ctype)
    if !isa(ctype, CLPointer)
        return false
    end
    ctype = pointee_type(ctype)
    if isconst(ctype) == 0
        return false
    end
    ctypedecl = typedecl(ctype)
    if spelling(ctypedecl) != "gchar"
        return false
    end
    true
end

function is_gbool(ctype)
    ctypedecl = typedecl(ctype)
    if spelling(ctypedecl) != "gboolean"
        return false
    end
    true
end

function isduplicatedef(expr, name, arg1ty, argcount)
    if expr.head == :function
        fargs = expr.args[1].args
        return fargs[1] == name &&
            fargs[2].args[2] == arg1ty && 
            length(fargs[2:end]) == argcount
    end
    false
end

function gen_get_set(body, gtk_h)
    fdecls = Clang.search(gtk_h, Clang.CXCursor_FunctionDecl)
    exports = Set{Symbol}([:default_icon_list, :position])
    export_stmt = Expr(:export)
    push!(body.args,export_stmt)
    count = 0
    for fdecl in fdecls
        fargs = Clang.search(fdecl, Clang.CXCursor_ParmDecl)
        if length(fargs) < 1
            continue
        end
        arg1ty = g_get_gtype(type(fargs[1]))
        if arg1ty === :Nothing
            continue
        end
        spell = spelling(fdecl)
        if startswith(spell,"gtk_test_") || startswith(spell,"_")
            continue
        end
        m = match(r"g.+_(get|set)_(.+)", spell)
        if m === nothing
            continue
        end
        method_name = Symbol(m.captures[2])
        header_file = filename(fdecl)
        libname = gtklibname[basename(splitdir(header_file)[1])]
        if libname === nothing
            continue
        end
        rettype = g_type_to_jl(return_type(fdecl))
        argnames = [Symbol(name(arg)) for arg in fargs]
        for i = 1:length(argnames)
            if argnames[i] == method_name || argnames[i] in reserved_names
                argnames[i] = Symbol(string(argnames[i],'_'))
            end
        end
        argtypes = [g_type_to_jl(type(arg)) for arg in fargs]
        @assert length(argnames) == length(argtypes)
        if any(argtypes .== :Nothing) || any(argtypes .== :Nothing)
            continue
        end
        if m.captures[1] == "get"
            fbody = :( ccall(($(QuoteNode(Symbol(spell))),$libname),$rettype,($(argtypes...),),$(argnames...)) )
            gtype = g_get_gtype(return_type(fdecl))
            if gtype != :Nothing
                fbody = :( convert($gtype, $fbody) )
            end
            fbody = Expr(:block, fbody)
            fargnames = Symbol[]
            multiret = false
            last_inarg = 1
            for i = 2:length(argnames)
                atype = type(fargs[i])
                if !isa(atype, CLPointer) || is_gstring(atype)
                    last_inarg = i
                end
            end
            for i = 2:length(argnames)
                atype = type(fargs[i])
                if i > last_inarg
                    atype = pointee_type(atype)
                    T = g_type_to_jl(atype)
                    if T !== :Nothing && T != :(Gtk.GObject)
                        retval = argnames[i]
                        pushfirst!(fbody.args, :( $retval = Gtk.mutable($T) ))
                        retval = :( $retval[] )
                        gtype = g_get_gtype(atype)
                        if gtype !== :Nothing
                            retval = :( convert($gtype, $retval) )
                            T = gtype
                        end
                        if multiret
                            push!(fbody.args[end].args, retval)
                        elseif rettype !== :Nothing
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
            if !any(ex -> isduplicatedef(ex, method_name, arg1ty, length(fargnames)+1), body.args)
                push!(body.args, Expr(:function, Expr(:call, method_name, Expr(:(::),argnames[1],arg1ty), fargnames...), fbody))
            end
        elseif m.captures[1] == "set"
            fbody = Expr(:block,
                :( ccall(($(QuoteNode(Symbol(spell))),$libname),$rettype,($(argtypes...),),$(argnames...)) ),
                Expr(:return, argnames[1])
            )
            if !any(ex -> isduplicatedef(ex, method_name, arg1ty, length(argnames)), body.args)
                push!(body.args, Expr(:function, Expr(:call, method_name, Expr(:(::),argnames[1],arg1ty), argnames[2:end]...), fbody))
            end
        else
            @assert false
        end
        push!(exports, method_name)
        count += 1
    end
    push!(body.args, quote
        function default_icon_list()
            ccall((:gtk_window_get_default_icon_list,Gtk.libgtk), Ptr{Gtk._GList{Gtk.GdkPixbuf}}, ())
            return list
        end
        function default_icon_list(list::Gtk.GList)
            ccall((:gtk_window_set_default_icon_list,Gtk.libgtk), Nothing, (Ptr{Gtk._GList{Nothing}},), list)
            return list
        end
        function position(w::Gtk.GtkWindow,x::Integer,y::Integer)
            ccall((:gtk_window_move,Gtk.libgtk),Nothing,(Ptr{Gtk.GObject},Cint,Cint),w,x,y)
            w
        end
    end)
    for x in exports
        push!(export_stmt.args, x)
    end
    count
end
