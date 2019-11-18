"""
    NoOp <: AugmentorBase.AffineOperation

Identity transformation that does not do anything with the given
image, but instead passes it along unchanged (without copying).

Usually used in combination with [`Either`](@ref) to denote a
"branch" that does not perform any computation.
"""
struct NoOp <: AffineOperation end

@inline supports_eager(::Type{NoOp}) = false
@inline supports_stepview(::Type{NoOp}) = true
@inline supports_view(::Type{NoOp}) = true

# TODO: implement method for n-dim arrays
applyeager(::NoOp, input::AbstractArray, param) = maybe_copy(input)
applylazy(::NoOp, input::AbstractArray, param) = input

function applyview(::NoOp, input::AbstractArray, param)
    idx = map(i->1:length(i), axes(input))
    indirect_view(input, idx)
end

function applystepview(::NoOp, input::AbstractArray, param)
    idx = map(i->1:1:length(i), axes(input))
    indirect_view(input, idx)
end

function showconstruction(io::IO, op::NoOp)
    print(io, typeof(op).name.name, "()")
end

function Base.show(io::IO, op::NoOp)
    if get(io, :compact, false)
        print(io, "No operation")
    else
        print(io, "AugmentorBase.")
        showconstruction(io, op)
    end
end
