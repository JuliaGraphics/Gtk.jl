const _depspath = joinpath(dirname(@__FILE__), "deps.jl")

if isfile(_depspath)
    include(_depspath)
else
    if OS_NAME == :Windows
        const libgobject = "libgobject-2.0-0"
        const libglib = "libglib-2.0-0"
    else
        const libgobject = "libgobject-2.0"
        const libglib = "libglib-2.0"
    end
end

@osx_only begin
    if Pkg.installed("Homebrew") != nothing
        using Homebrew
        if Homebrew.installed("gtk+3")
            # Append to XDG_DATA_DIRS to get us the proper paths setup for glib schemas
            if "XDG_DATA_DIRS" in ENV
                ENV["XDG_DATA_DIRS"] *= ":" * joinpath(Homebrew.brew_prefix, "share")
            else
                ENV["XDG_DATA_DIRS"] = joinpath(Homebrew.brew_prefix, "share")
            end
        end
    end
end