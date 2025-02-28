# SPDX-License-Identifier: MIT

# Copyright (c) 2024 Jook Walraven <69215586+walra356@users.noreply.github.com> and contributors

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# ------------------------------------------------------------------------------
#                               FORTRAN.jl
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                             FORTRAN_format
# ------------------------------------------------------------------------------

"""
    FORTRAN_format

Object to hold a FORTRAN format specifier decomposed in its fields.

Accepted *datatype specifiers* are:  `Aw`,  `Iw`,  `Fw.d`,  `Ew.d`,  `Dw.d`

Accepted *output formating specifiers* are: `Aw`,  `Iw.m`,  `Bw.m`,  `Ow.m`,
`Zw.m`,  `Fw.d`,  `Ew.dEe`,  `ENw.d`,  `ESw.d`,  `Gw.dEe`,  `Dw.dEe`.
Notation: `w` - width, `m` (optional) - minimum number of digits, `d` - number
of digits to right of decimal, `e` - number of digits in exponent `N`/`S`
(optional) indicates engineering/scientific formating of the `E` type.

The fields are:
* `.datatype`: primary FORTRAN datatype (`::String`)
* `.char`: primary FORTRAN datatype character (`::Char`)
* `.EngSci`: secundary datatype character - N for engineering/ S for scientific (`::Union{Char,Nothing}`)
* `.width`: width of numeric field (`::Int`)
* `.nmin`: minimum number of digits displayed (`::Int`)
* `.ndec`: number of digits to right of decimal (`::Int`)
* `.nexp`: number of digits in exponent (`::Int`)
"""
struct FORTRAN_format

    datatype::String
    char::Char
    EngSci::Union{Char,Nothing}
    width::Int
    nmin::Int
    ndec::Int
    nexp::Int

end

# ------------------------------------------------------------------------------
#                       cast_FORTRAN_format(format)
# ------------------------------------------------------------------------------

"""
    cast_FORTRAN_format(format::String)

Decompose the format specifier `format` into its fields and cast this into the
[`FORTRAN_format`](@ref) object. Allowed format specifiers are of the types:
`Aw`, `Iw.m`, `Bw.m`, `Ow.m`, `Zw.m`, `Fw.d`, `Ew.dEe`, `ENw.d`, `ESw.d`,
`Gw.dEe`, `Dw.dEe`, with: `w` - width, `m `(optional) - minimum number of
digits, `d` - number of digits to right of decimal, `e` - number of digits in
exponent; `N`/`S` (optional) indicates engineering/scientific formating of
the `E` type.
#### Examples:
```
julia> cast_FORTRAN_format("I10")
FORTRAN_format("Iw", 'I', nothing, 10, 0, 0, 0)

julia> cast_FORTRAN_format("I10.12")
FORTRAN_format("Iw.m", 'I', nothing, 10, 12, 0, 0)

julia> F = cast_FORTRAN_format("E10.5E3")
FORTRAN_format("Ew.dEe", 'E', nothing, 10, 0, 5, 3)

julia> F.Type, F.TypeChar, F.EngSci, F.width, F.nmin, F.ndec, F.nexp
("Ew.dEe", 'E', nothing, 10, 0, 5, 3)  
```
"""
function cast_FORTRAN_format(str::String)

    s = strip(str,['\'',' ']); w = m = d = e = 0

    strErr = "strError: $s: not a valid FORTRAN print format "
    accept = ['A','I','B','O','Z','F','E','G','D','N','S','.','1','2','3','4','5','6','7','8','9','0']

    sum([s[i] ∉ accept for i ∈ eachindex(s)]) == 0 ? n=length(s) : return error(strErr * "(unknown type character)")
    n > 1 ?  X = s[1] : return error(strErr * " (width field not specified)")
    s[2] ∈ ['N','S'] ? (ns = s[2]; i = 3) : (ns = nothing; i = 2)
    rst = s[i:end]; length(rst) < 1 && return error(strErr * "(decimal side not specified)")

    if !occursin('.', rst)
        sum(.!isnumeric.(collect(rst))) > 0 && return error(strErr)
        X ∈ ['A','I','B','O','Z'] ? (t = X * "w"; w = parse(Int,rst)) : 0
        X ∈ ['F','E','G','D'] && return error(strErr * "(decimal field not specified)")
    else
        X ∈ ['A'] && return error(strErr * "(decimal point incompatible with $X type)")
        spl = split(rst,'.'); length(spl) > 2 && return error(strErr * "(two decimal points not allowed)")
        lhs = spl[1]
        rhs = spl[2]
        length(lhs) < 1 && return error(strErr * "(width field not specified)")
        length(rhs) < 1 && return error(strErr * "(decimal side not specified)")
        sum(.!isnumeric.(collect(lhs))) > 0 && return error(strErr * "(width field not numeric)")

        if !occursin('E',rhs)
            sum(.!isnumeric.(collect(rhs))) > 0 && return error(strErr * "(decimal field not numeric)")
            x = isnothing(ns) ? "" : ns
            X ∈ ['E','G','D'] ? (t = X * x * "w.d"; w = parse(Int,lhs); d = parse(Int,rhs)) : 0
        else
            X ∈ ['F','I','B','O','Z'] && return error(strErr * "(exponent incompatible with $X type)")
            splE = split(rhs,'E'); length(splE) > 2 && return error(strErr * "(unexpected E character)")
            rhs1 = splE[1]
            rhs2 = splE[2]
            length(rhs1) < 1 && return error(strErr * "(decimal field not specified)")
            length(rhs2) < 1 && return error(strErr * "(exponent field not specified)")
            sum(.!isnumeric.(collect(rhs1))) > 0 && return error(strErr * "(decimal field not numeric)")
            sum(.!isnumeric.(collect(rhs2))) > 0 && return error(strErr * "(exponent field not numeric)")
            X ∈ ['E','G','D'] ? (t = X * "w.dEe"; w = parse(Int,lhs); d = parse(Int,rhs1); e = parse(Int,rhs2)) : 0
        end
        X ∈ ['I','B','O','Z'] ? (t = X * "w.m"; w = parse(Int,lhs); m = parse(Int,rhs)) : 0
        X ∈ ['F'] ? (t = X * "w.d"; w = parse(Int,lhs); d = parse(Int,rhs)) : 0
    end

    return FORTRAN_format(t, X, ns, w, m, d, e)

