# CamiFITS.jl

FITS stands for *Flexible Image Transport System*. This is an open standard origionally developed for the astronomy community to store telescope images together with tables of spectral information. Over the years it has developed into a scientific standard [[W. D. Pence et al., A&A, 524 (2010) A42](https://doi.org/10.1051/0004-6361/201015362)]. The standard is maintained by the [FITS Support Office](http://fits.gsfc.nasa.gov/) at NASA/GSFC [[FITS standard - Version 4.0](https://fits.gsfc.nasa.gov/fits_standard.html)]. The website also offers a [FITS Conformance Verifier](https://fits.gsfc.nasa.gov/fits_verify.html). 

CamiFITS offers the *basic FITS functionality* for scientific users not requiring celestal coordinates. Optional *Conforming Extentions* are under development. The user can create, read and extend .fits files as well as create, edit and delete user-defined metainformation.

*Disclaimer 2023-03-13:* The author is currently writing the manual. In this process the code is tested, both with regard to FITS conformance and runtest coverage. Known issues remain to be solved and the package certainly did not reach a stable form.

# Table of contents

```@contents
```
# Installation

The package is installed using the Julia package manager

```
julia> using Pkg; Pkg.add("CamiFITS")

julia> using CamiFITS
```

# Manual
### Introduction

A FITS file consists of a sequence of one or more header-data-units ([`FITS_HDU`](@ref)s), each containing a [`FITS_data`](@ref) block preceeded by [`FITS_header`](@ref) records of metainformation.

We distinguish between `IMAGE` and `TABLE` HDU data types. The first HDU in a .fits file is called the `PRIMARY` HDU.

Let us consider an *existing* .fits file, "example.fits". By the commands 

```
julia> filnam = "example.fits"

julia> f = fits_read(filnam)
```
we asign the collection of [`FITS_HDU`](@ref) objects from `filnam` to the variable `f`. 

The elements of `f`, f[1], f[2], ... are called *Header and Data Units* (*HDU*s), with f[1] representing the `PRIMARY` HDU. The structure of the HDU f[i] can be printed in the form of metainformation the command [`FITS_info`](@ref)(`f[i]`).

FITS files can be created using the command [`fits_create`](@ref).

#### The simplest FITS file
The simplest file conforming to the FITS standard consists of a single HDU containing an empty data field of the type `Any[]`.
```
julia> filename = "empty.fits";

julia> fits_create(filename; protect=false)

julia> f = fits_read(filename);

julia> fits_info(f[1])

File: minimal.fits
hdu: 1
hdutype: PRIMARY
DataType: Any
Datasize: (0,)

Metainformation:
SIMPLE  =                    T / file does conform to FITS standard
NAXIS   =                    0 / number of data axes
EXTEND  =                    T / FITS dataset may contain extensions
COMMENT    Primary FITS HDU    / http://fits.gsfc.nasa.gov/iaufwg
END

Any[]

julia> rm(filename); f = nothing
```

### The FITS file for a single matrix
We first create the data field in the form of a 3x3 matrix:
```
julia> filename = "matrix.fits";

julia> data = [11,21,31,12,22,23,13,23,33];

julia> data = reshape(data,(3,3,1))
3×3×1 Array{Int64, 3}:
[:, :, 1] =
 11  12  13
 21  22  23
 31  23  33
```
We next create and inspact the FITS file for the matrix `data`
```
julia> fits_create(filename, data; protect=false)

julia> f = fits_read(filename);

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
COMMENT    Primary FITS HDU    / http://fits.gsfc.nasa.gov/iaufwg
END

3×3×1 Array{Int64, 3}:
[:, :, 1] =
 11  12  13
 21  22  23
 31  23  33

julia> rm(filename); f = nothing
```
The keywords `NAXIS1`, `NAXIS2` and `NAXIS3` represent the dimensions 
of the data matrix in ``x``, ``y`` and ``z`` direction. 

The matrix elements are referred to as `pixels` and their bit size is 
represented by the keyword `BITPIX`. In the above example the pixel value 
is given by the matrix indices.
 

# API

### FITS - Types

```@docs
FITS_HDU{T,V}
FITS_header
FITS_data
FITS_table
FITS_name
```



### FITS - HDU Methods

```@docs
fits_info(hdu::FITS_HDU)
parse_FITS_TABLE(hdu::FITS_HDU)
```

#### FITS - File Methods

```@docs
cast_FITS_name(filename::String)
fits_combine(filnamFirst::String, filnamLast::String; protect=true)
fits_copy(filenameA::String, filenameB::String=" "; protect=true)
fits_create(filename::String, data=[]; protect=true)
fits_extend(filename::String, data_extend, hdutype="IMAGE")
fits_read(filename::String)
```

### FITS - Key Methods

```@docs
fits_add_key(filename::String, hduindex::Int, key::String, val::Real, com::String)
fits_delete_key(filename::String, hduindex::Int, key::String)
fits_edit_key(filename::String, hduindex::Int, key::String, val::Real, com::String)
fits_rename_key(filename::String, hduindex::Int, keyold::String, keynew::String)
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