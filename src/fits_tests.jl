# SPDX-License-Identifier: MIT

# ------------------------------------------------------------------------------
#                            fits_test.jl
#                        Jook Walraven 18-03-2023
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
#                         test_FITS_name(o=[])
# ------------------------------------------------------------------------------

function test_FITS_name(o=[])

    let filnam = "kanweg.fits"

        fits_create(filnam; protect=false)

        text = filnam * " is an existing file"
        err1 = _err_FITS_name(filnam)
        err2 = _err_FITS_name(filnam; protect=false)
        ans1 = 4
        text *= " and may not be overwritten"
        ans2 = 0
        text *= " and may be overwritten"
        push!(o, (text, ans1, err1, ans1 == err1))
        push!(o, (text, ans2, err2, ans2 == err2))

        rm(filnam)

        text = filnam * " is a non-existing file"
        err1 = _err_FITS_name(filnam)
        err2 = _err_FITS_name(filnam; protect=false)
        ans1 = 0
        text *= " and may be created"
        ans2 = 0
        text *= " and may be created"
        push!(o, (text, ans1, err1, ans1 == err1))
        push!(o, (text, ans2, err2, ans2 == err2))

    end

    let filnam = "kanweg"

        fits_create(filnam; protect=false, msg=false)

        text = filnam * " is an existing file"
        err1 = _err_FITS_name(filnam)
        err2 = _err_FITS_name(filnam; protect=false)
        ans1 = 4
        text *= " and may not be overwritten"
        ans2 = 2
        text *= " but lacks the mandatory .fits extension"
        push!(o, (text, ans1, err1, ans1 == err1))
        push!(o, (text, ans2, err2, ans2 == err2))

        rm(filnam)

        text = filnam * " does not exist"
        err1 = _err_FITS_name(filnam)
        err2 = _err_FITS_name(filnam; protect=false)
        ans1 = 2
        text *= " and lacks the mandatory .fits extension"
        ans2 = 2
        text *= " and lacks the mandatory .fits extension"
        push!(o, (text, ans1, err1, ans1 == err1))
        push!(o, (text, ans2, err2, ans2 == err2))

    end

    let filnam = "kanweg.fit"

        fits_create(filnam; protect=false, msg=false)

        text = filnam * " is an existing file"
        err1 = _err_FITS_name(filnam)
        err2 = _err_FITS_name(filnam; protect=false)
        err2 = _err_FITS_name(filnam; protect=false)
        ans1 = 4
        text *= "and may not be overwritten"
        ans2 = 2
        text *= "but lacks the mandatory .fits extension"
        push!(o, (text, ans1, err1, ans1 == err1))
        push!(o, (text, ans2, err2, ans2 == err2))

        rm(filnam)

        text = filnam * " does not exist"
        err1 = _err_FITS_name(filnam)
        err2 = _err_FITS_name(filnam; protect=false)
        ans1 = 2
        text *= " and lacks the mandatory .fits extension"
        ans2 = 2
        text *= " and lacks the mandatory .fits extension"
        push!(o, (text, ans1, err1, ans1 == err1))
        push!(o, (text, ans2, err2, ans2 == err2))

    end

    let filnam = ".fits"

        fits_create(filnam; protect=false, msg=false)

        text = filnam * " is an existing file"
        err1 = _err_FITS_name(filnam)
        err2 = _err_FITS_name(filnam; protect=false)
        ans1 = 4
        text *= " and may not be overwritten"
        ans2 = 3
        text *= " but lacks a mandatory filename"
        push!(o, (text, ans1, err1, ans1 == err1))
        push!(o, (text, ans2, err2, ans2 == err2))

        rm(filnam)

        text = filnam * " does not exist"
        err1 = _err_FITS_name(filnam)
        err2 = _err_FITS_name(filnam; protect=false)
        ans1 = 3
        text *= " and lacks a mandatory filename"
        ans2 = 3
        text *= " and lacks a mandatory filename"
        push!(o, (text, ans1, err1, ans1 == err1))
        push!(o, (text, ans2, err2, ans2 == err2))

    end

    invalid = [o[i][4] == 0 for i ∈ eachindex(o)]

    n = findfirst(invalid)

    isnothing(n) || println("Error: ", o[n])

    return isnothing(n) ? true : false

end

function test_fits_create()

    filnam = "minimal.fits"

    f = fits_create(filnam; protect=false)
    a = f.hdu[1].header.card[1].keyword == "SIMPLE"
    b = f.hdu[1].dataobject.data == Any[]
    c = f.hdu[1].header.card[1].val == true
    d = f.hdu[1].header.card[4].val == 0

    rm(filnam)

    filnam = "kanweg.fits"
    data = [0x0000043e, 0x0000040c, 0x0000041f]
    
    f = fits_create(filnam, data; protect=false)
    p = f.hdu[1].header.card[1].keyword == "SIMPLE"
    q = f.hdu[1].dataobject.data == [0x0000043e, 0x0000040c, 0x0000041f]
    r = f.hdu[1].header.card[1].val == true
    s = f.hdu[1].header.card[4].val == 3

    rm(filnam)

    o = isnothing(findfirst(.![a, b, c, d, p, q, r, s])) ? true : false
 
    o || println([a, b, c, d, p, q, r, s])

    return o

