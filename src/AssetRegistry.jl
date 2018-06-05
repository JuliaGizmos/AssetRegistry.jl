module AssetRegistry
using SHA
using JSON
using Pidfile

const registry = Dict{String,String}()

withlock(f,lockf) = (lock=mkpidlock(lockf, stale_age=5); f(); close(lock))

function register(path; registry_file = joinpath(homedir(), ".jlassetregistry.json"))
    target = abspath(path)
    (isfile(target) || isdir(target)) || 
                    error("Asset not found")

    key = getkey(target)
    if haskey(registry, key)
        # We have already registered this in our session
        return key
    end

    # update global registry file

    touch(registry_file)

    pidlock = joinpath(homedir(), ".jlassetregistry.lock")

    withlock(pidlock) do

        io = open(registry_file, "r+") # open in read-and-write mode
        # first get existing entries
        prev_registry =  filesize(io) > 0 ? JSON.parse(io) : Dict{String,Tuple{String,Int}}()

        if haskey(prev_registry, key)
            prev_registry[key] = (target, prev_registry[key][2]+1) # increment ref count
        else
            prev_registry[key] = (target, 1) # init refcount to 1
        end

        # write the updated registry to file
        seekstart(io)
        JSON.print(io, prev_registry)

        # truncate it to current length
        truncate(io, position(io))
        close(io)
    end

    registry[key] = target # keep this in current process memory


    key
end

function deregister(path; registry_file = joinpath(homedir(), ".jlassetregistry.json"))
    target = abspath(path)

    key = getkey(target)
    if !haskey(registry, key)
        return
    end

    pop!(registry, key)

    touch(registry_file)

    pidlock = joinpath(homedir(), ".jlassetregistry.lock")
    withlock(pidlock) do
        io = open(registry_file, "r+")

        # get existing information
        prev_registry =  filesize(io) > 0 ? JSON.parse(io) : Dict{String,Tuple{String, Int}}()

        if haskey(prev_registry, key)
            val, count = prev_registry[key]
            if count == 1
                pop!(prev_registry, key)
            else
                prev_registry[key] = (val, count-1) # increment ref count
            end
        end

        seekstart(io)
        JSON.print(io, prev_registry)

        # truncate it to current length
        truncate(io, position(io))
        close(io)
    end

    key
end

getkey(path) =  "/assetserver/" * bytes2hex(sha1(abspath(path))) * "-" * basename(path)

isregistered(path) = haskey(registry, getkey(path))

function __init__()
    atexit() do
        for (key, path) in AssetRegistry.registry
            AssetRegistry.deregister(path)
        end
    end
end

end # module
