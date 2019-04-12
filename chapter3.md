# 3장 스마트 계약 입문

> 블록체인 애플리케이션 개발 실전 입문 (와타나베 아츠시, 마츠모토 요시카즈, 시미즈 토시야 지음, 양현 옮김/김응수 감수), 위키북스

## 스마트 계약 개

스마트 계약은 블록체인에서 동작하는 응용 프로그램 단위다. Solidity와 같은 고급 언어로 작성하고 컴파일러를 통해 EVM(Ethereum Virtual Machine) 바이트코드로 만들어 블록체인에 배포한다. 

이더리움 계약을 만들기 위해사 사용하는 프로그래밍 언어로 Solidity, Serpent, LLL 등이 있다. 이 중 Solidity를 사용한다. 

* solc를 설치하고 geth를 실행해서 콘솔에 접속한다. 

```
 $ nohup geth --networkid 4649 --nodiscover --maxpeers 0 --datadir /home/khchoi/data_testnet/ --mine --minerthreads 1 --rpc --rpcapi "admin,db,eth,debug,miner,net,shh,txpool,personal,web3" 2>> /home/khchoi/data_testnet/geth.log &
[2] 2898
$ geth attach rpc:http://localhost:8545
Welcome to the Geth JavaScript console!

instance: Geth/v1.8.23-stable-c9427004/linux-amd64/go1.10.4
coinbase: 0x65d1ad661967de6cdf65b8571d1cfb3dd37060af
at block: 1489 (Mon, 08 Apr 2019 18:56:43 KST)
 datadir: /home/khchoi/data_testnet
 modules: admin:1.0 debug:1.0 eth:1.0 miner:1.0 net:1.0 personal:1.0 rpc:1.0 txpool:1.0 web3:1.0
```
* solc 경로를 설정한다. 참고로 solc는 /usr/bin/solc에 설치되어 있다.

```
{
	"config": {},
	"nonce": "0x0000000000000042",
	"timestamp": "0x0",
	"parentHash": "0x0000000000000000000000000000000000000000000000000000000000000000",
	"gasLimit": "0x8000000",
	"difficulty": "0x4000",
	"mixhash": "0x0000000000000000000000000000000000000000000000000000000000000000",
	"alloc": {}
}
```
## Geth 초기화 

* geth 클라이언트 디렉토리 data_testnet을 만들고, 제네식스 블록을 만들기 위한 정보 genensis.json를 복사한 다음, geth 초기화 명령을 실행

```
$ mkdir ./data_testnet
$ cd data_testnet/
$ pwd
/home/khchoi/data_testnet

$ cp ~/work/security/blockchain-solidity-master/appendix/genesis.json .

$ geth --datadir /home/khchoi/data_testnet init ./genesis.json 
INFO [04-08|10:12:10.318] Maximum peer count                       ETH=25 LES=0 total=25
INFO [04-08|10:12:10.319] Allocated cache and file handles         database=/home/khchoi/data_testnet/geth/chaindata cache=16 handles=16
INFO [04-08|10:12:10.330] Writing custom genesis block 
INFO [04-08|10:12:10.330] Persisted trie from memory database      nodes=0 size=0.00B time=2.48µs gcnodes=0 gcsize=0.00B gctime=0s livenodes=1 livesize=0.00B
INFO [04-08|10:12:10.330] Successfully wrote genesis state         database=chaindata                                hash=4b7556…13cf12
INFO [04-08|10:12:10.330] Allocated cache and file handles         database=/home/khchoi/data_testnet/geth/lightchaindata cache=16 handles=16
INFO [04-08|10:12:10.340] Writing custom genesis block 
INFO [04-08|10:12:10.340] Persisted trie from memory database      nodes=0 size=0.00B time=4.589µs gcnodes=0 gcsize=0.00B gctime=0s livenodes=1 livesize=0.00B
INFO [04-08|10:12:10.341] Successfully wrote genesis state         database=lightchaindata                                hash=4b7556…13cf12

$ tree
.
├── genesis.json
├── geth
│   ├── chaindata
│   │   ├── 000001.log
│   │   ├── CURRENT
│   │   ├── LOCK
│   │   ├── LOG
│   │   └── MANIFEST-000000
│   └── lightchaindata
│       ├── 000001.log
│       ├── CURRENT
│       ├── LOCK
│       ├── LOG
│       └── MANIFEST-000000
└── keystore

4 directories, 11 files
```

## 계정 만들기

