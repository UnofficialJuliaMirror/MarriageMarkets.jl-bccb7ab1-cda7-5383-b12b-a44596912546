using LinearAlgebra
using Distributions

λ, r, δ, σ = 5.0, 0.05, 0.05, 10.0

@everywhere h(x::Real, y::Real) = x * y # unidimensional production function
@everywhere hsup(x::Vector, y::Vector) = sum(x .* y) / 2 # supermodular production function
@everywhere hsub(x::Vector, y::Vector) = sqrt(sum(x .+ y)) # submodular production function

"Instantiate a static market with unidimensional types."
function static_unidim(nmen, nwom, prod)
	
	# types: concave to prevent numerical instability
	men = [log(i+1) for i=1:nmen]
	wom = [log(j+1) for j=1:nwom]

	# masses: unit mass of each sex
	menmass = ones(Float64, nmen)/nmen
	wommass = ones(Float64, nwom)/nwom

	job = @spawn MarriageMarkets.StaticMatch(men, wom, menmass, wommass, prod)
	return job
end

"Compute match distribution given equilibrium measures of singles."
function match_matrix(surp::Array, singlemen::Array, singlewom::Array)
	return [exp(surp[i,j]) * sqrt(singlemen[i] * singlewom[j])
	        for i in CartesianIndices(singlemen), j in CartesianIndices(singlewom)]
end

"Equilibrium conditions relating matches and singles."
function eqm_consistency(surp::Array, μm0::Array, μf0::Array)
	mmass = [μm0[i] + (sqrt(μm0[i]) * sum(exp(surp[i, j]) * sqrt(μf0[j]) for j in CartesianIndices(μf0)))
	         for i in CartesianIndices(μm0)]

	fmass = [μf0[j] + (sqrt(μf0[j]) * sum(exp(surp[i, j]) * sqrt(μm0[i]) for i in CartesianIndices(μm0)))
	         for j in CartesianIndices(μf0)]

	return mmass, fmass
end

"Instantiate a frictional market with uniform type distributions."
function search_uniform(ntypes, mmass, fmass, prod, σ)
	Θ = Vector(range(1.0, stop=2.0, length=ntypes)) # types

	# uniform population distributions
	lm = (mmass / ntypes) * ones(Float64, ntypes)
	lf = (fmass / ntypes) * ones(Float64, ntypes)

	job = @spawn MarriageMarkets.SearchClosed(λ, δ, r, σ, Θ, Θ, lm, lf, prod)
	return job
end

### Static model ###

pam_job = static_unidim(5, 5, hsup) # must be symmetric for the symmetry test
nam_job = static_unidim(3, 5, hsub)

# multidimensional types: symmetric case
n1, n2 = 6, 2
# common type vector
symtypes = [[log(1+i) for i=1:n1], [i for i=1:n2]]
# mass vectors: unit mass of each sex
symdist = ones(Float64, n1, n2)/(n1*n2)

symm_multi_job = @spawn MarriageMarkets.StaticMatch(symtypes, symtypes, symdist, symdist, hsup)

# multidimensional types: asymmetric case
# type vectors
men2 = [[1.0, 1.2, 1.3], [0.0, 1.0]]
wom2 = [[1.0, 1.2, 1.3, 1.35, 1.4], [0.0, 1.0]]
# mass vectors: unit mass of each sex
mdist2 = ones(Float64, 3, 2)/6
fdist2 = ones(Float64, 5, 2)/10

asym_multi_job = @spawn MarriageMarkets.StaticMatch(men2, wom2, mdist2, fdist2, hsup)



### Search model - non-stochastic ###

# instantiate on a worker process
symm_job = search_uniform(20, 100, 100, h, 0)


### Search model - stochastic ###

# symmetric case
rsym_job = search_uniform(20, 100, 100, h, σ)

# asymmetric case: needs σ >~ 10 to converge
rasym_job = search_uniform(20, 50, 100, h, σ)

# multidimensional types: symmetric case
k1, k2 = 10, 2
# common type vector
srsymtypes = [[log(1+i) for i=1:k1], [i for i=1:k2]]
# mass vectors: unit mass of each sex
srsymdist= ones(Float64, k1, k2)/(k1*k2)

srsymm_multi_job = @spawn MarriageMarkets.SearchClosed(λ, δ, r, σ, srsymtypes, srsymtypes, srsymdist, srsymdist, hsup)
