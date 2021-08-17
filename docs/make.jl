using Documenter, Gtk

makedocs(
    format = Documenter.HTML(
        prettyurls = get(ENV, "CI", nothing) == "true"
    ),
    modules = [Gtk],
    sitename = "Gtk.jl",
    authors = "...",
    pages = [
        "Home" => "index.md",
        "Manual" => ["manual/gettingStarted.md",
                     "manual/properties.md",
                     "manual/layout.md",
                     "manual/signals.md",
                     "manual/builder.md",
                     "manual/textwidgets.md",
                     "manual/combobox.md",
                     "manual/listtreeview.md",
                     "manual/filedialogs.md",
                     "manual/keyevents.md",
                     "manual/canvas.md",
                     "manual/customWidgets.md",
                     "manual/async.md",
                     "manual/nonreplusage.md",
                     "manual/packages.md"
                    ],
        "Reference" => "doc/reference.md",
    ],
)

deploydocs(
    repo   = "github.com/JuliaGraphics/Gtk.jl.git",
    target = "build",
    push_preview = true
)
