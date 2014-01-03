
const _gi_modules = Dict{Symbol,Module}()
const _gi_modsyms = Dict{(Symbol,Symbol),Any}()

module GI
    function create_module(modname,gns,gtk)
        mod = eval(Expr(:toplevel, :(module ($modname) 
            const _gi_ns = $gns
            const Gtk = $gtk
        end), modname))
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
    mod = GI.create_module(modname,gns,Gtk)
    _gi_modules[name] = mod
    mod
end


init_ns(:GObject)
init_ns(:Gtk)
_ns(name) = (init_ns(name); _gi_modules[name])
#TODO: separate GLib.jl and Gtk.jl

gtk_ns = GI._Gtk._gi_ns

ensure_name(mod::Module, name) = ensure_name(mod._gi_ns, name)
function ensure_name(ns::GINamespace, name::Symbol)
    if haskey(_gi_modsyms,(ns.name, name))
        return  _gi_modsyms[(ns.name, name)]
    end
    sym = load_name(ns,name,ns[name])
    _gi_modsyms[(ns.name,name)] = sym
    sym
end

function load_name(ns,name,info::GIObjectInfo)
    otype, oiface = create_type(info)
    if find_method(ns[name], :new) != nothing
        ensure_method(ns,name,:new) 
    end
    otype
end

#can probably  be merged into the modsym dict
const _gi_objects = Dict{(Symbol,Symbol),Type}()
const _gi_obj_ifaces = Dict{(Symbol,Symbol),Type}()
_gi_objects[(:GObject,:Object)] = GObjectAny #FIXME
_gi_obj_ifaces[(:GObject,:Object)] = GObjectI 
peval(mod, expr) = (print(expr,'\n'); eval(mod,expr))

function extract_type(info::GIObjectInfo,ret=false) 
    get( (ret ? _gi_obj_ifaces : _gi_objects), qual_name(info), (ret ? GObjectAny : GObjectI))
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
    NS = _ns(ns)
    iname = symbol("$(name)I")
    otype, oiface = eval(NS, quote
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

const _gi_methods = Dict{(Symbol,Symbol,Symbol),Any}()
ensure_method(mod::Module, rtype, method) = ensure_method(mod._gi_ns,rtype,method)

function ensure_method(ns::GINamespace, rtype::Symbol, method::Symbol)
    qname = (ns.name,rtype,method)
    if haskey( _gi_methods, qname)
        return _gi_methods[qname]
    end
    meth = create_method(ns[rtype][method])
    _gi_methods[qname] = meth
    return meth
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
        if name == :new
            name = symbol("$(get_name(get_container(info)))_new")
        end
    end
    rettype = extract_type(get_return_type(info),true)
    cargtypes = Expr(:tuple, Any[c_type(a) for a in argtypes]...)
    crettype = c_type(rettype)
    symb = get_symbol(info)
    j_call = Expr(:call, name, [ :($(argnames[i])::$(j_type(argtypes[i]))) for i=1:length(argtypes) ]... )
    c_call = :(ccall($(string(symb)), $(c_type(rettype)), $cargtypes))
    append!(c_call.args, argnames)
    if rettype == None
        #pass
    elseif rettype <: GObjectI 
        c_call = :( Gtk._GSubType($rettype,$c_call) )
    elseif rettype <: ByteString
        c_call = :( bytestring($c_call) )
    end
    eval(NS, Expr(:function, j_call, quote $c_call end))
    return eval(NS, name)
end
    

function _GSubType{T<:GObjectI}(::Type{T}, hnd::Ptr{GObjectI}) 
    if hnd == C_NULL
        error("can't handle NULL returns yet!")
    end
    g_type = G_OBJECT_CLASS_TYPE(hnd)
    info = find_by_gtype(g_type)
    constr, iface = create_type(info)
    return constr(hnd)::T
end

#some convenience macros, just for the show
macro gimport(ns, names)
    _name = (ns == :Gtk) ? :_Gtk : ns
    NS = _ns(ns)
    q = quote  $(esc(_name)) = $(NS) end
    if isa(names,Expr)  && names.head == :tuple
        names = names.args
    else 
        names = [names]
    end
    for item in names
        if isa(item,Symbol)
            name = item; meths = []
        else 
            name = item.args[1]
            meths = item.args[2:end]
        end
        push!(q.args, :(const $(esc(name)) = $(ensure_name(NS, name))))
        for meth in meths
            push!(q.args, :(const $(esc(meth)) = $(Gtk.ensure_method(NS, name, meth))))
        end
    end
    print(q)
    q
end


# temporary solution
macro gtkmethods(obj, names)
    if isa(names,Expr)  && names.head == :tuple
        names = names.args
    else 
        names = [names]
    end
        
    ex = Expr(:block, [:(const $(esc(name)) = $(ensure_method(gtk_ns, obj, name)) ) for name in names])
    if haskey(_gi_methods, (:Gtk, obj, :new)) 
        push!(ex.args, [:(const $(esc(symbol("$(obj)_new"))) = _gi_methods[(:Gtk, obj, :new)])])
    end
end


