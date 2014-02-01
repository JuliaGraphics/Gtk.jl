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

@gtktype GtkComboBoxText
GtkComboBoxText(with_entry::Bool=false) = GtkComboBoxText(
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

type GtkTreeIter
  stamp::Cint
  user_data::Ptr{Void}
  user_data2::Ptr{Void}
  user_data3::Ptr{Void}
  GtkTreeIter() = new(0,C_NULL,C_NULL,C_NULL)
end

### GtkListStore

@gtktype GtkListStore
function GtkListStore(types::Type...)
    gtypes = GLib.gtypes(types...)
    handle = ccall((:gtk_list_store_newv,libgtk),Ptr{GObject},(Cint,Ptr{GLib.GType}), length(types), gtypes)
    GtkListStore(handle)
end

function push!(listStore::GtkListStore, values::Tuple)
    iter = GtkTreeIter()
    ccall((:gtk_list_store_append,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter}), listStore, &iter)
    for (i,value) in enumerate(values)
        ccall((:gtk_list_store_set_value,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Cint,Ptr{GValue}),
              listStore,&iter,i-1,gvalue(value))
    end
    iter
end

function unshift!(listStore::GtkListStore, values::Tuple)
    iter = GtkTreeIter()
    ccall((:gtk_list_store_prepend,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter}), listStore, &iter)
    for (i,value) in enumerate(values)
        ccall((:gtk_list_store_set_value,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Cint,Ptr{GValue}),
              listStore,&iter,i-1,gvalue(value))
    end
    iter
end

function delete!(listStore::GtkListStore, iter::GtkTreeIter)
    # not sure what to do with the return value here
    deleted = ccall((:gtk_list_store_remove,libgtk),Cint,(Ptr{GObject},Ptr{GtkTreeIter}), listStore, &iter)
    listStore
end

empty!(listStore::GtkListStore) =
    ccall((:gtk_list_store_clear,libgtk), Void, (Ptr{GObject},),listStore)

isvalid(listStore::GtkListStore, iter::GtkTreeIter) = 
    bool( ccall((:gtk_list_store_iter_is_valid,libgtk), Cint, 
	     (Ptr{GObject},Ptr{GtkTreeIter}),listStore, &iter))

length(listStore::GtkListStore) =
    ccall((:gtk_tree_model_iter_n_children,libgtk), Cint, (Ptr{GObject},Ptr{GtkTreeIter}),listStore, C_NULL)

### GtkTreeStore

@gtktype GtkTreeStore
function GtkTreeStore(types::Type...)
    gtypes = GLib.gtypes(types...)
    handle = ccall((:gtk_tree_store_newv,libgtk),Ptr{GObject},(Cint,Ptr{GLib.GType}), length(types), gtypes)
    GtkTreeStore(handle)
end

function push!(treeStore::GtkTreeStore, values::Tuple, parent=nothing)
    iter = GtkTreeIter()
    if parent == nothing
        ccall((:gtk_tree_store_append,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void}), treeStore, &iter, C_NULL)
    else
        ccall((:gtk_tree_store_append,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}), treeStore, &iter, &parent)
    end    
    for (i,value) in enumerate(values)
        ccall((:gtk_tree_store_set_value,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Cint,Ptr{GValue}),
              treeStore,&iter,i-1,gvalue(value))
    end
    iter
end

function unshift!(treeStore::GtkTreeStore, values::Tuple, parent=nothing)
    iter = GtkTreeIter()
    if parent == nothing
        ccall((:gtk_tree_store_prepend,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{Void}), treeStore, &iter, C_NULL)
    else
        ccall((:gtk_tree_store_prepend,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}), treeStore, &iter, &parent)
    end    
    for (i,value) in enumerate(values)
        ccall((:gtk_tree_store_set_value,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter},Cint,Ptr{GValue}),
              treeStore,&iter,i-1,gvalue(value))
    end
    iter
end

function delete!(treeStore::GtkTreeStore, iter::GtkTreeIter)
    # not sure what to do with the return value here
    deleted = ccall((:gtk_tree_store_remove,libgtk),Cint,(Ptr{GObject},Ptr{GtkTreeIter}), treeStore, &iter)
    treeStore
end

empty!(treeStore::GtkTreeStore) =
    ccall((:gtk_tree_store_clear,libgtk), Void, (Ptr{GObject},),treeStore)

