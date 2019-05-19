# 6장 난수 생성 계약

> 블록체인 애플리케이션 개발 실전 입문 (와타나베 아츠시, 마츠모토 요시카즈, 시미즈 토시야 지음, 양현 옮김/김응수 감수), 위키북스

## 난수 생성 계약의 필요성 

스마트계약을 엔터테인먼트 목적으로 게임 분야에 적용할 때 난수를 생성하여 무작위적인 요소를 만들 필요가 있다. 예를 들어, 주사위를 던져 특정 숫자가 나오면 더 많은 코인을 돌려받는 것을 생각해볼 수 있다. 

서비스에서 난수 생성할 때 3가지 문제를 고려해야 한다. 

- 난수로 생성된 정수 값은 균등하게 분포하는가
- 각 아이템의 정수 범위는 발표된 확률대로 설정되어 있는가
- 게임 운영자나 게임 개발자가 난수를 임의로 조작할 수 있는가

클라이언트-서버 방시에서 이런 추첨 방식을 사용한다면 실제 추첨 로직을 사용자가 확인할 수 없고, 난수 자체의 공정성, 추첨 방식의 공정석을 담보할 수 없다. 또한 운영자가 확률을 조작할 수도 있다. 

기존의 난수 생성 방법은 seed라고 하는 초기화를 위한 숫자  값을 사용하는 난수 생성기를 활용한다.동일한 값으로 초기화된 경우 난수 생성기에서 만들어낸 난수열은 항상 동일해서 예측할 수 있다. 이 난수 값들을 의사 난수(Pseudo-Random Number)라 하고, 이때 사용한 방법을 의사 난수 생성기(PRNG: Pseudo-Random Number Generator)라고 한다. 

이러한 구조의 난수 발생기를 사용하는 경우 공정성의 증명과 담보를 위해서 두 가지 조건이 필요하다. 

- seed 값이 사전에 사용자에게 알려지지 않아야 한다.
- 운영자가 난수를 생성하는데 개임하지 않았음을 증명할 수 있어야 한다. 

스마트 계약을 통해 seed 값, 난수 생성기, 생성된 난수열의 변조 여부를 담보하는 방법을 생각해보자.  

- 난수 생성기와 추첨표를 미리 공개하고, seed 값은 이벤트가 끝난 다음에 공개 
- 이 seed 값이 추첨에 사용되었다는 것을 보여야 한다. 


### 난수 생성 계약 작성  

solc 0.5.7 버전에 맞추어 예제를 수정하였고, 교재 예제와의 차이점은 뒤에 설명

```
pragma solidity ^0.5.7;

contract RandomNumber {
    function get(uint max) public view returns (uint, uint) {
        // (1) 가장 마지막 블록이 생성된 시각을 정수 값으로 반환
        uint block_timestamp = block.timestamp;

        // (2) 그 값을 max로 나눈 나머지를 계산
        // max = 6인 경우 나머지는 0~5의 정수이므로 +1를 해 1~6의 정수로 만든다
        uint mod = block_timestamp % max + 1;

        return (block_timestamp, mod);
    }
}
```
Solidity로 작성한 스마트게약에서 전역 변수 now가 있다. 이 변수는 block.timestamp의 별칭(alias)로 정의되어 있으며, 가장 마지막 블록이 생성된 시간을 표시한 것이다. 예를 들어, 1558215818과 같은 정수 값으로 표시된다. 

### 스마트계약 실행 

교재에서 Remix를 활용하여 다음 과정을 설명한다. 

- 스마트계약을 컴파일하고 배치한 다음 
- get 함수에 인자 6을 주어 반복 실행한다. 

```
0: uint256: 1558215818
1: uint256: 3

0: uint256: 1558215945
1: uint256: 4

0: uint256: 1558215954
1: uint256: 1

0: uint256: 1558215967
1: uint256: 2

0: uint256: 1558215975
1: uint256: 4
```

이 과정을 이더스크립트(Etherscript) 작성하면 다음과 같다.

