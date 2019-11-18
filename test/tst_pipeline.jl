# test not exported
@test_throws UndefVarError Pipeline
@test_throws UndefVarError AbstractPipeline
@test_throws UndefVarError ImmutablePipeline
@test AugmentorBase.AbstractPipeline <: Any
@test AugmentorBase.Pipeline <: AugmentorBase.AbstractPipeline
@test AugmentorBase.ImmutablePipeline <: AugmentorBase.Pipeline

@test typeof((FlipX(),FlipY())) <: AugmentorBase.AbstractPipeline
@test AugmentorBase.operations((FlipX(),FlipY())) === (FlipX(),FlipY())

@testset "ImmutablePipeline" begin
    @test_throws MethodError AugmentorBase.ImmutablePipeline()
    @test_throws MethodError AugmentorBase.ImmutablePipeline(())
    @test_throws MethodError AugmentorBase.ImmutablePipeline(1)
    @test_throws MethodError AugmentorBase.ImmutablePipeline((1,))
    @test_throws MethodError AugmentorBase.ImmutablePipeline{1}((1,))
    @test_throws MethodError AugmentorBase.ImmutablePipeline{2}((FlipX(),))
    @test_throws MethodError AugmentorBase.ImmutablePipeline{1}(FlipX())

    @test @inferred(AugmentorBase.ImmutablePipeline(FlipX())) === @inferred(AugmentorBase.ImmutablePipeline{1}((FlipX(),)))

    p = @inferred AugmentorBase.ImmutablePipeline(FlipX())
    @test p === @inferred(AugmentorBase.ImmutablePipeline((FlipX(),)))
    @test typeof(p) <: AugmentorBase.ImmutablePipeline{1}
    @test @inferred(length(p)) === 1
    @test @inferred(AugmentorBase.operations(p)) === (FlipX(),)

    p = @inferred AugmentorBase.ImmutablePipeline(FlipX(), FlipY())
    @test p === @inferred(AugmentorBase.ImmutablePipeline((FlipX(),FlipY())))
    @test typeof(p) <: AugmentorBase.ImmutablePipeline{2}
    @test @inferred(length(p)) === 2
    @test @inferred(AugmentorBase.operations(p)) === (FlipX(),FlipY())

    p = @inferred AugmentorBase.ImmutablePipeline(FlipX(), FlipY(), Rotate90())
    @test p === @inferred(AugmentorBase.ImmutablePipeline((FlipX(),FlipY(),Rotate90())))
    @test typeof(p) <: AugmentorBase.ImmutablePipeline{3}
    @test @inferred(length(p)) === 3
    @test @inferred(AugmentorBase.operations(p)) === (FlipX(),FlipY(),Rotate90())
end

@testset "ImmutablePipeline with |>" begin
    buf = rand(2,2)

    p = @inferred(FlipX() |> FlipY())
    @test p === AugmentorBase.ImmutablePipeline(FlipX(), FlipY())

    p = @inferred(FlipX() |> buf |> FlipY())
    @test p === AugmentorBase.ImmutablePipeline(FlipX(), CacheImage(buf), FlipY())

    p = @inferred(FlipX() |> CacheImage(buf) |> FlipY())
    @test p === AugmentorBase.ImmutablePipeline(FlipX(), CacheImage(buf), FlipY())

    p = @inferred(FlipX() |> CacheImage() |> FlipY())
    @test p === AugmentorBase.ImmutablePipeline(FlipX(), CacheImage(), FlipY())

    p = @inferred(FlipX() |> FlipY() |> buf)
    @test p === AugmentorBase.ImmutablePipeline(FlipX(), FlipY(), CacheImage(buf))

    p = @inferred(FlipX() |> NoOp() |> FlipY())
    @test p === AugmentorBase.ImmutablePipeline(FlipX(), NoOp(), FlipY())

    p = @inferred((FlipX() |> NoOp()) |> FlipY())
    @test p === AugmentorBase.ImmutablePipeline(FlipX(), NoOp(), FlipY())

    p = @inferred(FlipX() |> (NoOp() |> FlipY()))
    @test p === AugmentorBase.ImmutablePipeline(FlipX(), NoOp(), FlipY())

    p = @inferred(FlipX() |> NoOp() |> FlipY() |> Rotate90())
    @test p === AugmentorBase.ImmutablePipeline(FlipX(), NoOp(), FlipY(), Rotate90())

    p = @inferred((FlipX() |> NoOp()) |> (FlipY() |> Rotate90()))
    @test p === AugmentorBase.ImmutablePipeline(FlipX(), NoOp(), FlipY(), Rotate90())

    p = FlipX() * FlipY() |> Rotate90() * Rotate270()
    @test p == AugmentorBase.ImmutablePipeline(Either(FlipX(),FlipY()), Either(Rotate90(),Rotate270()))

    p = NoOp() * FlipX() * FlipY() |> Rotate90() * Rotate270()
    @test p == AugmentorBase.ImmutablePipeline(Either(NoOp(),FlipX(),FlipY()), Either(Rotate90(),Rotate270()))
end

@testset "Pipeline constructor" begin
    @test_throws MethodError AugmentorBase.Pipeline()
    @test_throws MethodError AugmentorBase.Pipeline(())
    @test_throws MethodError AugmentorBase.Pipeline(1)
    @test_throws MethodError AugmentorBase.Pipeline((1,))

    p = @inferred AugmentorBase.Pipeline(FlipX())
    @test typeof(p) <: AugmentorBase.ImmutablePipeline
    @test p == AugmentorBase.ImmutablePipeline(FlipX())

    p = @inferred AugmentorBase.Pipeline((FlipX(),))
    @test typeof(p) <: AugmentorBase.ImmutablePipeline
    @test p == AugmentorBase.ImmutablePipeline(FlipX())

    p = @inferred AugmentorBase.Pipeline(FlipX(), FlipY())
    @test typeof(p) <: AugmentorBase.ImmutablePipeline
    @test p == AugmentorBase.ImmutablePipeline(FlipX(),FlipY())

    p = @inferred AugmentorBase.Pipeline((FlipX(), FlipY()))
    @test typeof(p) <: AugmentorBase.ImmutablePipeline
    @test p == AugmentorBase.ImmutablePipeline(FlipX(),FlipY())
end
