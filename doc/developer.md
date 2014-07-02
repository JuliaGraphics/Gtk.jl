# GLists

## Basic Usage

Gtk functions that return a `GLib.GList` can be used in Julia's iteration syntax in the following way:

    for obj in ccall((:gtk_function_that_returns_a_GList,libgtk),
            Ptr{_GSList{T}}, (ArgTypes...,), args...)
        # do something with obj
    end

## Return Type
The returned instance `obj` will be of type `eltype(_GSList{T})`, where for `T` you have picked the expected element return type. See [below](#glist-eltype-representations) for more details on the storage characteristics for various choices of `T`

## GC Safety

Depending on where you acquired your `GLib.GList`, you will need to select the appropriate method to provide seamless garbage-collection integration.

 1. A naked `ptr=Ptr{_GSList{T}}` is never garbage-collected by Julia. This is useful when iterating over a `GLib.GSList` (or `GLib.GList`) from `GLib` which still owned by the object `[transfer-none]`
 2. Wrapping the pointer in a call to `GLib.GList(ptr)` will free the list when the returned `GList` object reference is garbage-collected `[transfer-container]`
 3. Wrapping the pointer instead in a call to `glist_iter(ptr)` will wrap the list in GC-safe iterator. By contrast to calling `GLib.GList(ptr)`, this method is necessary if the user is unlikely to be able to maintain the a reference to the returned object for the life of the iterator. Instances where this is true include iterators (hence the name), since this function is often used to create iterators: `start(x) = glist_iter(get_ptr_to_glist(x))`. `[transfer-container]`
 4. To both 2 and 3, you can supply an additional boolean parameter `transfer-full`, to have Julia also dereference and free the individual elements `[transfer-full]`
 
## Julia-allocated GLists

You can create and manipulate a new doubly-linked `GList` object from Julia by calling the `GList(T)` constructor, where `T` is the `eltype` of the pointers that you want this list to be able to hold.

    list = GList(Int) # similar to Array(Int,1)
    list[1]
    
By default, these are allocated as `[transfer-full]`, meaning it will deallocate all of its elements when the list is destroyed. However, like all `GList` constructors, it takes an `transfer_full` argument, which can be set to false to have Julia reference it as `[tranfer-container]`.

To transfer ownership of the GList, you can extract the `GList.handle` from list, and the set `GList.handle = C_NULL` to reset it.

A `GList` conforms to the `AbstractVector` interface, and can be used in most contexts that an `Array` could be used.

## GList `eltype` Representations

 * `GList{T<:GObject} stores references to `GObject`
 * `GList{T<:Any}` stores Julia object references
 * `GList{T<:Ptr}` stores pointers, without alteration
 * `GList{T<:Number}` stores numbers inside the pointer (generally only works with Integer, and size must be <= sizeof(int) == 32 bits)
 * `GList{T<:Ptr{Number}}` stores individually `g_malloc`-created boxed numerical type objects
 
 You can add your own conversions by defining the appropriate `eltype  -> return type`, `GLib.ref_to -> makes a pointer from an object`, `GLib.deref_to -> makes an object from a pointer`, and `empty! -> frees the contents of a list object of this type` methods (see the bottom of `GLib/glist.jl` for examples.

# Utility functions

### `GLib.bytestring(ptr, own::Bool)`

This no-copy variant of `bytestring` allows you to specify whether Julia "owns" the memory pointed to by `ptr` (similar to `Base.pointer_to_array`).
This is useful for `GList` iteration when wishing to return strings created by a Gtk object, and other APIs that return a newly allocated string.
