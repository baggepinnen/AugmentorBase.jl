# Things to test
# [x] Construction limited to ImageOperation
# [x] Construction also works for ops like ElasticDistortion

@test (Either <: AugmentorBase.AffineOperation) == false
@test Either <: AugmentorBase.Operation

@testset "constructor" begin
    @test_throws ArgumentError Either()
    # T not defined:
    @test_throws UndefVarError Either(())
    @test_throws ArgumentError Either((NoOp(),),(0,))
    @test_throws ArgumentError Either((NoOp(),),(-1,))
    @test_throws MethodError Either((NoOp(),),(1,1))
    let op = @inferred Either(Rotate90(), 0.3)
        @test op.operations === (Rotate90(), NoOp())
        @test op.chances === @SVector([0.3,0.7])
        @test op.cum_chances === @SVector([0.3,1.0])
    end
    let op = @inferred Either(Rotate90())
        @test op.operations === (Rotate90(), NoOp())
        @test op.chances === @SVector([0.5,0.5])
        @test op.cum_chances === @SVector([0.5,1.0])
    end
    let op = @inferred Either(1 => Rotate90(), 2 => Rotate180(), 1 => Crop(1:10,1:10))
        @test op.operations === (Rotate90(),Rotate180(),Crop(1:10,1:10))
        @test op.chances === @SVector([0.25,0.5,0.25])
        @test op.cum_chances === @SVector([0.25,0.75,1.])
    end
    let op = @inferred Either(1 => Rotate90(), 2 => Rotate180(), 1 => Crop(1:10,1:10))
        @test op.operations === (Rotate90(),Rotate180(),Crop(1:10,1:10))
        @test op.chances === @SVector([0.25,0.5,0.25])
        @test op.cum_chances === @SVector([0.25,0.75,1.])
    end
    let op = @inferred Either((Rotate90(),Rotate180(),Crop(1:10,1:10)), (0.1,0.7,0.2))
        @test op.operations === (Rotate90(),Rotate180(),Crop(1:10,1:10))
        @test op.chances === @SVector([0.1,0.7,0.2])
        @test op.cum_chances ≈ @SVector([0.1,0.8,1.])
    end
    let op = @inferred Either((Rotate90(),Rotate180(),Crop(1:10,1:10)))
        @test op.operations === (Rotate90(),Rotate180(),Crop(1:10,1:10))
        @test op.chances ≈ @SVector([1/3,1/3,1/3])
        @test op.cum_chances ≈ @SVector([1/3,2/3,3/3])
    end
    let op = Either(Rotate90(), Rotate180(), Crop(1:10,1:10), chances = [1,7,2])
        @test op.operations === (Rotate90(),Rotate180(),Crop(1:10,1:10))
        @test op.chances === @SVector([0.1,0.7,0.2])
        @test op.cum_chances ≈ @SVector([0.1,0.8,1.])
    end
    let op = @inferred Either(Rotate90(),Rotate180(),Crop(1:10,1:10))
        @test op.operations === (Rotate90(),Rotate180(),Crop(1:10,1:10))
        @test op.chances ≈ @SVector([1/3,1/3,1/3])
        @test op.cum_chances ≈ @SVector([1/3,2/3,3/3])
    end
    let op = @inferred(Rotate90()*Rotate180()*Crop(1:10,1:10))
        @test op.operations === (Rotate90(),Rotate180(),Crop(1:10,1:10))
        @test op.chances ≈ @SVector([1/3,1/3,1/3])
        @test op.cum_chances ≈ @SVector([1/3,2/3,3/3])
    end
    let op = @inferred(Rotate90()*Rotate180()*ElasticDistortion(5))
        @test op.operations === (Rotate90(),Rotate180(),ElasticDistortion(5))
        @test op.chances ≈ @SVector([1/3,1/3,1/3])
        @test op.cum_chances ≈ @SVector([1/3,2/3,3/3])
    end
    let op = @inferred((1=>Rotate90())*(2=>Rotate180())*(1=>Crop(1:10,1:10)))
        @test op.operations === (Rotate90(),Rotate180(),Crop(1:10,1:10))
        @test op.chances ≈ @SVector([1/4,2/4,1/4])
        @test op.cum_chances ≈ @SVector([1/4,3/4,4/4])
    end
