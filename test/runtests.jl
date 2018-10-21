using Test
using Distributed

# compute models in parallel: multiprocess
addprocs(Sys.CPU_THREADS) # add a worker process per core
printstyled("Setup:\n", color=:white)
println("  > Using $(nprocs()-1) worker processes")

using MarriageMarkets

println("  > Computing models...")
include("setup_tests.jl") # multiprocess model computations

@testset "MarriageMarkets" begin

	@testset "Static model" begin

		@testset "Unidimensional model" begin
			include("test_static_unidim.jl")
		end

		@testset "Multidimensional model" begin
			include("test_static_multidim.jl")
		end

	end # static model


	@testset "Search model" begin

		@testset "Basic Shimer-Smith model" begin
			include("test_search_base.jl")
		end

		@testset "Stochastic model" begin
			include("test_search_stoch.jl")
		end

		@testset "Multidimensional types" begin
			include("test_search_multidim.jl")
		end

	end # search model

end # MarriageMarkets
