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
    push!(cb::GtkComboBoxText,id::TupleType(String,Symbol),text::String) =
        (ccall((:gtk_combo_box_text_append,libgtk),Void,(Ptr{GObject},Ptr{Uint8},Ptr{Uint8}),cb,id,bytestring(text)); cb)
    unshift!(cb::GtkComboBoxText,id::TupleType(String,Symbol),text::String) =
        (ccall((:gtk_combo_box_text_prepend,libgtk),Void,(Ptr{GObject},Ptr{Uint8},Ptr{Uint8}),cb,id,bytestring(text)); cb)
    insert!(cb::GtkComboBoxText,i::Integer,id::TupleType(String,Symbol),text::String) =
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
prev(path::GtkTreePath) = ccall((:gtk_tree_path_prev,libgtk),Cint, (Ptr{GtkTreePath},),path) != 0
up(path::GtkTreePath) = ccall((:gtk_tree_path_up,libgtk),Cint, (Ptr{GtkTreePath},),path) != 0
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
     iter
end

### GtkListStore

function GtkListStoreLeaf(types::Type...)
    gtypes = GLib.gtypes(types...)
    handle = ccall((:gtk_list_store_newv,libgtk),Ptr{GObject},(Cint,Ptr{GLib.GType}), length(types), gtypes)
    GtkListStoreLeaf(handle)
end

## index is integer for a liststore, vector of ints for tree
iter_from_index(store::GtkListStoreLeaf, index::Int) = iter_from_string_index(store, string(index-1))


function list_store_set_values(store::GtkListStoreLeaf, iter, values)
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
function insert!(listStore::GtkListStoreLeaf, iter::TRI, values)
    newiter = Gtk.mutable(GtkTreeIter)
    ccall((:gtk_list_store_insert_before,Gtk.libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}), listStore, newiter, iter)
    list_store_set_values(listStore, newiter, values)
    newiter[]
end


function delete!(listStore::GtkListStore, iter::TRI)
    # not sure what to do with the return value here
    deleted = ccall((:gtk_list_store_remove,libgtk),Cint,(Ptr{GObject},Ptr{GtkTreeIter}), listStore, mutable(iter))
    listStore
end

deleteat!(listStore::GtkListStore, iter::TRI) = delete!(listStore, iter)


empty!(listStore::GtkListStore) =
    ccall((:gtk_list_store_clear,libgtk), Void, (Ptr{GObject},),listStore)

## by index

## insert into a list store after index
function insert!(listStore::GtkListStoreLeaf, index::Int, values)
    index > length(listStore) && return(push!(listStore, values))

    iter = iter_from_index(listStore, index)
    insert!(listStore, iter, values)
end

deleteat!(listStore::GtkListStoreLeaf, index::Int) = delete!(listStore, iter_from_index(listStore, index))
pop!(listStore::GtkListStoreLeaf) = deleteat!(listStore, length(listStore))
shift!(listSTore::GtkListStoreLeaf) = deleteat!(listStore, 1)


isvalid(listStore::GtkListStore, iter::TRI) =
    ccall((:gtk_list_store_iter_is_valid,libgtk), Cint,
	     (Ptr{GObject},Ptr{GtkTreeIter}),listStore, mutable(iter)) != 0

length(listStore::GtkListStore) =
    ccall((:gtk_tree_model_iter_n_children,libgtk), Cint, (Ptr{GObject},Ptr{GtkTreeIter}),listStore, C_NULL)

size(listStore::GtkListStore) = (length(listStore), ncolumns(GtkTreeModel(listStore)))

getindex(listStore::GtkListStore, iter::TRI, column::Integer) = getindex(GtkTreeModel(listStore), iter, column)
getindex(listStore::GtkListStore, iter::TRI) = getindex(GtkTreeModel(listStore), iter)
getindex(listStore::GtkListStore, row::Int, column) = getindex(listStore, iter_from_index(listStore, row), column)
getindex(listStore::GtkListStore, row::Int) = getindex(listStore, iter_from_index(listStore, row))



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
              treeStore,iter,i-1,Gtk.gvalue(value))
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
function insert!(treeStore::GtkTreeStoreLeaf, piter::TRI, values; how::Symbol=:parent, where::Symbol=:after)

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

deleteat!(treeStore::GtkTreeStore, iter::TRI) = delete!(treeStore, iter)

