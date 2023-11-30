# Advanced-software-engineering--6324-001

This project is concerned with the enhancement of the slither tool . As of this moment we are working on the [Bugs] 
1265 : Slither incorrectly reports internal library function as unused #1265 (https://github.com/crytic/slither/issues/1265).
664: The feature (print call-graph) of Slither cannot correctly distinguish functions with the same name (i.e., overload) in a contract https://github.com/crytic/slither/issues/664

To run the custom call_graph.py and dead_code.py :
1. Place the files in ~/.local/lib/python3.10/site-packages/slither/printers/call/call_graph.py for call-graph and Place for dead-code as follows -> ~/.local/lib/python3.10/site-packages/slither/detectors/functions/dead_code.py
2. once they are placed the custom file and their logic will take over for analysing the certificates.
3. To run dead-code detector : slither contract.sol --dead-code
4. To run call-graph printer : slither contract.sol --print call-graph
   dot -Tpng contract.sol.all_contracts.call-graph.dot  -o demo_graph.png //run the dot command on the dot file generated to get the graph as a png.

Bug fix overview:

=================== 
Bug 1265:
===================

On further inspection of the bug it is evident that the dead-code detector is falsely adding internal function calls that are being used later on in its report. This porject hopes to understand what the issue is and come up with a better logic to filter out the truly unused function calls.

False positive :

Upon successful installation and running we were able to get the below output :

