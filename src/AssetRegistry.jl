module AssetRegistry
using SHA

const registry = Dict{String,String}()

function register(path)
    file = abspath(path)
    isfile(file) || error("Asset not found")
    key = sha1(file)
    registry[key] = file
    key
end


end # module
