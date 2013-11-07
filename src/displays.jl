#https://developer.gnome.org/gtk2/stable/DisplayWidgets.html

#GtkImage — A widget displaying an image
#GtkProgressBar — A widget which indicates progress visually
#GtkStatusbar — Report messages of minor importance to the user
#GtkInfoBar — Report important messages to the user
#GtkStatusIcon — Display an icon in the system tray
#GtkSpinner — Show a spinner animation

immutable RGB
    r::Uint8; g::Uint8; b::Uint8
end
convert(::Type{RGB},x::Unsigned) = RGB(uint8(x),uint8(x>>8),uint8(x>>16))
convert{U<:Unsigned}(::Type{U},x::RGB) = convert(U,(x.r)|(x.g>>8)|(x.b>>16))

immutable RGBA
    r::Uint8; g::Uint8; b::Uint8; a::Uint8
end
convert(::Type{RGBA},x::Unsigned) = RGBA(uint8(x),uint8(x>>8),uint8(x>>16),uint8(x>>24))
convert{U<:Unsigned}(::Type{U},x::RGBA) = convert(U,(x.r)|(x.g>>8)|(x.b>>16)|(x.a>>24))

# Example constructors:
#MatrixStrided(width=10,height=20)
#MatrixStrided(p, width=10,height=20,rowstride=30)
#MatrixStrided(p, rowstride=20,nbytes=100)
#MatrixStrided(p, width=10,height=20,rowstride=30,nbytes=100)
type MatrixStrided{T} <: AbstractArray{T,2}
    p::Ptr{T}
    nbytes::Int
    rowstride::Int
    width::Int
    height::Int
    function MatrixStrided(p::Ptr=C_NULL; nbytes=-1, rowstride=-1, width=-1, height=-1)
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
        rowstride_req = width*sizeof(T)
        if rowstride == -1
            @assert(p == C_NULL, "MatrixStrided rowstride must be given")
            rowstride_preferred = (rowstride_req + 3) & ~3
            nbytes_preferred = rowstride_preferred * (height-1) + width * sizeof(T)
            if p == C_NULL || nbytes > nbytes_preferred
                rowstride = rowstride_preferred
            else
                rowstride = rowstride_req
            end
        else
            @assert(rowstride >= rowstride_req, "MatrixStrided rowstride must be larger than the width")
        end
        nbytes_req = rowstride * (height-1) + width * sizeof(T)
        if nbytes == -1
            nbytes = nbytes_req
        else
            @assert(nbytes >= nbytes_req, "MatrixStrided nbytes too small to contain array")
        end
        if p == C_NULL
            a = new(c_malloc(nbytes),nbytes,rowstride,width,height)
            finalize(a, (a)->c_free(a.p))
        else
            a = new(p,nbytes,rowstride,width,height)
        end
        a
    end
end
MatrixStrided{T}(p::Ptr{T};kwargs...) = MatrixStrided{T}(p;kwargs...)
MatrixStrided{T}(::Type{T};kwargs...) = MatrixStrided{T}(;kwargs...)
function copy{T}(a::MatrixStrided{T})
    a2 = MatrixStrided{T}(a.nbytes, a.rowstride, a.width, a.height)
    unsafe_copy!(a2.p, a.p, a.nbytes)
    a2
end
Base.step(::Integer) = 1
function getindex{T}(a::MatrixStrided{T},x::RangeIndex,y::RangeIndex)
    i1 = (first(x)-1)*sizeof(T)+1
    @assert(1 <= i1 <= a.rowstride, "MatrixStrided: x1 index must be inbounds")
    j1 = (first(y)-1)*a.rowstride
    @assert(0 <= j1 && j1+i1 <= a.nbytes, "MatrixStrided: y1 index must be inbounds")
    if isa(x,Integer) && isa(y,Integer)
        return unsafe_load(a.p+i1+j1)
    end

    i2 = (last(x)-1)*sizeof(T)+1
    @assert(1 <= i2 <= a.rowstride, "MatrixStrided: x2 index must be inbounds")
    @assert(j1+i2 <= a.nbytes, "MatrixStrided: y1 index must be inbounds")
    j2 = (last(y)-1)*a.rowstride
    @assert(0 <= j2 && j2+max(i1,i2) <= a.nbytes, "MatrixStrided: y2 index must be inbounds")
    
    z = Array(T,length(x),length(y))
    zj = 0
    for j = j1:step(y)*a.rowstride:j2
        zj += 1
        zi = 1
        for i = i1:step(x)*sizeof(T):i2
            zi += 1
            z[zj,zi] = unsafe_load(a.p+i+j)
        end
    end
    return z