end

@testset "show" begin
    @test str_show(Either((Rotate90(),Rotate270(),NoOp()), (0.2,0.3,0.5))) == """
    AugmentorBase.Either (1 out of 3 operation(s)):
      - 20% chance to: Rotate 90 degree
      - 30% chance to: Rotate 270 degree
      - 50% chance to: No operation"""
    @test str_showcompact(Either((Rotate90(),Rotate270(),NoOp()), (0.2,0.3,0.5))) ==
        "Either: (20%) Rotate 90 degree. (30%) Rotate 270 degree. (50%) No operation."
    @test str_show(Either((Rotate90(),Rotate270(),NoOp()), (0.15,0.8,0.05))) == """
    AugmentorBase.Either (1 out of 3 operation(s)):
      - 15% chance to: Rotate 90 degree
      - 80% chance to: Rotate 270 degree
      -  5% chance to: No operation"""
    @test str_showcompact(Either((Rotate90(),Rotate270(),NoOp()), (0.15,0.8,0.05))) ==
        "Either: (15%) Rotate 90 degree. (80%) Rotate 270 degree. (5%) No operation."
    @test str_show(Either((Rotate90(),Rotate270(),NoOp()), (0.155,0.8,0.045))) == """
    AugmentorBase.Either (1 out of 3 operation(s)):
      - 15.5% chance to: Rotate 90 degree
      - 80.0% chance to: Rotate 270 degree
      -  4.5% chance to: No operation"""
    @test str_showcompact(Either((Rotate90(),Rotate270(),NoOp()), (0.155,0.8,0.045))) ==
        "Either: (16%) Rotate 90 degree. (80%) Rotate 270 degree. (4%) No operation."
    @test str_showconst(Either(Rotate90(), Rotate270(), NoOp())) == "Rotate90() * Rotate270() * NoOp()"
    @test str_showconst(Either((Rotate90(), Rotate270(), NoOp()),(1,1,2))) == "(0.25=>Rotate90()) * (0.25=>Rotate270()) * (0.5=>NoOp())"
    @test str_showconst(Either((Rotate90(), NoOp()),(1,2))) == "(0.333=>Rotate90()) * (0.667=>NoOp())"
end

