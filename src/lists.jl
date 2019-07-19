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

GtkComboBoxTextLeaf(with_entry::Bool = false) = GtkComboBoxTextLeaf(
        if with_entry
            ccall((:gtk_combo_box_text_new_with_entry, libgtk), Ptr{GObject}, ())
        else
            ccall((:gtk_combo_box_text_new, libgtk), Ptr{GObject}, ())
        end)
push!(cb::GtkComboBoxText, text::AbstractString) =
    (ccall((:gtk_combo_box_text_append_text, libgtk), Nothing, (Ptr{GObject}, Ptr{UInt8}), cb, bytestring(text)); cb)
pushfirst!(cb::GtkComboBoxText, text::AbstractString) =
    (ccall((:gtk_combo_box_text_prepend_text, libgtk), Nothing, (Ptr{GObject}, Ptr{UInt8}), cb, bytestring(text)); cb)
insert!(cb::GtkComboBoxText, i::Integer, text::AbstractString) =
    (ccall((:gtk_combo_box_text_insert_text, libgtk), Nothing, (Ptr{GObject}, Cint, Ptr{UInt8}), cb, i - 1, bytestring(text)); cb)

if libgtk_version >= v"3"
    push!(cb::GtkComboBoxText, id::Union{AbstractString, Symbol}, text::AbstractString) =
        (ccall((:gtk_combo_box_text_append, libgtk), Nothing, (Ptr{GObject}, Ptr{UInt8}, Ptr{UInt8}), cb, id, bytestring(text)); cb)
    pushfirst!(cb::GtkComboBoxText, id::Union{AbstractString, Symbol}, text::AbstractString) =
        (ccall((:gtk_combo_box_text_prepend, libgtk), Nothing, (Ptr{GObject}, Ptr{UInt8}, Ptr{UInt8}), cb, id, bytestring(text)); cb)
    insert!(cb::GtkComboBoxText, i::Integer, id::Union{AbstractString, Symbol}, text::AbstractString) =
        (ccall((:gtk_combo_box_text_insert, libgtk), Nothing, (Ptr{GObject}, Cint, Ptr{UInt8}, Ptr{UInt8}), cb, i - 1, id, bytestring(text)); cb)

    empty!(cb::GtkComboBoxText) =
        (ccall((:gtk_combo_box_text_remove_all, libgtk), Nothing, (Ptr{GObject},), cb); cb)
end

delete!(cb::GtkComboBoxText, i::Integer) =
    (ccall((:gtk_combo_box_text_remove, libgtk), Nothing, (Ptr{GObject}, Cint), cb, i - 1); cb)

struct GtkTreeIter
    stamp::Cint
    user_data::Ptr{Nothing}
    user_data2::Ptr{Nothing}
    user_data3::Ptr{Nothing}
    GtkTreeIter() = new(0, C_NULL, C_NULL, C_NULL)
end

const TRI = Union{Mutable{GtkTreeIter}, GtkTreeIter}
zero(::Type{GtkTreeIter}) = GtkTreeIter()
copy(ti::GtkTreeIter) = ti
copy(ti::Mutable{GtkTreeIter}) = mutable(ti[])
show(io::IO, iter::GtkTreeIter) = print("GtkTreeIter(...)")

Base.cconvert(::Type{Ref{GtkTreeIter}},x::GtkTreeIter) = Ref(x)
Base.cconvert(::Type{Ref{GtkTreeIter}},x::Gtk.Mutable{GtkTreeIter}) = Ref(x[])

### GtkTreePath

# for debugging purpose
# immutable _GtkTreePath
#    depth::Cint
#    alloc::Cint
#    indices::Ptr{Cint}
# end

mutable struct GtkTreePath <: GBoxed
    handle::Ptr{GtkTreePath}
    function GtkTreePath(pathIn::Ptr{GtkTreePath}, own::Bool = false)
        x = new( own ? pathIn :
            ccall((:gtk_tree_path_copy, Gtk.libgtk), Ptr{GtkTreePath}, (Ptr{GtkTreePath},), pathIn)
        )
        f = x::GtkTreePath -> ccall((:gtk_tree_path_free, libgtk), Nothing, (Ptr{GtkTreePath},), x.handle)
        finalizer(f,x)
        x
    end