end
function setindex!{T}(a::MatrixStrided{T},z,x::RangeIndex,y::RangeIndex)
    i1 = (first(x)-1)*sizeof(T)+1
    @assert(1 <= i1 <= a.rowstride, "MatrixStrided: x1 index must be inbounds")
    j1 = (first(y)-1)*a.rowstride
    @assert(0 <= j1 && j1+i1 <= a.nbytes, "MatrixStrided: y1 index must be inbounds")
    if isa(x,Integer) && isa(y,Integer)
        unsafe_store!(a.p+i1+j1,convert(T,z))
        return a
    end

    i2 = (last(x)-1)*sizeof(T)+1
    @assert(1 <= i2 <= a.rowstride, "MatrixStrided: x2 index must be inbounds")
    @assert(j1+i2 <= a.nbytes, "MatrixStrided: y1 index must be inbounds")
    j2 = (last(y)-1)*a.rowstride
    @assert(0 <= j2 && j2+max(i1,i2) <= a.nbytes, "MatrixStrided: y2 index must be inbounds")
    
    zj = 1
    for j = j1:step(y)*a.rowstride:j2
        zj += 1
        zi = 1
        for i = i1:step(x)*sizeof(T):i2
            zi += 1
            elem::T = isa(z,T) ? z::T : convert(T,z[zj,zi])
            unsafe_store!(a.p+i+j,elem)
        end
    end
    return a
end
stride(a::MatrixStrided,i) = (i == 1 ? 1 : (i == 2 ? a.rowstride : 0))
width(a::MatrixStrided) = a.width
height(a::MatrixStrided) = a.height
size(a::MatrixStrided,i::Integer) = (i == 1 ? width(a) : (i == 2 ? height(a) : 1))
size(a::MatrixStrided) = (width(a),height(a))
eltype{T}(a::MatrixStrided{T}) = T
Base.ndims(::MatrixStrided) = 2


@GType GdkPixbuf

