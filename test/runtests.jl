using Test
using Aqua
using CallableModules

@testset "Aqua" begin
    Aqua.test_all(CallableModules; piracies = (treat_as_own = [Module],))
end

# ── Test modules ──────────────────────────────────────────────────────

module ModLong
    using CallableModules
    @module_main function main(args...; kwargs...)
        (args, kwargs)
    end
end

module ModShort
    using CallableModules
    @module_main double(x) = 2x
end

module ModNoArgs
    using CallableModules
    @module_main function greet()
        "hello"
    end
end

# ── Tests ─────────────────────────────────────────────────────────────

@testset "CallableModules.jl" begin
    @testset "no arguments" begin
        @test ModNoArgs() == "hello"
    end

    @testset "positional arguments" begin
        args, kw = ModLong(1, "two", :three)
        @test args == (1, "two", :three)
        @test isempty(kw)
    end

    @testset "keyword arguments" begin
        args, kw = ModLong(; x=1, y=2)
        @test args == ()
        @test kw[:x] == 1
        @test kw[:y] == 2
        @test length(kw) == 2
    end

    @testset "mixed positional and keyword arguments" begin
        args, kw = ModLong(1, 2; flag=true)
        @test args == (1, 2)
        @test kw[:flag] == true
        @test length(kw) == 1
    end

    @testset "short-form function definition (=)" begin
        @test ModShort(21) == 42
        @test ModShort(0) == 0
        @test ModShort(-3) == -6
    end

    @testset "multiple callable modules coexist" begin
        @test ModNoArgs() == "hello"
        @test ModShort(5) == 10
        args, kw = ModLong(42)
        @test args == (42,)
        @test isempty(kw)
    end

    @testset "macro rejects non-function input" begin
        @test_throws LoadError @eval @module_main begin end
    end
end
