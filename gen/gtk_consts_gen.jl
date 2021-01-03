const PLATFORM_SPECIFIC = Dict{String, Any}(
    "G_DIR_SEPARATOR"           => :(Base.Filesystem.path_separator[1]),
    "G_DIR_SEPARATOR_S"         => :(Base.Filesystem.path_separator),
    "G_SEARCHPATH_SEPARATOR"    => :(Sys.iswindows() ? ';' : ':'),
    "G_SEARCHPATH_SEPARATOR_S"  => :(Sys.iswindows() ? ";" :  ":"),
    "G_MODULE_SUFFIX"           => :(Sys.iswindows() ? "dll" : "so"), #For "most" Unices and Linux this is "so".
    "G_PID_FORMAT"              => :(Sys.iswindows() ? "p" : "i"), #Incorrectly stated as only "i" in Glib reference.
)

function gen_consts(body, gtk_h)
    count = 0
    exports = Expr(:export)
    push!(body.args,exports)
    
    tdecls = Clang.search(gtk_h, Clang.CXCursor_TypedefDecl)
    for tdecl in tdecls
        ctype = canonical(type(tdecl))
        if isa(ctype, CLEnum)
            name = spelling(tdecl)
            m = match(r"^(G\w+)$", name)
            if m === nothing
                continue
            end
            name = Symbol(name)
            push!(exports.args, name)
            consts = Expr(:block)
            push!(body.args, Expr(:toplevel, Expr(:module, false, name, consts)))
            children = Clang.children(typedecl(ctype))
            mask = true
            c1 = spelling(children[1])
            splitc1 = split(c1,'_')
            prefix = length(splitc1)
            for child in children
                c2 = spelling(child)
                if !endswith(c2,"_MASK")
                    mask = false
                end
                if c1 != c2
                    for (i,pre) in enumerate(split(c2,'_';limit=prefix))
                        if i == prefix
                            break
                        end
                        if pre != splitc1[i]
                            prefix = i
                            break
                        end
                    end
                end
            end
            @assert prefix > 0
            lprefix = 1
            for i = 1:(prefix-1)
                lprefix += length(splitc1[i])+1
            end
            for child in children
                decl = spelling(child)
                if mask
                    shortdecl = decl[lprefix:end-5]
                else
                    shortdecl = decl[lprefix:end]
                end
                jldecl = Expr(:const, Expr(:(=), Symbol(decl), Expr(:call, :(Main.Base.convert), :(Main.Base.Int32), value(child))))
                if occursin(r"^[A-Za-z]", shortdecl)
                    push!(consts.args, Expr(:const, Expr(:(=), Symbol(shortdecl), jldecl)))
                else
                    push!(consts.args, jldecl)
                end
            end
            if name == :GdkModifierType
                push!(consts.args, Expr(:const, Expr(:(=), :BUTTONS, Expr(:const, Expr(:(=), :GDK_BUTTONS, 256+512+1024+2048+4096)))))
            end
            count += 1
        end
    end
    
    mdecls = Clang.search(gtk_h, Clang.CXCursor_MacroDefinition)
    for mdecl in mdecls
        name = spelling(mdecl)
        if occursin(r"^G\w*[A-Za-z]$", name)
            if haskey(PLATFORM_SPECIFIC, name)
                push!(body.args, Expr(:const, Expr(:(=), Symbol(name), PLATFORM_SPECIFIC[name])))
                continue
            end
            tokens = tokenize(mdecl)
            if length(tokens) == 2 && isa(tokens[2], Literal)
                tok2 = Clang.handle_macro_exprn(tokens, 2)[1]
                tok2 = replace(tok2, "\$"=>"\\\$")
                push!(body.args, Expr(:const, Expr(:(=), Symbol(name), Meta.parse(tok2))))
            else
                #println("Skipping: ", name, " = ", [tokens...])
            end
        end
    end
    count
end
