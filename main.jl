using Random
using Printf
include("./needleman_wunsch.jl")
Random.seed!(1)

function generate_sequences(t::Int64, l::Int64)
    # t is the number of sequences to create
    # l is the length of the sequences
    DNA = Array{String,1}(undef,0)
    base_arr = ["A", "T", "G", "C"]

    for t_index in 1:t
        push!(DNA, "")
        for l_value in 1:l
            r = convert(Int64, floor(Random.rand() * 4) + 1)
            DNA[t_index] = string(DNA[t_index], base_arr[r])
        end
    end
    return DNA
end


function array_equals_ordered(A::Array, B::Array)
    @printf("Comparing %s to %s\n", string(A), string(B))
    if length(A) != length(B)
        return false
    end

    for i in 1:length(A)
        if A[i] != B[i]
            return false
        end
    end
    return true
end

function array_contains(A::Array, e)
    for i in 1:length(A)
        if array_equals_ordered(A[i], e)
            return true
        end
    end

    return false
end

function random_permutations(A, num::Int64)
    # Return num random permutations of the elements of the Array A
    results = []
    if num >= factorial(length(A))
        throw(ErrorException("num is too high"))
    end
    max_check = 50
    try_count = 0
    for i in 1:num
        #@printf("Generating permutation %d\n", i)
        #@printf("Current Results: %s\n", string(results))
        localA = deepcopy(A)
        randomA = shuffle!(localA)
        #@printf("Sequence: %s\n", string(randomA))
        while array_contains(results, randomA)
            randomA = shuffle!(A)
            #@printf("Sequence: %s\n", string(randomA))
            try_count += 1
            if try_count > max_check
                throw(ErrorException("Exceeded max permutation tries"))
            end
        end
        push!(results, randomA)
    end
    return results
end

# Returns a swap sequence [(idx1, idx2), ...] to turn A into B
# Not necessarily the optimal swap sequence
function get_swap_sequence(A::Array, B::Array)
    if length(A) != length(B)
        throw(ErrorException("Length of A and B must be the same"))
    end

    localA = deepcopy(A)
    localB = deepcopy(B)
    swap_sequence = []

    for i in 1:length(A)
        @printf("Checking index %d\n", i)
        @printf("localA: %s\nlocalB: %s\n", string(localA), string(localB))
        if localA[i] != localB[i]

            # check where A[i] is in B[i:end]
            b_indexes = indexin(localA[i], localB[i:end])
            @assert(length(b_indexes) == 1)
            b_index = b_indexes[1]
            if b_index === nothing
                msg = string("Could not find ", string(localA[i], string(" in ", string(localB[i:end]))))
                throw(ErrorException(msg))
            end
            b_index += i - 1

            @printf("Doing swap (%d,%d)\n", i, b_index)
            # record the swap of i and b_index
            temp = localA[i]
            localA[i] = localA[b_index]
            localA[b_index] = temp
            
            push!(swap_sequence, (i, b_index))
        end
    end
    @printf("localA: %s\nlocalB: %s\n", string(localA), string(localB))
    local_equals = array_equals_ordered(localA, localB)
    @printf("localA == localB: %s\n", string(local_equals))
    return swap_sequence
end

# Calculates a new "velocity" for the particle given global best score, local best score
function pso_particle_velocity(particle, global_best::Array, local_best::Array, alpha::Float64, beta::Float64)
    swaps_to_local_best = get_swap_sequence(particle, local_best)
    swaps_to_global_best = get_swap_sequence(particle, global_best)
    r = Random.rand()
    velocity = []
    if r < alpha
        append!(velocity, swaps_to_local_best)
    end
    if r < beta
        append!(velocity, swaps_to_global_best)
    end
    return velocity
end

function progressive_alignment_inorder(sequences::Array, edge_weights::Array)
    if length(edge_weights) != length(sequences) - 1
        msg = @sprintf("Expected %d edge weights, got %d", length(sequences) - 1, length(edge_weights))
        throw(ErrorException(msg))
    end
    local_edge_weights = deepcopy(edge_weights)
    total_score = 0
    for i in 1:length(edge_weights)
        # find the min edge weight that has not been used yet
        min_i = argmin(local_edge_weights)
        # do the alignment of min_i and (min_i + 1)
        A = sequences[min_i]
        B = sequences[min_i+1]
        score, alignedA, alignedB = global_align(A, B)

        # TODO keep cumulative alignment.
        # need to figure out how to use alignedA and alignedB for the next step

    end
end

function PSO_MSA()
    N = 10
    t = 5
    iterations = 10
    solution_space = factorial(N) / (N*(N-1))
    search_space = N * iterations
    search_solution_ratio = search_space / solution_space
    @printf("Solution Space: %.02f\n", solution_space)
    @printf("Search Space: %.02f\n", search_space)
    @printf("Search/Solution space: %.02f\n", search_solution_ratio)

    sequences = generate_sequences(t, N)
    println(sequences)

    nodes = []
    for i in 1:length(sequences)
        push!(nodes, sequences[i])
    end

    edges = []
    for i in 1:length(sequences)
        for j in 1:length(sequences)
            if i != j
                seqA = sequences[i]
                seqB = sequences[j]
                # Use global_align function from needleman_wunsch to compute the distance
                distanceAB, seqA_aligned, seqB_aligned = global_align(seqA, seqB, 1, -1, 0)
                # Add edge A-B = distanceAB
                push!(edges, (seqA, seqB, distanceAB))
            end
        end
    end

    print("Nodes: ")
    println(nodes)
    print("Edges: ")
    println(edges)
    num_particles = 0
    if length(edges) > 100 || factorial(length(edges)) > 100
        num_particles = 100
    else
        num_particles = length(edges)
    end

    particles = random_permutations(nodes, 10)
    println("Permutations:")
    println(particles)

    alpha = Random.rand()
    beta = Random.rand()
    # TODO
    #global_best =  # calculate best permutation from the current particles
    #local_bests = zeros(Float64, length(particles))
    particle_scores = zeros(Float64, length(particles))

    for iteration in 1:iterations

    end


end

PSO_MSA()

# swap_sequence = get_swap_sequence([1,2,3,4,5,6], [4,3,2,1,6,5])
# println(swap_sequence)