abstract GObject
abstract GInterface <: GObject
abstract GBoxed
type GBoxedUnkown<:GBoxed
    handle::Ptr{GBoxed}
end

typealias Enum Int32
typealias GType Csize_t
immutable GParamSpec
  g_type_instance::Ptr{Void}
  name::Ptr{Uint8}
  flags::Cint
  value_type::GType
  owner_type::GType
end

const fundamental_types = (
    #(:name,      Ctype,            JuliaType,      g_value_fn)
    (:invalid,    Void,             Void,           :error),
    (:void,       Nothing,          Nothing,        :error),
    (:GInterface, Ptr{Void},        GInterface,     :error),
    (:gchar,      Int8,             Int8,           :schar),
    (:guchar,     Uint8,            Uint8,          :uchar),
    (:gboolean,   Cint,             Bool,           :boolean),
    (:gint,       Cint,             None,           :int),
    (:guint,      Cuint,            None,           :uint),
    (:glong,      Clong,            None,           :long),
    (:gulong,     Culong,           None,           :ulong),
    (:gint64,     Int64,            Signed,         :int64),
    (:guint64,    Uint64,           Unsigned,       :uint64),
    (:GEnum,      Enum,             None,           :enum),
    (:GFlags,     Enum,             None,           :flags),
    (:gfloat,     Float32,          Float32,        :float),
    (:gdouble,    Float64,          FloatingPoint,  :double),
    (:gchararray, Ptr{Uint8},       String,         :string),
    (:gpointer,   Ptr{Void},        Ptr,            :pointer),
    (:GBoxed,     Ptr{GBoxed},      GBoxed,         :boxed),
    (:GParam,     Ptr{GParamSpec},  Ptr{GParamSpec},:param),
    (:GObject,    Ptr{GObject},     GObject,        :object),
    #(:GVariant,  Ptr{GVariant},    GVariant,       :variant),
    )
# NOTE: in general do not cache ids, except for these fundamental values
g_type_from_name(name::Symbol) = ccall((:g_type_from_name,libgobject),GType,(Ptr{Uint8},),name)
const fundamental_ids = tuple(GType[g_type_from_name(name) for (name,c,j,f) in fundamental_types]...)

g_type(gtyp::GType) = gtyp
let jtypes = Expr(:block, :( g_type(::Type{Void}) = $(g_type_from_name(:void)) ))
    for (i,(name, ctype, juliatype, g_value_fn)) in enumerate(fundamental_types)
        if juliatype !== None
            push!(jtypes.args, :( g_type{T<:$juliatype}(::Type{T}) = convert(GType,$(fundamental_ids[i])) ))
        end
    end
    eval(jtypes)
end

G_TYPE_FROM_CLASS(w::Ptr{Void}) = unsafe_load(convert(Ptr{GType},w))
G_OBJECT_GET_CLASS(w::GObject) = G_OBJECT_GET_CLASS(w.handle)
G_OBJECT_GET_CLASS(hnd::Ptr{GObject}) = unsafe_load(convert(Ptr{Ptr{Void}},hnd))
G_OBJECT_CLASS_TYPE(w) = G_TYPE_FROM_CLASS(G_OBJECT_GET_CLASS(w))

g_isa(gtyp::GType, is_a_type::GType) = bool(ccall((:g_type_is_a,libgobject),Cint,(GType,GType),gtyp,is_a_type))
g_type_parent(child::GType) = ccall((:g_type_parent, libgobject), GType, (GType,), child)
g_type_name(g_type::GType) = symbol(bytestring(ccall((:g_type_name,libgobject),Ptr{Uint8},(GType,),g_type),false))

g_type_test_flags(g_type::GType, flag) = ccall((:g_type_test_flags,libgobject), Bool, (GType,Enum), g_type, flag)
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
        gc_ref(new(handle))
    end
end
g_type(obj::GObject) = g_type(typeof(obj))

gtypes(types...) = GType[g_type(t) for t in types]

const gtype_abstracts = Dict{Symbol,Type}()
const gtype_wrappers = Dict{Symbol,Type}()
const gtype_ifaces = Dict{Symbol,Type}()

gtype_abstracts[:GObject] = GObject
gtype_wrappers[:GObject] = GObjectLeaf

