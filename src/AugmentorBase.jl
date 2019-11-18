module Augmentor

using MappedArrays
using Interpolations
using StaticArrays
using OffsetArrays
using IdentityRanges
using MLDataPattern
using ComputationalResources
using FileIO
using LinearAlgebra
using Base.PermutedDimsArrays: PermutedDimsArray

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

    Resize,

    NoOp,
    Either,

    augment,
    augment!,
    augmentbatch!

include("utils.jl")
include("types.jl")
include("operation.jl")

include("operations/dims.jl")
include("operations/convert.jl")
include("operations/mapfun.jl")

include("operations/noop.jl")
include("operations/cache.jl")

include("operations/crop.jl")
include("operations/resize.jl")
include("operations/either.jl")

include("pipeline.jl")
include("codegen.jl")
include("augment.jl")
include("augmentbatch.jl")

function __init__()
    rand_mutex[] = Threads.Mutex()
end

end # module
