# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                            read_IO.jl
#                        Jook Walraven 19-03-2023
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                     IORead(filnam::String)
# 
#   - read filnam from disc 
#   - test for integral number of blocks of 2880 bytes/block
# ------------------------------------------------------------------------------  

function IORead(filnam::String)

    o = IOBuffer()

    nbytes = Base.write(o, Base.read(filnam))   # number of bytes
    nblock = nbytes ÷ 2880                      # number of blocks 
    remain = nbytes % 2880                      # remainder (incomplete block)

    remain > 0 && Base.throw(FITSError(msgErr(6)))

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

function _fits_type(bitpix::Int)

    T = bitpix == 8 ? UInt8 :
        bitpix == 16 ? Int16 :
        bitpix == 32 ? Int32 :
        bitpix == 64 ? Int64 :
        bitpix == -32 ? Float32 :
        bitpix == -64 ? Float64 : Base.throw(FITSError(msgErr(42)))

    return T

end

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

function _read_table_data(o::IO, hduindex::Int)

    ptr = _data_pointer(o)

    h = _read_header(o, hduindex) # FITS_header object

    Base.seek(o, ptr[hduindex])
    lrow = h.card[h.map["NAXIS1"]].value # row length in bytes
    nrow = h.card[h.map["NAXIS2"]].value # number of rows
    tfields = h.card[h.map["TFIELDS"]].value
    tbcol = [h.card[h.map["TBCOL$i"]].value for i = 1:tfields]

    Base.seek(o, ptr[hduindex])

    data = [String(Base.read(o, lrow)) for i = 1:nrow]

    itr = [tbcol[i]:tbcol[i+1]-1 for i=1:tfields-1]
    itr = push!(itr, tbcol[tfields]:lrow)

    data = [[data[i][itr[j]] for j ∈ eachindex(itr)] for i = 1:nrow]
    data = [join(data[i]) for i = 1:nrow]

    return data

end

function _read_bintable_data(o::IO, hduindex::Int)

    ptr = _data_pointer(o)

    h = _read_header(o, hduindex) # FITS_header object

    Base.seek(o, ptr[hduindex])
    lrow = h.card[h.map["NAXIS1"]].value # row length in bytes
    nrow = h.card[h.map["NAXIS2"]].value # number of rows
    tfields = h.card[h.map["TFIELDS"]].value
    tform = [h.card[h.map["TFORM$i"]].value for i = 1:tfields]

    Base.seek(o, ptr[hduindex])

    data = [String(Base.read(o, lrow)) for i = 1:nrow]

    itr = [tbcol[i]:tbcol[i+1]-1 for i = 1:tfields-1]
    itr = push!(itr, tbcol[tfields]:lrow)

    data = [[data[i][itr[j]] for j ∈ eachindex(itr)] for i = 1:nrow]
    data = [join(data[i]) for i = 1:nrow]

    return data

end

function _read_tform(tform::String)

    x = collect(tform)

    return 

end