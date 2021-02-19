@info "Loading packages ..."
using Makie, GLMakie, Arrow, MeshIO, RecursiveArrayTools, Revise, Rotations, StaticArrays, StructArrays, YAML
using PackageCompiler

@info "Creating sysimage ..."

PackageCompiler.create_sysimage(
    [:Makie, :GLMakie, :Arrow, :MeshIO, :RecursiveArrayTools, :Revise, :Rotations, :StaticArrays, :StructArrays, :YAML];
    sysimage_path="MakieSys.so",
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)