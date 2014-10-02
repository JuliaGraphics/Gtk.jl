#https://developer.gnome.org/gtk2/stable/TreeWidgetObjects.html

#Tree and List Widget Overview — Overview of GtkTreeModel, GtkTreeView, and friends
#GtkTreeModel — The tree interface used by GtkTreeView
#GtkTreeSelection — The selection object for GtkTreeView
#GtkTreeViewColumn — A visible column in a GtkTreeView widget
#GtkTreeView — A widget for displaying both trees and lists
#GtkTreeView drag-and-drop — Interfaces for drag-and-drop support in GtkTreeView
#GtkCellView — A widget displaying a single row of a GtkTreeModel
#GtkIconView — A widget which displays a list of icons in a grid
#GtkTreeSortable — The interface for sortable models used by GtkTreeView
#GtkTreeModelSort — A GtkTreeModel which makes an underlying tree model sortable
#GtkTreeModelFilter — A GtkTreeModel which hides parts of an underlying tree model
#GtkCellLayout — An interface for packing cells
#GtkCellRenderer — An object for rendering a single cell on a GdkDrawable
#GtkCellEditable — Interface for widgets which can are used for editing cells
#GtkCellRendererAccel — Renders a keyboard accelerator in a cell
#GtkCellRendererCombo — Renders a combobox in a cell
#GtkCellRendererPixbuf — Renders a pixbuf in a cell
#GtkCellRendererProgress — Renders numbers as progress bars
#GtkCellRendererSpin — Renders a spin button in a cell
#GtkCellRendererText — Renders text in a cell
#GtkCellRendererToggle — Renders a toggle button in a cell
#GtkCellRendererSpinner — Renders a spinning animation in a cell
#GtkListStore — A list-like data structure that can be used with the GtkTreeView
#GtkTreeStore — A tree-like data structure that can be used with the GtkTreeView

#GtkComboBox — A widget used to choose from a list of items
#GtkComboBoxText — A simple, text-only combo box

GtkComboBoxTextLeaf(with_entry::Bool=false) = GtkComboBoxTextLeaf(
        if with_entry
            ccall((:gtk_combo_box_text_new_with_entry,libgtk),Ptr{GObject},())
        else
            ccall((:gtk_combo_box_text_new,libgtk),Ptr{GObject},())
        end)
push!(cb::GtkComboBoxText,text::String) =
    (ccall((:gtk_combo_box_text_append_text,libgtk),Void,(Ptr{GObject},Ptr{Uint8}),cb,bytestring(text)); cb)
unshift!(cb::GtkComboBoxText,text::String) =
    (ccall((:gtk_combo_box_text_prepend_text,libgtk),Void,(Ptr{GObject},Ptr{Uint8}),cb,bytestring(text)); cb)
insert!(cb::GtkComboBoxText,i::Integer,text::String) =
    (ccall((:gtk_combo_box_text_insert_text,libgtk),Void,(Ptr{GObject},Cint,Ptr{Uint8}),cb,i-1,bytestring(text)); cb)

if gtk_version == 3
    push!(cb::GtkComboBoxText,id::(String,Symbol),text::String) =
        (ccall((:gtk_combo_box_text_append,libgtk),Void,(Ptr{GObject},Ptr{Uint8},Ptr{Uint8}),cb,id,bytestring(text)); cb)
    unshift!(cb::GtkComboBoxText,id::(String,Symbol),text::String) =
        (ccall((:gtk_combo_box_text_prepend,libgtk),Void,(Ptr{GObject},Ptr{Uint8},Ptr{Uint8}),cb,id,bytestring(text)); cb)
    insert!(cb::GtkComboBoxText,i::Integer,id::(String,Symbol),text::String) =
        (ccall((:gtk_combo_box_text_insert_text,libgtk),Void,(Ptr{GObject},Cint,Ptr{Uint8}),cb,i-1,id,bytestring(text)); cb)
end

delete!(cb::GtkComboBoxText,i::Integer) =
    (ccall((:gtk_combo_box_text_remove,libgtk),Void,(Ptr{GObject},Cint),cb,i-1); cb)

