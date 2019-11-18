abstract type Operation end
abstract type ArrayOperation <: Operation end
abstract type VectorOperation <: ArrayOperation end
abstract type ImageOperation <: ArrayOperation end
abstract type AffineOperation <: ImageOperation end
abstract type Pipeline end
const AbstractPipeline = Union{Pipeline,Tuple{Vararg{Operation}}}
