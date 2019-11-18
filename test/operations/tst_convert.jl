@testset "ConvertEltype" begin
    @test (ConvertEltype <: AugmentorBase.AffineOperation) == false
    @test (ConvertEltype <: AugmentorBase.ImageOperation) == false
    @test (ConvertEltype <: AugmentorBase.Operation) == true

    @testset "constructor" begin
        @test_throws MethodError ConvertEltype()
        @test typeof(@inferred(ConvertEltype(Float64))) <: ConvertEltype <: AugmentorBase.Operation
        @test typeof(@inferred(ConvertEltype(RGB))) <: ConvertEltype <: AugmentorBase.Operation
        @test typeof(@inferred(ConvertEltype(RGB{N0f8}))) <: ConvertEltype <: AugmentorBase.Operation
        @test str_show(ConvertEltype(Float64)) == "AugmentorBase.ConvertEltype(Float64)"
        @test str_show(ConvertEltype(RGB)) == "AugmentorBase.ConvertEltype(RGB{Any})"
        @test str_show(ConvertEltype(Gray{N0f8})) == "AugmentorBase.ConvertEltype(Gray{N0f8})"
        @test str_showconst(ConvertEltype(Float64)) == "ConvertEltype(Float64)"
        @test str_showconst(ConvertEltype(RGB{N0f8})) == "ConvertEltype(RGB{N0f8})"
        @test str_showcompact(ConvertEltype(Float64)) == "Convert eltype to Float64"
        @test str_showcompact(ConvertEltype(Gray)) == "Convert eltype to Gray{Any}"
    end
    @testset "eager" begin
        @test AugmentorBase.supports_eager(ConvertEltype) === true
        @test AugmentorBase.supports_eager(ConvertEltype{Float64}) === true
        res1 = convert(Array{Gray{Float32}}, rect)
        res1a = OffsetArray(res1, 0, 0)
        res1b = OffsetArray(res1, -2, -1)
        imgs = [
            (Float32, rect, Float32.(res1)),
            (Float32, OffsetArray(rect, -2, -1), Float32.(res1b)),
            (Gray{Float32}, rect, res1),
            (Gray{Float32}, Float64.(rect), res1),
            (Gray{Float32}, reshape(view(rect,:,:), 2,3), res1),
            (Gray{Float32}, RGB{N0f8}.(rect), res1),
            (Gray{Float32}, OffsetArray(rect, -2, -1), res1b),
            (Gray{Float32}, view(rect, IdentityRange(1:2), IdentityRange(1:3)), res1a),
            (RGB{Float32}, rect, RGB{Float32}.(res1)),
            (RGB{Float32}, OffsetArray(rect, -2, -1), RGB{Float32}.(res1b)),
        ]
        @testset "single image" begin
            for (T, img_in, img_out) in imgs
                res = @inferred(AugmentorBase.applyeager(ConvertEltype(T), img_in))
                @test res ≈ img_out
                @test typeof(res) == typeof(img_out)
            end
        end
    end
    @testset "affine" begin
        @test AugmentorBase.supports_affine(ConvertEltype) === false
    end
    @testset "affineview" begin
        @test AugmentorBase.supports_affineview(ConvertEltype) === false
    end
    @testset "lazy" begin
        @test AugmentorBase.supports_lazy(ConvertEltype) === true
        @test @inferred(AugmentorBase.supports_lazy(ConvertEltype{Float64})) === true
        @test @inferred(AugmentorBase.supports_lazy(typeof(ConvertEltype(Gray)))) === true
        @test @inferred(AugmentorBase.supports_lazy(typeof(ConvertEltype(Gray{N0f8})))) === true
        let img = @inferred(AugmentorBase.applylazy(ConvertEltype(Gray{Float32}), OffsetArray(rect,-2,-1)))
            @test parent(parent(img)) === rect
            @test axes(img) === (Base.IdentityUnitRange(-1:0), Base.IdentityUnitRange(0:2))
            @test img[0,0] isa Gray{Float32}
            @test collect(img) == convert.(Gray{Float32}, rect)
        end
        let img = @inferred(AugmentorBase.applylazy(ConvertEltype(Gray{Float32}), view(rect, IdentityRange(1:2), IdentityRange(1:3))))
            @test parent(parent(img)) === rect
            @test axes(img) === (1:2, 1:3)
            @test img[1,1] isa Gray{Float32}
            @test collect(img) == convert.(Gray{Float32}, rect)
        end
        let img = @inferred(AugmentorBase.applylazy(ConvertEltype(Gray{Float32}), rgb_rect))
            @test parent(img) === rgb_rect
            @test axes(img) === (Base.OneTo(2), Base.OneTo(3))
            @test img == convert.(Gray{Float32}, rgb_rect)
        end
        let img = @inferred(AugmentorBase.applylazy(ConvertEltype(Float32), checkers))
            @test parent(img) === checkers
            @test axes(img) === (Base.OneTo(3), Base.OneTo(5))
            @test img == convert(Array{Float32}, checkers)
        end
        let img = @inferred(AugmentorBase.applylazy(ConvertEltype(RGB{N0f8}), checkers))
            @test parent(img) === checkers
            @test img == convert.(RGB, checkers)
        end
        let img = @inferred(AugmentorBase.applylazy(ConvertEltype(RGB{Float64}), checkers))
            @test parent(img) === checkers
            @test img == convert.(RGB{Float64}, checkers)
        end
    end
    @testset "view" begin
        @test AugmentorBase.supports_view(ConvertEltype) === false
    end
    @testset "stepview" begin
        @test AugmentorBase.supports_stepview(ConvertEltype) === false
    end
    @testset "permute" begin
        @test AugmentorBase.supports_permute(ConvertEltype) === false
    end
end