immutable GtkTreeIter
    stamp::Cint
    user_data::Ptr{Void}
    user_data2::Ptr{Void}
    user_data3::Ptr{Void}
    GtkTreeIter() = new(0,C_NULL,C_NULL,C_NULL)
end

typealias TRI Union(Mutable{GtkTreeIter},GtkTreeIter)
zero(::Type{GtkTreeIter}) = GtkTreeIter()
copy(ti::GtkTreeIter) = ti
copy(ti::Mutable{GtkTreeIter}) = mutable(ti[])
show(io::IO, iter::GtkTreeIter) = print("GtkTreeIter(...)")

### GtkTreePath

# for debugging purpose
# immutable _GtkTreePath
#    depth::Cint
#    alloc::Cint
#    indices::Ptr{Cint}
# end

type GtkTreePath <: GBoxed
    handle::Ptr{GtkTreePath}
    function GtkTreePath(pathIn::Ptr{GtkTreePath},own::Bool=false)
        x = new( own ? pathIn :
            ccall((:gtk_tree_path_copy,Gtk.libgtk),Void,(Ptr{GtkTreePath},),pathIn))
        finalizer(path, x::GtkTreePath->begin
                ccall((:gtk_tree_path_free,libgtk),Void,(Ptr{GtkTreePath},),x.handle)
            end)
        path
    end
end
GtkTreePath() = GtkTreePath(ccall((:gtk_tree_path_new,libgtk),Ptr{GtkTreePath},()),true)
copy(path::GtkTreePath) = GtkTreePath(path.handle)

next(path::GtkTreePath) = ccall((:gtk_tree_path_next,libgtk), Void, (Ptr{GtkTreePath},),path)
prev(path::GtkTreePath) = bool( ccall((:gtk_tree_path_prev,libgtk),Cint, (Ptr{GtkTreePath},),path))
up(path::GtkTreePath) = bool( ccall((:gtk_tree_path_up,libgtk),Cint, (Ptr{GtkTreePath},),path))
down(path::GtkTreePath) = ccall((:gtk_tree_path_down,libgtk), Void, (Ptr{GtkTreePath},),path)
string(path::GtkTreePath) = bytestring( ccall((:gtk_tree_path_to_string,libgtk),Ptr{Uint8},
                                            (Ptr{GtkTreePath},),path))

### add indices for a store 1-based

## Get an iter corresponding to an index specified as a string
function iter_from_string_index(store, index::String)
    iter = Gtk.mutable(GtkTreeIter)
    Gtk.G_.iter_from_string(GtkTreeModel(store), iter, index)
    if !isvalid(store, iter)
        error("invalid index: $index")
    end
     iter[]
end

### GtkListStore

function GtkListStoreLeaf(types::Type...)
    gtypes = GLib.gtypes(types...)
    handle = ccall((:gtk_list_store_newv,libgtk),Ptr{GObject},(Cint,Ptr{GLib.GType}), length(types), gtypes)
    GtkListStoreLeaf(handle)
end

## index is integer for a liststore, vector of ints for tree
iter_from_index(store::GtkListStore, index::Int) = iter_from_string_index(store, string(index-1))
index_from_iter(store::GtkListStore, iter::TRI) = int(get_string_from_iter(store, iter)) + 1

function list_store_set_values(store::GtkListStore, iter, values)
    for (i,value) in enumerate(values)
        ccall((:gtk_list_store_set_value,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Cint,Ptr{Gtk.GValue}),
              store,iter,i-1, Gtk.gvalue(value))
    end
end

function push!(listStore::GtkListStore, values::Tuple)
    iter = mutable(GtkTreeIter)
    ccall((:gtk_list_store_append,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter}), listStore, iter)

    list_store_set_values(listStore, iter, values)
    iter[]
end

function unshift!(listStore::GtkListStore, values::Tuple)
    iter = mutable(GtkTreeIter)
    ccall((:gtk_list_store_prepend,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter}), listStore, iter)
    list_store_set_values(listStore, iter, values)
    iter[]
