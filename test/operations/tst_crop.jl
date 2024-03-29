@testset "Crop" begin
    @test (Crop <: AugmentorBase.AffineOperation) == false
    @testset "constructor" begin
        @test_throws MethodError Crop()
        @test_throws MethodError Crop(())
        @test typeof(@inferred(Crop(1:10))) <: Crop{1} <: Crop <: AugmentorBase.ArrayOperation
        @test typeof(@inferred(Crop(1:10,3:5))) <: Crop{2} <: Crop <: AugmentorBase.ArrayOperation
        @test @inferred(Crop(Base.OneTo(10), Base.OneTo(5))) === @inferred(Crop((1:10,1:5)))
        @test @inferred(Crop(Base.OneTo(10), 1:5)) === @inferred(Crop((1:10,1:5)))
        @test str_show(Crop(3:4)) == "AugmentorBase.Crop{1}((3:4,))"
        @test str_showconst(Crop(3:4)) == "Crop(3:4)"
        @test str_showcompact(Crop(3:4)) == "Crop region (3:4,)"
        @test str_show(Crop(1:2,2:3)) == "AugmentorBase.Crop{2}((1:2, 2:3))"
        @test str_showconst(Crop(1:2,2:3)) == "Crop(1:2, 2:3)"
        @test str_showcompact(Crop(1:2,2:3)) == "Crop region 1:2×2:3"
        @test str_show(Crop(1:2,2:3,3:4)) == "AugmentorBase.Crop{3}((1:2, 2:3, 3:4))"
        @test str_showconst(Crop(1:2,2:3,3:4)) == "Crop(1:2, 2:3, 3:4)"
        @test str_showcompact(Crop(1:2,2:3,3:4)) == "Crop region (1:2, 2:3, 3:4)"
    end
    @testset "eager" begin
        @test_throws MethodError AugmentorBase.applyeager(Crop(1:10), nothing)
        @test_throws MethodError AugmentorBase.applyeager(Crop(1:2,2:3), nothing)
        @test AugmentorBase.supports_eager(Crop) === false
        imgs = [
            (rect, (1:2, 2:3)),
            (AugmentorBase.prepareaffine(rect), (1:2, 2:3)),
            (OffsetArray(rect, -2, -1), (-1:0, 1:2)),
            (view(rect, IdentityRange(1:2), IdentityRange(1:3)), (1:2, 2:3)),
        ]
        @testset "single image" begin
            for (img_in, inds) in imgs
                res = @inferred(AugmentorBase.applyeager(Crop(1:2,2:3), img_in))
                @test collect(res) == rect[1:2, 2:3]
                @test axes(res) == inds
                @test typeof(res) <: OffsetArray{eltype(img_in),2}
            end
        end
        @testset "multiple images" begin
            for (img_in1, inds1) in imgs, (img_in2, inds2) in imgs
                img_in = (img_in1, img_in2)
                inds = (inds1, inds2)
                res = @inferred(AugmentorBase.applyeager(Crop(1:2,2:3), img_in))
                @test collect.(res) == ntuple(i->rect[1:2, 2:3],2)
                @test typeof(res) <: NTuple{2,OffsetArray{eltype(img_in1),2}}
            end
        end
    end
    @testset "affine" begin
        @test AugmentorBase.supports_affine(Crop) === false
    end
    imgs = [
        (rect),
        (AugmentorBase.prepareaffine(rect)),
        (OffsetArray(rect, -2, -1)),
        (view(rect, IdentityRange(1:2), IdentityRange(1:3))),
    ]
    @testset "affineview" begin
        @test AugmentorBase.supports_affineview(Crop) === true
        @test_throws MethodError AugmentorBase.applyaffineview(Crop(1:2,2:3), nothing)
        @test @inferred(AugmentorBase.applyaffineview(Crop(1:2,2:3), rect)) ==
            view(AugmentorBase.prepareaffine(rect), IdentityRange(1:2), IdentityRange(2:3))
        @testset "multiple images" begin
            for img_in in imgs
                res1, res2 = @inferred(AugmentorBase.applyaffineview(Crop(1:2,2:3), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
                @test typeof(parent(res1)) <: InvWarpedView
                @test typeof(parent(res2)) <: InvWarpedView
            end
        end
    end
    @testset "lazy" begin
        @test AugmentorBase.supports_lazy(Crop) === true
        @test @inferred(AugmentorBase.applylazy(Crop(1:2,2:3), rect)) ===
            view(rect, IdentityRange(1:2), IdentityRange(2:3))
        @testset "multiple images" begin
            for img_in in imgs
                res1, res2 = @inferred(AugmentorBase.applylazy(Crop(1:2,2:3), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
            end
        end
    end
    @testset "view" begin
        @test AugmentorBase.supports_view(Crop) === true
        @test @inferred(AugmentorBase.applyview(Crop(1:2,2:3), rect)) ===
            view(rect, IdentityRange(1:2), IdentityRange(2:3))
        @testset "multiple images" begin
            for img_in in imgs
                res1, res2 = @inferred(AugmentorBase.applyview(Crop(1:2,2:3), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
            end
        end
    end
    @testset "stepview" begin
        @test AugmentorBase.supports_stepview(Crop) === true
        @test @inferred(AugmentorBase.applystepview(Crop(1:2,2:3), rect)) === view(rect, 1:1:2, 2:1:3)
        @testset "multiple images" begin
            for img_in in imgs
                res1, res2 = @inferred(AugmentorBase.applystepview(Crop(1:2,2:3), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
            end
        end
    end
    @testset "permute" begin
        @test AugmentorBase.supports_permute(Crop) === false
    end
end

# --------------------------------------------------------------------

@testset "CropNative" begin
    @test (CropNative <: AugmentorBase.AffineOperation) == false
    @testset "constructor" begin
        @test_throws MethodError CropNative()
        @test_throws MethodError CropNative(())
        @test typeof(@inferred(CropNative(1:10))) <: CropNative{1} <: CropNative <: AugmentorBase.ArrayOperation
        @test typeof(@inferred(CropNative(1:10,3:5))) <: CropNative{2} <: CropNative <: AugmentorBase.ArrayOperation
        @test @inferred(CropNative(Base.OneTo(10), Base.OneTo(5))) === @inferred(CropNative((1:10,1:5)))
        @test @inferred(CropNative(Base.OneTo(10), 1:5)) === @inferred(CropNative((1:10,1:5)))
        @test str_show(CropNative(3:4)) == "AugmentorBase.CropNative{1}((3:4,))"
        @test str_showconst(CropNative(3:4)) == "CropNative(3:4)"
        @test str_showcompact(CropNative(3:4)) == "Crop native region (3:4,)"
        @test str_show(CropNative(1:2,2:3)) == "AugmentorBase.CropNative{2}((1:2, 2:3))"
        @test str_showconst(CropNative(1:2,2:3)) == "CropNative(1:2, 2:3)"
        @test str_showcompact(CropNative(1:2,2:3)) == "Crop native region 1:2×2:3"
        @test str_show(CropNative(1:2,2:3,3:4)) == "AugmentorBase.CropNative{3}((1:2, 2:3, 3:4))"
        @test str_showconst(CropNative(1:2,2:3,3:4)) == "CropNative(1:2, 2:3, 3:4)"
        @test str_showcompact(CropNative(1:2,2:3,3:4)) == "Crop native region (1:2, 2:3, 3:4)"
    end
    imgs = [
        (rect, (1:2, 2:3)),
        (AugmentorBase.prepareaffine(rect), (1:2, 2:3)),
        (OffsetArray(rect, -2, -1), (-1:0, 1:2)),
        (view(rect, IdentityRange(1:2), IdentityRange(1:3)), (1:2, 2:3)),
    ]
    @testset "eager" begin
        @test_throws MethodError AugmentorBase.applyeager(CropNative(1:10), nothing)
        @test_throws MethodError AugmentorBase.applyeager(CropNative(1:2,2:3), nothing)
        @test AugmentorBase.supports_eager(CropNative) === false
        @testset "single image" begin
            for (img_in, inds) in imgs
                res = @inferred(AugmentorBase.applyeager(CropNative(inds), img_in))
                @test collect(res) == rect[1:2, 2:3]
                @test axes(res) == inds
                @test typeof(res) <: OffsetArray{eltype(img_in),2}
            end
        end
        img = OffsetArray(rect, -2, -1)
        @test collect(@inferred(AugmentorBase.applyeager(CropNative(-1:0,1:2), img))) == rect[1:2, 2:3]
        @test typeof(AugmentorBase.applyeager(CropNative(-1:0,1:2), img)) <: OffsetArray
    end
    @testset "affine" begin
        @test AugmentorBase.supports_affine(CropNative) === false
    end
    @testset "affineview" begin
        @test AugmentorBase.supports_affineview(CropNative) === true
        @test_throws MethodError AugmentorBase.applyaffineview(CropNative(1:2,2:3), nothing)
        @test @inferred(AugmentorBase.applyaffineview(CropNative(1:2,2:3), rect)) ==
            view(AugmentorBase.prepareaffine(rect), IdentityRange(1:2), IdentityRange(2:3))
        @testset "multiple images" begin
            for (img_in, inds) in imgs
                res1, res2 = @inferred(AugmentorBase.applyaffineview(CropNative(inds), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
                @test typeof(parent(res1)) <: InvWarpedView
                @test typeof(parent(res2)) <: InvWarpedView
            end
        end
    end
    @testset "lazy" begin
        @test AugmentorBase.supports_lazy(CropNative) === true
        @test @inferred(AugmentorBase.applylazy(CropNative(1:2,2:3), rect)) ===
            view(rect, IdentityRange(1:2), IdentityRange(2:3))
        @testset "multiple images" begin
            for (img_in, inds) in imgs
                res1, res2 = @inferred(AugmentorBase.applylazy(CropNative(inds), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
            end
        end
    end
    @testset "view" begin
        @test AugmentorBase.supports_view(CropNative) === true
        @test @inferred(AugmentorBase.applyview(CropNative(1:2,2:3), rect)) ===
            view(rect, IdentityRange(1:2), IdentityRange(2:3))
        @testset "multiple images" begin
            for (img_in, inds) in imgs
                res1, res2 = @inferred(AugmentorBase.applyview(CropNative(inds), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
            end
        end
    end
    @testset "stepview" begin
        @test AugmentorBase.supports_stepview(CropNative) === true
        @test @inferred(AugmentorBase.applystepview(CropNative(1:2,2:3), rect)) === view(rect, 1:1:2, 2:1:3)
        # TODO: fix behaviour for stepview on IdentityRange
        @testset "multiple images" begin
           for (img_in, inds) in imgs[1:3]
               res1, res2 = @inferred(AugmentorBase.applystepview(CropNative(inds), (img_in, N0f8.(img_in))))
               # make sure both images are processed
               @test res1 == res2
               @test typeof(res1) <: SubArray{Gray{N0f8}}
               @test typeof(res2) <: SubArray{N0f8}
           end
        end
    end
    @testset "permute" begin
        @test AugmentorBase.supports_permute(CropNative) === false
    end
end

# --------------------------------------------------------------------

@testset "CropSize" begin
    @test (CropSize <: AugmentorBase.AffineOperation) == false
    @test typeof(@inferred(CropSize())) <: CropSize <: AugmentorBase.ArrayOperation
    @testset "constructor" begin
        @test_throws MethodError CropSize(())
        @test_throws MethodError CropSize(1.,2.)
        @test_throws MethodError CropSize(:a)
        @test_throws MethodError CropSize([:a])
        @test_throws ArgumentError CropSize(-1)
        @test_throws ArgumentError CropSize(0,2)
        op = @inferred(CropSize(10))
        @test str_show(op) == "AugmentorBase.CropSize{1}((10,))"
        @test str_showconst(op) == "CropSize(10)"
        @test str_showcompact(op) == "Crop a 10-length window at the center"
        op = @inferred(CropSize(20,30))
        @test op === CropSize(width=30, height=20)
        @test op.size == (20,30)
        @test str_show(op) == "AugmentorBase.CropSize{2}((20, 30))"
        @test str_showconst(op) == "CropSize(20, 30)"
        @test str_showcompact(op) == "Crop a 20×30 window around the center"
        op = @inferred(CropSize(20,30,40))
        @test op === @inferred(CropSize((20,30,40)))
        @test op === @inferred(CropSize{3}((20,30,40)))
        @test op.size == (20,30,40)
        @test str_show(op) == "AugmentorBase.CropSize{3}((20, 30, 40))"
        @test str_showconst(op) == "CropSize(20, 30, 40)"
        @test str_showcompact(op) == "Crop a 20×30×40 window around the center"
    end
    @testset "cropsize_axes" begin
        @test @inferred(AugmentorBase.cropsize_axes(CropSize(2,2), square)) == [1:2, 1:2]
        @test @inferred(AugmentorBase.cropsize_axes(CropSize(2,2), square2)) == [2:3, 2:3]
        @test @inferred(AugmentorBase.cropsize_axes(CropSize(2,2), checkers)) == [1:2, 2:3]
        @test @inferred(AugmentorBase.cropsize_axes(CropSize(1,3), checkers)) == [2:2, 2:4]
        @test @inferred(AugmentorBase.cropsize_axes(CropSize(3,3), checkers)) == [1:3, 2:4]
        @test @inferred(AugmentorBase.cropsize_axes(CropSize(2,2), OffsetArray(rect, -2, -1))) == [-1:0, 0:1]
    end
    imgs = [
        (rect, (1:2, 1:2)),
        (AugmentorBase.prepareaffine(rect), (1:2, 1:2)),
        (OffsetArray(rect, -2, -1), (-1:0, 0:1)),
        (view(rect, IdentityRange(1:2), IdentityRange(1:3)), (1:2, 1:2)),
        (square2, (2:3, 2:3)),
        (AugmentorBase.prepareaffine(square2), (2:3, 2:3)),
        (OffsetArray(square2, -2, -1), (0:1, 1:2)),
        (view(square2, IdentityRange(1:4), IdentityRange(1:4)), (2:3, 2:3)),
    ]
    @testset "eager" begin
        @test_throws MethodError AugmentorBase.applyeager(CropSize(10), nothing)
        @test_throws MethodError AugmentorBase.applyeager(CropSize(2,3), nothing)
        @test AugmentorBase.supports_eager(CropSize) === false
        @test @inferred(AugmentorBase.applyeager(CropSize(4,4), square2)) == square2
        @testset "single image" begin
            for (img_in, inds) in imgs
                res = @inferred(AugmentorBase.applyeager(CropSize(2,2), img_in))
                @test collect(res) == img_in[inds...]
                @test axes(res) == inds
                @test typeof(res) <: OffsetArray{eltype(img_in),2}
            end
        end
        @testset "multiple images" begin
            for (img_in1, inds1) in imgs, (img_in2, inds2) in imgs
                img_in = (img_in1, img_in2)
                inds = (inds1, inds2)
                res = @inferred(AugmentorBase.applyeager(CropSize(2,2), img_in))
                @test collect.(res) == ntuple(i->img_in[i][inds[i]...],2)
                @test typeof(res) <: NTuple{2,OffsetArray{eltype(img_in1),2}}
            end
        end
    end
    @testset "affine" begin
        @test AugmentorBase.supports_affine(CropSize) === false
    end
    @testset "affineview" begin
        @test AugmentorBase.supports_affineview(CropSize) === true
        @test_throws MethodError AugmentorBase.applyaffineview(CropSize(1:2,2:3), nothing)
        @test @inferred(AugmentorBase.applyaffineview(CropSize(2,3), rect)) ==
            view(AugmentorBase.prepareaffine(rect), IdentityRange(1:2), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applyaffineview(CropSize(2,2), square2)) ==
            view(AugmentorBase.prepareaffine(square2), IdentityRange(2:3), IdentityRange(2:3))
        @testset "multiple images" begin
            for (img_in, inds) in imgs
                res1, res2 = @inferred(AugmentorBase.applyaffineview(CropSize(2,2), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test axes(res1) == inds
                @test axes(res2) == inds
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
                @test typeof(parent(res1)) <: InvWarpedView
                @test typeof(parent(res2)) <: InvWarpedView
            end
        end
    end
    @testset "lazy" begin
        @test AugmentorBase.supports_lazy(CropSize) === true
        @test @inferred(AugmentorBase.applylazy(CropSize(2,3), rect)) ===
            view(rect, IdentityRange(1:2), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applylazy(CropSize(2,2), square2)) ===
            view(square2, IdentityRange(2:3), IdentityRange(2:3))
        @testset "multiple images" begin
            for (img_in, inds) in imgs
                res1, res2 = @inferred(AugmentorBase.applylazy(CropSize(2,2), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test axes(res1) == inds
                @test axes(res2) == inds
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
            end
        end
    end
    @testset "view" begin
        @test AugmentorBase.supports_view(CropSize) === true
        @test @inferred(AugmentorBase.applyview(CropSize(2,3), rect)) ===
            view(rect, IdentityRange(1:2), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applyview(CropSize(2,2), square2)) ===
            view(square2, IdentityRange(2:3), IdentityRange(2:3))
        @testset "multiple images" begin
            for (img_in, inds) in imgs
                res1, res2 = @inferred(AugmentorBase.applyview(CropSize(2,2), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test axes(res1) == inds
                @test axes(res2) == inds
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
            end
        end
    end
    @testset "stepview" begin
        @test AugmentorBase.supports_stepview(CropSize) === true
        @test @inferred(AugmentorBase.applystepview(CropSize(2,3), rect)) === view(rect, 1:1:2, 1:1:3)
        @test @inferred(AugmentorBase.applystepview(CropSize(2,2), square2)) === view(square2, 2:1:3, 2:1:3)
    end
    @testset "permute" begin
        @test AugmentorBase.supports_permute(CropSize) === false
    end
end

# --------------------------------------------------------------------

@testset "CropRatio" begin
    @test (CropRatio <: AugmentorBase.AffineOperation) == false
    @test typeof(@inferred(CropRatio())) <: CropRatio <: AugmentorBase.ArrayOperation
    @testset "constructor" begin
        @test_throws MethodError CropRatio(())
        @test_throws MethodError CropRatio(1.,2.)
        @test_throws MethodError CropRatio(:a)
        @test_throws MethodError CropRatio([:a])
        @test_throws ArgumentError CropRatio(-1)
        @test_throws ArgumentError CropRatio(0)
        op = @inferred(CropRatio(3/4))
        @test op === CropRatio(ratio=3/4)
        @test str_show(op) == "AugmentorBase.CropRatio(0.75)"
        @test str_showconst(op) == "CropRatio(0.75)"
        @test str_showcompact(op) == "Crop to 3:4 aspect ratio"
        op = @inferred(CropRatio(1))
        @test op === @inferred(CropRatio())
        @test op === CropRatio(ratio=1)
        @test str_show(op) == "AugmentorBase.CropRatio(1.0)"
        @test str_showconst(op) == "CropRatio(1.0)"
        @test str_showcompact(op) == "Crop to 1:1 aspect ratio"
        op = @inferred(CropRatio(2.5))
        @test op === CropRatio(ratio=2.5)
        @test str_show(op) == "AugmentorBase.CropRatio(2.5)"
        @test str_showconst(op) == "CropRatio(2.5)"
        @test str_showcompact(op) == "Crop to 5:2 aspect ratio"
        op = @inferred(CropRatio(sqrt(2)))
        @test str_showcompact(op) == "Crop to 1.41 aspect ratio"
    end
    @testset "cropratio_axes" begin
        @test @inferred(AugmentorBase.cropratio_axes(CropRatio(1), square)) == UnitRange{Int64}[1:3, 1:3]
        @test @inferred(AugmentorBase.cropratio_axes(CropRatio(2), square)) == UnitRange{Int64}[2:2, 1:3]
        @test @inferred(AugmentorBase.cropratio_axes(CropRatio(1), square2)) == UnitRange{Int64}[1:4, 1:4]
        @test @inferred(AugmentorBase.cropratio_axes(CropRatio(1), rect)) == UnitRange{Int64}[1:2, 1:2]
        @test @inferred(AugmentorBase.cropratio_axes(CropRatio(1), checkers)) == UnitRange{Int64}[1:3, 2:4]
        @test @inferred(AugmentorBase.cropratio_axes(CropRatio(1), rotl90(checkers))) == UnitRange{Int64}[2:4, 1:3]
        @test @inferred(AugmentorBase.cropratio_axes(CropRatio(1), OffsetArray(rect, -2, -1))) == UnitRange{Int64}[-1:0, 0:1]
    end
    imgs = [
        (rect, (1:2, 1:2)),
        (AugmentorBase.prepareaffine(rect), (1:2, 1:2)),
        (OffsetArray(rect, -2, -1), (-1:0, 0:1)),
        (view(rect, IdentityRange(1:2), IdentityRange(1:3)), (1:2, 1:2)),
        (checkers, (1:3, 2:4)),
        (AugmentorBase.prepareaffine(square2), (1:4, 1:4)),
        (OffsetArray(square2, -2, -1), (-1:2, 0:3)),
        (view(checkers, IdentityRange(1:3), IdentityRange(1:5)), (1:3, 2:4)),
    ]
    @testset "eager" begin
        @test_throws MethodError AugmentorBase.applyeager(CropRatio(10), nothing)
        @test_throws MethodError AugmentorBase.applyeager(CropRatio(2), nothing)
        @test AugmentorBase.supports_eager(CropRatio) === false
        @test @inferred(AugmentorBase.applyeager(CropRatio(1), rect)) == rect[1:2,1:2]
        @test @inferred(AugmentorBase.applyeager(CropRatio(1), square)) == square
        @test @inferred(AugmentorBase.applyeager(CropRatio(1), square2)) == square2
        @testset "single image" begin
            for (img_in, inds) in imgs
                res = @inferred(AugmentorBase.applyeager(CropRatio(1), img_in))
                @test collect(res) == img_in[inds...]
                @test axes(res) == inds
                @test typeof(res) <: OffsetArray{eltype(img_in),2}
            end
        end
        @testset "multiple images" begin
            for (img_in1, inds1) in imgs, (img_in2, inds2) in imgs
                img_in = (img_in1, img_in2)
                inds = (inds1, inds2)
                res = @inferred(AugmentorBase.applyeager(CropRatio(1), img_in))
                @test collect.(res) == ntuple(i->img_in[i][inds[i]...],2)
                @test typeof(res) <: NTuple{2,OffsetArray{eltype(img_in1),2}}
            end
        end
    end
    @testset "affine" begin
        @test AugmentorBase.supports_affine(CropRatio) === false
    end
    @testset "affineview" begin
        @test AugmentorBase.supports_affineview(CropRatio) === true
        @test_throws MethodError AugmentorBase.applyaffineview(CropRatio(1), nothing)
        @test @inferred(AugmentorBase.applyaffineview(CropRatio(1), rect)) ==
            view(AugmentorBase.prepareaffine(rect), IdentityRange(1:2), IdentityRange(1:2))
        @test @inferred(AugmentorBase.applyaffineview(CropRatio(2), square2)) ==
            view(AugmentorBase.prepareaffine(square2), IdentityRange(2:3), IdentityRange(1:4))
        @test @inferred(AugmentorBase.applyaffineview(CropRatio(.5), square2)) ==
            view(AugmentorBase.prepareaffine(square2), IdentityRange(1:4), IdentityRange(2:3))
        @testset "multiple images" begin
            for (img_in, inds) in imgs
                res1, res2 = @inferred(AugmentorBase.applyaffineview(CropRatio(1), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test axes(res1) == inds
                @test axes(res2) == inds
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
                @test typeof(parent(res1)) <: InvWarpedView
                @test typeof(parent(res2)) <: InvWarpedView
            end
        end
    end
    @testset "lazy" begin
        @test AugmentorBase.supports_lazy(CropRatio) === true
        @test @inferred(AugmentorBase.applylazy(CropRatio(1), rect)) ===
            view(rect, IdentityRange(1:2), IdentityRange(1:2))
        @test @inferred(AugmentorBase.applylazy(CropRatio(2), square2)) ===
            view(square2, IdentityRange(2:3), IdentityRange(1:4))
        @test @inferred(AugmentorBase.applylazy(CropRatio(.5), square2)) ===
            view(square2, IdentityRange(1:4), IdentityRange(2:3))
        @testset "multiple images" begin
            for (img_in, inds) in imgs
                res1, res2 = @inferred(AugmentorBase.applylazy(CropRatio(1), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test axes(res1) == inds
                @test axes(res2) == inds
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
            end
        end
    end
    @testset "view" begin
        @test AugmentorBase.supports_view(CropRatio) === true
        @test @inferred(AugmentorBase.applyview(CropRatio(1), rect)) ===
            view(rect, IdentityRange(1:2), IdentityRange(1:2))
        @test @inferred(AugmentorBase.applyview(CropRatio(2), square2)) ===
            view(square2, IdentityRange(2:3), IdentityRange(1:4))
        @test @inferred(AugmentorBase.applyview(CropRatio(.5), square2)) ===
            view(square2, IdentityRange(1:4), IdentityRange(2:3))
        @testset "multiple images" begin
            for (img_in, inds) in imgs
                res1, res2 = @inferred(AugmentorBase.applyview(CropRatio(1), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test axes(res1) == inds
                @test axes(res2) == inds
                @test typeof(res1) <: SubArray{Gray{N0f8}}
                @test typeof(res2) <: SubArray{N0f8}
            end
        end
    end
    @testset "stepview" begin
        @test AugmentorBase.supports_stepview(CropRatio) === true
        @test @inferred(AugmentorBase.applystepview(CropRatio(1), rect)) === view(rect, 1:1:2, 1:1:2)
        @test @inferred(AugmentorBase.applystepview(CropRatio(2), square2)) === view(square2, 2:1:3, 1:1:4)
        @test @inferred(AugmentorBase.applystepview(CropRatio(.5), square2)) === view(square2, 1:1:4, 2:1:3)
    end
    @testset "permute" begin
        @test AugmentorBase.supports_permute(CropRatio) === false
    end
end

# --------------------------------------------------------------------

@testset "RCropRatio" begin
    @test (RCropRatio <: AugmentorBase.AffineOperation) == false
    @test typeof(@inferred(RCropRatio())) <: RCropRatio <: AugmentorBase.ArrayOperation
    @testset "constructor" begin
        @test_throws MethodError RCropRatio(())
        @test_throws MethodError RCropRatio(1.,2.)
        @test_throws MethodError RCropRatio(:a)
        @test_throws MethodError RCropRatio([:a])
        @test_throws ArgumentError RCropRatio(-1)
        @test_throws ArgumentError RCropRatio(0)
        op = @inferred(RCropRatio(3/4))
        @test op === RCropRatio(ratio=3/4)
        @test str_show(op) == "AugmentorBase.RCropRatio(0.75)"
        @test str_showconst(op) == "RCropRatio(0.75)"
        @test str_showcompact(op) == "Crop random window with 3:4 aspect ratio"
        op = @inferred(RCropRatio(1))
        @test op === @inferred(RCropRatio())
        @test op === RCropRatio(ratio=1)
        @test str_show(op) == "AugmentorBase.RCropRatio(1.0)"
        @test str_showconst(op) == "RCropRatio(1.0)"
        @test str_showcompact(op) == "Crop random window with 1:1 aspect ratio"
        op = @inferred(RCropRatio(2.5))
        @test op === RCropRatio(ratio=2.5)
        @test str_show(op) == "AugmentorBase.RCropRatio(2.5)"
        @test str_showconst(op) == "RCropRatio(2.5)"
        @test str_showcompact(op) == "Crop random window with 5:2 aspect ratio"
        op = @inferred(RCropRatio(sqrt(2)))
        @test str_showcompact(op) == "Crop random window with 1.41 aspect ratio"
    end
    @testset "randparam" begin
        @test @inferred(AugmentorBase.randparam(RCropRatio(1), square)) == (1:3, 1:3)
        @test @inferred(AugmentorBase.randparam(RCropRatio(1), rect)) in ((1:2, 2:3), (1:2, 1:2))
        @test @inferred(AugmentorBase.randparam(RCropRatio(1), (rect,square2))) in ((1:2, 2:3), (1:2, 1:2))
    end
    imgs = [
        (rect, (1:2, 1:3)),
        (AugmentorBase.prepareaffine(rect), (1:2, 1:3)),
        (OffsetArray(rect, -2, -1), (-1:0, 0:2)),
        (view(rect, IdentityRange(1:2), IdentityRange(1:3)), (1:2, 1:3)),
    ]
    @testset "eager" begin
        @test_throws MethodError AugmentorBase.applyeager(RCropRatio(10), nothing)
        @test_throws MethodError AugmentorBase.applyeager(RCropRatio(2), nothing)
        @test AugmentorBase.supports_eager(RCropRatio) === false
        @test @inferred(AugmentorBase.applyeager(RCropRatio(1), square)) == square
        @test @inferred(AugmentorBase.applyeager(RCropRatio(1), square2)) == square2
        out = collect(@inferred(AugmentorBase.applyeager(RCropRatio(1), rect)))
        @test out == rect[1:2,1:2] || out == rect[1:2,2:3]
        @testset "single image" begin
            for (img_in, inds) in imgs
                res = @inferred(AugmentorBase.applyeager(RCropRatio(3/2), img_in))
                @test collect(res) == img_in[inds...]
                @test axes(res) == inds
                @test typeof(res) <: OffsetArray{eltype(img_in),2}
            end
        end
        @testset "multiple images" begin
            for (img_in, _) in imgs
                res1, res2 = @inferred(AugmentorBase.applyeager(RCropRatio(1), (img_in, N0f8.(img_in))))
                # make sure both images are processed
                @test res1 == res2
                @test axes(res1) == axes(res2)
                @test typeof(res1) <: OffsetArray{Gray{N0f8}}
                @test typeof(res2) <: OffsetArray{N0f8}
            end
        end
    end
    @testset "affine" begin
        @test AugmentorBase.supports_affine(RCropRatio) === false
    end
    @testset "affineview" begin
        @test AugmentorBase.supports_affineview(RCropRatio) === true
        @test_throws MethodError AugmentorBase.applyaffineview(RCropRatio(1), nothing)
        # preserve aspect ratio (i.e. not random)
        @test @inferred(AugmentorBase.applyaffineview(RCropRatio(3/2), rect)) ==
            view(AugmentorBase.prepareaffine(rect), IdentityRange(1:2), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applyaffineview(RCropRatio(1), square)) ==
            view(AugmentorBase.prepareaffine(square), IdentityRange(1:3), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applyaffineview(RCropRatio(1), square2)) ==
            view(AugmentorBase.prepareaffine(square2), IdentityRange(1:4), IdentityRange(1:4))
        # randomly placed
        out = @inferred AugmentorBase.applyaffineview(RCropRatio(1), rect)
        @test out == view(AugmentorBase.prepareaffine(rect), IdentityRange(1:2), IdentityRange(1:2)) ||
            out == view(AugmentorBase.prepareaffine(rect), IdentityRange(1:2), IdentityRange(2:3))
        out = @inferred AugmentorBase.applyaffineview(RCropRatio(2/3), square)
        @test out == view(AugmentorBase.prepareaffine(square), IdentityRange(1:3), IdentityRange(1:2)) ||
            out == view(AugmentorBase.prepareaffine(square), IdentityRange(1:3), IdentityRange(2:3))
        out = @inferred AugmentorBase.applyaffineview(RCropRatio(3/2), square)
        @test out == view(AugmentorBase.prepareaffine(square), IdentityRange(1:2), IdentityRange(1:3)) ||
            out == view(AugmentorBase.prepareaffine(square), IdentityRange(2:3), IdentityRange(1:3))
    end
    @testset "lazy" begin
        @test AugmentorBase.supports_lazy(RCropRatio) === true
        # preserve aspect ratio (i.e. not random)
        @test @inferred(AugmentorBase.applylazy(RCropRatio(3/2), rect)) ===
            view(rect, IdentityRange(1:2), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applylazy(RCropRatio(1), square)) ===
            view(square, IdentityRange(1:3), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applylazy(RCropRatio(1), square2)) ===
            view(square2, IdentityRange(1:4), IdentityRange(1:4))
        # randomly placed
        out = @inferred AugmentorBase.applylazy(RCropRatio(1), rect)
        @test out === view(rect, IdentityRange(1:2), IdentityRange(1:2)) || out ===
            view(rect, IdentityRange(1:2), IdentityRange(2:3))
        out = @inferred AugmentorBase.applylazy(RCropRatio(2/3), square)
        @test out === view(square, IdentityRange(1:3), IdentityRange(1:2)) || out ===
            view(square, IdentityRange(1:3), IdentityRange(2:3))
        out = @inferred AugmentorBase.applylazy(RCropRatio(3/2), square)
        @test out === view(square, IdentityRange(1:2), IdentityRange(1:3)) || out ===
            view(square, IdentityRange(2:3), IdentityRange(1:3))
    end
    @testset "view" begin
        @test AugmentorBase.supports_view(RCropRatio) === true
        # preserve aspect ratio (i.e. not random)
        @test @inferred(AugmentorBase.applyview(RCropRatio(3/2), rect)) ===
            view(rect, IdentityRange(1:2), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applyview(RCropRatio(1), square)) ===
            view(square, IdentityRange(1:3), IdentityRange(1:3))
        @test @inferred(AugmentorBase.applyview(RCropRatio(1), square2)) ===
            view(square2, IdentityRange(1:4), IdentityRange(1:4))
        # randomly placed
        out = @inferred AugmentorBase.applyview(RCropRatio(1), rect)
        @test out === view(rect, IdentityRange(1:2), IdentityRange(1:2)) || out ===
            view(rect, IdentityRange(1:2), IdentityRange(2:3))
        out = @inferred AugmentorBase.applyview(RCropRatio(2/3), square)
        @test out === view(square, IdentityRange(1:3), IdentityRange(1:2)) || out ===
            view(square, IdentityRange(1:3), IdentityRange(2:3))
        out = @inferred AugmentorBase.applyview(RCropRatio(3/2), square)
        @test out === view(square, IdentityRange(1:2), IdentityRange(1:3)) || out ===
            view(square, IdentityRange(2:3), IdentityRange(1:3))
    end
    @testset "stepview" begin
        @test AugmentorBase.supports_stepview(RCropRatio) === true
        # preserve aspect ratio (i.e. not random)
        @test @inferred(AugmentorBase.applystepview(RCropRatio(3/2), rect)) === view(rect, 1:1:2, 1:1:3)
        @test @inferred(AugmentorBase.applystepview(RCropRatio(1), square)) === view(square, 1:1:3, 1:1:3)
        @test @inferred(AugmentorBase.applystepview(RCropRatio(1), square2)) === view(square2, 1:1:4, 1:1:4)
        # randomly placed
        out = @inferred AugmentorBase.applystepview(RCropRatio(1), rect)
        @test out === view(rect, 1:1:2, 1:1:2) || out === view(rect, 1:1:2, 2:1:3)
        out = @inferred AugmentorBase.applystepview(RCropRatio(2/3), square)
        @test out === view(square, 1:1:3, 1:1:2) || out === view(square, 1:1:3, 2:1:3)
        out = @inferred AugmentorBase.applystepview(RCropRatio(3/2), square)
        @test out === view(square, 1:1:2, 1:1:3) || out === view(square, 2:1:3, 1:1:3)
    end
    @testset "permute" begin
        @test @inferred(AugmentorBase.supports_permute(RCropRatio)) === false
    end
end
