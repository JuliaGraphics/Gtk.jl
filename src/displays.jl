#https://developer.gnome.org/gtk2/stable/DisplayWidgets.html

#GtkImage — A widget displaying an image
#GtkProgressBar — A widget which indicates progress visually
#GtkStatusbar — Report messages of minor importance to the user
#GtkInfoBar — Report important messages to the user
#GtkStatusIcon — Display an icon in the system tray
#GtkSpinner — Show a spinner animation

struct RGB
    r::UInt8; g::UInt8; b::UInt8
    RGB(r, g, b) = new(r, g, b)
end
convert(::Type{RGB}, x::Unsigned) = RGB(UInt8(x), UInt8(x >> 8), UInt8(x >> 16))
convert(::Type{U}, x::RGB) where {U <: Unsigned} = convert(U, (x.r) | (x.g >> 8) | (x.b >> 16))

struct RGBA
    r::UInt8; g::UInt8; b::UInt8; a::UInt8
    RGBA(r, g, b, a) = new(r, g, b, a)
end
convert(::Type{RGBA}, x::Unsigned) = RGBA(UInt8(x), UInt8(x >> 8), UInt8(x >> 16), UInt8(x >> 24))
convert(::Type{U}, x::RGBA) where {U <: Unsigned} = convert(U, (x.r) | (x.g >> 8) | (x.b >> 16) | (x.a >> 24))

# Example constructors:
#MatrixStrided(width = 10, height = 20)
#MatrixStrided(p, width = 10, height = 20, rowstride = 30)
#MatrixStrided(p, rowstride = 20, nbytes = 100)
#MatrixStrided(p, width = 10, height = 20, rowstride = 30, nbytes = 100)
mutable struct MatrixStrided{T} <: AbstractMatrix{T}
    # immutable, except that we need the GC root for p
    p::Ptr{T}
    nbytes::Int
    rowstride::Int
    width::Int
    height::Int
    function MatrixStrided{T}(p::Ptr = C_NULL; nbytes = -1, rowstride = -1, width = -1, height = -1) where T
        if width == -1
            @assert(rowstride > 0, "MatrixStrided rowstride must be > 0 if width not given")
            width = div(rowstride, sizeof(T))
        end
        @assert(width > 0, "MatrixStrided width must be > 0")
        if height == -1
            @assert nbytes > 0 && rowstride > 0, "MatrixStrided nbytes and rowstride must be > 0 if height not given"
            height = div(nbytes + rowstride - 1, rowstride)
        end
        @assert(height > 0, "MatrixStrided height must be > 0")
        rowstride_req = width * sizeof(T)
        if rowstride == -1
            @assert(p == C_NULL, "MatrixStrided rowstride must be given")
            rowstride_preferred = (rowstride_req + 3) & ~3
            nbytes_preferred = rowstride_preferred * (height - 1) + width * sizeof(T)
            if p == C_NULL || nbytes > nbytes_preferred
                rowstride = rowstride_preferred
            else
                rowstride = rowstride_req
            end
        else
            @assert(rowstride >= rowstride_req, "MatrixStrided rowstride must be larger than the width")
        end
        nbytes_req = rowstride * (height - 1) + width * sizeof(T)
        if nbytes == -1
            nbytes = nbytes_req
        else
            @assert(nbytes >= nbytes_req, "MatrixStrided nbytes too small to contain array")
        end
        if p == C_NULL
            a = new{T}(g_malloc(nbytes), nbytes, rowstride, width, height)
            finalize(a, a -> g_free(a.p))
        else
            a = new{T}(p, nbytes, rowstride, width, height)
        end
        a
    end
end
MatrixStrided(p::Ptr{T}; kwargs...) where {T} = MatrixStrided{T}(p; kwargs...)
MatrixStrided(::Type{T}; kwargs...) where {T} = MatrixStrided{T}(; kwargs...)
function copy(a::MatrixStrided{T}) where T
    a2 = MatrixStrided{T}(a.nbytes, a.rowstride, a.width, a.height)
    unsafe_copy!(a2.p, a.p, a.nbytes)
    a2
