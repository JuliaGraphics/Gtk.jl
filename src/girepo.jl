abstract GIRepository
const girepo = ccall((:g_irepository_get_default, libgi), Ptr{GIRepository}, () )

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
    #core dumps on reload("GTK.jl"), 
    #ccall((:g_base_info_unref, libgi), Void, (Ptr{GIBaseInfo},), info.handle)
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

show{Typeid}(io::IO, ::Type{GIInfo{Typeid}}) = print(io, GIInfoTypeNames[Typeid+1])

function show(io::IO, info::GIInfo)
    show(io, typeof(info)) 
    print(io,"(:$(get_namespace(info)), :$(get_name(info)))")
end

show(io::IO, info::GITypeInfo) = print(io,"GITypeInfo($(extract_type(info)))")
show(io::IO, info::GIArgInfo) = print(io,"GIArgInfo(:$(get_name(info)),$(extract_type(info)))")
showcompact(io::IO, info::GIArgInfo) = show(io,info) # bug in show.jl ?

function show(io::IO, info::GIFunctionInfo) 
    print(io, "$(get_namespace(info)).$(get_name(info))(")
    for arg in get_args(info)
        print(io, "$(get_name(arg))::$(extract_type(arg)), ")
    end
    print(io,")\n")
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
            (Ptr{GIRepository}, Ptr{Uint8}, Ptr{Uint8}, Cint, Ptr{Ptr{GError}}), 
            girepo, namespace, version, 0, error_check)
        return  typelib !== C_NULL
    end
end

function gi_find_by_name(namespace, name)
    info = ccall((:g_irepository_find_by_name, libgi), Ptr{GIBaseInfo}, 
           (Ptr{GIRepository}, Ptr{Uint8}, Ptr{Uint8}), girepo, namespace, name)
    if info == C_NULL
        error("Name $name not found in $namespace")
    end
    GIInfo(info) 
end

#GIInfo(namespace, name::Symbol) = gi_find_by_name(namespace, name)

#TODO: make ns behave more like Array and/or Dict{Symbol,GIInfo}?
length(ns::GINamespace) = int(ccall((:g_irepository_get_n_infos, libgi), Cint, (Ptr{GIRepository}, Ptr{Uint8}), girepo, ns))
function getindex(ns::GINamespace, i::Integer) 
    GIInfo(ccall((:g_irepository_get_info, libgi), Ptr{GIBaseInfo}, (Ptr{GIRepository}, Ptr{Uint8}, Cint), girepo, ns, i-1 ))
end
getindex(ns::GINamespace, name::Symbol) = gi_find_by_name(ns, name)

function get_all{T<:GIInfo}(ns::GINamespace, t::Type{T})
    all = GIInfo[]
    for i=1:length(ns)
        info = ns[i]
        if isa(info,t)
            push!(all,info)
        end
    end
    all
end


function get_shlibs(ns)
    names = bytestring(ccall((:g_irepository_get_shared_library, libgi), Ptr{Uint8}, (Ptr{GIRepository}, Ptr{Uint8}), girepo, ns))
    split(names,",")
end
get_shlibs(info::GIInfo) = get_shlibs(get_namespace(info))

function find_by_gtype(gtypeid::Csize_t)
    GIInfo(ccall((:g_irepository_find_by_gtype, libgi), Ptr{GIBaseInfo}, (Ptr{GIRepository}, Csize_t), girepo, gtypeid))
end

GIInfoTypes[:method] = GIFunctionInfo
GIInfoTypes[:callable] = GICallableInfo
GIInfoTypes[:registered_type] = GIRegisteredTypeInfo
GIInfoTypes[:base] = GIInfo