end
GtkTreePath() = GtkTreePath(ccall((:gtk_tree_path_new, libgtk), Ptr{GtkTreePath}, ()), true)
copy(path::GtkTreePath) = GtkTreePath(path.handle)

next(path::GtkTreePath) = ccall((:gtk_tree_path_next, libgtk), Nothing, (Ptr{GtkTreePath},), path)
prev(path::GtkTreePath) = ccall((:gtk_tree_path_prev, libgtk), Cint, (Ptr{GtkTreePath},), path) != 0
up(path::GtkTreePath) = ccall((:gtk_tree_path_up, libgtk), Cint, (Ptr{GtkTreePath},), path) != 0
down(path::GtkTreePath) = ccall((:gtk_tree_path_down, libgtk), Nothing, (Ptr{GtkTreePath},), path)
string(path::GtkTreePath) = bytestring( ccall((:gtk_tree_path_to_string, libgtk), Ptr{UInt8},
                                            (Ptr{GtkTreePath},), path))

### add indices for a store 1-based

## Get an iter corresponding to an index specified as a string
function iter_from_string_index(store, index::AbstractString)
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
    handle = ccall((:gtk_list_store_newv, libgtk), Ptr{GObject}, (Cint, Ptr{GLib.GType}), length(types), gtypes)
    GtkListStoreLeaf(handle)
end

GtkListStoreLeaf(combo::GtkComboBoxText) = GtkListStoreLeaf(ccall((:gtk_combo_box_get_model, libgtk), Ptr{GObject}, (Ptr{GObject},), combo))

## index is integer for a liststore, vector of ints for tree
iter_from_index(store::GtkListStore, index::Int) = iter_from_string_index(store, string(index - 1))
index_from_iter(store::GtkListStore, iter::TRI) = parse(Int, get_string_from_iter(GtkTreeModel(store), iter)) + 1

function list_store_set_values(store::GtkListStore, iter, values)
    for (i, value) in enumerate(values)
        ccall((:gtk_list_store_set_value, Gtk.libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}, Cint, Ptr{Gtk.GValue}),
              store, iter, i - 1, Gtk.gvalue(value))
    end
end

function push!(listStore::GtkListStore, values::Tuple)
    iter = mutable(GtkTreeIter)
    ccall((:gtk_list_store_append, libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}), listStore, iter)

    list_store_set_values(listStore, iter, values)
    iter[]
end

function pushfirst!(listStore::GtkListStore, values::Tuple)
    iter = mutable(GtkTreeIter)
    ccall((:gtk_list_store_prepend, libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}), listStore, iter)
    list_store_set_values(listStore, iter, values)
    iter[]
end

## insert before
function insert!(listStore::GtkListStoreLeaf, iter::TRI, values)
    newiter = Gtk.mutable(GtkTreeIter)
    ccall((:gtk_list_store_insert_before, Gtk.libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{GtkTreeIter}), listStore, newiter, iter)
    list_store_set_values(listStore, newiter, values)
    newiter[]
end


function delete!(listStore::GtkListStore, iter::TRI)
    # not sure what to do with the return value here
    deleted = ccall((:gtk_list_store_remove, libgtk), Cint, (Ptr{GObject}, Ref{GtkTreeIter}), listStore, iter)
    listStore
end

deleteat!(listStore::GtkListStore, iter::TRI) = delete!(listStore, iter)


empty!(listStore::GtkListStore) =
    ccall((:gtk_list_store_clear, libgtk), Nothing, (Ptr{GObject},), listStore)

## by index

## insert into a list store after index
function insert!(listStore::GtkListStoreLeaf, index::Int, values)
    index > length(listStore) && return(push!(listStore, values))

    iter = iter_from_index(listStore, index)
    insert!(listStore, iter, values)
end

deleteat!(listStore::GtkListStoreLeaf, index::Int) = delete!(listStore, iter_from_index(listStore, index))
pop!(listStore::GtkListStoreLeaf) = deleteat!(listStore, length(listStore))
popfirst!(listSTore::GtkListStoreLeaf) = deleteat!(listStore, 1)


