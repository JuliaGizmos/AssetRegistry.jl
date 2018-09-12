ENV["JULIA_ASSETREGISTRY_BASEURL"] = "/mybasedir"

using AssetRegistry
using Distributed
ps = addprocs(1)

using Test

using JSON

@testset "register" begin
    key = AssetRegistry.register(pwd())
    @test startswith(key, ENV["JULIA_ASSETREGISTRY_BASEURL"])
    @test key == AssetRegistry.getkey(pwd())
    @test AssetRegistry.isregistered(pwd())
    @test JSON.parse(String(read(joinpath(homedir(), ".jlassetregistry.json")))) == Dict(AssetRegistry.filekey(key) => [pwd(), 1])

    # test that a new proc doesn't leave any residue
    run(```
        $(Base.julia_cmd())
        -e 'using AssetRegistry; AssetRegistry.register(pwd());'
        ```)

    @test JSON.parse(String(read(joinpath(homedir(), ".jlassetregistry.json")))) == Dict(AssetRegistry.filekey(key) => [pwd(), 1])

    AssetRegistry.deregister(pwd())
    @test !AssetRegistry.isregistered(pwd())
    @test JSON.parse(String(read(joinpath(homedir(), ".jlassetregistry.json")))) == Dict()
end

@testset "register for not normalized paths" begin
    path = joinpath(pwd(), "..", "src")
    key = AssetRegistry.register(path)
    @test startswith(key, ENV["JULIA_ASSETREGISTRY_BASEURL"])
    @test key == AssetRegistry.getkey(path)
    @test AssetRegistry.isregistered(path)
    @test JSON.parse(String(read(joinpath(homedir(), ".jlassetregistry.json")))) == Dict(AssetRegistry.filekey(key) => [normpath(path), 1])
    AssetRegistry.deregister(path)
    @test !AssetRegistry.isregistered(path)
    @test JSON.parse(String(read(joinpath(homedir(), ".jlassetregistry.json")))) == Dict()
end