end

## insert before
function Base.insert!(listStore::GtkListStoreLeaf, iter::TRI, values)
    newiter = Gtk.mutable(GtkTreeIter)
    ccall((:gtk_list_store_insert_before,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}), listStore, newiter, mutable(iter))
    list_store_set_values(listStore, newiter, values)
    newiter[]
end


function delete!(listStore::GtkListStore, iter::TRI)
    # not sure what to do with the return value here
    deleted = ccall((:gtk_list_store_remove,libgtk),Cint,(Ptr{GObject},Ptr{GtkTreeIter}), listStore, mutable(iter))
    listStore
end

Base.deleteat!(listStore::GtkListStore, iter::TRI) = delete!(listStore, iter)


empty!(listStore::GtkListStore) =
    ccall((:gtk_list_store_clear,libgtk), Void, (Ptr{GObject},),listStore)

## by index

## insert into a list store after index
function Base.insert!(listStore::GtkListStoreLeaf, index::Int, values)
    index > length(listStore) && return(push!(listStore, values))

    iter = iter_from_index(listStore, index)
    insert!(listStore, iter, values)
end

Base.deleteat!(listStore::GtkListStoreLeaf, index::Int) = delete!(listStore, iter_from_index(listStore, index))
Base.pop!(listStore::GtkListStoreLeaf) = deleteat!(listStore, length(listStore))
Base.shift!(listSTore::GtkListStoreLeaf) = deleteat!(listStore, 1)




isvalid(listStore::GtkListStore, iter::TRI) =
    bool( ccall((:gtk_list_store_iter_is_valid,libgtk), Cint,
	     (Ptr{GObject},Ptr{GtkTreeIter}),listStore, mutable(iter)))

length(listStore::GtkListStore) =
    ccall((:gtk_tree_model_iter_n_children,libgtk), Cint, (Ptr{GObject},Ptr{GtkTreeIter}),listStore, C_NULL)

size(listStore::GtkListStore) = (length(listStore), ncolumns(GtkTreeModel(listStore)))


Base.getindex(store::GtkListStore, row::Int, column) = getindex(store, iter_from_index(store, row), column)
Base.getindex(store::GtkListStore, row::Int) = getindex(store, iter_from_index(store, row))


function Base.setindex!(store::GtkListStore, value, index::Int, column::Integer)
	 setindex!(store, value, Gtk.iter_from_index(store, index), column)
end

### GtkTreeStore

function GtkTreeStoreLeaf(types::Type...)
    gtypes = GLib.gtypes(types...)
    handle = ccall((:gtk_tree_store_newv,libgtk),Ptr{GObject},(Cint,Ptr{GLib.GType}), length(types), gtypes)
    GtkTreeStoreLeaf(handle)
end

iter_from_index(store::GtkTreeStoreLeaf, index::Vector{Int}) = iter_from_string_index(store, join(index.-1, ":"))

function tree_store_set_values(treeStore::GtkTreeStoreLeaf, iter, values)
    for (i,value) in enumerate(values)
        ccall((:gtk_tree_store_set_value,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Cint,Ptr{Gtk.GValue}),
              treeStore,iter,i-1,gvalue(value))
    end
    iter[]
end


function push!(treeStore::GtkTreeStore, values::Tuple, parent=nothing)
    iter = mutable(GtkTreeIter)
    if parent == nothing
        ccall((:gtk_tree_store_append,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void}), treeStore, iter, C_NULL)
    else
        ccall((:gtk_tree_store_append,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}), treeStore, iter, &parent)
    end

    tree_store_set_values(treeStore, iter, values)
    iter[]
end

function unshift!(treeStore::GtkTreeStore, values::Tuple, parent=nothing)
    iter = mutable(GtkTreeIter)
    if parent == nothing
        ccall((:gtk_tree_store_prepend,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void}), treeStore, iter, C_NULL)
    else
        ccall((:gtk_tree_store_prepend,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}), treeStore, iter, &parent)
    end

    tree_store_set_values(treeStore, iter, values)
    iter[]
