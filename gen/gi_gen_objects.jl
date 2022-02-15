using GI

## GLib, including GObject and Gio

toplevel, exprs, exports = GI.output_exprs()

bloc = Expr(:block)

gobj = GINamespace(:GObject,"2.0")
gio = GINamespace(:Gio,"2.0")
for o in [:Binding]
    m=GI.obj_macro(gobj[o])
    push!(exprs,m)
    push!(exports.args, GI.get_full_name(gobj[o]))
end
for i in GI.get_all(gobj,GI.GIInterfaceInfo)
    m=GI.interface_macro(i)
    push!(exprs,m)
    push!(exports.args, GI.get_full_name(i))
end
for o in [:Application,:Cancellable,:Menu,:MenuModel,:Notification,:Permission,:PropertyAction,:SimpleAction,:SimpleActionGroup]
    m=GI.obj_macro(gio[o])
    push!(exprs,m)
    push!(exports.args, GI.get_full_name(gio[o]))
end
for i in [:ActionGroup,:AsyncResult,:File,:Icon]
    m=GI.interface_macro(gio[i])
    push!(exprs,m)
    push!(exports.args, GI.get_full_name(gio[i]))
end

push!(exprs,exports)

GI.write_to_file(".","glib_structs",toplevel)

## Gtk3 (and Pango, GdkPixbuf, Gdk3)

toplevel, exprs, exports = GI.output_exprs()

GI.struct_cache_expr!(exprs)

pango = GINamespace(:Pango, "1.0")

for o in GI.get_all(pango,GI.GIObjectInfo)
    m=GI.obj_macro(o)
    push!(exprs,m)
    push!(exports.args, GI.get_full_name(o))
end

for n in [:AttrList,:FontDescription,:TabArray]
    push!(exprs,GI.struct_decl(pango[n],force_opaque=true))
end

gdkpb = GINamespace(:GdkPixbuf, "2.0")

for o in GI.get_all(gdkpb,GI.GIObjectInfo)
    m=GI.obj_macro(o)
    push!(exprs,m)
    push!(exports.args, GI.get_full_name(o))
end

gdk3 = GINamespace(:Gdk, "3.0")

for o in [:Device,:Display,:FrameClock,:Monitor,:Screen, :Visual, :Window]
    m=GI.obj_macro(gdk3[o])
    push!(exprs,m)
    push!(exports.args, GI.get_full_name(gdk3[o]))
end

gtk3 = GINamespace(:Gtk, "3.0")

for o in GI.get_all(gtk3,GI.GIObjectInfo)
    if GI.get_name(o)===:Plug || GI.get_name(o)===:Socket
        continue
    end
    m=GI.obj_macro(o)
    push!(exprs,m)
    push!(exports.args, GI.get_full_name(o))
end

for i in GI.get_all(gtk3,GI.GIInterfaceInfo)
    m=GI.interface_macro(i)
    push!(exprs,m)
    push!(exports.args, GI.get_full_name(i))
end

disguised = [:RcContext,:TextBTree,:ThemeEngine]
special = []
struct_skiplist=vcat(disguised, special, [:AccelGroupEntry,:BindingEntry,:BindingSet,:BindingSignal,:CellAreaClass,:PageRange,:TargetPair,:TextAppearance,:_MountOperationHandler,:_MountOperationHandlerIface,:_MountOperationHandlerProxy,:_MountOperationHandlerSkeleton,:_MountOperationHandlerSkeletonClass,:_MountOperationHandlerProxyClass])

struct_skiplist = GI.all_struct_exprs!(exprs,exports,gtk3;excludelist=struct_skiplist,import_as_opaque=[:TextAttributes],only_opaque=true)
#push!(exprs,exports)

GI.write_to_file(".","gtk3_structs",toplevel)