isvalid(listStore::GtkListStore, iter::TRI) =
    ccall((:gtk_list_store_iter_is_valid, libgtk), Cint,
         (Ptr{GObject}, Ref{GtkTreeIter}), listStore, iter) != 0

function length(listStore::GtkListStore)
    _len = ccall((:gtk_tree_model_iter_n_children, libgtk), Cint, (Ptr{GObject}, Ptr{GtkTreeIter}), listStore, C_NULL)
	return convert(Int, _len)
end

size(listStore::GtkListStore) = (length(listStore), ncolumns(GtkTreeModel(listStore)))

getindex(store::GtkListStore, row::Int, column) = getindex(store, iter_from_index(store, row), column)
getindex(store::GtkListStore, row::Int) = getindex(store, iter_from_index(store, row))

function setindex!(store::GtkListStore, value, index::Int, column::Integer)
    setindex!(store, value, Gtk.iter_from_index(store, index), column)
end

### GtkTreeStore

function GtkTreeStoreLeaf(types::Type...)
    gtypes = GLib.gtypes(types...)
    handle = ccall((:gtk_tree_store_newv, libgtk), Ptr{GObject}, (Cint, Ptr{GLib.GType}), length(types), gtypes)
    GtkTreeStoreLeaf(handle)
end

iter_from_index(store::GtkTreeStoreLeaf, index::Vector{Int}) = iter_from_string_index(store, join(index.-1, ":"))

function tree_store_set_values(treeStore::GtkTreeStoreLeaf, iter, values)
    for (i, value) in enumerate(values)
        ccall((:gtk_tree_store_set_value, Gtk.libgtk), Nothing, (Ptr{GObject}, Ref{GtkTreeIter}, Cint, Ptr{Gtk.GValue}),
              treeStore, iter, i - 1, gvalue(value))
    end
    iter[]
end


function push!(treeStore::GtkTreeStore, values::Tuple, parent = nothing)
    iter = mutable(GtkTreeIter)
    if parent == nothing
        ccall((:gtk_tree_store_append, libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}, Ptr{Nothing}), treeStore, iter, C_NULL)
    else
        ccall((:gtk_tree_store_append, libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{GtkTreeIter}), treeStore, iter, parent)
    end

    tree_store_set_values(treeStore, iter, values)
    iter[]
end

function pushfirst!(treeStore::GtkTreeStore, values::Tuple, parent = nothing)
    iter = mutable(GtkTreeIter)
    if parent == nothing
        ccall((:gtk_tree_store_prepend, libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}, Ptr{Nothing}), treeStore, iter, C_NULL)
    else
        ccall((:gtk_tree_store_prepend, libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{GtkTreeIter}), treeStore, iter, parent)
    end

    tree_store_set_values(treeStore, iter, values)
    iter[]
end

## index can be :parent or :sibling
## insertion can be :after or :before
function insert!(treeStore::GtkTreeStoreLeaf, piter::TRI, values; how::Symbol = :parent, where::Symbol = :after)

    iter =  Gtk.mutable(GtkTreeIter)
    if how == :parent
        if where == :after
            ccall((:gtk_tree_store_insert_after, Gtk.libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{GtkTreeIter}, Ptr{Nothing}), treeStore, iter, piter, C_NULL)
        else
            ccall((:gtk_tree_store_insert_before, Gtk.libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{GtkTreeIter}, Ptr{Nothing}), treeStore, iter, piter, C_NULL)
        end
    else
        if where == :after
            ccall((:gtk_tree_store_insert_after, Gtk.libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{Nothing}, Ref{GtkTreeIter}), treeStore, iter, C_NULL, piter)
        else
            ccall((:gtk_tree_store_insert_before, Gtk.libgtk), Nothing, (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{Nothing}, Ref{GtkTreeIter}), treeStore, iter, C_NULL, piter)
        end
    end

    tree_store_set_values(treeStore, iter, values)
end


