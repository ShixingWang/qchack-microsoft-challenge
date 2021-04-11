namespace QCHack.Task4 {
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Logical;
    open Microsoft.Quantum.Arrays as Arrays;

    // Task 4 (12 points). f(x) = 1 if the graph edge coloring is triangle-free
    // 
    // Inputs:
    //      1) The number of vertices in the graph "V" (V ≤ 6).
    //      2) An array of E tuples of integers "edges", representing the edges of the graph (0 ≤ E ≤ V(V-1)/2).
    //         Each tuple gives the indices of the start and the end vertices of the edge.
    //         The vertices are indexed 0 through V - 1.
    //         The graph is undirected, so the order of the start and the end vertices in the edge doesn't matter.
    //      3) An array of E qubits "colorsRegister" that encodes the color assignments of the edges.
    //         Each color will be 0 or 1 (stored in 1 qubit).
    //         The colors of edges in this array are given in the same order as the edges in the "edges" array.
    //      4) A qubit "target" in an arbitrary state.
    //
    // Goal: Implement a marking oracle for function f(x) = 1 if
    //       the coloring of the edges of the given graph described by this colors assignment is triangle-free, i.e.,
    //       no triangle of edges connecting 3 vertices has all three edges in the same color.
    //
    // Example: a graph with 3 vertices and 3 edges [(0, 1), (1, 2), (2, 0)] has one triangle.
    // The result of applying the operation to state (|001⟩ + |110⟩ + |111⟩)/√3 ⊗ |0⟩ 
    // will be 1/√3|001⟩ ⊗ |1⟩ + 1/√3|110⟩ ⊗ |1⟩ + 1/√3|111⟩ ⊗ |0⟩.
    // The first two terms describe triangle-free colorings, 
    // and the last term describes a coloring where all edges of the triangle have the same color.
    //
    // In this task you are not allowed to use quantum gates that use more qubits than the number of edges in the graph,
    // unless there are 3 or less edges in the graph. For example, if the graph has 4 edges, you can only use 4-qubit gates or less.
    // You are guaranteed that in tests that have 4 or more edges in the graph the number of triangles in the graph 
    // will be strictly less than the number of edges.
    //
    // Hint: Make use of helper functions and helper operations, and avoid trying to fit the complete
    //       implementation into a single operation - it's not impossible but make your code less readable.
    //       GraphColoring kata has an example of implementing oracles for a similar task.
    //
    // Hint: Remember that you can examine the inputs and the intermediary results of your computations
    //       using Message function for classical values and DumpMachine for quantum states.
    //

    function FindTriangles(edges : (Int, Int)[]): (Int,Int,Int)[] {
        let numEdges = Length(edges);
        mutable indicesEdges = Arrays.EmptyArray<(Int,Int,Int)>(); 
        if (numEdges>=3) {
            mutable points = [-1,-1,-1,-1,-1,-1];
            for i in 0..numEdges-3 {
                let (e0,e1) = edges[i];
                set points w/=0..1 <- [e0,e1];
                for j in i+1..numEdges-2 {
                    let (e2,e3) = edges[j];
                    set points w/=2..3 <- [e2,e3];
                    for k in j+1..numEdges-1 {
                        let (e4,e5) = edges[k];
                        set points w/=4..5 <- [e4,e5];

                        let uniquePoints = Arrays.Unique(EqualI,Arrays.Sorted(LessThanI,points));
                        if Length(uniquePoints)==3 {
                            set indicesEdges = indicesEdges + [(i,j,k)];  
                        }
                    }
                }
            }
        }
        return indicesEdges;
    }

    operation Task3_ValidTriangle (inputs : Qubit[], output : Qubit) : Unit is Adj+Ctl {
        // Inputs:
        //      1) a 3-qubit array "inputs",
        //      2) a qubit "output".
        // Goal: Implement a marking oracle for function f(x) = 1 if at least two of the three bits of x are different.
        CNOT(inputs[0],inputs[1]);
        CNOT(inputs[0],inputs[2]);
        X(inputs[1]);
        X(inputs[2]);
        CCNOT(inputs[1],inputs[2],output);
        X(inputs[1]);
        X(inputs[2]);
        CNOT(inputs[0],inputs[1]);
        CNOT(inputs[0],inputs[2]);
        X(output);
    }

    operation Task4_TriangleFreeColoringOracle (
        V : Int, 
        edges : (Int, Int)[], 
        colorsRegister : Qubit[], 
        target : Qubit
    ) : Unit is Adj+Ctl {
        let indices = FindTriangles(edges);
        if Length(indices)==0 {
            X(target);
        }
        else {
            use qubitsTriangle = Qubit[Length(indices)];
            for idx in 0..Length(indices)-1 {
                let (a1,a2,a3) = indices[idx];
                Task3_ValidTriangle(Arrays.Subarray([a1,a2,a3],colorsRegister),qubitsTriangle[idx]);
            }
            let boolArray = Arrays.ConstantArray(Length(indices),true);
            let CheckTriangleFree = ControlledOnBitString(boolArray,X);
            CheckTriangleFree(qubitsTriangle,target);
            for idx in 0..Length(indices)-1 {
                let (a1,a2,a3) = indices[idx];
                Task3_ValidTriangle(Arrays.Subarray([a1,a2,a3],colorsRegister),qubitsTriangle[idx]);
            }
        }
    }
}
