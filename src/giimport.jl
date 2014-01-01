
const _gi_modules = Dict{Symbol,Module}()
const _gi_modsyms = Dict{(Symbol,Symbol),Any}()

module GI
    #eval quote module seems to mess the parent module, isolate
    function create_module(modname::Symbol)
        eval(quote module ($modname) end; $modname end)
    end
end


function init_ns(name::Symbol)
    if haskey(_gi_modules,name)
        return
    end
    gns = GINamespace(name)
    for path=get_shlibs(gns) 
        dlopen(path,RTLD_GLOBAL) 
    end
    # use submodules to GI module later
    modname = symbol("_$name")
    mod = GI.create_module(modname)
    setconst(mod,:_gi_ns,gns) #eval(quote module const) didn't seem to work
    setconst(mod,:Gtk,Gtk) 
    _gi_modules[name] = mod
end
setconst(mod,name,val) = eval(mod, :(const $name = $(Expr(:quote,val))))

init_ns(:GObject)
_ns(name) = (init_ns(name); _gi_modules[name])

ensure_name(mod::Module, name) = ensure_name(mod._gi_ns, name)
function ensure_name(ns::GINamespace, name::Symbol)
    if haskey(_gi_modsyms,(ns.name, name))
        return 
    end
    _gi_modsyms[(ns.name,name)] = load_name(ns,name,ns[name])
end

function load_name(ns,name,info::GIObjectInfo)
    otype, oiface = create_type(info)
    ensure_method(ns,name,:new) #FIXME: new might not exist
    otype
end

#can probably  be merged into the modsym dict
const _gi_objects = Dict{(Symbol,Symbol),Type}()
const _gi_obj_ifaces = Dict{(Symbol,Symbol),Type}()
_gi_objects[(:GObject,:Object)] = GObjectAny #FIXME
_gi_obj_ifaces[(:GObject,:Object)] = GObjectI 
peval(mod, expr) = (print(expr,'\n'); eval(mod,expr))

function extract_type(info::GIObjectInfo) 
    get( _gi_objects, qual_name(info), GObjectAny)
end

function create_type(info::GIObjectInfo)
    ns = get_namespace(info)
    name = get_name(info)
    qname =(ns,name) # this should be unique in the GObject-o-sphere?
    if haskey(_gi_objects,qname )
        return _gi_objects[qname], _gi_obj_ifaces[qname]
    end
    ptype, piface = create_type(get_parent(info))
    #convention from gtktypes, but maybe not good in general?
    iname = symbol("$(name)I")
    NS = _ns(ns)
    otype, oiface = peval(NS, quote
        abstract ($iname) <: ($piface)
        type ($name) <: ($iname)
            handle::Ptr{Gtk.GObjectI}
            $name(handle::Ptr{Gtk.GObjectI}) = (handle != C_NULL ? Gtk.gc_ref(new(handle)) : error($("Cannot construct $name with a NULL pointer")))
        end #FIXME
        ($name, $iname)
    end)
    _gi_objects[qname] =  otype
    _gi_obj_ifaces[qname] =  oiface
    (otype,oiface)
end

const _gi_methods = Set{(Symbol,Symbol,Symbol)}()
ensure_method(mod::Module, rtype, method) = ensure_method(mod._gi_ns,rtype,method)

function ensure_method(ns::GINamespace, rtype::Symbol, method::Symbol)
    qname = (ns.name,rtype,method)
    if qname in _gi_methods
        return
    end
    create_method(ns[rtype][method])
    push!(_gi_methods,qname)
end
    
c_type(t) = t
c_type{T<:GObjectI}(t::Type{T}) = Ptr{GObjectI}
c_type{T<:ByteString}(t::Type{T}) = Ptr{Uint8}

j_type(t) = t
j_type{T<:Integer}(::Type{T}) = Integer
function create_method(info::GIFunctionInfo)
    ns = get_namespace(info)
    NS = _ns(ns)
    name = get_name(info)
    flags = get_flags(info)
    args = get_args(info)
    argtypes = Type[extract_type(a) for a in args]
    argnames = [symbol("_$(get_name(a))") for a in args]
    if flags & IS_METHOD != 0
        object = get_container(info)
        t, iface = create_type(object)
        unshift!(argtypes, iface)
        unshift!(argnames, :__instance)
    end
    if flags & IS_CONSTRUCTOR != 0
        name = get_name(get_container(info))
    end
    rettype = extract_type(get_return_type(info))
    cargtypes = Expr(:tuple, Any[c_type(a) for a in argtypes]...)
    crettype = c_type(rettype)
    symb = get_symbol(info)
    j_call = Expr(:call, name, [ :($(argnames[i])::$(j_type(argtypes[i]))) for i=1:length(argtypes) ]... )
    c_call = :(ccall($(string(symb)), $(c_type(rettype)), $cargtypes))
    append!(c_call.args, argnames)
    if rettype == None
        #pass
    elseif rettype <: GObjectI 
        #TODO: returned value may be a subtype
        c_call = :( $rettype($c_call) )
    elseif rettype <: ByteString
        c_call = :( bytestring($c_call) )
    end
    peval(NS, Expr(:function, j_call, quote $c_call end))

end
    
