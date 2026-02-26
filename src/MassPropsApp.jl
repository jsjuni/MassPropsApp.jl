module MassPropsApp

    using ArgParse
    using CSV
    using DataFrames
    using MetaGraphsNext
    using Graphs
    using MassProps

    function parse_commandline()
        s = ArgParseSettings()
        @add_arg_table s begin
            "--include-uncertainties"
                help = "Include uncertainties"
                action = :store_true
            "input-file"
                help = "Input file (CSV)"
                arg_type = String
                required = false
        end
        return parse_args(s)
    end

    read_data(input) = CSV.read(input, DataFrame; missingstring = "NA")

    tree_from_edgelist(el, id, pid) = begin
        tree = MetaGraphsNext.MetaGraph(Graphs.SimpleDiGraph(), label_type = String)
        for row in eachrow(el)
            Graphs.add_vertex!(tree, row[id])
            if !ismissing(row[pid])
                Graphs.add_vertex!(tree, row[pid])
                Graphs.add_edge!(tree, row[id], row[pid])
            end
        end
        tree
    end

    function (@main)(ARGS)
        
        args = parse_commandline()
    
        rollup = args["include-uncertainties"] ? MassProps.rollup_mass_props_and_unc : MassProps.rollup_mass_props
        input = isnothing(args["input-file"]) ? stdin : open(args["input-file"], "r")
        df = read_data(input)
        tree = tree_from_edgelist(df, :id, :pid)
        aggs = map(c -> label_for(tree, c), filter(v -> indegree(tree, v) > 0, vertices(tree)))

        result = rollup(tree, df)
        CSV.write(stdout, result[in(aggs).(result.id), :], writeheader = true, missingstring = "NA")

        exit(0)
    end

end # module
