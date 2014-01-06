abstract GObjectI
typealias GObject GObjectI

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
    #(:name,      Ctype,      JuliaType,     g_value_fn)
    #(:invalid,    Void,       Void,          :error),
    #(:void,       Nothing,    Nothing,       :error),
    #(:GInterface, Ptr{Void},        None,           :???),
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
    (:GBoxed,     Ptr{Void},        None,           :boxed),
    (:GParam,     Ptr{GParamSpec},  Ptr{GParamSpec},:param),
    (:GObject,    Ptr{GObject},     GObject,        :object),
    #(:GType,      Int,              None,           :gtype), # this isn't a fundamental type
    #(:GVariant,  Ptr{GVariant},    GVariant,       :variant),
    )
# NOTE: in general do not cache ids, except for the fundamental values
g_type_from_name(name::Symbol) = ccall((:g_type_from_name,libgobject),Int,(Ptr{Uint8},),name)
# these constants are used elsewhere
const gvoid_id = g_type_from_name(:void)
const gboxed_id = g_type_from_name(:GBoxed)
const gobject_id = g_type_from_name(:GObject)
const gstring_id = g_type_from_name(:gchararray)

G_TYPE_FROM_CLASS(w::Ptr{Void}) = unsafe_load(convert(Ptr{GType},w))
G_OBJECT_GET_CLASS(w::GObject) = G_OBJECT_GET_CLASS(w.handle)
G_OBJECT_GET_CLASS(hnd::Ptr{GObjectI}) = unsafe_load(convert(Ptr{Ptr{Void}},hnd))
G_OBJECT_CLASS_TYPE(w) = G_TYPE_FROM_CLASS(G_OBJECT_GET_CLASS(w))

g_type_parent(child::GType) = ccall((:g_type_parent, libgobject), GType, (GType,), child)
g_type_name(g_type::GType) = symbol(bytestring(ccall((:g_type_name,libgobject),Ptr{Uint8},(GType,),g_type),false))

g_type_test_flags(g_type::GType, flag) = ccall((:g_type_test_flags,libgobject), Bool, (GType,Enum), g_type, flag)
const G_TYPE_FLAG_CLASSED           = 1 << 0
const G_TYPE_FLAG_INSTANTIATABLE    = 1 << 1
const G_TYPE_FLAG_DERIVABLE         = 1 << 2
const G_TYPE_FLAG_DEEP_DERIVABLE    = 1 << 3
type GObjectAny <: GObjectI
    handle::Ptr{GObject}
    GObjectAny(handle::Ptr{GObject}) = (handle != C_NULL ? gc_ref(new(handle)) : error("Cannot construct $gname with a NULL pointer"))
end
g_type(::Type{GObjectI}) = gobject_id
g_type(::Type{GObject}) = gobject_id
g_type(::Type{GObjectAny}) = gobject_id

const gtype_ifaces = Dict{Symbol,Type}()
const gtype_wrappers = Dict{Symbol,Type}()

gtype_ifaces[:GObject] = GObjectI
gtype_wrappers[:GObject] = GObjectAny

function g_type(name::Symbol, lib, symname::Symbol)
    if name in keys(gtype_wrappers)
        return g_type(gtype_wrappers[name])
    end
    if !isa(lib,String)
        lib = eval(current_module(),lib)
    end
    libptr = dlopen(lib)
    fnptr = dlsym(libptr, string(symname,"_get_type"))
    typ = ccall(fnptr, GType, ())
    dlclose(libptr)
    typ
end

function get_iface_decl(name::Symbol, iname::Symbol, gtyp::GType)
    if name in keys(gtype_ifaces)
        return nothing
    end
    parent = g_type_parent(gtyp)
    @assert parent != 0
    pname = g_type_name(parent)
    piname = symbol(string(pname,'I'))
    piface_decl = get_iface_decl(pname, piname, parent)
    quote
        $piface_decl
        abstract $(esc(iname)) <: $(esc(piname))
        gtype_ifaces[$(Meta.quot(name))] = $(esc(iname))
    end
end

function get_gtype_decl(name::Symbol, lib, symname::Symbol)
    quote
        GLib.g_type(::Type{$(esc(name))}) = ccall(($(symbol(string(symname,"_get_type"))), $(esc(lib))), GType, ())
    end
end

macro Gtype(name,lib,symname)
    gtyp = g_type(name, lib, symname)
    @assert name === g_type_name(gtyp)
    if !g_type_test_flags(gtyp, G_TYPE_FLAG_CLASSED)
        error("not implemented yet")
    end
    iname = symbol(string(name,'I'))
    quote
        $(get_iface_decl(name, iname, gtyp))
        type $(esc(name)) <: $(esc(iname))
            handle::Ptr{GObjectI}
            $(esc(name))(handle::Ptr{GObjectI}) = (handle != C_NULL ? gc_ref(new(handle)) : error($("Cannot construct $name with a NULL pointer")))
        end
        gtype_wrappers[$(Meta.quot(name))] = $(esc(name))
        $(get_gtype_decl(name, lib, symname))
    end
