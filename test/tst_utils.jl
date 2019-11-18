@testset "testpattern" begin
    tp = testpattern()
    @test typeof(tp) <: Matrix
    @test eltype(tp) <: RGBA
    @test size(tp) === (300,400)
    tp2 = augment(NoOp())
    @test tp == tp2
end

@testset "safe_rand" begin
    num = @inferred AugmentorBase.safe_rand()
    @test 0 <= num <= 1
    @test typeof(num) <: Float64
    num = @inferred AugmentorBase.safe_rand(2)
    @test all(0 .<= num .<= 1)
    @test typeof(num) <: Vector{Float64}
end

@testset "maybe_copy" begin
    A = [1 2 3; 4 5 6; 7 8 9]
    Ao = OffsetArray(A, (-2,-1))
    @test @inferred(AugmentorBase.maybe_copy(A)) === A
    @test @inferred(AugmentorBase.maybe_copy(Ao)) === Ao
    let Ast = @SMatrix [1 2 3; 4 5 6; 7 8 9]
        @test @inferred(AugmentorBase.maybe_copy(Ast)) === Ast
    end
    let v = view(A, 2:3, 1:2)
        @test @inferred(AugmentorBase.maybe_copy(v)) == A[2:3, 1:2]
        @test typeof(AugmentorBase.maybe_copy(v)) <: Array
    end
    let v = view(OffsetArray(A, (-2,-1)), 0:1, 0:1)
        @test @inferred(AugmentorBase.maybe_copy(v)) == A[2:3, 1:2]
        @test typeof(AugmentorBase.maybe_copy(v)) <: Array
    end
    let v = view(A, IdentityRange(2:3), IdentityRange(1:2))
        @test @inferred(AugmentorBase.maybe_copy(v)) == OffsetArray(A[2:3,1:2], (1, 0))
        @test typeof(AugmentorBase.maybe_copy(v)) <: OffsetArray
    end

    let Ar = reshape(view(A,:,:),1,3,3)
        @test @inferred(AugmentorBase.maybe_copy(Ar)) == reshape(A,1,3,3)
        @test typeof(AugmentorBase.maybe_copy(Ar)) <: Array{Int,3}
    end
    let Ar = reshape(view(Ao,:,:),1,3,3)
        @test @inferred(AugmentorBase.maybe_copy(Ar)) == reshape(A,1,3,3)
        @test typeof(AugmentorBase.maybe_copy(Ar)) <: Array{Int,3}
    end
end

@testset "plain_array" begin
    A = [1 2 3; 4 5 6; 7 8 9]
    @test @inferred(AugmentorBase.plain_array(A)) === A
    @test @inferred(AugmentorBase.plain_array(OffsetArray(A, (-2,-1)))) === A
    let As = sparse(A)
       @test @inferred(AugmentorBase.plain_array(As)) == A
       @test typeof(AugmentorBase.plain_array(As)) <: Array
       Ar = reshape(As, 3, 3, 1)
       @test typeof(Ar) <: Base.ReshapedArray
       @test @inferred(AugmentorBase.plain_array(Ar)) == reshape(A,3,3,1)
       @test typeof(AugmentorBase.plain_array(Ar)) <: Array
    end
    let Ast = @SMatrix [1 2 3; 4 5 6; 7 8 9]
        @test @inferred(AugmentorBase.plain_array(Ast)) === Ast
    end
    let v = view(A, 2:3, 1:2)
        @test @inferred(AugmentorBase.plain_array(v)) == A[2:3, 1:2]
        @test typeof(AugmentorBase.plain_array(v)) <: Array
    end
    let v = view(OffsetArray(A, (-2,-1)), 0:1, 0:1)
        @test @inferred(AugmentorBase.plain_array(v)) == A[2:3, 1:2]
        @test typeof(AugmentorBase.plain_array(v)) <: Array
    end
    let v = view(A, IdentityRange(2:3), IdentityRange(1:2))
        @test @inferred(AugmentorBase.plain_array(v)) == A[2:3, 1:2]
        @test typeof(AugmentorBase.plain_array(v)) <: Array
    end
    let Ar = reshape(view(A,:,:),1,3,3)
        @test @inferred(AugmentorBase.plain_array(Ar)) == reshape(A,1,3,3)
        @test typeof(AugmentorBase.plain_array(Ar)) <: Array{Int,3}
    end
end

@testset "plain_axes" begin
    A = [1 2 3; 4 5 6; 7 8 9]
    @test @inferred(AugmentorBase.plain_axes(A)) === A
    @test @inferred(AugmentorBase.plain_axes(OffsetArray(A, (-2,-1)))) === A
    let v = view(A, 2:3, 1:2)
        @test @inferred(AugmentorBase.plain_axes(v)) === v
    end
    let v = view(OffsetArray(A, (-2,-1)), 0:1, 0:1)
        @test @inferred(AugmentorBase.plain_axes(v)) === v
    end
    let v = view(A, IdentityRange(2:3), IdentityRange(1:2))
        @test @inferred(AugmentorBase.plain_axes(v)) === view(A, 2:3, 1:2)
    end

    let Ar = reshape(view(A,:,:),1,3,3)
        @test @inferred(AugmentorBase.plain_axes(Ar)) === Ar
    end
