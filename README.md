# ERC7540 Reusable Properties

A collection of reusable properties or [ERC-7540](https://eips.ethereum.org/EIPS/eip-7540) Vaults 

Written in collaboration with [Centrifuge](https://centrifuge.io/)

## Specification

| Property | Description | Category
| --- | --- | --- | --- | --- |
| 7540-1 | `convertToAssets(totalSupply) == totalAssets` unless price is 0.0 | High Level
| 7540-2 | `convertToShares(totalAssets) == totalSupply` unless price is 0.0 | High Level
| 7540-3 | max* never reverts | DOS Invariant
| 7540-4 | claiming more than max always reverts | Stateful Test
| 7540-5 | requestRedeem reverts if the share balance is less than amount | Stateful Test
| 7540-6 | preview* always reverts | Stateful Test 
| 7540-7 | if max[method] > 0, then [method] (max) should not revert | DOS Invariant

## Usage

- Install the repo

```
forge install Recon-Fuzz/erc7540-reusable-properties --no-commit
```

- Import the Contract

- Add a way to change the `actor`

- Use the tests you want!