* geth 클라이언트를 콘솔 모드로 실행 

```
geth --networkid 4649 --nodiscover --maxpeers 0 --datadir /home/khchoi/data_testnet console 2>> /home/khchoi/data_testnet/geth.log
Welcome to the Geth JavaScript console!

instance: Geth/v1.8.23-stable-c9427004/linux-amd64/go1.10.4
 modules: admin:1.0 debug:1.0 eth:1.0 ethash:1.0 miner:1.0 net:1.0 personal:1.0 rpc:1.0 txpool:1.0 web3:1.0
```

* 계정을 만들기
	* 계정 2개를 만들어 패스워드로 각각 pass0와 pass1을 지정
```
> personal.newAccount("pass0")

"0x65d1ad661967de6cdf65b8571d1cfb3dd37060af"
> eth.accounts

["0x65d1ad661967de6cdf65b8571d1cfb3dd37060af"]
> personal.newAccount("pass1")

"0x750846fbafb34b77d2cf6690dc1774763f2753da"
> eth.accounts

["0x65d1ad661967de6cdf65b8571d1cfb3dd37060af", "0x750846fbafb34b77d2cf6690dc1774763f2753da"]
> eth.accounts[0]

"0x65d1ad661967de6cdf65b8571d1cfb3dd37060af"
> eth.accounts[1]

"0x750846fbafb34b77d2cf6690dc1774763f2753da"
```

* geth 클라이언트 콘솔 모드를 종료하기

```
>  exit
```

* 리눅스 쉘에서 계정 만들기

```
$ geth --datadir /home/khchoi/data_testnet account new
INFO [04-08|10:23:24.037] Maximum peer count                       ETH=25 LES=0 total=25
Your new account is locked with a password. Please give a password. Do not forget this password.
!! Unsupported terminal, password will be echoed.
Passphrase: pass2
Repeat passphrase: pass2 
Address: {31642fbed9347d373129f481afc511e8faef55b4}

$ geth --datadir /home/khchoi/data_testnet account list
INFO [04-08|10:23:43.173] Maximum peer count                       ETH=25 LES=0 total=25
Account #0: {65d1ad661967de6cdf65b8571d1cfb3dd37060af} keystore:///home/khchoi/data_testnet/keystore/UTC--2019-04-08T01-22-26.243234170Z--65d1ad661967de6cdf65b8571d1cfb3dd37060af
Account #1: {750846fbafb34b77d2cf6690dc1774763f2753da} keystore:///home/khchoi/data_testnet/keystore/UTC--2019-04-08T01-22-41.149478537Z--750846fbafb34b77d2cf6690dc1774763f2753da
Account #2: {31642fbed9347d373129f481afc511e8faef55b4} keystore:///home/khchoi/data_testnet/keystore/UTC--2019-04-08T01-23-32.088101366Z--31642fbed9347d373129f481afc511e8faef55b4

$ tree
.
├── genesis.json
├── geth
│   ├── LOCK
│   ├── chaindata
│   │   ├── 000002.ldb
│   │   ├── 000003.log
│   │   ├── CURRENT
│   │   ├── CURRENT.bak
│   │   ├── LOCK
│   │   ├── LOG
│   │   └── MANIFEST-000004
│   ├── lightchaindata
│   │   ├── 000001.log
│   │   ├── CURRENT
│   │   ├── LOCK
│   │   ├── LOG
│   │   └── MANIFEST-000000
│   ├── nodekey
│   ├── nodes
│   │   ├── 000001.log
│   │   ├── CURRENT
│   │   ├── LOCK
│   │   ├── LOG
│   │   └── MANIFEST-000000
│   └── transactions.rlp
├── geth.log
├── history
└── keystore
    ├── UTC--2019-04-08T01-22-26.243234170Z--65d1ad661967de6cdf65b8571d1cfb3dd37060af
    ├── UTC--2019-04-08T01-22-41.149478537Z--750846fbafb34b77d2cf6690dc1774763f2753da
    └── UTC--2019-04-08T01-23-32.088101366Z--31642fbed9347d373129f481afc511e8faef55b4

5 directories, 26 files
```

* 백그라운드로 geth를 실행하기

```
$ nohup geth --networkid 4649 --nodiscover --maxpeers 0 --datadir /home/khchoi/data_testnet/ --mine --minerthreads 1 --rpc --rpcapi "admin,db,eth,debug,miner,net,shh,txpool,personal,web3" 2>> /home/khchoi/data_testnet/geth.log &

$ ps
  PID TTY          TIME CMD
 6795 pts/0    00:00:00 bash
11775 pts/0    00:00:02 geth
11791 pts/0    00:00:00 ps
```

