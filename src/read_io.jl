# .................................. read-io (header sector) .......................................................

function _fits_read_IO(filename::String)

    Base.Filesystem.isfile(filename) || error("Error: $filename: file not found in current directory")

    a = _validate_FITS_name(filename)

    o = IOBuffer()

    nbytes = Base.write(o,Base.read(filename))            # number of bytes
    nblock = nbytes ÷ 2880                                # number of blocks (2880 bytes/block)
    remain = nbytes % 2880                                # remainder (incomplete block)

    remain > 0 && return error("FitsError: format requires integer number of blocks of 2880 bytes")

    return o

end

function _read_header(o::IO, hduindex::Int)               # reads non-blank records from header

    ptr = _hdu_pointers(o)

    header::Array{String,1} = []
    record = " "
    Base.seek(o, ptr[hduindex])

    while record ≠ "END" * Base.repeat(" ",77)
        record = String(Base.read(o,80))
        Base.push!(header,record)
    end

    return FITS_header = _cast_header(header, hduindex)

end

# .................................. read-io (data sector) .......................................................

function _read_data(o::IO, hduindex::Int)                   # read all data using header information

    FITS_header = _read_header(o, hduindex)

      dicts = FITS_header.dict
    hdutype = Base.get(dicts,"XTENSION", "'PRIMARY '")
    hdutype = Base.strip(hdutype[2:9])

    hdutype == "PRIMARY"  && return _read_PRIMARY_data(o, hduindex)
    hdutype == "IMAGE"    && return _read_IMAGE_data(o, hduindex)
    hdutype == "TABLE"    && return _read_TABLE_data(o, hduindex)
    hdutype == "BINTABLE" && return _read_BINTABLE_data(o, hduindex)

    return error("FitsError: '$hdutype': not a 'FITS standard extension'")

end

function _read_PRIMARY_data(o::IO, hduindex::Int)             # read all data using header information

    ptr = _data_pointers(o)                                 # ptrd: start-of-data pointers

    FITS_header = _read_header(o, hduindex)

    Base.seek(o,ptr[hduindex])

    dicts = FITS_header.dict
    ndims = Base.get(dicts,"NAXIS", 0)

    if ndims > 0
         dims = Core.tuple([Base.get(dicts,"NAXIS$n", 0) for n=1:ndims[1]]...)      # e.g. dims[1]=(512,512,1)
        ndata = Base.prod(dims)                                                     # number of data points
        nbits = Base.get(dicts,"BITPIX", 0)
        bzero = Base.get(dicts,"BZERO", 0.0)                # default 0.0 by convention (also for unsigned Ints)
            E = _fits_eltype(nbits, bzero)
         data = [Base.read(o,E) for n=1:ndata]
         data = Base.ntoh.(data)                            # change from network to host ordering
         data = data .+ E(bzero)                            # offset from Int to UInt
         data = Base.reshape(data, dims)
    else
        data = []
    end

    return FITS_data = _cast_data(hduindex, "PRIMARY", data)

end

function _read_IMAGE_data(o::IO, hduindex::Int)             # read all data using header information

    ptr = _data_pointers(o)                                 # ptrd: start-of-data pointers

    FITS_header = _read_header(o, hduindex)

    Base.seek(o,ptr[hduindex])

    dicts = FITS_header.dict
    ndims = Base.get(dicts,"NAXIS", 0)

    if ndims > 0
         dims = Core.tuple([Base.get(dicts,"NAXIS$n", 0) for n=1:ndims[1]]...)      # e.g. dims[1]=(512,512,1)
        ndata = Base.prod(dims)                                                     # number of data points
        nbits = Base.get(dicts,"BITPIX", 0)
        bzero = Base.get(dicts,"BZERO", 0.0)                # default 0.0 by convention (also for unsigned Ints)
            E = _fits_eltype(nbits, bzero)
         data = [Base.read(o,E) for n=1:ndata]
         data = Base.ntoh.(data)                            # change from network to host ordering
         data = data .+ E(bzero)                            # offset from Int to UInt
         data = Base.reshape(data, dims)
    else
        data = []
    end

    return FITS_data = _cast_data(hduindex, "IMAGE", data)

end

function _read_TABLE_data(o::IO, hduindex::Int)

    ptr = _data_pointers(o)

    FITS_header = _read_header(o, hduindex)

    dicts = FITS_header.dict
    lrecs = Base.get(dicts,"NAXIS1", 0)
    nrecs = Base.get(dicts,"NAXIS2", 0)

    Base.seek(o,ptr[hduindex])

    data = [String(Base.read(o,lrecs)) for i=1:nrecs]

    return FITS_data = _cast_data(hduindex, "TABLE", data)

end
