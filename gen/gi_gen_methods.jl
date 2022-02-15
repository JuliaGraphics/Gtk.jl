using GI

toplevel, exprs, exports = GI.output_exprs()

gtk3 = GINamespace(:Gtk, "3.0")

# method args don't include the instance, so getters should have 0 arguments and setters should have 1 argument
valid_getsetter(m)=(startswith(string(GI.get_name(m)),"get_") && length(GI.get_args(m))==0) ||
                    (startswith(string(GI.get_name(m)),"set_") && length(GI.get_args(m))==1)

for o in GI.get_all(gtk3,GI.GIObjectInfo)
    if GI.get_name(o)===:Gesture || GI.get_name(o)===:GestureSingle || GI.get_name(o)===:IMContext  # avoid problematic arguments
        continue
    end
    if GI.get_name(o)===:Plug || GI.get_name(o)===:Socket
        continue
    end
    for m in GI.get_methods(o)
        if GI.is_deprecated(m)
            continue
        end
        # avoid non-setters and some problematic arguments
        if startswith(string(GI.get_name(m)), "set_from_") || GI.get_name(m) === :get_surface ||
                        GI.get_name(m) === :get_cairo_context || GI.get_name(m) === :get_font_options ||
                        GI.get_name(m) === :get_default || GI.get_name(m) === :get_drag_target_group ||
                        GI.get_name(m) === :get_drag_target_item || GI.get_name(m)=== :set_font_options ||
                        GI.get_name(m) === :set_accel_closure || GI.get_name(m) === :set_background_rgba ||
                        GI.get_name(m) === :set_rgba || GI.get_name(m) === :set_current_rgba || GI.get_name(m) === :set_previous_rgba ||
                        GI.get_name(m) === :set_active_iter || GI.get_name(m) === :set_area || GI.get_name(m) === :set_pointing_to ||
                        GI.get_name(m) === :set_tip_area || GI.get_name(m) === :set_allocation || GI.get_name(m) === :set_clip
            continue
        end
        if valid_getsetter(m)
            try
                push!(exprs,GI.create_method(m))
            catch NotImplementedError
                println("NotImplementedError: ",GI.get_name(m))
            end
        end
    end
end

for i in GI.get_all(gtk3,GI.GIInterfaceInfo)
    # avoid method name collisions (for interfaces, we use "GObject" for the
    # instance type because we don't have multiple inheritance)
    # if GI.get_name(i)===:RecentChooser || GI.get_name(i)===:ToolShell
    #     continue
    # end
    for m in GI.get_methods(i)
        if GI.is_deprecated(m)
            continue
        end
        if GI.get_name(m) === :set_rgba
            continue
        end
        if valid_getsetter(m)
            try
                push!(exprs,GI.create_method(m))
            catch NotImplementedError
                println("NotImplementedError: ",GI.get_name(m))
            end
        end
    end
end

GI.write_to_file(".","gtk3_methods",toplevel)