end

## index can be :parent or :sibling
## insertion can be :after or :before
function Base.insert!(treeStore::GtkTreeStoreLeaf, piter::TRI, values; how::Symbol=:parent, where::Symbol=:after)

    iter =  Gtk.mutable(GtkTreeIter)
    if how == :parent
        if where == :after
            ccall((:gtk_tree_store_insert_after,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void},Ptr{GtkTreeIter}), treeStore, iter, piter, C_NULL)
        else
            ccall((:gtk_tree_store_insert_before,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void},Ptr{GtkTreeIter}), treeStore, iter, piter, C_NULL)
        end
    else
        if where == :after
            ccall((:gtk_tree_store_insert_after,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void},Ptr{GtkTreeIter}), treeStore, iter, C_NULL, piter)
        else
            ccall((:gtk_tree_store_insert_before,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void},Ptr{GtkTreeIter}), treeStore, iter, C_NULL, piter)
        end
    end

    tree_store_set_values(treeStore, iter, values)
end


function delete!(treeStore::GtkTreeStore, iter::TRI)
    # not sure what to do with the return value here
    deleted = ccall((:gtk_tree_store_remove,libgtk),Cint,(Ptr{GObject},Ptr{GtkTreeIter}), treeStore, mutable(iter))
    treeStore
end

Base.deleteat!(treeStore::GtkTreeStore, iter::TRI) = delete!(treeStore, iter)

## insert by index
function Base.insert!(treeStore::GtkTreeStoreLeaf, index::Vector{Int}, values; how::Symbol=:parent, where::Symbol=:after)
    piter = iter_from_index(treeStore, index)
    insert!(treeStore, iter, values; how=how, where=where)
end


function Base.splice!(treeStore::GtkTreeStoreLeaf, index::Vector{Int})
    iter = iter_from_index(treeStore, index)
    delete!(treeStore, iter)
end

empty!(treeStore::GtkTreeStore) =
    ccall((:gtk_tree_store_clear,libgtk), Void, (Ptr{GObject},),treeStore)

isvalid(treeStore::GtkTreeStore, iter::TRI) =
    bool( ccall((:gtk_tree_store_iter_is_valid,libgtk), Cint,
	     (Ptr{GObject},Ptr{GtkTreeIter}),treeStore, mutable(iter)))

isancestor(treeStore::GtkTreeStore, iter::TRI, descendant::TRI) =
    bool( ccall((:gtk_tree_store_is_ancestor,libgtk), Cint,
          (Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}),
          treeStore, mutable(iter), mutable(descendant)))

depth(treeStore::GtkTreeStore, iter::TRI) =
    ccall((:gtk_tree_store_iter_depth,libgtk), Cint, (Ptr{GObject},Ptr{GtkTreeIter}),treeStore, mutable(iter))

## get index store[iter], store[iter, column], store[index], store[index,column]
Base.getindex(store::Union(GtkTreeStore,GtkListStore), iter::TRI, column::Integer) = getindex(GtkTreeModel(store), iter, column)
Base.getindex(store::Union(GtkTreeStore, GtkListStore), iter::TRI) = getindex(GtkTreeModel(store), iter)

Base.getindex(store::GtkTreeStore, row::Vector{Int}, column) = getindex(store, iter_from_index(store, row), column)
Base.getindex(store::GtkTreeStore, row::Vector{Int}) = getindex(store, iter_from_index(store, row))


function Base.setindex!(store::Union(GtkListStore, GtkTreeStore), value, iter::TRI, column::Integer)
    Gtk.G_.value(store, Gtk.mutable(iter), column-1, gvalue(value))
end

function Base.setindex!(store::GtkTreeStore, value, index::Vector{Int}, column::Integer)
	 setindex!(store, value, Gtk.iter_from_index(store, index), column)
end



### GtkTreeModelFilter

GtkTreeModelFilterLeaf(child_model::GObject) = GtkTreeModelFilterLeaf(
    ccall((:gtk_tree_model_filter_new,libgtk),Ptr{GObject},(Ptr{GObject},Ptr{Void}), child_model, C_NULL))

