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
#                            read_IO.jl
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                     IORead(filnam::String)
# 
#   - read filnam from disc 
#   - test for integral number of blocks of 2880 bytes/block
# ------------------------------------------------------------------------------  

function IORead(filnam::String; msg=false)

    o = IOBuffer()

    nbytes = Base.write(o, Base.read(filnam))   # number of bytes
    nblock = nbytes ÷ 2880                      # number of blocks 
    remain = nbytes % 2880                      # remainder (incomplete block)

    remain > 0 && Base.throw(FITSError(msgErr(6)))

    if msg
        println("===========================================")
        println("IORead:") 
        println("-------------------------------------------")
        for i=1:2880:nbytes     
            str = String(o.data[i:i+7])                                                                                                                                                                                    
            str ∈ ["SIMPLE  ", "XTENSION"] && println("$i: " * str)                                                                                                                                            
        end
        println("-------------------------------------------")
    end

    return o

end

# ------------------------------------------------------------------------------
#                   _read_header(o::IO, hduindex::Int)
#
#   - reads non-blank records from header 
#   - stop after "END" record is reached
# ------------------------------------------------------------------------------

function _read_header(o::IO, hduindex::Int)

    ptrhdu = _hdu_pointer(o)
    ptrdat = _data_pointer(o)

    nhdu = length(ptrhdu)

    hduindex ≤ nhdu || error("hduindex ≤ $(nhdu) required")

    Base.seek(o, ptrhdu[hduindex])

    record::Vector{String} = []

    for i = (ptrhdu[hduindex]÷80+1):(ptrdat[hduindex]÷80)
        rec = String(Base.read(o, 80))
        Base.push!(record, rec)
    end
    
    return cast_FITS_header(record)

end

# ------------------------------------------------------------------------------
#                   _read_hdu(o::IO, hduindex::Int)
#
#   - reads non-blank records from header 
#   - stop after "END" record is reached
# ------------------------------------------------------------------------------  

function _read_hdu(o::IO, hduindex::Int)  # read data using header information

    h = _read_header(o, hduindex) #  FITS_header

    hdutype = h.card[1].keyword == "XTENSION" ? h.card[1].value : "'PRIMARY '"
    hdutype = Base.strip(hdutype)
    hdutype = Base.Unicode.uppercase(hdutype)

    if     hdutype == "'PRIMARY '"
        data = _read_image_data(o, hduindex)
    elseif hdutype == "'IMAGE   '"
        data = _read_image_data(o, hduindex)
    elseif hdutype == "'TABLE   '"
        data = _read_table_data(o, hduindex)
    elseif hdutype == "'BINTABLE'"
        data = _read_bintable_data(o, hduindex)
    else
        Base.throw(FITSError(msgErr(25)))
    end

    dataobject = FITS_dataobject(hdutype, data)

    return FITS_HDU(hduindex, h, dataobject)

end

# ------------------------------------------------------------------------------
#                   _read_image_data(o::IO, hduindex::Int)
#
#   - reads image data in accordance with header information
# ------------------------------------------------------------------------------  

function _fits_type(bitpix::Int)

    T = bitpix == 8 ? UInt8 :
        bitpix == 16 ? Int16 :
        bitpix == 32 ? Int32 :
        bitpix == 64 ? Int64 :
        bitpix == -32 ? Float32 :
        bitpix == -64 ? Float64 : Base.throw(FITSError(msgErr(42)))

    return T

end
# ------------------------------------------------------------------------------
function _read_image_data(o::IO, hduindex::Int)

    header = _read_header(o, hduindex)            # FITS_header object

    ptrdata = _data_pointer(o)
    Base.seek(o, ptrdata[hduindex])
    
    i = get(header.map, "NAXIS", 0)
    ndims = header.card[i].value

    if ndims > 0                           # e.g. dims=(512,512,1)
        dims = Core.tuple([header.card[i+n].value for n = 1:ndims]...)      
        ndata = Base.prod(dims)            # number of data points
        i = get(header.map, "BITPIX", 0)
        bitpix = header.card[i].value
        T = _fits_type(bitpix)
        data = [Base.read(o, T) for n = 1:ndata]
        data = Base.ntoh.(data)  # change from network to host ordering
        # data = data .+ T(bzero)
        # remove mapping between UInt-range and Int-range (if applicable):
        data = fits_remove_offset(data, header)
        data = Base.reshape(data, dims)
    else
        data = Any[]
    end

    return data

