let
    include("../src/KiteViewer.jl")
    Utils.test(true)
    main(false)
end

@info "Precompile script has completed execution."