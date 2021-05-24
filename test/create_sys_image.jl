@info "Loading packages ..."
using GLMakie, Arrow, MeshIO, RecursiveArrayTools, Revise, Rotations, StaticArrays, StructArrays, YAML, Sundials, NLsolve
using PackageCompiler

@info "Creating sysimage ..."

PackageCompiler.create_sysimage(
    [:GLMakie, :Arrow, :MeshIO, :RecursiveArrayTools, :Revise, :Rotations, :StaticArrays, :StructArrays, :YAML, :Sundials, :NLsolve];
    sysimage_path="MakieSys_tmp.so",
    precompile_execution_file=joinpath("test", "test_for_precompile.jl")
)