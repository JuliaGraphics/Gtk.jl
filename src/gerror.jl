immutable GError
    domain::Uint32
    code::Cint
    message::Ptr{Uint8}
end
make_gvalue(GError, Ptr{GError}, :boxed, (:g_error,:libgobject))
convert(::Type{GError}, err::Ptr{GError}) = GError(err)

GError(err::Ptr{GError}) = unsafe_load(err)
function GError(f::Function)
    err = zeros(Ptr{GError},1)
    if !f(err) || err[1] != C_NULL
        gerror = GError(err[1])
        emsg = bytestring(gerror.message)
        ccall((:g_clear_error,libglib),Void,(Ptr{Ptr{GError}},),err)
        error(emsg)
    end
end

