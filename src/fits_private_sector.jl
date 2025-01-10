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
#                          fits_private_sector.jl
# ------------------------------------------------------------------------------

using Dates

function _fits_dims(str::SubString)

    s = strip(str, ['\'', ' ', '(', ')'])

    return s[end] == ',' ? Tuple(parse(Int, s[1:end-1])) : Tuple(parse.(Int, split(s, ',')))

end

function _fits_parse(cardindex::Int, str::String)

    T = Float32
    s = Base.strip(str)
    c = Base.collect(s)
    ℓ = Base.length(s)

    Base.length(s) == 0 && return 0

    d = [Base.Unicode.isdigit(c[i]) for i ∈ Base.eachindex(c)]  # d: digits
    p = [Base.Unicode.ispunct(c[i]) for i ∈ Base.eachindex(c)]  # p: punctuation

    s[1] == '\'' && ℓ == 1 && return str
    s[1] == '\'' && (s[2] ≠ '(') && return str
    s[1] == '-' && (d[1] = true) && (p[1] = false)      # change leading sign into digit (for type parsing only)
    s[1] == '+' && (d[1] = true) && (p[1] = false)      # change leading sign into digit (for type parsing only)

    a = p .== d                                         # a: other non-digit or punctuation characters

    ia = [i for i ∈ Base.eachindex(a) if a[i] == 1]     # ia: indices of nonzero elements of a
    ip = [i for i ∈ Base.eachindex(p) if p[i] == 1]     # ip: indices of nonzero elements of p

    sd = Base.sum(d)                                    # sd: number of digits
    sp = Base.sum(p)                                    # sp: number of punctuation characters
    sa = Base.sum(a)                                    # sa: number of other non-digit or punctuation characters

    #println("sd = $(sd), sp = $(sp), sa = $(sa)")

    E = ['E', 'D', 'e', 'p']

    sd == ℓ && return s ≠ "9223372036854775808" ? Base.parse(Int, s) : 9223372036854775808
    sp == 5 && s[ip[2]] == '(' && s[ip[3]] == ',' && s[ip[4]] == ')' && return _fits_dims(s)
    sa >= 2 && return str
    sp >= 3 && return str
    sa == 1 && s == "T" && return true
    sa == 1 && s == "F" && return false
    sa == 0 && sp == 1 && s[ip[1]] == '.' && return Base.parse(T, s)
    sp == 0 && sa == 1 && s[ia[1]] ∈ E && return Base.parse(T, s)
    sp == 1 && s[ip[1]] == '-' && s[ip[1]-1] ∈ E && return Base.parse(T, s)
    sp == 1 && s[ip[1]] == '.' && s[ia[1]] ∈ E && ip[1] < ia[1] && return Base.parse(T, s)
    sp == 2 && s[ip[1]] == '.' && s[ip[2]] == '-' && s[ip[2]-1] ∈ E && ip[1] < ia[1] && return Base.parse(T, s)

    return error("strError: cardindex $(cardindex), string $(str): parsing case not resolved")

end

function _isascii_text(text::String)::Bool

    return !convert(Bool, sum(.!(32 .≤ Int.(collect(text)) .≤ 126)))

end

# ==============================================================================
#                      _format_keyword(key; abr=false)::String
# ------------------------------------------------------------------------------

function _format_keyword(key::String; abr=false)::String

    key = Base.Unicode.uppercase(Base.strip(key))
    l = length(key)
    l ≤ 8 || Base.throw(FITSError(msgErr(10))) # exceeds 8 characters

    v = Int.(collect(key))
    o = (48 .≤ v .≤ 57) .| (65 .≤ v .≤ 90) .| (v .== 45) .| (v .== 95)

    ispermitted = !convert(Bool, sum(.!o))

    ispermitted || Base.throw(FITSError(msgErr(24))) # illegal character

    l > 5 || return key

    key = !isnumeric(key[6]) ? key : abr ? (key[1:5] * "n") : key

    return key

end

# ==============================================================================
#                      _format_hdutype(hdutype::String;)::String
# ------------------------------------------------------------------------------

function _format_hdutype(hdutype::String)::String

    hdutype = Base.strip(hdutype)
    hdutype = hdutype[1] == ''' ? hdutype[2:end] : hdutype
    hdutype = Base.strip(hdutype)
    hdutype = Base.Unicode.uppercase(hdutype)
    hdutype = hdutype[end] == ''' ? hdutype[1:end-1] : hdutype
    hdutype = "'" * Base.rpad(hdutype, 8) * "'"

    return hdutype

end

# ==============================================================================
#                      _format_value(val::Any)::String
# ------------------------------------------------------------------------------

function _format_value_numeric(val::Real)

    val = typeof(val) != Bool ? string(val) : val == true ? "T" : "F"

    return [lpad(val, 20)]

end
# ------------------------------------------------------------------------------

function _format_value_datetime(val)

    return [rpad("'" * string(val) * "'", 20)]

end
# ------------------------------------------------------------------------------