@testset "eager" begin
    @test_throws MethodError AugmentorBase.applyeager(Either(Rotate90(),NoOp()), nothing)
    imgs = [
        (rect),
        (view(rect, :, :)),
        (AugmentorBase.prepareaffine(rect)),
        (OffsetArray(rect, -2, -1)),
        (view(rect, IdentityRange(1:2), IdentityRange(1:3))),
    ]
    for img in imgs
        let op = @inferred Either((Rotate90(),ElasticDistortion(5)), (1,0))
            @test_throws MethodError AugmentorBase.applylazy(op, img)
            @test AugmentorBase.supports_eager(op) === true
            @test AugmentorBase.supports_affine(op) === false
            @test AugmentorBase.supports_lazy(op) === false
            @test AugmentorBase.supports_affineview(op) === false
            @test AugmentorBase.supports_view(op) === false
            @test AugmentorBase.supports_stepview(op) === false
            @test AugmentorBase.supports_permute(op) === false
            @test @inferred(AugmentorBase.applyeager(op, img)) == rotl90(rect)
            @test typeof(AugmentorBase.applyeager(op, img)) <: OffsetArray
            res1, res2 = @inferred(AugmentorBase.applyeager(op, (square2, img)))
            @test res1 == rotl90(square2)
            @test res2 == rotl90(rect)
        end
        let op = @inferred Either((Rotate90(),Rotate270()), (1,0))
            @test AugmentorBase.supports_eager(op) === true
            @test @inferred(AugmentorBase.applyeager(op, img)) == rotl90(rect)
            @test typeof(AugmentorBase.applyeager(op, img)) <: OffsetArray
        end
        let op = @inferred Either((Rotate90(),Rotate270(),Crop(1:2,2:3)), (0,1,0))
            @test AugmentorBase.supports_eager(op) === true
            @test @inferred(AugmentorBase.applyeager(op, img)) == rotr90(rect)
            @test typeof(AugmentorBase.applyeager(op, img)) <: OffsetArray
        end
        let op = @inferred Either((Rotate90(),Rotate270(),NoOp()), (0,0,1))
            @test AugmentorBase.supports_eager(op) === true
            if img isa Union{Array,OffsetArray}
                @test parent(@inferred(AugmentorBase.applyeager(op, img))) === rect
            else
                @test @inferred(AugmentorBase.applyeager(op, img)) == rect
                @test typeof(AugmentorBase.applyeager(op, img)) <: OffsetArray
            end
        end
        let op = @inferred Either((Rotate90(),Rotate270(),Crop(1:2,2:3)), (0,0,1))
            @test AugmentorBase.supports_eager(op) === true
            @test collect(@inferred(AugmentorBase.applyeager(op, img))) == rect[1:2,2:3]
            @test_throws MethodError AugmentorBase.applyaffine(op, rect)
            @test_throws MethodError AugmentorBase.applyview(op, rect)
            @test_throws MethodError AugmentorBase.applystepview(op, rect)
            @test_throws MethodError AugmentorBase.applypermute(op, rect)
        end
        let op = @inferred Either((Rotate90(),Zoom(.8)), (1,0))
            @test AugmentorBase.supports_eager(op) === true
            @test @inferred(AugmentorBase.applyeager(op, img)) == rotl90(rect)
            @test typeof(AugmentorBase.applyeager(op, img)) <: OffsetArray
        end
        let op = @inferred Either((Rotate90(),FlipX()), (1,0))
            @test AugmentorBase.supports_eager(op) === true
            @test @inferred(AugmentorBase.applyeager(op, img)) == rotl90(rect)
            @test typeof(AugmentorBase.applyeager(op, img)) <: OffsetArray
        end
        let op = @inferred Either((Rotate90(),FlipX()), (0,1))
            @test AugmentorBase.supports_eager(op) === true
            @test @inferred(AugmentorBase.applyeager(op, img)) == reverse(rect, dims=2)
            @test typeof(AugmentorBase.applyeager(op, img)) <: OffsetArray
        end
        let op = @inferred Either((Rotate90(),FlipY()), (0,1))
            @test AugmentorBase.supports_eager(op) === true
            @test @inferred(AugmentorBase.applyeager(op, img)) == reverse(rect, dims=1)
            @test typeof(AugmentorBase.applyeager(op, img)) <: OffsetArray
        end
        let op = @inferred Either((Rotate90(),Resize(5,5)), (0,1))
            @test AugmentorBase.supports_eager(op) === true
            @test @inferred(AugmentorBase.applyeager(op, img)) == imresize(rect,5,5)
            @test typeof(AugmentorBase.applyeager(op, img)) <: OffsetArray
        end
        let op = @inferred Either((Crop(1:2,1:2),Resize(5,5)), (0,1))
            @test AugmentorBase.supports_eager(op) === true
            @test @inferred(AugmentorBase.applyeager(op, img)) == imresize(rect,5,5)
            @test typeof(AugmentorBase.applyeager(op, img)) <: OffsetArray
        end
        let op = @inferred Either((Rotate90(),Rotate270(),Crop(1:2,2:3)))
            @test AugmentorBase.supports_eager(op) === true
            res1, res2 = @inferred(AugmentorBase.applyeager(op, (N0f8.(img), img)))
            @test res1 == res2
        end
    end
