# SPDX-License-Identifier: MIT

# Copyright (c) 2024 Jook Walraven <69215586+walra356@users.noreply.github.com> and contributors

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

using CamiFITS
using Test

@testset "CamiFITS.jl" begin

    @test test_fits_info(dbg=true)
    @test test_fits_copy()
    @test test_fits_create()
    @test test_fits_keyword()
    @test test_fits_read()
    @test test_fits_save_as()
    @test test_fits_collect()
    @test test_fits_pointer()
    @test test_fits_ptr()
    @test test_fits_zero_offset()
    @test test_format_hdutype()
    @test test_table_datatype()
    @test test_bintable_datatype()

    @test test_fits_add_key!()
    @test test_fits_delete_key!()
    @test test_fits_edit_key!()
    @test test_fits_rename_key!()
    @test test_FORTRAN_format()
    @test test_FORTRAN_eltype_char()

    filnam = "kanweg.fits"
    data = [0x0000043e, 0x0000040c, 0x0000041f]
    f = fits_create(filnam, data; protect=false)
    fits_extend!(f, data; hdutype="Image")
    fits_extend!(f, data; hdutype="IMAGE")
    @test_throws FITSError fits_create(filnam)
    rm(filnam)
    @test_throws FITSError fits_create("kanweg")
    @test_throws FITSError fits_create("kanweg.fit")
    @test_throws FITSError fits_create(" .fits")

    @test fits_terminology("FITS"; test=true) == "FITS:\nFlexible Image Transport System."
    @test fits_terminology("s"; test=true)
    @test fits_terminology(; test=true)

end
