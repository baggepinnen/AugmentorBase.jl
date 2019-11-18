"""
    MapFun <: AugmentorBase.Operation

Description
--------------

Maps the given function over all individual array elements.

This means that the given function is called with an individual
elements and is expected to return a transformed element that
should take the original's place. This further implies that the
function is expected to be unary. It is encouraged that the
function should be consistent with its return type and
type-stable.

Usage
--------------

    MapFun(fun)

Arguments
--------------

- **`fun`** : The unary function that should be mapped over all
    individual array elements.

See also
--------------

[`AggregateThenMapFun`](@ref), [`ConvertEltype`](@ref), [`augment`](@ref)

Examples
--------------

```julia
using Augmentor, ColorTypes
input = testpattern()

# subtract the constant RGBA value from each pixel
augment(input, MapFun(px -> px - RGBA(0.5, 0.3, 0.7, 0.0)))

# separate channels to scale each numeric element by a constant value
pl = SplitChannels() |> MapFun(el -> el * 0.5) |> CombineChannels(RGBA)
augment(input, pl)
```
"""
struct MapFun{T} <: Operation
    fun::T
end

@inline supports_lazy(::Type{<:MapFun}) = true

function applyeager(op::MapFun, input::AbstractArray, param)
    maybe_copy(map(op.fun, input))
end

function applylazy(op::MapFun, input::AbstractArray, param)
    mappedarray(op.fun, input)
end

function showconstruction(io::IO, op::MapFun)
    print(io, nameof(typeof(op)), '(', op.fun, ')')
end

function Base.show(io::IO, op::MapFun)
    if get(io, :compact, false)
        print(io, "Map function \"", op.fun, "\" over image")
    else
        print(io, "AugmentorBase.")
        showconstruction(io, op)
    end
end

# --------------------------------------------------------------------

"""
    AggregateThenMapFun <: AugmentorBase.Operation

Description
--------------

Compute some aggregated value of the current image using the
given function `aggfun`, and map that value over the current
image using the given function `mapfun`.

This is particularly useful for achieving effects such as
per-image normalization.

Usage
--------------

    AggregateThenMapFun(aggfun, mapfun)

Arguments
--------------

- **`aggfun`** : A function that takes the whole current image as
    input and which result will also be passed to `mapfun`. It
    should have a signature of `input -> agg`, where `input` will the
    the current image. What type and value `agg` should be is up
    to the user.

- **`mapfun`** : The binary function that should be mapped over
    all individual array elements. It should have a signature of
    `(px, agg) -> new_px` where `px` is a single element of the
    current image, and `agg` is the output of `aggfun`.

See also
--------------

[`MapFun`](@ref), [`ConvertEltype`](@ref), [`augment`](@ref)

Examples
--------------

```julia
using Augmentor
input = testpattern()

# subtract the average RGB value of the current image
augment(input, AggregateThenMapFun(input -> mean(input), (px, agg) -> px - agg))
```
"""
struct AggregateThenMapFun{A,M} <: Operation
    aggfun::A
    mapfun::M
end

@inline supports_lazy(::Type{<:AggregateThenMapFun}) = true

function applyeager(op::AggregateThenMapFun, input::AbstractArray, param)
    agg = op.aggfun(input)
    maybe_copy(map(x -> op.mapfun(x, agg), input))
end

function applylazy(op::AggregateThenMapFun, input::AbstractArray, param)
    agg = op.aggfun(input)
    mappedarray(x -> op.mapfun(x, agg), input)
end

function showconstruction(io::IO, op::AggregateThenMapFun)
    print(io, nameof(typeof(op)), '(', op.aggfun, ", ", op.mapfun, ')')
end

function Base.show(io::IO, op::AggregateThenMapFun)
    if get(io, :compact, false)
        print(io, "Map result of \"", op.aggfun, "\" using \"", op.mapfun, "\" over image")
    else
        print(io, "AugmentorBase.")
        showconstruction(io, op)
    end
end
