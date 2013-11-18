import Clang.cindex
gtk_libdir = "/opt/local/lib"

const GtkTypeMap = [
    "GObject" => :GObjectI,
    "GtkWidget" => :GtkWidgetI,
    "GtkContainer" => :GtkContainerI,
    "GtkBin" => :GtkBinI,
    "GtkBox" => :GtkBoxI,
    "GdkPixbuf" => :GdkPixbuf,
    "GtkStatusIcon" => :GtkStatusIcon,
    "GtkTextBuffer" => :GtkTextBuffer,
    "GtkTextMark" => :GtkTextMark,
    "GtkTextTag" => :GtkTextTag,
    "GtkCanvas" => :GtkCanvas,
    "GtkComboBoxText" => :GtkComboBoxText,
    "GtkEntry" => :GtkEntry,
    "GtkImage" => :GtkImage,
    "GtkLabel" => :GtkLabel,
    "GtkProgressBar" => :GtkProgressBar,
    "GtkScale" => :GtkScale,
    "GtkSpinButton" => :GtkSpinButton,
    "GtkSpinner" => :GtkSpinner,
    "GtkTextView" => :GtkTextView,
    "GtkLayout" => :GtkLayout,
    "GtkNotebook" => :GtkNotebook,
    "GtkPaned" => :GtkPaned,
    "GtkTable" => :GtkTable,
    "GtkButtonBox" => :GtkButtonBox,
    "GtkStatusbar" => :GtkStatusbar,
    "GtkAlignment" => :GtkAlignment,
    "GtkAspectFrame" => :GtkAspectFrame,
    "GtkButton" => :GtkButton,
    "GtkCheckButton" => :GtkCheckButton,
    "GtkExpander" => :GtkExpander,
    "GtkFrame" => :GtkFrame,
    "GtkLinkButton" => :GtkLinkButton,
    "GtkRadioButton" => :GtkRadioButton,
    "GtkToggleButton" => :GtkToggleButton,
    "GtkVolumeButton" => :GtkVolumeButton,
    "GtkWindow" => :GtkWindow,
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
c_typdef_to_jl = [
    "size_t"                => :Csize_t,
    "ptrdiff_t"             => :Cptrdiff_t,
    "GdkRectangle"          => :(Gtk.GdkRectangle),
    "GdkPoint"              => :(Gtk.GdkPoint),
    "GdkEventButton"        => :(Gtk.GdkEventButton),
    "GdkEventMotion"        => :(Gtk.GdkEventMotion),
    ]
for gtktype in keys(GtkTypeMap)
    c_typdef_to_jl[gtktype] = :(Gtk.GObject)
end

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

function gen_get_set(body, header, args)
    local gtk_h
    cd(JULIA_HOME) do
        gtk_h = cindex.parse_header(header, diagnostics=true, args=args)
    end
    fdecls = cindex.search(gtk_h, cindex.FunctionDecl)
    count = 0
    for fdecl in fdecls
        fargs = cindex.function_args(fdecl)
        if length(fargs) < 1
            continue
        end
        arg1ty = g_get_gtype(fargs[1])
        if arg1ty === :Nothing
            continue
        end
        spell = cindex.spelling(fdecl)
        m = match(r"g.+_(get|set)_(.+)", spell)
        if m === nothing
            continue
        end
        method_name = symbol(m.captures[2])
        header_file = cindex.cu_file(fdecl)
        libname = Expr(:., :Gtk, Expr(:quote, symbol(string("lib",basename(splitdir(header_file)[1])))))
        rettype = g_type_to_jl(cindex.return_type(fdecl))
        argnames = [symbol(cindex.name(arg)) for arg in filter!((f)->isa(f,cindex.ParmDecl),[cindex.children(fdecl)...])]
        for i = 1:length(argnames)
            if argnames[i] == method_name
                argnames[i] = symbol(string(argnames[i],'_'))
            end
        end
        argtypes = [g_type_to_jl(arg) for arg in fargs]
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
            for i = 2:length(argnames)
                atype = fargs[i]
                if isa(atype, cindex.Pointer) && !is_gstring(atype)
                    atype = cindex.getPointeeType(atype)
                    T = g_type_to_jl(atype)
                    if T !== :Nothing && T !== :Void && T !== :GObject
                        retval = argnames[i]
                        unshift!(fbody.args, :( $retval = Array($T) ))
                        retval = :( $retval[1] )
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
    count
end

toplevels = {}
ARCHS = ((32,("-m32",)),(64,("-m64",)))
for (word_size,cppflags) = ARCHS
    for gtk_version = (2, 3)
        body = Expr(:block,
            Expr(:import, :., :., :Gtk),
            Expr(:import, :., :., :Gtk, :GObject),
            Expr(:import, :., :., :Gtk, :GObjectI),
        )
        toplevel = Expr(:toplevel,Expr(:module, true, :GAccessor, body))
        args = ASCIIString[split(readall(`$(joinpath(gtk_libdir,"..","bin","pkg-config")) --cflags gtk+-$gtk_version.0`),' ')..., cppflags...]
        count = gen_get_set(body, joinpath(gtk_libdir,"..","include","gtk-$gtk_version.0","gtk","gtk.h"), args)
        cachepath = "gbox$(gtk_version)_$(Sys.OS_NAME)_m$(word_size)_julia$(VERSION.major)_$(VERSION.minor)"
        println("Generated $cachepath with $count function definitions")
        open(joinpath(splitdir(@__FILE__)[1], cachepath), "w") do cache
            serialize(cache, toplevel)
        end
        push!(toplevels,toplevel)
    end
end
toplevels
