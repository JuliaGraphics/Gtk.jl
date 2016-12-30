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
                     "manual/filedialogs.md",
                     "manual/nonreplusage.md"
                    ],
    ],
)

