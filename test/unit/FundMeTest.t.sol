// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

//import {Test, console} from "forge-std/Test.sol";
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    //address BETUL = makeAddr("betul");
    uint256 constant SEND_VALUE = 1 ether; // 1e17
    uint256 constant STARTING_BALANCE = 10 ether; // 10e18
    uint256 constant GAS_PRICE = 0.03 gwei;

    function setUp() public {
        DeployFundMe deployFundMe = new DeployFundMe();
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
        vm.deal(fundMe.getOwner(), STARTING_BALANCE);
        //vm.deal(BETUL, STARTING_BALANCE);
    }

    function testMinumumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        console.log(address(this));
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        if (block.chainid == 11155111) {
            assertEq(fundMe.getVersion(), 4);
        } else if (block.chainid == 1) {
            assertEq(fundMe.getVersion(), 6);
        } else {
            assertEq(fundMe.getVersion(), 0);
        }
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // hey, the next line should revert!
        // assert(this tx fails/reverts)
        fundMe.fund();
        //uint256 betul = 1;
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        //console.log("BETUL address: ", BETUL);
        console.log("USER address: ", USER);
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        console.log("funder address: ", funder);
        console.log("fundme.getFunder(0): ", fundMe.getFunder(0));
        console.log("fundme getOwner: ", fundMe.getOwner());
        console.log("msg.sender: ", msg.sender);
        console.log("address(this): ", address(this));
        vm.expectRevert();
        console.log("fundme.getFunder(1): ", fundMe.getFunder(1)); // [FAIL: panic: array out-of-bounds access (0x32)]
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        // vm.prank(USER);
        // fundMe.fund{value: SEND_VALUE}();

        vm.expectRevert();
        // console.log("address(this): ", address(this));
        // console.log("msg.sender: ", msg.sender);
        // console.log("fundMe.getOwner(): ", fundMe.getOwner());
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        console.log("fundMe.getOwner(): ", fundMe.getOwner());
        console.log("msg.sender: ", msg.sender);
        console.log("address(this): ", address(this));
        console.log("USER: ", USER);
        console.log("startingFundMeBalance: ", startingFundMeBalance / 1e18);
        console.log("startingOwnerBalance: ", startingOwnerBalance / 1e18);

        // act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        console.log("endingFundMeBalance: ", endingFundMeBalance / 1e18);
        console.log("endingOwnerBalance: ", endingOwnerBalance / 1e18);
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public {
        // arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        vm.txGasPrice(GAS_PRICE);
        uint256 gasStart = gasleft();
        console.log("gasStart: %d", gasStart);

        console.log("FundMe owner address: ", fundMe.getOwner());
        console.log(
            "FundMe owner starting balance: ",
            fundMe.getOwner().balance
        );

        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // prank + deal
            hoax(address(i), SEND_VALUE);
            // vm.prank(address(i));
            // fundMe.fund{value: SEND_VALUE}();
            //address funder = address(i);
            console.log("Funder address: ", address(i));
            //vm.deal(funder, STARTING_BALANCE);
            console.log("Funder balance: ", address(i).balance);
            //vm.prank(funder);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        console.log("FundMe owner address: ", fundMe.getOwner());
        uint256 gasEnd = gasleft();
        console.log("gasStart: %d", gasStart);
        console.log("gasEnd: %d", gasEnd);
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("gasUsed: %d", (gasStart - gasEnd));
        console.log("tx.gasprice: %d", tx.gasprice);
        console.log("Withdraw consumed for funders: %d gas", gasUsed);

        // act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        console.log("FundMe owner ending balance: ", fundMe.getOwner().balance);

        uint256 gasEndAfterOwner = gasleft();
        console.log("gasEndAfterOwner: %d", gasEndAfterOwner);
        uint256 gasUsedAfterOwner = (gasStart - gasEndAfterOwner) * tx.gasprice;
        console.log(
            "Withdraw consumed for all: %d gas",
            (gasStart - gasEndAfterOwner)
        );

        // assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersExp() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }

    function testPrintStorageData() public {
        for (uint256 i = 0; i < 3; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }
        console.log("i_owner address:", address(fundMe.getOwner()));
        console.log("msg.sender: ", msg.sender);
        console.log("address(this): ", address(this));
    }
}
