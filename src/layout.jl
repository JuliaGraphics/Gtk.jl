#GtkAlignment — A widget which controls the alignment and size of its child
#GtkAspectFrame — A frame that constrains its child to a particular aspect ratio
#GtkBox — A container box
#GtkButtonBox — A container for arranging buttons
#GtkFixed — A container which allows you to position widgets at fixed coordinates
#GtkPaned — A widget with two adjustable panes
#GtkLayout — Infinite scrollable area containing child widgets at (x, y) locations
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

rangestep(r::AbstractRange) = step(r)
rangestep(::Integer) = 1
if libgtk_version >= v"3"
    ### GtkGrid was introduced in Gtk3 (replaces GtkTable)
    GtkGridLeaf() = GtkGridLeaf(ccall((:gtk_grid_new, libgtk), Ptr{GObject}, ()))

    function getindex(grid::GtkGrid, i::Integer, j::Integer)
        x = ccall((:gtk_grid_get_child_at, libgtk), Ptr{GObject}, (Ptr{GObject}, Cint, Cint), grid, i-1, j-1)
        x == C_NULL && error("tried to get non - existent child at [$i $j]")
        return convert(GtkWidget, x)
    end

    function setindex!(grid::GtkGrid, child, i::Union{T, AbstractRange{T}}, j::Union{R, AbstractRange{R}}) where {T <: Integer, R <: Integer}
        (rangestep(i) == 1 && rangestep(j) == 1) || throw(ArgumentError("cannot layout grid with range-step != 1"))
        ccall((:gtk_grid_attach, libgtk), Nothing,
            (Ptr{GObject}, Ptr{GObject}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, first(j)-1, length(i), length(j))
    end
    #TODO:
    # function setindex!{T <: Integer, R <: Integer}(grid::GtkGrid, child::Array, j::Union{T, Range{T}}, i::Union{R, Range1{R}})
    #    (rangestep(i) == 1 && rangestep(j) == 1) || throw(ArgumentError("cannot layout grid with range-step != 1"))
    #    ccall((:gtk_grid_attach, libgtk), Nothing,
    #        (Ptr{GObject}, Ptr{GObject}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, first(j)-1, length(i), length(j))
    # end

    function insert!(grid::GtkGrid, i::Integer, side::Symbol)
        if side == :left
            ccall((:gtk_grid_insert_column, libgtk), Nothing, (Ptr{GObject}, Cint), grid, i - 1)
        elseif side == :right
            ccall((:gtk_grid_insert_column, libgtk), Nothing, (Ptr{GObject}, Cint), grid, i)
        elseif side == :top
            ccall((:gtk_grid_insert_row, libgtk), Nothing, (Ptr{GObject}, Cint), grid, i - 1)
        elseif side == :bottom
            ccall((:gtk_grid_insert_row, libgtk), Nothing, (Ptr{GObject}, Cint), grid, i)
        else
            error(string("invalid GtkPositionType ", s))
        end
    end

    function deleteat!(grid::GtkGrid, i::Integer, side::Symbol)
        if side == :row
            ccall((:gtk_grid_remove_row, libgtk), Nothing, (Ptr{GObject}, Cint), grid, i)
        elseif side == :col
            ccall((:gtk_grid_remove_column, libgtk), Nothing, (Ptr{GObject}, Cint), grid, i)
        else
            error(string("invalid GtkPositionType ", s))
        end
    end

    function insert!(grid::GtkGrid, sibling, side::Symbol)
        ccall((:gtk_grid_insert_next_to, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}, Cint), grid, sibling, GtkPositionType.(side))
    end
end

if libgtk_version >= v"3.16.0"
    ### GtkGLArea was introduced inside Gtk3.16.0 (earlier it existed as a separate library)
    GtkGLAreaLeaf() = GtkGLAreaLeaf(ccall((:gtk_gl_area_new, libgtk), Ptr{GObject}, ()))
end

