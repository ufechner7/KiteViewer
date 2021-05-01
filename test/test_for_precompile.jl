let
    include("../src/KiteViewer.jl")
    Utils.test(true)
    main(false)
end
include("../src/Plot2D.jl")
main(false)

@info "Precompile script has completed execution."