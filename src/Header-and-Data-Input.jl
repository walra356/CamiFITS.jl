# ....................... Header and Data input ..................

function _PRIMARY_input(dataobject::FITS_data)

    dataobject.hdutype == "PRIMARY" || error("FitsError: FITS_data is not of hdutype 'PRIMARY'")

    r::Array{String,1} = []

         E = Base.eltype(dataobject.data)
    nbytes = E ≠ Any ? sizeof(E) : 0
     nbits = 8 * nbytes
    bitpix = E <: AbstractFloat ? -abs(nbits) : nbits
    bitpix = Base.lpad(bitpix,20)
      dims = Base.size(dataobject.data)
     ndims = dims == (0,) ? 0 : Base.length(dims)
     naxis = Base.lpad(ndims,20)
      dims = ndims > 0 ? [Base.lpad(dims[i],20) for i=1:ndims] : 0
     bzero = Base.lpad(string(_fits_bzero(E)),20)

    incl = ndims > 0 ? true : false

           Base.push!(r,"SIMPLE  =                    T / file does conform to FITS standard             ")
    incl ? Base.push!(r,"BITPIX  = "   * bitpix  *    " / number of bits per data pixel                  ") : 0
           Base.push!(r,"NAXIS   = "   * naxis   *    " / number of data axes                            ")
    incl ? [Base.push!(r,"NAXIS$i  = " * dims[i] *    " / length of data axis " * rpad(i,27) ) for i=1:ndims] : 0
    incl ? Base.push!(r,"BZERO   = "   * bzero   *    " / offset data range to that of unsigned integer  ") : 0
    incl ? Base.push!(r,"BSCALE  =                  1.0 / default scaling factor                         ") : 0
           Base.push!(r,"EXTEND  =                    T / FITS dataset may contain extensions            ")
           Base.push!(r,"COMMENT    Primary FITS HDU    / http://fits.gsfc.nasa.gov/iaufwg               ")
           Base.push!(r,"END                                                                             ")

    return r          # r: Array{String,1} of records

end

function _IMAGE_input(data::Array{T,N} where {T <: Real,N})

    eltype(data) <: Real || error("FitsError: Array of real numbers expected")

         E = Base.eltype(data)
    nbytes = sizeof(E)
     nbits = 8 * nbytes
    bitpix = E <: AbstractFloat ? -abs(nbits) : nbits
    bitpix = Base.lpad(bitpix,20)
      dims = Base.size(data)
     ndims = dims == (0,) ? 0 : Base.length(dims)
      dims = ndims > 0 ? [Base.lpad(dims[i],20) for i=1:ndims] : 0
     naxis = Base.lpad(ndims,20)
     bzero = Base.lpad(string(_fits_bzero(E)),20)

    r::Array{String,1} = [];  incl = ndims > 0 ? true : false

           Base.push!(r,"XTENSION= 'IMAGE   '           / FITS standard extension                        ")
    incl ? Base.push!(r,"BITPIX  = "   * bitpix  *    " / number of bits per data pixel                  ") : 0
           Base.push!(r,"NAXIS   = "   * naxis   *    " / number of data axes                            ")
    incl ? [Base.push!(r,"NAXIS$i  = " * dims[i] *    " / length of data axis " * rpad(i,27) ) for i=1:ndims] : 0
    incl ? Base.push!(r,"PCOUNT  =                    0 / number of data axes                            ") : 0
    incl ? Base.push!(r,"GCOUNT  =                    1 / number of data axes                            ") : 0
    incl ? Base.push!(r,"BZERO   = "   * bzero   *    " / offset data range to that of unsigned integer  ") : 0
    incl ? Base.push!(r,"BSCALE  =                  1.0 / default scaling factor                         ") : 0
           Base.push!(r,"COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/iaufwg               ")
           Base.push!(r,"END                                                                             ")

    return (r, data)           # r: Array{String,1} of records; data: same as input

end

