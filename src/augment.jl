"""
    augment([input], pipeline) -> out

Apply the operations of the given `pipeline` sequentially to the
given image `input` and return the resulting image `out`.

```julia-repl
julia> input = testpattern();

julia> out = augment(input, FlipX() |> FlipY())
3×2 Array{Gray{N0f8},2}:
[...]
```

The parameter `input` can either be a single image, or a tuple of
multiple images. In case `input` is a tuple of images, its elements
will be assumed to be conceptually connected. Consequently, all
images in the tuple will take the exact same path through the
pipeline; even when randomness is involved. This is useful for the
purpose of image segmentation, for which the input and output are
both images that need to be transformed exactly the same way.

```julia
input1 = testpattern()
input2 = Gray.(testpattern())
out1, out2 = augment((input1, input2), FlipX() |> FlipY())
```

The parameter `pipeline` can be a `Augmentor.Pipeline`, a tuple
of `Augmentor.Operation`, or a single `Augmentor.Operation`.

```julia
input = testpattern()
augment(input, FlipX() |> FlipY())
augment(input, (FlipX(), FlipY()))
augment(input, FlipX())
```

If `input` is omitted, Augmentor will use the augmentation test
image provided by the function [`testpattern`](@ref) as the input
image.

```julia
augment(FlipX())
```
"""
function augment(input, pipeline::AbstractPipeline)
    plain_array(_augment(input, pipeline))
end

function augment(input, pipeline::Union{ImmutablePipeline{1},NTuple{1,Operation}})
    augment(input, first(operations(pipeline)))
end

function augment(input, op::Operation)
    plain_array(applyeager(op, input))
end

function augment(op::Union{AbstractPipeline,Operation})
    augment(use_testpattern(), op)
end

@inline function _augment(input, pipeline::AbstractPipeline)
    _augment(input, operations(pipeline)...)
end

@generated function _augment(input, pipeline::Vararg{Operation})
    Expr(:block, Expr(:meta, :inline), augment_impl(:input, pipeline, false))
end

# --------------------------------------------------------------------

"""
    augment!(out, input, pipeline) -> out

Apply the operations of the given `pipeline` sequentially to the
image `input` and write the resulting image into the preallocated
parameter `out`. For convenience `out` is also the function's
return-value.

```julia
input = testpattern()
out = similar(input)
augment!(out, input, FlipX() |> FlipY())
```

The parameter `input` can either be a single image, or a tuple of
multiple images. In case `input` is a tuple of images, the
parameter `out` has to be a tuple of the same length and
ordering. See [`augment`](@ref) for more information.

```julia
inputs = (testpattern(), Gray.(testpattern()))
outs = (similar(inputs[1]), similar(inputs[2]))
augment!(outs, inputs, FlipX() |> FlipY())
```

The parameter `pipeline` can be a `Augmentor.Pipeline`, a tuple
of `Augmentor.Operation`, or a single `Augmentor.Operation`.

```julia
input = testpattern()
out = similar(input)
augment!(out, input, FlipX() |> FlipY())
augment!(out, input, (FlipX(), FlipY()))
augment!(out, input, FlipX())
```
"""
augment!(out, input, op::Operation) = augment!(out, input, (op,))

function augment!(out::AbstractArray, input::AbstractArray, pipeline::AbstractPipeline)
    out_lazy = _augment_avoid_eager(input, pipeline)
    copy!(match_idx(out, axes(out_lazy)), out_lazy)
    out
end

function augment!(outs::NTuple{N,AbstractArray}, inputs::NTuple{N,AbstractArray}, pipeline::AbstractPipeline) where N
    outs_lazy = _augment_avoid_eager(inputs, pipeline)
    map(outs, outs_lazy) do out, out_lazy
        copy!(match_idx(out, axes(out_lazy)), out_lazy)
    end
    outs
end

@inline function _augment_avoid_eager(input, pipeline::AbstractPipeline)
    _augment_avoid_eager(input, operations(pipeline)...)
end

@generated function _augment_avoid_eager(input, pipeline::Vararg{Operation})
    Expr(:block, Expr(:meta, :inline), augment_impl(:input, pipeline, true))
end
