// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ICurveMinter {
    function mint(address gauge_addr) external;
}