```
account{balance:1ether} A;

account{contract:"6.2.2.sol", by:A} contract; 

(block_number, rand_number) = contract.get(6);

(block_number, rand_number) = contract.get(6);

(block_number, rand_number) = contract.get(6);
```

(참고) 교재 예제와 위 예제의 차이

```
1c1
< pragma solidity ^0.5.7;
---
> pragma solidity ^0.4.8;
4c4
<     function get(uint max) public view returns (uint, uint) {
---
>     function get(uint max) constant returns (uint, uint) {

```

만일 채굴을 중지한 상태에서 contract.get(6)을 반복해서 난수를 생성하면 블록이 그대로이기 때문에 동일한 난수만 반환되는 현상을 볼 수 있다. 

이처럼 block.timestamp가 변하지 않는 한 여기에 의존하여 생성한 난수도 계속 같은 값이 된다. 동일한 블록체인 네트워크에 연결된 사용자라면 누구나 최근 block.timestamp에 접근할 수 있기 때문에 여기서부터 계산이 시작되는 난수 값도 미리 예측할 수 있다. 

## 예측 곤란성 확보하기  

아래 BlockHashTest 스마트계약에서 블록 번호를 제공하면 해당 블록의 블록 해시 값을 얻을 수 있다. 블록 해시 값은 블록별로 다르며 타임스탬프보다 사전 예측이 곤란한 값으로 처리할 수 있다. 

* [주의] remix에서 현재 마지막 블록 번호를 가져오는 방법이 필요
	* 아래 웹 주소에서 Remix 콘솔에서 사용 방법 ( JavaScript )
	* https://docs.ethers.io/ethers.js/html/api-providers.html#blockchain-status

* Solidity의 block.blockhash() 함수 사용법
	* block.blockhash(uint blockNumber) returns (bytes32)
		* 주어진 블록 번호의 해쉬 값을 리턴
		* 현재 블록을 제외하고 최근 256 블록들에 대해서만 동작 

```
pragma solidity ^0.5.7;

contract BlockHashTest {
    function getBlockHash(uint _blockNumber) public view returns (bytes32 __blockhash, uint __blockhashToNumber){
        bytes32 _blockhash = blockhash(_blockNumber);
        uint _blockhashToNumber = uint(_blockhash);
        return (_blockhash, _blockhashToNumber);
    }
}
```

이제 블록 해시 값을 사용하는 난수 생성 예약 스마트 계약을 구현해보자. 

* 기본 아이디어는 사용자가 난수 생성을 요청하면 예약 번호, 예약 시점의 마지막 블록 번호, 생성된 난수로 구성된 이력 정보를 관리한다. 
* 사용자가 생성된 난수를 가져가려고 시도하면 3가지 결과가 가능하다.
	* 예약 번호가 존재하지 않음
	* 아직 다음 블록이 없음 
	* 다음 블록이 생성되었고 난수도 생성됨 

