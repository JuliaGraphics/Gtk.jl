@compat abstract type GObject end
@compat abstract type GInterface <: GObject end
@compat abstract type GBoxed  end
type GBoxedUnkown <: GBoxed
    handle::Ptr{GBoxed}
end

const  GEnum = Int32
const  GType = Csize_t

immutable GParamSpec
  g_type_instance::Ptr{Void}
  name::Ptr{UInt8}
  flags::Cint
  value_type::GType
  owner_type::GType
end

const fundamental_types = (
    #(:name,      Ctype,            JuliaType,      g_value_fn)
    (:invalid,    Void,             Union{},        :error),
    (:void,       Void,             Void,           :error),
    (:GInterface, Ptr{Void},        GInterface,     :error),
    (:gchar,      Int8,             Int8,           :schar),
    (:guchar,     UInt8,            UInt8,          :uchar),
    (:gboolean,   Cint,             Bool,           :boolean),
    (:gint,       Cint,             Union{},        :int),
    (:guint,      Cuint,            Union{},        :uint),
    (:glong,      Clong,            Union{},        :long),
    (:gulong,     Culong,           Union{},        :ulong),
    (:gint64,     Int64,            Signed,         :int64),
    (:guint64,    UInt64,           Unsigned,       :uint64),
    (:GEnum,      GEnum,            Union{},        :enum),
    (:GFlags,     GEnum,            Union{},        :flags),
    (:gfloat,     Float32,          Float32,        :float),
    (:gdouble,    Float64,          AbstractFloat,  :double),
    (:gchararray, Ptr{UInt8},       AbstractString, :string),
    (:gpointer,   Ptr{Void},        Ptr,            :pointer),
    (:GBoxed,     Ptr{GBoxed},      GBoxed,         :boxed),
    (:GParam,     Ptr{GParamSpec},  Ptr{GParamSpec}, :param),
    (:GObject,    Ptr{GObject},     GObject,        :object),
    #(:GVariant,  Ptr{GVariant},    GVariant,       :variant),
    )
# NOTE: in general do not cache ids, except for these fundamental values
g_type_from_name(name::Symbol) = ccall((:g_type_from_name, libgobject), GType, (Ptr{UInt8},), name)
const fundamental_ids = tuple(GType[g_type_from_name(name) for (name, c, j, f) in fundamental_types]...)

g_type(gtyp::GType) = gtyp
let jtypes = Expr(:block, :( g_type(::Type{Void}) = $(g_type_from_name(:void)) ))
    for i = 1:length(fundamental_types)
        (name, ctype, juliatype, g_value_fn) = fundamental_types[i]
        if juliatype != Union{}
            push!(jtypes.args, :( g_type{T <: $juliatype}(::Type{T}) = convert(GType, $(fundamental_ids[i])) ))
        end
    end
    eval(jtypes)
end

G_TYPE_FROM_CLASS(w::Ptr{Void}) = unsafe_load(convert(Ptr{GType}, w))
G_OBJECT_GET_CLASS(w::GObject) = G_OBJECT_GET_CLASS(w.handle)
G_OBJECT_GET_CLASS(hnd::Ptr{GObject}) = unsafe_load(convert(Ptr{Ptr{Void}}, hnd))
G_OBJECT_CLASS_TYPE(w) = G_TYPE_FROM_CLASS(G_OBJECT_GET_CLASS(w))

g_isa(gtyp::GType, is_a_type::GType) = ccall((:g_type_is_a, libgobject), Cint, (GType, GType), gtyp, is_a_type) != 0
g_isa(gtyp, is_a_type) = g_isa(g_type(gtyp), g_type(is_a_type))
g_type_parent(child::GType) = ccall((:g_type_parent, libgobject), GType, (GType,), child)
g_type_name(g_type::GType) = Symbol(bytestring(ccall((:g_type_name, libgobject), Ptr{UInt8}, (GType,), g_type)))

g_type_test_flags(g_type::GType, flag) = ccall((:g_type_test_flags, libgobject), Bool, (GType, GEnum), g_type, flag)
const G_TYPE_FLAG_CLASSED           = 1 << 0
const G_TYPE_FLAG_INSTANTIATABLE    = 1 << 1
const G_TYPE_FLAG_DERIVABLE         = 1 << 2
const G_TYPE_FLAG_DEEP_DERIVABLE    = 1 << 3
type GObjectLeaf <: GObject
    handle::Ptr{GObject}
    function GObjectLeaf(handle::Ptr{GObject})
        if handle == C_NULL
            error("Cannot construct $gname with a NULL pointer")
        end
        return gobject_ref(new(handle))
    end
