
module AssetRegistry
using SHA
using JSON3
using Pidfile

const baseurl = Ref{String}("")
const registry = Dict{String,String}()

withlock(f,lockf) = (lock=mkpidlock(lockf, stale_age=5); f(); close(lock))

# Need to remove the basepath for file database
filekey(key) = key[length(baseurl[])+1:end]

"""

    register("path/to/asset")

    Register an asset. Returns a unique key which is
the unique URL where the asset can be accessed.
For example:

```julia
julia> key = AssetRegistry.register("/Users/ranjan/.julia/v0.6/Tachyons/assets/tachyons.min.css")
"/assetserver/97a47bdda5bd9274ad1a9cd10a0337f3b033a790-tachyons.min.css"
```
"""
function register(path; registry_file = joinpath(homedir(), ".jlassetregistry.json"))
    target = gettarget(path)
    (isfile(target) || isdir(target)) || error("Asset not found")

    key = getkey(target)
    if haskey(registry, key)
        # We have already registered this in our session
        return key
    end

    # update global registry file
    update_registry_file(registry_file, key) do prev_registry, fkey
        if haskey(prev_registry, fkey)
            prev_registry[fkey] = (target, prev_registry[fkey][2]+1) # increment ref count
        else
            prev_registry[fkey] = (target, 1) # init refcount to 1
        end
    end

    registry[key] = target # keep this in current process memory

    return key
end

function deregister(path; registry_file = joinpath(homedir(), ".jlassetregistry.json"))
    target = gettarget(path)

    key = getkey(target)
    if !haskey(registry, key)
        return nothing
    end
    pop!(registry, key)

    update_registry_file(registry_file, key) do prev_registry, fkey
        if haskey(prev_registry, fkey)
            val, count = prev_registry[fkey]
            if count == 1
                pop!(prev_registry, fkey)
            else
                prev_registry[fkey] = (val, count-1) # increment ref count
            end
        end
    end

    return key
end

function update_registry_file(f, file, key)
    pidlock = joinpath(homedir(), ".jlassetregistry.lock")
    # touch(registry_file) -- this doesn't work on Azure fs
    if !isfile(file)
        # WARN: may need a lock here
        open(_ -> nothing, file, "w")
    end
    withlock(pidlock) do
        fkey = filekey(key)
        io = open(file, "r+")
        # get existing information
        DT = Dict{String,Tuple{String,Int}}
        prev_registry =  filesize(io) > 0 ? JSON3.read(io, DT) : DT()
        f(prev_registry, fkey)
        # write the updated registry to file
        seekstart(io)
        JSON3.write(io, prev_registry)
        # truncate it to current length
        truncate(io, position(io))
        close(io)
    end
end

gettarget(path) = normpath(abspath(expanduser(path)))

getkey(path) =  baseurl[] * "/assetserver/" * bytes2hex(sha1(abspath(path))) * "-" * basename(path)

isregistered(path) = haskey(registry, getkey(path))

function __init__()
    baseurl[] = get(ENV, "JULIA_ASSETREGISTRY_BASEURL", get(ENV, "JUPYTERHUB_SERVICE_PREFIX", ""))
    atexit() do
        for (key, path) in AssetRegistry.registry
            AssetRegistry.deregister(path)
        end
    end
end

# Precompile with a dummy registration
let
    register(pwd())
    deregister(pwd())
end

end # module
