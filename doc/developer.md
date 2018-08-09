# Gtk-Developer-Oriented Documentation: Extending Gtk.jl’s functionality
---

## Implementing New Gtk Types

You can subclass an existing Gtk type in Julia using the following code pattern:

    type MyWidget <: Gtk.GtkButton
        handle::Ptr{Gtk.GObject}
        other_fields
        function MyWidget(label)
            btn = @GtkButton(label)
            Gtk.gobject_move_ref(new(btn), btn)
        end
    end

This creates a `MyWidget` type which inherits its behavior from `GtkButton`. The `gobject_move_ref` call transfers ownership of the `GObject` handle from `GtkButton` to `MyWidget` in a gc-safe manner. Afterwards, the `btn` object is invalid and converting from the `Ptr{GtkObject}` to `GtkObject` will return the `MyWidget` object.

New native Gtk types can be most easily added by invoking the `Gtk.@GTypes` macro:

     Gtk.@GTypes GTypeName library_variable sym_name
     Gtk.@GTypes GTypeName library_variable gtyp_getter_expr

and then defining the appropriate outer constructors. Note that the `@GTypes` macro expects a variable `suffix` to be defined in the current module, which will be appended to the name of the type to create a unique type instance.

Please pay attention to existing constructors that already exist to avoid user confusion: for example, the first argument to a `GtkContainer` may optionally be its first child widget. And keyword arguments are reserved for setting properties after construction.

---

## Utility functions

### `GLib.bytestring(ptr, own::Bool)`

This no-copy variant of `bytestring` allows you to specify whether Julia "owns" the memory pointed to by `ptr` (similar to `Base.pointer_to_array`).
This is useful for `GList` iteration when wishing to return strings created by a Gtk object, and other APIs that return a newly allocated string.

### `GLib.gc_ref(x::ANY)` / `GLib.gc_unref(x::ANY)` / `GLib.gobject_ref(x::GObject)`

As the names suggests, these functions increase / decrease the reference count of a Julia object `x`, to prevent garbage-collection of this object while it is in use by `Glib`. Note that `GLib.gc_unref(w::GObject)` should typically not be called, since it will immediately destroy the Julia reference `w`, and will be called automatically by the Julia garbage-collector once their are no remaining references to this object (in GLib or Julia). The function `gc_ref` returns a pointer to the gc-protected memory (as a `*jl_value_t` / `Ptr{Nothing}`) for use in ccall, whereas `gobject_ref` returns `x` for use in method chaining.

### `mutable{T}(::Type{T})`

Creates a new box to contain an reference to an instance of `T`

### `mutable(x, i=1)`

Creates a new box (with optional offset index `i==1`) initialized to contain `x`

### `mutable(x::Union{Ptr,Array,Mutable}, i=1)`

Returns the reference to the box, `x`, optionally offset by index `i`

---

## GLib.MutableTypes

The `GLib.MutableTypes` module provides methods for seamlessly working with various forms of boxed `immutable` (or `mutable`) objects. An immutable object could be boxed in a `Ptr` and `Array`, or an `MutableTypes.MutableX` singleton wrapper. Therefore, the `mutable` class helps to seamlessly merge all three into a single interface.

Given a `mutable` object, the user can extract the data in one of three ways:

 * Using `[]` (`getindex`) notation is convenient short-hand, but is not defined for pointers
 * If the `mutable` object reference might be a pointer, instead choose either of the `deref` or `unsafe_load` function names. Their behavior is identical for the types in the `MutableTypes` module, but they might have had different fallback methods added externally.

Updating the value is a `mutable` object reference can also be done in one of three ways:

 * By passing the mutable object to `ccall`, with type signature `Ptr{T}`
 * Using `[] =` (`setindex!`) is convenient short-hand notation, but is not defined for pointers
 * If the `mutable` object reference might be a pointer, instead call `unsafe_store!`

---

## GLists

### Basic Usage

Gtk functions that return a `GLib.GList` can be used in Julia's iteration syntax in the following way:

    for obj in ccall((:gtk_function_that_returns_a_GList,libgtk),
            Ptr{_GSList{T}}, (ArgTypes...,), args...)
        # do something with obj
    end

