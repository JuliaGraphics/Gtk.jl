@GType GIRepository
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
        finalizer(info, free_info)
        info
    end
end

# don't call directly, called by gc
function free_info(info::GIInfo) 
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


#TODO: display(info)

const girepo = GIRepository(ccall((:g_irepository_get_default, libgi), Ptr{GObject}, () ))

function gi_require(namespace::Symbol, version=C_NULL,)
    local typelib::Ptr{GITypelib}
    GError() do error_check
        typelib = ccall((:g_irepository_require, libgi), Ptr{GITypelib}, 
            (Ptr{GObject}, Ptr{Uint8}, Ptr{Uint8}, Cint, Ptr{Ptr{GError}}), 
            girepo, namespace, version, 0, error_check)
        return  typelib !== C_NULL
    end
    #transfer none
    #return GITypelib(typelib)
end


function gi_find_by_name(namespace::Symbol, name::Symbol)
    info = ccall((:g_irepository_find_by_name, libgi), Ptr{GIBaseInfo}, 
           (Ptr{GObject}, Ptr{Uint8}, Ptr{Uint8}), girepo, namespace, name)
    if info == C_NULL
        error("Name $name not found in $namespace")
    end
    GIInfo(info) #TODO: Infer type
    #return GITypelib(typelib)
end

GIInfo(namespace::Symbol, name::Symbol) = gi_find_by_name(namespace, name)

#TODO: make iterator
function gi_get_infos(namespace::Symbol) 
    n_entries = ccall((:g_irepository_get_n_infos, libgi), Cint, (Ptr{GObject}, Ptr{Uint8}), girepo, namespace)
    if n_entries <= 0
        error("no names found in $namespace")
    end
    [GIInfo(ccall((:g_irepository_get_info, libgi), Ptr{GIBaseInfo}, (Ptr{GObject}, Ptr{Uint8}, Cint), girepo, namespace, n )) for n in 0:n_entries-1]
end


