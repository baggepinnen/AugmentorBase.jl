using   FixedPointNumbers,
        IdentityRanges,
        Interpolations,
        MappedArrays,
        MLDataPattern,
        OffsetArrays,
        Random,
        SparseArrays,
        StaticArrays,
        Statistics

# extras
using Test

# removed
# ComputationalResources

# check for ambiguities
using AugmentorBase

str_show(obj) = @io2str show(::IO, obj)
str_showcompact(obj) = @io2str show(IOContext(::IO, :compact=>true), obj)
str_showconst(obj) = @io2str Augmentor.showconstruction(::IO, obj)


tests = [
    "tst_utils.jl",

    "operations/tst_dims.jl",
    "operations/tst_convert.jl",
    "operations/tst_mapfun.jl",
    "operations/tst_noop.jl",
    "operations/tst_cache.jl",
    "operations/tst_crop.jl",
    "operations/tst_resize.jl",
    "operations/tst_either.jl",
    "tst_operations.jl",
    "tst_pipeline.jl",
    "tst_augment.jl",
    "tst_augmentbatch.jl",
]

for t in tests
    @testset "$t" begin
        include(t)
    end
end