BridgeGovernanceParameters.beginRedemptionTimeoutNotifierRewardMultiplierUpdate(BridgeGovernanceParameters.RedemptionData,uint32) (contracts/bridge/BridgeGovernanceParameters.sol#685-699) is never used and should be removed
BridgeGovernanceParameters.getNewDepositDustThreshold(BridgeGovernanceParameters.DepositData) (contracts/bridge/BridgeGovernanceParameters.sol#355-361) is never used and should be removed
BridgeGovernanceParameters.getNewDepositTreasuryFeeDivisor(BridgeGovernanceParameters.DepositData) (contracts/bridge/BridgeGovernanceParameters.sol#401-407) is never used and should be removed
BridgeGovernanceParameters.getNewDepositTxMaxFee(BridgeGovernanceParameters.DepositData) (contracts/bridge/BridgeGovernanceParameters.sol#442-448) is never used and should be removed
BridgeGovernanceParameters.getNewFraudChallengeDefeatTimeout(BridgeGovernanceParameters.FraudData) (contracts/bridge/BridgeGovernanceParameters.sol#1596-1602) is never used and should be removed
BridgeGovernanceParameters.getNewFraudChallengeDepositAmount(BridgeGovernanceParameters.FraudData) (contracts/bridge/BridgeGovernanceParameters.sol#1549-1555) is never used and should be removed
BridgeGovernanceParameters.getNewFraudNotifierRewardMultiplier(BridgeGovernanceParameters.FraudData) (contracts/bridge/BridgeGovernanceParameters.sol#1688-1694) is never used and should be removed
BridgeGovernanceParameters.getNewFraudSlashingAmount(BridgeGovernanceParameters.FraudData) (contracts/bridge/BridgeGovernanceParameters.sol#1640-1646) is never used and should be removed.........

Of this, on examining for example the first line itself we can see that the function "beginRedemptionTimeoutNotifierRewardMultiplierUpdate" is actually being used in line 649 of "tbtc-v2/solidity/contracts/bridge/BridgeGovernance.sol"

True positive :

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ExampleContract {
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }

    function set(address _newOwner) internal {
        owner = _newOwner;
       
    }

    function get() public view returns (address) {
        return owner;
    }
}
// This is an example of where the dead-code detector is indeed working fine. 
// This is also an internal function however unlike in the other contracts it is truly never used.

// Internal library
library L {
    function add(uint a, uint b) internal pure returns (uint) {
        return a + b;
    }
}

contract testforpositive {
    function test(uint x, uint y) public view returns (uint) {
        // Call the internal library function
        return L.add(x, y);
    }
}


// This is an example of where the dead-code detector is indeed working fine. 
// This is also an internal function which is used. The detector is reporting this correctly.


output : 

INFO:Detectors:
ExampleContract.set(address) (tbtc-v2/solidity/contracts/test.sol#11-14) is never used and should be removed
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code

************************************************************************************************************************************************************************************************************************************************************************
11/06/2023:
************************************************************************************************************************************************************************************************************************************************************************

After taking further look at the issue we were able to find that the internal functions were being flagged by the dead-code detector at the contract they were being defined in. After adding internal functions to the defer list on the detector the unneccesary flags are no longer appearing.

The internal functions can always be imported later on and static analysis has no way of knowing if they will be reused again. Private functions however atleast need to be used in the contract they are defined in :

example -

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

//1

contract ExampleContract {
    address public owner;
    uint public data;

    constructor() {
        owner = msg.sender;
    }

    function set(address _newOwner) internal {
        owner = _newOwner;
       
    }

    function get() public view returns (address) {
        return owner;
    }
     function anotherUnusedFunction() public {
        // This function is also never called
        data = 0;
    }
}

output : 
6324-001' running
No unused functions detected by dead-code detector

//2

contract SimpleContract {
    uint public data;

    constructor() {
        data = 42;
    }

    function updateData(uint _value) public {
        // This is live code
        data = _value;
    }

    function unusedFunction() internal {
        // This function is never called
        data = 0;
    }

    function anotherUnusedFunction() private {
        // This function is also never called
        data = 0;
    }
}

output :
INFO:Detectors:
SimpleContract.anotherUnusedFunction() (test.sol#48-51) is never used and should be removed
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code


Code snippet containg the change in dead-code.py :


 for function in sorted(self.compilation_unit.functions, key=lambda x: x.canonical_name):
            if (
                function.visibility in ["public", "external","internal"]
                or function.is_constructor
                or function.is_fallback
                or function.is_constructor_variables
            ):
                continue
            if function.canonical_name in functions_used:
                continue
            if isinstance(function, FunctionContract) and (
                function.contract_declarer.is_from_dependency()
            ):
                continue
            # Continue if the functon is not implemented because it means the contract is abstract
            if not function.is_implemented:
                continue
            info: DETECTOR_INFO = [function, " is never used and should be removed\n"]
            res = self.generate_result(info)
            results.append(res)
        if(len(results)==0):
             print("No unused functions detected by dead-code detector")
        return results
===============================
Bug 664:
===============================
Initially the printer was ubnable to differentiate between overloaded functions and so we made changes to the _def_process and _function_node functions where we created id's for the functions using a combination of their names and paramters. 

# return unique id for contract function to use as node name
def _function_node(contract: Contract, function: Union[Function, Variable]) -> str:
    parameters_hash = hashlib.sha256("_".join(param.name for param in function.parameters).encode()).hexdigest()
    return f"{contract.id}_{function.name}_{parameters_hash}"


    def _process_function(
    contract: Contract,
    function: FunctionContract,
    contract_functions: Dict[Contract, Set[str]],
    contract_calls: Dict[Contract, Set[str]],
    solidity_functions: Set[str],
    solidity_calls: Set[str],
    external_calls: Set[str],
    all_contracts: Set[Contract],
) -> None:
    # Extract function parameters
    parameters = [param.name for param in function.parameters]

    # Add the node with function name and parameters
    function_identifier = f"{function.name}({', '.join(parameters)})"
    node = _node(_function_node(contract, function), function_identifier)
    contract_functions[contract].add(node)

    for internal_call in function.internal_calls:
        _process_internal_call(
            contract,
            function,
            internal_call,
            contract_calls,
            solidity_functions,
            solidity_calls,
        )
    for external_call in function.high_level_calls:
        _process_external_call(
            contract,
            function,
            external_call,
            contract_functions,
            external_calls,
            all_contracts,
        )


def _process_functions(functions: Sequence[Function]) -> str:
    # TODO  add support for top level function

    contract_functions: Dict[Contract, Set[str]] = defaultdict(
        set
    )  # contract -> contract functions nodes
    contract_calls: Dict[Contract, Set[str]] = defaultdict(set)  # contract -> contract calls edges

    solidity_functions: Set[str] = set()  # solidity function nodes
    solidity_calls: Set[str] = set()  # solidity calls edges
    external_calls: Set[str] = set()  # external calls edges

    all_contracts = set()

    for function in functions:
        if isinstance(function, FunctionContract):
            all_contracts.add(function.contract_declarer)
    for function in functions:
        if isinstance(function, FunctionContract):
            _process_function(
                function.contract_declarer,
                function,
                contract_functions,
                contract_calls,
                solidity_functions,
                solidity_calls,
                external_calls,
                all_contracts,
            )

    render_internal_calls = ""
    for contract in all_contracts:
        render_internal_calls += _render_internal_calls(
            contract, contract_functions, contract_calls
        )

    render_solidity_calls = _render_solidity_calls(solidity_functions, solidity_calls)

    render_external_calls = _render_external_calls(external_calls)

    return render_internal_calls + render_solidity_calls + render_external_calls


class PrinterCallGraph(AbstractPrinter):
    ARGUMENT = "call-graph"
    HELP = "Export the call-graph of the contracts to a dot file"

    WIKI = "https://github.com/trailofbits/slither/wiki/Printer-documentation#call-graph"

    def output(self, filename: str) -> Output:
        """
        Output the graph in filename
        Args:
            filename(string)
        """

        all_contracts_filename = ""
        if not filename.endswith(".dot"):
            if filename in ("", "."):
                filename = ""
            else:
                filename += "."
            all_contracts_filename = f"{filename}all_contracts.call-graph.dot"

        if filename == ".dot":
            all_contracts_filename = "all_contracts.dot"

        info = ""
        results = []
        with open(all_contracts_filename, "w", encoding="utf8") as f:
            info += f"Call Graph: {all_contracts_filename}\n"

            # Avoid duplicate functions due to different compilation unit
            all_functionss = [
                compilation_unit.functions for compilation_unit in self.slither.compilation_units
            ]
            all_functions = [item for sublist in all_functionss for item in sublist]
            all_functions_as_dict = {
                function.canonical_name: function for function in all_functions
            }
            content = "\n".join(
                ["strict digraph {"]
                + [_process_functions(list(all_functions_as_dict.values()))]
                + ["}"]
            )
            f.write(content)
            results.append((all_contracts_filename, content))

        for derived_contract in self.slither.contracts_derived:
            derived_output_filename = f"{filename}{derived_contract.name}.call-graph.dot"
            with open(derived_output_filename, "w", encoding="utf8") as f:
                info += f"Call Graph: {derived_output_filename}\n"
                content = "\n".join(
                    ["strict digraph {"] + [_process_functions(derived_contract.functions)] + ["}"]
                )
                f.write(content)
                results.append((derived_output_filename, content))

        self.info(info)
        res = self.generate_output(info)
        for filename_result, content in results:
            res.add_file(filename_result, content)
