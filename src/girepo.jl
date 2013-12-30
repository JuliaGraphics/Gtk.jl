@GType GIRepository
const girepo = GIRepository(ccall((:g_irepository_get_default, libgi), Ptr{GObject}, () ))

abstract GITypelib

abstract GIBaseInfo
# a GIBaseInfo we own a reference to
type GIInfo#{Name} 
    handle::Ptr{GIBaseInfo}
    function GIInfo(h::Ptr{GIBaseInfo}) 
        if h == C_NULL 
            error("Cannot constrct GIInfo from NULL")
        end
        info = new(h)
        finalizer(info, info_unref)
        info
    end
end

# don't call directly, called by gc
function info_unref(info::GIInfo) 
    ccall((:g_base_info_unref, libgi), Void, (Ptr{GIBaseInfo},), info.handle)
    info.handle = C_NULL
end

convert(::Type{Ptr{GIBaseInfo}},w::GIInfo) = w.handle

function info_get_name(info::GIInfo) 
    str = ccall((:g_base_info_get_name, libgi), Ptr{Uint8}, (Ptr{GIBaseInfo},), info)
    bytestring(str) # can assume non-NULL?
end

function info_get_namespace(info::GIInfo) 
    str = ccall((:g_base_info_get_namespace, libgi), Ptr{Uint8}, (Ptr{GIBaseInfo},), info)
    bytestring(str) # can assume non-NULL?
end

function show(io::IO, info::GIInfo) 
    print(io, "GIInfo(:", info_get_namespace(info), ", :", info_get_name(info), ")")
end

immutable GINamespace
    name::Symbol
    function GINamespace(namespace::Symbol, version=nothing)
        #TODO: stricter version sematics?
        gi_require(namespace, version)
        new(namespace)
    end
end 
convert(::Type{Symbol}, ns::GINamespace) = ns.name
convert(::Type{Ptr{Uint8}}, ns::GINamespace) = convert(Ptr{Uint8}, ns.name)

function gi_require(namespace, version=nothing)
    #local typelib::Ptr{GITypelib}
    if version==nothing
        version = C_NULL
    end
    GError() do error_check
        typelib = ccall((:g_irepository_require, libgi), Ptr{GITypelib}, 
            (Ptr{GObject}, Ptr{Uint8}, Ptr{Uint8}, Cint, Ptr{Ptr{GError}}), 
            girepo, namespace, version, 0, error_check)
        return  typelib !== C_NULL
    end
    #transfer none
    #return GITypelib(typelib)
end

function gi_find_by_name(namespace, name)
    info = ccall((:g_irepository_find_by_name, libgi), Ptr{GIBaseInfo}, 
           (Ptr{GObject}, Ptr{Uint8}, Ptr{Uint8}), girepo, namespace, name)
    if info == C_NULL
        error("Name $name not found in $namespace")
    end
    GIInfo(info) #TODO: Infer type
end

GIInfo(namespace, name::Symbol) = gi_find_by_name(namespace, name)

#TODO: make ns behave more like Array and/or Dict{Symbol,GIInfo}?
length(ns::GINamespace) = int(ccall((:g_irepository_get_n_infos, libgi), Cint, (Ptr{GObject}, Ptr{Uint8}), girepo, ns))
function getindex(ns::GINamespace, i::Integer) 
    GIInfo(ccall((:g_irepository_get_info, libgi), Ptr{GIBaseInfo}, (Ptr{GObject}, Ptr{Uint8}, Cint), girepo, ns, i ))
end
function getindex(ns::GINamespace, name::Symbol) 
    gi_find_by_name(ns, name)
end

function gi_get_infos(namespace::Symbol) 
    [ns[i] for i=length(ns)]
end