function delete!(treeStore::GtkTreeStore, iter::TRI)
    # not sure what to do with the return value here
    deleted = ccall((:gtk_tree_store_remove, libgtk), Cint, (Ptr{GObject}, Ref{GtkTreeIter}), treeStore, iter)
    treeStore
end

deleteat!(treeStore::GtkTreeStore, iter::TRI) = delete!(treeStore, iter)

## insert by index
function insert!(treeStore::GtkTreeStoreLeaf, index::Vector{Int}, values; how::Symbol = :parent, where::Symbol = :after)
    piter = iter_from_index(treeStore, index)
    insert!(treeStore, iter, values; how = how, where = where)
end


function splice!(treeStore::GtkTreeStoreLeaf, index::Vector{Int})
    iter = iter_from_index(treeStore, index)
    delete!(treeStore, iter)
end

empty!(treeStore::GtkTreeStore) =
    ccall((:gtk_tree_store_clear, libgtk), Nothing, (Ptr{GObject},), treeStore)

isvalid(treeStore::GtkTreeStore, iter::TRI) =
    ccall((:gtk_tree_store_iter_is_valid, libgtk), Cint,
         (Ptr{GObject}, Ref{GtkTreeIter}), treeStore, iter) != 0

isancestor(treeStore::GtkTreeStore, iter::TRI, descendant::TRI) =
    ccall((:gtk_tree_store_is_ancestor, libgtk), Cint,
          (Ptr{GObject}, Ref{GtkTreeIter}, Ref{GtkTreeIter}),
          treeStore, iter, descendant) != 0

depth(treeStore::GtkTreeStore, iter::TRI) =
    ccall((:gtk_tree_store_iter_depth, libgtk), Cint, (Ptr{GObject}, Ref{GtkTreeIter}), treeStore, iter)

## get index store[iter], store[iter, column], store[index], store[index, column]
getindex(store::Union{GtkTreeStore, GtkListStore}, iter::TRI, column::Integer) = getindex(GtkTreeModel(store), iter, column)
getindex(store::Union{GtkTreeStore, GtkListStore}, iter::TRI) = getindex(GtkTreeModel(store), iter)

getindex(store::GtkTreeStore, row::Vector{Int}, column) = getindex(store, iter_from_index(store, row), column)
getindex(store::GtkTreeStore, row::Vector{Int}) = getindex(store, iter_from_index(store, row))


function setindex!(store::Union{GtkListStore, GtkTreeStore}, value, iter::TRI, column::Integer)
    Gtk.G_.value(store, Gtk.mutable(iter), column - 1, gvalue(value))
end

function setindex!(store::GtkTreeStore, value, index::Vector{Int}, column::Integer)
     setindex!(store, value, Gtk.iter_from_index(store, index), column)
end



### GtkTreeModelFilter

GtkTreeModelFilterLeaf(child_model::GObject) = GtkTreeModelFilterLeaf(
    ccall((:gtk_tree_model_filter_new, libgtk), Ptr{GObject}, (Ptr{GObject}, Ptr{Nothing}), child_model, C_NULL))

function convert_iter_to_child_iter(model::GtkTreeModelFilter, filter_iter::TRI)
    child_iter = mutable(GtkTreeIter)
    ccall((:gtk_tree_model_filter_convert_iter_to_child_iter, libgtk), Nothing,
          (Ptr{GObject}, Ptr{GtkTreeIter}, Ptr{GtkTreeIter}),
          model, child_iter, mutable(filter_iter))
    child_iter[]
end

function convert_child_iter_to_iter(model::GtkTreeModelFilter, child_iter::TRI)
    filter_iter = mutable(GtkTreeIter)
    ccall((:gtk_tree_model_filter_convert_child_iter_to_iter, libgtk), Nothing,
          (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{GtkTreeIter}),
          model,  filter_iter, child_iter)
    filter_iter[]
end

### GtkTreeModelSort

GtkTreeModelSortLeaf(child_model::GObject) = GtkTreeModelSortLeaf(
    ccall((:gtk_tree_model_sort_new_with_model, libgtk), Ptr{GObject}, (Ptr{GObject},), child_model))

