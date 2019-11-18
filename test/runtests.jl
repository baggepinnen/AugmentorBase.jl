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
using Test, ReferenceTests

# removed
# ComputationalResources

# check for ambiguities
using AugmentorBase, OffsetArrays, IdentityRanges, SparseArrays, Colors, FixedPointNumbers, ColorTypes, MappedArrays

str_show(obj) = @io2str show(::IO, obj)
str_showcompact(obj) = @io2str show(IOContext(::IO, :compact=>true), obj)
str_showconst(obj) = @io2str AugmentorBase.showconstruction(::IO, obj)


# camera = testimage("cameraman")
# cameras = similar(camera, size(camera)..., 2)
# copy!(view(cameras,:,:,1), camera)
# copy!(view(cameras,:,:,2), camera)
square = Gray{N0f8}[0.1 0.2 0.3; 0.4 0.5 0.6; 0.7 0.6 0.9]
square2 = rand(Gray{N0f8}, 4, 4)
rect = Gray{N0f8}[0.1 0.2 0.3; 0.4 0.5 0.6]
checkers = Gray{N0f8}[1 0 1 0 1; 0 1 0 1 0; 1 0 1 0 1]
rgb_rect = rand(RGB{N0f8}, 2, 3)

tests = [
    "tst_utils.jl",
    "operations/tst_convert.jl",
    "operations/tst_mapfun.jl",
    "operations/tst_noop.jl",
    "operations/tst_cache.jl",
    "operations/tst_crop.jl",
    "operations/tst_resize.jl",
    # "operations/tst_either.jl",
    "tst_operations.jl",
    "tst_pipeline.jl",
    "tst_augment.jl",
    # "tst_augmentbatch.jl",
]

@testset "AugmentorBase" begin
    @info "Testing AugmentorBase"

    for t in tests
        @testset "$t" begin
            include(t)
        end
    end
end
