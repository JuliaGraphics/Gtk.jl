abstract GObject

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
    #(:GVariant,  Ptr{GVariant},    GVariant,       :variant),
    )
# NOTE: in general do not cache ids, except for these fundamental values
g_type_from_name(name::Symbol) = ccall((:g_type_from_name,libgobject),GType,(Ptr{Uint8},),name)
const fundamental_ids = tuple(Int[g_type_from_name(name) for (name,c,j,f) in fundamental_types]...)
# this constant is needed elsewhere, but doesn't have a matching Julia type so it can't be used from g_type
const gboxed_id = g_type_from_name(:GBoxed)

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
new{T}(::Type{T}, args...) = T(args...)

gtypes(types...) = GType[g_type(t) for t in types]

const gtype_ifaces = Dict{Symbol,Type}()
const gtype_wrappers = Dict{Symbol,Type}()

gtype_ifaces[:GObject] = GObject
gtype_wrappers[:GObject] = GObjectLeaf

let libs = Dict{String,Any}()
global g_type
function g_type(name::Symbol, lib, symname::Symbol)
    if name in keys(gtype_wrappers)
        return g_type(gtype_wrappers[name])
    end
    if !isa(lib,String)
        lib = eval(current_module(), lib)
    end
    libptr = get(libs, lib, C_NULL)::Ptr{Void}
    if libptr == C_NULL
        libs[lib] = libptr = dlopen(lib)
    end
    fnptr = dlsym_e(libptr, string(symname,"_get_type"))
    if fnptr != C_NULL
        ccall(fnptr, GType, ())
    else
        convert(GType, 0)
    end
end
g_type(name::Symbol, lib, symname::Expr) = eval(current_module(), symname)
end

function get_interface_decl(gtyp::GType)
    #TODO
end

function get_itype_decl(iname::Symbol, gtyp::GType)
    if isdefined(current_module(), iname)
        return nothing
    end
    if iname === :GObject
        return :( const $(esc(iname)) = gtype_ifaces[:GObject] )
    end
    #ntypes = mutable(Cuint)
    #interfaces = ccall((:g_type_interfaces,libgobject),Ptr{GType},(GType,Ptr{Cuint}),gtyp,ntypes)
    #println(g_type_name(gtyp), " implements ->")
    #for i = 1:ntypes[]
    #    interface = unsafe_load(interfaces,i)
    #    println("  ",g_type_name(interface))
    #end
    parent = g_type_parent(gtyp)
    @assert parent != 0
    piname = g_type_name(parent)
    piface_decl = get_itype_decl(piname, parent)
    :(
        if $(Meta.quot(iname)) in keys(gtype_ifaces)
            const $(esc(iname)) = gtype_ifaces[$(Meta.quot(iname))]
            nothing
        else
            $piface_decl
            abstract $(esc(iname)) <: $(esc(piname))
            gtype_ifaces[$(Meta.quot(iname))] = $(esc(iname))
            nothing
        end
    )
end

get_gtype_decl(name::Symbol, lib, symname::Expr) =
    :( GLib.g_type(::Type{$(esc(name))}) = $(esc(symname)) )
get_gtype_decl(name::Symbol, lib, symname::Symbol) =
    :( GLib.g_type(::Type{$(esc(name))}) =
        ccall(($(Meta.quot(symbol(string(symname,"_get_type")))), $(esc(lib))), GType, ()) )

function get_type_decl(name,iname,gtyp,gtype_decl)
    ename = esc(name)
    einame = esc(iname)
    cm = current_module()
    :(begin
        if $(Meta.quot(iname)) in keys(gtype_wrappers)
            const $einame = gtype_ifaces[$(QuoteNode(iname))]
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
        function $ename(args...; kwargs...)
            w = $ename(args...)
            for (kw,val) in kwargs
                $cm._.(kw)(w, val)
            end
            w
        end
        GLib.new(::Type{$einame}, args...) = $ename(args...)
        gtype_wrappers[$(QuoteNode(iname))] = $ename
        $(gtype_decl)
        nothing
    end)
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
        error("not implemented yet")
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
    @assert name === g_type_name(gtyp)
    Expr(:block,
        get_itype_decl(iname, gtyp),
        get_gtype_decl(iname, lib, symname))
end

macro quark_str(q)
    :( ccall((:g_quark_from_string, libglib), Uint32, (Ptr{Uint8},), bytestring($q)) )
end
const jlref_quark = quark"julia_ref"

# All GObjects are expected to have a 'handle' field
# of type Ptr{GObject} corresponding to the GLib object
convert(::Type{Ptr{GObject}},w::GObject) = w.handle
convert{T<:GObject}(::Type{T},w::Ptr{T}) = convert(T,convert(Ptr{GObject},w))
eltype{T<:GObject}(::_LList{T}) = T

# this could be used for gtk methods returing widgets of unknown type
# and/or might have been wrapped by julia before
function convert{T<:GObject}(::Type{T}, hnd::Ptr{GObject})
    if hnd == C_NULL
        error("cannot convert null pointer to GObject")
    end
    x = ccall((:g_object_get_qdata, libgobject), Ptr{GObject}, (Ptr{GObject},Uint32), hnd, jlref_quark)
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

const gc_preserve_gtk = WeakKeyDict{GObject,Union(Bool,GObject)}() # gtk objects
function gc_ref{T<:GObject}(x::T)
    global gc_preserve_gtk
    addref = function()
        ccall((:g_object_ref_sink,libgobject),Ptr{GObject},(Ptr{GObject},),x)
        finalizer(x,function(x)
                global gc_preserve_gtk
                if x.handle != C_NULL
                    gc_preserve_gtk[x] = x # convert to a strong-reference
                    ccall((:g_object_unref,libgobject),Void,(Ptr{GObject},),x) # may clear the strong reference
                else
                    delete!(gc_preserve_gtk, x) # x is invalid, ensure we are dead
                end
            end)
        gc_preserve_gtk[x] = true # record the existence of the object, but allow the finalizer
    end
    ref = get(gc_preserve_gtk,x,nothing)
    if isa(ref,Nothing)
        ccall((:g_object_set_qdata_full, libgobject), Void,
            (Ptr{GObject}, Uint32, Any, Ptr{Void}), x, jlref_quark, x,
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
    ref = ccall((:g_object_get_qdata,libgobject),Ptr{Void},(Ptr{GObject},Uint32),x,jlref_quark)
    if ref != C_NULL && x !== unsafe_pointer_to_objref(ref)
        # We got called because we are no longer the default object for this handle, but we are still alive
        warn("Duplicate Julia object creation detected for GObject")
        ccall((:g_object_weak_ref,libgobject),Void,(Ptr{GObject},Ptr{Void},Any),x,cfunction(gc_unref_weak,Void,(typeof(x),)),x)
    else
        ccall((:g_object_steal_qdata,libgobject),Any,(Ptr{GObject},Uint32),x,jlref_quark)
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
    @assert old.handle == new.handle != C_NULL
    gc_unref(old)
    gc_force_floating(new)
    gc_ref(new)
end

