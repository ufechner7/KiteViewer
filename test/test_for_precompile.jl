push!(LOAD_PATH,joinpath(pwd(),"src"))
@info LOAD_PATH
let    
    include("../src/KiteViewer.jl")
    Utils.test(true)
    main(false)
end
let 
    include("../src/DAE_Example.jl")
end

@info "Precompile script has completed execution."