end

@testset "affine" begin
    let op = @inferred Either((Rotate90(),Rotate(-90)), (1,0))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.applyaffine(op, nothing)
        @test @inferred(AugmentorBase.toaffinemap(op, rect, 1)) ≈ AffineMap([6.12323e-17 -1.0; 1.0 6.12323e-17], [3.5,0.5])
        wv = @inferred AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine(square))
        @test parent(wv).itp.coefs === square
        @test wv == rotl90(square)
        @test typeof(wv) <: InvWarpedView{eltype(square),2}
        res1, res2 = @inferred AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine.((square2, square)))
        @test res1 == rotl90(square2)
        @test res2 == rotl90(square)
    end
    let op = @inferred Either((Rotate90(),Rotate270()), (1,0))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === true
        @test_throws MethodError AugmentorBase.applyaffine(op, nothing)
        @test @inferred(AugmentorBase.toaffinemap(op, rect, 1)) ≈ AffineMap([6.12323e-17 -1.0; 1.0 6.12323e-17], [3.5,0.5])
        wv = @inferred AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine(square))
        @test parent(wv).itp.coefs === square
        @test wv == rotl90(square)
        @test typeof(wv) <: InvWarpedView{eltype(square),2}
    end
    let op = @inferred Either((Rotate180(),FlipX(),FlipY()), (0,1,0))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === true
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.applyaffine(op, nothing)
        @test @inferred(AugmentorBase.toaffinemap(op, rect, 2)) ≈ AffineMap([1. 0.; 0. -1.], [0,4])
        wv = @inferred AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine(square))
        @test parent(wv).itp.coefs === square
        @test wv == reverse(square, dims=2)
        @test typeof(wv) <: InvWarpedView{eltype(square),2}
    end
    let op = @inferred Either((Rotate90(),FlipY()), (0,1))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.applyaffine(op, nothing)
        @test @inferred(AugmentorBase.toaffinemap(op, rect, 2)) ≈ AffineMap([-1. 0.; 0. 1.], [3,0])
        wv = @inferred AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine(square))
        @test parent(wv).itp.coefs === square
        @test wv == reverse(square,dims=1)
        @test typeof(wv) <: InvWarpedView{eltype(square),2}
    end
    let op = @inferred Either((Rotate90(),Rotate270()), (0,1))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === true
        @test_throws MethodError AugmentorBase.applyaffine(op, nothing)
        @test @inferred(AugmentorBase.toaffinemap(op, rect, 2)) ≈ AffineMap([6.12323e-17 1.0; -1.0 6.12323e-17], [-0.5,3.5])
        wv = @inferred AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine(square))
        @test parent(wv).itp.coefs === square
        @test wv == rotr90(square)
        @test typeof(wv) <: InvWarpedView{eltype(square),2}
    end
    for op = (@inferred(Rotate90(1)), @inferred(Either((Rotate90(),Scale(0.8)),(1,0))))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.applyaffine(op, nothing)
        @test @inferred(AugmentorBase.toaffinemap(op, rect, 1)) ≈ AffineMap([6.12323e-17 -1.0; 1.0 6.12323e-17], [3.5,0.5])
        wv = @inferred AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine(square))
        @test parent(wv).itp.coefs === square
        @test wv == rotl90(square)
        @test typeof(wv) <: InvWarpedView{eltype(square),2}
        wv2 = @inferred AugmentorBase.applylazy(op, square)
        @test parent(wv2).itp.coefs === square
        @test wv2 == rotl90(square)
        @test typeof(wv2) == typeof(wv)
    end
    let op = @inferred Either((Rotate180(),FlipX(),FlipY()))
        res1, res2 = @inferred(AugmentorBase.applyaffine(op, (N0f8.(square), square)))
        @test res1 == res2
        @test typeof(res1) <: InvWarpedView{N0f8,2}
        @test typeof(res2) <: InvWarpedView{eltype(square),2}
    end