```
pragma solidity ^0.5.7;

contract RandomNumber {
    address owner;
    // (1) 1~numberMax 의 난수 값을 생성하도록 설정하는 변수
    uint numberMax;

    // (2) 예약 객체
    struct draw {
        uint blockNumber;
        uint drawnNumber;
    }

    // (3) 예약 객체 배열
    struct draws {
        uint numDraws;
        mapping (uint => draw) draws;
    }

    // (4) 사용자(address)별로 예약 배열을 관리
    mapping (address => draws) requests;

    // (5) 이벤트(용도에 대해서는 이후 설명)
    event ReturnNextIndex(uint _index);
    event ReturnDraw(int _status, bytes32 _blockhash, uint _drawnNumber);

    // (6) 생성자
    constructor(uint _max) public {
        owner = msg.sender;
        numberMax = _max;
    }

    // (7) 난수 생성 예약을 추가
    function request() public returns (uint) {
        // (8) 현재 예약 갯수 취득
        uint _nextIndex = requests[msg.sender].numDraws;
        // (9) 마지막 블록의 블록 번호를 기록
        requests[msg.sender].draws[_nextIndex].blockNumber = block.number;
        // (10) 예약 갯수 카운트 증가
        requests[msg.sender].numDraws = _nextIndex + 1;
        // (11) 예약 번호 반환
        emit ReturnNextIndex(_nextIndex);
        return _nextIndex;
    }

    // (12) 예약된 난수 생성 결과 획득 시도
    function get(uint _index) public returns (int status, bytes32 __blockhash, uint __drawnNumber){
        // (13) 존재하지 않는 예약 번호인 경우
        if(_index >= requests[msg.sender].numDraws){
            emit ReturnDraw(-2, 0, 0);
            return (-2, 0, 0);
        // (14) 예약 번호가 존재하는 경우
        }else{
            // (15) 예약시 기록한 block.number의 다음 블록 번호를 계산
            uint _nextBlockNumber = requests[msg.sender].draws[_index]. blockNumber + 1;
            // (16) 아직 다음 블록이 생성되지 않은 경우
            if (_nextBlockNumber >= block.number) {
                emit ReturnDraw(-1, 0, 0);
                return (-1, 0, 0);
            // (17) 다음 블록이 생성됐기 때문에 난수 계산
            }else{
                // (18) 블록 해시 값을 획득
                bytes32 _blockhash = blockhash(_nextBlockNumber);
                // (19) 블록 해시 값에서 난수 값을 계산
                uint _drawnNumber = uint(_blockhash) % numberMax + 1;
                // (20) 계산된 난수 값을 저장
                requests[msg.sender].draws[_index].drawnNumber = _drawnNumber;
                // (21) 결과를 반환
                emit ReturnDraw(0, _blockhash, _drawnNumber);
                return (0, _blockhash, _drawnNumber);
            }
        }
    }
}

```

### 스마트계약 실행 

스마트계약 RandomNumber를 컴파일 후 배치한 다음, 

* request 함수를 호출하여 난수 생성을 예약하고
* 예약 번호 (ReturnNextIndex 이벤트의 index)를 인자로 get 함수를 호출한다. 
	* 앞에서 설명한 3가지 중 하나의 결과를 낸다. 
	* [주의] Remix에서 실행하면 처음 get 함수를 호출하면 정상적으로 -1, 즉 아직 새로 블록이 만들어지지 않았음을 확인할 수 있지만, 다시 호출하면 0이 되지만 블록 해시 값도 0만 읽어와서 제대로 난수를 만들지 못하였다. 


(참고) 교재 예제와 위 예제의 차이

```
1c1
< pragma solidity ^0.5.7;
---
> pragma solidity ^0.4.8;
28c28
<     constructor(uint _max) public {
---
>     function RandomNumber(uint _max) {
34c34
<     function request() public returns (uint) {
---
>     function request() returns (uint) {
42c42
<         emit ReturnNextIndex(_nextIndex);
---
>         ReturnNextIndex(_nextIndex);
47c47
<     function get(uint _index) public returns (int status, bytes32 __blockhash, uint __drawnNumber){
---
>     function get(uint _index) returns (int status, bytes32 blockhash, uint drawnNumber){
50c50
<             emit ReturnDraw(-2, 0, 0);
---
>             ReturnDraw(-2, 0, 0);
58c58
<                 emit ReturnDraw(-1, 0, 0);
---
>                 ReturnDraw(-1, 0, 0);
63c63
<                 bytes32 _blockhash = blockhash(_nextBlockNumber);
---
>                 bytes32 _blockhash = block.blockhash(_nextBlockNumber);
69c69
<                 emit ReturnDraw(0, _blockhash, _drawnNumber);
---
>                 ReturnDraw(0, _blockhash, _drawnNumber);
```

앞의 스마트계약에서 get 함수를 실행하면 트랜잭션으로 처리하기 때문에 응답성이 좋지 않다. ([주의] 앞에서 에러가 발생한 이유?) 트랜잭선으로 처리하는 이유는 난수 계산 결과를 저장하기 때문이다. 사실 예약할 시점의 블록 번호가 저장되어 있다면 언제든지 동일한 난수를 다시 계산할 수 있다. 이 점을 이용해서 앞의 스마트계약을 수정한다.

