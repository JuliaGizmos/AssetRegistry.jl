module AssetRegistry
using SHA

const registry = Dict{String,String}()

function register(path)
    target = abspath(path)
    (isfile(target) || isdir(target)) || 
                    error("Asset not found")
    key = getkey(target)
    registry[key] = target
    key
end

getkey(path) =  bytes2hex(sha1(abspath(path))) * "-" * basename(path)
isregistered(path) = haskey(registry, getkey(path))

end # module
