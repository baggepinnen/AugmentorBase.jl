module AugmentorBase

using ColorTypes
using MappedArrays
using Interpolations
using StaticArrays
using OffsetArrays
using IdentityRanges
using MLDataPattern
using ComputationalResources
using FileIO
using LinearAlgebra

export
    testpattern,
    CPU1,
    CPUThreads,

    Reshape,

    ConvertEltype,
    MapFun,
    AggregateThenMapFun,

    Crop,
    CropNative,
    CropSize,
    CropRatio,
    RCropRatio,

    CacheIntermediate,

    Resize,

    NoOp,
    Either,

    augment,
    augment!,
    augmentbatch!

include("utils.jl")
include("types.jl")
include("operation.jl")

include("operations/convert.jl")
include("operations/mapfun.jl")

include("operations/noop.jl")
include("operations/cache.jl")

include("operations/crop.jl")
include("operations/either.jl")

include("pipeline.jl")
include("codegen.jl")
include("augment.jl")
include("augmentbatch.jl")

function __init__()
    rand_mutex[] = ReentrantLock()
end

end # module
