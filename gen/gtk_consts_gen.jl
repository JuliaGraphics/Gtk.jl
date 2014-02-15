#function common_prefix(a::String, b::String)
#    i = start(a)
#    j = start(b)
#    while !(done(a,i) || done(b,j))
#        last = i
#        ci, i = next(a,i)
#        cj, j = next(b,j)
#        if ci != cj
#            return last
#        end
#    end
#    i
#end
function common_prefix(a::String, b::String)
    findfirst(split(a,'_') .== split(b,'_'), false)
end


function gen_consts(body, gtk_h)
    count = 0
    exports = Expr(:export)
    push!(body.args,exports)

    tdecls = cindex.search(gtk_h, cindex.TypedefDecl)
    for tdecl in tdecls
        ctype = cindex.getCanonicalType(cindex.getCursorType(tdecl))
        if !isa(ctype,cindex.Enum)
            continue
        end
        name = cindex.spelling(tdecl)
        m = match(r"^(G\w+)$", name)
        if m === nothing
            continue
        end
        name = symbol(m.captures[1])
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
            #push!(consts.args, Expr(:const, Expr(:(=), symbol(shortdecl), cindex.value(child))))
            push!(consts.args, Expr(:const, Expr(:(=), symbol(shortdecl), Expr(:const, Expr(:(=), symbol(decl), cindex.value(child))))))
        end
        if name == :ModifierType
            push!(consts.args, Expr(:const, Expr(:(=), :BUTTONS, Expr(:const, Expr(:(=), :GDK_BUTTONS, 256+512+1024+2048+4096)))))
        end
        count += 1
    end
    count
end
