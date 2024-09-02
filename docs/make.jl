using Documenter
using CamiFITS

makedocs(;
    modules = [CamiFITS],
    authors = "<walra356@planet.nl> and contributors",
    sitename = "CamiFITS.jl",
    format=Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        assets = String[]
    ),
    pages=[
        "Home" => "index.md",
        "Manual" => "pages/manual.md",
        "Basic tools" => "pages/tools.md",
        # "API" => ["pages/fits.md", "pages/FORTRAN.md"] 
        "FITS structure" => "pages/fits.md",
        "Index" => "pages/index.md",
    ]
)

deploydocs(;
    repo = "github.com/walra356/CamiFITS.jl.git",
    devbranch = "main"
) 