# one-> many relationships
for (owner, property) in [
    (:object, :method), (:object, :signal), (:object, :interface),
    (:object, :property), (:object, :constant), (:object, :field),
    (:interface, :method), (:interface, :signal), (:callable, :arg)]
    @eval function $(symbol("get_$(property)s"))(info::$(GIInfoTypes[owner]))
        n = int(ccall(($("g_$(owner)_info_get_n_$(property)s"), libgi), Cint, (Ptr{GIBaseInfo},), info))
        GIInfo[ GIInfo( ccall(($("g_$(owner)_info_get_$property"), libgi), Ptr{GIBaseInfo}, (Ptr{GIBaseInfo}, Cint), info, i)) for i=0:n-1]
    end
    if property == :method
        @eval function $(symbol("find_$(property)"))(info::$(GIInfoTypes[owner]), name)
            ptr = ccall(($("g_$(owner)_info_find_$(property)"), libgi), Ptr{GIBaseInfo}, (Ptr{GIBaseInfo},Ptr{Uint8}), info, name)
            (ptr == C_NULL) ? nothing : GIInfo(ptr)
        end
    end
end
getindex(info::GIRegisteredTypeInfo, name::Symbol) = find_method(info, name)

# one->one
_unit(x) = x
# reuse gvalues.jl instead?
# FIXME: memory management of GIInfo:s
_types = [GIInfo=>(Ptr{GIBaseInfo},GIInfo),
          Symbol=>(Ptr{Uint8}, (x -> symbol(bytestring(x))))]
for (owner,property,typ) in [
    (:base, :name, Symbol), (:base, :namespace, Symbol),
    (:base, :container, GIInfo), (:registered_type, :g_type, GType), (:object, :parent, GIInfo),
    (:callable, :return_type, GIInfo), (:callable, :caller_owns, Enum),
    (:function, :flags, Enum), (:function, :symbol, Symbol),
    (:arg, :type, GIInfo), (:arg, :direction, Enum),
    (:type, :tag, Enum), (:type, :interface, GIInfo), (:constant, :type, GIInfo)]

    ctype, conv = get(_types, typ, (typ,_unit))
    @eval function $(symbol("get_$(property)"))(info::$(GIInfoTypes[owner]))
        $conv(ccall(($("g_$(owner)_info_get_$(property)"), libgi), $ctype, (Ptr{GIBaseInfo},), info))
    end
end

get_name(info::GITypeInfo) = symbol("<gtype>")
get_name(info::GIInvalidInfo) = symbol("<INVALID>")


qual_name(info::GIRegisteredTypeInfo) = (get_namespace(info),get_name(info))

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
    GType, 
    ByteString
    ]
const TAG_BASIC_MAX = 13
const TAG_ARRAY = 15
const TAG_INTERFACE = 16 

extract_type(info::Union(GIArgInfo,GIConstantInfo),ret=false) = extract_type(get_type(info),ret)

function extract_type(info::GITypeInfo,ret=false)
    tag = get_tag(info)
    if tag <= TAG_BASIC_MAX
        basetype = typetag_primitive[tag+1]
    elseif tag == TAG_INTERFACE
        # Object Types n such
        iface = get_interface(info)
        basetype = extract_type(iface,ret)
    elseif tag == TAG_ARRAY
        basetype = Void
    else
        print(tag)
        return Nothing
    end
    # GObjects are implicit pointers
    if is_pointer(info) && (!(basetype <: Union(GObjectI,ByteString))  || basetype == Void)
        Ptr{basetype}
    else
        basetype
    end
end

abstract GStruct #placeholder
function extract_type(info::GIStructInfo,ret) 
    GStruct # TODO: specialize
end

extract_type(info::GIEnumInfo,ret) = Enum 

const IS_METHOD = 1 << 0
const IS_CONSTRUCTOR = 1 << 1

function get_value(info::GIConstantInfo)
    typ = extract_type(info)
    x = Array(Int64,1) #or mutable
    size = ccall((:g_constant_info_get_value,libgi),Cint,(Ptr{GIBaseInfo}, Ptr{Void}), info, x) 
    if typ <: Number
        unsafe_load(Base.cconvert(Ptr{typ}, x))
    elseif typ == ByteString
        #val = bytestring(unsafe_load(Base.cconvert(Ptr{Uint8},x)))
        #ccall((:g_constant_info_free_value,libgi), Void, (Ptr{GIBaseInfo}, Ptr{Void}), info, x)
        #val
        nothing
    else
        nothing#unimplemented
    end
end