function _format_value_string(val::AbstractString, nocomment=true)

    isasciitext = _isascii_text(val)
    isasciitext || Base.throw(FITSError(msgErr(23)))

    v = (strip(val))
    n = length(v) ÷ 67 + 1

    if nocomment
        if length(v) ≤ 18
            o = [rpad("'" * v * "'", 20)]
        elseif length(v) ≤ 68
            o = ["'" * v * "'"]
        else
            o = ["'" * v[2+68(i-1)-i:67i] * "&'" for i = 1:n-1]
            push!(o, "'" * v[2+68(n-1)-n:end])
        end
    else
        if length(v) ≤ 18
            o = [rpad("'" * v * "'", 20)]
        elseif length(v) ≤ 67
            o = ["'" * v * "&'"]
        else
            o = ["'" * v[2+68(i-1)-i:67i] * "&'" for i = 1:n-1]
            push!(o, "'" * v[2+68(n-1)-n:end] * "&'")
        end
    end

    return o

end
# ------------------------------------------------------------------------------

function _format_value(val::Any, nocomment=true)

    T = typeof(val)

    T <: AbstractChar && Base.throw(FITSError(msgErr(15)))
    T <: AbstractString && length(val) ≤ 1 && Base.throw(FITSError(msgErr(14)))

    o = T <: Real ? _format_value_numeric(val) :
        T <: AbstractString ? _format_value_string(val, nocomment) :
        T <: Date ? _format_value_datetime(val) :
        T <: Time ? _format_value_datetime(val) :
        T <: DateTime ? _format_value_datetime(val) :
        Base.throw(FITSError(msgErr(16)))  # Error: illegal keyword value type

    return o

end

# ==============================================================================
#                      _format_comment(com::String)::String
# ------------------------------------------------------------------------------

function _format_comment(comment::String; offset=0, linesize=65)

    com = collect(repeat(' ', offset) * " " * strip(comment) * " ")
    pos = findall(x -> x == ' ', collect(com)) .- 1
    len = prepend!([pos[i] - pos[i-1] for i ∈ indices(pos, 2)], 1)
    out = []

    n = 1
    while n < 25
        i = findfirst(x -> x > linesize * n, pos)
        !isnothing(i) || break
        spaces = n * linesize - pos[i-1]
        if len[i] > linesize
            insert!(com, n * linesize + 1, ' ')
            for j ∈ indices(pos, i - 1)
                pos[j] += 1
            end
            insert!(pos, i, n * linesize)
            insert!(len, i, spaces)
            len[i] -= spaces
        else
            for s = 1:spaces
                insert!(com, pos[i-1] + 1, ' ')
            end
            for j ∈ indices(pos, i - 1)
                pos[j] += spaces
            end
        end
        push!(out, join(com[(n-1)*linesize+1:n*linesize]))
        n += 1
    end
    push!(out, rpad(join(com[(n-1)*linesize+1:end]), 65))

    for n ∈ indices(out, dropfirst=true)
        out[n] = "CONTINUE  '&' /" * out[n]
    end

    return out

end

# ==============================================================================
#            _format_record(key::String, val::Any, com::String)
# ------------------------------------------------------------------------------

function _format_record(key::String, val::Any, com::String)

    nocomment = iszero(length(com)) ? true : false
    key = _format_keyword(key)
    key = rpad(key, 8)

    key == "       " && return [repeat(' ', 80)]
    key == "END    " && return ["END" * repeat(' ', 77)]

    v = _format_value(val, nocomment)
    c = _format_comment(com)
    n = length(v)

    if (length(v[1]) == 20) & (length(com) ≤ 47)
        return [rpad(key * "= " * v[1] * " / " * strip(com), 80)]
    elseif nocomment
        v[1] = key * "= " * v[1]
        v[2:end] = "CONTINUE  " .* v[2:end]
        v[end] = n > 1 ? v[end] * "'" : v[end]
        v[end] = rpad(v[end], 80)
        return v
    else
        if isone(n)
            if length(v[1]) + length(com) < 69
                o = key * "= " * v[1][1:end-2] * "' / " * strip(c[1])
                o = [rpad(o, 80)]
            else
                offset = length(v[1])
                o = _format_comment(com; offset)
                o[1] = rpad(key * "= " * v[1] * " /" * o[1][offset+1:end], 80)
            end
        else
            offset = length(v[end])
            o = _format_comment(com; offset)
            v[1] = key * "= " * v[1][1:end-2] * "&'"
            v[2:end-1] = "CONTINUE  " .* v[2:end-1]
            o[1] = rpad("CONTINUE  " * v[end] * " /" * o[1][offset+1:end], 80)
            o = vcat(v[1:end-1], o)
        end
        return o
    end

end

# ------------------------------------------------------------------------------
#                  _append_blanks!(records::Vector{String})
# ------------------------------------------------------------------------------  

function _append_blanks!(records::Vector{String})

    nrec = length(records)

    nrec > 0 || Base.throw(FITSError(msgErr(13))) # "END keyword not present

    remainder = nrec % 36
    nblanks = remainder > 0 ? 36 - remainder : 0

    if nblanks > 0
        blanks = [Base.repeat(' ', 80) for i = 1:nblanks]
        append!(records, blanks)
    end

    return records

end

# ------------------------------------------------------------------------------
#                  _rm_blanks!(records::Vector{String})
# ------------------------------------------------------------------------------  

function _rm_blanks!(record::Vector{String})         # remove blank records

    nrec = length(record)

    i = 1
    while record[i] ≠ "END" * repeat(' ', 77)
        i += 1
    end

    while i < nrec 
        Base.pop!(record) # remove records trailing after "END"  
        i += 1
    end

    return record

end
