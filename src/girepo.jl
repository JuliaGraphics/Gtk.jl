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
    typeid = int(ccall((:g_base_info_get_type, libgi), Enum, (Ptr{GIBaseInfo},), h))
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

const GIInfoTypesShortNames = (:Invalid, :Function, :Callback, :Struct, :Boxed, :Enum, :Flags, :Object, :Interface, :Constant, :Unknown, :Union, :Value, :Signal, :VFunc, :Property, :Field, :Arg, :Type, :Unresolved)
const GIInfoTypeNames = [ Base.symbol("GI$(name)Info") for name in GIInfoTypesShortNames]

const GIInfoTypes = Dict{Symbol, Type}()

for (i,itype) in enumerate(GIInfoTypesShortNames)
    let lowername = symbol(lowercase(string(itype)))
        @eval typealias $(GIInfoTypeNames[i]) GIInfo{$(i-1)}
        GIInfoTypes[lowername] = GIInfo{i-1}
    end
end

typealias GICallableInfo Union(GIFunctionInfo,GIVFuncInfo, GICallbackInfo, GISignalInfo)
typealias GIRegisteredTypeInfo Union(GIEnumInfo,GIInterfaceInfo, GIObjectInfo, GIStructInfo, GIUnionInfo)

function get_name(info::GIInfo) 
    str = ccall((:g_base_info_get_name, libgi), Ptr{Uint8}, (Ptr{GIBaseInfo},), info)
    symbol(bytestring(str)) 
end

#Bug in gobject
get_name(info::GITypeInfo) = symbol("<gtype>")

function get_namespace(info::GIInfo) 
    str = ccall((:g_base_info_get_namespace, libgi), Ptr{Uint8}, (Ptr{GIBaseInfo},), info)
    symbol(bytestring(str)) 
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
    if version==nothing
        version = C_NULL
    end
    GError() do error_check
        typelib = ccall((:g_irepository_require, libgi), Ptr{GITypelib}, 
            (Ptr{GObject}, Ptr{Uint8}, Ptr{Uint8}, Cint, Ptr{Ptr{GError}}), 
            girepo, namespace, version, 0, error_check)
        return  typelib !== C_NULL
    end
end

function gi_find_by_name(namespace, name)
    info = ccall((:g_irepository_find_by_name, libgi), Ptr{GIBaseInfo}, 
           (Ptr{GObject}, Ptr{Uint8}, Ptr{Uint8}), girepo, namespace, name)
    if info == C_NULL
        error("Name $name not found in $namespace")
    end
    GIInfo(info) 
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

GIInfoTypes[:method] = GIFunctionInfo
GIInfoTypes[:callable] = GICallableInfo

# one-> many relationships
for (owner, property) in [
    (:object, :method), (:object, :signal), (:object, :interface),
    (:object, :property), (:object, :constant), (:object, :field),
    (:interface, :method), (:interface, :signal), (:callable, :arg)]
    @eval function $(symbol("get_$(property)s"))(info::$(GIInfoTypes[owner]))
        n = int(ccall(($("g_$(owner)_info_get_n_$(property)s"), libgi), Cint, (Ptr{GIBaseInfo},), info))
        $(GIInfoTypes[property])[ GIInfo( ccall(($("g_$(owner)_info_get_$property"), libgi), Ptr{GIBaseInfo}, (Ptr{GIBaseInfo}, Cint), info, i)) for i=0:n-1]
    end
    if property == :method
        @eval function $(symbol("find_$(property)"))(info::$(GIInfoTypes[owner]), name)
            GIInfo(ccall(($("g_$(owner)_info_find_$(property)"), libgi), Ptr{GIBaseInfo}, (Ptr{GIBaseInfo},Ptr{Uint8}), info, name))
        end
    end
end

# one->one
_unit(x) = x
_types = [GIInfo=>(Ptr{GIBaseInfo},GIInfo)]
for (owner,property,typ) in [
    (:callable, :return_type, GIInfo), (:callable, :caller_owns, Enum),
    (:arg, :type, GIInfo), (:arg, :direction, Enum),
    (:type, :tag, Enum), (:type, :interface, GIInfo)]
    ctype, conv = get(_types, typ, (typ,_unit))
    @eval function $(symbol("get_$(property)"))(info::$(GIInfoTypes[owner]))
        $conv(ccall(($("g_$(owner)_info_get_$(property)"), libgi), $ctype, (Ptr{GIBaseInfo},), info))
    end
end

for (owner,flag) in [ (:type, :is_pointer) ]
    @eval function $flag(info::$(GIInfoTypes[owner]))
        ret = ccall(($("g_$(owner)_info_$(flag)"), libgi), Cint, (Ptr{GIBaseInfo},), info)
        return ret != 0
    end
end


const typetag_primitive = [
    Void,Bool,Int8,Uint8,
    Int16,Uint16,Int32,Uint32,
    Int64,Uint64,Cfloat,Cdouble,
    Csize_t, # FIXME: Gtype
    UTF8String
    ]
const TAG_BASIC_MAX = 13
const TAG_INTERFACE = 16 

extract_type(info::GIArgInfo) = extract_type(get_type(info))

function extract_type(info::GITypeInfo)
    tag = get_tag(info)
    if tag <= TAG_BASIC_MAX
        basetype = typetag_primitive[tag-1]
    elseif tag == TAG_INTERFACE
        # Object Types n such
        iface = get_interface(info)
        basetype = extract_type(iface)
    end
    if is_pointer(info)
        Ptr{basetype}
    else
        basetype
    end
end

function extract_type(info::GIObjectInfo) 
    GObjectI # TODO: specialize
end
