import Gtk
import Gtk.GLib: g_type, g_type_from_name, g_isa, GObject, get_fn_ptr
importall Gtk.GLib.Compat
import Clang, Clang.cindex

function gen_g_type_lists(gtk_h)
    replacelist = Dict{Symbol,Symbol}(
        :GVariant => :nothing,
        :GType => :g_gtype,
        )
    tdecls = cindex.search(gtk_h, cindex.TypedefDecl)
    leafs = Tuple{Symbol,Expr}[]
    ifaces = Tuple{Symbol,Expr}[]
    boxes = Tuple{Symbol,Expr}[]
    gpointers = Tuple{Symbol,Expr}[]
    for tdecl in tdecls
        ty = cindex.getTypedefDeclUnderlyingType(tdecl)
        if isa(ty,cindex.Pointer)
            ty = cindex.getPointeeType(ty)
            isptr = true
        else
            isptr = false
        end
        sdecl = cindex.getTypeDeclaration(cindex.getCanonicalType(ty))
        isa(sdecl, cindex.StructDecl) || continue
        typname = cindex.spelling(tdecl)
        if endswith(typname,"Iface")||endswith(typname,"Class")||endswith(typname,"Private")
            continue
        end
        typname = Symbol(typname)
        header_file = cindex.cu_file(tdecl)
        libname = get(gtklibname,basename(splitdir(header_file)[1]),nothing)
        libname == nothing && continue
        if typname in keys(replacelist)
            symname = replacelist[typname]
            symname == :nothing && continue
        else
            symname = Symbol(join([lowercase(s) for s in split(string(typname), r"(?=[A-Z])")],"_"))
        end
        gtyp = g_type(typname, libname, symname)
        if gtyp == 0
            gtyp = g_type_from_name(typname)
            if gtyp != 0 && !(gtyp in Gtk.GLib.fundamental_ids)
                println("WARNING: couldn't guess symname for $typname -- skipping")
                continue
            end
        end
        if g_isa(gtyp, g_type_from_name(:GInterface))
            @assert !isptr
            push!(ifaces,(typname, :(@Giface $typname $libname $symname)))
        elseif gtyp == 0 || g_isa(gtyp, g_type_from_name(:GBoxed))
            unref_fn = Symbol(string(symname,:_free))
            has_ref_fn = false
            if get_fn_ptr(unref_fn, libname) == C_NULL
                unref_fn = Symbol(string(symname,:_unref))
                if get_fn_ptr(unref_fn, libname) == C_NULL
                    unref_fn = nothing
                    ref_fn = nothing
                else
                    has_ref_fn = true
                    ref_fn_sym = Symbol(string(symname,:_ref))
                    @assert get_fn_ptr(ref_fn_sym, libname) != C_NULL
                    ref_fn = :(ccall(($(QuoteNode(ref_fn_sym)),$libname),Nothing,(Ptr{Nothing},),ref))
                end
            else
                ref_fn = nothing
            end
            if length(cindex.children(sdecl)) == 0 || has_ref_fn || isptr
                # Opaque box
                if unref_fn === nothing
                    println("WARNING: couldn't detect gc characteristics of $symname")
                    continue
                end
                push!(gpointers, (typname, quote
                    mutable struct $typname <: GBoxed
                        handle::Ptr{$typname}
                        function $typname(ref::Ptr{$typname})
                            $ref_fn
                            x = new(ref)
                            $(if unref_fn !== nothing
                                :(finalizer(
                                    (x::$typname)->ccall(($(QuoteNode(unref_fn)),$libname),Nothing,
                                    (Ptr{Nothing},),x.handle), x)
                                )
                            else
                                nothing
                            end)
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
                    push!(paramlist.args, Expr(:(::), Symbol(name), jtyp))
                end
                if valid
                    push!(boxes,(typname, ex))
                else
                    println("WARNING: unable to generate box for $typname: $ex")
                end
            end
        elseif g_isa(gtyp, g_type(GObject))
            @assert !isptr
            push!(leafs,(typname, :(@Gtype $typname $libname $symname)))
        else
            if isptr; typname = "Ptr{$typname}" end
            println("WARNING: skipping $typname struct of unknown type")
        end
    end
    leafs,ifaces,boxes,gpointers
end
