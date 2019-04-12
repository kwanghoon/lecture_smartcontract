# 4장 가상 화폐 계약

> 블록체인 애플리케이션 개발 실전 입문 (와타나베 아츠시, 마츠모토 요시카즈, 시미즈 토시야 지음, 양현 옮김/김응수 감수), 위키북스

## 기본기능: 가상 화폐 계약

첫번째 스마트컨트랙트 예제로 계정 A에서 계정 B로 송금하는 시나리오를 구현할 수 있다고 설명한다. 먼저 스마트컨트랙트를 사용하지 않고 송금하는 과정을 설명하고 계정이 보유한 잔액보다 더 많은 금액을 송금하려고 할 때 잔고 부족 에러가 발생하는 것도 설명한다.

### 스마트계약 OreOreCoin 

solc 0.5.7 버전에 맞추어 예제를 수정하였고, 교재 예제와의 차이점은 뒤에 설명

```
pragma solidity ^0.5.7;

contract OreOreCoin {
    // (1) 상태 변수 선언
    string public name; // 토큰 이름
    string public symbol; // 토큰 단위
    uint8 public decimals; // 소수점 이하 자릿수
    uint256 public totalSupply; // 토큰 총량
    mapping (address => uint256) public balanceOf; // 각 주소의 잔고

    // (2) 이벤트 알림
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // (3) 생성자
    constructor(uint256 _supply, string memory _name, string memory _symbol, uint8 _decimals) public {
        balanceOf[msg.sender] = _supply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply;
    }
    
    // (4) 송금
    function transfer(address _to, uint256 _value) public {
        // (5) 부정 송금 확인
        if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        // (6) 송금하는 주소와 송금받는 주소의 잔고 갱신
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        // (7) 이벤트 알림
        emit Transfer(msg.sender, _to, _value);
    }
}
```

### 스마트계약 실행 

교재에서 Remix를 활용하여 다음 과정을 설명한다. 

- 스마트계약을 만들어 계정 A가 10000 오레오레 코인을 갖도록 초기화한다.
- 계정 A에서 스마트계약을 통해 계정 B에게 2000 오레오레 코인을 송금한다.
- 계정 A에서 스마트계약을 통해 계정 B에게 10000 오레오레 코인을 송금하려고 시도하면 잔액 부족 오류가 발생한다.

(참고) 성공적으로 송금(transfer)하면 Transfer 이벤트가 발생한다.

이 과정을 이더스크립트(Etherscript) 작성하면 다음과 같다.

```
account{balance:1ether} A;
account{balance:1ether} B;

account{contract:"ch4_01_OreOreCoin.sol", by:A} contract(10000, "OreOreCoin" ,"oc", 0); 

assert contract.balanceOf[A] == 10000;

contract.transfer(B,2000){by:A};

assert contract.balanceOf[A] == 2000;
assert contract.balanceOf[A] == 8000;
```

(참고) 교재 예제와 위 예제의 차이

```
1c1
< pragma solidity ^0.5.7;
---
> pragma solidity ^0.4.8;
15c15
<     constructor(uint256 _supply, string memory _name, string memory _symbol, uint8 _decimals) public {
---
>     function OreOreCoin(uint256 _supply, string _name, string _symbol, uint8 _decimals) {
24c24
<     function transfer(address _to, uint256 _value) public {
---
>     function transfer(address _to, uint256 _value) {
26,27c26,27
<         if (balanceOf[msg.sender] < _value) revert();
<         if (balanceOf[_to] + _value < balanceOf[_to]) revert();
---
>         if (balanceOf[msg.sender] < _value) throw;
>         if (balanceOf[_to] + _value < balanceOf[_to]) throw;
32c32
<         emit Transfer(msg.sender, _to, _value);
---
>         Transfer(msg.sender, _to, _value);
```



## 추가기능1: 블랙 리스트 

가상 화폐 스마트계약에 블랙 리스트 기능을 추가한다. 

* 블랙리스트에 계정을 추가하거나 그 리스트에서 제외시킬 수 있다.
	* Blacklisted 이벤트
	* DeletedFromBlacklist 이벤트

* 블랙리스트에 포함된 계정에 송금하는 것을 막고, 또한 이 계정에서 임의의 다른 계정으로 송금하는 것도 막는다. 
	* RejectedPaymentToBlacklistedAddr 이벤트
	* RejectedPaymentFromBlacklistedAddr 이벤트 


### 블랙리스트 기능을 갖춘 가상 화폐 계약 

