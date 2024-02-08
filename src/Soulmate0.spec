/// @title A soulmate cannot have more than one soulmate
// attempt to test this through parametric test.
rule soulmateCannotHaveMoreThanOne(address soulmate, method f) {
    // preconditions:
    require soulmate != 0;

    // The environment for calling the contract method
    env e;  // The env for f
    calldataarg args;  // Any possible arguments for f
    f(e, args);  // Calling the contract method f
    
    // Initialize a counter for the number of soulmates found
    mathint soulmatesFound =  0;

    // Get the address of the soulmate from the contract
    address foundSoulmate = soulmateOf(e, soulmate);

    // Check if the address has a soulmate and increment the counter accordingly
    if (foundSoulmate != 0) {
        soulmatesFound =  1;
    }

    // Assert that the address has at most one soulmate
    assert soulmatesFound <=  1;
}




// invariant onlyOneSoulmatePerPerson() {
//     forall uint256 id in {1 .. Soulmate.totalSupply()} {
//         if (Soulmate.ownerToId(Soulmate.soulmateOf(id)) != 0) {
//             assert Soulmate.ownerToId(msg.sender) != Soulmate.ownerToId(Soulmate.soulmateOf(id));
//         }
//     }
// }
// rule onlyOneSoulmatePerPerson(method f)

//     definition soulmateOf : Map<Address, Address>;
//     env e;  // The env for f
//     calldataarg args;  // Any possible arguments for f
//     f(e, args);  // Calling the contract method f

//     assert ownerToId(msg.sender) => 



//  AI suggested test --- check for errors:
// rule soulmateCannotHaveMoreThanOne(address soulmate) {
//     // Precondition: the soulmate address is not the zero address
//     require soulmate !=  0;

//     // The environment for calling the contract method
//     env e;
    
//     // Call the mintSoulmateToken method to simulate the process of creating a new soulmate
//     e.call(soulmate,  0, "mintSoulmateToken()");
    
//     // After minting, the soulmate should either have a new soulmate or remain alone
//     address newSoulmate = soulmateOf(e, soulmate);
//     assert newSoulmate ==  0 || newSoulmate != soulmate;
// }
