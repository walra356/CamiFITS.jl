# SPDX-License-Identifier: MIT

using CamiFITS
#using Test

#data = [1,2];
#filnam = "kanweg.fits";
#f = fits_create(filnam, data; protect=false);
#fits_info(filnam)
#fits_record_dump(filnam)


#    @test test_fits_pointer()
filnam = "kanweg.fits"
data = [0x0000043e, 0x0000040c, 0x0000041f]
f = fits_create(filnam, data; protect=false);
f = fits_extend!(filnam, data; hdutype="'IMAGE   '");
f = fits_extend!(filnam, data; hdutype="'IMAGE   '");
#data = fits_info(filnam)

#f = fits_extend!(f, data; hdutype="'IMAGE   '")
#fits_info(filnam)
#fits_record_dump(filnam)

#fits_extend!(f, data; hdutype="'IMAGE   '")
#fits_extend!(f, data; hdutype="'IMAGE   '")
#test_fits_pointer()