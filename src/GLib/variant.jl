mutable struct GVariant
    handle::Ptr{GVariant}
    function GVariant(ref::Ptr{GVariant})
        x = new(ref)
    end
end

convert(::Type{GVariant}, unbox::Ptr{GVariant}) = GVariant(unbox)
unsafe_convert(::Type{Ptr{GVariant}}, w::GVariant) = getfield(w, :handle)
