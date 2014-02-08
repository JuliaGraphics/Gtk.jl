baremodule GtkIconSize
    const INVALID=0
    const MENU=1
    const SMALL_TOOLBAR=2
    const LARGE_TOOLBAR=3
    const BUTTON=4
    const DND=5
    const DIALOG=6
    get(s::Symbol) =
        if     s === :invalid
            INVALID
        elseif s === :menu
            MENU
        elseif s === :small_toolbar
            SMALL_TOOLBAR
        elseif s === :large_toolbar
            LARGE_TOOLBAR
        elseif s === :button
            BUTTON
        elseif s === :dnd
            DND
        elseif s === :dialog
            DIALOG
        else
            Main.Base.error(Main.Base.string("invalid GtkIconSize ",s))
        end
end