function convert_iter_to_child_iter(model::GtkTreeModelFilter, filter_iter::TRI)
    child_iter = mutable(GtkTreeIter)
    ccall((:gtk_tree_model_filter_convert_iter_to_child_iter,libgtk),Void,
          (Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}),
          model, child_iter, mutable(filter_iter))
    child_iter[]
end

function convert_child_iter_to_iter(model::GtkTreeModelFilter, child_iter::TRI)
    filter_iter = mutable(GtkTreeIter)
    ccall((:gtk_tree_model_filter_convert_child_iter_to_iter,libgtk),Void,
          (Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}),
          model,  &filter_iter, mutable(child_iter))
    filter_iter[]
end

### GtkTreeModel

function getindex(treeModel::GtkTreeModel, iter::TRI, column::Integer)
    val = mutable(GValue())
    ccall((:gtk_tree_model_get_value,libgtk), Void, (Ptr{GObject},Ptr{GtkTreeIter},Cint,Ptr{GValue}),
           treeModel, mutable(iter), column-1, val)
    val[Any]
end

function getindex(treeModel::GtkTreeModel, iter::TRI)
    ntuple( ncolumns(treeModel), i -> treeModel[iter,i] )
end

function setindex!(treeModel::GtkTreeModel, value, iter::TRI, column::Integer)
    G_.value(treeModel,mutable(iter),column-1,gvalue(value))
end

function setindex!(treeModel::GtkTreeModel, values, iter::TRI)
    for (i,v) in enumerate(values)
        G_.value(treeModel,mutable(iter),i-1,gvalue(v))
    end
end

ncolumns(treeModel::GtkTreeModel) =
    ccall((:gtk_tree_model_get_n_columns,libgtk), Cint, (Ptr{GObject},),treeModel)

## add in gtk_tree_model iter functions to traverse tree
## where a gtk function passes an iter and returns a boolean, we pass back (Bool, iter)

## First iter [1]
function get_iter_first(treeModel::GtkTreeModel)
    iter = mutable(GtkTreeIter)
    ret = ccall((:gtk_tree_model_get_iter_first, libgtk), Bool,
          (Ptr{GObject},Ptr{GtkTreeIter}), 
          treeModel, iter)
    ret, iter[]
end

## return (Bool, iter)
function get_iter_next(treeModel::GtkTreeModel, iter::TRI)
    iter = mutable(copy(iter))
    ret = ccall((:gtk_tree_model_iter_next, libgtk), Bool,
                (Ptr{GObject}, Ptr{GtkTreeIter}), 
                treeModel, iter)
    ret, iter[]
end
next(treeModel::GtkTreeModel, iter::TRI) = get_iter_next(treeModel, iter)

## return iter pointing to previous. Invalidates previous
## return (Bool, GtkTreeIter)
function get_iter_previous(treeModel::GtkTreeModel, iter::TRI)
    iter = mutable(copy(iter))
    ret = ccall((:gtk_tree_model_iter_previous, libgtk), Bool,
          (Ptr{GObject}, Ptr{GtkTreeIter}), 
          treeModel, iter)
    ret, iter[]
end
prev(treeModel::GtkTreeModel, iter::TRI) = get_iter_previous(treeModel, iter)

## return iter pointing to first child of parent iter
## return (Bool, GtkTreeIter)
function iter_children(treeModel::GtkTreeModel, piter::TRI)
    iter = mutable(GtkTreeIter)
    ret = ccall((:gtk_tree_model_iter_children, libgtk), Bool,
                (Ptr{GObject}, Ptr{GtkTreeIter}, Ptr{GtkTreeIter}), 
                treeModel, iter, mutable(piter))
    ret, iter[]
end


## return boolean, checks if there is a child
function iter_has_child(treeModel::GtkTreeModel, iter::TRI)
    ret = ccall((:gtk_tree_model_iter_has_child, libgtk), Bool,
          (Ptr{GObject},  Ptr{GtkTreeIter}), 
          treeModel, mutable(iter))
    ret