end

function test_fits_read()

    filnam = "minimal.fits"

    f = fits_create(filnam; protect=false)
    f = fits_read(filnam)

    a = f.hdu[1].header.card[1].keyword == "SIMPLE"
    b = f.hdu[1].dataobject.data == Any[]
    c = f.hdu[1].header.card[1].val == true
    d = f.hdu[1].header.card[4].val == 0

    rm(filnam)

    filnam = "kanweg.fits"
    data = [0x0000043e, 0x0000040c, 0x0000041f]

    f = fits_create(filnam, data; protect=false)
    f = fits_read(filnam)

    p = f.hdu[1].header.card[1].keyword == "SIMPLE"
    q = f.hdu[1].dataobject.data == [0x0000043e, 0x0000040c, 0x0000041f]
    r = f.hdu[1].header.card[1].val == true
    s = f.hdu[1].header.card[4].val == 3

    rm(filnam)

    o = isnothing(findfirst(.![a, b, c, d, p, q, r, s])) ? true : false

    o || println([a, b, c, d, p, q, r, s])

    return o

end


function test_fits_extend()

    filnam = "test_example.fits"
    data = [0x0000043e, 0x0000040c, 0x0000041f]
    f = fits_create(filnam, data; protect=false)

    f = fits_read(filnam)
    a = Float16[1.01E-6, 2.0E-6, 3.0E-6, 4.0E-6, 5.0E-6]
    b = [0x0000043e, 0x0000040c, 0x0000041f, 0x0000042e, 0x0000042f]
    c = [1.23, 2.12, 3.0, 4.0, 5.0]
    d = ['a', 'b', 'c', 'd', 'e']
    e = ["a", "bb", "ccc", "dddd", "ABCeeaeeEEEEEEEEEEEE"]
    data = [a, b, c, d, e]

    f = fits_extend(filnam, data, "TABLE")

    f = fits_read(filnam)
    strExample = "1.0e-6 1086 1.23 a a                    "
    a = f.hdu[1].header.card[1].keyword == "SIMPLE"
    b = f.hdu[1].dataobject.data[1][1] == 0x0000043e
    c = f.hdu[2].header.card[1].keyword == "XTENSION"
    d = f.hdu[2].dataobject.data[1] == strExample
    # e = f.hdu[2].header.key[3].val == 2
    e = get(Dict(f.hdu[2].header.map), "NAXIS", 0) == 3

    rm(filnam)

    o = isnothing(findfirst(.![a, b, c, d, e])) ? true : false

    o || println([a, b, c, d, e])

    return o

end

function test_fits_rename_key()

    filnam = "minimal.fits"
    fits_create(filnam; protect=false)
    fits_add_key(filnam, 1, "KEYNEW1", true, "this is record 5")

    f = fits_read(filnam)
    i = get(f[1].header.maps, "KEYNEW1", 0)

    test1 = i == 5

    fits_rename_key(filnam, 1, "KEYNEW1", "KEYNEW2")

    f = fits_read(filnam)
    i = get(f[1].header.maps, "KEYNEW2", 0)

    test2 = i == 5

    test = .![test1, test2]

    o = isnothing(findfirst(.![test1, test2])) ? true : false

    rm(filnam)

    return o

end

function test_fits_delete_key()

    filnam = "minimal.fits"
    fits_create(filnam; protect=false)
    fits_add_key(filnam, 1, "KEYNEW1", true, "FITS dataset may contain extension")

    f = fits_read(filnam)
    i = get(f[1].header.maps, "KEYNEW1", 0)

    test1 = i == 5

    # println(test1)

    fits_delete_key(filnam, 1, "KEYNEW1")

    f = fits_read(filnam)
    i = get(f[1].header.maps, "KEYNEW1", 0)

    test2 = i == 0

    # println(test2)

    test = .![test1, test2]

    o = isnothing(findfirst(.![test1, test2])) ? true : false

    rm(filnam)

    return o

end

function test_fits_edit_key()

    filnam = "minimal.fits"
    fits_create(filnam; protect=false)
    fits_add_key(filnam, 1, "KEYNEW1", true, "FITS dataset may contain extension")
    fits_edit_key(filnam, 1, "KEYNEW1", false, "comment has changed")

    f = fits_read(filnam)
    i = get(f[1].header.maps, "KEYNEW1", 0)
    r = f[1].header.records

    test = r[i] == "KEYNEW1 =                    F / comment has changed                            "

    rm(filnam)

    return test

end

function test_fits_add_key()

    filnam = "minimal.fits"
    fits_create(filnam; protect=false)
    fits_add_key(filnam, 1, "KEYNEW1", true, "FITS dataset may contain extension")

    f = fits_read(filnam)
    i = get(f.hdu[1].header.map, "KEYNEW1", 0)
    r = f.hdu[1].header.record[i]

    test = r[i] == "KEYNEW1 =                    T / FITS dataset may contain extension             "

    rm(filnam)

    return test

end
