#using Gtk, Test

window = GtkWindow("GtkTree", 300, 100)
boxtop = GtkBox(:v) # vertical box, basic structure

wscroll = GtkScrolledWindow()

function itemlist(types, rownames)

    @assert length(types) == length(rownames)

    list = GtkTreeStore(types...)
    tv = GtkTreeView(GtkTreeModel(list))
    cols = GtkTreeViewColumn[]

    for i=1:length(types)
        r1 = GtkCellRendererText()
        c1 = GtkTreeViewColumn(rownames[i], r1, Dict([("text",i-1)]))
        Gtk.G_.sort_column_id(c1,i-1)
        push!(cols,c1)
        #Gtk.G_.max_width(c1,Int(200/n))
        push!(tv,c1)
    end

    return (tv,list,cols)
end

tv, store, cols = itemlist([Int, String], ["No", "Name"])
treeModel = GtkTreeModel(store)

push!(wscroll, tv)
push!(boxtop, wscroll)
push!(window, boxtop)

wscroll.height_request[Int] = 300

showall(window);

##

push!(store, (1, "London"))
iter = push!(store, (2, "Grenoble"))

@test isvalid(store,iter)
@test Gtk.ncolumns(treeModel) == 2

path = Gtk.path(treeModel,iter)
@test depth(path) == 1
@test string(path) == "1"
@test prev(path)
@test string(path) == "0"

success, iter = Gtk.iter(treeModel,path)
@test success == true
@test store[iter] == (1, "London")

iter = Gtk.iter_from_string_index(store,"0")
@test isvalid(store,iter)
@test store[iter] == (1, "London")

iter = insert!(store, iter, (0,"Paris"); how = :sibling, where=:before)
@test store[iter] == (0,"Paris")

iter = insert!(store, iter, (3,"Paris child"); how = :parent, where=:after)
path = Gtk.path(treeModel,iter)
@test depth(path) == 2

##

selection = GAccessor.selection(tv)
@test hasselection(selection) == false

iter = Gtk.iter_from_string_index(store,"0")
select!(selection, iter)

@test length(selection) == 1

# this crashes
# iters = Gtk.selected_rows(selection)