```
pragma solidity ^0.5.7;

contract RandomNumber {
    address owner;
    uint numberMax;

    struct draw {
        // (1) 예약할 때 마지막 블록 번호만 유지
        uint blockNumber;
    }

    struct draws {
        uint numDraws;
        mapping (uint => draw) draws;
    }

    mapping (address => draws) requests;

    // (2) request()의 반환 값 참조용 이벤트에 정의
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

    // (3) 난수 값 계산 결과를 저장하지 않게끔 변경하고 constant 함수로 변경
    function get(uint _index) public view returns (int status, bytes32 __blockhash, uint __drawnNumber){
        if(_index >= requests[msg.sender].numDraws){
            return (-2, 0, 0);
        }else{
            uint _nextBlockNumber = requests[msg.sender].draws[_index]. blockNumber + 1;
            if (_nextBlockNumber >= block.number) {
                return (-1, 0, 0);
            }else{
                // (4) 매번 블록 번호로부터 블록 해시를 참조해 반환
                bytes32 _blockhash = blockhash(_nextBlockNumber);
                uint _drawnNumber = uint(_blockhash) % numberMax + 1;
                return (0, _blockhash, _drawnNumber);
            }
        }
    }
}
```

(참고) 교재 예제와 위 예제의 차이

```
1c1
< pragma solidity ^0.5.7;
---
> pragma solidity ^0.4.8;
22c22
<     constructor (uint _max) public {
---
>     function RandomNumber(uint _max) {
27c27
<     function request() public returns (uint) {
---
>     function request() returns (uint) {
31c31
<         emit ReturnNextIndex(_nextIndex);
---
>         ReturnNextIndex(_nextIndex);
36c36
<     function get(uint _index) public view returns (int status, bytes32 __blockhash, uint __drawnNumber){
---
>     function get(uint _index) constant returns (int status, bytes32 blockhash, uint drawnNumber){
45c45
<                 bytes32 _blockhash = blockhash(_nextBlockNumber);
---
>                 bytes32 _blockhash = block.blockhash(_nextBlockNumber);
52d51
< 
```

[주의] get 함수를 수정한 다음에도 앞의 문제가 아직 해결되지 않았음 

난수 생성 스마트계약의 한 가지 문제점은 동일한 시점에 request 함수를 호출하면 예약할 때 블록 번호가 같고, 그 결과 다음 블록의 블록 해시도 같기 때문에 최종 생성되는 난수도 동일하다. 

* 실제로 동일한지 확인해보기 위해서 빠르게 request를 반복해서 실행한 다음 각 예약 번호를 입력해 난수를 만들어본다. 

이러한 경우 사용자가 사전에 난수 값을 알 수 있는 것은 아니기 때문에 예측 곤란성이라는 관점에서는 문제가 없다. 하지만 난수로 생성된 값이 균일하게 분포되는가에 관한 문제가 생긴다.

* 예를 들어, 특별한 아이템을 이벤트로 증정하는 경우에 특정 시점에 생성된 난수는 모두 동일하기 때문에 해당 시간에 이벤트에 참여하는 사람은 모두 동일한 아이템을 받는 현상이 벌어질수  있다. 각 아이템 추천을 독립적으로 시행한다고 말하기 힘든 상황인 것이다. 

다음 주제로 각 추첨(난수 생성 예약)마다 독립적인 난수를 생성하는 방법을 알아본다. 


### 난수로서의 균일성 확보하기 

두 가지 문제를 해결하고자 한다.

* 같은 사용자가 같은 시각에 여러 번 난수 요청을 수행하면 동일한 난수가 생성된다. 
* 다른 사용자가 같은 시각에 난수 요청을 하면 동일한 난수가 생성된다. 

해결 방법: 

* 사용자마다 다른 값으로 난수 계산을 진행하기 위하여 사용자 주소(msg.sender)를 이용한다.
* 동일한 사용자의 경우 요청마다 다른 값으로 난수 계산을 진행하기 위하여 예약 번호를 이용한다. 