function _table_data_types(cols::Vector{Vector{T} where T})

    ncols = length(cols)
    nrows = length(cols[1])
        f = Array{String,1}(undef,ncols)                                        # format specifier Xw.d

    for i ∈ eachindex(f)
        E = eltype(cols[i][1])
        x = E <: Integer ? "I" : E <: Real ? "E" : E == Float64 ? "D" : E <: Union{String,Char} ? "A" : "X"
        w = string(maximum([length(string(cols[i][j])) for j=1:nrows]))

        E <: Union{Char,String} ? (isascii(join(cols[i])) || error("FitsError: non-ASCII character in table $i")) : 0

        if E <: Union{Float16,Float32,Float64}
            v = string(cols[i][1])
            x = (('e' ∉ v) & ('p' ∉ v)) ? 'F' : x
            v = 'e' ∈ v ? split(v,'e')[1] : 'p' ∈ v ? split(v,'p')[1] : v
            d = !isnothing(findfirst('.',v)) ? string(length(split(v,'.')[2])) : '0'
        end

        f[i] = E <: Union{Float16,Float32,Float64} ? (x * w * '.' * d) : x * w
    end

    return f

end

function _TABLE_input(cols::Vector{Vector{T} where T})     # input array of table columns

    pcols = 1                                              # pointer to starting position of column in table row
    ncols = length(cols)                                   # number of columns
    nrows = length(cols[1])
    ncols < 1 && error("FitsError: a minimum of one column is mandatory")
    ncols = ncols < 999 ? ncols : 999
    ncols == 999 && println("FitsWarning: maximum number of columns exceeded (truncated at 999)")
    lcols = [length(cols[i]) for i=1:ncols]                          # length of columns (number of rows)
     pass = (sum(.!(lcols .== fill(nrows, ncols))) == 0)             # equal colum length test
     pass || error("FitsError: cannot create ASCII table (columns not of equal length)")

        w = [maximum([length(string(cols[i][j])) + 1  for j=1:nrows])  for i=1:ncols]
     data = [join([rpad(string(cols[i][j]),w[i])[1:w[i]] for i=1:ncols]) for j=1:nrows]
    tbcol = [pcols += w[i] for i=1:(ncols-1)]                        # field pointers (first column)
    tbcol = prepend!(tbcol,1)
    tbcol = [Base.lpad(tbcol[i],20) for i=1:ncols]
    tform = _table_data_types(cols)
    tform = ["'" * Base.rpad(tform[i],8) * "'"  for i=1:ncols]
    tform = [Base.rpad(tform[i],20) for i=1:ncols]
    ttype = ["HEAD$i"  for i=1:ncols]
    ttype = ["'" * Base.rpad(ttype[i],18) * "'" for i=1:ncols]          # default column headers
    nrows = Base.lpad(nrows,20)
    wcols = Base.lpad(sum(w),20)
    tcols = Base.lpad(ncols,20)

    r::Array{String,1} = []

    Base.push!(r,"XTENSION= 'TABLE   '           / FITS standard extension                        ")
    Base.push!(r,"BITPIX  =                    8 / number of bits per data pixel                  ")
    Base.push!(r,"NAXIS   =                    2 / number of data axes                            ")
    Base.push!(r,"NAXIS1  = "  * wcols    *    " / number of bytes/row                            ")
    Base.push!(r,"NAXIS2  = "  * nrows    *    " / number of rows                                 ")
    Base.push!(r,"PCOUNT  =                    0 / number of bytes in supplemetal data area       ")
    Base.push!(r,"GCOUNT  =                    1 / data blocks contain single table               ")
    Base.push!(r,"TFIELDS = "  * tcols    *    " / number of data fields (columns)                ")
    Base.push!(r,"COLSEP  =                    1 / number of spaces in column separator           ")
   [Base.push!(r,"TTYPE$i  = " * ttype[i] *    " / header of column " * rpad(i,30) ) for i=1:ncols]
   [Base.push!(r,"TBCOL$i  = " * tbcol[i] *    " / pointer to column " * rpad(i,29) ) for i=1:ncols]
   [Base.push!(r,"TFORM$i  = " * tform[i] *    " / data type of column " * rpad(i,27) ) for i=1:ncols]
   [Base.push!(r,"TDISP$i  = " * tform[i] *    " / data type of column " * rpad(i,27) ) for i=1:ncols]
    Base.push!(r,"COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/iaufwg               ")
    Base.push!(r,"END                                                                             ")

    return (r, data)         # r: Array{String,1} of records; data: Array{String,1} of rows of table

end
