```@meta
CurrentModule = CamiFITS
```

# Home

## CamiFITS.jl

FITS stands for *Flexible Image Transport System*. This is an open standard 
originally developed for the astronomy community to store telescope images 
together with tables of spectral information. Over the years it has developed 
into a scientific standard [[W. D. Pence et al., A&A, 524 (2010) A42]
(https://doi.org/10.1051/0004-6361/201015362)]. The standard is maintained by 
the [FITS Support Office](http://fits.gsfc.nasa.gov/) at 
NASA/GSFC [[FITS standard - Version 4.0]
(https://fits.gsfc.nasa.gov/fits_standard.html)]. This website also offers a 
[FITS Conformance Verifier](https://fits.gsfc.nasa.gov/fits_verify.html). 

CamiFITS offers the *basic FITS functionality* for scientific users not 
requiring celestal coordinates. Optional *Conforming Extensions* are under 
development. The user can create, read and extend .fits files as well as 
create, edit and delete user-defined metainformation.

*Disclaimer 2023-10-5:* The author is currently writing the documentation. 
In this process the code is tested, both with regard to FITS conformance and 
runtest coverage. Known issues remain to be solved but the package steadily
converges to a stable form.

## Table of contents

```@contents
```

## Install

The package is installed using the Julia package manager

```
julia> using Pkg; Pkg.add("CamiFITS")

julia> using CamiFITS
```