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

account{contract:"01_OreOreCoin.sol", by:A} contract(10000, "OreOreCoin" ,"oc", 0); 

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

account{contract:"02_OreOreCoin.sol", by:A} contract(10000, "OreOreCoin" ,"oc", 0); 

assert contract.balanceOf[A] == 10000;

contract.transfer(B,2000){by:A};

// 이벤트 Transfer{from:A, to:B, value:2000} 발생 

assert contract.balanceOf[B] == 2000;
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

assert contract.balanceOf[B] == 4000;
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

OreOreCoin 가상 화폐를 사용하는 주소는 각자의 캐시백을 0~100%로 설정하여, 이 주소로 누군가 송금하면 캐시백 비율만큼을 되돌려준다. 각 주소의 캐시백은 그 주소 소유자만 설정할 수 있다. 

### 캐시백 기능을 갖춘 가상 화폐
```
pragma solidity ^0.5.7;

// 캐시백 기능이 추가된 가상 화폐
contract OreOreCoin {
    // (1) 상태 변수 선언
    string public name; // 토큰 이름
    string public symbol; // 토큰 단위
    uint8 public decimals; // 소수점 이하 자릿수
    uint256 public totalSupply; // 토큰 총량
    mapping (address => uint256) public balanceOf; // 각 주소의 잔고
    mapping (address => int8) public blackList; // 블랙리스트
    mapping (address => int8) public cashbackRate; // 각 주소의 캐시백 비율
    address public owner; // 소유자 주소
     
    // 수식자
    modifier onlyOwner() { if (msg.sender != owner) revert(); _; }
     
    // (2) 이벤트 알림
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Blacklisted(address indexed target);
    event DeleteFromBlacklist(address indexed target);
    event RejectedPaymentToBlacklistedAddr(address indexed from, address indexed to, uint256 value);
    event RejectedPaymentFromBlacklistedAddr(address indexed from, address indexed to, uint256 value);
    event SetCashback(address indexed addr, int8 rate);
    event Cashback(address indexed from, address indexed to, uint256 value);
     
    // 생성자
    constructor(uint256 _supply, string memory _name, string memory _symbol, uint8 _decimals) public {
        balanceOf[msg.sender] = _supply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply;
        owner = msg.sender;
    }
     
    // 주소를 블랙리스트에 등록
    function blacklisting(address _addr) onlyOwner public {
        blackList[_addr] = 1;
        emit Blacklisted(_addr);
    }
     
    // 주소를 블랙리스트에서 제거
    function deleteFromBlacklist(address _addr) onlyOwner public {
        blackList[_addr] = -1;
        emit DeleteFromBlacklist(_addr);
    }
     
    // (3) 캐시백 비율 설정
    function setCashbackRate(int8 _rate) public {
        if (_rate < 1) {
           _rate = -1;
        } else if (_rate > 100) {
            _rate = 100;
        }
        cashbackRate[msg.sender] = _rate;
        if (_rate < 1) {
            _rate = 0;
        }
        emit SetCashback(msg.sender, _rate);
    }
     
    // 송금
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
            // (4) 캐시백 금액 계산(각 대상의 캐시백 비율을 사용)
            uint256 cashback = 0;
            if(cashbackRate[_to] > 0) cashback = _value / 100 * uint256(cashbackRate[_to]);
             
            balanceOf[msg.sender] -= (_value - cashback);
            balanceOf[_to] += (_value - cashback);
             
            emit Transfer(msg.sender, _to, _value);
            emit Cashback(_to, msg.sender, cashback);
        }
    }
}
```

### 스마트계약 실행

교재에서 Remix를 활용하여 다음 과정을 설명한다. 

- 스마트계약을 만들어 계정 A가 10000 오레오레 코인을 갖도록 초기화한다.
- 계정 A에서 스마트계약을 통해 계정 B에게 2000 오레오레 코인을 송금한다.
- 계정B의 캐시백을 아직 설정하지 않았기 때문에 송금받은 돈을 모두 받는다.
- 계정 B의 캐시백을 10으로 설정한다.
- 다시 한 번 계정 A에서 스마트계약을 통해 계정 B에게 2000 오레오레 코인을 송금한다.
- 계정 B에 3800(2000+1800)이 되고, 계정 A는 200을 캐시백으로 돌려받았기 때문에 6200(10000-2000-2000+200)이 된다.

