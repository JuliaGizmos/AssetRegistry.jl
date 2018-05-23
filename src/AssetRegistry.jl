module AssetRegistry

const registry = Dict{String,String}()

function register(path)
    key = sha1(abspath(path))
    registry[key] = abspath(path) 
    key
end


end # module
