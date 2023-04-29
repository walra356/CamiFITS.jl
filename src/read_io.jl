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

    ptrhdu = _hdu_pointers(o)
    ptrdat = _data_pointers(o)

    Base.seek(o, ptrhdu[hduindex])

    itr = (ptrhdu[hduindex] ÷ 80 + 1) : (ptrdat[hduindex] ÷ 80)

    record::Array{String,1} = []

    for i = itr
        rec = String(Base.read(o, 80))
        Base.push!(record, rec)
    end

    return cast_FITS_header(record) #, hduindex)

end

# ------------------------------------------------------------------------------
#                   _read_data(o::IO, hduindex::Int)
#
#   - reads non-blank records from header 
#   - stop after "END" record is reached
# ------------------------------------------------------------------------------  

function _read_data(o::IO, hduindex::Int)                   # read all data using header information

    h = _read_header(o, hduindex) #  FITS_header

    hdutype = h.card[1].keyword == "XTENSION" ? h.card[1].value : "'PRIMARY '"
    hdutype = Base.strip(hdutype[2:9])

    hdutype == "PRIMARY" && return _read_PRIMARY_data(o, hduindex)
    hdutype == "IMAGE" && return _read_IMAGE_data(o, hduindex)
    hdutype == "TABLE" && return _read_TABLE_data(o, hduindex)
    hdutype == "BINTABLE" && return _read_BINTABLE_data(o, hduindex)

    return error("strError: '$hdutype': not a 'FITS standard extension'")

end

function _read_PRIMARY_data(o::IO, hduindex::Int)             # read all data using header information

    h = _read_header(o, hduindex)            # FITS_header object

    ptrdata = _data_pointers(o)
    Base.seek(o, ptrdata[hduindex])

    i = get(h.map, "NAXIS", 0)
    ndims = h.card[i].value

    if ndims > 0
        dims = Core.tuple([h.card[i+n].value for n = 1:ndims[1]]...)      # e.g. dims[1]=(512,512,1)
        ndata = Base.prod(dims)                                                     # number of data points
        i = get(h.map, "BITPIX", 0)
        nbits = h.card[i].value
        i = get(h.map, "BZERO", 0)
        bzero = h.card[i].value
        E = _fits_eltype(nbits, bzero)
        data = [Base.read(o, E) for n = 1:ndata]
        data = Base.ntoh.(data)                            # change from network to host ordering
        data = data .+ E(bzero)                            # offset from Int to UInt
        data = Base.reshape(data, dims)
    else
        data = Any[]
    end

    return FITS_data = cast_FITS_data("PRIMARY", data) # (hduindex, "PRIMARY", data)

end

function _read_IMAGE_data(o::IO, hduindex::Int)             # read all data using header information

    h = _read_header(o, hduindex) # FITS_header object

    ptrdata = _data_pointers(o)
    Base.seek(o, ptrdata[hduindex])

    i = get(h.map, "NAXIS", 0)
    ndims = h.key[i].val

    if ndims > 0

        dims = Core.tuple([h.card[i+n].value for n = 1:ndims[1]]...)      # e.g. dims[1]=(512,512,1)
        ndata = Base.prod(dims)                                                     # number of data points
        i = get(h.map, "BITPIX", 0)
        nbits = h.card[i].value
        i = get(h.map, "NAXIS", 0)
        bzero = h.card[i].value
        E = _fits_eltype(nbits, bzero)
        data = [Base.read(o, E) for n = 1:ndata]
        data = Base.ntoh.(data)                            # change from network to host ordering
        data = data .+ E(bzero)                            # offset from Int to UInt
        data = Base.reshape(data, dims)
    else
        data = Any[]
    end

    return FITS_data = _cast_data("IMAGE", data) # (hduindex, "IMAGE", data)

end

function _read_TABLE_data(o::IO, hduindex::Int)

    ptr = _data_pointers(o)

    h = _read_header(o, hduindex) # FITS_header object

    Base.seek(o, ptr[hduindex])

    i = get(h.map, "NAXIS1", 0)
    lrecs = h.card[i].value
    i = get(h.map, "NAXIS2", 0)
    nrecs = h.card[i].value

    # dicts = FITS_header.dict
    # lrecs = Base.get(dicts, "NAXIS1", 0)
    # nrecs = Base.get(dicts, "NAXIS2", 0)

    Base.seek(o, ptr[hduindex])

    data = [String(Base.read(o, lrecs)) for i = 1:nrecs]

    return FITS_data = cast_FITS_data(hduindex, "TABLE", data)

end