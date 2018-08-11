using Documenter, Gtk

makedocs(
    format = :html,
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
    ],
)

deploydocs(repo   = "github.com/JuliaGraphics/Gtk.jl.git",
           julia  = "0.7",
           target = "build",
           deps   = nothing,
           make   = nothing)
