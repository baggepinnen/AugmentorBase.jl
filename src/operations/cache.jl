"""
    CacheIntermediate <: Augmentor.ImageOperation

Description
--------------

Write the current state of the image into the working memory.
Optionally a user has the option to specify a preallocated
`buffer` to write the image into. Note that if a `buffer` is
provided, then it has to be of the correct size and eltype.

Even without a preallocated `buffer` it can be beneficial in some
situations to cache the image. An example for such a scenario is
when chaining a number of affine transformations after an elastic
distortion, because performing that lazily requires nested
interpolation.

Usage
--------------

    CacheIntermediate()

    CacheIntermediate(buffer)

Arguments
--------------

- **`buffer`** : Optional. A preallocated `AbstractArray` of the
    appropriate size and eltype.

See also
--------------

[`augment`](@ref)

Examples
--------------

```julia
using Augmentor

# make pipeline that forces caching after elastic distortion
pl = ElasticDistortion(3,3) |> CacheIntermediate() |> Rotate(-10:10) |> ShearX(-5:5)

# cache output of elastic distortion into the allocated
# 20x20 Matrix{Float64}. Note that for this case this assumes that
# the input image is also a 20x20 Matrix{Float64}
pl = ElasticDistortion(3,3) |> CacheIntermediate(zeros(20,20)) |> Rotate(-10:10)

# convenience syntax with the same effect as above.
pl = ElasticDistortion(3,3) |> zeros(20,20) |> Rotate(-10:10)
```
"""
struct CacheIntermediate <: ImageOperation end

applyeager(op::CacheIntermediate, input::AbstractArray, param) = maybe_copy(input)

function showconstruction(io::IO, op::CacheIntermediate)
    print(io, typeof(op).name.name, "()")
end

function Base.show(io::IO, op::CacheIntermediate)
    if get(io, :compact, false)
        print(io, "Cache into temporary buffer")
    else
        print(io, "Augmentor.")
        showconstruction(io, op)
    end
end

# --------------------------------------------------------------------

"""
    CacheIntermediateInto <: Augmentor.ImageOperation

see [`CacheIntermediate`](@ref)
"""
struct CacheIntermediateInto{T<:Union{AbstractArray,Tuple}} <: ImageOperation
    buffer::T
end
CacheIntermediate(buffer::AbstractArray) = CacheIntermediateInto(buffer)
CacheIntermediate(buffers::AbstractArray...) = CacheIntermediateInto(buffers)
CacheIntermediate(buffers::NTuple{N,AbstractArray}) where {N} = CacheIntermediateInto(buffers)

@inline supports_lazy(::Type{<:CacheIntermediateInto}) = true

applyeager(op::CacheIntermediateInto, input::AbstractArray, param) = applylazy(op, input)
applyeager(op::CacheIntermediateInto, input::Tuple) = applylazy(op, input)

function applylazy(op::CacheIntermediateInto, input::Tuple)
    throw(ArgumentError("Operation $(op) not compatiable with given image(s) ($(summary(input))). This can happen if the amount of images does not match the amount of buffers in the operation"))
end

function applylazy(op::CacheIntermediateInto{<:AbstractArray}, input::AbstractArray, param)
    copy!(match_idx(op.buffer, axes(input)), input)
end

function applylazy(op::CacheIntermediateInto{<:Tuple}, inputs::Tuple)
    map(op.buffer, inputs) do buffer, input
        copy!(match_idx(buffer, axes(input)), input)
    end
end

function _showconstruction(io::IO, array::AbstractArray)
    print(io, "Array{")
    _showcolor(io, eltype(array))
    print(io, "}(")
    print(io, join(map(i->string(length(i)), axes(array)), ", "))
    print(io, ")")
end

function showconstruction(io::IO, op::CacheIntermediateInto{<:AbstractArray})
    print(io, "CacheIntermediate(") # shows exported API
    _showconstruction(io, op.buffer)
    print(io, ")")
end

function showconstruction(io::IO, op::CacheIntermediateInto{<:Tuple})
    print(io, "CacheIntermediate(")
    for (i, buffer) in enumerate(op.buffer)
        _showconstruction(io, buffer)
        i < length(op.buffer) && print(io, ", ")
    end
    print(io, ")")
end

function Base.show(io::IO, op::CacheIntermediateInto{<:AbstractArray})
    if get(io, :compact, false)
        print(io, "Cache into preallocated ")
        print(io, summary(op.buffer))
    else
        print(io, typeof(op).name, "(")
        Base.showarg(io, op.buffer, false)
        print(io, ")")
    end
end

function Base.show(io::IO, op::CacheIntermediateInto{<:Tuple})
    if get(io, :compact, false)
        print(io, "Cache into preallocated ")
        print(io, "(", join(map(summary, op.buffer), ", "), ")")
    else
        print(io, typeof(op).name, "((")
        for (i, buffer) in enumerate(op.buffer)
            Base.showarg(io, buffer, false)
            i < length(op.buffer) && print(io, ", ")
        end
        print(io, "))")
    end
end