이 과정을 이더스크립트로 작성하면 다음과 같다.
```
account{balance:1ether} A;
account{balance:1ether} B;

account{contract:"03_OreOreCoin.sol", by:A} contract(10000, "OreOreCoin" ,"oc", 0); 

assert contract.balanceOf[A] == 10000;

contract.transfer(B,2000){by:A};

// 이벤트 Transfer{from:A, to:B, value:2000} 발생 
// 이벤트 Cashback{from:B, to:A, value:0} 발생

assert contract.balanceOf[B] == 2000;
assert contract.balanceOf[A] == 8000;

contract.setCashbackRate(10){by:B}

// 이벤트 SetCashback{from:B, value:10} 발생

contract.transfer(B,2000){by:A};

// 이벤트 Transfer{from:A, to:B, value:2000} 발생 
// 이벤트 Cashback{from:B, to:A, value:10} 발생

assert contract.balanceOf[B] == 3800;
assert contract.balanceOf[A] == 6200;
```

교재 예제와 차이
```
< pragma solidity ^0.5.7;
---
> pragma solidity ^0.4.8;
16c16
<     modifier onlyOwner() { if (msg.sender != owner) revert(); _; }
---
>     modifier onlyOwner() { if (msg.sender != owner) throw; _; }
28c28
<     constructor(uint256 _supply, string memory _name, string memory _symbol, uint8 _decimals) public {
---
>     function OreOreCoin(uint256 _supply, string _name, string _symbol, uint8 _decimals) {
38c38
<     function blacklisting(address _addr) onlyOwner public {
---
>     function blacklisting(address _addr) onlyOwner {
40c40
<         emit Blacklisted(_addr);
---
>         Blacklisted(_addr);
44c44
<     function deleteFromBlacklist(address _addr) onlyOwner public {
---
>     function deleteFromBlacklist(address _addr) onlyOwner {
46c46
<         emit DeleteFromBlacklist(_addr);
---
>         DeleteFromBlacklist(_addr);
50c50
<     function setCashbackRate(int8 _rate) public {
---
>     function setCashbackRate(int8 _rate) {
60c60
<         emit SetCashback(msg.sender, _rate);
---
>         SetCashback(msg.sender, _rate);
64c64
<     function transfer(address _to, uint256 _value) public {
---
>     function transfer(address _to, uint256 _value) {
66,67c66,67
<         if (balanceOf[msg.sender] < _value) revert();
<         if (balanceOf[_to] + _value < balanceOf[_to]) revert();
---
>         if (balanceOf[msg.sender] < _value) throw;
>         if (balanceOf[_to] + _value < balanceOf[_to]) throw;
71c71
<             emit RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
---
>             RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
73c73
<             emit RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
---
>             RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
82,83c82,83
<             emit Transfer(msg.sender, _to, _value);
<             emit Cashback(_to, msg.sender, cashback);
---
>             Transfer(msg.sender, _to, _value);
>             Cashback(_to, msg.sender, cashback);
```

## 추가기능3: 회원 관리

각 사용자(주소)는 회원 관리 기능을 가지고 있어서 거래 횟수와 최저 거래 금액에 따라 캐시백 비율을 지정할 수 있다. 따라서 회원 관리 스마트계약은 회원별로 거래 횟수와 금액을 기록한다. 거래 횟수와 금액을 충족하면 캐시백 비율을 올린다. 

스마트계약 Owned를 상속받아 스마트계약 Members와 스마트계약 OreOreCoin을 만들었다.
- 스마트계약 Owned은 소유자만 계약을 다른 사람에게 권리를 넘길 수 있는 특징을 제공한다. 
- 스마트계약 Members의 소유자는 회원 등급을 추가와 변경할 수 있고, 코인(으로 설정된 스마트계약)만 거래 내역(횟수와 누적 금액)을 변경할 수 있다. 
- 스마트계약 OreOreCoin의 소유자는 (이 예제에서는 사용하지 않지만) 블랙 리스트 관리를 할 수 있다. 
- Members와 OreOreCoin을 서로 연관짓기 위해 Members에는 setCoin을 OreOreCoin에는 setMembers를 두어 서로 가리킬 수 있도록 한다. 

