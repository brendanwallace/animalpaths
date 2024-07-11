abstract type Walker end
abstract type AbstractWorld end
abstract type AbstractScenario end

const Position = Tuple{Float64, Float64}
const GridPosition = Tuple{Int64, Int64}


function update!(walker :: Walker)
    @error "No update! function implemented for this walker class"
end


struct Location
    position :: Tuple{Float64, Float64}
end


# TODO - is this being used in more than just walker?
normalize(x) = x / norm(x)


function costs(patches :: Matrix{Float64})
    # TODO - verify this
    return MAX_COST .* (1.0 .- patches) .+ (1.0 .* patches)
end

# It's wild that this doesn't already exist.
function delete!(array, element)
    deleteat!(array, findall(isequal(element), array))
end