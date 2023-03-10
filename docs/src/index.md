# CamiFITS.jl

FITS stands for 'Flexible Image Transport System'. This is an open standard origionally developed for the astronomy community to store telescope images together with tables of spectral information. Over the years it has developed into a scientific standard - http://fits.gsfc.nasa.gov/iaufwg. CamiFITS offers the basic FITS functionality for scientific users not requiring celestal coordinates. 

## Installation

```@contents
julia> using Pkg; Pkg.add("CamiFITS")
```



The user can create, read and extend .fits files as well as create, edit and delete user-defined metainformation.

A FITS file consists of a sequence of one or more header-data-units (HDUs), each containing a data block preceeded by header records of metainformation.

By the command `f = fits_read(filnam)` we asign a collection of `FITS_HDU` objects from the file `filnam` to the variable `f`.

---

# Library

```@contents
Pages = ["man/library.md"]
```

# Index

```@contents
Pages = ["man/index.md"]
```