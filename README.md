# AssetRegistry

[![Build Status](https://travis-ci.org/JuliaGizmos/AssetRegistry.jl.svg?branch=master)](https://travis-ci.org/JuliaGizmos/AssetRegistry.jl)

[![Coverage Status](https://coveralls.io/repos/JuliaGizmos/AssetRegistry.jl/badge.svg?branch=master&service=github)](https://coveralls.io/github/JuliaGizmos/AssetRegistry.jl?branch=master)

[![codecov.io](http://codecov.io/github/JuliaGizmos/AssetRegistry.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaGizmos/AssetRegistry.jl?branch=master)

AssetRegistry allows you to serve arbitrary files and 
folders, using a global registry. Now packages like
[`Mux`](https://github.com/JuliaWeb/Mux.jl) and 
[`IJulia`](https://github.com/JuliaLang/IJulia.jl) can 
look up this registry and serve these files while 
packages like [`WebIO`](https://github.com/JuliaGizmos/WebIO.jl) 
and [`InteractBase`](https://github.com/piever/InteractBase.jl) 
can register assets to be served to implement web-based UIs. 

## Usage

You can register an asset with the package by doing:
```julia
key = AssetRegistry.register("path/to/asset")
```
This `key` is the unique URL where the asset 
can be accessed. For example:

```julia
julia> key = AssetRegistry.register("/Users/ranjan/.julia/v0.6/Tachyons/assets/tachyons.min.css")
"/assetserver/97a47bdda5bd9274ad1a9cd10a0337f3b033a790-tachyons.min.css"
```

