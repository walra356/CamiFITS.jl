# ...................................................... FITS_HDU Objects .........................................................

"""
    FITS_HDU{T,V}

Object to hold a single "Header-Data Unit" (HDU).

The fields are
* `.filename`:  name of the corresponding FITS file (`::String`)
* `.hduindex:`:  identifier (a file may contain more than one HDU) (`:Int`)
* `.header`:  the header object where T=FITS_header (`::T`)
* `.dataobject`:  the data object where V=FITS_data (`::V`)
"""
struct FITS_HDU{T,V}

    filename::String
    hduindex::Int
    header::T        #FITS_header
    dataobject::V    #FITS_data

end

# ........................................... FITS_name Object..........................................................

"""
    FITS_name

FITS object to hold the decomposed name of a .fits file.

The fields are:
* `     .name`:  for 'p#.fits' this is 'p#.fits' (`::String`)
* `   .prefix`:  for 'p#.fits' this is 'p' (`::String`)
* `.numerator`:  for 'p#.fits' this is '#', a serial number (e.g., '3') or a range (e.g., '3-7') (`::String`)
* `.extension`:  for 'p#.fits' this is '.fits' (`::String`)
"""
struct FITS_name

    name::String
    prefix::String
    numerator::String
    extension::String

end

# ........................................... FITS_header Object..........................................................

"""
    FITS_header

Object to hold the header information of a [`FITS_HDU`](@ref).

The fields are:
* `.hduindex`:  identifier (a file may contain more than one HDU) (`::Int`)
* `.records`:  the header formated as an array of strings of 80 ASCII characters (`::Array{String,1}`)
* `.keys`:  `keys[i]` - key corresponding to `records[i]` (record of index `i`)  (`::Array{String,1}`)
* `.values`:  `value[i]` - corresponding to `records[i]`  (`::Array{Any,1}`)
* `.comments`:  `comments[i]` - comment corresponding to `records[i]` (`::String`)
* `.dict`:  Dictionary `key[i] => value[i]` (`::Dict{String,Any}`)
* `.maps`:  Dictionary `key[i] => i` (`::Dict{String,Int}`)
"""
struct FITS_header

    hduindex::Int
    records::Array{String,1}
    keys::Array{String,1}
    values::Array{Any,1}
    comments::Array{String,1}
    dict::Dict{String,Any}
    maps::Dict{String,Int}

end

# ........................................... FITS_data Object ...................................................

"""
    FITS_data

Object to hold the data of the [`FITS_HDU`](@ref) of given `hduindex` and
`hdutype`.

The fields are:
* `.hduindex`:  identifier (a file may contain more than one HDU) (`::Int`)
* `.hdutype`:  accepted types are 'PRIMARY', 'IMAGE' and 'TABLE' (`::String`)
* `.data`:  in the from appropriate for the `hdutype` (::Any)
"""
struct FITS_data

    hduindex::Int
    hdutype::String
    data

end

# ........................................... FITS_table Object ..........................................................

"""
    FITS_table

Object to hold the data of a `TABLE HDU` (a [`FITS_HDU`](@ref) for ASCII
tables). It contains the data in the form of records (rows) of ASCII strings.

The fields are:
* `.hduindex`:  identifier (a file may contain more than one HDU) (`::Int`)
* `.rows`:  the table formated as an array of rows of ASCII strings (`::Array{String,1}`)
"""
struct FITS_table

    hduindex::Int
    rows::Array{String,1}

end