### Return Type
The returned instance `obj` will be of type `eltype(_GSList{T})`, where for `T` you have picked the expected element return type. See [below](#glist-eltype-representations) for more details on the storage characteristics for various choices of `T`

### GC Safety

Depending on where you acquired your `GLib.GList`, you will need to select the appropriate method to provide seamless garbage-collection integration.

 1. A naked `ptr=Ptr{_GSList{T}}` is never garbage-collected by Julia. This is useful when iterating over a `GLib.GSList` (or `GLib.GList`) from `GLib` which still owned by the object `[transfer-none]`
 2. Wrapping the pointer in a call to `GLib.GList(ptr)` will free the list when the returned `GList` object reference is garbage-collected `[transfer-container]`
 3. Wrapping the pointer instead in a call to `glist_iter(ptr)` will wrap the list in GC-safe iterator. By contrast to calling `GLib.GList(ptr)`, this method is necessary if the user is unlikely to be able to maintain the a reference to the returned object for the life of the iterator. Instances where this is true include iterators (hence the name), since this function is often used to create iterators: `start(x) = glist_iter(get_ptr_to_glist(x))`. `[transfer-container]`
 4. To both 2 and 3, you can supply an additional boolean parameter `transfer-full`, to have Julia also dereference and free the individual elements `[transfer-full]`
 5. WARNING: ensure the choice of `_GSList` vs `_GList` matches the Gtk API exactly. Using the wrong one will corrupt the GSlice allocator.

### Julia-allocated GLists

You can create and manipulate a new doubly-linked `GList` object from Julia by calling the `GList(T)` constructor, where `T` is the `eltype` of the pointers that you want this list to be able to hold.

    list = GList(Int) # similar to Array(Int,1)
    list[1]

By default, these are allocated as `[transfer-full]`, meaning it will deallocate all of its elements when the list is destroyed. However, like all `GList` constructors, it takes an `transfer_full` argument, which can be set to false to have Julia reference it as `[tranfer-container]`.

To transfer ownership of the GList, you can extract the `GList.handle` from list, and the set `GList.handle = C_NULL` to reset it.

A `GList` conforms to the `AbstractVector` interface, and can be used in most contexts that an `Array` could be used.

### GList `eltype` Representations

 * `GList{T<:GObject} stores references to `GObject`
 * `GList{T<:Any}` stores Julia object references
 * `GList{T<:Ptr}` stores pointers, without alteration
 * `GList{T<:Number}` stores numbers inside the pointer (generally only works with Integer, and size must be <= sizeof(int) == 32 bits)
 * `GList{T<:Ptr{Number}}` stores individually `g_malloc`-created boxed numerical type objects

 You can add your own conversions by defining the appropriate `eltype  -> return type`, `GLib.ref_to -> makes a pointer from an object`, `GLib.deref_to -> makes an object from a pointer`, and `empty! -> frees the contents of a list object of this type` methods (see the bottom of `GLib/glist.jl` for examples.

---

## Adding new `GValue`⇄`Julia` auto-conversions

New GValue-to-Julia conversions can be implemented via the `Gtk.make_gvalue(pass_x,as_ctype,to_gtype,with_id,allow_reverse::Bool=true)` function. This adds all of the appropriate methods to getindex, setindex!, and gvalue to handle converting this value to and from a GValue.

- `pass_x` is the Julia type
- `as_ctype` is the type for ccall
- `to_gtype` is the name of the `g_value_get_*` `g_value_set_*` method to use
- `with_id` specifies the type identifier. It must resolve to an Int, but can either be a variable, and Integer, or a tuple of the type name and library where the `_get_type` function can be called
- `allow_reverse` specifies whether this entry should be used for auto-unpacking

Note that this calls Core.eval on its arguments in the current module, so if you want to use a symbol from Gtk (such as `Gtk.libgtk`, make sure you give the fully qualified name). You will also need to ensure the appropriate convert methods exist to translate from `pass_x` to `as_ctype` and back. `make_gvalue` does a few automatic transformations:

- if the `to_gtype` is `:string` or `:static_string`, make_gvalue will insert calls to bytestring
- if the `to_gtype` is `:pointer` or `:boxed`, make_gvalue will insert code (a call to `Gtk.mutable`) that converts from `Type` -> `Ptr{Type}` in the `setindex!` method. Providing a conversion from `Ptr{Type}` -> `Type` must be handled by the user.

For example:

    Gtk.make_gvalue(Gtk.GdkRectangle, Ptr{Gtk.GdkRectangle}, :boxed, (:gdk_rectangle,:(Gtk.libgdk)))
    Base.convert(::Type{Gtk.GdkRectangle}, rect::Ptr{Gtk.GdkRectangle}) = unsafe_load(rect)