end

# ------------------------------------------------------------------------------
#                   _read_table_data(o::IO, hduindex::Int)
#
#   - reads table data in accordance with header information
# ------------------------------------------------------------------------------  

function _read_table_data(o::IO, hduindex::Int)

    ptr = _data_pointer(o)

    h = _read_header(o, hduindex) # FITS_header object

    Base.seek(o, ptr[hduindex])
    lrow = h.card[h.map["NAXIS1"]].value # row length in bytes
    nrow = h.card[h.map["NAXIS2"]].value # number of rows

    Base.seek(o, ptr[hduindex])

    data = [String(Base.read(o, lrow)) for i = 1:nrow]

    return data

end

# ------------------------------------------------------------------------------
#                   _read_bintable_data(o::IO, hduindex::Int)
#
#   - reads bintable data in accordance with header information
# ------------------------------------------------------------------------------  

function _t_char(str::String)

    n = 1
    while !isletter(str[n])
        n += 1
    end

    x = str[n:end]

    return x

end
# ------------------------------------------------------------------------------
function _repeat(str::String)

    s = strip(str, ['\'', ' '])

    r = n = 1
    while isnumeric(s[n])
        r = parse(Int, s[1:n])
        n += 1
    end

    return r

end
# ------------------------------------------------------------------------------
function r_correct!(r::Vector{Int}, char::Vector{Char})

    for i ∈ eachindex(r)
        r[i] = iszero(r[i]) ? r[i] : char == 'P' ? 2 : char == 'Q' ? 2 : r[i]
    end

    return r

end
# ------------------------------------------------------------------------------
function _set_type(x::Char, bzero::Real)

    X = ['L', 'B', 'I', 'J', 'K', 'A', 'E', 'D', 'C', 'M', 'P', 'Q', 'X']

    x ∈ X || return Base.throw(FITSError(msgErr(44))) # illegal datatype

    if x ∈ ['B', 'I', 'J', 'K']
        T = x == 'B' ? UInt8 : x == 'I' ? Int16 :
            x == 'J' ? Int32 : x == 'K' ? Int64 : nothing
    elseif x ∈ ['E', 'D', 'C', 'M']
        T = x == 'E' ? Float32 : x == 'D' ? Float64 :
            x == 'C' ? ComplexF32 : x == 'M' ? ComplexF64 : nothing
    elseif x ∈ ['P', 'Q']
        T = x == 'P' ? UInt32 : 
            x == 'Q' ? UInt64 : nothing
    elseif x == 'X'
        T = Int
    else
        T = UInt8
    end

    return T

end
# ------------------------------------------------------------------------------
function _read_indexed_keyword(h::FITS_header, key::String, n::Int, default)

    idx = [get(h.map, key * "$i", 0) for i = 1:n]
   
    o = [idx[i] > 0 ? h.card[idx[i]].value : default for i = 1:n]

    return o

end

function _remove_offset(data)

    t = eltype(data)

    t ∈ (UInt8, Int16, Int32, Int64) || return data

    t == UInt8 && return Int8.(Int.(data) .- 128)
    t == Int16 && return UInt16.(Int.(data) .+ 32768)
    t == Int32 && return UInt32.(Int.(data) .+ 2147483648)
    t == Int64 && return UInt64.(Int128.(data) .+ 9223372036854775808)

    # workaround for InexactError:trunc(Int64, 9223372036854775808)