## insert by index
function insert!(treeStore::GtkTreeStoreLeaf, index::Vector{Int}, values; how::Symbol=:parent, where::Symbol=:after)
    piter = iter_from_index(treeStore, index)
    insert!(treeStore, iter, values; how=how, where=where)
end


function splice!(treeStore::GtkTreeStoreLeaf, index::Vector{Int})
    iter = iter_from_index(treeStore, index)
    delete!(treeStore, iter)
end

empty!(treeStore::GtkTreeStore) =
    ccall((:gtk_tree_store_clear,libgtk), Void, (Ptr{GObject},),treeStore)

isvalid(treeStore::GtkTreeStore, iter::TRI) =
    ccall((:gtk_tree_store_iter_is_valid,libgtk), Cint,
	     (Ptr{GObject},Ptr{GtkTreeIter}),treeStore, mutable(iter)) != 0

isancestor(treeStore::GtkTreeStore, iter::TRI, descendant::TRI) =
    ccall((:gtk_tree_store_is_ancestor,libgtk), Cint,
          (Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}),
          treeStore, mutable(iter), mutable(descendant)) != 0

depth(treeStore::GtkTreeStore, iter::TRI) =
    ccall((:gtk_tree_store_iter_depth,libgtk), Cint, (Ptr{GObject},Ptr{GtkTreeIter}),treeStore, mutable(iter))

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

#TODO: Replace by accessor
function iter(treeModel::GtkTreeModel, path::GtkTreePath)
  it = mutable(GtkTreeIter)
  ret = ccall((:gtk_tree_model_get_iter,libgtk), Cint, (Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreePath}),
                    treeModel,it,path) != 0
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

GtkTreeViewColumnLeaf() = GtkTreeViewColumnLeaf(ccall((:gtk_tree_view_column_new,libgtk),Ptr{GObject},()))
function GtkTreeViewColumnLeaf(renderer::GtkCellRenderer, mapping)
    treeColumn = GtkTreeViewColumnLeaf()
    unshift!(treeColumn,renderer)
    for (k,v) in mapping
        add_attribute(treeColumn,renderer,string(k),v)
    end
    treeColumn
end

function GtkTreeViewColumnLeaf(title::String, renderer::GtkCellRenderer, mapping)
    setproperty!(GtkTreeViewColumnLeaf(renderer,mapping), :title, title)
end

empty!(treeColumn::GtkTreeViewColumn) =
    ccall((:gtk_tree_view_column_clear,libgtk), Void, (Ptr{GObject},), treeColumn)

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

    ret = ccall((:gtk_tree_selection_get_selected,libgtk),Cint,
              (Ptr{GObject},Ptr{Ptr{GtkTreeModel}},Ptr{GtkTreeIter}),selection,model,iter) != 0

    !ret  &&  error("No selection of GtkTreeSelection")

    iter[]
end

function selected_rows(selection::GtkTreeSelection)
    hasselection(selection) || return GtkTreeIter[]

    model = mutable(Ptr{GtkTreeModel})

    paths = Gtk.GLib.GList(ccall((:gtk_tree_selection_get_selected_rows, Gtk.libgtk), 
                                Ptr{Gtk._GList{Gtk.GtkTreePath}},
                                (Ptr{GObject}, Ptr{GtkTreeModel}), 
                                selection, model))
    
    iters = GtkTreeIter[]
    for path in paths
        it = mutable(GtkTreeIter)
        ret = ccall((:gtk_tree_model_get_iter,libgtk), Cint, (Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreePath}),
                          model,it,path) != 0
        ret && push!(iters, it[])
    end
    
    iters
    
end


length(selection::GtkTreeSelection) =
    ccall((:gtk_tree_selection_count_selected_rows,libgtk), Cint, (Ptr{GObject},),selection)

hasselection(selection::GtkTreeSelection) = length(selection) > 0

select!(selection::GtkTreeSelection, iter::TRI) =
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

    ret = ccall((:gtk_tree_view_get_path_at_pos,libgtk),Cint,
                      (Ptr{GObject},Cint,Cint,Ptr{Ptr{Void}},Ptr{Ptr{Void}},Ptr{Cint},Ptr{Cint} ),
                       treeView,x,y,pathPtr,C_NULL,C_NULL,C_NULL) != 0
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
