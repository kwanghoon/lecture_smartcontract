pragma solidity ^0.5.7;

contract BlockHashTest {
    function getBlockHash(uint _blockNumber) public view returns (bytes32 __blockhash, uint __blockhashToNumber){
        bytes32 _blockhash = blockhash(_blockNumber);
        uint _blockhashToNumber = uint(_blockhash);
        return (_blockhash, _blockhashToNumber);
    }
}
