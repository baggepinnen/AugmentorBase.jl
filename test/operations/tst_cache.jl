@testset "CacheImage" begin
    @test (CacheImage <: AugmentorBase.AffineOperation) == false
    @test (CacheImage <: AugmentorBase.ImageOperation) == true
    @test typeof(@inferred(CacheImage())) <: CacheImage
    @test str_show(CacheImage()) == "AugmentorBase.CacheImage()"
    @test str_showconst(CacheImage()) == "CacheImage()"
    @test str_showcompact(CacheImage()) == "Cache into temporary buffer"

    @test @inferred(AugmentorBase.applyeager(CacheImage(),square)) === square
    @test @inferred(AugmentorBase.applyeager(CacheImage(),(square,))) === (square,)
    @test @inferred(AugmentorBase.applyeager(CacheImage(),(square,square2))) === (square,square2)

    # SubArray
    v = view(square, :, :)
    img = @inferred AugmentorBase.applyeager(CacheImage(), v)
    @test typeof(img) <: Array
    @test eltype(img) == eltype(v)
    @test img !== square
    @test img == square
    # Identidy ranges
    v = view(square, IdentityRange(1:3), IdentityRange(1:3))
    img = @inferred AugmentorBase.applyeager(CacheImage(), v)
    @test typeof(img) <: OffsetArray
    @test eltype(img) == eltype(v)
    @test img == OffsetArray(square, 0, 0)
    # Affine
    v = AugmentorBase.prepareaffine(square)
    img = @inferred AugmentorBase.applyeager(CacheImage(), v)
    @test typeof(img) <: OffsetArray
    @test eltype(img) == eltype(v)
    @test img == OffsetArray(square, 0, 0)
    # Array and SubArray
    v = view(square, :, :)
    tmp,img = @inferred AugmentorBase.applyeager(CacheImage(), (square,v))
    @test typeof(img) <: Array
    @test eltype(img) == eltype(v)
    @test tmp === square
    @test img !== square
    @test img == square
    # OffsetArray
    o = OffsetArray(square, (-1,2))
    @test @inferred(AugmentorBase.applyeager(CacheImage(),o)) === o
    @test @inferred(AugmentorBase.applyeager(CacheImage(),(o,square))) === (o,square)

    @test AugmentorBase.supports_eager(CacheImage) === true
    @test AugmentorBase.supports_lazy(CacheImage) === false
    @test AugmentorBase.supports_view(CacheImage) === false
    @test AugmentorBase.supports_stepview(CacheImage) === false
    @test AugmentorBase.supports_permute(CacheImage) === false
    @test AugmentorBase.supports_affine(CacheImage) === false
    @test AugmentorBase.supports_affineview(CacheImage) === false

    @test_throws MethodError AugmentorBase.applylazy(CacheImage(), v)
    @test_throws MethodError AugmentorBase.applylazy(CacheImage(), (v,v))
    @test_throws MethodError AugmentorBase.applyview(CacheImage(), v)
    @test_throws MethodError AugmentorBase.applystepview(CacheImage(), v)
    @test_throws MethodError AugmentorBase.applypermute(CacheImage(), v)
    @test_throws MethodError AugmentorBase.applyaffine(CacheImage(), v)
    @test_throws MethodError AugmentorBase.applyaffineview(CacheImage(), v)
end

# --------------------------------------------------------------------

