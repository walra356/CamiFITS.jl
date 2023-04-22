function indices(v::Vector{}, firstindex::Int)
    
    return Base.Iterators.drop(eachindex(v), firstindex-1)
    
end

function indices(v::Vector{}; dropfirst=false, droplast=false)

    n = length(v)

    itr = dropfirst & droplast ? (2:n-1) :
          dropfirst ? (2:n) :
          droplast ? (1:n-1) : (1:n)

    return itr

end