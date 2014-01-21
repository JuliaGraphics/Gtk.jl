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

@gtktype GtkListStore
function GtkListStore{D}(types::NTuple{D,Symbol})
    gtypes = GLib.GType[]
    for t in types
        push!(gtypes, GLib.g_type_from_name(t))
    end
    handle = ccall((:gtk_list_store_newv,libgtk),Ptr{GObject},(Cint,Ptr{GLib.GType}), length(types), gtypes)
    GtkListStore(handle)
end

function push!(listStore::GtkListStore, iter::GtkTreeIter)
    ccall((:gtk_list_store_append,libgtk),Void,(Ptr{GObject},Ptr{GtkTreeIter}), listStore, &iter)
    listStore
end

@gtktype GtkCellRenderer
GtkCellRenderer() = GtkCellRenderer( ccall((:gtk_cell_renderer_text_new,libgtk),Ptr{GObject},()))
	
@gtktype GtkTreeViewColumn
GtkTreeViewColumn() = GtkTreeViewColumn( ccall((:gtk_tree_view_column_new,libgtk),Ptr{GObject},()))

pack_start(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer, expand::Bool=false) = 
    ccall((:gtk_tree_view_column_pack_start,libgtk), Void,
          (Ptr{GObject},Ptr{GObject},Bool),treeColumn,renderer,expand)
		  
pack_end(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer, expand::Bool=false) = 
    ccall((:gtk_tree_view_column_pack_end,libgtk), Void,
          (Ptr{GObject},Ptr{GObject},Bool),treeColumn,renderer,expand)

add_attribute(treeColumn::GtkTreeViewColumn, renderer::GtkCellRenderer, attribute::String, column) = 
    ccall((:gtk_tree_view_column_add_attribute,libgtk),Void,
          (Ptr{GObject},Ptr{GObject},Ptr{Uint8},Cint),treeColumn,renderer,bytestring(attribute),int32(column))

@gtktype GtkTreeView
GtkTreeView() = GtkTreeView(ccall((:gtk_tree_view_new,libgtk),Ptr{GObject},()))
GtkTreeView(listStore::GtkListStore) = GtkTreeView(
   ccall((:gtk_tree_view_new_with_model,libgtk),Ptr{GObject},(Ptr{GObject},),listStore))
   
function push!(treeView::GtkTreeView,treeColumn::GtkTreeViewColumn)
  ccall((:gtk_tree_view_append_column,libgtk),Void,(Ptr{GObject},Ptr{GObject}),treeView,treeColumn)
  treeView
end