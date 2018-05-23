module AssetRegistry
using SHA

const registry = Dict{String,String}()

function register(path)
    target = abspath(path)
    (isfile(target) || isdir(target)) || 
                    error("Asset not found")
    key = sha1(target)
    registry[key] = target
    key
end


end # module