let libs = Dict{String,Any}()
global get_fn_ptr
function get_fn_ptr(fnname, lib)
    if !isa(lib,String)
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
    fnptr = get_fn_ptr(string(symname,"_get_type"), lib)
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
                $(esc(iname))(x::GObject) = new(convert(Ptr{GObject},x), x)
                # Gtk does an interface type check when calling methods. So, it's
                # not worth repeating it here. Plus, we might as well just allow
                # the user to lie, since we aren't using this for dispatch
                # (like C & unlike most other languages), the user may be able 
                # to write more generic code
            end
            gtype_ifaces[$(QuoteNode(iname))] = $(esc(iname))
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
    #interfaces = ccall((:g_type_interfaces,libgobject),Ptr{GType},(GType,Ptr{Cuint}),gtyp,ntypes)
    #for i = 1:ntypes[]
    #    interface = unsafe_load(interfaces,i)
    #    # what do we care to do here?!
    #end
    #c_free(interfaces)
    parent = g_type_parent(gtyp)
    @assert parent != 0
    piname = g_type_name(parent)
    piface_decl = get_itype_decl(piname, parent)
    quote
        if $(QuoteNode(iname)) in keys(gtype_abstracts)
            const $(esc(iname)) = gtype_abstracts[$(QuoteNode(iname))]
        else
            $piface_decl
            abstract $(esc(iname)) <: $(esc(piname))
            gtype_abstracts[$(QuoteNode(iname))] = $(esc(iname))
        end
        nothing
    end
end

get_gtype_decl(name::Symbol, lib, symname::Expr) =
    :( GLib.g_type(::Type{$(esc(name))}) = $(esc(symname)) )
get_gtype_decl(name::Symbol, lib, symname::Symbol) =
    :( GLib.g_type(::Type{$(esc(name))}) =
        ccall(($(QuoteNode(symbol(string(symname,"_get_type")))), $(esc(lib))), GType, ()) )

function get_type_decl(name,iname,gtyp,gtype_decl)
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
                gc_ref(new(handle))
            end
        end
        local kwargs #to prevent Julia-0.2 from name-mangling kwargs
        function $ename(args...; kwargs...)
            if isempty(kwargs)
                error(MethodError($ename, args))
            end
            w = $ename(args...)
            for (kw,val) in kwargs
                setproperty!(w, kw, val)
            end
            w
        end
        gtype_wrappers[$(QuoteNode(iname))] = $ename
        macro $einame(args...)
            Expr(:call, $ename, map(esc,args)...)
        end
        $gtype_decl
        nothing
    end
end

macro Gtype_decl(name,gtyp,gtype_decl)
    get_type_decl(name,symbol(string(name,current_module().suffix)),gtyp,gtype_decl)
end

macro Gtype(iname,lib,symname)
    gtyp = g_type(iname, lib, symname)
    if gtyp == 0
        return Expr(:call,:error,string("Could not find ",symname," in ",lib,
            ". This is likely a issue with a missing Gtk.jl version check."))
    end
    @assert iname === g_type_name(gtyp)
    if !g_type_test_flags(gtyp, G_TYPE_FLAG_CLASSED)
        error("GType is currently only implemented for G_TYPE_FLAG_CLASSED")
    end
    name = symbol(string(iname,current_module().suffix))
    gtype_decl = get_gtype_decl(name, lib, symname)
    get_type_decl(name, iname, gtyp, gtype_decl)
end

macro Gabstract(iname,lib,symname)
    gtyp = g_type(iname, lib, symname)
    if gtyp == 0
        return Expr(:call,:error,string("Could not find ",symname," in ",lib,". This is likely a issue with a missing Gtk.jl version check."))
    end
    @assert iname === g_type_name(gtyp)
    Expr(:block,
        get_itype_decl(iname, gtyp),
        get_gtype_decl(iname, lib, symname))
end

macro Giface(iname,lib,symname)
    gtyp = g_type(iname, lib, symname)
    if gtyp == 0
        return Expr(:call,:error,string("Could not find ",symname," in ",lib,". This is likely a issue with a missing Gtk.jl version check."))
    end
    @assert iname === g_type_name(gtyp)
    gtype_decl = get_gtype_decl(iname, lib, symname)
    get_interface_decl(iname::Symbol, gtyp::GType, gtype_decl)
end


macro quark_str(q)
    :( ccall((:g_quark_from_string, libglib), Uint32, (Ptr{Uint8},), bytestring($q)) )
end

# All GObjects are expected to have a 'handle' field
# of type Ptr{GObject} corresponding to the GLib object
convert(::Type{Ptr{GObject}},w::GObject) = w.handle
convert{T<:GObject}(::Type{T},w::Ptr{T}) = convert(T,convert(Ptr{GObject},w))
eltype{T<:GObject}(::Type{_LList{T}}) = T
ref_to{T<:GObject}(::Type{T}, x) = gc_ref(convert(Ptr{GObject},x))
deref_to{T<:GObject}(::Type{T}, x::Ptr) = convert(T,x)
empty!{T<:GObject}(li::Ptr{_LList{Ptr{T}}}) = gc_unref(unsafe_load(li).data)

convert{T<:GBoxed}(::Type{Ptr{T}},box::T) = convert(Ptr{T},box.handle)
convert{T<:GBoxed}(::Type{T},unbox::Ptr{GBoxed}) = convert(T,convert(Ptr{T},unbox))
convert{T<:GBoxed}(::Type{T},unbox::Ptr{T}) = T(unbox)
convert{T<:GBoxed}(::Type{GBoxed},unbox::Ptr{T}) = GBoxedUnkown(unbox)
convert{T<:GBoxed}(::Type{T},unbox::GBoxedUnkown) = convert(T, unbox.handle)

