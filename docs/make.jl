using Documenter, Gtk

makedocs(
    format = :html,
    modules = [Gtk],
    sitename = "Gtk.jl",
    authors = "...",
    pages = [
        "Home" => "index.md",
        "Manual" => ["manual/gettingStarted.md",
                    ],
    ],
)

