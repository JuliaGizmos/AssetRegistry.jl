ENV["JULIA_ASSETREGISTRY_BASEURL"] = "/mybasedir"
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Distributed
    using Test
end
using AssetRegistry
ps = addprocs(1)

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
