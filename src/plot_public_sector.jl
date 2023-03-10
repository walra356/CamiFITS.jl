# ==================================== step125(x) ============================================================

"""
    step125(x)

Step used for deviding the number x in steps according to 1-2-5 scheme
#### Examples:
```
step125.([5,10,21.3,50,100.1])
5-element Vector{Int64}:
  1
  2
  5
 10
 20
```
"""
function step125(x::Real)

    m = CamiMath.log10_mantissa(x)
    p = CamiMath.log10_characteristic(x)
    v = 10^m
    d = v > 7.9 ? 2.0 : v > 3.9 ? 1.0 : v > 1.49 ? 0.5 : 0.2

    return max(1,round(Int, d *= 10^p))

end

# ==================================== select125(x) ===============================================================

"""
    select125(x)

Select elements of the collection x by index according to 1-2-5 scheme
#### Examples:
```@docs
x = [1,2,4,6,8,10,13,16,18,20,40,60,80,100]
select125(x)
 [2, 6, 10, 16, 20, 60, 100]

x = string.(x)
select125(x)
 ["2", "6", "10", "16", "20", "60", "100"]

x = 1:100
select125(x)
 [20, 40, 60, 80, 100]
```
"""
select125(x) = (n = length(x); return [x[i] for i=step125(n):step125(n):n])

# ==================================== edges(x) ===============================================================

"""
    edges(px [, Δx[, x0]])

Heatmap range transformation from pixel coordinates to physical coordinates,
with pixelsize Δx and offset x0, both in physical units.
#### Examples:
```@docs
px = 1:5
Δx = 2.5
x0 = 2.5
edges(px)
 [0.5, 1.5, 2.5, 3.5, 4.5]

edges(px, Δx)
 [1.25, 3.75, 6.25, 8.75, 11.25]

edges(px, Δx, x0)
 [-1.25, 1.25, 3.75, 6.25, 8.75]
```
"""
edges(px, Δx=1.0, x0=0.0) = collect(px .* Δx) .-(x0 + 0.5Δx)

# =================================== steps(x) =============================================================

"""
    steps(x)

Heatmap range transformation for steplength specification vector x
#### Examples:
```@docs
x = [4,2,6]
steps(x)
 [0, 4, 6, 12]
```
"""
function steps(x::Vector{T} where T<:Real)

    sum(x .< 0) == 0 || error("Error: $x - nagative step length not allowed")

    return (s = append!(eltype(x)[0],x); [Base.sum(s[1:i]) for i ∈ Base.eachindex(s)])

end

# =================================== stepcenters(x) =============================================================

"""
    stepcenters(x)

Stepcenter positions for steplength specification vector x
#### Examples:
```@docs
x = [4,2,6]
stepcenters(x)
 [2.0, 5.0, 9.0]
```
"""
function stepcenters(x::Vector{T} where T<:Real)

    s = append!(eltype(x)[0],x)

    return [Base.sum(s[1:i]) + 0.5x[i] for i ∈ Base.eachindex(x)]

end

# =================================== stepedges(x) =============================================================

"""
    stepedges(x)

Stepedges for steplength specification vector x
#### Examples:
```@docs
x = [4,2,6]
stepedges(x)
 [0, 4, 6, 12]
```
"""
function stepedges(x::Vector{T} where T<:Real)

    return steps(x)

end
