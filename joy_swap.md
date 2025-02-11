mint a
```bash
sui client call --package 0x1b1587a13334aaad13e6150a03be6ddf29e57f02e85732d175e3935bd14b2d2f --module a --function mint --args 0x8e7f0c88bb95d2c4a9bc11f27c668a9235ea3fc59122ea94f14ce02007bc00ba 10000000000 <YOU_ADDRESS> --gas-budget 10000000
```

mint b
```bash
sui client call --package 0x10049b536d383a43939e28f2db4077ed5bc6a5e15ffaaf056e906f81448fccf1 --module b --function mint --args 0xa625ca486a648119f6171101298a0536d55b36df9811c218f3c36be45e62a5a3 10000000000 <YOU_ADDRESS> --gas-budget 10000000
```

joy_swap
packageID:`0x4237fdce40e5729345200da42e251d444ec1881afbf542de1b70186843b440e9`
factoryID:`0xec6d3e08796b82f4d1260d764f190e81e27ede1b66c96395226149c74864cfc9`
create_pool:
```bash
sui client call --package 0x4237fdce40e5729345200da42e251d444ec1881afbf542de1b70186843b440e9 --module joy_swap --function create_pool --type-args 0x1b1587a13334aaad13e6150a03be6ddf29e57f02e85732d175e3935bd14b2d2f::a::A 0x10049b536d383a43939e28f2db4077ed5bc6a5e15ffaaf056e906f81448fccf1::b::B --args 0xec6d3e08796b82f4d1260d764f190e81e27ede1b66c96395226149c74864cfc9 <COIN_A_ID> <COIN_B_ID>  --gas-budget 10000000
```
(This pool has been created by me at this step)
![](/images/createPool.png)

add_liquidity:
```bash
sui client call --package 0x4237fdce40e5729345200da42e251d444ec1881afbf542de1b70186843b440e9 --module joy_swap --function add_liquidity --type-args 0x1b1587a13334aaad13e6150a03be6ddf29e57f02e85732d175e3935bd14b2d2f::a::A 0x10049b536d383a43939e28f2db4077ed5bc6a5e15ffaaf056e906f81448fccf1::b::B --args 0x470f4b0f1d2d1706503e34656667a1f829536868be4854ab126300ec46870e0b <COIN_A_ID> <COIN_B_ID>  <AMOUNT> --gas-budget 10000000
```
![](/images/addLiquidity.png) 

remove_liquidity:
```bash
sui client call --package 0x4237fdce40e5729345200da42e251d444ec1881afbf542de1b70186843b440e9 --module joy_swap --function remove_liquidity --type-args 0x1b1587a13334aaad13e6150a03be6ddf29e57f02e85732d175e3935bd14b2d2f::a::A 0x10049b536d383a43939e28f2db4077ed5bc6a5e15ffaaf056e906f81448fccf1::b::B --args 0x470f4b0f1d2d1706503e34656667a1f829536868be4854ab126300ec46870e0b <LP_COIN_ID> <AMOUNT> --gas-budget 10000000
```
![](/images/removeLiquidity.png) 

swap:
```bash
sui client call --package 0x4237fdce40e5729345200da42e251d444ec1881afbf542de1b70186843b440e9 --module joy_swap --function swap_a_to_b --type-args 0x1b1587a13334aaad13e6150a03be6ddf29e57f02e85732d175e3935bd14b2d2f::a::A 0x10049b536d383a43939e28f2db4077ed5bc6a5e15ffaaf056e906f81448fccf1::b::B --args 0x470f4b0f1d2d1706503e34656667a1f829536868be4854ab126300ec46870e0b <COIN_A_ID> <AMOUNT> 10000000000 --gas-budget 10000000
```
![](/images/swap.png) 