# this could be used for gtk methods returing widgets of unknown type
# and/or might have been wrapped by julia before
function convert{T<:GObject}(::Type{T}, hnd::Ptr{GObject})
    if hnd == C_NULL
        error(UndefRefError())
    end
    x = ccall((:g_object_get_qdata, libgobject), Ptr{GObject}, (Ptr{GObject},Uint32), hnd, jlref_quark::Uint32)
    if x != C_NULL
        return unsafe_pointer_to_objref(x)::T
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
            Main.Base.error(Main.Base.string("invalid GConnectFlag ",s))
        end
end

### Garbage collection [prevention]
const gc_preserve = ObjectIdDict() # reference counted closures
function gc_ref(x::ANY)
    global gc_preserve
    isbits(x) && error("can't gc-preserve an isbits object")
    gc_preserve[x] = (get(gc_preserve, x, 0)::Int)+1
    x
end
function gc_unref(x::ANY)
    global gc_preserve
    @assert !isbits(x)
    count = get(gc_preserve, x, 0)::Int-1
    if count <= 0
        delete!(gc_preserve, x)
    end
    nothing
end
gc_ref_closure{T}(x::T) = (gc_ref(x);cfunction(gc_unref, Void, (T, Ptr{Void})))
gc_unref(x::Any, ::Ptr{Void}) = gc_unref(x)

# generally, you shouldn't need to call gc_ref(::Ptr)
gc_ref(x::Ptr{GObject}) = ccall((:g_object_ref,libgobject),Void,(Ptr{GObject},),x)
gc_unref(x::Ptr{GObject}) = ccall((:g_object_unref,libgobject),Void,(Ptr{GObject},),x)

const gc_preserve_gtk = WeakKeyDict{GObject,Union(Bool,GObject)}() # gtk objects
function gc_ref{T<:GObject}(x::T)
    global gc_preserve_gtk
    addref = function()
        ccall((:g_object_ref_sink,libgobject),Ptr{GObject},(Ptr{GObject},),x)
        finalizer(x,function(x)
                global gc_preserve_gtk, exiting
                if exiting
                    return # unnecessary to cleanup if we are about to die anyways
                end
                if x.handle != C_NULL
                    gc_preserve_gtk[x] = x # convert to a strong-reference
                    gc_unref(convert(Ptr{GObject},x)) # may clear the strong reference
                else
                    delete!(gc_preserve_gtk, x) # x is invalid, ensure we are dead
                end
            end)
        gc_preserve_gtk[x] = true # record the existence of the object, but allow the finalizer
    end
    ref = get(gc_preserve_gtk,x,nothing)
    if isa(ref,Nothing)
        ccall((:g_object_set_qdata_full, libgobject), Void,
            (Ptr{GObject}, Uint32, Any, Ptr{Void}), x, jlref_quark::Uint32, x,
            cfunction(gc_unref, Void, (T,))) # add a circular reference to the Julia object in the GObject
        addref()
    elseif !isa(ref,WeakRef)
        # oops, we previously deleted the link, but now it's back
        addref()
    else
        # already gc-protected, nothing to do
    end
    x
end


function gc_unref_weak(x::GObject)
    # this strongly destroys and invalidates the object
    # it is intended to be called by GLib, not in user code function
    # note: this may be called multiple times by GLib
    x.handle = C_NULL
    global gc_preserve_gtk
    delete!(gc_preserve_gtk, x)
    nothing
end
function gc_unref(x::GObject)
    # this strongly destroys and invalidates the object
    # it is intended to be called by GLib, not in user code function
    ref = ccall((:g_object_get_qdata,libgobject),Ptr{Void},(Ptr{GObject},Uint32),x,jlref_quark::Uint32)
    if ref != C_NULL && x !== unsafe_pointer_to_objref(ref)
        # We got called because we are no longer the default object for this handle, but we are still alive
        warn("Duplicate Julia object creation detected for GObject")
        ccall((:g_object_weak_ref,libgobject),Void,(Ptr{GObject},Ptr{Void},Any),x,cfunction(gc_unref_weak,Void,(typeof(x),)),x)
    else
        ccall((:g_object_steal_qdata,libgobject),Any,(Ptr{GObject},Uint32),x,jlref_quark::Uint32)
        gc_unref_weak(x)
    end
    nothing
end
gc_unref(::Ptr{GObject}, x::GObject) = gc_unref(x)
gc_ref_closure(x::GObject) = C_NULL

function gc_force_floating(x::GObject)
    ccall((:g_object_force_floating,libgobject),Void,(Ptr{GObject},),x)
end
function gc_move_ref(new::GObject, old::GObject)
    h = convert(Ptr{GObject}, new)
    @assert h == convert(Ptr{GObject}, old) != C_NULL
    gc_ref(h)
    gc_unref(old)
    gc_ref(new)
    gc_unref(h)
end
