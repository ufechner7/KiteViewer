@info "Loading packages ..."
using GLMakie, Arrow, MeshIO, RecursiveArrayTools, Revise, Rotations, StaticArrays, StructArrays, YAML, DifferentialEquations, Sundials
using PackageCompiler

@info "Creating sysimage ..."

PackageCompiler.create_sysimage(
    [:GLMakie, :Arrow, :MeshIO, :RecursiveArrayTools, :Revise, :Rotations, :StaticArrays, :StructArrays, :YAML, :DifferentialEquations, :Sundials];
    sysimage_path="MakieSys_tmp.so",
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)