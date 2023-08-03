// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.5.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.5.0/access/Ownable.sol";

contract EventNFT is ERC721, Ownable {

    struct Event {
        address owner;
        address mainERC20;
        uint256 eventId;
        string eventName;
        uint256 eventDate;
        uint256 maxTicketSupply;
        uint256 ticketPrice;
        uint256 ticketId;
    }

    Event public eventNFT;
    mapping(uint256 => address) public ticketOwners;
    uint256 private ticketCount;

    constructor(
        address _owner,
        address _mainERC20,
        uint256 _eventId,
        string memory _eventName,
        uint256 _eventDate,
        uint256 _maxTicketSupply,
        uint256 _ticketPrice,
        uint256 _ticketId
    ) ERC721("EventNFT", "ENFT") {
        eventNFT = Event(
            _owner,
            _mainERC20,
            _eventId,
            _eventName,
            _eventDate,
            _maxTicketSupply,
            _ticketPrice,
            _ticketId
        );
    }

    function mintTicket(address _owner) public {
        require(ticketCount < eventNFT.maxTicketSupply, "Maximum ticket supply reached");

        uint256 tokenId = ticketCount + 1;
        _safeMint(_owner, tokenId);

        ticketOwners[tokenId] = _owner;
        ticketCount++;
    }

    function transferTicket(address _to, uint256 _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this ticket");
        require(_to != address(0), "Invalid address");

        safeTransferFrom(msg.sender, _to, _tokenId);
        ticketOwners[_tokenId] = _to;
    }

    function getTicketPrice() public view returns (uint256) {
        return eventNFT.ticketPrice;
    }

    function withdrawEthers() public onlyOwner {
        require(address(this).balance > 0, "No ethers to withdraw");
        payable(owner()).transfer(address(this).balance);
    }
}
