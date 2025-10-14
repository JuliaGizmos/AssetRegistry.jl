ENV["JULIA_ASSETREGISTRY_BASEURL"] = "/mybasedir"

using AssetRegistry
using Distributed
ps = addprocs(1)

using Test

using JSON
import AssetRegistry.parsejson

# julia 1.12 precompiles in a separate process with in a different directory,
# so we need to use `@__DIR__` insted of `pwd()`
mydir = Base.@__DIR__
registry_file = joinpath(homedir(), ".jlassetregistry.json")

@testset "register" begin
    key = AssetRegistry.register(mydir)
    @test startswith(key, ENV["JULIA_ASSETREGISTRY_BASEURL"])
    @test key == AssetRegistry.getkey(mydir)
    @test AssetRegistry.isregistered(mydir)
    @test parsejson(String(read(registry_file))) == Dict(AssetRegistry.filekey(key) => [mydir, 1])

    # test that a new proc doesn't leave any residue
    run(```
        $(Base.julia_cmd())
        --project=@. -e 'using AssetRegistry; AssetRegistry.register(pwd());'
        ```)

    @test parsejson(String(read(registry_file))) == Dict(AssetRegistry.filekey(key) => [mydir, 1])

    AssetRegistry.deregister(mydir)
    @test !AssetRegistry.isregistered(mydir)
    @test parsejson(String(read(registry_file))) == Dict()
end

@testset "register for not normalized paths" begin
    path = joinpath(mydir, "..", "src")
    key = AssetRegistry.register(path)
    @test startswith(key, ENV["JULIA_ASSETREGISTRY_BASEURL"])
    @test key == AssetRegistry.getkey(path)
    @test AssetRegistry.isregistered(path)
    @test parsejson(String(read(registry_file))) == Dict(AssetRegistry.filekey(key) => [normpath(path), 1])
    AssetRegistry.deregister(path)
    @test !AssetRegistry.isregistered(path)
    @test parsejson(String(read(registry_file))) == Dict()
end