end
g_type(obj::GObject) = g_type(typeof(obj))

gtypes(types...) = GType[g_type(t) for t in types]

const gtype_abstracts = Dict{Symbol, Type}()
const gtype_wrappers = Dict{Symbol, Type}()
const gtype_ifaces = Dict{Symbol, Type}()

gtype_abstracts[:GObject] = GObject
gtype_wrappers[:GObject] = GObjectLeaf

let libs = Dict{AbstractString, Any}()
global get_fn_ptr
function get_fn_ptr(fnname, lib)
    if !isa(lib, AbstractString)
        lib = eval(current_module(), lib)
    end
    libptr = get(libs, lib, C_NULL)::Ptr{Void}
    if libptr == C_NULL
        libs[lib] = libptr = dlopen(lib)
    end
    fnptr = dlsym_e(libptr, fnname)
end
end
function g_type(name::Symbol, lib, symname::Symbol)
    if name in keys(gtype_wrappers)
        return g_type(gtype_wrappers[name])
    end
    fnptr = get_fn_ptr(string(symname, "_get_type"), lib)
    if fnptr != C_NULL
        ccall(fnptr, GType, ())
    else
        convert(GType, 0)
    end
end
g_type(name::Symbol, lib, symname::Expr) = eval(current_module(), symname)

function get_interface_decl(iname::Symbol, gtyp::GType, gtyp_decl)
    if isdefined(current_module(), iname)
        return nothing
    end
    parent = g_type_parent(gtyp)
    @assert parent != 0
    piname = g_type_name(parent)
    quote
        if $(QuoteNode(iname)) in keys(gtype_ifaces)
            const $(esc(iname)) = gtype_abstracts[$(Meta.quot(iname))]
        else
            immutable $(esc(iname)) <: GInterface
                handle::Ptr{GObject}
                gc::Any
                $(esc(iname))(x::GObject) = new(unsafe_convert(Ptr{GObject}, x), x)
                # Gtk does an interface type check when calling methods. So, it's
                # not worth repeating it here. Plus, we might as well just allow
                # the user to lie, since we aren't using this for dispatch
                # (like C & unlike most other languages), the user may be able
                # to write more generic code
            end
            gtype_ifaces[$(QuoteNode(iname))] = $(esc(iname))
            local T #to prevent Julia-0.2 from name-mangling <: T
            $gtyp_decl
        end
        nothing
    end
end

function get_itype_decl(iname::Symbol, gtyp::GType)
    if isdefined(current_module(), iname)
        return nothing
    end
    if iname === :GObject
        return :( const $(esc(iname)) = gtype_abstracts[:GObject] )
    end
    #ntypes = mutable(Cuint)
    #interfaces = ccall((:g_type_interfaces, libgobject), Ptr{GType}, (GType, Ptr{Cuint}), gtyp, ntypes)
    #for i = 1:ntypes[]
    #    interface = unsafe_load(interfaces, i)
    #    # what do we care to do here?!
    #end
    #g_free(interfaces)
    parent = g_type_parent(gtyp)
    @assert parent != 0
    piname = g_type_name(parent)
    piface_decl = get_itype_decl(piname, parent)
    quote
        if $(QuoteNode(iname)) in keys(gtype_abstracts)
            const $(esc(iname)) = gtype_abstracts[$(QuoteNode(iname))]
        else
            $piface_decl
            @compat abstract type $(esc(iname)) <: $(esc(piname)) end
            gtype_abstracts[$(QuoteNode(iname))] = $(esc(iname))
        end
        nothing
    end
end

get_gtype_decl(name::Symbol, lib, symname::Expr) =
    :( GLib.g_type{T <: $(esc(name))}(::Type{T}) = $(esc(symname)) )
let handled = Set()
function get_gtype_decl(name::Symbol, lib, symname::Symbol)
    if !(name in handled)
        push!(handled, name)
        return :( GLib.g_type{T <: $(esc(name))}(::Type{T}) =
                  ccall(($(QuoteNode(Symbol(string(symname, "_get_type")))), $(esc(lib))), GType, ()) )
    end
    nothing
