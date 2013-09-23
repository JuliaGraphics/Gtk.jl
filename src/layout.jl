abstract GtkLayout <: GtkWidget
#GtkGrid — Pack widgets in a rows and columns
#GtkAlignment — A widget which controls the alignment and size of its child
#GtkAspectFrame — A frame that constrains its child to a particular aspect ratio
#GtkBox — A container box
#GtkButtonBox — A container for arranging buttons
#GtkFixed — A container which allows you to position widgets at fixed coordinates
#GtkPaned — A widget with two adjustable panes
#GtkLayout — Infinite scrollable area containing child widgets and/or custom drawing
#GtkNotebook — A tabbed notebook container
#GtkExpander — A container which can hide its child
#GtkOverlay — A container which overlays widgets on top of each other
#GtkOrientable — An interface for flippable widgets

if gtk_version == 3
### GtkGrid was introduced in Gtk3 (replaces GtkTable)
type GtkGrid <: GtkLayout
    handle::Ptr{GtkWidget}
    function GtkGrid()
        gc_ref(new(ccall((:gtk_grid_new, libgtk), Ptr{GtkWidget}, ())))
    end
end

function getindex(grid::GtkGrid, i::Integer, j::Integer)
    x = ccall((:gtk_grid_get_child_at, libgtk), Ptr{GtkWidget}, (Ptr{GtkWidget}, Cint, Cint), grid, i, j)
    x == C_NULL && error("tried to get non-existent child at [$i $j]")
    return convert(GtkWidget, x)
end