end

@testset "affineview" begin
    let op = @inferred Either((Rotate90(),Rotate270(),Crop(1:2,1:2)),(1,0,0))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.toaffinemap(op, nothing)
        @test_throws MethodError AugmentorBase.toaffinemap(op, rect, 1)
        @test_throws MethodError AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine(square))
        wv = @inferred AugmentorBase.applyaffineview(op, AugmentorBase.prepareaffine(square))
        @test typeof(wv) <: SubArray{eltype(square),2}
        @test typeof(parent(wv)) <: InvWarpedView
        @test parent(parent(wv)).itp.coefs === square
        @test wv == rotl90(square)
        wv2 = @inferred AugmentorBase.applylazy(op, square)
        @test typeof(wv) == typeof(wv2)
        @test parent(parent(wv2)).itp.coefs === square
        @test wv2 == wv
        res1, res2 = @inferred AugmentorBase.applyaffineview(op, AugmentorBase.prepareaffine.((square2,square)))
        @test res1 == rotl90(square2)
        @test res2 == rotl90(square)
    end
    let op = @inferred Either((Rotate90(),Rotate270(),CropSize(2,2)),(0,0,1))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.toaffinemap(op, nothing)
        @test_throws MethodError AugmentorBase.toaffinemap(op, rect, 1)
        @test_throws MethodError AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine(square))
        wv = @inferred AugmentorBase.applyaffineview(op, AugmentorBase.prepareaffine(square))
        @test typeof(wv) <: SubArray{eltype(square),2}
        @test typeof(parent(wv)) <: InvWarpedView
        @test parent(parent(wv)).itp.coefs === square
        @test wv == view(AugmentorBase.prepareaffine(square), IdentityRange(1:2), IdentityRange(1:2))
        wv2 = @inferred AugmentorBase.applylazy(op, square)
        @test typeof(wv) == typeof(wv2)
        @test parent(parent(wv2)).itp.coefs === square
        @test wv2 == wv
    end
    let op = @inferred Either((Rotate90(),Zoom(.8)), (0,1))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.toaffinemap(op, nothing)
        @test_throws MethodError AugmentorBase.toaffinemap(op, rect, 1)
        @test_throws MethodError AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine(square))
        wv = @inferred AugmentorBase.applyaffineview(op, AugmentorBase.prepareaffine(square))
        @test typeof(wv) <: SubArray{eltype(square),2}
        @test typeof(parent(wv)) <: InvWarpedView
        @test parent(parent(wv)).itp.coefs === square
        wv2 = @inferred AugmentorBase.applylazy(op, square)
        @test typeof(wv) == typeof(wv2)
        @test parent(parent(wv2)).itp.coefs === square
        @test wv2 == wv
    end
    let op = @inferred Either((Rotate90(),Resize(2,3)), (0,1))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.toaffinemap(op, nothing)
        @test_throws MethodError AugmentorBase.toaffinemap(op, rect, 1)
        @test_throws MethodError AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine(square))
        wv = @inferred AugmentorBase.applyaffineview(op, AugmentorBase.prepareaffine(square))
        @test typeof(wv) <: SubArray{eltype(square),2}
        @test typeof(parent(wv)) <: InvWarpedView
        @test parent(parent(wv)).itp.coefs === square
        @test wv == imresize(square, (2,3))
        wv2 = @inferred AugmentorBase.applylazy(op, square)
        @test typeof(wv) == typeof(wv2)
        @test parent(parent(wv2)).itp.coefs === square
        @test wv2 == wv
    end
    let op = @inferred Either((Crop(1:2,1:2),Resize(2,3)), (1,0))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.toaffinemap(op, nothing)
        @test_throws MethodError AugmentorBase.toaffinemap(op, rect, 1)
        @test_throws MethodError AugmentorBase.applyaffine(op, AugmentorBase.prepareaffine(square))
        wv = @inferred AugmentorBase.applyaffineview(op, AugmentorBase.prepareaffine(square))
        @test typeof(wv) <: SubArray{eltype(square),2}
        @test typeof(parent(wv)) <: InvWarpedView
        @test parent(parent(wv)).itp.coefs === square
        @test wv == square[1:2,1:2]
        wv2 = @inferred AugmentorBase.applylazy(op, square)
        @test typeof(wv) == typeof(wv2)
        @test parent(parent(wv2)).itp.coefs === square
        @test wv2 == wv
    end
    let op = @inferred Either((Rotate90(),Rotate(45),Crop(1:2,1:2)))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === false
        res1, res2 = @inferred(AugmentorBase.applyaffineview(op, AugmentorBase.prepareaffine.((N0f8.(square), square))))
        @test res1 == res2
        @test typeof(res1) <: SubArray{N0f8,2,<:InvWarpedView}
        @test typeof(res2) <: SubArray{eltype(square),2,<:InvWarpedView}
    end
