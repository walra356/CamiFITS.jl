# SPDX-License-Identifier: MIT

using CamiFITS
#using Test

filnam = "kanweg.fits"
data = [0x0000043e, 0x0000040c, 0xffffffff]
f = fits_create(filnam, data; protect=false);
f = fits_extend!(f, data; hdutype="'IMAGE   '")
f = fits_extend!(f, data; hdutype="'IMAGE   '")
#data = [1,2];
#filnam = "kanweg.fits";
#f = fits_create(filnam, data; protect=false);
#fits_info(filnam)
#fits_record_dump(filnam)


#test_fits_info()