end

## return number of children for iter
function iter_n_children(treeModel::GtkTreeModel, iter::TRI)
    ret = ccall((:gtk_tree_model_iter_n_children, libgtk), Cint,
          (Ptr{GObject},  Ptr{GtkTreeIter}), 
          treeModel, mutable(iter))
    ret
end
length(treeModel::GtkTreeModel, iter::TRI) = iter_n_children(treeModel, iter)

## return (Bool, iter pointing to nth child n in 1:nchildren)
function iter_nth_child(treeModel::GtkTreeModel, piter::TRI, n::Int)
    iter = mutable(GtkTreeIter)
    ret = ccall((:gtk_tree_model_iter_nth_child, libgtk), Bool,
          (Ptr{GObject}, Ptr{GtkTreeIter}, Ptr{GtkTreeIter}, Cint), 
          treeModel, iter, mutable(piter), n - 1) # 0-based
    ret, iter[]
end

## return (Bool, GtkTreeIter)
function iter_parent(treeModel::GtkTreeModel, citer::TRI)
    iter = mutable(GtkTreeIter)
    ret = ccall((:gtk_tree_model_iter_parent, libgtk), Bool,
                (Ptr{GObject}, Ptr{GtkTreeIter}, Ptr{GtkTreeIter}), 
                treeModel, iter, mutable(citer))
    ret, iter[]
end
parent(treeModel::GtkTreeModel, iter::TRI) = iter_parent(treeModel, iter)

## string is of type "0:1:0" (0-based)
function get_string_from_iter(treeModel::GtkTreeModel, iter::TRI)
    val = ccall((:gtk_tree_model_get_string_from_iter, libgtk),  Ptr{Uint8},
          (Ptr{GObject},Ptr{GtkTreeIter}), 
          treeModel, mutable(iter))
    val = bytestring(val)
end
string(treeModel::GtkTreeModel, iter::TRI) = get_string_from_iter(treeModel, iter)

## index is Int[] 1-based
index_from_iter(treeModel::GtkTreeModel, iter::TRI) = map(int, split(get_string_from_iter(treeModel, iter), ":")) + 1

## An iterator to walk a tree, e.g.,
## for iter in walktree(store)
##   println(store[iter, 1])
## end 
type TreeIterator
    store::GtkTreeStore
    model::GtkTreeModel
    iter
    next
end

function walktree(store::GtkTreeStore, iter=nothing; method::Symbol=:depth_first)
    model = GtkTreeModel(store)

    if iter === Nothing
        return TreeIterator(store, model, nothing, nothing)
    end

    Gtk.iter_has_child(model, iter) !! error("Iter must be a parent")
    TreeIterator(store, model, iter, nothing)
end
  
## iterator interface
function Base.start(x::TreeIterator)
    x.iter
end

function Base.done(x::TreeIterator, state)
    if isa(state, Nothing)
        ret, x.next = Gtk.get_iter_first(x.model)
        return(false) # special case root
    end

    ## we are not done if:
    ## * state has child, 
    ret, nstate = Gtk.iter_children(x.model, state)
    if ret
        x.next = nstate
        return(false)
    end

    ## has a sibling
    ret, nstate = next(x.model, state)
    if ret
        x.next = nstate
        return(false)
    end

    ## walking back we have a sibling
    function can_walk_back(iter)
        ret, piter = parent(x.model, iter)
        !ret && return((false, piter))
        isa(x.iter, Nothing) && return((true, piter))
        if isancestor(x.store, x.iter, piter)
            return((true, piter))
        else
            return((false, piter))
        end
    end
        
    ret, pstate = can_walk_back(state)
    while ret
        has_sibling, siter = next(x.model, pstate)
        if has_sibling
            x.next = siter
            return(false)
        end
        ret, pstate = can_walk_back(pstate)
    end
    return(true)
end

function Base.next(x::TreeIterator, state)
    return(x.next, x.next)
end



