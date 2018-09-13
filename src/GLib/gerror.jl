struct GError
    domain::UInt32
    code::Cint
    message::Ptr{UInt8}
end
@make_gvalue(GError, Ptr{GError}, :boxed, (:g_error, :libgobject))
convert(::Type{GError}, err::Ptr{GError}) = GError(err)

GError(err::Ptr{GError}) = unsafe_load(err)
function GError(f::Function)
    err = mutable(Ptr{GError})
    err.x = C_NULL
    if !f(err) || err[] != C_NULL
        gerror = GError(err[])
        emsg = bytestring(gerror.message)
        ccall((:g_clear_error, libglib), Nothing, (Ptr{Ptr{GError}},), err)
        error(emsg)
    end
end

