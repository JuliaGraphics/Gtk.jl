using GI;
function write_exprs(fn, exprs)
    open(fn,"w") do f
        println(f,"quote")
        for ex in exprs
            Base.show_unquoted(f,ex)
            Base.print(f,"\n")
        end
        println(f,"end")
    end
end
        
#Example: Gtk/Gdk consts
function write_gtk_consts(fn)
    exprs = Expr[]
    gtk = GINamespace(:Gtk)
    append!(exprs, GI.const_decls(gtk, x-> beginswith(string(x),"STOCK_") ? nothing : "GTK_$x"))
    append!(exprs, GI.enum_decls(gtk, x-> "Gtk$x"))
    gtk = GINamespace(:Gdk)
    #Key names could go into a Dict/submodule or something
    append!(exprs, GI.const_decls(gtk, x-> beginswith(string(x),"KEY_") ? nothing : "GDK_$x"))
    append!(exprs, GI.enum_decls(gtk, x-> "Gdk$x"))
    write_exprs(fn,exprs)
end

write_gtk_consts("consts")
