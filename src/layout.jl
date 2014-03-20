#GtkAlignment — A widget which controls the alignment and size of its child
#GtkAspectFrame — A frame that constrains its child to a particular aspect ratio
#GtkBox — A container box
#GtkButtonBox — A container for arranging buttons
#GtkFixed — A container which allows you to position widgets at fixed coordinates
#GtkPaned — A widget with two adjustable panes
#GtkLayout — Infinite scrollable area containing child widgets at (x,y) locations
#GtkNotebook — A tabbed notebook container
#GtkExpander — A container which can hide its child

# Introduced in Gtk3
#GtkGrid — Pack widgets in a rows and columns
#GtkRevealer — Hide and show with animation
#GtkListBox — A list container
#GtkStack — A stacking container
#GtkStackSwitcher — A controller for GtkStack
#GtkHeaderBar — A box with a centered child
#GtkOverlay — A container which overlays widgets on top of each other
#GtkExpander — A container which can hide its child
#GtkOrientable — An interface for flippable widgets

if gtk_version == 3
    ### GtkGrid was introduced in Gtk3 (replaces GtkTable)
    @gtktype GtkGrid
    GtkGridLeaf() = GtkGridLeaf(ccall((:gtk_grid_new, libgtk), Ptr{GObject}, ()))

    function getindex(grid::GtkGrid, i::Integer, j::Integer)
        x = ccall((:gtk_grid_get_child_at, libgtk), Ptr{GObject}, (Ptr{GObject}, Cint, Cint), grid, i-1, j-1)
        x == C_NULL && error("tried to get non-existent child at [$i $j]")
        return convert(GtkWidget, x)
    end

    setindex!{T<:Integer,R<:Integer}(grid::GtkGrid, child, i::Union(T,Range1{T}), j::Union(R,Range1{R})) = ccall((:gtk_grid_attach, libgtk), Void,
        (Ptr{GObject}, Ptr{GObject}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, first(j)-1, length(i), length(j))
    #TODO:
    # setindex!{T<:Integer,R<:Integer}(grid::GtkGrid, child::Array, j::Union(T,Range1{T}), i::Union(R,Range1{R})) = ccall((:gtk_grid_attach, libgtk), Void,
    #    (Ptr{GObject}, Ptr{GObject}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, first(j)-1, length(i), length(j))

    function insert!(grid::GtkGrid, i::Integer, side::Symbol)
        if side == :left
            ccall((:gtk_grid_insert_column,libgtk), Void, (Ptr{GObject}, Cint), grid, i-1)
        elseif side == :right
            ccall((:gtk_grid_insert_column,libgtk), Void, (Ptr{GObject}, Cint), grid, i)
        elseif side == :top
            ccall((:gtk_grid_insert_row,libgtk), Void, (Ptr{GObject}, Cint), grid, i-1)
        elseif side == :bottom
            ccall((:gtk_grid_insert_row,libgtk), Void, (Ptr{GObject}, Cint), grid, i)
        else
            error(string("invalid GtkPositionType ",s))
        end
    end

    function insert!(grid::GtkGrid, sibling, side::Symbol)
        ccall((:gtk_grid_insert_next_to,libgtk), Void, (Ptr{GObject}, Ptr{GObject}, Cint), grid, sibling, GtkPositionType.(side))
    end
else
    type GtkGrid end
    GtkGridLeaf(x...) = error("GtkGrid is not available until Gtk3.0")
end

### GtkTable was deprecated in Gtk3 (replaced by GtkGrid)
@gtktype GtkTable
GtkTableLeaf(x::Integer, y::Integer, homogeneous::Bool=false) = GtkTableLeaf(ccall((:gtk_table_new, libgtk), Ptr{GObject}, (Cint, Cint, Cint), x, y, homogeneous))
GtkTableLeaf(homogeneous::Bool=false) = GtkTableLeaf(0,0,homogeneous)
setindex!{T<:Integer,R<:Integer}(grid::GtkTable, child, i::Union(T,Range1{T}), j::Union(R,Range1{R})) =
    ccall((:gtk_table_attach_defaults, libgtk), Void,
        (Ptr{GObject}, Ptr{GObject}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, last(i), first(j)-1, last(j))
#TODO:
# setindex!{T<:Integer,R<:Integer}(grid::GtkTable, child::Array, i::Union(T,Range1{T}), j::Union(R,Range1{R})) =
#    ccall((:gtk_table_attach_defaults, libgtk), Void,
#        (Ptr{GObject}, Ptr{GObject}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, last(i), first(j)-1, last(j))

### GtkAlignment was deprecated in Gtk3 (replaced by properties "halign", "valign", and "margin")
@gtktype GtkAlignment
GtkAlignmentLeaf(xalign, yalign, xscale, yscale) = # % of available space, 0<=a<=1
    GtkAlignmentLeaf(ccall((:gtk_alignment_new, libgtk), Ptr{GObject},
        (Cfloat, Cfloat, Cfloat, Cfloat), xalign, yalign, xscale, yscale))

### GtkFrame — A bin with a decorative frame and optional label
@gtktype GtkFrame
GtkFrameLeaf(label::StringLike) = GtkFrameLeaf(ccall((:gtk_frame_new, libgtk), Ptr{GObject},
        (Ptr{Uint8},), bytestring(label)))
GtkFrameLeaf() = GtkFrameLeaf(ccall((:gtk_frame_new, libgtk), Ptr{GObject},
        (Ptr{Uint8},), C_NULL))

### GtkAspectFrame
@gtktype GtkAspectFrame
GtkAspectFrameLeaf(label, xalign, yalign, ratio) = # % of available space, 0<=a<=1
    GtkAspectFrameLeaf(ccall((:gtk_aspect_frame_new, libgtk), Ptr{GObject},
        (Ptr{Uint8}, Cfloat, Cfloat, Cfloat, Cint), bytestring(label), xalign, yalign, ratio, false))
GtkAspectFrameLeaf(label, xalign, yalign) = # % of available space, 0<=a<=1. Uses the aspect ratio of the child
    GtkAspectFrameLeaf(ccall((:gtk_aspect_frame_new, libgtk), Ptr{GObject},
        (Ptr{Uint8}, Cfloat, Cfloat, Cfloat, Cint), bytestring(label), xalign, yalign, 1., true))

### GtkBox
@gtktype GtkBox
if gtk_version == 3
    GtkBoxLeaf(vertical::Bool, spacing=0) =
        GtkBoxLeaf(ccall((:gtk_box_new, libgtk), Ptr{GObject},
            (Cint, Cint), vertical, spacing))
else
    GtkBoxLeaf(vertical::Bool, spacing=0) =
        GtkBoxLeaf(
            if vertical
                ccall((:gtk_vbox_new, libgtk), Ptr{GObject},
                    (Cint, Cint), false, spacing)
            else
                ccall((:gtk_hbox_new, libgtk), Ptr{GObject},
                    (Cint, Cint), false, spacing)
            end
            )
end

### GtkButtonBox
@gtktype GtkButtonBox
if gtk_version == 3
    GtkButtonBoxLeaf(vertical::Bool) =
        GtkButtonBoxLeaf(ccall((:gtk_button_box_new, libgtk), Ptr{GObject},
            (Cint,), vertical))
else
     GtkButtonBoxLeaf(vertical::Bool) =
        GtkButtonBoxLeaf(
            if vertical
                ccall((:gtk_vbutton_box_new, libgtk), Ptr{GObject},())
            else
                ccall((:gtk_hbutton_box_new, libgtk), Ptr{GObject},())
            end
            )
end

### GtkFixed
# this is a bad option, so I'm leaving it out

### GtkPaned
@gtktype GtkPaned
if gtk_version == 3
    GtkPanedLeaf(vertical::Bool, spacing=0) =
        GtkPanedLeaf(ccall((:gtk_paned_new, libgtk), Ptr{GObject},
            (Cint, Cint), vertical, spacing))
else
    GtkPanedLeaf(vertical::Bool) =
        GtkPanedLeaf(
            if vertical
                ccall((:gtk_vpaned_new, libgtk), Ptr{GObject},())
            else
                ccall((:gtk_hpaned_new, libgtk), Ptr{GObject},())
            end
            )
end
function getindex(pane::GtkPaned, i::Integer)
    if i == 1
        x = ccall((:gtk_paned_get_child1, libgtk), Ptr{GObject}, (Ptr{GObject},), pane)
    elseif i == 2
        x = ccall((:gtk_paned_get_child2, libgtk), Ptr{GObject}, (Ptr{GObject},), pane)
    else
        error("tried to get pane $i of GtkPane")
    end
    x == C_NULL && error("tried to get non-existent child at $i of GtkPane")
    return convert(GtkWidget, x)
end

function setindex!(pane::GtkPaned, child, i::Integer)
    if i == 1
        ccall((:gtk_paned_add1, libgtk), Void, (Ptr{GObject},Ptr{GObject}), pane, child)
    elseif i == 2
        ccall((:gtk_paned_add2, libgtk), Void, (Ptr{GObject},Ptr{GObject}), pane, child)
    else
        error("tried to set pane $i of GtkPane")
    end
end

function setindex!(pane::GtkPaned, child, i::Integer, resize::Bool, shrink::Bool=true)
    if i == 1
        ccall((:gtk_paned_pack1, libgtk), Void, (Ptr{GObject},Ptr{GObject},Cint,Cint), pane, child, resize, shrink)
    elseif i == 2
        ccall((:gtk_paned_pack2, libgtk), Void, (Ptr{GObject},Ptr{GObject},Cint,Cint), pane, child, resize, shrink)
    else
        error("tried to set pane $i of GtkPane")
    end
end

### GtkLayout
@gtktype GtkLayout
function GtkLayoutLeaf(width::Real, height::Real)
    layout = ccall((:gtk_layout_new, libgtk), Ptr{GObject},
        (Ptr{Void},Ptr{Void}), C_NULL, C_NULL)
    ccall((:gtk_layout_set_size,libgtk),Void,(Ptr{GObject},Cuint,Cuint),layout,width,height)
    GtkLayoutLeaf(layout)
end
setindex!(layout::GtkLayout, child, i::Real, j::Real) = ccall((:gtk_layout_put,libgtk),Void,
    (Ptr{GObject},Ptr{GObject},Cint,Cint), layout, child, i, j)
function size(layout::GtkLayout)
    sz = Array(Cuint,2)
    ccall((:gtk_layout_get_size,libgtk),Void,
        (Ptr{GObject},Ptr{Cuint},Ptr{Cuint}),layout,pointer(sz,1),pointer(sz,2))
    (sz[1],sz[2])
end
width(layout::GtkLayout) = size(layout)[1]
height(layout::GtkLayout) = size(layout)[2]

### GtkExpander
@gtktype GtkExpander
GtkExpanderLeaf(title::StringLike) =
    GtkExpanderLeaf(ccall((:gtk_expander_new, libgtk), Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))

### GtkNotebook
@gtktype GtkNotebook
GtkNotebookLeaf() = GtkNotebookLeaf(ccall((:gtk_notebook_new, libgtk), Ptr{GObject},()))
function insert!(w::GtkNotebook, position::Integer, x::Union(GtkWidget,StringLike), label::Union(GtkWidget,StringLike))
    ccall((:gtk_notebook_insert_page,libgtk), Cint,
        (Ptr{GObject}, Ptr{GObject}, Ptr{GObject}, Cint),
        w, x, label, position-1)+1
    w
end
function unshift!(w::GtkNotebook, x::Union(GtkWidget,StringLike), label::Union(GtkWidget,StringLike))
    ccall((:gtk_notebook_prepend_page,libgtk), Cint,
        (Ptr{GObject}, Ptr{GObject}, Ptr{GObject}),
        w, x, label)+1
    w
end
function push!(w::GtkNotebook, x::Union(GtkWidget,StringLike), label::Union(GtkWidget,StringLike))
    ccall((:gtk_notebook_append_page,libgtk), Cint,
        (Ptr{GObject}, Ptr{GObject}, Ptr{GObject}),
        w, x, label)+1
    w
end
function splice!(w::GtkNotebook, i::Integer)
    ccall((:gtk_notebook_remove_page,libgtk), Cint,
        (Ptr{GObject}, Cint), w, i-1)
    w
end

pagenumber(w::GtkNotebook, child::GtkWidget) =
    ccall((:gtk_notebook_page_num,libgtk), Cint, (Ptr{GObject}, Ptr{GObject}), w, child)

### GtkOverlay
if gtk_version == 3
    @gtktype GtkOverlay # this is a GtkBin, except it behaves more like a container
    GtkOverlayLeaf() = GtkOverlayLeaf(ccall((:gtk_overlay_new, libgtk), Ptr{GObject},
        (Ptr{Uint8},), bytestring(title)))
    GtkOverlayLeaf(w::GtkWidget) = invoke(push!, (GtkContainer,), GtkOverlayLeaf(), w)
    function push!(w::GtkOverlay, x::GtkWidget)
        ccall((:gtk_overlay_add_overlay,libgtk), Cint,
            (Ptr{GObject}, Ptr{GObject}), w, x)
    end
else
    type GtkOverlay end
    GtkOverlayLeaf(x...) = error("GtkOverlay is not available until Gtk3.2")
end