end
function getindex(a::MatrixStrided{T}, x::Integer, y::Integer) where T
    @assert(1 <= minimum(x) && maximum(x) <= width(a), "MatrixStrided: x index must be inbounds")
    @assert(1 <= minimum(y) && maximum(y) <= height(a), "MatrixStrided: y index must be inbounds")
    return unsafe_load(a.p + (x - 1) * sizeof(T) + (y - 1) * a.rowstride)
end
function getindex(a::MatrixStrided{T}, x::Index, y::Index) where T
    @assert(1 <= minimum(x) && maximum(x) <= width(a), "MatrixStrided: x index must be inbounds")
    @assert(1 <= minimum(y) && maximum(y) <= height(a), "MatrixStrided: y index must be inbounds")
    z = Matrix{T}(length(x), length(y))
    rs = a.rowstride
    st = sizeof(T)
    p = a.p
    lenx = length(x)
    for zj = 1:length(y)
        j = (y[zj]-1) * rs
        for zi = 1:lenx
            i = (x[zi]-1) * st
            z[zi, zj] = unsafe_load(p + i + j)
        end
    end
    return z
end
function setindex!(a::MatrixStrided{T}, z, x::Integer, y::Integer) where T
    @assert(1 <= minimum(x) && maximum(x) <= width(a), "MatrixStrided: x index must be inbounds")
    @assert(1 <= minimum(y) && maximum(y) <= height(a), "MatrixStrided: y index must be inbounds")
    unsafe_store!(a.p + (x - 1) * sizeof(T) + (y - 1) * a.rowstride, convert(T, z))
    a
end
function setindex!(a::MatrixStrided{T}, z, x::Index, y::Index) where T
    @assert(1 <= minimum(x) && maximum(x) <= width(a), "MatrixStrided: x index must be inbounds")
    @assert(1 <= minimum(y) && maximum(y) <= height(a), "MatrixStrided: y index must be inbounds")
    rs = a.rowstride
    st = sizeof(T)
    p = a.p
    lenx = length(x)
    if !isa(z, AbstractMatrix)
        elem = convert(T, z)::T
        for zj = 1:length(y)
            j = (y[zj]-1) * rs + p
            for zi = 1:lenx
                i = (x[zi]-1) * st
                unsafe_store!(j + i, elem)
            end
        end
    else
        for zj = 1:length(y)
            j = (y[zj]-1) * rs + p
            for zi = 1:lenx
                i = (x[zi]-1) * st
                elem = convert(T, z[zi, zj])::T
                unsafe_store!(j + i, elem)
            end
        end
    end
    a
end
Base.fill!(a::MatrixStrided{T}, z) where {T} = setindex!(a, convert(T, z), 1:width(a), 1:height(a))
width(a::MatrixStrided) = a.width
height(a::MatrixStrided) = a.height
size(a::MatrixStrided, i::Integer) = (i == 1 ? width(a) : (i == 2 ? height(a) : 1))
size(a::MatrixStrided) = (width(a), height(a))
eltype(a::MatrixStrided{T}) where {T} = T
Base.ndims(::MatrixStrided) = 2
convert(::Type{P}, a::MatrixStrided) where {P <: Ptr} = convert(P, a.p)
bstride(a::MatrixStrided, i) = (i == 1 ? sizeof(eltype(a)) : (i == 2 ? a.rowstride : 0))
bstride(a, i) = stride(a, i) * sizeof(eltype(a))

