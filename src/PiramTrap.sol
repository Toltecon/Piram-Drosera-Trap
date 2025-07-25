// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface ITrap {
    function collect() external view returns (bytes memory);
    function shouldRespond(bytes[] calldata data) external pure returns (bool, bytes memory);
}

contract PiramTrap is ITrap {
    // адрес токена PIRAM
    address public constant PIRAM_TOKEN_ADDRESS = 0x00DBD98148D0d552aC960B1DB23D2BAcbaD648F5;

    // отслеживаемый адрес
    address public constant WATCHED_ADDRESS = 0x4a61B89655A5903224A1b82Eec50c320DD899e1c;

    IERC20 private constant piram = IERC20(PIRAM_TOKEN_ADDRESS);

    struct Action {
        uint256 watchedBalance;
    }

    function collect() external view override returns (bytes memory) {
        Action memory snapshot = Action({
            watchedBalance: piram.balanceOf(WATCHED_ADDRESS)
        });

        return abi.encode(snapshot);
    }

    function shouldRespond(bytes[] calldata data) external pure override returns (bool, bytes memory) {
        if (data.length < 2) {
            return (false, bytes("Insufficient historical data"));
        }

        Action memory current = abi.decode(data[0], (Action));
        Action memory previous = abi.decode(data[1], (Action));
        
        // Точное условие: уменьшение > 1 PIRAM (1e6 единиц при 6 знаках)
        if (previous.watchedBalance > current.watchedBalance &&
            previous.watchedBalance - current.watchedBalance > 1_000_000)
        {
            return (true, bytes("Detected significant decrease in PIRAM balance"));
        }

        return (false, bytes(""));
    }
}
