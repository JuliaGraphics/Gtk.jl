
baremodule GApplicationFlags
    import Base.<<
    const NONE = 0
    const IS_SERVICE  = 1 << 0
    const IS_LAUNCHER = 1 << 1
    const HANDLES_OPEN = 1 << 2
    const HANDLES_COMMAND_LINE = 1 << 3
    const SEND_ENVIRONMENT = 1 << 4
    const NON_UNIQUE = 1 << 5
end

@Gtype GApplication libgio g_application

run(app::GApplicationI) = 
    ccall((:g_application_run,libgio),Cint, (Ptr{GObject},Cint, Ptr{Ptr{Uint8}}), app, 0, C_NULL)

function register(app::GApplicationI)
   GError() do error_check
      ret = bool(ccall((:g_application_register,libgio), Cint, 
         (Ptr{GObject},Ptr{Void}, Ptr{Ptr{GError}}), app, C_NULL, error_check))
      return ret
   end
end

activate(app::GApplicationI) = 
    ccall((:g_application_activate,libgio),Void, (Ptr{GObject},), app)

#void                g_application_open                  (GApplication *application,
#                                                         GFile **files,
#                                                         gint n_files,
#                                                         const gchar *hint);

#g_application_register() then g_application_activate() or g_application_open(), then exit if g_application_is_remote()