```
pragma solidity ^0.5.7;

// 블랙리스트 기능을 추가한 가상 화폐
contract OreOreCoin {
    // (1) 상태 변수 선언
    string public name; // 토큰 이름
    string public symbol; // 토큰 단위
    uint8 public decimals; // 소수점 이하 자릿수
    uint256 public totalSupply; // 토큰 총량
    mapping (address => uint256) public balanceOf; // 각 주소의 잔고
    mapping (address => int8) public blackList; // 블랙리스트
    address public owner; // 소유자 주소
 
    // (2) 수식자
    modifier onlyOwner() { if (msg.sender != owner) revert(); _; }

    // (3) 이벤트 알림
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Blacklisted(address indexed target);
    event DeleteFromBlacklist(address indexed target);
    event RejectedPaymentToBlacklistedAddr(address indexed from, address indexed to, uint256 value);
    event RejectedPaymentFromBlacklistedAddr(address indexed from, address indexed to, uint256 value);

    // (4) 생성자
    constructor(uint256 _supply, string memory _name, string memory _symbol, uint8 _decimals) public {
        balanceOf[msg.sender] = _supply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply;
        owner = msg.sender; // 소유자 주소 설정
    }
    
    // (5) 주소를 블랙리스트에 등록 
    function blacklisting(address _addr) onlyOwner public {
        blackList[_addr] = 1;
        emit Blacklisted(_addr);
    }
 
    // (6) 주소를 블랙리스트에서 제거
    function deleteFromBlacklist(address _addr) onlyOwner public {
        blackList[_addr] = -1;
        emit DeleteFromBlacklist(_addr);
    }
     
    // (7) 송금
    function transfer(address _to, uint256 _value) public {
        // 부정 송금 확인
        if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();
        // 블랙리스트에 존재하는 주소는 입출금 불가
        if (blackList[msg.sender] > 0) {
            emit RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
        } else if (blackList[_to] > 0) {
            emit RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
        } else {
            balanceOf[msg.sender] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
        }
    }
}
```

### 스마트계약 실행 

교재에서 Remix를 활용하여 다음 과정을 설명한다. 

- 스마트계약을 만들어 계정 A가 10000 오레오레 코인을 갖도록 초기화한다.
- 계정 A에서 스마트계약을 통해 계정 B에게 2000 오레오레 코인을 송금한다.
- 계정 B를 블랙리스트에 추가한다.
- 계정 A에서 계정 B에 송금하면 실패하고, 두 계정의 잔고가 변하지 않는다.
-  반대로 계정 B에서 계정 A에 송금해도 역시 실패하고 잔고는 그대로다.
- 계정 B를 블랙리스트에서 제외한다.
- 계정 A에서 스마트계약을 통해 계정 B에게 2000 오레오레 코인을 송금하고, 두 계정의 잔고를 확인한다. 

(참고) 이더스크립트로 작성한 블랙리스트 가상 화폐 시나리오
```
account{balance:1ether} A;
account{balance:1ether} B;

account{contract:"ch4_02_OreOreCoin.sol", by:A} contract(10000, "OreOreCoin" ,"oc", 0); 

assert contract.balanceOf[A] == 10000;

contract.transfer(B,2000){by:A};

// 이벤트 Transfer{from:A, to:B, value:2000} 발생 

assert contract.balanceOf[A] == 2000;
assert contract.balanceOf[A] == 8000;

contract.blacklisting(B){by:A}

// 이벤트 Blacklisted 발생

contract.transfer(B,2000){by:A};

// 이벤트 RejectedPaymentToBlacklistedAddr{from:A, to:B, value:2000} 발생 

contract.transfer(A,2000){by:B};

// 이벤트 RejectedPaymentFromBlacklistedAddr{from:B, to:A, value;2000} 발생

contract.deleteFromBlacklist(B){by:A};

// 이벤트 DeleteFromBlacklist(B) 발생 

contract.transfer(B,2000){by:A};

assert contract.balanceOf[A] == 4000;
assert contract.balanceOf[A] == 6000;

```

(참고) 교재 예제와 위 예제의 차이

```
1c1
< pragma solidity ^0.5.7;
---
> pragma solidity ^0.4.8;
15c15
<     modifier onlyOwner() { if (msg.sender != owner) revert(); _; }
---
>     modifier onlyOwner() { if (msg.sender != owner) throw; _; }
25c25
<     constructor(uint256 _supply, string memory _name, string memory _symbol, uint8 _decimals) public {
---
>     function OreOreCoin(uint256 _supply, string _name, string _symbol, uint8 _decimals) {
35c35
<     function blacklisting(address _addr) onlyOwner public {
---
>     function blacklisting(address _addr) onlyOwner {
37c37
<         emit Blacklisted(_addr);
---
>         Blacklisted(_addr);
41c41
<     function deleteFromBlacklist(address _addr) onlyOwner public {
---
>     function deleteFromBlacklist(address _addr) onlyOwner {
43c43
<         emit DeleteFromBlacklist(_addr);
---
>         DeleteFromBlacklist(_addr);
47c47
<     function transfer(address _to, uint256 _value) public {
---
>     function transfer(address _to, uint256 _value) {
49,50c49,50
<         if (balanceOf[msg.sender] < _value) revert();
<         if (balanceOf[_to] + _value < balanceOf[_to]) revert();
---
>         if (balanceOf[msg.sender] < _value) throw;
>         if (balanceOf[_to] + _value < balanceOf[_to]) throw;
53c53
<             emit RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
---
>             RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
55c55
<             emit RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
---
>             RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
59c59
<             emit Transfer(msg.sender, _to, _value);
---
>             Transfer(msg.sender, _to, _value);
```

## 추가기능2: 캐시백 

## 추가기능3: 회원 관리

## 추가기능4: 토큰 크라우드 세일

## 추가기능5: 토큰과 이더 에스크로 