* 백그라운드로 실행 중인 geth에 접속하기

```
$ geth attach rpc:http://localhost:8545
Welcome to the Geth JavaScript console!

instance: Geth/v1.8.23-stable-c9427004/linux-amd64/go1.10.4
coinbase: 0x65d1ad661967de6cdf65b8571d1cfb3dd37060af
at block: 45 (Mon, 08 Apr 2019 10:32:00 KST)
 datadir: /home/khchoi/data_testnet
 modules: admin:1.0 debug:1.0 eth:1.0 miner:1.0 net:1.0 personal:1.0 rpc:1.0 txpool:1.0 web3:1.0
```

* 이더리움에서 마이닝을 통해 트랜잭션을 블록에 기록한다. 
	* 백그라운드 이더리움 클라이언트를 실행할 때 --mine 옵션을 지정하여 계속 마이닝을 진행
	* 마이닝 결과 블록체인의 길이가 늘어나고 이때 accounts[0]가 마이닝 인센티브를 받음
	* 마이닝 인센티브를 받는 계정을 coinbase로 지정 

* 현재 마이닝을 진행하고 있음을 확인

```
> eth.mining

true
```

* 초기 지정한 블록을 확인 
	* genesis.json 내용과 비교하면 일치함을 알 수 있다.

```
> eth.getBlock(0)

{
  difficulty: 16384,
  extraData: "0x",
  gasLimit: 134217728,
  gasUsed: 0,
  hash: "0x4b7556eb256a3c9fa1539df3f660fa7326927e8f16da9270f77568956613cf12",
  logsBloom: "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  miner: "0x0000000000000000000000000000000000000000",
  mixHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
  nonce: "0x0000000000000042",
  number: 0,
  parentHash: "0x0000000000000000000000000000000000000000000000000000000000000000",
  receiptsRoot: "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
  sha3Uncles: "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
  size: 507,
  stateRoot: "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
  timestamp: 0,
  totalDifficulty: 16384,
  transactions: [],
  transactionsRoot: "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
  uncles: []
}
```

* 백그라운드로 마이닝을 진행하고 있기 때문에 블록 길이가 늘어나 있다.
	* 현재 블록 번호를 확인하면 58이다.
	* 58번 블록을 확인하면 내용을 이해할 수는 없지만 0번 블록과 내용이 다름을 확인할 수 있다.
	* 마이닝 인센티브를 계정 0가 받는 것으로 설정되어 있기 때문에 이 계정의 잔고는 315000000000000000000인데
	* 나머지 게정 1과 2의 잔고는 0이다.
	
```
> eth.blockNumber

58
> eth.getBlock(58)

{
  difficulty: 134745,
  extraData: "0xd883010817846765746888676f312e31302e34856c696e7578",
  gasLimit: 126823415,
  gasUsed: 0,
  hash: "0x92ef9f38474683dff76047e51cd5048134fbedb45686459b4e5ebf5cf8f7e51c",
  logsBloom: "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  miner: "0x65d1ad661967de6cdf65b8571d1cfb3dd37060af",
  mixHash: "0x437e74cfffbe03978c0132623a3b7c73e38f1c309f39a1fc40a5a715e27d992f",
  nonce: "0x2893acf82c5925c9",
  number: 58,
  parentHash: "0x81a5259ad977a23cdc07e997bf184db2731dfe11bc639f4dccbda3c16e2e16bc",
  receiptsRoot: "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
  sha3Uncles: "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
  size: 537,
  stateRoot: "0x26df49e225513c742fa0865c341b7ed7e8a44374a43b085393b7fbc6c042be06",
  timestamp: 1554687147,
  totalDifficulty: 7724677,
  transactions: [],
  transactionsRoot: "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
  uncles: []
}
> eth.getBalance(eth.accounts[0])

315000000000000000000
> eth.getBalance(eth.accounts[1])

0
> eth.getBalance(eth.accounts[2])

0
```

* 계정 0에서 계정 1로 10,000 Wei를 보낸다.
	* 처음 시도에서 에러가 난다. 그 이유는 계정에서 실수로 송금하는 것을 방지하기 위해 lock을 걸어두었는데 이것을 먼저 풀고 송금해야 한다.

