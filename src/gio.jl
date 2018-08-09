if libgtk_version >= v"3"
    run(app::GApplication) =
        (@sigatom ccall((:g_application_run, libgio), Cint,
            (Ptr{GObject}, Cint, Ptr{Ptr{UInt8}}), app, 0, C_NULL))::Cint

    function register(app::GApplication)
       GError() do error_check
          ret = Bool(ccall((:g_application_register, libgio), Cint,
             (Ptr{GObject}, Ptr{Nothing}, Ptr{Ptr{GError}}), app, C_NULL, error_check))
          return ret
       end
    end

    activate(app::GApplication) =
        ccall((:g_application_activate, libgio), Nothing, (Ptr{GObject},), app)
end