end
end #let

function get_type_decl(name, iname, gtyp, gtype_decl)
    ename = esc(name)
    einame = esc(iname)
    quote
        if $(QuoteNode(iname)) in keys(gtype_wrappers)
            const $einame = gtype_abstracts[$(QuoteNode(iname))]
        else
            $(get_itype_decl(iname, gtyp))
        end
        type $ename <: $einame
            handle::Ptr{GObject}
            function $ename(handle::Ptr{GObject})
                if handle == C_NULL
                    error($("Cannot construct $name with a NULL pointer"))
                end
                return gobject_ref(new(handle))
            end
        end
        local kwargs, T #to prevent Julia-0.2 from name-mangling kwargs, <: T
        function $ename(args...; kwargs...)
            if isempty(kwargs)
                error(MethodError($ename, args))
            end
            w = $ename(args...)
            for (kw, val) in kwargs
                setproperty!(w, kw, val)
            end
            w
        end
        gtype_wrappers[$(QuoteNode(iname))] = $ename
        macro $einame(args...)
            Base.depwarn(string("\@", $einame, " is deprecated, use ", $einame, " instead."), :Gtk)
            Expr(:call, $ename, map(esc, args)...)
        end
        function $einame(args...; kwargs...)
            $ename(args...; kwargs...)
        end
        $gtype_decl
        nothing
    end
end

macro Gtype_decl(name, gtyp, gtype_decl)
    get_type_decl(name, Symbol(string(name, current_module().suffix)), gtyp, gtype_decl)
end

macro Gtype(iname, lib, symname)
    gtyp = g_type(iname, lib, symname)
    if gtyp == 0
        return Expr(:call, :error, string("Could not find ", symname, " in ", lib,
            ". This is likely a issue with a missing Gtk.jl version check."))
    end
    @assert iname === g_type_name(gtyp)
    if !g_type_test_flags(gtyp, G_TYPE_FLAG_CLASSED)
        error("GType is currently only implemented for G_TYPE_FLAG_CLASSED")
    end
    gtype_decl = get_gtype_decl(iname, lib, symname)
    name = Symbol(string(iname, current_module().suffix))
    get_type_decl(name, iname, gtyp, gtype_decl)
end

macro Gabstract(iname, lib, symname)
    gtyp = g_type(iname, lib, symname)
    if gtyp == 0
        return Expr(:call, :error, string("Could not find ", symname, " in ", lib, ". This is likely a issue with a missing Gtk.jl version check."))
    end
    @assert iname === g_type_name(gtyp)
    Expr(:block,
        get_itype_decl(iname, gtyp),
        get_gtype_decl(iname, lib, symname))
end

macro Giface(iname, lib, symname)
    gtyp = g_type(iname, lib, symname)
    if gtyp == 0
        return Expr(:call, :error, string("Could not find ", symname, " in ", lib, ". This is likely a issue with a missing Gtk.jl version check."))
    end
    @assert iname === g_type_name(gtyp)
    gtype_decl = get_gtype_decl(iname, lib, symname)
    get_interface_decl(iname::Symbol, gtyp::GType, gtype_decl)
end


macro quark_str(q)
    :( ccall((:g_quark_from_string, libglib), UInt32, (Ptr{UInt8},), bytestring($q)) )
end

unsafe_convert{T <: GBoxed}(::Type{Ptr{T}}, box::T) = convert(Ptr{T}, box.handle)
convert(::Type{GBoxed}, boxed::GBoxed) = boxed
convert(::Type{GBoxedUnkown}, boxed::GBoxedUnkown) = boxed
convert{T <: GBoxed}(::Type{T}, boxed::T) = boxed
convert{T <: GBoxed}(::Type{T}, boxed::GBoxed) = convert(T, boxed.handle)
convert(::Type{GBoxed}, unbox::Ptr{GBoxed}) = GBoxedUnkown(unbox)
convert{T <: GBoxed}(::Type{GBoxed}, unbox::Ptr{T}) = GBoxedUnkown(unbox)
convert{T <: GBoxed}(::Type{T}, unbox::Ptr{GBoxed}) = convert(T, convert(Ptr{T}, unbox))
convert{T <: GBoxed}(::Type{T}, unbox::Ptr{T}) = T(unbox)

