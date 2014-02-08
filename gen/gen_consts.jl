using GI;

const_expr(name,val) =  :(const $(symbol(name)) = $(val))
        
function enum_decl(enumname,vals)
    body = Expr(:block)
    for (name,val) in vals
        if match(r"^[a-zA-Z_]",string(name)) === nothing
            name = "_$name"
        end
        name = uppercase(string(name))
        push!(body.args, const_expr(name,val) )
    end
    Expr(:toplevel,Expr(:module, false, symbol(enumname), body))
end

function strip_mask(vals)
    if all( [endswith(string(name),"_mask") for (name,val) in vals] )
        [ (string(name)[1:end-5],val) for (name,val) in vals]
    else
        vals
    end
end

function write_gtk_consts(fn)
    body = Expr(:block)
    toplevel = Expr(:toplevel,Expr(:module, true, :GConstants, body))
    exprs = body.args
    gtk = GINamespace(:Gtk)
    exports = Expr(:export)
    for (name,val) in GI.get_consts(gtk)
        if !beginswith(string(name),"STOCK_") 
            push!(exprs, const_expr("GTK_$name",val))
        end
    end
    for (name,vals,isflags) in GI.get_enums(gtk)
        name = symbol("Gtk$name")
        push!(exprs, enum_decl(name,vals))
        push!(exports.args, name)
    end
        
    gdk = GINamespace(:Gdk)
    #Key names could go into a Dict/submodule or something
    for (name,val) in GI.get_consts(gdk)
        if !beginswith(string(name),"KEY_") 
            push!(exprs, const_expr("GDK_$name",val))
        end
    end
    for (name,vals,isflags) in GI.get_enums(gdk)
        if isflags 
            vals = strip_mask(vals)
        end
        name = symbol("Gdk$name")
        push!(exprs, enum_decl(name,vals))
        push!(exports.args, name)
    end
    push!(exprs,exports)
    open(fn,"w") do f
        Base.println(f,"quote")
        Base.show_unquoted(f, toplevel)
        println(f)
        Base.println(f,"end")
    end
end

write_gtk_consts("consts")