end
# ------------------------------------------------------------------------------
function _read_bintable_data(o::IO, hduindex::Int)

    ptr = _data_pointer(o)

    h = _read_header(o, hduindex) # FITS_header object

    Base.seek(o, ptr[hduindex])
    lrow = h.card[h.map["NAXIS1"]].value # row length in bytes
    nrow = h.card[h.map["NAXIS2"]].value # number of rows
    tfields = h.card[h.map["TFIELDS"]].value

    tform = _read_indexed_keyword(h, "TFORM", tfields, "'U'")
    tchar = [_t_char(tform[i])[1] for i = 1:tfields]
    tuple = [_t_char(tform[i])[2:6] == "tuple" for i = 1:tfields]

    r = [_repeat(tform[i]) for i = 1:tfields]

    tscal = _read_indexed_keyword(h, "TSCAL", tfields, 1.0)
    tzero = _read_indexed_keyword(h, "TZERO", tfields, 0.0)
    tdims = _read_indexed_keyword(h, "TDIM", tfields, nothing)
    tdisp = _read_indexed_keyword(h, "TDISP", tfields, nothing)

    Base.seek(o, ptr[hduindex])

    data = Vector{Any}(undef, nrow)
    for i = 1:nrow
        data[i] = Any[]
        row = Any[]
        for j = 1:tfields
            t = _set_type(tchar[j], tzero[j])
            val = []
            for k = 1:r[j]
                a = Base.ntoh(Base.read(o, t)) # change from network to host ordering
                a = iszero(tzero[j]) ? a : _remove_offset(a)
                push!(val, a)
            end
            append!(row, val)
        end
        append!(data[i], row)
    end

    o = Any[]

    for i = 1:nrow
        k = 0 # extra variable to handle bitvectors
        row = Any[]
        for j = 1:tfields
            n = r[j]
            if n > 0
                if tchar[j] == 'A'
                    if isnothing(tdims[j]) && !tuple[j]
                        if n > 1
                            d = join(Char.(data[i][k+1:k+n]))
                        else
                            d = Char(data[i][k+1])
                        end
                    else
                        d = Char.(data[i][k+1:k+n])
                        d = tuple[j] ? d : reshape(d, tdims[j])
                    end
                    k += n
                elseif tchar[j] == 'L'
                    if n > 1
                        d = Bool.(data[i][k+1:k+n])
                        d = isnothing(tdims[j]) ? d : reshape(d, tdims[j])
                    else
                        d = Bool(data[i][k+1])
                    end
                    k += n
                elseif tchar[j] == 'X'
                    if n > 1
                        d = [data[i][k+m] for m = 1:n]
                        d = bitstring.(d)
                        p = findfirst.("1", d)
                        d = [d[m][p[m].start:end] for m = 1:n]
                        d = collect.(d)
                        d = [BitVector(parse.(Int, d[m])) for m = 1:n]
                        d = isnothing(tdims[j]) ? d : reshape(d, tdims[j])
                    else
                        d = data[i][k+1]
                        d = bitstring(d)
                        p = findfirst("1", d)
                        d = d[p.start:end]
                        d = collect(d)
                        d = BitVector(parse.(Int, d))
                    end
                    k += n
                elseif (tchar[j] == 'P') ⊻ (tchar[j] == 'Q')
                    error("variable-length arrays not yet implemented")
                    #    push!(row, Tuple([data[i][k+m] for m = 1:n])) 
                    #    k += n
                else
                    if n > 1
                        d = [data[i][k+m] for m = 1:n]
                        d = isnothing(tdims[j]) ? d : reshape(d, tdims[j])
                    else
                        d = data[i][k+1]
                    end
                    k += n
                end
                d = tuple[j] ? Tuple(d) : d
                push!(row, d)
            end
        end
        push!(o, row)
    end

    for i = 1:nrow
        for j = 1:tfields
            V = typeof(o[1][j])
            T = typeof(o[i][j])
            T ≠ V && Base.throw(FITSError(msgErr(46)))
        end
    end

    return o

end