# Example constructors:
#GdkPixbuf(filename = "", width = -1, height = -1, preserve_aspect_ratio = true)
#GdkPixbuf(resource_path = "", width = -1, height = -1, preserve_aspect_ratio = true)
#GdkPixbuf(stream = "", width = -1, height = -1, preserve_aspect_ratio = true)
#GdkPixbuf(xpm_data = [...])
#GdkPixbuf(data = [...], has_alpha = true)
#GdkPixbuf(width = 1, height = 1, has_alpha = true)
function GdkPixbufLeaf(; stream = nothing, resource_path = nothing, filename = nothing, xpm_data = nothing, inline_data = nothing, data = nothing,
        width = -1, height = -1, preserve_aspect_ratio = true, has_alpha = nothing)
    source_count = (stream !== nothing) + (resource_path !== nothing) + (filename !== nothing) +
        (xpm_data !== nothing) + (inline_data !== nothing) + (data !== nothing)
    @assert(source_count <= 1,
        "GdkPixbuf must have at most one stream, resource_path, filename, xpm_data, inline_data, or data argument")
    @assert(source_count == 0 || data !== nothing || has_alpha === nothing,
        "GdkPixbuf can only set the has-alpha property for new buffers")
    local pixbuf::Ptr{GObject}
    if stream !== nothing
        @assert(false, "not implemented yet")
    elseif resource_path !== nothing
        GError() do error_check
            if width == -1 && height == -1
                pixbuf = ccall((:gdk_pixbuf_new_from_resource, libgdk_pixbuf), Ptr{GObject}, (Ptr{UInt8}, Ptr{Ptr{GError}}), bytestring(resource_path), error_check)
            else
                pixbuf = ccall((:gdk_pixbuf_new_from_resource_at_scale, libgdk_pixbuf), Ptr{GObject},
                    (Ptr{UInt8}, Cint, Cint, Cint, Ptr{Ptr{GError}}), bytestring(resource_path), width, height, preserve_aspect_ratio, error_check)
            end
            return pixbuf !== C_NULL
        end
    elseif filename !== nothing
        GError() do error_check
            if width == -1 && height == -1
                pixbuf = ccall((:gdk_pixbuf_new_from_file, libgdk_pixbuf), Ptr{GObject}, (Ptr{UInt8}, Ptr{Ptr{GError}}), bytestring(filename), error_check)
            else
                pixbuf = ccall((:gdk_pixbuf_new_from_file_at_scale, libgdk_pixbuf), Ptr{GObject},
                    (Ptr{UInt8}, Cint, Cint, Cint, Ptr{Ptr{GError}}), bytestring(filename), width, height, preserve_aspect_ratio, error_check)
            end
            return pixbuf !== C_NULL
        end
    elseif xpm_data !== nothing
        @assert(width == -1 && height == -1, "GdkPixbuf cannot set the width/height of a image from xpm_data")
        GError() do error_check
            pixbuf = ccall((:gdk_pixbuf_new_from_xpm_data, libgdk_pixbuf), Ptr{GObject}, (Ptr{Ptr{Nothing}},), xpm_data)
            return pixbuf !== C_NULL
        end
    elseif inline_data !== nothing
        @assert(width == -1 && height == -1, "GdkPixbuf cannot set the width/height of a image from inline_data")
        GError() do error_check
            pixbuf = ccall((:gdk_pixbuf_new_from_inline, libgdk_pixbuf), Ptr{GObject}, (Cint, Ptr{Nothing}, Cint, Ptr{Ptr{GError}}), sizeof(inline_data), inline_data, true, error_check)
            return pixbuf !== C_NULL
        end
    elseif data !== nothing # RGB or RGBA array, packed however you wish
        @assert(width == -1 && height == -1, "GdkPixbuf cannot set the width/height of a image from data")
        alpha = convert(Bool, has_alpha)
        width = size(data, 1) * bstride(data, 1)/(3 + Int(alpha))
        height = size(data, 2)
        ref_data, deref_data = GLib.gc_ref_closure(data)
        pixbuf = ccall((:gdk_pixbuf_new_from_data, libgdk_pixbuf), Ptr{GObject},
            (Ptr{Nothing}, Cint, Cint, Cint, Cint, Cint, Cint, Ptr{Nothing}, Ptr{Nothing}),
            data, 0, alpha, 8, width, height, bstride(data, 2),
            deref_data, ref_data)
    else
        @assert(width != -1 && height != -1, "GdkPixbuf requires a width, height, and has_alpha to create an uninitialized pixbuf")
        alpha = convert(Bool, has_alpha)
        pixbuf = ccall((:gdk_pixbuf_new, libgdk_pixbuf), Ptr{GObject},
            (Cint, Cint, Cint, Cint, Cint), 0, alpha, 8, width, height)
    end
    return GdkPixbufLeaf(pixbuf)
