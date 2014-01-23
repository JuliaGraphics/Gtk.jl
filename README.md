Julia interface to Gtk+-2 and Gtk+-3 GUI library (http://www.gtk.org/)

Disclaimer: some part of this API may not be finalized

## Installation

Prior to using this library, you must install a version of libgtk on your computer. While this interface currently defaults to using Gtk+-2, it can be configured by editing `Gtk/deps/ext.jl` and changing the integer valued `gtk_version` variable.

### Windows

The easiest method of installation is to use `WinRPM.jl`:

1. Pkg.add("WinRPM")
2. WinRPM.install("gtk2")
3. RPMbindir = Pkg.dir("WinRPM","deps","usr","$(Sys.ARCH)-w64-mingw32","sys-root","mingw","bin")
4. ENV["PATH"]=ENV["PATH"]*";"*RPMbindir

You may need to repeat steps 3 and 4 every time you restart julia, or put these two lines in your $HOME/.juliarc.jl file

### OS X

I use MacPorts:

1. `port install gtk2 +quartz -x11 gtk3 +quartz -x11` (this may require that you first remove Cairo and Pango, I like to put this in my "/opt/local/etc/macports/variants.conf" file as "+no_x11 -x11 +quartz" before installing anything to minimize conflicts)
2. push!(DL_LOAD_PATH,"/opt/local/lib")
You will need to repeat step 2 every time you restart julia, or put this line in your ~/.juliarc.jl file.

If you want to use Homebrew, the built-in formula is deficient (it does not support the Quartz back-end). See https://github.com/JuliaLang/Homebrew.jl/issues/27 for possible eventual workarounds.

### Linux

Try any of the following until something is successful:

     aptitude install libgtk2.0-0 libgtk-3-0
     apt-get install libgtk2.0-0 libgtk-3-0
     yum install gtk2 gtk3

On some distributions you can also install a `devhelp` package to have a local copy of the Gtk documentation.

## Overview

This Gtk wrapper attempts to expose all of the power of the Gtk library in a simple, uniform interface. The structure and names employed should be easily familiar to anyone browsing the Gtk documentation or example code, or anyone who has prior experience with Gtk.

There is also a more [detailed description](doc/usage.md) in tutorial style, as well as a [property/hierarchy browser](doc/properties.md) and [function reference](doc/function_reference.md).

### Referring to Gtk.Objects

Gtk object can be referenced by their Gtk names (which almost always have a name like GtkWindow), their interfaces (which will have an ``I`` prefixed to their name, such as GtkContainerI), or their "short name" (which is generally just the Gtk name without the "Gtk", for example, Window). You can call `using Gtk` to import the regular names, or `using Gtk.ShortNames` to import the shorter names. You can also call `import Gtk`, and then access either the regular or short names (e.g. `Gtk.Window` or `Gtk.GtkWindow`).

### Objects are containers for their [child_elements...]

All objects in Gtk are intended to behave uniformly. This means that all objects will try to act as container objects. Indexing into an object (by number), or iterating the object will return a list of its contents or child objects. This also means that constructors are called with information on the elements that they contain. For example, when you create a button, you can specify either the embedded text or another widget!

    Gtk.Button("This is a button")
    Gtk.Button(Gtk.Label("Click me"))

On the flip side, you can assign child widgets to indices, or `push!` them onto the list of child widgets, for any object which derives from a GtkContainerI. Of special note is the anti-object GtkNullContainer. This is not a Gtk Object. However, it can be used to prevent the creation of a default container, and it has the special behavior that it will remove any object added to it from its existing parent (although the standard operations like `splice!` and `delete!` also exist, and are typically preferable).

### Objects have getproperty(obj, :prop, types) and setproperty!(obj, :prop, value)

The properties of any object can be accessed by via the `getproperty` and `setproperty!` methods. Displaying a GtkObjectI at the REPL-prompt will show you all of the properties that can be set on the object. Or you can view the [Gtk documentation](https://developer.gnome.org/gtk3/stable/GtkWidget.html) online. Indexing is typically done using a symbol, but you can also use a string. In property names, you can replace `-` with `_` as shown below.

When retrieving a property, you must specify the output type. Specifying the input type when setting a property is strictly optional.

Some Examples:

    w = GtkWindow("Title")
    show(STDOUT, w) # without the STDOUT parameter, show(w) would
                    # make the window visible on the screen, instead
                    # of printing the information in the REPL
    getproperty(w,:title,String)
    setproperty!(w,:title,"New title")
    setproperty!(w,:urgency_hint,Bool,true)

### Objects can signal events

There are two entry points to the API for handling signals: Simple and robust OR fast and precise.

You can remove signal handlers by their id using `signal_handler_disconnect` or temporarily block them by id using `signal_handler_block` and `signal_handler_unblock`

#### Easy Event Handlers

Upon entry to the signal handler, Julia will unpack the arguments it received into native types:

    id = signal_connect(widget, :event) do obj, args...
        println("That tickles: $args")
        nothing
    end

See section on [Extending Gtk's Functionality with new GValue<->Julia auto-conversions](#new-gvalue-julia-auto-conversions) at the end of this document for details on the auto-unpacking implementation.

#### Fast Event Handlers

If you want pre-optimized event handlers, you will need to specify the interface types when creating the signal handlers. (There are a few `on_signal_` convenience functions which do this, often in conjunction with setting other flags needed for the signal handler to function). You will often find it necessary to refer to the Gtk documentation for the signals API for Gtk callbacks:

- Gtk+-2
  -  https://developer.gnome.org/gtk2/stable/GObject.html#GObject-destroy
  -  https://developer.gnome.org/gtk2/stable/GtkWidget.html#GtkWidget-accel-closures-changed
- Gtk+-3
  -  https://developer.gnome.org/gtk3/stable/GtkWidget.html#GtkWidget-accel-closures-changed

Note that the ArgType argument only specifies the type for the middle arguments. The type of the first and last arguments are determined automatically.

Example:

    function on_signal_event(ptr, args, widget)
        println("That tickles")
        nothing
    end
    id = signal_connect(widget, :event, Void, (ArgType,))
    ## OR
    id = signal_connect(widget, :event, Void, (ArgType,)) do ptr, args, obj
        println("That tickles")
        nothing
    end

### Events can be emitted

In addition to listening for events, you can trigger your own:

    #syntax: signal_emit(w::GObject, sig::Union(String,Symbol), RT::Type, args...)
    signal_emit(widget, :event, Void, 42)

Note: the return type and argument types do not need to match the spec. However, the length of the args list MUST exactly match the length of the ArgType's list.

### Objects have get and set accessor methods

warning: this API has not been completely finalized

``Gtk._`` (not exported), ``Gtk.G_`` (exported by ShortNames), and ``Gtk.GAccessor`` (exported by Gtk) all refer to the same module: a collection of auto-generated method stubs for calling get/set methods on the GtkObjects. The difference between a get and set method is based upon the number of arguments.

Example usage:

    bytestring(Gtk._.title(Window("my title")))
    G_.title(Window("my title"), "my new title")
    GAccessor.size(Window("what size?"))

Note that because these are auto-generated, you will often need to do your own gc-management at the interface. For example, the string returned by title must not be freed or modified. Since the code auto-generator cannot know this, it simply returns the raw pointer.


## Gtk Object Tree

    +- Any
    .  +- AbstractArray = AbstractArray{GValue,1}
    .  .  +- MatrixStrided = MatrixStrided{T}
    .  .  +- Ranges = Ranges{T}
    .  .  .  +- GtkTextRange
    .  +- GError
    .  +- GObject = GObjectI
    .  +- GObjectI
    .  .  +- GObjectAny = GObjectAny{Name}
    .  .  +- GdkPixbuf
    .  .  +- GtkStatusIcon
    .  .  +- GtkTextBuffer
    .  .  +- GtkTextMark
    .  .  +- GtkTextTag
    .  .  +- GtkWidgetI
    .  .  .  +- Canvas = GtkCanvas
    .  .  .  +- GtkCanvas
    .  .  .  +- GtkComboBoxText
    .  .  .  +- GtkContainerI
    .  .  .  .  +- GtkBinI
    .  .  .  .  .  +- GtkAlignment
    .  .  .  .  .  +- GtkAspectFrame
    .  .  .  .  .  +- GtkButton
    .  .  .  .  .  +- GtkCheckButton
    .  .  .  .  .  +- GtkExpander
    .  .  .  .  .  +- GtkFrame
    .  .  .  .  .  +- GtkLinkButton
    .  .  .  .  .  +- GtkRadioButton
    .  .  .  .  .  +- GtkToggleButton
    .  .  .  .  .  +- GtkVolumeButton
    .  .  .  .  .  +- GtkWindowI
    .  .  .  .  .  .  +- GtkDialogI
    .  .  .  .  .  .  .  +- GtkFileChooserDialog
    .  .  .  .  .  .  +- GtkWindow
    .  .  .  .  .  .  +- Window = GtkWindow
    .  .  .  .  +- GtkBoxI
    .  .  .  .  .  +- GtkBox
    .  .  .  .  .  +- GtkButtonBox
    .  .  .  .  .  +- GtkStatusbar
    .  .  .  .  +- GtkGrid
    .  .  .  .  +- GtkLayout
    .  .  .  .  +- GtkNotebook
    .  .  .  .  +- GtkNullContainer
    .  .  .  .  +- GtkOverlay
    .  .  .  .  +- GtkPaned
    .  .  .  .  +- GtkRadioButtonGroup
    .  .  .  .  +- GtkTable
    .  .  .  +- GtkEntry
    .  .  .  +- GtkImage
    .  .  .  +- GtkLabel
    .  .  .  +- GtkProgressBar
    .  .  .  +- GtkScale
    .  .  .  +- GtkSpinButton
    .  .  .  +- GtkSpinner
    .  .  .  +- GtkSwitch
    .  .  .  +- GtkTextView
    .  +- GParamSpec
    .  +- GSList = GSList{T}
    .  +- GValue
    .  +- GdkEventI
    .  .  +- GdkEventAny
    .  .  +- GdkEventButton
    .  .  +- GdkEventCrossing
    .  .  +- GdkEventKey
    .  .  +- GdkEventMotion
    .  .  +- GdkEventScroll
    .  +- GdkPoint
    .  +- GdkRectangle
    .  +- GtkTextIter
    .  +- MouseHandler
    .  +- RGB
    .  +- RGBA


### Extending Gtk's functionality

#### New Gtk Types

New Gtk types can be most easily added by using the Gtk.@GTypes macro:
     
     Gtk.@GTypes GTypeName <: GParentName
     
and then defining the appropriate outer constructors. Pay attention to existing constructors that already exist, though, to avoid confusion: the first argument to a GtkContainer may optionally be its first child widget. And keyword arguments are reserved for setting properties after construction.

#### New GValue<->Julia auto-conversions

New GValue-to-Julia conversions can be implemented via the `Gtk.make_gvalue(pass_x,as_ctype,to_gtype,with_id,allow_reverse::Bool=true)` function. This adds all of the appropriate methods to getindex, setindex!, and gvalue to handle converting this value to and from a GValue.

- `pass_x` is the Julia type
- `as_ctype` is the type for ccall
- `to_gtype` is the name of the `g_value_get_*` `g_value_set_*` method to use
- `with_id` specifies the type identifier. It must resolve to an Int, but can either be a variable, and Integer, or a tuple of the type name and library where the `_get_type` function can be called
- `allow_reverse` specifies whether this entry should be used for auto-unpacking

Note that this calls eval on its arguments in the current module, so if you want to use a symbol from Gtk (such as `Gtk.libgtk`, make sure you give the fully qualified name). You will also need to ensure the appropriate convert methods exist to translate from `pass_x` to `as_ctype` and back. `make_gvalue` does a few automatic transformations:

- if the `to_gtype` is `:string` or `:static_string`, make_gvalue will insert calls to bytestring
- if the `to_gtype` is `:pointer` or `:boxed`, make_gvalue will insert code (a call to `Gtk.mutable`) that converts from `Type` -> `Ptr{Type}` in the `setindex!` method. Providing a conversion from `Ptr{Type}` -> `Type` must be handled by the user.

For example:

    Gtk.make_gvalue(Gtk.GdkRectangle, Ptr{Gtk.GdkRectangle}, :boxed, (:gdk_rectangle,:(Gtk.libgdk)))
    Base.convert(::Type{Gtk.GdkRectangle}, rect::Ptr{Gtk.GdkRectangle}) = unsafe_load(rect)