end

@testset "view" begin
    let op = @inferred Either((NoOp(),Crop(1:2,2:3)), (1,0))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === true
        @test AugmentorBase.supports_stepview(op) === true
        @test AugmentorBase.supports_permute(op) === false
        @test @inferred(AugmentorBase.applyview(op, rect)) === view(rect, IdentityRange(1:2), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applylazy(op, rect)) === view(rect, IdentityRange(1:2), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applyaffineview(op, AugmentorBase.prepareaffine(rect))) == view(AugmentorBase.prepareaffine(rect), IdentityRange(1:2), IdentityRange(1:3))
        res1, res2 = @inferred(AugmentorBase.applylazy(op, (square2, rect)))
        @test res1 === view(square2, IdentityRange(1:4), IdentityRange(1:4))
        @test res2 === view(rect, IdentityRange(1:2), IdentityRange(1:3))
    end
    let op = @inferred Either((NoOp(),Crop(1:2,2:3)), (0,1))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === true
        @test AugmentorBase.supports_stepview(op) === true
        @test AugmentorBase.supports_permute(op) === false
        @test @inferred(AugmentorBase.applyview(op, rect)) === view(rect, IdentityRange(1:2), IdentityRange(2:3))
        @test @inferred(AugmentorBase.applylazy(op, rect)) === view(rect, IdentityRange(1:2), IdentityRange(2:3))
        @test @inferred(AugmentorBase.applyaffineview(op, AugmentorBase.prepareaffine(rect))) == view(AugmentorBase.prepareaffine(rect), IdentityRange(1:2), IdentityRange(2:3))
    end
    let op = @inferred Either((Crop(1:2,2:4),CropSize(2,3)), (0,1))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === true
        @test AugmentorBase.supports_stepview(op) === true
        @test AugmentorBase.supports_permute(op) === false
        @test @inferred(AugmentorBase.applyview(op, rect)) === view(rect, IdentityRange(1:2), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applylazy(op, rect)) === view(rect, IdentityRange(1:2), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applyaffineview(op, AugmentorBase.prepareaffine(rect))) == view(AugmentorBase.prepareaffine(rect), IdentityRange(1:2), IdentityRange(1:3))
    end
    let op = @inferred Either((Crop(1:2,2:4),CropSize(2,3),CropRatio(1)))
        tres1, tres2 = @inferred(AugmentorBase.applylazy(op, (N0f8.(square2), square2)))
        res1, res2 = @inferred(AugmentorBase.applyview(op, (N0f8.(square2), square2)))
        @test typeof((tres1,tres2)) == typeof((res1,res2))
        @test res1 == res2
        @test typeof(res1) <: SubArray{N0f8,2,<:Array}
        @test typeof(res2) <: SubArray{eltype(square),2,<:Array}
        res1, res2 = @inferred(AugmentorBase.applyview(op, (N0f8.(square2), AugmentorBase.prepareaffine(square2))))
        @test res1 == res2
        @test typeof(res1) <: SubArray{N0f8,2,<:Array}
        @test typeof(res2) <: SubArray{eltype(square),2,<:InvWarpedView}
    end
