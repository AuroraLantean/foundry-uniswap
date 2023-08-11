// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

//import "solmate/tokens/ERC20.sol";
//import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; //_mint, _burn
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; //safeTransfer, safeTransferFrom, safeApprove, safeIncreaseAllowance, safeDecreaseAllowance

//import "forge-std/console.sol";

contract ERC20Token is Ownable, ERC20, ERC20Burnable {
    //constructor() ERC20("GoldCoin", "GLDC") {}
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        // Mint 100 tokens to msg.sender
        // Similar to how
        // 1 dollar = 100 cents
        // 1 token = 1 * (10 ** decimals)
        _mint(msg.sender, 9000000000 * 10 ** uint256(decimals()));
    }

    function mintToOwner() public onlyOwner {
        _mint(msg.sender, 90000000 * 10 ** uint256(decimals()));
    }

    function mint(address user, uint256 amount) public onlyOwner returns (bool) {
        _mint(user, amount);
        return true;
    }
}

contract ERC20DP6 is ERC20Token {
    //USDT, USDC use 6 dp !!! But DAI has 18!!
    constructor(string memory name, string memory symbol) ERC20Token(name, symbol) {
        _setupDecimals(6);
    }
}

contract ERC20DP8 is ERC20Token {
    //WBTC
    constructor(string memory name, string memory symbol) ERC20Token(name, symbol) {
        _setupDecimals(8);
    }
}

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IERC20Meta is IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

interface IWETH is IERC20Meta {
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface IERC20Receiver {
    /**
     * @dev Whenever an {IERC20} `tokenId` token is transferred to this contract via {IERC20-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC20Receiver.tokenReceived.selector`.
     */
    function tokenReceived(address from, uint256 amount, bytes calldata data) external returns (bytes4);
}