end
#GdkPixbufLoader for new with type/mimetype
#GdkPixbuf(callback, stream, width = -1, height = -1, preserve_aspect_ratio = true)

copy(img::GdkPixbuf) = GdkPixbufLeaf(ccall((:gdk_pixbuf_copy, libgdk_pixbuf), Ptr{GObject}, (Ptr{GObject},), img))
slice(img::GdkPixbuf, x, y) = GdkPixbufLeaf(ccall((:gdk_pixbuf_new_subpixbuf, libgdk_pixbuf), Ptr{GObject},
    (Ptr{GObject}, Cint, Cint, Cint, Cint), img, first(x)-1, first(y)-1, length(x), length(y)))
width(img::GdkPixbuf) = ccall((:gdk_pixbuf_get_width, libgdk_pixbuf), Cint, (Ptr{GObject},), img)
height(img::GdkPixbuf) = ccall((:gdk_pixbuf_get_height, libgdk_pixbuf), Cint, (Ptr{GObject},), img)
size(a::GdkPixbuf, i::Integer) = (i == 1 ? width(a) : (i == 2 ? height(a) : 1))
size(a::GdkPixbuf) = (width(a), height(a))
Base.ndims(::GdkPixbuf) = 2
function bstride(img::GdkPixbuf, i)
    if i == 1
        convert(Cint, div(ccall((:gdk_pixbuf_get_bits_per_sample, libgdk_pixbuf), Cint, (Ptr{GObject},), img) *
            ccall((:gdk_pixbuf_get_n_channels, libgdk_pixbuf), Cint, (Ptr{GObject},), img) + 7, 8))
    elseif i == 2
        ccall((:gdk_pixbuf_get_rowstride, libgdk_pixbuf), Cint, (Ptr{GObject},), img)
    else
        convert(Cint, 0)
    end
end
function eltype(img::GdkPixbuf)
    #nbytes = stride(img, 1)
    nbytes = convert(Cint, div(ccall((:gdk_pixbuf_get_bits_per_sample, libgdk_pixbuf), Cint, (Ptr{GObject},), img) *
        ccall((:gdk_pixbuf_get_n_channels, libgdk_pixbuf), Cint, (Ptr{GObject},), img) + 7, 8))
    if nbytes == 3
        RGB
    elseif nbytes == 4
        RGBA
    else
        error("GdkPixbuf stride must be 3 or 4")
    end
end
function convert(::Type{MatrixStrided}, img::GdkPixbuf)
    MatrixStrided(
        convert(Ptr{eltype(img)}, ccall((:gdk_pixbuf_get_pixels, libgdk_pixbuf), Ptr{Nothing}, (Ptr{GObject},), img)),
        width = width(img), height = height(img),
        rowstride = ccall((:gdk_pixbuf_get_rowstride, libgdk_pixbuf), Cint, (Ptr{GObject},), img))
end
getindex(img::GdkPixbuf, x::Index, y::Index) = convert(MatrixStrided, img)[x, y]
setindex!(img::GdkPixbuf, pix, x::Index, y::Index) = setindex!(convert(MatrixStrided, img), pix, x, y)
Base.fill!(img::GdkPixbuf, pix) = fill!(convert(MatrixStrided, img), pix)

#TODO: image transformations, rotations, compositing

GtkImageLeaf(pixbuf::GdkPixbuf) = GtkImageLeaf(ccall((:gtk_image_new_from_pixbuf, libgtk), Ptr{GObject}, (Ptr{GObject},), pixbuf))
GtkImageLeaf(filename::AbstractString) = GtkImageLeaf(ccall((:gtk_image_new_from_file, libgtk), Ptr{GObject}, (Ptr{UInt8},), bytestring(filename)))

