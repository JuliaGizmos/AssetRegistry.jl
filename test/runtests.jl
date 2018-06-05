using AssetRegistry
ps = addprocs(1)

@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

using JSON

@testset "register" begin
    key = AssetRegistry.register(pwd())
    @test key == AssetRegistry.getkey(pwd())
    @test AssetRegistry.isregistered(pwd())
    @test JSON.parse(String(read(joinpath(homedir(), ".jlassetregistry.json")))) == Dict(key => [pwd(), 1])

    # test that a new proc doesn't leave any residue
    run(```
        $(Base.julia_cmd())
        -e 'using AssetRegistry; AssetRegistry.register(pwd());'
        ```)

    @test JSON.parse(String(read(joinpath(homedir(), ".jlassetregistry.json")))) == Dict(key => [pwd(), 1])

    AssetRegistry.deregister(pwd())
    @test !AssetRegistry.isregistered(pwd())
    @test JSON.parse(String(read(joinpath(homedir(), ".jlassetregistry.json")))) == Dict()
end
