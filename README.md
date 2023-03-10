# CamiFITS

A [`Julia`](@ref) package for reading and writing files in the FITS format.

FITS stands for 'Flexible Image Transport System'. This is an open standard origionally developed for the astronomy community to store telescope images together with tables of spectral information. Over the years it has developed into a scientific standard - http://fits.gsfc.nasa.gov/iaufwg.

Within CamiFITS only the basic FITS functionality is implemented for users not requiring celestal coordinates. The user can create, read and extend .fits files as well as create, edit and delete user-defined metainformation.

A FITS file consists of a sequence of one or more header-data-units (HDUs), each containing a data block preceeded by header records of metainformation.

By the command `f = fits_read(filnam)` we asign a collection of `FITS_HDU` objects from the file `filnam` to the variable `f`.


| **Documentation**                              |                 
|:----------------------------------------------:|
|[![Stable](https://img.shields.io/badge/docs-v1-blue.svg)](https://walra356.github.io/CamiFITS.jl/stable)|[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://walra356.github.io/CamiFITS.jl/dev)

| **Build status**                | **Code coverage**                     | **Tag status**                        | **Compatibility**                 | **Licence**                                 
:--------------------------------:|:-------------------------------------:|:-------------------------------------:|:---------------------------------:|:-----------------------------------:|
|[![CI](https://github.com/walra356/CamiFITS.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/walra356/CamiFITS.jl/actions/workflows/CI.yml)
|[![codecov](https://codecov.io/gh/walra356/CamiFITS.jl/branch/main/graph/badge.svg?token=7LW41FGMK5)](https://codecov.io/gh/walra356/CamiFITS.jl)
|[![TagBot](https://github.com/walra356/CamiFITS.jl/actions/workflows/TagBot.yml/badge.svg)](https://github.com/walra356/CamiFITS.jl/actions/workflows/TagBot.yml)
|[![CompatHelper](https://github.com/walra356/CamiFITS.jl/actions/workflows/CompatHelper.yml/badge.svg)](https://github.com/walra356/CamiFITS.jl/actions/workflows/CompatHelper.yml)
|[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)