isvalid(treeStore::GtkTreeStore, iter::GtkTreeIter) =
    bool( ccall((:gtk_tree_store_iter_is_valid,libgtk), Cint, 
	     (Ptr{GObject},Ptr{GtkTreeIter}),treeStore, &iter))

isancestor(treeStore::GtkTreeStore, iter::GtkTreeIter, descendant::GtkTreeIter) =
    bool( ccall((:gtk_tree_store_is_ancestor,libgtk), Cint,
          (Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}),
          treeStore, &iter, &descendant))

depth(treeStore::GtkTreeStore, iter::GtkTreeIter) =
    ccall((:gtk_tree_store_iter_depth,libgtk), Cint, (Ptr{GObject},Ptr{GtkTreeIter}),treeStore, &iter)
  
### GtkTreeModelFilter

@gtktype GtkTreeModelFilter
function GtkTreeModelFilter(child_model::GObjectI)
    handle = ccall((:gtk_tree_model_filter_new,libgtk),Ptr{GObject},(Ptr{GObject},Ptr{None}), child_model, C_NULL)
    GtkTreeModelFilter(handle)
end

function convert_iter_to_child_iter(model::GtkTreeModelFilter, filter_iter::GtkTreeIter)
    child_iter = GtkTreeIter()
    ccall((:gtk_tree_model_filter_convert_iter_to_child_iter,libgtk),Void,
          (Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}), 
          model, &child_iter, &filter_iter)
    child_iter
end

function convert_child_iter_to_iter(model::GtkTreeModelFilter, child_iter::GtkTreeIter)
    filter_iter = GtkTreeIter()
    ccall((:gtk_tree_model_filter_convert_child_iter_to_iter,libgtk),Void,
          (Ptr{GObject},Ptr{GtkTreeIter},Ptr{GtkTreeIter}), 
          model,  &filter_iter, &child_iter)
    filter_iter
end

### GtkTreeModelI

GtkTreeModelI = Union(GtkListStore,GtkTreeStore,GtkTreeModelFilter)

function getindex(treeModel::GtkTreeModelI, iter::GtkTreeIter, column::Integer)
    arr = [GValue()]
    ptr = pointer(arr)
    ccall((:gtk_tree_model_get_value,libgtk), Void, (Ptr{GObject},Ptr{GtkTreeIter},Cint,Ptr{GValue}),
           treeModel, &iter, column-1, ptr)
    ptr[]
end

function getindex(treeModel::GtkTreeModelI, iter::GtkTreeIter)
    ntuple( ncolumns(treeModel), i -> treeModel[iter,i] )
end

function setindex!(treeModel::GtkTreeModelI, value, iter::GtkTreeIter, column::Integer)
    G_.value(treeModel,mutable(iter),column-1,gvalue(value))
end

function setindex!(treeModel::GtkTreeModelI, values, iter::GtkTreeIter)
    for (i,v) in enumerate(values)
        G_.value(treeModel,mutable(iter),i-1,gvalue(v))
    end
end

ncolumns(treeModel::GtkTreeModelI) =
    ccall((:gtk_tree_model_get_n_columns,libgtk), Cint, (Ptr{GObject},),treeModel)

### GtkTreeSortableI

baremodule GtkSortType
    const ASCENDING = 0
    const DESCENDING = 1
end

typealias GtkTreeSortableI Union(GtkListStore,GtkTreeStore)

### GtkCellRenderer

@gtktype GtkCellRenderer

@gtktype GtkCellRendererAccel
GtkCellRendererAccel() = GtkCellRendererAccel( ccall((:gtk_cell_renderer_accel_new,libgtk),Ptr{GObject},()))

@gtktype GtkCellRendererCombo
GtkCellRendererCombo() = GtkCellRendererCombo( ccall((:gtk_cell_renderer_combo_new,libgtk),Ptr{GObject},()))

@gtktype GtkCellRendererPixbuf
GtkCellRendererPixbuf() = GtkCellRendererPixbuf( ccall((:gtk_cell_renderer_pixbuf_new,libgtk),Ptr{GObject},()))

@gtktype GtkCellRendererProgress
GtkCellRendererProgress() = GtkCellRendererProgress( ccall((:gtk_cell_renderer_progress_new,libgtk),Ptr{GObject},()))