### GtkTable was deprecated in Gtk3 (replaced by GtkGrid)
GtkTableLeaf(x::Integer, y::Integer, homogeneous::Bool = false) = GtkTableLeaf(ccall((:gtk_table_new, libgtk), Ptr{GObject}, (Cint, Cint, Cint), x, y, homogeneous))
GtkTableLeaf(homogeneous::Bool = false) = GtkTableLeaf(0, 0, homogeneous)
function setindex!(grid::GtkTable, child, i::Union{T, AbstractRange{T}}, j::Union{R, AbstractRange{R}}) where {T <: Integer, R <: Integer}
    (rangestep(i) == 1 && rangestep(j) == 1) || throw(ArgumentError("cannot layout grid with range-step != 1"))
    ccall((:gtk_table_attach_defaults, libgtk), Nothing,
        (Ptr{GObject}, Ptr{GObject}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, last(i), first(j)-1, last(j))
end
#TODO:
# function setindex!{T <: Integer, R <: Integer}(grid::GtkTable, child::Array, i::Union{T, Range{T}}, j::Union{R, Range{R}})
#    (rangestep(i) == 1 && rangestep(j) == 1) || throw(ArgumentError("cannot layout grid with range-step != 1"))
#    ccall((:gtk_table_attach_defaults, libgtk), Nothing,
#        (Ptr{GObject}, Ptr{GObject}, Cint, Cint, Cint, Cint), grid, child, first(i)-1, last(i), first(j)-1, last(j))
# end

### GtkAlignment was deprecated in Gtk3 (replaced by properties "halign", "valign", and "margin")
GtkAlignmentLeaf(xalign, yalign, xscale, yscale) = # % of available space, 0 <= a <= 1
    GtkAlignmentLeaf(ccall((:gtk_alignment_new, libgtk), Ptr{GObject},
        (Cfloat, Cfloat, Cfloat, Cfloat), xalign, yalign, xscale, yscale))

### GtkFrame — A bin with a decorative frame and optional label
GtkFrameLeaf(label::AbstractStringLike) = GtkFrameLeaf(ccall((:gtk_frame_new, libgtk), Ptr{GObject},
        (Ptr{UInt8},), bytestring(label)))
GtkFrameLeaf() = GtkFrameLeaf(ccall((:gtk_frame_new, libgtk), Ptr{GObject},
        (Ptr{UInt8},), C_NULL))

### GtkAspectFrame
GtkAspectFrameLeaf(label, xalign, yalign, ratio) = # % of available space, 0 <= a <= 1
    GtkAspectFrameLeaf(ccall((:gtk_aspect_frame_new, libgtk), Ptr{GObject},
        (Ptr{UInt8}, Cfloat, Cfloat, Cfloat, Cint), bytestring(label), xalign, yalign, ratio, false))
GtkAspectFrameLeaf(label, xalign, yalign) = # % of available space, 0 <= a <= 1. Uses the aspect ratio of the child
    GtkAspectFrameLeaf(ccall((:gtk_aspect_frame_new, libgtk), Ptr{GObject},
        (Ptr{UInt8}, Cfloat, Cfloat, Cfloat, Cint), bytestring(label), xalign, yalign, 1., true))

### GtkBox
if libgtk_version >= v"3"
    GtkBoxLeaf(vertical::Bool, spacing = 0) =
        GtkBoxLeaf(ccall((:gtk_box_new, libgtk), Ptr{GObject},
            (Cint, Cint), vertical, spacing))
else
    GtkBoxLeaf(vertical::Bool, spacing = 0) =
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
if libgtk_version >= v"3"
    GtkButtonBoxLeaf(vertical::Bool) =
        GtkButtonBoxLeaf(ccall((:gtk_button_box_new, libgtk), Ptr{GObject},
            (Cint,), vertical))
else
     GtkButtonBoxLeaf(vertical::Bool) =
        GtkButtonBoxLeaf(
            if vertical
                ccall((:gtk_vbutton_box_new, libgtk), Ptr{GObject}, ())
            else
                ccall((:gtk_hbutton_box_new, libgtk), Ptr{GObject}, ())
            end
            )
end

### GtkFixed
# this is a bad option, so I'm leaving it out

### GtkPaned
if libgtk_version >= v"3"
    GtkPanedLeaf(vertical::Bool, spacing = 0) =
        GtkPanedLeaf(ccall((:gtk_paned_new, libgtk), Ptr{GObject},
            (Cint, Cint), vertical, spacing))
else
    GtkPanedLeaf(vertical::Bool) =
        GtkPanedLeaf(
            if vertical
                ccall((:gtk_vpaned_new, libgtk), Ptr{GObject}, ())
            else
                ccall((:gtk_hpaned_new, libgtk), Ptr{GObject}, ())
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
        ccall((:gtk_paned_add1, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}), pane, child)
    elseif i == 2
        ccall((:gtk_paned_add2, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}), pane, child)
    else
        error("tried to set pane $i of GtkPane")
    end
