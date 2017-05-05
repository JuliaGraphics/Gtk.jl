get_default_mod_mask() = ccall((:gtk_accelerator_get_default_mod_mask , libgtk),
    typeof(GdkModifierType.CONTROL),())

@static if is_apple()
    const PrimaryModifier = GdkModifierType.MOD2 #command key
    const SecondaryModifer = GdkModifierType.CONTROL
end
@static if is_windows()
    const PrimaryModifier = GdkModifierType.CONTROL
    const SecondaryModifer = GdkModifierType.MOD1 #alt key
end
@static if is_linux()
    const PrimaryModifier = GdkModifierType.CONTROL
    const SecondaryModifer = GdkModifierType.MOD1
end
const NoModifier  = Base.zero(UInt32)

"""
Represents a combination of keys.

##Examples:

    Shortcut(GdkKeySyms.Tab) # Tab key

    Shortcut("c") # c key

    Shortcut("c",PrimaryModifier) # Ctrl-c (Windows & Linux) or Command-c (OS X)

    Shortcut("C",PrimaryModifier + GdkModifierType.SHIFT) # Ctrl-Shit-c (notice the capital C)

"""
immutable Shortcut
    keyval::UInt32
    state::UInt32

    Shortcut(k::Integer,s::Integer) = new(k,s)
    Shortcut(k::Integer) = new(k,NoModifier)
    Shortcut(k::AbstractString) = new(keyval(k),NoModifier)
    Shortcut(k::AbstractString,s::Integer) = new(keyval(k),s)
end

"""
    doing(s::Shortcut, event::GdkEvent)

Test wether the `GdkEvent` corresponds to the given `Shortcut`.

##Example:

    if doing(Shortcut("c",PrimaryModifier),event)
        #copy...
    end

Reference : https://developer.gnome.org/gtk3/unstable/checklist-modifiers.html

"""
function doing(s::Shortcut, event::GdkEvent)

    mod = get_default_mod_mask()
    #on os x, the command key is also the meta key
    @static if is_apple()
        if s.state == NoModifier && event.state == NoModifier
             return event.keyval == s.keyval
        end
        if (event.keyval == s.keyval) && (event.state & mod == s.state)
            return true
        end
        return (event.keyval == s.keyval) &&
               (event.state & mod == s.state + GdkModifierType.META)
    end

    return (event.keyval == s.keyval) && (event.state & mod == s.state)
end