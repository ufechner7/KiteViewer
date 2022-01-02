module Utils

 __precompile__(false)

using YAML, OrderedCollections, Parameters

export struct2tuple

function struct2tuple(set)
    values=[]
    for fieldname in fieldnames(typeof(set))
        value = getfield(set, Symbol(fieldname))
        push!(values, value)
    end
    NamedTuple{fieldnames(typeof(set))}(values)
end

function read_settings(settings="./data/settings.yaml")
    dict = YAML.load_file(settings; dicttype=OrderedDict{String,Any})
    fields = Symbol[]
    my_values = []
    for (name, values) in dict
        for (name, value) in values
            push!(fields, Symbol(name))
            push!(my_values, value)
            # println("$name: $value")
        end
    end
    fields, my_values
end

function read_settings_struct(settings="./data/settings.yaml"; mutable=true)
    fields, values = read_settings(settings)
    if mutable
        res = "@with_kw mutable struct Settings\n"
    else
        res = "@with_kw struct Settings\n"
    end
    for (name, value) in zip(fields, values)
        res *= String(name) * "::" * repr(typeof(value)) * " = " * repr(value) * "\n"
    end
    ast  = Meta.parse(res * "\nend")
    return eval(ast)
end

function se(settings="./data/settings.yaml"; mutable=true)
    Base.invokelatest(read_settings_struct(settings; mutable = mutable), )
end

end