/// @title A soulmate cannot mint more than one soulmate

methods {
    mintSoulmateToken() returns (uint256);
}

rule noExtraSoulmatePossible() {

mintSoulmateToken()

}