### 회원 관리 기능을 갖춘 가상 화폐

```
pragma solidity ^0.5.7;

// 소유자 관리용 계약
contract Owned {
    // 상태 변수
    address public owner; // 소유자 주소

    // 소유자 변경 시 이벤트
    event TransferOwnership(address oldaddr, address newaddr);

    // 소유자 한정 메서드용 수식자
    modifier onlyOwner()  { if (msg.sender != owner) revert(); _; }

    // 생성자
    constructor() public {
        owner = msg.sender; // 처음에 계약을 생성한 주소를 소유자로 한다
    }
    
    // (1) 소유자 변경
    function transferOwnership(address _new) onlyOwner public {
        address oldaddr = owner;
        owner = _new;
        emit TransferOwnership(oldaddr, owner);
    }
}

// (2) 회원 관리용 계약
contract Members is Owned {
    // (3) 상태 변수 선언
    address public coin; // 토큰(가상 화폐) 주소
    MemberStatus[] public status; // 회원 등급 배열
    mapping(address => History) public tradingHistory; // 회원별 거래 이력
     
    // (4) 회원 등급용 구조체
    struct MemberStatus {
        string name; // 등급명
        uint256 times; // 최저 거래 회수
        uint256 sum; // 최저 거래 금액
        int8 rate; // 캐시백 비율
    }
    // 거래 이력용 구조체
    struct History {
        uint256 times; // 거래 회수
        uint256 sum; // 거래 금액
        uint256 statusIndex; // 등급 인덱스
    }
 
    // (5) 토큰 한정 메서드용 수식자
    modifier onlyCoin() { if (msg.sender == coin) _; }
     
    // (6) 토큰 주소 설정
    function setCoin(address _addr) onlyOwner public {
        coin = _addr;
    }
     
    // (7) 회원 등급 추가
    function pushStatus(string memory _name, uint256 _times, uint256 _sum, int8 _rate) onlyOwner public {
        status.push(MemberStatus({
            name: _name,
            times: _times,
            sum: _sum,
            rate: _rate
        }));
    }
 
    // (8) 회원 등급 내용 변경
    function editStatus(uint256 _index, string memory _name, uint256 _times, uint256 _sum, int8 _rate) onlyOwner public {
        if (_index < status.length) {
            status[_index].name = _name;
            status[_index].times = _times;
            status[_index].sum = _sum;
            status[_index].rate = _rate;
        }
    }
     
    // (9) 거래 내역 갱신
    function updateHistory(address _member, uint256 _value) onlyCoin public {
        tradingHistory[_member].times += 1;
        tradingHistory[_member].sum += _value;
        // 새로운 회원 등급 결정(거래마다 실행)
        uint256 index;
        int8 tmprate;
        for (uint i = 0; i < status.length; i++) {
            // 최저 거래 횟수, 최저 거래 금액 충족 시 가장 캐시백 비율이 좋은 등급으로 설정
            if (tradingHistory[_member].times >= status[i].times &&
                tradingHistory[_member].sum >= status[i].sum &&
                tmprate < status[i].rate) {
                index = i;
            }
        }
        tradingHistory[_member].statusIndex = index;
    }

    // (10) 캐시백 비율 획득(회원의 등급에 해당하는 비율 확인)
    function getCashbackRate(address _member) view public  returns (int8 rate) {
        rate = status[tradingHistory[_member].statusIndex].rate;
    }
}
     
// (11) 회원 관리 기능이 구현된 가상 화폐
contract OreOreCoin is Owned{
    // 상태 변수 선언
    string public name; // 토큰 이름
    string public symbol; // 토큰 단위
    uint8 public decimals; // 소수점 이하 자릿수
    uint256 public totalSupply; // 토큰 총량
    mapping (address => uint256) public balanceOf; // 각 주소의 잔고
    mapping (address => int8) public blackList; // 블랙리스트
    mapping (address => Members) public members; // 각 주소의 회원 정보
     
    // 이벤트 알림
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Blacklisted(address indexed target);
    event DeleteFromBlacklist(address indexed target);
    event RejectedPaymentToBlacklistedAddr(address indexed from, address indexed to, uint256 value);
    event RejectedPaymentFromBlacklistedAddr(address indexed from, address indexed to, uint256 value);
    event Cashback(address indexed from, address indexed to, uint256 value);
     
    // 생성자
    constructor(uint256 _supply, string memory _name, string memory _symbol, uint8 _decimals) public {
        balanceOf[msg.sender] = _supply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _supply;
    }
 
    // 주소를 블랙리스트에 등록
    function blacklisting(address _addr) onlyOwner public {
        blackList[_addr] = 1;
        emit Blacklisted(_addr);
    }
 
    // 주소를 블랙리스트에서 해제
    function deleteFromBlacklist(address _addr) onlyOwner public {
        blackList[_addr] = -1;
        emit DeleteFromBlacklist(_addr);
    }
 
    // 회원 관리 계약 설정
    function setMembers(Members _members) public {
        members[msg.sender] = Members(_members);
    }

    // 송금
    function transfer(address _to, uint256 _value) public {
        // 부정 송금 확인
        if (balanceOf[msg.sender] < _value) revert();
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();

        // 블랙리스트에 존재하는 계정은 입출금 불가
        if (blackList[msg.sender] > 0) {
            emit RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
        } else if (blackList[_to] > 0) {
            emit RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
        } else {
            // (12) 캐시백 금액을 계산(각 대상의 비율을 사용)
            uint256 cashback = 0;
            if(address(members[_to]) > address(0)) {
                cashback = _value / 100 * uint256(members[_to].getCashbackRate(msg.sender));
                members[_to].updateHistory(msg.sender, _value);
            }
 
            balanceOf[msg.sender] -= (_value - cashback);
            balanceOf[_to] += (_value - cashback);
 
            emit Transfer(msg.sender, _to, _value);
            emit Cashback(_to, msg.sender, cashback);
        }
    }
}
```