end

function setindex!(pane::GtkPaned, child, i::Integer, resize::Bool, shrink::Bool = true)
    if i == 1
        ccall((:gtk_paned_pack1, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}, Cint, Cint), pane, child, resize, shrink)
    elseif i == 2
        ccall((:gtk_paned_pack2, libgtk), Nothing, (Ptr{GObject}, Ptr{GObject}, Cint, Cint), pane, child, resize, shrink)
    else
        error("tried to set pane $i of GtkPane")
    end
end

### GtkLayout
function GtkLayoutLeaf(width::Real, height::Real)
    layout = ccall((:gtk_layout_new, libgtk), Ptr{GObject},
        (Ptr{Nothing}, Ptr{Nothing}), C_NULL, C_NULL)
    ccall((:gtk_layout_set_size, libgtk), Nothing, (Ptr{GObject}, Cuint, Cuint), layout, width, height)
    GtkLayoutLeaf(layout)
end
setindex!(layout::GtkLayout, child, i::Real, j::Real) = ccall((:gtk_layout_put, libgtk), Nothing,
    (Ptr{GObject}, Ptr{GObject}, Cint, Cint), layout, child, i, j)
function size(layout::GtkLayout)
    sz = Vector{Cuint}(undef, 2)
    ccall((:gtk_layout_get_size, libgtk), Nothing,
        (Ptr{GObject}, Ptr{Cuint}, Ptr{Cuint}), layout, pointer(sz, 1), pointer(sz, 2))
    (sz[1], sz[2])
end
width(layout::GtkLayout) = size(layout)[1]
height(layout::GtkLayout) = size(layout)[2]

### GtkExpander
GtkExpanderLeaf(title::AbstractStringLike) =
    GtkExpanderLeaf(ccall((:gtk_expander_new, libgtk), Ptr{GObject},
        (Ptr{UInt8},), bytestring(title)))

### GtkNotebook
GtkNotebookLeaf() = GtkNotebookLeaf(ccall((:gtk_notebook_new, libgtk), Ptr{GObject}, ()))
function insert!(w::GtkNotebook, position::Integer, x::Union{GtkWidget, AbstractStringLike}, label::Union{GtkWidget, AbstractStringLike})
    ccall((:gtk_notebook_insert_page, libgtk), Cint,
        (Ptr{GObject}, Ptr{GObject}, Ptr{GObject}, Cint),
        w, x, label, position - 1) + 1
    w
end
function pushfirst!(w::GtkNotebook, x::Union{GtkWidget, AbstractStringLike}, label::Union{GtkWidget, AbstractStringLike})
    ccall((:gtk_notebook_prepend_page, libgtk), Cint,
        (Ptr{GObject}, Ptr{GObject}, Ptr{GObject}),
        w, x, label) + 1
    w
end
function push!(w::GtkNotebook, x::Union{GtkWidget, AbstractStringLike}, label::Union{GtkWidget, AbstractStringLike})
    ccall((:gtk_notebook_append_page, libgtk), Cint,
        (Ptr{GObject}, Ptr{GObject}, Ptr{GObject}),
        w, x, label) + 1
    w
end
function splice!(w::GtkNotebook, i::Integer)
    ccall((:gtk_notebook_remove_page, libgtk), Cint,
        (Ptr{GObject}, Cint), w, i - 1)
    w
end

pagenumber(w::GtkNotebook, child::GtkWidget) =
    ccall((:gtk_notebook_page_num, libgtk), Cint, (Ptr{GObject}, Ptr{GObject}), w, child)

### GtkOverlay
if libgtk_version >= v"3"
    GtkOverlayLeaf() = GtkOverlayLeaf(ccall((:gtk_overlay_new, libgtk), Ptr{GObject}, () ))
    GtkOverlayLeaf(w::GtkWidget) = invoke(push!, (GtkContainer,), GtkOverlayLeaf(), w)
    function push!(w::GtkOverlay, x::GtkWidget)
        ccall((:gtk_overlay_add_overlay, libgtk), Cint,
            (Ptr{GObject}, Ptr{GObject}), w, x)
    end
end