function convert_iter_to_child_iter(model::GtkTreeModelSort, sort_iter::TRI)
    child_iter = mutable(GtkTreeIter)
    ccall((:gtk_tree_model_sort_convert_iter_to_child_iter, libgtk), Nothing,
          (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{GtkTreeIter}),
          model, child_iter, sort_iter)
    child_iter[]
end

function convert_child_iter_to_iter(model::GtkTreeModelSort, child_iter::TRI)
    sort_iter = mutable(GtkTreeIter)
    ccall((:gtk_tree_model_sort_convert_child_iter_to_iter, libgtk), Nothing,
          (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{GtkTreeIter}),
          model, sort_iter, child_iter)
    sort_iter[]
end
### GtkTreeModel

function getindex(treeModel::GtkTreeModel, iter::TRI, column::Integer)
    val = mutable(GValue())
    ccall((:gtk_tree_model_get_value, libgtk), Nothing, (Ptr{GObject}, Ref{GtkTreeIter}, Cint, Ptr{GValue}),
           treeModel, iter, column - 1, val)
    val[Any]
end

function getindex(treeModel::GtkTreeModel, iter::TRI)
    ntuple( i -> treeModel[iter, i], ncolumns(treeModel) )
end

function setindex!(treeModel::GtkTreeModel, value, iter::TRI, column::Integer)
    G_.value(treeModel, mutable(iter), column - 1, gvalue(value))
end

function setindex!(treeModel::GtkTreeModel, values, iter::TRI)
    for (i, v) in enumerate(values)
        G_.value(treeModel, mutable(iter), i - 1, gvalue(v))
    end
end

ncolumns(treeModel::GtkTreeModel) =
    ccall((:gtk_tree_model_get_n_columns, libgtk), Cint, (Ptr{GObject},), treeModel)

## add in gtk_tree_model iter functions to traverse tree

## Most gtk function pass in a Mutable Iter and return a bool
## Update iter to point to first iterm
function get_iter_first(treeModel::GtkTreeModel, iter = Mutable{GtkTreeIter})
    ret = ccall((:gtk_tree_model_get_iter_first, libgtk), Cint,
          (Ptr{GObject}, Ptr{GtkTreeIter}),
          treeModel, iter)
    ret != 0
end

## return (Bool, iter)
function get_iter_next(treeModel::GtkTreeModel, iter::Mutable{GtkTreeIter})
    ret = ccall((:gtk_tree_model_iter_next, libgtk), Cint,
                (Ptr{GObject}, Ptr{GtkTreeIter}),
                treeModel, iter)
    ret != 0
end

## update iter to point to previous.
## return Bool
function get_iter_previous(treeModel::GtkTreeModel, iter::Mutable{GtkTreeIter})
    ret = ccall((:gtk_tree_model_iter_previous, libgtk), Cint,
          (Ptr{GObject}, Ptr{GtkTreeIter}),
          treeModel, iter)
    ret != 0
end

## update iter to point to first child of parent iter
## return Bool
function iter_children(treeModel::GtkTreeModel, iter::Mutable{GtkTreeIter}, piter::TRI)
    ret = ccall((:gtk_tree_model_iter_children, libgtk), Cint,
                (Ptr{GObject}, Ptr{GtkTreeIter}, Ptr{GtkTreeIter}),
                treeModel, iter, mutable(piter))
    ret != 0
end

## return boolean, checks if there is a child
function iter_has_child(treeModel::GtkTreeModel, iter::TRI)
    ret = ccall((:gtk_tree_model_iter_has_child, libgtk), Cint,
          (Ptr{GObject},  Ref{GtkTreeIter}),
          treeModel, iter)
    ret != 0
end

## return number of children for iter
function iter_n_children(treeModel::GtkTreeModel, iter::TRI)
    ret = ccall((:gtk_tree_model_iter_n_children, libgtk), Cint,
          (Ptr{GObject},  Ref{GtkTreeIter}),
          treeModel, iter)
    ret
end