end

@testset "match_idx" begin
    A = [1 2 3; 4 5 6; 7 8 9]
    @test @inferred(AugmentorBase.match_idx(A, axes(A))) === A
    let img = @inferred AugmentorBase.match_idx(A, (2:4, 2:4))
        @test axes(img) === Base.IdentityUnitRange.((2:4, 2:4))
        @test typeof(img) <: OffsetArray
    end
    let B = view(A,1:3,1:3)
        @test @inferred(AugmentorBase.match_idx(B, axes(B))) === B
    end
    let B = view(A,1:3,1:3)
        img = @inferred(AugmentorBase.match_idx(B, B.indices))
        @test axes(img) === Base.IdentityUnitRange.((1:3, 1:3))
        @test typeof(img) <: OffsetArray
    end
    let img = @inferred AugmentorBase.match_idx(view(A,1:3,1:3), (2:4,2:4))
        @test axes(img) === Base.IdentityUnitRange.((2:4, 2:4))
        @test typeof(img) <: OffsetArray
    end

end

@testset "direct_view" begin
    A = [1 2 3; 4 5 6; 7 8 9]
    Av = view(A, IdentityRange(2:3), IdentityRange(1:2))
    As = view(A, 3:-1:2, 1:1:2)
    @test_throws MethodError AugmentorBase.indirect_axes((), ())
    @test_throws MethodError AugmentorBase.direct_axes((), ())
    @test_throws MethodError AugmentorBase.direct_view(A, ())
    @test @inferred(AugmentorBase.direct_view(A, (2:3,1:2))) === Av
    @test @inferred(AugmentorBase.indirect_view(A, (2:3,1:2))) === Av
    @test @inferred(AugmentorBase.direct_view(A, (IdentityRange(2:3),IdentityRange(1:2)))) === Av
    @test @inferred(AugmentorBase.indirect_view(A, (IdentityRange(2:3),IdentityRange(1:2)))) === Av
    @test @inferred(AugmentorBase.direct_view(A, (3:-1:2,1:1:2))) === As
    @test @inferred(AugmentorBase.indirect_view(A, (3:-1:2,1:1:2))) === As
    @test @inferred(AugmentorBase.direct_view(Av, (3:3,1:2))) === view(Av,3:3,1:2)
    @test @inferred(AugmentorBase.indirect_view(Av, (2:2,1:2))) === view(Av,3:3,1:2)
    @test @inferred(AugmentorBase.direct_view(Av, (IdentityRange(3:3),IdentityRange(1:2)))) === view(Av,3:3,1:2)
    @test @inferred(AugmentorBase.indirect_view(Av, (IdentityRange(2:2),IdentityRange(1:2)))) === view(Av,3:3,1:2)
    @test_throws MethodError AugmentorBase.direct_view(Av, (3:-1:2,2:-1:1))
    @test @inferred(AugmentorBase.indirect_view(Av, (2:-1:1,2:-1:1))) === view(A,3:-1:2,2:-1:1)
end

@testset "vectorize" begin
    @test @inferred(AugmentorBase.vectorize(2)) === 2:2
    @test @inferred(AugmentorBase.vectorize(2.3)) === 2.3:2.3
    @test @inferred(AugmentorBase.vectorize(3:4)) === 3:4
    @test @inferred(AugmentorBase.vectorize(3:1:4)) === 3:1:4
    @test @inferred(AugmentorBase.vectorize(3.0:4)) === 3.0:4
    @test @inferred(AugmentorBase.vectorize(3.0:1:4)) === 3.0:1:4
    @test @inferred(AugmentorBase.vectorize(Base.OneTo(4))) === Base.OneTo(4)
end

@testset "round_if_float" begin
    @test @inferred(AugmentorBase.round_if_float(3,2)) === 3
    @test @inferred(AugmentorBase.round_if_float(3.1111,2)) === 3.11
    @test @inferred(AugmentorBase.round_if_float((3,3.1111),2)) === (3,3.11)
end

@testset "unionrange" begin
    @test_throws MethodError AugmentorBase.unionrange(1:1:2, 4:5)
    @test @inferred(AugmentorBase.unionrange(1:5, 2:6)) === 1:6
    @test @inferred(AugmentorBase.unionrange(2:6, 1:5)) === 1:6
    @test @inferred(AugmentorBase.unionrange(1:2, 4:5)) === 1:5
    @test @inferred(AugmentorBase.unionrange(Base.OneTo(2), 4:5)) === 1:5
    @test @inferred(AugmentorBase.unionrange(1:6, 2:3)) === 1:6
    @test @inferred(AugmentorBase.unionrange(2:3, 1:6)) === 1:6
end

@testset "_2dborder!" begin
    A = rand(2, 5, 6)
    @test @inferred(AugmentorBase._2dborder!(A, 0.)) === A
    s = 0.
    ndim, h, w = size(A)
    for i = 1:h, j = 1:w
        if i == 1 || j == 1 || i == h || j == w
            for d = 1:ndim
                s += abs(A[d, i, j])
            end
        end
    end
    @test s == 0.
end
