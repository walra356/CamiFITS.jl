# ======================== sup(i) ==============================================

function _superscript(i::Int)

    c = i < 0 ? [Char(0x207B)] : []

    for d ∈ reverse(digits(abs(i)))
        d == 0 ? Base.push!(c, Char(0x2070)) :
        d == 1 ? Base.push!(c, Char(0x00B9)) :
        d == 2 ? Base.push!(c, Char(0x00B2)) :
        d == 3 ? Base.push!(c, Char(0x00B3)) : Base.push!(c, Char(0x2070+d))
    end

    return join(c)

end

function _subscript(i::Int)

    c = i < 0 ? [Char(0x208B)] : []

    for d ∈ reverse(digits(abs(i)))
        Base.push!(c, Char(0x2080+d))
    end

    return join(c)

end
function _subscript(str::String)

    d = Dict(
        'a' => Char(0x2090),
        'e' => Char(0x2091),
        'h' => Char(0x2095),
        'k' => Char(0x2096),
        'l' => Char(0x2097),
        'm' => Char(0x2098),
        'n' => Char(0x2099),
        'o' => Char(0x2092),
        'p' => Char(0x209A),
        'r' => Char(0x1D63),
        's' => Char(0x209B),
        't' => Char(0x209C),
        'x' => Char(0x2093))

    c::Vector{Char} = []

    for i ∈ collect(str)
        Base.push!(c, get(d, i,'.'))
    end

    return join(c)

end

# ======================== sup(i) ==============================================

@doc raw"""
    sup(i::T) where T<:Real

Superscript notation for integers and rational numbers
#### Examples:
```
sup(3) * 'P'
 "³P"
```
"""
function sup(i::T) where T<:Real

    sgn = i < 0 ? Char(0x207B) : ""

    num = _superscript(numerator(abs(i)))
    den = _superscript(denominator(abs(i)))

    return T == Rational{Int} ? (sgn * num * '\U141F' * den) : (sgn * num)

end

# ======================== sub(i) ==============================================

@doc raw"""
    sub(i::T) where T<:Real

Subscript notation for integers, rational numbers and a *subset* of lowercase characters ('a','e','h','k','l','m','n','o','p','r','s','t','x')
#### Examples:
```
'D' * sub(5//2)
 "D₅⸝₂"

"m" * sub("e")
 "mₑ"
```
"""
function sub(i::T) where T<:Real

    sgn = i < 0 ? Char(0x208B) : ""

    num = _subscript(numerator(abs(i)))
    den = _subscript(denominator(abs(i)))

    return T == Rational{Int} ? (sgn * num * '\U2E1D' * den) : (sgn * num)

end
function sub(str::String)

    U = ['a','e','h','k','l','m','n','o','p','r','s','t','x']

    c = collect(str)

    for i ∈ eachindex(c)
        c[i] ∈ U || error("Error: subscript $(S[i]) not part of Unicode")
    end

    return _subscript(str::String)

end

@doc raw"""
    frac(i)

Fraction notation for rational numbers
#### Examples:
```
frac(-5//2)
 "-⁵/₂"
```
"""
function frac(i::Rational{Int})

    sgn = i < 0 ? "-" : ""

    num = _superscript(numerator(abs(i)))
    den = _subscript(denominator(abs(i)))

    return sgn * num *  '/' * den

end

@doc raw"""
    strRational(i)

Fraction notation for rational numbers and integers
#### Examples:
```
strRational(-5//2)
 "-5/2"

 strRational(-5//2)
  "-5"
```
"""
function strRational(n::T) where T<:Union{Rational{}, Int, BigInt}


    isinteger(n) && return repr(n)

    sgn = n < 0 ? "-" : ""

    num = repr(numerator(abs(n)))
    den = repr(denominator(abs(n)))

    return sgn * num *  '/' * den

end
