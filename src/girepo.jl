@GType GIRepository
const girepo = GIRepository(ccall((:g_irepository_get_default, libgi), Ptr{GObject}, () ))

abstract GITypelib

abstract GIBaseInfo
# a GIBaseInfo we own a reference to
type GIInfo{Typeid} 
    handle::Ptr{GIBaseInfo}
end

function GIInfo(h::Ptr{GIBaseInfo}) 
    if h == C_NULL 
        error("Cannot constrct GIInfo from NULL")
    end
    typeid = int(ccall((:g_base_info_get_type, libgi), Cint, (Ptr{GIBaseInfo},), h))
    info = GIInfo{typeid}(h)
    finalizer(info, info_unref)
    info
end
# don't call directly, called by gc
function info_unref(info::GIInfo) 
    ccall((:g_base_info_unref, libgi), Void, (Ptr{GIBaseInfo},), info.handle)
    info.handle = C_NULL
end

convert(::Type{Ptr{GIBaseInfo}},w::GIInfo) = w.handle

const GIInfoTypes = (:Invalid, :Function, :Callback, :Struct, :Boxed, :Enum, :Flags, :Object, :Interface, :Constant, :Unknown, :Union, :Value, :Signal, :VFunc, :Property, :Field, :Arg, :Type, :Unresolved)
const GIInfoTypeNames = [ Base.symbol("GI$(name)Info") for name in GIInfoTypes]
baremodule GIInfoType 
end    

for (i,itype) in enumerate(GIInfoTypes)
    let uppername = symbol(uppercase(string(itype)))
        eval(GIInfoType,:(const $uppername = $(i-1)))
        @eval typealias $(GIInfoTypeNames[i]) GIInfo{$(i-1)}
    end
end

typealias GICallableInfo Union(GIFunctionInfo,GIVFuncInfo, GICallbackInfo, GISignalInfo)
typealias GIRegisteredTypeInfo Union(GIEnumInfo,GIInterfaceInfo, GIObjectInfo, GIStructInfo, GIUnionInfo)

function get_name(info::GIInfo) 
    str = ccall((:g_base_info_get_name, libgi), Ptr{Uint8}, (Ptr{GIBaseInfo},), info)
    bytestring(str) # can assume non-NULL?
end

function get_namespace(info::GIInfo) 
    str = ccall((:g_base_info_get_namespace, libgi), Ptr{Uint8}, (Ptr{GIBaseInfo},), info)
    bytestring(str) # can assume non-NULL?
end

show{Typeid}(io::IO, ::Type{GIInfo{Typeid}}) = print(io, GIInfoTypeNames[Typeid+1])

function show(io::IO, info::GIInfo)
    show(io, typeof(info)) 
    print(io,"(:$(get_namespace(info)), :$(get_name(info)))")
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

#GIInfo(namespace, name::Symbol) = gi_find_by_name(namespace, name)

#TODO: make ns behave more like Array and/or Dict{Symbol,GIInfo}?
length(ns::GINamespace) = int(ccall((:g_irepository_get_n_infos, libgi), Cint, (Ptr{GObject}, Ptr{Uint8}), girepo, ns))
function getindex(ns::GINamespace, i::Integer) 
    GIInfo(ccall((:g_irepository_get_info, libgi), Ptr{GIBaseInfo}, (Ptr{GObject}, Ptr{Uint8}, Cint), girepo, ns, i ))
end
function getindex(ns::GINamespace, name::Symbol) 
    gi_find_by_name(ns, name)
end

# Registered types
const _typemap = [:method => GIFunctionInfo, 
        :signal => GISignalInfo,
        :vfunc => GIVFuncInfo,
        :object => GIObjectInfo,
        :interface => GIInterfaceInfo] 

for (owner, property) in [
    (:object, :method), (:object, :signal), (:object, :interface),
    (:interface, :method), (:interface, :signal)]
    @eval function $(symbol("get_$(property)s"))(info::$(_typemap[owner]))
        n = int(ccall(($("g_$(owner)_info_get_n_$(property)s"), libgi), Cint, (Ptr{GIBaseInfo},), info))
        $(_typemap[property])[ GIInfo( ccall(($("g_$(owner)_info_get_$property"), libgi), Ptr{GIBaseInfo}, (Ptr{GIBaseInfo}, Cint), info, i)) for i=0:n-1]
    end
end