end

macro Gabstract(iname,lib,symname)
    @assert endswith(string(iname),"I")
    name = symbol(string(iname)[1:end-1])
    gtyp = g_type(name, lib, symname)
    @assert name === g_type_name(gtyp)
    iface_decl = get_iface_decl(name, iname, gtyp)
    quote
        $iface_decl
        $(get_gtype_decl(iname, lib, symname))
    end
end

macro quark_str(q)
    :( ccall((:g_quark_from_string, libglib), Uint32, (Ptr{Uint8},), bytestring($q)) )
end
const jlref_quark = quark"julia_ref"

# All GtkWidgets are expected to have a 'handle' field
# of type Ptr{GObjectI} corresponding to the Gtk object
convert(::Type{Ptr{GObjectI}},w::GObjectI) = w.handle
convert{T<:GObjectI}(::Type{T},w::Ptr{T}) = convert(T,convert(Ptr{GObjectI},w))
eltype{T<:GObjectI}(::GSList{T}) = T

# this could be used for gtk methods returing widgets of unknown type
# and/or might have been wrapped by julia before
function convert{T<:GObjectI}(::Type{T}, hnd::Ptr{GObjectI})
    if hnd == C_NULL
        error("cannot convert null pointer to GObject")
    end
    x = ccall((:g_object_get_qdata, libgobject), Ptr{GObjectI}, (Ptr{GObjectI},Uint32), hnd, jlref_quark)
    if x != C_NULL
        return unsafe_pointer_to_objref(x)::T
    end
    wrap_gobject(hnd)::T
end

function wrap_gobject(hnd::Ptr{GObjectI})
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
    gc_preserve[x] = (get(gc_preserve, x, 0)::Int)+1
    x
end
function gc_unref(x::ANY)
    global gc_preserve
    count = get(gc_preserve, x, 0)::Int-1
    if count <= 0
        delete!(gc_preserve, x)
    end
    nothing
end
gc_ref_closure{T}(x::T) = (gc_ref(x);cfunction(gc_unref, Void, (T, Ptr{Void})))
gc_unref(x::Any, ::Ptr{Void}) = gc_unref(x)

const gc_preserve_gtk = WeakKeyDict{GObjectI,Union(Bool,GObjectI)}() # gtk objects
function gc_ref{T<:GObjectI}(x::T)
    global gc_preserve_gtk
    addref = function()
        ccall((:g_object_ref_sink,libgobject),Ptr{GObjectI},(Ptr{GObjectI},),x)
        finalizer(x,function(x)
                global gc_preserve_gtk
                gc_preserve_gtk[x] = x # convert to a strong-reference
                ccall((:g_object_unref,libgobject),Void,(Ptr{GObjectI},),x) # may clear the strong reference
            end)
        gc_preserve_gtk[x] = true # record the existence of the object, but allow the finalizer
    end
    ref = get(gc_preserve_gtk,x,nothing)
    if isa(ref,Nothing)
        ccall((:g_object_set_qdata_full, libgobject), Void,
            (Ptr{GObjectI}, Uint32, Any, Ptr{Void}), x, jlref_quark, x,
            cfunction(gc_unref, Void, (T,))) # add a circular reference to the Julia object in the GObjectI
        addref()
    elseif !isa(ref,WeakRef)
        # oops, we previously deleted the link, but now it's back
        addref()
    else
        # already gc-protected, nothing to do
    end
    x
end


function gc_unref_weak(x::GObjectI)
    # this strongly destroys and invalidates the object
    # it is intended to be called by Gtk, not in user code function
    # note: this may be called multiple times by Gtk
    x.handle = C_NULL
    global gc_preserve_gtk
    delete!(gc_preserve_gtk, x)
    nothing
end
function gc_unref(x::GObjectI)
    # this strongly destroys and invalidates the object
    # it is intended to be called by Gtk, not in user code function
    ref = ccall((:g_object_get_qdata,libgobject),Ptr{Void},(Ptr{GObjectI},Uint32),x,jlref_quark)
    if ref != C_NULL && x !== unsafe_pointer_to_objref(ref)
        # We got called because we are no longer the default object for this handle, but we are still alive
        warn("Duplicate Julia object creation detected for GObject")
        ccall((:g_object_weak_ref,libgobject),Void,(Ptr{GObjectI},Ptr{Void},Any),x,cfunction(gc_unref_weak,Void,(typeof(x),)),x)
    else
        ccall((:g_object_steal_qdata,libgobject),Any,(Ptr{GObjectI},Uint32),x,jlref_quark)
        gc_unref_weak(x)
    end
    nothing
end
gc_unref(::Ptr{GObjectI}, x::GObjectI) = gc_unref(x)
gc_ref_closure(x::GObjectI) = C_NULL