end

@testset "stepview" begin
    let op = @inferred Either((Rotate180(),FlipX()), (1,0))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === true
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.applylazy(op, nothing)
        @test_throws MethodError AugmentorBase.applystepview(op, nothing)
        v = @inferred AugmentorBase.applylazy(op, rect)
        @test v === @inferred(AugmentorBase.applystepview(op, rect))
        @test v === view(rect,2:-1:1,3:-1:1)
        @test v == rot180(rect)
        @test typeof(v) <: SubArray
        res1, res2 = @inferred AugmentorBase.applystepview(op, (square2, rect))
        @test res1 === view(square2,4:-1:1,4:-1:1)
        @test res2 === view(rect,2:-1:1,3:-1:1)
    end
    let op = @inferred Either((Rotate180(),FlipX()), (0,1))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === true
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.applylazy(op, nothing)
        @test_throws MethodError AugmentorBase.applystepview(op, nothing)
        v = @inferred AugmentorBase.applylazy(op, rect)
        @test v === @inferred(AugmentorBase.applystepview(op, rect))
        @test v === view(rect,1:1:2,3:-1:1)
        @test v == reverse(rect, dims=2)
        @test typeof(v) <: SubArray
    end
    let op = @inferred Either((FlipY(),FlipX()), (1,0))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === true
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.applylazy(op, nothing)
        @test_throws MethodError AugmentorBase.applystepview(op, nothing)
        v = @inferred AugmentorBase.applylazy(op, rect)
        @test v === @inferred(AugmentorBase.applystepview(op, rect))
        @test v === view(rect,2:-1:1,1:1:3)
        @test v == reverse(rect, dims=1)
        @test typeof(v) <: SubArray
    end
    let op = @inferred Either((Rotate180(),NoOp()), (1,0))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === true
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.applylazy(op, nothing)
        @test_throws MethodError AugmentorBase.applystepview(op, nothing)
        v = @inferred AugmentorBase.applylazy(op, rect)
        @test v === @inferred(AugmentorBase.applystepview(op, rect))
        @test v === view(rect,2:-1:1,3:-1:1)
        @test v == rot180(rect)
        @test typeof(v) <: SubArray
    end
    let op = @inferred Either((Rotate180(),NoOp(),Crop(1:2,2:3)),(0,1,0))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === true
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.applylazy(op, nothing)
        @test_throws MethodError AugmentorBase.applystepview(op, nothing)
        v = @inferred AugmentorBase.applylazy(op, rect)
        @test v === @inferred(AugmentorBase.applystepview(op, rect))
        @test v === view(rect,1:1:2,1:1:3)
        @test v == rect
        @test typeof(v) <: SubArray
        wv = @inferred AugmentorBase.applylazy(op, AugmentorBase.prepareaffine(square))
        @test typeof(wv) <: SubArray{eltype(square),2}
        @test typeof(parent(wv)) <: InvWarpedView
        @test parent(parent(wv)).itp.coefs === square
        @test wv == square
    end
    let op = @inferred Either((Rotate180(),NoOp(),Crop(1:2,2:3)),(0,0,1))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === true
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.applylazy(op, nothing)
        @test_throws MethodError AugmentorBase.applystepview(op, nothing)
        v = @inferred AugmentorBase.applylazy(op, rect)
        @test v === @inferred(AugmentorBase.applystepview(op, rect))
        @test v === view(rect,1:1:2,2:1:3)
        @test typeof(v) <: SubArray
    end
    let op = @inferred Either((Rotate180(),CropSize(2,3)),(0,1))
        @test AugmentorBase.supports_affine(op) === false
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === true
        @test AugmentorBase.supports_permute(op) === false
        @test_throws MethodError AugmentorBase.applylazy(op, nothing)
        @test_throws MethodError AugmentorBase.applystepview(op, nothing)

        v = @inferred AugmentorBase.applylazy(op, square)
        @test v === @inferred(AugmentorBase.applystepview(op, square))
        @test v === AugmentorBase.applystepview(op, square)
        @test v === view(square,1:1:2,1:1:3)
        @test typeof(v) <: SubArray
    end
    let op = @inferred Either((Rotate180(),NoOp(),Crop(1:2,2:3)))
        tres1, tres2 = @inferred(AugmentorBase.applylazy(op, (N0f8.(square2), square2)))
        res1, res2 = @inferred(AugmentorBase.applystepview(op, (N0f8.(square2), square2)))
        @test typeof((tres1,tres2)) == typeof((res1,res2))
        @test res1 == res2
        @test typeof(res1) <: SubArray{N0f8,2,<:Array}
        @test typeof(res2) <: SubArray{eltype(square),2,<:Array}
        res1, res2 = @inferred(AugmentorBase.applystepview(op, (N0f8.(square2), AugmentorBase.prepareaffine(square2))))
        @test res1 == res2
        @test typeof(res1) <: SubArray{N0f8,2,<:Array}
        @test typeof(res2) <: SubArray{eltype(square),2,<:InvWarpedView}
    end