#TODO: Replace by accessor
function iter(treeModel::GtkTreeModel, path::GtkTreePath)
  it = mutable(GtkTreeIter)
  ret = bool( ccall((:gtk_tree_model_get_iter,libgtk), Cint, (Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreePath}),
                    treeModel,it,path))
  ret, it[]
end

#TODO: Replace by accessor (accessor is wrong)
function path(treeModel::GtkTreeModel, iter::TRI)
  GtkTreePath( ccall((:gtk_tree_model_get_path,libgtk), Ptr{GtkTreePath},
                            (Ptr{GObject},Ptr{GtkTreeIter}),
                            treeModel,mutable(iter)))
end

depth(path::GtkTreePath) = ccall((:gtk_tree_path_get_depth,libgtk), Cint,
    (Ptr{GtkTreePath},),path)

### GtkTreeSortable

### GtkCellRenderer

GtkCellRendererAccelLeaf() = GtkCellRendererAccelLeaf(
    ccall((:gtk_cell_renderer_accel_new,libgtk),Ptr{GObject},()))

GtkCellRendererComboLeaf() = GtkCellRendererComboLeaf(
    ccall((:gtk_cell_renderer_combo_new,libgtk),Ptr{GObject},()))

GtkCellRendererPixbufLeaf() = GtkCellRendererPixbufLeaf(
    ccall((:gtk_cell_renderer_pixbuf_new,libgtk),Ptr{GObject},()))

GtkCellRendererProgressLeaf() = GtkCellRendererProgressLeaf(
    ccall((:gtk_cell_renderer_progress_new,libgtk),Ptr{GObject},()))

GtkCellRendererSpinLeaf() = GtkCellRendererSpinLeaf(
    ccall((:gtk_cell_renderer_spin_new,libgtk),Ptr{GObject},()))

GtkCellRendererTextLeaf() = GtkCellRendererTextLeaf(
    ccall((:gtk_cell_renderer_text_new,libgtk),Ptr{GObject},()))

GtkCellRendererToggleLeaf() = GtkCellRendererToggleLeaf(
    ccall((:gtk_cell_renderer_toggle_new,libgtk),Ptr{GObject},()))

GtkCellRendererSpinnerLeaf() = GtkCellRendererSpinnerLeaf(
    ccall((:gtk_cell_renderer_spinner_new,libgtk),Ptr{GObject},()))

### GtkTreeViewColumn

typealias KVMapping Union(Dict, ((TypeVar(:K),TypeVar(:V))...), Vector{(TypeVar(:K), TypeVar(:V))})

GtkTreeViewColumnLeaf() = GtkTreeViewColumnLeaf(ccall((:gtk_tree_view_column_new,libgtk),Ptr{GObject},()))
function GtkTreeViewColumnLeaf(renderer::GtkCellRenderer, mapping::KVMapping)
    treeColumn = GtkTreeViewColumnLeaf()
    unshift!(treeColumn,renderer)
    for (k,v) in mapping
        add_attribute(treeColumn,renderer,string(k),v)
    end
    treeColumn
end

function GtkTreeViewColumnLeaf(title::String,renderer::GtkCellRenderer, mapping::KVMapping)
    setproperty!(GtkTreeViewColumnLeaf(renderer,mapping), :title, title)
end

empty!(treeColumn::GtkTreeViewColumn) =
    ccall((:gtk_tree_view_column_clear,libgtk), Void, (Ptr{GObject},),treeColumn)

function unshift!(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer, expand::Bool=false)
    ccall((:gtk_tree_view_column_pack_start,libgtk), Void,
          (Ptr{GObject},Ptr{GObject},Cint),treeColumn,renderer,expand)
    treeColumn
end

function push!(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer, expand::Bool=false)
    ccall((:gtk_tree_view_column_pack_end,libgtk), Void,
          (Ptr{GObject},Ptr{GObject},Cint),treeColumn,renderer,expand)
    treeColumn
end

add_attribute(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer,
              attribute::String, column::Integer) =
    ccall((:gtk_tree_view_column_add_attribute,libgtk),Void,
          (Ptr{GObject},Ptr{GObject},Ptr{Uint8},Cint),treeColumn,renderer,bytestring(attribute),column)