```
> eth.sendTransaction({from:eth.accounts[0], to:eth.accounts[1], value:100000})

Error: authentication needed: password or unlock
    at web3.js:3143:20
    at web3.js:6347:15
    at web3.js:5081:36
    at <anonymous>:1:1

> personal.unlockAccount(eth.accounts[0])

Unlock account 0x65d1ad661967de6cdf65b8571d1cfb3dd37060af
!! Unsupported terminal, password will be echoed.
Passphrase: pass0
true

> eth.sendTransaction({from:eth.accounts[0], to:eth.accounts[1], value:100000})

"0x70b7aa93bc8eeb807b654bd624d68013cb320c1047413104b5deea9b32f7b9e2"
```

* 송금하는 트랜잭션을 만들었고 이 트랜잭션의 고유 번호를 확인할 수 있다.
	* 이 트랜잭션 고유 번호로 블록체인에 기록될 내용을 확인할 수 있다.

```
> eth.getTransaction("0x70b7aa93bc8eeb807b654bd624d68013cb320c1047413104b5deea9b32f7b9e2")

{
  blockHash: "0x6e142c41b80ceb3490cb2b82fa6b6bd432e3fe4b663a2664918233208f914f3d",
  blockNumber: 101,
  from: "0x65d1ad661967de6cdf65b8571d1cfb3dd37060af",
  gas: 90000,
  gasPrice: 1000000000,
  hash: "0x70b7aa93bc8eeb807b654bd624d68013cb320c1047413104b5deea9b32f7b9e2",
  input: "0x",
  nonce: 0,
  r: "0x570c291a23fe669ce22795aed11dd02defca8a50d609655324e8e730e53ac003",
  s: "0x5551d933bb3d1eb8c34bce5f4c54df8dd0f36cd447e21d2850f439eaf8f505b0",
  to: "0x750846fbafb34b77d2cf6690dc1774763f2753da",
  transactionIndex: 0,
  v: "0x1b",
  value: 100000
}
```

* 현재 블록에 기록되지 않은 상태로 남아 있는(Pending) 트랜잭션 목록을 확인할 수 있다.
	* []으로 비어 있다. 그 이유는 백그라운드로 마이닝을 진행하고 있기 때문에 트랜잭션을 제출하면 바로 마이닝을 통해 완료되었기 때문이다.
	
```
> eth.pendingTransactions

[]
> eth.mining

true
> eth.hashrate

48665
> eth.blockNumber

124
```

* 그럼 마이닝을 임시로 중단시키고 트랜잭션을 만들어보자.

```
> miner.stop()

null
> eth.mining

false
> eth.hashrate

46278
> eth.blockNumber

126
```

* 마이닝 인센티비를 받아갈 계정 coinbase를 보면 계정 0와 일치함을 확인할 수 있다.

```
> eth.coinbase

"0x65d1ad661967de6cdf65b8571d1cfb3dd37060af"

> eth.accounts[0]

"0x65d1ad661967de6cdf65b8571d1cfb3dd37060af"
```

*  다시 계정 0에서 계정 1로 100,000 Wei를 송금해보자. 얼마 전에(300초 이내) 계정 0의 lock을 해제해놓았기 때문에 바로 트랜잭션을 만들어 제출할 수 있다. 
	* 마이닝을 멈춤 상태에서 미처리된 트랜잭션을 확인하고
	* 3가지 계정의 현재 잔고를 확인하자.
	* 그런 다음 마이닝을 다시 재개하면 트랜잭션이 처리되고 송금이 된다.
	* 마이닝을 멈추었을 때 126번 블록까지 만들었으므로 새로 마이닝을 시작하면 127번 블록을 만들 것이고, 이 블록에 송금 트랜잭션을 기록되었을 것이다. 
	* 127번 블록에 방금 처리한 송금 트랜잭션이 기록되어 있음을 확인한다.

