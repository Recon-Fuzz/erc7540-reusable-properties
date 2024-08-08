# ERC7540 Reusable Properties

A collection of reusable properties for [ERC-7540](https://eips.ethereum.org/EIPS/eip-7540) Vaults 

Written in collaboration with [Centrifuge](https://centrifuge.io/)

## Specification

| Property | Description | Category |
| --- | --- | --- |
| 7540-1 | `convertToAssets(totalSupply) == totalAssets` unless price is 0.0 | High Level |
| 7540-2 | `convertToShares(totalAssets) == totalSupply` unless price is 0.0 | High Level | 
| 7540-3 | max* never reverts | DOS Invariant | 
| 7540-4 | claiming more than max always reverts | Stateful Test | 
| 7540-5 | requestRedeem reverts if the share balance is less than amount | Stateful Test | 
| 7540-6 | preview* always reverts | Stateful Test |
| 7540-7 | if max[method] > 0, then [method] (max) should not revert | DOS Invariant | 

## Usage

1. Install the repo as a dependency to a Foundry project

```
forge install Recon-Fuzz/erc7540-reusable-properties --no-commit
```

2. Inherit from the `ERC7540Properties` contract in the contract where you've defined your properties. For a test suite harnessed with Recon it will look something like this: 

```solidity
abstract contract Properties is Setup, Asserts, ERC7540Properties {}
```

3. Add a way to change the `actor` state variable in the `ERC7540Properties` contract. The simplest way to do this is by exposing a target function with something like the following implementation: 

```solidity
    function setup_switchActor(uint8 actorIndex) public {
        actor = actorsArray[actorIndex % actorsArray.length];
    }
```

4. The properties defined in the `ERC7540Properties` contract are meant to hold for a vault implementation conforming to the ERC specification. If your implementation doesn't require certain properties to hold you can simply exclude them from your contract in which you define your properties:

```solidity
abstract contract Properties is Setup, Asserts, ERC7540Properties {
    function crytic_erc7540_1() public returns (bool test) {
        test = erc7540_1(address(vault));
    }

    function crytic_erc7540_2() public returns (bool test) {
        test = erc7540_2(address(vault));
    }
}
```

by not adding a wrapper for properties other than `erc7540_2` and `erc7540_2` the other properties defined in `ERC7540Properties` don't get evaluated by the fuzzer.