## update iter pointing to nth child n in 1:nchildren)
## return boolean
function iter_nth_child(treeModel::GtkTreeModel, iter::Mutable{GtkTreeIter}, piter::TRI, n::Int)
    ret = ccall((:gtk_tree_model_iter_nth_child, libgtk), Cint,
          (Ptr{GObject}, Ptr{GtkTreeIter}, Ptr{GtkTreeIter}, Cint),
          treeModel, iter, mutable(piter), n - 1) # 0-based
    ret != 0
end

## return Bool
function iter_parent(treeModel::GtkTreeModel, iter::Mutable{GtkTreeIter}, citer::TRI)
    ret = ccall((:gtk_tree_model_iter_parent, libgtk), Cint,
                (Ptr{GObject}, Ptr{GtkTreeIter}, Ref{GtkTreeIter}),
                treeModel, iter, citer)
    ret != 0
end

## string is of type "0:1:0" (0-based)
function get_string_from_iter(treeModel::GtkTreeModel, iter::TRI)
    val = ccall((:gtk_tree_model_get_string_from_iter, libgtk),  Ptr{UInt8},
          (Ptr{GObject}, Ref{GtkTreeIter}),
          treeModel, iter)
    val = bytestring(val)
end

## these mutate iter to point to new object.
next(treeModel::GtkTreeModel, iter::Mutable{GtkTreeIter}) = get_iter_next(treeModel, iter)
prev(treeModel::GtkTreeModel, iter::Mutable{GtkTreeIter}) = get_iter_previous(treeModel, iter)
up(treeModel::GtkTreeModel, iter::Mutable{GtkTreeIter}) = iter_parent(treeModel, iter, copy(iter))
down(treeModel::GtkTreeModel, iter::Mutable{GtkTreeIter}) = iter_children(treeModel, iter, copy(iter))

length(treeModel::GtkTreeModel, iter::TRI) = iter_n_children(treeModel, iter)
string(treeModel::GtkTreeModel, iter::TRI) = get_string_from_iter(treeModel, iter)

## index is Int[] 1-based
index_from_iter(treeModel::GtkTreeModel, iter::TRI) = map(int, split(get_string_from_iter(treeModel, iter), ":")) + 1

## An iterator to walk a tree, e.g.,
## for iter in Gtk.TreeIterator(store) ## or Gtk.TreeIterator(store, piter)
##   println(store[iter, 1])
## end
mutable struct TreeIterator
    store::GtkTreeStore
    model::GtkTreeModel
    iter::Union{Nothing, TRI}
end
TreeIterator(store::GtkTreeStore, iter = nothing) = TreeIterator(store, GtkTreeModel(store), iter)
Base.IteratorSize(::TreeIterator) = Base.SizeUnknown()

## iterator interface for depth first search
function start_(x::TreeIterator)
    isa(x.iter, Nothing) ? nothing : mutable(copy(x.iter))
end

function done_(x::TreeIterator, state)

    iter = mutable(GtkTreeIter)

    isa(state, Nothing) && return (!Gtk.get_iter_first(x.model, iter))   # special case root

    state = copy(state)

    ## we are not done if:
    iter_has_child(x.model, state) && return(false) # state has child
    next(x.model, copy(state))     && return(false) # state has sibling

    # or a valid ancestor of piter has a sibling
    up(x.model, state) || return(true)

    while isa(x.iter, Nothing) || isancestor(x.store, x.iter, state)
        next(x.model, copy(state)) && return(false) # has a sibling
        up(x.model, state) || return(true)
    end
    return(true)
end


function next_(x::TreeIterator, state)
    iter = mutable(GtkTreeIter)

    if isa(state, Nothing)      # special case root
        Gtk.get_iter_first(x.model, iter)
        return(iter, iter)
    end

    state = copy(state)

    if iter_has_child(x.model, state)
        down(x.model, state)
        return(state, state)
    end

    cstate = copy(state)
    next(x.model, cstate) && return(cstate, cstate)

    up(x.model, state)

    while isa(x.iter, Nothing) || isancestor(x.store, x.iter, state)
        cstate = copy(state)
        next(x.model, cstate) && return(cstate, cstate) # return the sibling of state
        up(x.model, state)
    end
    error("next not found")
end

iterate(x::TreeIterator, state=start_(x)) = done_(x, state) ? nothing : next_(x, state)


