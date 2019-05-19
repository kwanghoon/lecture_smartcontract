pragma solidity ^0.5.7;

contract RandomNumber {
    address owner;
    uint numberMax;

    struct draw {
        uint blockNumber;
    }

    struct draws {
        uint numDraws;
        mapping (uint => draw) draws;
    }

    mapping (address => draws) requests;

    event ReturnNextIndex(uint _index);

    constructor (uint _max) public {
        owner = msg.sender;
        numberMax = _max;
    }

    function request() public returns (uint) {
        uint _nextIndex = requests[msg.sender].numDraws;
        requests[msg.sender].draws[_nextIndex].blockNumber = block.number;
        requests[msg.sender].numDraws = _nextIndex + 1;
        emit ReturnNextIndex(_nextIndex);
        return _nextIndex;
    }

    function get(uint _index) public view returns (int, bytes32, bytes32, uint){
        if(_index >= requests[msg.sender].numDraws){
            return (-2, 0, 0, 0);
        }else{
            uint _nextBlockNumber = requests[msg.sender].draws[_index]. blockNumber + 1;
            if (_nextBlockNumber >= block.number) {
                return (-1, 0, 0, 0);
            }else{
                bytes32 _blockhash = blockhash(_nextBlockNumber);
                bytes32 _seed = sha256(abi.encodePacked(_blockhash, msg.sender, _index));
                uint _drawnNumber = uint(_seed) % numberMax + 1;
                return (0, _blockhash, _seed, _drawnNumber);
            }
        }
    }
}