function GtkImageLeaf(; resource_path = nothing, filename = nothing, icon_name = nothing, stock_id = nothing, size::Symbol = :INVALID)
    source_count = (resource_path !== nothing) + (filename !== nothing) + (icon_name !== nothing) + (stock_id !== nothing)
    @assert(source_count <= 1,
        "GdkPixbuf must have at most one resource_path, filename, stock_id, or icon_name argument")
    local img::Ptr{GObject}
    if resource_path !== nothing
        img = ccall((:gtk_image_new_from_resource, libgtk), Ptr{GObject}, (Ptr{UInt8},), bytestring(resource_path))
    elseif filename !== nothing
        img = ccall((:gtk_image_new_from_file, libgtk), Ptr{GObject}, (Ptr{UInt8},), bytestring(filename))
    elseif icon_name !== nothing
        img = ccall((:gtk_image_new_from_icon_name, libgtk), Ptr{GObject}, (Ptr{UInt8}, Cint), bytestring(icon_name), getfield(GtkIconSize, size))
    elseif stock_id !== nothing
        img = ccall((:gtk_image_new_from_stock, libgtk), Ptr{GObject}, (Ptr{UInt8}, Cint), bytestring(stock_id), getfield(GtkIconSize, size))
    else
        img = ccall((:gtk_image_new, libgtk), Ptr{GObject}, ())
    end
    return GtkImageLeaf(img)
end
empty!(img::GtkImage) = ccall((:gtk_image_clear, libgtk), Nothing, (Ptr{GObject},), img)
GdkPixbufLeaf(img::GtkImage) = GdkPixbufLeaf(ccall((:gtk_image_get_pixbuf, libgtk), Ptr{GObject}, (Ptr{GObject},), img))

GtkProgressBarLeaf() = GtkProgressBarLeaf(ccall((:gtk_progress_bar_new, libgtk), Ptr{GObject}, ()))
pulse(progress::GtkProgressBar) = ccall((:gtk_progress_bar_pulse, libgtk), Nothing, (Ptr{GObject},), progress)

GtkSpinnerLeaf() = GtkSpinnerLeaf(ccall((:gtk_spinner_new, libgtk), Ptr{GObject}, ()))

start(spinner::GtkSpinner) = ccall((:gtk_spinner_start, libgtk), Nothing, (Ptr{GObject},), spinner)
stop(spinner::GtkSpinner) = ccall((:gtk_spinner_stop, libgtk), Nothing, (Ptr{GObject},), spinner)

GtkStatusbarLeaf() = GtkStatusbarLeaf(ccall((:gtk_statusbar_new, libgtk), Ptr{GObject}, ()))
context_id(status::GtkStatusbar, source) =
    ccall((:gtk_statusbar_get_context_id, libgtk), Cuint, (Ptr{GObject}, Ptr{UInt8}),
        status, bytestring(source))
context_id(status::GtkStatusbar, source::Integer) = source
push!(status::GtkStatusbar, context, text) =
    (ccall((:gtk_statusbar_push, libgtk), Cuint, (Ptr{GObject}, Cuint, Ptr{UInt8}),
        status, context_id(status, context), bytestring(text)); status)
pop!(status::GtkStatusbar, context) =
    ccall((:gtk_statusbar_pop, libgtk), Ptr{GObject}, (Ptr{GObject}, Cuint),
        status, context_id(status, context))
slice!(status::GtkStatusbar, context, message_id) =
    ccall((:gtk_statusbar_remove, libgtk), Ptr{GObject}, (Ptr{GObject}, Cuint, Cuint),
        status, context_id(status, context), message_id)
empty!(status::GtkStatusbar, context) =
    ccall((:gtk_statusbar_remove_all, libgtk), Ptr{GObject}, (Ptr{GObject}, Cuint, Cuint),
        status, context_id(status, context), context_id(context))

#GtkInfoBarLeaf() = GtkInfoBarLeaf(ccall((:gtk_info_bar_new, libgtk), Ptr{GObject}, ())

GtkStatusIconLeaf() = GtkStatusIconLeaf(ccall((:gtk_status_icon_new, libgtk), Ptr{GObject}, ()))
