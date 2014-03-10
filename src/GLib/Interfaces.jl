module Interfaces

using MetaTools
export @interface, @multi, @implements, Interface

if false
    # this is an example of what we are generating
    let _some_multi_method = ()
    global some_method
    function some_method(arg1, X::ANY, arg2, arg3)
        nxt = _some_multi_method
        ifaces = InterfacesMap[typeof(X)]
        local best, found = false
        while nxt != ()
            tmatch, meth, nxt = nxt
            if type_in(tmatch,ifaces)
                found && MethodError(:some_method, (arg1, X, arg2, arg3))
                found = true
                best = meth
            end
        end
        found || MethodError(:some_method, (arg1, X, arg2, arg3))
        best(arg1, X, arg2, arg3)
    end
    end
end

function type_in(typ, dict)
    for itm in dict
        if itm <: typ
            return true
        end
    end
    return false
end

type MethodAmbiguity <: Exception
    f
    args
end
function Base.showerror(io::IO, e::MethodAmbiguity)
    name = isgeneric(e.f) ? e.f.env.name : :anonymous
    if isa(e.f, DataType)
        print(io, "ambiguous method call $(e.f)(")
    else
        print(io, "ambiguous method call $(name)(")
    end
    for (i, arg) in enumerate(e.args)
        if isa(arg,Type) && arg != typeof(arg)
            print(io, "Type{$(arg)}")
        else
            print(io, typeof(arg))
        end
        i == length(e.args) || print(io,", ")
    end
    print(io, ")")
end


abstract Interface
InterfacesMap = ObjectIdDict()
#macro interface(name)
#    quote
#        abstract $(esc(name)) <: Interface
#    end
#end
macro implements(expr)
    (expr.head === :comparison && length(expr.args) == 3 && expr.args[2] === :(<:)) || error("Invalid syntax for @implements A <: B")
    obj = expr.args[1]
    iface = expr.args[3]
    quote
        let obj = $(esc(obj)), iface = $(esc(iface)), imap = InterfacesMap
            ifaces = get(imap, obj, nothing)
            if ifaces === nothing
                ifaces = imap[obj] = Type{TypeVar(:I,Interface)}[]
            end
            push!(ifaces, iface)
            nothing
        end
    end
end
MultiMethodCaches = ObjectIdDict()
macro multi(fn)
    fn = ParsedFunction(fn)
    name = fn.name
    local iname, itype, iarg, count = 0
    m = current_module()
    for arg in fn.args
        t = eval(m,arg.typ)
        if t <: Interface
            count += 1
            iarg = arg
            iname = esc(arg.name)
            itype = arg.typ
            arg.typ = :Any
        end
    end
    argnames = ntuple(length(fn.args), (i)->esc(fn.args[i].name))
    argtypes = ntuple(length(fn.args), (i)->fn.args[i].typ)
    count == 1 || error("@multi is not yet implemented to support multiple interfaces")
    local mcache = nothing
    if isdefined(m, name)
        fn_obj = getfield(m, name)
        fcache = get(MultiMethodCaches, fn_obj, nothing)
        if fcache !== nothing
            mcache = get(fcache, argtypes, nothing)
        end
    end
    anonfn = Expr(:function, Expr(:tuple, emit(fn.args)...), fn.body)
    ename = esc(name)
    fn.body = quote
            local best_match_fn
            let T = typeof($iname), found = false
                while !found
                    T === Any && error(MethodError($ename, ($(argnames...))))
                    ifaces = get(InterfacesMap, T, nothing)
                    if ifaces !== nothing
                        for (tmatch, meth) in mcache
                            if type_in(tmatch,ifaces)
                                found && error(MethodAmbiguity($ename, ($(argnames...))))
                                found = true
                                best_match_fn = meth
                            end
                        end
                    end
                    T = super(T)
                end
            end
            best_match_fn($(argnames...))
        end
    iarg.typ = :ANY
    fn = emit(fn)
    fn.args[1] = esc(fn.args[1])
    if mcache !== nothing
        quote
            let mcache = $(mcache)
                global $ename
                push!(mcache, $(esc(Expr(:tuple, itype, anonfn))))
                $fn
            end
        end
    else
        quote
            global $ename
            $(if !isdefined(m, name)
                # temporary declaration to that Function `name` is defined
                fn
            end)
            let name = $ename
                let fcache = get(MultiMethodCaches, name, nothing)
                    if fcache === nothing
                        fcache = MultiMethodCaches[name] = ObjectIdDict()
                    end
                    let mcache = get(fcache, $argtypes, nothing)
                        if mcache === nothing
                            mcache = fcache[$argtypes] = Array((Type,Function),0)
                        end
                        global $ename
                        push!(mcache, $(esc(Expr(:tuple, itype, anonfn))))
                        $fn
                    end
                end
            end
        end
    end
end

end
