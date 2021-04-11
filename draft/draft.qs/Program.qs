namespace MyDraft {

  open Microsoft.Quantum.Diagnostics;
  open Microsoft.Quantum.Intrinsic;
  open Microsoft.Quantum.Canon;
  open Microsoft.Quantum.Arrays as Arrays;

function whatever(): Unit {
    mutable list = Arrays.EmptyArray<Int>();
    for i in 0..5 {
        set list w/= i <- 0;
    }
    Message("{list}");
    } 
@EntryPoint()
operation PhaseOracle_Demo() : Unit {
    // Allocate 3 qubits in the |000⟩ state
    
    use q = Qubit[5];

    mutable list = Arrays.EmptyArray<Int>();
    for i in 0..5 {
        set list w/= i <- 0;
    }
    whatever();
    Message("{list}");

    use result = Qubit();
    ApplyToEach(H,q);
    let PatternZero = ControlledOnBitString([false, false, true, false, false], X);
    PatternZero(q,result);
    // Prepare an equal superposition of all basis states

    // Print the current state of the system; notice the phases of each basis state
    Message("Starting state (equal superposition of all basis states):");
    DumpMachine();

    ResetAll(q);
}
}