# Example constructors:
#GdkPixbuf(filename="", width=-1, height=-1, preserve_aspect_ratio=true)
#GdkPixbuf(resource_path="", width=-1, height=-1, preserve_aspect_ratio=true)
#GdkPixbuf(stream="", width=-1, height=-1, preserve_aspect_ratio=true)
#GdkPixbuf(xpm_data=[...])
#GdkPixbuf(data=[...],has_alpha=true)
#GdkPixbuf(width=1,height=1,has_alpha=true)
function GdkPixbuf(;stream=nothing,resource_path=nothing,filename=nothing,xpm_data=nothing,inline_data=nothing,data=nothing,
        width=-1,height=-1,preserve_aspect_ratio=true,has_alpha=nothing)
    source_count = (stream!==nothing) + (resource_path!==nothing) + (filename!==nothing) +
        (xpm_data!==nothing) + (inline_data!==nothing) + (data!==nothing)
    @assert(source_count <= 1,
        "GdkPixbuf must have at most one stream, resource_path, filename, xpm_data, inline_data, or data argument")
    @assert(source_count==0 || data!==nothing || has_alpha===nothing,
        "GdkPixbuf can only set the has-alpha property for new buffers")
    local pixbuf::Ptr{GObject}
    if stream !== nothing
        @assert(false, "not implemented yet")
    elseif resource_path !== nothing
        GError() do error_check
            if width == -1 && height == -1
                pixbuf = ccall((:gdk_pixbuf_new_from_resource,libgdk),Ptr{GObject},(Ptr{Uint8},Ptr{Ptr{GError}}),bytestring(resource_path),error_check)
            else
                pixbuf = ccall((:gdk_pixbuf_new_from_resource_at_scale,libgdk),Ptr{GObject},
                    (Ptr{Uint8},Cint,Cint,Cint,Ptr{Ptr{GError}}),bytestring(resource_path),width,height,preserve_aspect_ratio,error_check)
            end
            return pixbuf !== C_NULL
        end
    elseif filename !== nothing
        GError() do error_check
            if width == -1 && height == -1
                pixbuf = ccall((:gdk_pixbuf_new_from_file,libgdk),Ptr{GObject},(Ptr{Uint8},Ptr{Ptr{GError}}),bytestring(filename),error_check)
            else
                pixbuf = ccall((:gdk_pixbuf_new_from_file_at_scale,libgdk),Ptr{GObject},
                    (Ptr{Uint8},Cint,Cint,Cint,Ptr{Ptr{GError}}),bytestring(filename),width,height,preserve_aspect_ratio,error_check)
            end
            return pixbuf !== C_NULL
        end
    elseif xmp_data !== nothing
        @assert(width==-1 && height==-1,"GdkPixbuf cannot set the width/height of a image from xpm_data")
        GError() do error_check
            pixbuf = ccall((:gdk_pixbuf_new_from_xpm_data,libgdk),Ptr{GObject},(Ptr{Ptr{Uint8}},),xpm_data)
            return pixbuf !== C_NULL
        end
    elseif inline_data !== nothing
        @assert(width==-1 && height==-1,"GdkPixbuf cannot set the width/height of a image from inline_data")
        GError() do error_check
            pixbuf = ccall((:gdk_pixbuf_new_from_inline,libgdk),Ptr{GObject},(Cint,Ptr{Uint8},Cint,Ptr{Ptr{GError}}),sizeof(inline_data),inline_data,true,error_check)
            return pixbuf !== C_NULL
        end
    elseif data !== nothing
        @assert(width==-1 && height==-1,"GdkPixbuf cannot set the width/height of a image from data")
        pixbuf = ccall((:gdk_pixbuf_new_from_data,libgdk),Ptr{GObject},
            (Ptr{Uint8},Cint,Cint,Cint,Cint,Cint,Cint,Ptr{Void},Any),
            data,0,convert(Bool,has_alpha),8,width,height,size(data,1)*sizeof(eltype(data)),
            gc_ref_closure(data),data)
    else
        @assert(width!=-1 && height!=-1,"GdkPixbuf requires a width and height to create an uninitialized pixbuf")
        pixbuf = ccall((:gdk_pixbuf_new,libgdk),Ptr{GObject},
            (Cint,Cint,Cint,Cint,Cint),0,convert(Bool,has_alpha),8,width,height)
    end
    return GdkPixbuf(pixbuf)
end
#GdkPixbufLoader for new with type/mimetype
#GdkPixbuf(callback, stream, width=-1, height=-1, preserve_aspect_ratio=true)

copy(img::GdkPixbuf) = GdkPixbuf(ccall((:gdk_pixbuf_copy,libgdk),Ptr{GObject},(Ptr{GObject},),img))
slice(img::GdkPixbuf,x,y) = GdkPixbuf(ccall((:gdk_pixbuf_new_subpixbuf,libgdk),Ptr{GObject},
    (Ptr{GObject},Cint,Cint,Cint,Cint),img,first(x)-1,first(y)-1,length(x),length(y)))
