// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.21;

import {Asserts} from "@chimera/Asserts.sol";


interface IShareLike {
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
}

interface IERC7540Like {
    function share() external view returns (address shareTokenAddress);
    function convertToShares(uint256 assets) external view returns (uint256 shares);
    function convertToAssets(uint256 shares) external view returns (uint256 assets);
    function totalAssets() external view returns (uint256 totalManagedAssets);
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);
    function previewDeposit(uint256 assets) external view returns (uint256 shares);
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
    function maxMint(address receiver) external view returns (uint256 maxShares);
    function previewMint(uint256 shares) external view returns (uint256 assets);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
    function maxRedeem(address owner) external view returns (uint256 maxShares);
    function previewRedeem(uint256 shares) external view returns (uint256 assets);
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);

    function requestRedeem(uint256 shares, address receiver, address owner, bytes calldata data)
        external
        returns (uint256 requestId);
}

/// @dev ERC-7540 Properties
/// @author The Recon Team
/// @notice A set of reuseable tests for your ERC7540 Vaults
///     To get started, extend from this contract and make sure to add a way to set the actor (the current user)
///     For more info: https://getrecon.xyz/
abstract contract ERC7540Properties is Asserts {

    uint256 constant public MAX_ROUNDING_ERROR = 10 ** 18;
    
    address actor; /// @audit TODO: You must add a way to change this!

    /// @dev 7540-1	convertToAssets(totalSupply) == totalAssets unless price is 0.0
    function erc7540_1(address erc7540Target) public virtual returns (bool) {
        // Doesn't hold on zero price
        if (
            IERC7540Like(erc7540Target).convertToAssets(
                10 ** IShareLike(IERC7540Like(erc7540Target).share()).decimals()
            ) == 0
        ) return true;

        return IERC7540Like(erc7540Target).convertToAssets(
            IShareLike(IERC7540Like(erc7540Target).share()).totalSupply()
        ) == IERC7540Like(erc7540Target).totalAssets();
    }

    /// @dev 7540-2	convertToShares(totalAssets) == totalSupply unless price is 0.0
    function erc7540_2(address erc7540Target) public virtual returns (bool) {
        if (
            IERC7540Like(erc7540Target).convertToAssets(
                10 ** IShareLike(IERC7540Like(erc7540Target).share()).decimals()
            ) == 0
        ) return true;

        // convertToShares(totalAssets) == totalSupply
        return _diff(
            IERC7540Like(erc7540Target).convertToShares(IERC7540Like(erc7540Target).totalAssets()),
            IShareLike(IERC7540Like(erc7540Target).share()).totalSupply()
        ) <= MAX_ROUNDING_ERROR;
    }

    function _diff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    /// @dev 7540-3	max* never reverts
    function erc7540_3(address erc7540Target) public virtual returns (bool) {
        // max* never reverts
        try IERC7540Like(erc7540Target).maxDeposit(actor) {}
        catch {
            return false;
        }
        try IERC7540Like(erc7540Target).maxMint(actor) {}
        catch {
            return false;
        }
        try IERC7540Like(erc7540Target).maxRedeem(actor) {}
        catch {
            return false;
        }
        try IERC7540Like(erc7540Target).maxWithdraw(actor) {}
        catch {
            return false;
        }

        return true;
    }

    /// == erc7540_4 == //
    
    /// @dev 7540-4 claiming more than max always reverts
    function erc7540_4_deposit(address erc7540Target, uint256 amt) public virtual returns (bool) {
        // Skip 0
        if (amt == 0) {
            return true; // Skip
        }

        uint256 maxDep = IERC7540Like(erc7540Target).maxDeposit(actor);

        /// @audit No Revert is proven by erc7540_5

        uint256 sum = maxDep + amt;
        if (sum == 0) {
            return true; // Needs to be greater than 0, skip
        }

        try IERC7540Like(erc7540Target).deposit(maxDep + amt, actor) {
            return false;
        } catch {
            // We want this to be hit
            return true; // So we explicitly return here, as a means to ensure that this is the code path
        }

        // NOTE: This code path is never hit per the above
    }
    
    function erc7540_4_mint(address erc7540Target, uint256 amt) public virtual returns (bool) {
        // Skip 0
        if (amt == 0) {
            return true;
        }

        uint256 maxDep = IERC7540Like(erc7540Target).maxMint(actor);

        uint256 sum = maxDep + amt;
        if (sum == 0) {
            return true; // Needs to be greater than 0, skip
        }

        try IERC7540Like(erc7540Target).mint(maxDep + amt, actor) {
            return false;
        } catch {
            // We want this to be hit
            return true; // So we explicitly return here, as a means to ensure that this is the code path
        }

        // NOTE: This code path is never hit per the above
    }

    function erc7540_4_withdraw(address erc7540Target, uint256 amt) public virtual returns (bool) {
        // Skip 0
        if (amt == 0) {
            return true;
        }

        uint256 maxDep = IERC7540Like(erc7540Target).maxWithdraw(actor);

        uint256 sum = maxDep + amt;
        if (sum == 0) {
            return true; // Needs to be greater than 0
        }

        try IERC7540Like(erc7540Target).withdraw(maxDep + amt, actor, actor) {
            return false;
        } catch {
            // We want this to be hit
            return true; // So we explicitly return here, as a means to ensure that this is the code path
        }

        // NOTE: This code path is never hit per the above
    }

    function erc7540_4_redeem(address erc7540Target, uint256 amt) public virtual returns (bool) {
        // Skip 0
        if (amt == 0) {
            return true;
        }

        uint256 maxDep = IERC7540Like(erc7540Target).maxRedeem(actor);

        uint256 sum = maxDep + amt;
        if (sum == 0) {
            return true; // Needs to be greater than 0
        }

        try IERC7540Like(erc7540Target).redeem(maxDep + amt, actor, actor) {
            return false;
        } catch {
            // We want this to be hit
            return true; // So we explicitly return here, as a means to ensure that this is the code path
        }

        // NOTE: This code path is never hit per the above
    }

    /// == END erc7540_4 == //

    /// @dev 7540-5	requestRedeem reverts if the share balance is less than amount
    function erc7540_5(address erc7540Target, address shareToken, uint256 shares) public virtual returns (bool) {
        if (shares == 0) {
            return true; // Skip
        }

        uint256 actualBal = IShareLike(shareToken).balanceOf(actor);
        uint256 balWeWillUse = actualBal + shares;

        if (balWeWillUse == 0) {
            return true; // Skip
        }

        try IERC7540Like(erc7540Target).requestRedeem(balWeWillUse, actor, actor, "") {
            return false;
        } catch {
            return true;
        }

        // NOTE: This code path is never hit per the above
    }

    /// @dev 7540-6	preview* always reverts
    function erc7540_6(address erc7540Target) public virtual returns (bool) {
        // preview* always reverts
        try IERC7540Like(erc7540Target).previewDeposit(0) {
            return false;
        } catch {}
        try IERC7540Like(erc7540Target).previewMint(0) {
            return false;
        } catch {}
        try IERC7540Like(erc7540Target).previewRedeem(0) {
            return false;
        } catch {}
        try IERC7540Like(erc7540Target).previewWithdraw(0) {
            return false;
        } catch {}

        return true;
    }

    /// == erc7540_7 == //

    /// @dev 7540-7 if max[method] > 0, then [method] (max) should not revert
    function erc7540_7_deposit(address erc7540Target, uint256 amt) public virtual returns (bool) {
        // Per erc7540_4
        uint256 maxDeposit = IERC7540Like(erc7540Target).maxDeposit(actor);
        amt = between(amt, 0, maxDeposit);

        if (amt == 0) {
            return true; // Skip
        }

        try IERC7540Like(erc7540Target).deposit(amt, actor) {
            // Success here
            return true;
        } catch {
            return false;
        }

        // NOTE: This code path is never hit per the above
    }

    function erc7540_7_mint(address erc7540Target, uint256 amt) public virtual returns (bool) {
        uint256 maxMint = IERC7540Like(erc7540Target).maxMint(actor);
        amt = between(amt, 0, maxMint);

        if (amt == 0) {
            return true; // Skip
        }

        try IERC7540Like(erc7540Target).mint(amt, actor) {
            // Success here
            return true;
        } catch {
            return false;
        }

        // NOTE: This code path is never hit per the above
    }

    function erc7540_7_withdraw(address erc7540Target, uint256 amt) public virtual returns (bool) {
        uint256 maxWithdraw = IERC7540Like(erc7540Target).maxWithdraw(actor);
        amt = between(amt, 0, maxWithdraw);

        if (amt == 0) {
            return true; // Skip
        }

        try IERC7540Like(erc7540Target).withdraw(amt, actor, actor) {
            // Success here
            return true;
        } catch {
            return false;
        }

        // NOTE: This code path is never hit per the above
    }

    function erc7540_7_redeem(address erc7540Target, uint256 amt) public virtual returns (bool) {
        // Per erc7540_4
        uint256 maxRedeem = IERC7540Like(erc7540Target).maxRedeem(actor);
        amt = between(amt, 0, maxRedeem);

        if (amt == 0) {
            return true; // Skip
        }

        try IERC7540Like(erc7540Target).redeem(amt, actor, actor) {
            return true;
        } catch {
            return false;
        }

        // NOTE: This code path is never hit per the above
    }

    /// == END erc7540_7 == //
}