#TODO: Replace by accessor
function iter(treeModel::GtkTreeModel, path::GtkTreePath)
  it = mutable(GtkTreeIter)
  ret = ccall((:gtk_tree_model_get_iter, libgtk), Cint, (Ptr{GObject}, Ptr{GtkTreeIter}, Ptr{GtkTreePath}),
                    treeModel, it, path) != 0
  ret, it[]
end

#TODO: Replace by accessor (accessor is wrong)
function path(treeModel::GtkTreeModel, iter::TRI)
  GtkTreePath( ccall((:gtk_tree_model_get_path, libgtk), Ptr{GtkTreePath},
                            (Ptr{GObject}, Ref{GtkTreeIter}),
                            treeModel, iter ) )
end

depth(path::GtkTreePath) = ccall((:gtk_tree_path_get_depth, libgtk), Cint,
    (Ptr{GtkTreePath},), path)

### GtkTreeSortable

### GtkCellRenderer

GtkCellRendererAccelLeaf() = GtkCellRendererAccelLeaf(
    ccall((:gtk_cell_renderer_accel_new, libgtk), Ptr{GObject}, ()))

GtkCellRendererComboLeaf() = GtkCellRendererComboLeaf(
    ccall((:gtk_cell_renderer_combo_new, libgtk), Ptr{GObject}, ()))

GtkCellRendererPixbufLeaf() = GtkCellRendererPixbufLeaf(
    ccall((:gtk_cell_renderer_pixbuf_new, libgtk), Ptr{GObject}, ()))

GtkCellRendererProgressLeaf() = GtkCellRendererProgressLeaf(
    ccall((:gtk_cell_renderer_progress_new, libgtk), Ptr{GObject}, ()))

GtkCellRendererSpinLeaf() = GtkCellRendererSpinLeaf(
    ccall((:gtk_cell_renderer_spin_new, libgtk), Ptr{GObject}, ()))

GtkCellRendererTextLeaf() = GtkCellRendererTextLeaf(
    ccall((:gtk_cell_renderer_text_new, libgtk), Ptr{GObject}, ()))

GtkCellRendererToggleLeaf() = GtkCellRendererToggleLeaf(
    ccall((:gtk_cell_renderer_toggle_new, libgtk), Ptr{GObject}, ()))

GtkCellRendererSpinnerLeaf() = GtkCellRendererSpinnerLeaf(
    ccall((:gtk_cell_renderer_spinner_new, libgtk), Ptr{GObject}, ()))

### GtkTreeViewColumn

GtkTreeViewColumnLeaf() = GtkTreeViewColumnLeaf(ccall((:gtk_tree_view_column_new, libgtk), Ptr{GObject}, ()))
function GtkTreeViewColumnLeaf(renderer::GtkCellRenderer, mapping)
    treeColumn = GtkTreeViewColumnLeaf()
    pushfirst!(treeColumn, renderer)
    for (k, v) in mapping
        add_attribute(treeColumn, renderer, string(k), v)
    end
    treeColumn
end

function GtkTreeViewColumnLeaf(title::AbstractString, renderer::GtkCellRenderer, mapping)
    set_gtk_property!(GtkTreeViewColumnLeaf(renderer, mapping), :title, title)
end

empty!(treeColumn::GtkTreeViewColumn) =
    ccall((:gtk_tree_view_column_clear, libgtk), Nothing, (Ptr{GObject},), treeColumn)

function pushfirst!(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer, expand::Bool = false)
    ccall((:gtk_tree_view_column_pack_start, libgtk), Nothing,
          (Ptr{GObject}, Ptr{GObject}, Cint), treeColumn, renderer, expand)
    treeColumn
end

function push!(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer, expand::Bool = false)
    ccall((:gtk_tree_view_column_pack_end, libgtk), Nothing,
          (Ptr{GObject}, Ptr{GObject}, Cint), treeColumn, renderer, expand)
    treeColumn
end

add_attribute(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer,
              attribute::AbstractString, column::Integer) =
    ccall((:gtk_tree_view_column_add_attribute, libgtk), Nothing,
          (Ptr{GObject}, Ptr{GObject}, Ptr{UInt8}, Cint), treeColumn, renderer, bytestring(attribute), column)

