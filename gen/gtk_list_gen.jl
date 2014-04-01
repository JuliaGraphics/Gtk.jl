import Gtk
import Gtk.GLib: g_type, g_type_from_name, g_isa, GObject, get_fn_ptr
import Clang, Clang.cindex

function gen_g_type_lists(gtk_h)
    replacelist = (Symbol=>Symbol)[
        :GVariant => :nothing,
        :GType => :g_gtype,
        ]
    tdecls = cindex.search(gtk_h, cindex.TypedefDecl)
    leafs = (Symbol,Expr)[]
    ifaces = (Symbol,Expr)[]
    boxes = (Symbol,Expr)[]
    gpointers = (Symbol,Expr)[]
    for tdecl in tdecls
        sdecl = cindex.getTypeDeclaration(cindex.getCanonicalType(
            cindex.getTypedefDeclUnderlyingType(tdecl)))
        isa(sdecl, cindex.StructDecl) || continue
        typname = symbol(cindex.spelling(tdecl))
        header_file = cindex.cu_file(tdecl)
        libname = get(gtklibname,basename(splitdir(header_file)[1]),nothing)
        libname == nothing && continue
        if typname in keys(replacelist)
            symname = replacelist[typname]
            symname == :nothing && continue
        else
            symname = symbol(join([lowercase(s) for s in split(string(typname), r"(?=[A-Z])")],"_"))
        end
        gtyp = g_type(typname, libname, symname)
        if gtyp == 0
            gtyp = g_type_from_name(typname)
            if gtyp != 0 && !(gtyp in Gtk.GLib.fundamental_ids)
                println("WARNING: couldn't guess symname for $typname -- skipping")
            end
            continue
        end
        if g_isa(gtyp, g_type_from_name(:GInterface))
            push!(ifaces,(typname, :(@Giface $typname $libname $symname)))
        elseif g_isa(gtyp, g_type_from_name(:GBoxed))
            unref_fn = symbol(string(symname,:_free))
            if get_fn_ptr(unref_fn, libname) == C_NULL
                unref_fn = symbol(string(symname,:_unref))
                if get_fn_ptr(unref_fn, libname) == C_NULL
                    unref_fn = nothing
                end
                ref_fn = :(ccall(($(QuoteNode(symbol(string(symname,:_ref)))),$libname),Void,(Ptr{Void},),ref))
            else
                ref_fn = nothing
            end
            if length(cindex.children(sdecl)) == 0 || unref_fn !== nothing
                # Opaque box
                if unref_fn === nothing
                    println("WARNING: couldn't detect gc characteristics of $symname")
                    continue
                end
                push!(gpointers, (typname, quote
                    type $typname <: GBoxed
                        handle::Ptr{$typname}
                        function $typname(ref::Ptr{$typname})
                            $ref_fn
                            x = new(ref)
                            finalizer(x, (x::$typname)->ccall(($(QuoteNode(unref_fn)),$libname),Void,
                                (Ptr{Void},),x.handle))
                            path
                        end
                    end
                end))
            else
                # Stack-allocated box
                valid = true
                paramlist = Expr(:block)
                ex = Expr(:type, false, typname, paramlist)
                for cu in cindex.children(sdecl)
                    name = cindex.spelling(cu)
                    if isempty(name)
                        name = gensym()
                    end
                    jtyp = g_type_to_jl(cindex.getCursorType(cu))
                    if jtyp === :Nothing
                        jtyp = " < $(cindex.getCursorType(cu)) >"
                        valid = false
                    end
                    push!(paramlist.args, Expr(:(::), symbol(name), jtyp))
                end
                if valid
                    push!(boxes,(typname, ex))
                else
                    println("WARNING: unable to generate box for $typname: $ex")
                end
            end
        elseif g_isa(gtyp, g_type(GObject))
            push!(leafs,(typname, :(@Gtype $typname $libname $symname)))
        else
            println("WARNING: skipping $gtyp of unknown type")
        end
    end
    leafs,ifaces,boxes,gpointers
end