end

# ------------------------------------------------------------------------------
#                             FORTRAN_
# ------------------------------------------------------------------------------

function _FORTRAN_integer_type(T::Type; msg=true)

    c = T == Bool ? 'L' : T == UInt8 ? 'B' : T == Int16 ? 'I' :
        T == UInt16 ? 'I' : T == Int32 ? 'J' : T == UInt32 ? 'J' :
        T == Int64 ? 'K' : T == UInt64 ? 'K' : '-'

    c == '-' && msg && println("$T: datatype not part of the FITS standard")

    return c

end
# ------------------------------------------------------------------------------
function _FORTRAN_real_type(T::Type; msg=true)

    c = T == Float32 ? 'E' : T == Float64 ? 'D' : '-'

    c == '-' && msg && println("$T: datatype not part of the FITS standard")

    return c

end
# ------------------------------------------------------------------------------
function _FORTRAN_complex_type(T::Type; msg=true)

    c = T == ComplexF32 ? 'C' : T == ComplexF64 ? 'M' : '-'

    c == '-' && msg && println("$T: datatype not part of the FITS standard")

    return c

end

# ------------------------------------------------------------------------------
#                        FORTRAN_eltype_char(T::Type)
# ------------------------------------------------------------------------------

@doc raw"""
    FORTRAN_eltype_char(T::Type)

FORTRAN datatype description character for julia type `T`: 

Bool => 'L', UInt8 => 'B', Int16 => 'I', UInt16 => 'I', Int32 => 'J', 
UInt32 => 'J', Int64 => 'K', UInt64 => 'K', Float32 => 'E', Float64 => 'D', 
ComplexF32 => 'C', ComplexF64 => 'M'

The character '-' is returned for non-primitive FORTRAN datatypes and for 
primitive datatypes not included in the FITS standard.

#### Examples:
```
julia> T = Type[Bool, Int8, UInt8, Int16, UInt16, Int32, UInt32, Int64, UInt64];

julia> print([FORTRAN_eltype_char(T[i]) for i ∈ eachindex(T)])
Int8: datatype not part of the FITS standard
['L', '-', 'B', 'I', 'I', 'J', 'J', 'K', 'K']

julia> T = [Float16, Float32, Float64, ComplexF32, ComplexF64];

julia> print([FORTRAN_eltype_char(T[i]) for i ∈ eachindex(T)])
Float16: datatype not part of the FITS standard
['-', 'E', 'D', 'C', 'M']

julia> T = [String, Vector{Char}, FITS];

julia> print([FORTRAN_eltype_char(T[i]) for i ∈ eachindex(T)])
Vector{Char}: not a FORTRAN datatype
FITS: not a FORTRAN datatype
['A', 'A', '-', '-']
```
"""
function FORTRAN_eltype_char(T::Type; msg=true)

    if T <: Union{Char,String}
        o = 'A'
    elseif T <: Integer
        o = _FORTRAN_integer_type(T; msg)
    elseif T <: Real
        o = _FORTRAN_real_type(T; msg)
    elseif T <: Complex
        o = _FORTRAN_complex_type(T; msg)
    else
        o = '-'
        msg && println("$T: not a FORTRAN datatype")
    end

    return o

end
# ------------------------------------------------------------------------------
function FORTRAN_fits_table_string(field::Any, tform::Vector{String})

    strcol = string.(field)
    fmt = cast_FORTRAN_format.(tform)


    for j ∈ eachindex(field)
        x = fmt[j].char
        w = fmt[j].width
        d = fmt[j].ndec

        if x == 'I'
            if eltype(field) == Bool
                strcol[j] = field[j] ? "1" : "0" #  "T" : "F"
            end
        elseif x == 'F'
            n = [w - d - 1, d]
            k = findfirst('.', strcol[j])
            s = [strcol[j][1:k-1], strcol[j][k+1:end]]
            Δ = n .- length.(s)
            if Δ[1] > 0
                s[1] = repeat(' ', Δ[1]) * s[1]
            end
            if Δ[2] > 0
                s[2] = s[2] * repeat('0', Δ[2])
            end
            strcol[j] = s[1] * '.' * s[2]
        elseif x == 'E'
            k = findfirst('.', strcol[j])
            l = findfirst('e', strcol[j])
            s = [strcol[j][1:k-1], strcol[j][k+1:l-1], strcol[j][l+1:end]]
            Δ = d - length(s[2])
            if Δ > 0
                s[2] = s[2] * repeat('0', Δ)
            end
            strcol[j] = s[1] * '.' * s[2] * 'E' * s[3]
        elseif x == 'D'
            k = findfirst('.', strcol[j])
            l = findfirst('e', strcol[j])
            s = [strcol[j][1:k-1], strcol[j][k+1:l-1], strcol[j][l+1:end]]
            Δ = d - length(s[2])
            if Δ > 0
                s[2] = s[2] * repeat('0', Δ)
            end
            strcol[j] = s[1] * '.' * s[2] * 'D' * s[3]
        else
            strcol[j] = strcol[j]
        end
    end

    return strcol

end