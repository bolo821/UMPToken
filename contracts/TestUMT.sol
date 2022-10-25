// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

contract TestUMT is ERC1155, IERC2981, Ownable, Pausable, ERC1155Burnable, ERC1155Supply, ERC1155URIStorage {
    enum METAL { GOLD, PLATINUM, SILVER, COPPER } // Metal types

    string public name; // NFT name.
    string public symbol; // NFT symbol.
    address private _recipient;
    uint256 private _royaltyPoint = 1000;

    uint256 _totalSupply = 4; // Total supply of NFTs.
    uint256 _goldSupply = 1; // Total number of gold NFTs.
    uint256 _platinumSupply = 1; // Total number of platinum NFTs.
    uint256 _silverSupply = 1; // Total number of silver NFTs.
    uint256 _copperSupply = 1; // total number of copper NFTs.

    mapping(address => uint256[]) private _userTokens; // Token ids per account.
    mapping(uint256 => METAL) private _metalType; // Metal type per token id.
    mapping(uint256 => bool) private _tokenSold; // Sell status per token id.

    event InitMetalType();
    event InitialMint(uint256[], uint256[]);
    event WithdrawAll(uint256);
    event Deposit(uint256);

    constructor()
        ERC1155("https://www.urbanminerproject.org/")
    {
        name = "Test Urban Miner Project 77-2";
        symbol = "TURM772";
        _recipient = 0x6902125e1936b7c1234856A284374B70069ef9FF;
        ERC1155._setURI("ipfs://bafkreibmre4xlda24qjpl52rwyqmfwttlxz33eklqafhytnnuohlyjctvi");
    }

    // @Pause function.
    function pause() public onlyOwner {
        _pause();
    }

    // @Unpause function
    function unpause() public onlyOwner {
        _unpause();
    }

    // @Mint single NFT.
    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    // @Mint batch NFTs.
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // @Overrided this method to limit the token count of every account.
    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        // All accounts except the owner can only own max 2 NFTs.
        require(to == owner() || _userTokens[to].length + amounts.length <= 2, "Account balance could not be bigger than 2");
    }

    // @Overrided this function to update metadata after purchasing.
    function _afterTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override
    {
        uint256 fromUserBal = _userTokens[from].length;

        // Remove token ids from "from" user's _userToken list.
        for (uint256 i=0; i<ids.length; i++) {
            for (uint256 j=0; j<_userTokens[from].length; j++) {
                if (_userTokens[from][j] == ids[i]) {
                    _userTokens[from][j] = _userTokens[from][fromUserBal-1];
                    _userTokens[from].pop();
                }
            }
        }

        // Add token ids to "to" user's _userToken list.
        for (uint256 i=0; i<ids.length; i++) {
            _userTokens[to].push(ids[i]);

            // If the token is transferred from the owner, we update the metadata of that token because that is just "purchase".
            if (from == owner() && to != owner()) {
                if (getMetalType(ids[i]) == METAL.GOLD) {
                    _setURI(ids[i], "ipfs://bafkreib3muqei5tjfd6bunwihl7iozjycw4ztyab5rxmo3ldkkp4xvhvdi");
                } else if (getMetalType(ids[i]) == METAL.PLATINUM) {
                    _setURI(ids[i], "ipfs://bafkreibp3lofjfgwcg5vzzyyg5b4flqvlitiaivo3cuwpkwu4fmwr57am4");
                } else if (getMetalType(ids[i]) == METAL.SILVER) {
                    _setURI(ids[i], "ipfs://bafkreibua7cpcwkj3rom4tjfi3a4yhunyd5acv4bxtuvldag5jzqmhb2j4");
                } else {
                    _setURI(ids[i], "ipfs://bafkreicfchzjlwaecuuld7lwakyn5oizccjbwi4cpfkcbbp42v4wlt5pai");
                }
            }
        }
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // @Set contract level metadata.
    function contractURI() public pure returns (string memory) {
        return
            "ipfs://bafkreig2ifiw5qwukd6mooiiii3zmjucdt7dkv5wrw6yzalxgg7vnhm2hi";
    }

    // @Random generator function.
    function getRandomNumber(uint256 max, uint256 adder) internal view returns (uint256) {
        uint256 randomHash = uint256(
            keccak256(abi.encodePacked(block.timestamp, uint256(7789), adder))
        );
        return randomHash % max;
    }

    // @Set metal type to all NFTs. Metal types are determined by random numbers.
    function initMetalType()
        external
        onlyOwner
    {
        uint256 goldCount = 0;
        uint256 platinumCount = 0;
        uint256 silverCount = 0;
        uint256 copperCount = 0;
        bool[] memory usedIds = new bool[](_totalSupply);
        uint256 tryCount = 0;

        while (true) {
            uint256 tmp = getRandomNumber(_totalSupply, tryCount);
            tryCount ++;
            if (usedIds[tmp]) continue;
            usedIds[tmp] = true;
        
            if (goldCount < _goldSupply){
                _metalType[tmp] = METAL.GOLD;
                goldCount ++;
            } else if (platinumCount < _platinumSupply) {
                _metalType[tmp] = METAL.PLATINUM;
                platinumCount ++;
            } else if (silverCount < _silverSupply) {
                _metalType[tmp] = METAL.SILVER;
                silverCount ++;
            } else {
                _metalType[tmp] = METAL.COPPER;
                copperCount ++;
            }
            if (copperCount == _copperSupply) break;
        }

        emit InitMetalType();
    }

    // @Get metal type for given token id.
    function getMetalType(uint256 tokenId) public view returns (METAL) {
        return _metalType[tokenId];
    }

    // Mint batch of tokens and transfer it to the owner to list in opensea.
    function initialMint(uint256[] memory ids, uint256[] memory amounts) onlyOwner external {
        mintBatch(owner(), ids, amounts, "0x");
        _userTokens[owner()] = ids;

        emit InitialMint(ids, amounts);
    }

    // @Get token owned by specific account.
    function getUserTokenIds(address user) external view returns (uint256[] memory) {
        return _userTokens[user];
    }

    // @Ger how many each type of metal users own.
    function getUserBalance(address user) external view returns (uint256, uint256, uint256, uint256) {
        uint256 goldCount = 0;
        uint256 platinumCount = 0;
        uint256 silverCount = 0;
        uint256 copperCount = 0;

        for (uint256 i=0; i<_userTokens[user].length; i++) {
            METAL type_ = getMetalType(_userTokens[user][i]);
            if (type_ == METAL.GOLD) goldCount++;
            else if (type_ == METAL.PLATINUM) platinumCount++;
            else if (type_ == METAL.SILVER) silverCount++;
            else copperCount++;
        }

        return (goldCount, platinumCount, silverCount, copperCount);
    }

    // @Set token level metadata.
    function uri(uint256 tokenId) public override(ERC1155, ERC1155URIStorage) view returns (string memory) {
        return ERC1155URIStorage.uri(tokenId);
    }

    // @Deposit ETH to contract
    function deposit() external payable {
        emit Deposit(msg.value);
    }

    // @Withdraw ETH from contract to owners address
    function withdrawAll() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _withdraw(owner(), address(this).balance);

        emit WithdrawAll(balance);
    }

    // @Native coin transfer function
    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed!");
    }

    /** @dev EIP2981 royalties implementation. */

    // Maintain flexibility to modify royalties recipient (could also add basis points).
    function _setRoyalties(address newRecipient, uint256 royaltyPoint) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        require(royaltyPoint >= 0 && royaltyPoint <10000, "Royalty point should be between 0 and 100");
        _recipient = newRecipient;
        _royaltyPoint = royaltyPoint;
    }

    function setRoyalties(address newRecipient, uint256 royaltyPoint) external onlyOwner {
        _setRoyalties(newRecipient, royaltyPoint);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_recipient, (_salePrice * _royaltyPoint) / 10000);
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }
}