width(img::GdkPixbuf) = ccall((:gdk_pixbuf_get_width,libgdk),Cint,(Ptr{GObject},),img)
height(img::GdkPixbuf) = ccall((:gdk_pixbuf_get_height,libgdk),Cint,(Ptr{GObject},),img)
size(a::GdkPixbuf,i::Integer) = (i == 1 ? width(a) : (i == 2 ? height(a) : 1))
size(a::GdkPixbuf) = (width(a),height(a))
Base.ndims(::GdkPixbuf) = 2
function stride(img::GdkPixbuf,i)
    if i == 1
        convert(Cint, div(ccall((:gdk_pixbuf_get_bits_per_sample,libgdk),Cint,(Ptr{GObject},),img) * 
         ccall((:gdk_pixbuf_get_n_channels,libgdk),Cint,(Ptr{GObject},),img) + 7, 8))
    elseif i == 2
        ccall((:gdk_pixbuf_get_rowstride,libgdk),Cint,(Ptr{GObject},),img)
    else
        convert(Cint,0)
    end
end

size(img::GdkPixbuf) = (width(img),height(img))
function eltype(img::GdkPixbuf)
    nbytes = stride(img,1)
    if nbytes == 3
        RGB
    elseif nbytes == 4
        RGBA
    else
        error("GdkPixbuf stride must be 3 or 4")
    end
end
function convert(::Type{MatrixStrided},img::GdkPixbuf)
    MatrixStrided(
        convert(Ptr{eltype(img)},ccall((:gdk_pixbuf_get_pixels,libgdk),Ptr{Void},(Ptr{GObject},),img)),
        width=width(img), height=height(img), rowstride=stride(img,2))
end
getindex(img::GdkPixbuf,x::RangeIndex,y::RangeIndex) = convert(MatrixStrided,img)[x,y]
setindex!(img::GdkPixbuf,pix,x::RangeIndex,y::RangeIndex) = setindex!(convert(MatrixStrided,img),pix,x,y)

#TODO: image transformations, rotations, compositing

baremodule GtkIconSize
    const INVALID=0
    const MENU=1
    const SMALL_TOOLBAR=2
    const LARGE_TOOLBAR=3
    const BUTTON=4
    const DND=5
    const DIALOG=6
    get(s::Symbol) =
        if s === :invalid
            INVALID
        elseif s === :menu
            MENU
        elseif s === :small_toolbar
            SMALL_TOOLBAR
        elseif s === :large_toolbar
            LARGE_TOOLBAR
        elseif s === :button
            BUTTON
        elseif s === :dnd
            DND
        elseif s === :dialog
            DIALOG
        else
            Main.Base.error(Main.Base.string("invalid GtkIconSize ",s))
        end
end

@GType GtkImage <: GtkWidget
GtkImage(pixbuf::GdkPixbuf) = GtkImage(ccall((:gtk_image_new_from_pixbuf,libgtk),Ptr{GtkObject},(Ptr{GtkObject},),pixbuf))
GtkImage(filename) = GtkImage(ccall((:gtk_image_new_from_file,libgtk),Ptr{GtkObject},(Ptr{Uint8},),bytestring(filename)))

function GtkImage(;resource_path=nothing,filename=nothing,icon_name=nothing,size::Symbol=:invalid)
    source_count = (resource_path!==nothing) + (filename!==nothing) + (icon_name!==nothing)
    @assert(source_count != 1,
        "GdkPixbuf must at most one resource_path, filename, or icon_name argument")
    local img::GtkImage
    if resource_path !== nothing
        img = GtkImage(ccall((:gtk_image_new_from_resource,libgtk),Ptr{GtkObject},(Ptr{Uint8},),bytestring(resource_path)))
    elseif filename !== nothing
        img = GtkImage(ccall((:gtk_image_new_from_file,libgtk),Ptr{GtkObject},(Ptr{Uint8},),bytestring(filename)))
    elseif icon_name !== nothing
        img = GtkImage(ccall((:gtk_image_new_from_icon_name,libgtk),Ptr{GtkObject},(Ptr{Uint8},Cint),bytestring(icon_name),GtkIconSize.get(size)))
    else
        img = GtkImage(ccall((:gtk_image_new,libgtk),Ptr{GtkObject},()))
    end
    return img
end
empty!(img::GtkImage) = ccall((:gtk_image_clear,libgtk),Void,(Ptr{GObject},),img)
