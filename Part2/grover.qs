namespace grover.qs {

    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Logical;
    open Microsoft.Quantum.Arrays as Arrays;
    open Microsoft.Quantum.Measurement;
    
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

    operation CheckValidTriangle (
        inputs : Qubit[], 
        output : Qubit) : Unit is Adj+Ctl {
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

    operation TriangleFreeColoringOracle (
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
                CheckValidTriangle(Arrays.Subarray([a1,a2,a3],colorsRegister),qubitsTriangle[idx]);
            }
            let boolArray = Arrays.ConstantArray(Length(indices),true);
            let CheckTriangleFree = ControlledOnBitString(boolArray,X);
            CheckTriangleFree(qubitsTriangle,target);
            // Reset qubitsTriangle to zeros:
            for idx in 0..Length(indices)-1 {
                let (a1,a2,a3) = indices[idx];
                CheckValidTriangle(Arrays.Subarray([a1,a2,a3],colorsRegister),qubitsTriangle[idx]);
            }
        }
    }

    operation MarkingOracleToPhaseOracle(
        markingOracle : ((Qubit[], Qubit) => Unit is Adj), 
        register : Qubit[]
    ): Unit is Adj {
        use target = Qubit();
        within {
            X(target);
            H(target);
        } apply {
            markingOracle(register, target);
        }
    }

    operation RunGroversAlgorithm(
        register : Qubit[], 
        phaseOracle : ((Qubit[]) => Unit is Adj), 
        iterations : Int) : Unit {
        
        ApplyToEach(H, register);

        for _ in 1 .. iterations {
            phaseOracle(register);
            within {
                ApplyToEachA(H, register);
                ApplyToEachA(X, register);
            } apply {
                Controlled Z(Arrays.Most(register), Arrays.Tail(register));
            }
        }
    }    
    
    @EntryPoint()
    operation SolveStrongInteractiveCivs() : Unit {
        // Graph distription:
        let nCivlizations = 7;
        let relationsDiplomacy = [(0,1),(1,3),(1,5),(2,4),(2,6),(3,5),(4,6)];

        // Oracles that implements this graph.
        let markingOracle = TriangleFreeColoringOracle(nCivlizations, relationsDiplomacy, _, _);
        let phaseOracle = MarkingOracleToPhaseOracle(markingOracle, _);

        // Parameters for Grover Algorithm:
        let searchSpaceSize = 2^nCivlizations;
        let nSolutions = 72;
        let nIterations = Round(PI() / 4.0 * Sqrt(IntAsDouble(searchSpaceSize) / IntAsDouble(nSolutions)));

        mutable answer = new Bool[nCivlizations];
        use (register,output) = (Qubit[nCivlizations],Qubit());
        mutable isCorrect = false;
        repeat {
            RunGroversAlgorithm(register,phaseOracle,nIterations);
            let result = MultiM(register);

            markingOracle(register,output);
            if (MResetZ(output)==One) {
                set isCorrect = true;
                set answer = ResultArrayAsBoolArray(result);
            }
            ResetAll(register);
        } until (isCorrect);
        Message("A balanced international relationship: ");
        for i in 0..Length(relationsDiplomacy)-1 {
            let pairRelation = relationsDiplomacy[i];
            let typeRelation = answer[i] ? "Allied" | "In conflict";
            Message($"Relationship {pairRelation} - {typeRelation}");
        }
    }
}