### GtkTreeSelection
function selected(selection::GtkTreeSelection)
    hasselection(selection) || error("No selection for GtkTreeSelection")

    model = mutable(Ptr{GtkTreeModel})
    iter = mutable(GtkTreeIter)

    ret = bool(ccall((:gtk_tree_selection_get_selected,libgtk),Cint,
          (Ptr{GObject},Ptr{Ptr{GtkTreeModel}},Ptr{GtkTreeIter}),selection,model,iter))

    !ret  &&  error("No selection of GtkTreeSelection")

    iter[]
end

function selected_rows(selection::GtkTreeSelection)
    hasselection(selection) || return GtkTreeIter[]

    model = mutable(Ptr{GtkTreeModel})

    paths = Gtk.GLib.GList(ccall((:gtk_tree_selection_get_selected_rows, Gtk.libgtk), 
                                Ptr{Gtk._GSList{Gtk.GtkTreePath}},
                                (Ptr{GObject}, Ptr{GtkTreeModel}), 
                                selection, model))
    
    iters = GtkTreeIter[]
    for path in paths
        it = mutable(GtkTreeIter)
        ret = bool( ccall((:gtk_tree_model_get_iter,libgtk), Cint, (Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreePath}),
                          model,it,path))
        ret && push!(iters, it[])
    end
    
    iters
    
end


length(selection::GtkTreeSelection) =
    ccall((:gtk_tree_selection_count_selected_rows,libgtk), Cint, (Ptr{GObject},),selection)

hasselection(selection::GtkTreeSelection) = length(selection) > 0

Base.select!(selection::GtkTreeSelection, iter::TRI) =
    ccall((:gtk_tree_selection_select_iter,libgtk), Void,
          (Ptr{GObject},Ptr{GtkTreeIter}),selection, mutable(iter))

unselect!(selection::GtkTreeSelection, iter::TRI) =
    ccall((:gtk_tree_selection_unselect_iter,libgtk), Void,
          (Ptr{GObject},Ptr{GtkTreeIter}),selection, mutable(iter))

selectall!(selection::GtkTreeSelection) =
    ccall((:gtk_tree_selection_select_all,libgtk), Void, (Ptr{GObject},),selection)

unselectall!(selection::GtkTreeSelection) =
    ccall((:gtk_tree_selection_select_all,libgtk), Void, (Ptr{GObject},),selection)

### GtkTreeView

GtkTreeViewLeaf() = GtkTreeViewLeaf(ccall((:gtk_tree_view_new,libgtk),Ptr{GObject},()))
GtkTreeViewLeaf(treeStore::GtkTreeModel) = GtkTreeViewLeaf(
   ccall((:gtk_tree_view_new_with_model,libgtk),Ptr{GObject},(Ptr{GObject},),treeStore))

function push!(treeView::GtkTreeView,treeColumns::GtkTreeViewColumn...)
    for col in treeColumns
        ccall((:gtk_tree_view_append_column,libgtk),Void,(Ptr{GObject},Ptr{GObject}),treeView,col)
    end
    treeView
end

# TODO Use internal accessor with default values?
function path_at_pos(treeView::GtkTreeView, x::Integer, y::Integer)
    pathPtr = mutable(Ptr{GtkTreePath})
    path = GtkTreePath()

    ret = bool( ccall((:gtk_tree_view_get_path_at_pos,libgtk),Cint,
                      (Ptr{GObject},Cint,Cint,Ptr{Ptr{Void}},Ptr{Ptr{Void}},Ptr{Cint},Ptr{Cint} ),
                       treeView,x,y,pathPtr,C_NULL,C_NULL,C_NULL) )
    if ret
      path = convert(GtkTreePath, pathPtr[])
    end
    ret, path
end

### To be done
#
#if gtk_version == 3
#    GtkCellArea
#    GtkCellAreaBox
#    GtkCellAreaContext
#end
#
#GtkTreeModelSort
#
#GtkCellView
#GtkIconView