end

@testset "permute" begin
    let op = @inferred Either((Rotate90(),Rotate270()), (1,0))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === true
        @test_throws MethodError AugmentorBase.applylazy(op, nothing)
        @test_throws MethodError AugmentorBase.applypermute(op, nothing)
        v = @inferred AugmentorBase.applylazy(op, rect)
        @test v === @inferred(AugmentorBase.applypermute(op, rect))
        @test v === view(permuteddimsview(rect,(2,1)),3:-1:1,1:1:2)
        @test v == rotl90(rect)
        @test typeof(v) <: SubArray
        res1, res2 = @inferred AugmentorBase.applylazy(op, (square2, rect))
        @test res1 == rotl90(square2)
        @test res2 == rotl90(rect)
    end
    let op = @inferred Either((Rotate90(),Rotate270()), (0,1))
        @test AugmentorBase.supports_affine(op) === true
        @test AugmentorBase.supports_lazy(op) === true
        @test AugmentorBase.supports_affineview(op) === true
        @test AugmentorBase.supports_view(op) === false
        @test AugmentorBase.supports_stepview(op) === false
        @test AugmentorBase.supports_permute(op) === true
        @test_throws MethodError AugmentorBase.applylazy(op, nothing)
        @test_throws MethodError AugmentorBase.applypermute(op, nothing)
        v = @inferred AugmentorBase.applylazy(op, rect)
        @test v === @inferred(AugmentorBase.applypermute(op, rect))
        @test v === view(permuteddimsview(rect,(2,1)),1:1:3,2:-1:1)
        @test v == rotr90(rect)
        @test typeof(v) <: SubArray
    end
    let op = @inferred Either((Rotate90(),Rotate270()))
        tres1, tres2 = @inferred(AugmentorBase.applylazy(op, (N0f8.(square2), square2)))
        res1, res2 = @inferred(AugmentorBase.applypermute(op, (N0f8.(square2), square2)))
        @test typeof((tres1,tres2)) == typeof((res1,res2))
        @test res1 == res2
        @test typeof(res1) <: SubArray{N0f8,2,<:PermutedDimsArray}
        @test typeof(res2) <: SubArray{eltype(square),2,<:PermutedDimsArray}
        res1, res2 = @inferred(AugmentorBase.applypermute(op, (N0f8.(square2), AugmentorBase.prepareaffine(square2))))
        @test res1 == res2
        @test typeof(res1) <: SubArray{N0f8,2,<:PermutedDimsArray}
        @test typeof(res2) <: SubArray{eltype(square),2,<:PermutedDimsArray}
        @test typeof(parent(parent(res2))) <: InvWarpedView
    end
end
