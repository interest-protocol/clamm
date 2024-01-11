// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC20} from "./ERC20.sol";

contract LpCoin is ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the name of the token.
    function name() public view virtual override returns (string memory) {
        return "LpCoin";
    }

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual override returns (string memory) {
        return "LPCOIN";
    }

    function mint_relative(
        address to,
        uint256 amount
    ) external returns (uint256) {
        uint256 supply = totalSupply();
        uint256 d_supply = (supply * amount) / 1 ether;

        if (d_supply != 0) {
            _mint(to, d_supply);
        }

        return d_supply;
    }

    function burnFrom(address to, uint256 value) external returns (bool) {
        _burn(to, value);
        return true;
    }

    function mint(address to, uint256 amount) external returns (bool) {
        _mint(to, amount);
        return true;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}
