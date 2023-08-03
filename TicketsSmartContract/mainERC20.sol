// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.5.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.5.0/access/Ownable.sol";
import "./mainERC721.sol";

contract mainERC20 is ERC20, Ownable {

    uint256 public tokenPrice;
    uint256 [] public events;
    mapping(uint256 => address) public eventContracts;
    mapping(address => uint256[]) user_events;
    uint256 randNonce;
    uint feePercent = 5;

    constructor() ERC20("Easy Tickets", "ET"){
        _mint(address(this), 10000);
        tokenPrice = 0.1 ether;
    }

    // Funcion para crear nuevos tokens
    function mint(uint256 _numTokens) public onlyOwner {
        _mint(address(this), _numTokens);
    }

    // Funcion para visualizar el balance de tokens del Smart Contract
    function tokenBalanceSC() public view returns(uint256){
        return balanceOf(address(this));
    }

    // Funcion para visualizar el balance en ethers del Smart Contract
    function etherBalanceSC() public view returns(uint256){
        return address(this).balance / 10**18;
    }

    // Funcion para visualizar el balance de tokens de un usuario
    function tokenBalance(address _account) public view returns(uint256){
        return balanceOf(_account);
    }

    // Funcion para comprar tokens
    function buyTokens(uint256 _ammount) public payable {
        uint256 totalPrice = tokenPrice * _ammount;
        require(msg.value >= totalPrice, "Insufficient Ether Balance");
        require(_ammount > 0, "The amount must be higher than 0");
        require(_ammount <= balanceOf(address(this)), "The amount of tokens you requested is not available at the moment. Please try less or try again later");
        _transfer(address(this), msg.sender, _ammount);
    }

    // Funcion para devolver tokens
    function returnTokens(uint256 _ammount) public {
        require(_ammount > 0, "The amount must be higher than 0");
        require(_ammount <= balanceOf(msg.sender), "You don't have enough tokens");
        _transfer(msg.sender, address(this), _ammount);
        payable(msg.sender).transfer(_ammount * tokenPrice);
    }

    // Funcion para visualizar los eventos que ha creado un usuario
    function userEvents(address _user) public view returns(uint [] memory){
        return user_events[_user];
    }

    // Función para crear un nuevo evento
    function createEvent(
        string memory _eventName,
        uint256 _eventDate,
        uint256 _maxTicketSupply,
        uint256 _ticketPrice,
        uint256 _ticketId
    ) public {
        uint256 _eventId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, events.length))) % 1000;
        address _owner = msg.sender;
        address _mainERC20 = address(this);

        EventNFT eventContract = new EventNFT(
            _owner,
            _mainERC20,
            _eventId,
            _eventName,
            _eventDate,
            _maxTicketSupply,
            _ticketPrice,
            _ticketId
        );

        eventContracts[_eventId] = address(eventContract);
        events.push(_eventId);
        user_events[msg.sender].push(_eventId);
    }

    // Funcion para obtener la direccion del contrato EventNFT de un evento
    function getEventContract(uint256 _eventId) public view returns (address) {
        return eventContracts[_eventId];
    }

    function buyTickets(uint256 _eventId) public {
        require(eventContracts[_eventId] != address(0), "Invalid event ID");
        address eventContractAddress = eventContracts[_eventId];
        uint256 ticketPrice = EventNFT(eventContractAddress).getTicketPrice();
        uint256 totalPrice = ticketPrice + (ticketPrice * (feePercent/100));
        require(balanceOf(msg.sender) >= totalPrice, "Insufficient token balance");
        // Transfiere los tokens desde el usuario al contrato mainERC20
        transferFrom(msg.sender, address(this), totalPrice);
        // Minta los boletos en el contrato EventNFT
        EventNFT(eventContractAddress).mintTicket(msg.sender);
        // Transfiere los ethers correspondientes al ticketPrice al contrato del evento
        uint256 ethersForTicket = ticketPrice * tokenPrice; // Conversión de tokens a ethers
        payable(eventContractAddress).transfer(ethersForTicket);
    }
}