```
> eth.sendTransaction({from:eth.accounts[0], to:eth.accounts[1], value:100000})

"0xd01b0215b1d254bf7d6a02bd5ce6612c563e39d6926c8a472fff692f6ed17710"

> eth.pendingTransactions

[{
    blockHash: null,
    blockNumber: null,
    from: "0x65d1ad661967de6cdf65b8571d1cfb3dd37060af",
    gas: 90000,
    gasPrice: 1000000000,
    hash: "0xd01b0215b1d254bf7d6a02bd5ce6612c563e39d6926c8a472fff692f6ed17710",
    input: "0x",
    nonce: 1,
    r: "0x6b87e1101f7b44b7af4f5ec7acc22405fcc13b9bab93d5accee157741ba0bce5",
    s: "0x4c10fb311323c5f0297dfa477d148f9460631744ee0933f943fbfe3f7085c82d",
    to: "0x750846fbafb34b77d2cf6690dc1774763f2753da",
    transactionIndex: 0,
    v: "0x1b",
    value: 100000
}]
> eth.getBalance(eth.accounts[0])

629999999999999900000
> eth.getBalance(eth.accounts[1])

100000
> eth.getBalance(eth.accounts[2])

0
> miner.start(1)

null
> eth.mining

true
> eth.pendingTransactions

[]
> eth.getBalance(eth.accounts[0])

659999999999999800000
> eth.getBalance(eth.accounts[1])

200000
> eth.getBalance(eth.accounts[2])

0
> eth.blockNumber

140
> eth.getBlock(127)

{
  difficulty: 139189,
  extraData: "0xd883010817846765746888676f312e31302e34856c696e7578",
  gasLimit: 118555453,
  gasUsed: 21000,
  hash: "0xd1c59866fef39eef9dc9dfe5d129db49439e2036b693570fa5461ec5216f4b8d",
  logsBloom: "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  miner: "0x65d1ad661967de6cdf65b8571d1cfb3dd37060af",
  mixHash: "0x6be690158a1fff51effb85d0a6a11109cf9d5ff44d86f5155661618474bae40d",
  nonce: "0x283004adfd866140",
  number: 127,
  parentHash: "0x4e4c6871b4349888f6b95eece557a2ad2e707e01cf596626cac3306dbe74c140",
  receiptsRoot: "0x4a57e95b8a2e15ed1d5a5a22873a93d7476e8f18524f97eab25e9f1b1ddb21ff",
  sha3Uncles: "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
  size: 645,
  stateRoot: "0xba01f2849dd9827954e2ccab53ec0ce99e7ab2ab154fb8cce5e2e5ed527201a0",
  timestamp: 1554687633,
  totalDifficulty: 17181372,
  transactions: ["0xd01b0215b1d254bf7d6a02bd5ce6612c563e39d6926c8a472fff692f6ed17710"],
  transactionsRoot: "0x36e1606c67eaa9e9a6a65c1c48353dd9db5fd2f8ca4ba346ac0188cc8e27bce0",
  uncles: []
}
```

* 이번에는 계정 1에서 계정 2로 송금하면 계정 1의 잔고에서 송금한 금액 뿐만 아니라 송금 트랜잭션 처리에 필요한 Gas 금액도 차감되었음을 확인하자. 
	* 현재 계정 1의 잔고는 100,000 Wei로 송금 트랜잭션 처리에도 부족하다. 따라서 일단 계정 0에서 계정 1로 1 ether를 먼저 송금한 다음, 처리한다.
	* 트랜잭션 처리가 완료하기 까지 마이닝을 위한 시간이 필요하다. 송금 후 계정 1의 잔고를 확인해보면 처음에는 송금이 되지 않은 상태의 잔고를 볼 수 있지만 오래지 않아 송금 후 잔고를 볼 수 있다.
	* 계정 1의 잔고에서 계정 2에 보낸 100,000 Wei가 빠져나간것 외에도 2.1e+13 Gas 금액도 차감되었다.
	* 계정 2의 잔고는 송금받은 금액과 일치한다.

```
> personal.unlockAccount(eth.accounts[0])

Unlock account 0x65d1ad661967de6cdf65b8571d1cfb3dd37060af
Passphrase: pass0
true
> eth.getBalance(eth.accounts[0])

1.1349999999999998e+21
> eth.sendTransaction({from:eth.accounts[0], to:eth.accounts[1], value:web3.toWei(1,"ether")})

"0xf81b544d6d30427254d556c8e20427c40469f6707533111b5b628f02c55213e1"

> eth.getBalance(eth.accounts[1])

1000000000000200000
> eth.sendTransaction({from:eth.accounts[1], to:eth.accounts[2], value:100000})

"0x20c54b66a170d59e7adb382a6c9cf1069864ee65f6aae806594f7578e6199bd3"
> eth.getBalance(eth.accounts[1])

1000000000000200000
> eth.getBalance(eth.accounts[1])

999979000000100000
> eth.getBalance(eth.accounts[2])

100000
> exit

```



