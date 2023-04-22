# CamiFITS.jl

FITS stands for *Flexible Image Transport System*. This is an open standard origionally developed for the astronomy community to store telescope images together with tables of spectral information. Over the years it has developed into a scientific standard [[W. D. Pence et al., A&A, 524 (2010) A42](https://doi.org/10.1051/0004-6361/201015362)]. The standard is maintained by the [FITS Support Office](http://fits.gsfc.nasa.gov/) at NASA/GSFC [[FITS standard - Version 4.0](https://fits.gsfc.nasa.gov/fits_standard.html)]. The website also offers a [FITS Conformance Verifier](https://fits.gsfc.nasa.gov/fits_verify.html). 

CamiFITS offers the *basic FITS functionality* for scientific users not requiring celestal coordinates. Optional *Conforming Extentions* are under development. The user can create, read and extend .fits files as well as create, edit and delete user-defined metainformation.

*Disclaimer 2023-04-02:* The author is currently writing the manual. In this process the code is tested, both with regard to FITS conformance and runtest coverage. Known issues remain to be solved and the package certainly did not reach a stable form.

# Table of contents

```@contents
```
# Install

The package is installed using the Julia package manager

```
julia> using Pkg; Pkg.add("CamiFITS")

julia> using CamiFITS
```

# Manual
### Introduction

A FITS file consists of a sequence of one or more *Header and Data Units* ([`FITS_HDU`](@ref)s), each containing a [`FITS_data`](@ref) block (containing one or more images) preceeded by a [`FITS_header`](@ref) of records with metainformation.

We distinguish between *IMAGE* and *TABLE* HDU data types. The first HDU in a `.fits` file is called the *PRIMARY HDU*.

Let "example.fits" be an *existing* `.fits` file. By the commands 

```
julia> filnam = "example.fits"
"example.fits"

julia> f = fits_read(filnam);
```
we asign the [`FITS`](@ref) object (read from the `.fits` file `filnam` on dics) to the variable `f`. 

The fields of `f`, `f.hdu[1]`, `f.hdu[2]`, ... correspond to the 
[`FITS_HDU`](@ref) objects. The *PRIMARY HDU* of the [`FITS`](@ref) object is
represented by `f.hdu[1]`. When dealing with a single [`FITS`](@ref) object it 
is often practical to redefine `f = f.hdu` to represent the 
[`FITS_HDU`](@ref) object without explicit reference to principal [`FITS`](@ref)
object.

The formal terminology of the [FITS standard](https://fits.gsfc.nasa.gov/fits_standard.html) can be consulted using 
[`fits_terminology`](@ref): 
```
julia> fits_terminology("HDU")
HDU:
Header and Data Unit. A data structure consisting of a header and the data the header describes. 
Note that an HDU may consist entirely of a header with no data blocks.
```

#### Creating a simple FITS file
FITS files can be created using the command [`fits_create`](@ref).
The minimal file conforming to the FITS standard consists of a single HDU 
with an empty data field.
```
julia> filnam = "minimal.fits"
"minimal.fits"

julia> f = fits_create(filnam; protect=false);

julia> fits_info(f.hdu[1])

File: minimal.fits
hdu: 1
hdutype: PRIMARY
DataType: Any
Datasize: (0,)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
BITPIX  =                   64 / number of bits per data pixel
NAXIS   =                    1 / number of data axes
NAXIS1  =                    0 / length of data axis 1
BZERO   =                  0.0 / offset data range to that of unsigned integer  
BSCALE  =                  1.0 / default scaling factor
EXTEND  =                    T / FITS dataset may contain extensions
COMMENT    Extended FITS HDU   / http://fits.gsfc.nasa.gov/
END

Any[]

julia> rm(filnam); f = nothing
```

#### Inspecting the FITS object

```
julia> filnam = "minimal.fits";

julia> f = fits_create(filnam; protect=false);

julia> i = Base.get(f.hdu[1].header.map, "NAXIS", 0)
3

julia> (card[i].cardindex, card[i].keyword, card[i].value, card[i].comment)
(3, "NAXIS", 1, "number of data axes                            ")

julia> card[i].record
"NAXIS   =                    1 / number of data axes                            "

julia> rm(filnam); f = nothing
```

#### The FITS file for a single matrix

We first create the data field in the form of a 3x3 matrix:
```
julia> filnam = "matrix.fits";

julia> data = [11,21,31,12,22,23,13,23,33];

julia> data = reshape(data,(3,3,1))
3×3×1 Array{Int64, 3}:
[:, :, 1] =
 11  12  13
 21  22  23
 31  23  33
```
We next create and inspect the FITS file for the matrix `data`
```
julia> fits_create(filnam, data; protect=false)

julia> f = fits_read(filnam);

julia> f = f.hdu;

julia> fits_info(f[1])

File: matrix.fits
hdu: 1
hdutype: PRIMARY
DataType: Int64
Datasize: (3, 3, 1)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
BITPIX  =                   64 / number of bits per data pixel
NAXIS   =                    3 / number of data axes
NAXIS1  =                    3 / length of data axis 1
NAXIS2  =                    3 / length of data axis 2
NAXIS3  =                    1 / length of data axis 3
BZERO   =                  0.0 / offset data range to that of unsigned integer
BSCALE  =                  1.0 / default scaling factor
EXTEND  =                    T / FITS dataset may contain extensions
COMMENT    Primary FITS HDU    / http://fits.gsfc.nasa.gov
END

3×3×1 Array{Int64, 3}:
[:, :, 1] =
 11  12  13
 21  22  23
 31  23  33

julia> rm(filnam); f = nothing
```
The keywords `NAXIS1`, `NAXIS2` and `NAXIS3` represent the dimensions 
of the ``x, y`` data matrix stacked in the ``z`` direction. 

The matrix elements are referred to as `pixels` and their bit size is 
represented by the keyword `BITPIX`. In the above example the pixel value 
is given by the matrix indices.
# API

### Terminology

```@docs
fits_terminology(term::String; test=false)
```

### FITS 

#### Types

```@docs
FITS_filnam
FITS
FITS_HDU
FITS_header
FITS_card
FITS_data
FITS_table
```
#### Type casting

```@docs
cast_FITS_filnam(filnam::String)
cast_FITS_card(cardindex::Int, record::String)
cast_FITS_data(hduindex::Int, hdutype::String, data)
```

### FITS - HDU Methods

```@docs
fits_info(hdu::FITS_HDU)
parse_FITS_TABLE(hdu::FITS_HDU)
```

#### FITS - File Methods

```@docs
fits_combine(filnamFirst::String, filnamLast::String; protect=true)
fits_copy(filnamA::String, filnamB::String=" "; protect=true)
fits_read(filnam::String)
fits_create(filnam::String, data=nothing; protect=true, msg=true)
fits_extend(filnam::String, data_extend, hdutype="IMAGE")
```

### FITS - Key Methods

```@docs
fits_add_key(filnam::String, hduindex::Int, key::String, val::Real, com::String)
fits_delete_key(filnam::String, hduindex::Int, key::String)
fits_edit_key(filnam::String, hduindex::Int, key::String, val::Real, com::String)
fits_rename_key(filnam::String, hduindex::Int, keyold::String, keynew::String)
```

## FORTRAN

```@docs
FORTRAN_format
cast_FORTRAN_format(str::String)
cast_FORTRAN_datatype(str::String)
```

## Plotting

```@docs
step125(x::Real)
select125(x)
steps(x::Vector{T} where T<:Real)
stepcenters(x::Vector{T} where T<:Real)
stepedges(x::Vector{T} where T<:Real)
edges(px, Δx=1.0, x0=0.0)
```

## Index

```@index
```