module Utils

export struct2tuple

function struct2tuple(set)
    values=[]
    for fieldname in fieldnames(typeof(set))
        value = getfield(set, Symbol(fieldname))
        push!(values, value)
    end
    NamedTuple{fieldnames(typeof(set))}(values)
end

end