@gtktype GtkCellRendererSpin
GtkCellRendererSpin() = GtkCellRendererSpin( ccall((:gtk_cell_renderer_spin_new,libgtk),Ptr{GObject},()))

@gtktype GtkCellRendererText
GtkCellRendererText() = GtkCellRendererText( ccall((:gtk_cell_renderer_text_new,libgtk),Ptr{GObject},()))

@gtktype GtkCellRendererToggle
GtkCellRendererToggle() = GtkCellRendererToggle( ccall((:gtk_cell_renderer_toggle_new,libgtk),Ptr{GObject},()))

@gtktype GtkCellRendererSpinner
GtkCellRendererSpinner() = GtkCellRendererSpinner( ccall((:gtk_cell_renderer_spinner_new,libgtk),Ptr{GObject},()))

### GtkTreeViewColumn

typealias KVMapping Union(Dict, ((TypeVar(:K),TypeVar(:V))...), Vector{(TypeVar(:K), TypeVar(:V))})

@gtktype GtkTreeViewColumn
GtkTreeViewColumn() = GtkTreeViewColumn( ccall((:gtk_tree_view_column_new,libgtk),Ptr{GObject},()))
function GtkTreeViewColumn(renderer::GtkCellRendererI, mapping::KVMapping)
    treeColumn = GtkTreeViewColumn()
    unshift!(treeColumn,renderer)
    for (k,v) in mapping
        add_attribute(treeColumn,renderer,string(k),v)
    end
    treeColumn
end

function GtkTreeViewColumn(title::String,renderer::GtkCellRendererI, mapping::KVMapping)
    setproperty!(GtkTreeViewColumn(renderer,mapping), :title, title)
end

empty!(treeColumn::GtkTreeViewColumn) =
    ccall((:gtk_tree_view_column_clear,libgtk), Void, (Ptr{GObject},),treeColumn)

function unshift!(treeColumn::GtkTreeViewColumn, renderer::GtkCellRendererI, expand::Bool=false)
    ccall((:gtk_tree_view_column_pack_start,libgtk), Void,
          (Ptr{GObject},Ptr{GObject},Cint),treeColumn,renderer,expand)
    treeColumn
end

function push!(treeColumn::GtkTreeViewColumn, renderer::GtkCellRendererI, expand::Bool=false)
    ccall((:gtk_tree_view_column_pack_end,libgtk), Void,
          (Ptr{GObject},Ptr{GObject},Cint),treeColumn,renderer,expand)
    treeColumn
end

add_attribute(treeColumn::GtkTreeViewColumn, renderer::GtkCellRendererI, 
              attribute::String, column::Integer) =
    ccall((:gtk_tree_view_column_add_attribute,libgtk),Void,
          (Ptr{GObject},Ptr{GObject},Ptr{Uint8},Cint),treeColumn,renderer,bytestring(attribute),column)

### GtkTreeSelection

@gtktype GtkTreeSelection

function selected(selection::GtkTreeSelection)
    model = mutable(Ptr{GtkTreeModelI})
    iter = GtkTreeIter()
    ret = ccall((:gtk_tree_selection_get_selected,libgtk),Cint,
          (Ptr{GObject},Ptr{Ptr{GtkTreeModelI}},Ptr{GtkTreeIter}),selection,model,&iter)
    convert(GtkTreeModelI, model[]), iter, bool(ret)
end

### GtkTreeView

@gtktype GtkTreeView
GtkTreeView() = GtkTreeView(ccall((:gtk_tree_view_new,libgtk),Ptr{GObject},()))
GtkTreeView(treeStore::GtkTreeModelI) = GtkTreeView(
   ccall((:gtk_tree_view_new_with_model,libgtk),Ptr{GObject},(Ptr{GObject},),treeStore))

function push!(treeView::GtkTreeView,treeColumns::GtkTreeViewColumn...)
    for col in treeColumns
        ccall((:gtk_tree_view_append_column,libgtk),Void,(Ptr{GObject},Ptr{GObject}),treeView,col)
    end
    treeView
end

### To be done

@gtktype GtkCellArea
@gtktype GtkCellAreaBox
@gtktype GtkCellAreaContext

@gtktype GtkTreeModelSort

@gtktype GtkCellView
@gtktype GtkIconView