# All GObjects are expected to have a 'handle' field
# of type Ptr{GObject} corresponding to the GLib object
# or to override this method (e.g. GtkNullContainer, AbstractString)
unsafe_convert(::Type{Ptr{GObject}}, w::GObject) = w.handle

# this method should be used by gtk methods returning widgets of unknown type
# and/or that might have been wrapped by julia before,
# instead of a direct call to the constructor
convert{T <: GObject}(::Type{T}, w::Ptr{GObject}) = convert(T, convert(Ptr{T}, w)) # this definition must be first due to a 0.2 dispatch bug

function convert{T <: GObject}(::Type{T}, ptr::Ptr{T})
    hnd = convert(Ptr{GObject}, ptr)
    if hnd == C_NULL
        throw(UndefRefError())
    end
    x = ccall((:g_object_get_qdata, libgobject), Ptr{GObject}, (Ptr{GObject}, UInt32), hnd, jlref_quark::UInt32)
    if x != C_NULL
        return gobject_ref(unsafe_pointer_to_objref(x)::T)
    end
    wrap_gobject(hnd)::T
end

function wrap_gobject(hnd::Ptr{GObject})
    gtyp = G_OBJECT_CLASS_TYPE(hnd)
    typname = g_type_name(gtyp)
    while !(typname in keys(gtype_wrappers))
        gtyp = g_type_parent(gtyp)
        @assert gtyp != 0
        typname = g_type_name(gtyp)
    end
    T = gtype_wrappers[typname]
    return T(hnd)
end

eltype{T <: GObject}(::Type{_LList{T}}) = T
ref_to{T <: GObject}(::Type{T}, x) = gobject_ref(unsafe_convert(Ptr{GObject}, x))
deref_to{T <: GObject}(::Type{T}, x::Ptr) = convert(T, x)
empty!{T <: GObject}(li::Ptr{_LList{Ptr{T}}}) = gc_unref(unsafe_load(li).data)

### Miscellaneous types
baremodule GConnectFlags
    const AFTER = 1
    const SWAPPED = 2
    get(s::Symbol) =
        if s === :after
            AFTER
        elseif s === :swapped
            SWAPPED
        else
            Main.Base.error(Main.Base.string("invalid GConnectFlag ", s))
        end
end

### Garbage collection [prevention]
const gc_preserve = ObjectIdDict() # reference counted closures
function gc_ref(x::ANY)
    global gc_preserve
    local ref::Ref{Any}, cnt::Int
    if x in keys(gc_preserve)
        ref, cnt = gc_preserve[x]::Tuple{Ref{Any}, Int}
    else
        ref = Ref{Any}(x)
        cnt = 0
    end
    gc_preserve[x] = (ref, cnt + 1)
    return unsafe_load(convert(Ptr{Ptr{Void}}, unsafe_convert(Ptr{Any}, ref)))
end
function gc_unref(x::ANY)
    global gc_preserve
    ref, cnt = gc_preserve[x]::Tuple{Ref{Any}, Int}
    @assert cnt > 0
    if cnt == 1
        delete!(gc_preserve, x)
    else
        gc_preserve[x] = (ref, cnt - 1)
    end
    nothing
end
gc_ref_closure{T}(x::T) = (gc_ref(x), cfunction(_gc_unref, Void, (Any, Ptr{Void})))
_gc_unref(x::ANY, ::Ptr{Void}) = gc_unref(x)

# generally, you shouldn't be calling gc_ref(::Ptr{GObject})
gc_ref(x::Ptr{GObject}) = ccall((:g_object_ref, libgobject), Void, (Ptr{GObject},), x)
gc_unref(x::Ptr{GObject}) = ccall((:g_object_unref, libgobject), Void, (Ptr{GObject},), x)

const gc_preserve_glib = Dict{Union{WeakRef, GObject}, Bool}() # glib objects
const gc_preserve_glib_lock = Ref(false) # to satisfy this lock, must never decrement a ref counter while it is held
const topfinalizer = Ref(true) # keep recursion to a minimum by only iterating from the top
const await_finalize = Any[]