### GtkTreeSelection
function selected(selection::GtkTreeSelection)
    hasselection(selection) || error("No selection for GtkTreeSelection")

    model = mutable(Ptr{GtkTreeModel})
    iter = mutable(GtkTreeIter)

    ret = ccall((:gtk_tree_selection_get_selected, libgtk), Cint,
              (Ptr{GObject}, Ptr{Ptr{GtkTreeModel}}, Ptr{GtkTreeIter}), selection, model, iter) != 0

    !ret && error("No selection of GtkTreeSelection")

    iter[]
end

function selected_rows(selection::GtkTreeSelection)
    hasselection(selection) || return GtkTreeIter[]

    model = mutable(Ptr{GtkTreeModel})

    paths = GLib.GList(ccall((:gtk_tree_selection_get_selected_rows, libgtk),
                                Ptr{GLib._GList{GtkTreePath}},
                                (Ptr{GObject}, Ptr{GtkTreeModel}),
                                selection, model))

    iters = GtkTreeIter[]
    for path in paths
        ret, it = iter(model, path)
        ret && push!(iters, it)
    end

    iters
end

length(selection::GtkTreeSelection) =
    ccall((:gtk_tree_selection_count_selected_rows, libgtk), Cint, (Ptr{GObject},), selection)

hasselection(selection::GtkTreeSelection) = length(selection) > 0

select!(selection::GtkTreeSelection, iter::TRI) =
    ccall((:gtk_tree_selection_select_iter, libgtk), Nothing,
          (Ptr{GObject}, Ref{GtkTreeIter}), selection, iter)

unselect!(selection::GtkTreeSelection, iter::TRI) =
    ccall((:gtk_tree_selection_unselect_iter, libgtk), Nothing,
          (Ptr{GObject}, Ref{GtkTreeIter}), selection, iter)

selectall!(selection::GtkTreeSelection) =
    ccall((:gtk_tree_selection_select_all, libgtk), Nothing, (Ptr{GObject},), selection)

unselectall!(selection::GtkTreeSelection) =
    ccall((:gtk_tree_selection_unselect_all, libgtk), Nothing, (Ptr{GObject},), selection)

### GtkTreeView

GtkTreeViewLeaf() = GtkTreeViewLeaf(ccall((:gtk_tree_view_new, libgtk), Ptr{GObject}, ()))
GtkTreeViewLeaf(treeStore::GtkTreeModel) = GtkTreeViewLeaf(
   ccall((:gtk_tree_view_new_with_model, libgtk), Ptr{GObject}, (Ptr{GObject},), treeStore))

function push!(treeView::GtkTreeView, treeColumns::GtkTreeViewColumn...)
    for col in treeColumns
        ccall((:gtk_tree_view_append_column, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}), treeView, col)
    end
    treeView
end

# TODO Use internal accessor with default values?
function path_at_pos(treeView::GtkTreeView, x::Integer, y::Integer)
    pathPtr = Ref{Ptr{GtkTreePath}}(0)

    ret = ccall((:gtk_tree_view_get_path_at_pos, libgtk), Cint,
                      (Ptr{GObject}, Cint, Cint, Ref{Ptr{GtkTreePath}}, Ptr{Ptr{Nothing}}, Ptr{Cint}, Ptr{Cint} ),
                       treeView, x, y, pathPtr, C_NULL, C_NULL, C_NULL) != 0
    if ret
        path = GtkTreePath(pathPtr[], true)
    else
      path = GtkTreePath()
    end
    ret, path
end

### GtkCellLayout
function cells(cellLayout::GtkCellLayout)
  cells = Gtk.GLib.GList(ccall((:gtk_cell_layout_get_cells, Gtk.libgtk),
             Ptr{Gtk._GList{Gtk.GtkCellRenderer}}, (Ptr{GObject},), cellLayout))
  return cells
end

### To be done
#
#if libgtk_version >= v"3"
#    GtkCellArea
#    GtkCellAreaBox
#    GtkCellAreaContext
#end
#
#GtkCellView
#GtkIconView