setindex(grid::GtkGrid, x::child, i, j) = ccall((:gtk_grid_attach, libgtk), Void,
    (Ptr{GtkWidget}, Ptr{GtkWidget}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, first(j)-1, length(i), length(j))

function insert!(grid::GtkGrid, i::Integer, side::Symbol)
    if side == :left
        ccall((:gtk_grid_insert_column,libgtk), Void, (Ptr{GtkWidget}, Cint), grid, i-1)
    elseif side == :right
        ccall((:gtk_grid_insert_column,libgtk), Void, (Ptr{GtkWidget}, Cint), grid, i)
    elseif side == :top
        ccall((:gtk_grid_insert_row,libgtk), Void, (Ptr{GtkWidget}, Cint), grid, i-1)
    elseif side == :bottom
        ccall((:gtk_grid_insert_row,libgtk), Void, (Ptr{GtkWidget}, Cint), grid, i)
    else
        error(string("invalid GtkPositionType ",s))
    end
end

function insert!(grid::GtkGrid, i::GtkWidget, side::Symbol)
    ccall((:gtk_grid_insert_next_to,libgtk), Void, (Ptr{GtkWidget}, Cint), grid, i-1)
end
end

### GtkTable was deprecated in Gtk3 (replaced by GtkGrid)
type GtkTable <: GtkLayout
    handle::Ptr{GtkWidget}
    x::Cuint, y::Cuint
    function GtkTable(x, y, homogeneous=false)
        gc_ref(new(ccall((:gtk_table_new, libgtk), Ptr{GtkWidget}, (Cint, Cint, Cint), x, y, homogeneous)))
    end
end
setindex(grid::GtkGrid, x::child, i, j) = ccall((:gtk_table_attach_defaults, libgtk), Void,
    (Ptr{GtkWidget}, Ptr{GtkWidget}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, last(i)-1, first(j)-1, last(j)-1)

### GtkAlignment was deprecated in Gtk3 (replaced by properties "halign", "valign", and "margin")
type GtkAlignment <: GtkLayout
    handle::Ptr{GtkWidget}
    function GtkAlignment(xalign, yalign, xscale, yscale) # % of available space, 0<=a<=1
        gc_ref(new(ccall((:gtk_alignment_new, libgtk), Ptr{GtkWidget},
            (Cfloat, Cfloat, Cfloat, Cfloat), xalign, yalign, xscale, yscale)))
    end
end

### GtkAspectFrame
type GtkAspectFrame <: GtkLayout
    handle::Ptr{GtkWidget}
    function GtkAspectFrame(xalign, yalign, ratio) # % of available space, 0<=a<=1
        gc_ref(new(ccall((:gtk_aspect_frame_new, libgtk), Ptr{GtkWidget},
            (Cfloat, Cfloat, Cfloat, Cint), xalign, yalign, ratio, false)))
    end
    function GtkAspectFrame(xalign, yalign) # % of available space, 0<=a<=1. Uses the aspect ratio of the child
        gc_ref(new(ccall((:gtk_aspect_frame_new, libgtk), Ptr{GtkWidget},
            (Cfloat, Cfloat, Cfloat, Cint), xalign, yalign, 1., true)))
    end
end

### GtkBox
type GtkBox <: GtkLayout
    handle::Ptr{GtkWidget}
    if gtk_version == 3
        function GtkBox(vertical::Bool, spacing=0)
            gc_ref(new(ccall((:gtk_box_new, libgtk), Ptr{GtkWidget},
                (Cint, Cint), vertical, spacing)))
        end
    else
        function GtkBox(vertical::Bool, spacing=0)
            gc_ref(new(
                if vertical
                    ccall((:gtk_vbox_new, libgtk), Ptr{GtkWidget},
                        (Cint, Cint), false, spacing)
                else
                    ccall((:gtk_hbox_new, libgtk), Ptr{GtkWidget},
                        (Cint, Cint), false, spacing)
                end
                ))
        end
    end
end

### GtkButtonBox
type GtkButtonBox <: GtkLayout
    handle::Ptr{GtkWidget}
    if gtk_version == 3
        function GtkButtonBox(vertical::Bool)
            gc_ref(new(ccall((:gtk_button_box_new, libgtk), Ptr{GtkWidget},
                (Cint,), vertical)))
        end
    else
        function GtkButtonBox(vertical::Bool)
            gc_ref(new(
                if vertical
                    ccall((:gtk_vbutton_box_new, libgtk), Ptr{GtkWidget},())
                else
                    ccall((:gtk_hbutton_box_new, libgtk), Ptr{GtkWidget},())
                end
                ))
        end
    end
end

### GtkFixed TODO: this is a bad option, typically, so I'm leaving it out for now

### GtkPaned
type GtkPaned <: GtkLayout
    handle::Ptr{GtkWidget}
    if gtk_version == 3
        function GtkPaned(vertical::Bool)
            gc_ref(new(ccall((:gtk_paned_new, libgtk), Ptr{GtkWidget},
                (Cint, Cint), vertical, spacing)))
        end
    else
        function GtkPaned(vertical::Bool)
            gc_ref(new(
                if vertical
                    ccall((:gtk_vpaned_new, libgtk), Ptr{GtkWidget},())
                else
                    ccall((:gtk_hpaned_new, libgtk), Ptr{GtkWidget},())
                end
                ))
        end
    end
end

function getindex(pane::GtkPaned, i::Integer)
    if i == 1
        x = ccall((:gtk_paned_get_child1, libgtk), Ptr{GtkWidget}, (Ptr{GtkWidget},), pane)
    elseif i == 2
        x = ccall((:gtk_paned_get_child2, libgtk), Ptr{GtkWidget}, (Ptr{GtkWidget},), pane)
    else
        error("tried to get pane $i of GtkPane")
    end
    x == C_NULL && error("tried to get non-existent child at $i of GtkPane")
    return convert(GtkWidget, x)
end

function setindex(grid::GtkGrid, x::child, i)
    if i == 1
        ccall((:gtk_paned_add1, libgtk), Void, (Ptr{GtkWidget},), pane)
    elseif i == 2
        ccall((:gtk_paned_add2, libgtk), Void, (Ptr{GtkWidget},), pane)
    else
        error("tried to set pane $i of GtkPane")
    end
end

function setindex(grid::GtkGrid, x::child, i, resize::Bool, shrink::Bool=true)
    if i == 1
        ccall((:gtk_paned_pack1, libgtk), Void, (Ptr{GtkWidget},Cint,Cint), pane, resize, shrink)
    elseif i == 2
        ccall((:gtk_paned_pack2, libgtk), Void, (Ptr{GtkWidget},Cint,Cint), pane, resize, shrink)
    else
        error("tried to set pane $i of GtkPane")
    end
end

### GtkLayout

### GtkNotebook

### GtkExpander

### GtkOverlay

### GtkOrientable

