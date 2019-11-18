_berror() = throw(ArgumentError("Number of output images must be equal to the number of input images"))

inputvector(inputs::AbstractArray, args...) = obsview(inputs, args...)
inputvector(inputs::Tuple{Vararg{AbstractArray}}, args...) = obsview(inputs, args...)
@inline inputvector(inputs::AbstractVector{<:AbstractArray}, args...) = inputs
@inline inputvector(inputs::AbstractVector{<:Tuple{Vararg{AbstractArray}}}, args...) = inputs

# --------------------------------------------------------------------

"""
    augmentbatch!([resource], outputs, inputs, pipeline, [obsdim]) -> outputs

Apply the operations of the given `pipeline` to the images in
`inputs` and write the resulting images into `outputs`.

Both `outputs` and `inputs` have to contain the same number of images.
Each of these two variables can either be in the form of a higher
dimensional array, in the form of a vector of arrays for which
each vector element denotes an image.

```julia
# create five example observations of size 3x3
inputs = rand(3,3,5)
# create output arrays of appropriate shape
outputs = similar(inputs)
# transform the batch of images
augmentbatch!(outputs, inputs, FlipX() |> FlipY())
```

If one (or both) of the two parameters `outputs` and `inputs` is a
higher dimensional array, then the optional parameter `obsdim`
can be used specify which dimension denotes the observations
(defaults to `ObsDim.Last()`),

```julia
# create five example observations of size 3x3
inputs = rand(5,3,3)
# create output arrays of appropriate shape
outputs = similar(inputs)
# transform the batch of images
augmentbatch!(outputs, inputs, FlipX() |> FlipY(), ObsDim.First())
```

Similar to [`augment!`](@ref), it is also allowed for `outputs` and
`inputs` to both be tuples of the same length. If that is the case,
then each tuple element can be in any of the forms listed above.
This is useful for tasks such as image segmentation, where each
observations is made up of more than one image.

```julia
# create five example observations where each observation is
# made up of two conceptually linked 3x3 arrays
inputs = (rand(3,3,5), rand(3,3,5))
# create output arrays of appropriate shape
outputs = similar.(inputs)
# transform the batch of images
augmentbatch!(outputs, inputs, FlipX() |> FlipY())
```

The parameter `pipeline` can be a `AugmentorBase.Pipeline`, a tuple
of `AugmentorBase.Operation`, or a single `AugmentorBase.Operation`.

```julia
augmentbatch!(outputs, inputs, FlipX() |> FlipY())
augmentbatch!(outputs, inputs, (FlipX(), FlipY()))
augmentbatch!(outputs, inputs, FlipX())
```

The optional first parameter `resource` can either be `CPU1()`
(default) or `CPUThreads()`. In the later case the images will be
augmented in parallel. For this to make sense make sure that the
environment variable `JULIA_NUM_THREADS` is set to a reasonable
number so that `Threads.nthreads()` is greater than 1.

```julia
# transform the batch of images in parallel using multithreading
augmentbatch!(CPUThreads(), outputs, inputs, FlipX() |> FlipY())
```
"""
function augmentbatch!(
        outputs::Union{Tuple, AbstractArray},
        inputs::Union{Tuple, AbstractArray},
        pipeline,
        args...)
    augmentbatch!(CPU1(), outputs, inputs, pipeline, args...)
end

function augmentbatch!(
        r::AbstractResource,
        outputs::Union{Tuple, AbstractArray},
        inputs::Union{Tuple, AbstractArray},
        pipeline,
        obsdim = MLDataPattern.default_obsdim(outputs))
    augmentbatch!(r, inputvector(outputs, obsdim), inputvector(inputs, obsdim), pipeline)
    outputs
end

function augmentbatch!(
        ::CPU1,
        outputs::AbstractVector{<:Union{Tuple, AbstractArray}},
        inputs::AbstractVector{<:Union{Tuple, AbstractArray}},
        pipeline)
    length(outputs) == length(inputs) || _berror()
    for i in 1:length(outputs)
        augment!(outputs[i], inputs[i], pipeline)
    end
    outputs
end

function augmentbatch!(
        ::CPUThreads,
        outputs::AbstractVector{<:Union{Tuple, AbstractArray}},
        inputs::AbstractVector{<:Union{Tuple, AbstractArray}},
        pipeline)
    length(outputs) == length(inputs) || _berror()
    Threads.@threads for i in 1:length(outputs)
        augment!(outputs[i], inputs[i], pipeline)
    end
    outputs
end
