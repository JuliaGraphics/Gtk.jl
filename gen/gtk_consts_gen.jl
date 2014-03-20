function gen_consts(body, gtk_h)
    count = 0
    exports = Expr(:export)
    push!(body.args,exports)

    tdecls = cindex.search(gtk_h, cindex.TypedefDecl)
    for tdecl in tdecls
        ctype = cindex.getCanonicalType(cindex.getCursorType(tdecl))
        if isa(ctype,cindex.Enum)
            name = cindex.spelling(tdecl)
            m = match(r"^(G\w+)$", name)
            if m === nothing
                continue
            end
            name = symbol(name)
            push!(exports.args, name)
            consts = Expr(:block)
            push!(body.args, Expr(:toplevel, Expr(:module, false, name, consts)))
            children = cindex.children(cindex.getTypeDeclaration(ctype))
            mask = true
            c1 = cindex.spelling(children[1])
            splitc1 = split(c1,'_')
            prefix = length(splitc1)
            for child in children
                c2 = cindex.spelling(child)
                if !endswith(c2,"_MASK")
                    mask = false
                end
                if c1 != c2
                    for (i,pre) in enumerate(split(c2,'_',prefix))
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
                decl = cindex.spelling(child)
                if mask
                    shortdecl = decl[lprefix:end-5]
                else
                    shortdecl = decl[lprefix:end]
                end
                if ismatch(r"^[A-Za-z]", shortdecl)
                    push!(consts.args, Expr(:const, Expr(:(=), symbol(shortdecl), Expr(:const, Expr(:(=), symbol(decl), cindex.value(child))))))
                else
                    push!(consts.args, Expr(:const, Expr(:(=), symbol(decl), cindex.value(child))))
                end
            end
            if name == :GdkModifierType
                push!(consts.args, Expr(:const, Expr(:(=), :BUTTONS, Expr(:const, Expr(:(=), :GDK_BUTTONS, 256+512+1024+2048+4096)))))
            end
            count += 1
        end
    end
    mdecls = cindex.search(gtk_h, cindex.MacroDefinition)
    for mdecl in mdecls
        name = cindex.spelling(mdecl)
        if ismatch(r"^G\w*[A-Za-z]$", name)
            tokens = cindex.tokenize(mdecl)
            if length(tokens) == 2 && isa(tokens[2], cindex.Literal)
                tok2 = Clang.wrap_c.lex_exprn(tokens, 2)[1]
                tok2 = replace(tok2, "\$", "\\\$")
                push!(body.args, Expr(:const, Expr(:(=), symbol(name), parse(tok2))))
            else
                #println("Skipping: ", name, " = ", [tokens...])
            end
        end
    end
    count
end