@testset "CacheImageInto" begin
    @test_throws UndefVarError CacheImageInto
    @test (AugmentorBase.CacheImageInto <: AugmentorBase.AffineOperation) == false
    @test (AugmentorBase.CacheImageInto <: AugmentorBase.ImageOperation) == true
    @test_throws MethodError AugmentorBase.CacheImageInto()

    @testset "single image" begin
        buf = copy(rect)
        @test typeof(@inferred(CacheImage(buf))) <: AugmentorBase.CacheImageInto
        op = @inferred CacheImage(buf)
        @test AugmentorBase.CacheImageInto(buf) === op
        @test str_show(op) == "AugmentorBase.CacheImageInto(::Array{Gray{N0f8},2})"
        @test str_showconst(op) == "CacheImage(Array{Gray{N0f8}}(2, 3))"
        op2 = @inferred CacheImage(Array{Gray{N0f8}}(undef, 2, 3))
        @test typeof(op) == typeof(op2)
        @test typeof(op.buffer) == typeof(op2.buffer)
        @test size(op.buffer) == size(op2.buffer)
        @test str_showcompact(op) == "Cache into preallocated 2×3 Array{Gray{N0f8},2} with eltype Gray{Normed{UInt8,8}}"

        v = AugmentorBase.applylazy(Resize(2,3), camera)
        res = @inferred AugmentorBase.applyeager(op, v)
        @test res == v
        @test typeof(res) <: OffsetArray
        @test parent(res) === op.buffer

        res = @inferred AugmentorBase.applyeager(op, rect)
        @test res == rect
        @test res === op.buffer

        res = @inferred AugmentorBase.applylazy(op, v)
        @test res == v
        @test typeof(res) <: OffsetArray
        @test parent(res) === op.buffer

        res = @inferred AugmentorBase.applylazy(op, rect)
        @test res == rect
        @test res === op.buffer

        @test_throws ArgumentError AugmentorBase.applyeager(op, camera)
        @test_throws MethodError AugmentorBase.applyview(CacheImage(buf), v)
        @test_throws MethodError AugmentorBase.applystepview(CacheImage(buf), v)
        @test_throws MethodError AugmentorBase.applypermute(CacheImage(buf), v)
        @test_throws MethodError AugmentorBase.applyaffine(CacheImage(buf), v)
        @test_throws MethodError AugmentorBase.applyaffineview(CacheImage(buf), v)
    end

    @testset "multiple images" begin
        buf1 = copy(square)
        buf2 = copy(rgb_rect)
        @test typeof(@inferred(CacheImage(buf1,buf2))) <: AugmentorBase.CacheImageInto
        op = @inferred CacheImage(buf1,buf2)
        @test op === @inferred CacheImage((buf1,buf2))
        @test AugmentorBase.CacheImageInto((buf1,buf2)) === op
        @test str_show(op) == "AugmentorBase.CacheImageInto((::Array{Gray{N0f8},2}, ::Array{RGB{N0f8},2}))"
        @test str_showconst(op) == "CacheImage(Array{Gray{N0f8}}(3, 3), Array{RGB{N0f8}}(2, 3))"
        op2 = @inferred CacheImage(Array{Gray{N0f8}}(undef, 3, 3), Array{RGB{N0f8}}(undef, 2, 3))
        @test typeof(op) == typeof(op2)
        @test typeof(op.buffer) == typeof(op2.buffer)
        @test size.(op.buffer) === size.(op2.buffer)
        @test str_showcompact(op) == "Cache into preallocated (3×3 Array{Gray{N0f8},2} with eltype Gray{Normed{UInt8,8}}, 2×3 Array{RGB{N0f8},2} with eltype RGB{Normed{UInt8,8}})"
        @test buf1 == square
        @test buf2 == rgb_rect
        v1 = AugmentorBase.applylazy(Resize(3,3), camera)
        v2 = AugmentorBase.applylazy(Resize(2,3), RGB.(camera))
        res = @inferred AugmentorBase.applyeager(op, (v1,v2))
        @test buf1 != square
        @test buf2 != rgb_rect
        @test res == (v1, v2)
        @test typeof(res) <: NTuple{2,OffsetArray}
        @test parent.(res) === (op.buffer[1], op.buffer[2])

        @test_throws ArgumentError AugmentorBase.applyeager(op, (camera,buf1)) #1
        @test_throws MethodError AugmentorBase.applylazy(op, v1)
        @test_throws ArgumentError AugmentorBase.applylazy(op, (buf2,buf1)) #3
        @test_throws BoundsError AugmentorBase.applylazy(op, (buf1,))
        # ?
        @test_throws DimensionMismatch AugmentorBase.applylazy(op, (v1,v1))
    end

    @test AugmentorBase.supports_eager(AugmentorBase.CacheImageInto) === true
    @test AugmentorBase.supports_lazy(AugmentorBase.CacheImageInto) === true
    @test AugmentorBase.supports_view(AugmentorBase.CacheImageInto) === false
    @test AugmentorBase.supports_stepview(AugmentorBase.CacheImageInto) === false
    @test AugmentorBase.supports_permute(AugmentorBase.CacheImageInto) === false
    @test AugmentorBase.supports_affine(AugmentorBase.CacheImageInto) === false
    @test AugmentorBase.supports_affineview(AugmentorBase.CacheImageInto) === false
end