```
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
```

교재 예제와 차이점 

```
1c1
< pragma solidity ^0.5.7;
---
> pragma solidity ^0.4.8;
20c20
<     constructor (uint _max) public {
---
>     function RandomNumber(uint _max) {
25c25
<     function request() public returns (uint) {
---
>     function request() returns (uint) {
29c29
<         emit ReturnNextIndex(_nextIndex);
---
>         ReturnNextIndex(_nextIndex);
33c33
<     function get(uint _index) public view returns (int, bytes32, bytes32, uint){
---
>     function get(uint _index) constant returns (int status, bytes32 blockhash, bytes32 seed, uint drawnNumber){
41,42c41,42
<                 bytes32 _blockhash = blockhash(_nextBlockNumber);
<                 bytes32 _seed = sha256(abi.encodePacked(_blockhash, msg.sender, _index));
---
>                 bytes32 _blockhash = block.blockhash(_nextBlockNumber);
>                 bytes32 _seed = sha256(_blockhash, msg.sender, _index);
```

교재에 수정된 스마트계약으로 3000개의 난수를 생성하여 정말 균등하게 발생했는가를 살펴본다. 

* 생성된 난수의 빈도를 그래프로 그려 분포를 살펴보고 
* 카이제곱 검정으로 얻은 결과의 편차가 허용 범위에 있는지 확인한다. 


## 외부 정보를 참조하는 방법  

지금까지 스마트계약 내에서 난수를 생성하는 방법을 살펴보았다. 다른 방법으로, 충분히 신뢰할 수 있는 외부 기관으로부터 스마트 계약 안으로 정보를 가져오는 방법으로 난수를 생성할 수도 있다.

이더리움 네트워크 외부와 정보를 연결해주는 서비스를 오라클 또느 외부 오라클이라 한다. 유명한 사례로 Oraclize가 있다.  이것을 이용하여 외부에서 난수 값을 가져와 스마트계약 안에서 참조하는 방법을 시험해본다.  

[주의] Oracleize를 위한 패키지 설치 에러 발생 

먼저 ethereum-bridge를 설치 

```
 git clone https://github.com/oraclize/ethereum-bridge.git
 cd ethereum-bridge/
 npm install
```

Geth를 접속하여 계정 [1]을 준비해두고, 우분투 콘솔에서 ethereum-bridge를 실행한다. 
Oraclize 계약 배포 계정으로 [1]번 계정을 사용한다. 

```
node bridge -H localhost:8545 -a 1 --disable-deterministic-oar
```

위 명령어 실행 결과로 OAR 주소를 복사해둔다. 

```
OAR = OraclizeAddrResolverI(0x55359e7e492218E4CF8112FCe6a8Ef7e319eA4fB);
```

Oaraclize를 사용하기 위하여 usingOraclize를 상속한 계약을 만든다. 

```
pragma solidity ^0.5.7;
import "github.com/oraclize/ethereum-api/oraclizeAPI.sol";

contract RandomNumberOraclized is usingOraclize{
    uint public randomNumber;
    bytes32 public request_id;

    constructor () public {
        // (1) Oraclize Address Resolver를 읽어온다
        // <OAR주소를 지정. deterministic OAR인 경우 이 행은 필요 없다.
        OAR = OraclizeAddrResolverI(0x55359e7e492218E4CF8112FCe6a8Ef7e319eA4fB);
    }

    function request() public {
        // (2) wolframAlpha에서 난수를 받아오도록 의뢰
        // 디버그를 위해 request_id에 Oraclize 처리 의뢰 번호를 저장해둔다
        request_id = oraclize_query("WolframAlpha", "random number between 1 and 6");
    }

    // (3) Oraclize 측에서 외부 처리가 실행되면 이 __callback 함수를 호출한다
    function __callback(bytes32 request_id, string result) {
        if (msg.sender != oraclize_cbAddress()) {
            throw;
        }

        // (4) 실행 결과 result를 drawnNumber에 저장
        randomNumber = parseInt(result);
    }
}
```

[주의] 컴파일 에러 발생 