function finalize_gc_unref(x::ANY)
    # this records that the are no user references left to the object from Julia
    # and notifies GLib that it can free the object (if no reference exist from C)
    # it is intended to be called by GC, not in user code function
    istop = topfinalizer[]
    topfinalizer[] = false
    gc_preserve_glib_lock[] = true
    delete!(gc_preserve_glib, x)
    if x.handle != C_NULL
        gc_preserve_glib[x] = true # convert to a strong-reference
        gc_preserve_glib_lock[] = false
        gc_unref(unsafe_convert(Ptr{GObject}, x)) # may clear the strong reference
    else
        gc_preserve_glib_lock[] = false
    end
    topfinalizer[] = istop
    istop && run_delayed_finalizers()
    nothing
end

function delref(x::ANY)
    # internal helper function
    # for v0.4 compat, this is toplevel function
    exiting[] && return # unnecessary to cleanup if we are about to die anyways
    if gc_preserve_glib_lock[] || g_yielded[]
        push!(await_finalize, x)
        return # avoid running finalizers at random times
    end
    finalize_gc_unref(x)
    nothing
end
function addref(x::ANY)
    # internal helper function
    # for v0.4 compat, this is toplevel function
    ccall((:g_object_ref_sink, libgobject), Ptr{GObject}, (Ptr{GObject},), x)
    finalizer(x, delref)
    delete!(gc_preserve_glib, x) # in v0.2, the WeakRef assignment below wouldn't update the key
    gc_preserve_glib[WeakRef(x)] = false # record the existence of the object, but allow the finalizer
    nothing
end
function gobject_ref{T <: GObject}(x::T)
    gc_preserve_glib_lock[] = true
    strong = get(gc_preserve_glib, x, nothing)
    if strong === nothing
        # we haven't seen this before, setup the metadata
        deref = cfunction(gc_unref, Void, (Ref{T},))
        ccall((:g_object_set_qdata_full, libgobject), Void,
            (Ptr{GObject}, UInt32, Any, Ptr{Void}), x, jlref_quark::UInt32, x,
            deref) # add a circular reference to the Julia object in the GObject
        addref(x)
    elseif strong
        # oops, we previously deleted the link, but now it's back
        addref(x)
    else
        # already gc-protected, nothing to do
    end
    gc_preserve_glib_lock[] = false
    run_delayed_finalizers()
    return x
end
gc_ref(x::GObject) = pointer_from_objref(gobject_ref(x))

function run_delayed_finalizers()
    exiting[] && return # unnecessary to cleanup if we are about to die anyways
    g_yielded[] && return # can't run them right now
    topfinalizer[] = false
    while !isempty(await_finalize)
        x = pop!(await_finalize)
        finalize_gc_unref(x)
    end
    topfinalizer[] = true
end

function gc_unref_weak(x::GObject)
    # this strongly destroys and invalidates the object
    # it is intended to be called by GLib, not in user code function
    # note: this may be called multiple times by GLib
    x.handle = C_NULL
    gc_preserve_glib_lock[] = true
    delete!(gc_preserve_glib, x)
    gc_preserve_glib_lock[] = false
    nothing
end

function gc_unref(x::GObject)
    # this strongly destroys and invalidates the object
    # it is intended to be called by GLib, not in user code function
    ref = ccall((:g_object_get_qdata, libgobject), Ptr{Void}, (Ptr{GObject}, UInt32), x, jlref_quark::UInt32)
    if ref != C_NULL && x !== unsafe_pointer_to_objref(ref)
        # We got called because we are no longer the default object for this handle, but we are still alive
        warn("Duplicate Julia object creation detected for GObject")
        deref = cfunction(gc_unref_weak, Void, (Ref{typeof(x)},))
        ccall((:g_object_weak_ref, libgobject), Void, (Ptr{GObject}, Ptr{Void}, Any), x, deref, x)
    else
        ccall((:g_object_steal_qdata, libgobject), Any, (Ptr{GObject}, UInt32), x, jlref_quark::UInt32)
        gc_unref_weak(x)
    end
    nothing
end

gc_unref(::Ptr{GObject}, x::GObject) = gc_unref(x)
gc_ref_closure(x::GObject) = (gc_ref(x), C_NULL)

function gc_force_floating(x::GObject)
    ccall((:g_object_force_floating, libgobject), Void, (Ptr{GObject},), x)
end
function gobject_move_ref(new::GObject, old::GObject)
    h = unsafe_convert(Ptr{GObject}, new)
    @assert h == unsafe_convert(Ptr{GObject}, old) != C_NULL
    gc_ref(h)
    gc_unref(old)
    gc_ref(new)
    gc_unref(h)
    new
end