### 스마트 계약 실행

- 계정 A에서 Members 스마트계약을 생성한다. 
- 계정 A의 회원 등급을 추가한다. Bronze, 0, 0, 0 / Silver, 5, 500, 5 / Gold, 15, 1500, 10
-계정 B에게 Members 스마트계약의 소유를 넘긴다.
- 계정 A에서 OreOreCoin 스마트계약을 만들고 앞서 만든 Members 스마트계약을 지정한다. 
- 반대로 Members 스마트계약에도 OreOreCoin 스마트게약을 지정한다. 
- 계정 A에서 계정 B로 10000을 송금한 다음 거래 내역을 확인한다. 
- 계정 A의 등급을 올리기 위해 4번 100을 반복해서 송금하면 Silver 등급이 된다. (statusIndex == 1)
- 회원 등급이 Silver인 상태에서 1000을 다시 보내면 5% 캐쉬백 적용을 받아 50을 계정 B가 계정 A에게 50을 돌려준다. 

```
account{balance:1ether} A;
account{balance:1ether} B;

account{contract:"04_OreOreCoin.sol", by:A} membersContract();

membersContract.pushStatus("Bronze",0,0,0);
membersContract.pushStatus("Silver",5,500,5);
membersContract.pushStatus("Gold",15,1500,10);

membersContract.transferOwner(B);

// 이벤트 TransferOwnership{oldaddr:A, newaddr:B} 발생

assert membersContract.owner == B;

account{contract:"04_OreOreCoin.sol", by:A} contract(10000, "OreOreCoin" ,"oc", 0); 

contract.setMembers(membersContract){by:B};
membersContract.setCoin(contract){by:B};

assert contract.balanceOf[A] == 10000;

contract.transfer(B,2000){by:A};

// 이벤트 Transfer{from:A, to:B, value:2000} 발생 
// 이벤트 Cashback{from:B, to:A, value:0} 발생

assert members.tradingHistory(A) == {times:1, sum:2000, statusIndex:0};

contract.transfer(B,100){by:A};
contract.transfer(B,100){by:A};
contract.transfer(B,100){by:A};
contract.transfer(B,100){by:A};
// 4번 Transfer, Cashback 이벤트가 발생 

assert members.tradingHistory(A) == {times:5, sum:2400, statusIndex:1};
// 2400 = 2000 + 100 + 100 + 100 + 100

contract.transfer(B,1000){by:A};

// 이벤트 Transfer{from:A, to:B, value:1000} 발생 
// 이벤트 Cashback{from:B, to:A, value:50} 발생

assert contract.balanceOf[A] == 6650; 
assert contract.balanceOf[B] == 3350;

// 6650 = 10000 - 2000 - 100 x 4 - 1000 + 50
// 3350 = 2000 + 100 x 4 - 50  
```

