pragma solidity ^0.5.7;     // (1) 버전 프라그마

// (2) 계약 선언
contract HelloWorld {
  // (3) 상태 변수 선언
  string public greeting;
  // (4) 생성자
  constructor(string memory _greeting) public {
    greeting = _greeting;
  }
  // (5) 메서드 선언
  function setGreeting(string memory _greeting) public {
    greeting = _greeting;
  }
  function say() public view returns (string memory) {
    return greeting;
  }
}