교재 예제와 차이
```
1c1
< pragma solidity ^0.5.7;
---
> pragma solidity ^0.4.8;
12c12
<     modifier onlyOwner()  { if (msg.sender != owner) revert(); _; }
---
>     modifier onlyOwner() { if (msg.sender != owner) throw; _; }
15c15
<     constructor() public {
---
>     function Owned() {
20c20
<     function transferOwnership(address _new) onlyOwner public {
---
>     function transferOwnership(address _new) onlyOwner {
23c23
<         emit TransferOwnership(oldaddr, owner);
---
>         TransferOwnership(oldaddr, owner);
52c52
<     function setCoin(address _addr) onlyOwner public {
---
>     function setCoin(address _addr) onlyOwner {
57c57
<     function pushStatus(string memory _name, uint256 _times, uint256 _sum, int8 _rate) onlyOwner public {
---
>     function pushStatus(string _name, uint256 _times, uint256 _sum, int8 _rate) onlyOwner {
67c67
<     function editStatus(uint256 _index, string memory _name, uint256 _times, uint256 _sum, int8 _rate) onlyOwner public {
---
>     function editStatus(uint256 _index, string _name, uint256 _times, uint256 _sum, int8 _rate) onlyOwner {
77c77
<     function updateHistory(address _member, uint256 _value) onlyCoin public {
---
>     function updateHistory(address _member, uint256 _value) onlyCoin {
95c95
<     function getCashbackRate(address _member) view public  returns (int8 rate) {
---
>     function getCashbackRate(address _member) constant returns (int8 rate) {
120c120
<     constructor(uint256 _supply, string memory _name, string memory _symbol, uint8 _decimals) public {
---
>     function OreOreCoin(uint256 _supply, string _name, string _symbol, uint8 _decimals) {
129c129
<     function blacklisting(address _addr) onlyOwner public {
---
>     function blacklisting(address _addr) onlyOwner {
131c131
<         emit Blacklisted(_addr);
---
>         Blacklisted(_addr);
135c135
<     function deleteFromBlacklist(address _addr) onlyOwner public {
---
>     function deleteFromBlacklist(address _addr) onlyOwner {
137c137
<         emit DeleteFromBlacklist(_addr);
---
>         DeleteFromBlacklist(_addr);
141c141
<     function setMembers(Members _members) public {
---
>     function setMembers(Members _members) {
144c144
< 
---
>  
146c146
<     function transfer(address _to, uint256 _value) public {
---
>     function transfer(address _to, uint256 _value) {
148,149c148,149
<         if (balanceOf[msg.sender] < _value) revert();
<         if (balanceOf[_to] + _value < balanceOf[_to]) revert();
---
>         if (balanceOf[msg.sender] < _value) throw;
>         if (balanceOf[_to] + _value < balanceOf[_to]) throw;
153c153
<             emit RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
---
>             RejectedPaymentFromBlacklistedAddr(msg.sender, _to, _value);
155c155
<             emit RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
---
>             RejectedPaymentToBlacklistedAddr(msg.sender, _to, _value);
159c159
<             if(address(members[_to]) > address(0)) {
---
>             if(members[_to] > address(0)) {
167,168c167,168
<             emit Transfer(msg.sender, _to, _value);
<             emit Cashback(_to, msg.sender, cashback);
---
>             Transfer(msg.sender, _to, _value);
>             Cashback(_to, msg.sender, cashback);
```


## 추가기능4: 토큰 크라우드 세일

### 토큰 크라우드 기능을 갖춘 가상 화폐

```
```

### 스마트 계약 실행

```
```

교재 예제와 차이
```
```

## 추가기능5: 토큰과 이더 에스크로 

### 중개자(에스크로)를 갖춘 가상 화폐

```
```

### 스마트 계약 실행

```
```

교재 예제와 차이
```
```



