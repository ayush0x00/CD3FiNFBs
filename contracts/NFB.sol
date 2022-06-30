// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "./IPancakePair.sol";

interface IBEP20{
    function balanceOf(address _owner) external view returns (uint256);
    function decimals() external view returns (uint256);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

contract NFB is ERC721,ERC721URIStorage{
    address owner;
    uint8 public currBatchToBeMinted = 1;
    uint16 totalNFBSupply = 0;
    uint256 public _bondPrice;
    uint256 public totalHolders;
    address CD3FiToken;
    IBEP20 CD3FiContract;
    IPancakeFactory factory;

    modifier onlyOwner{
        require (msg.sender == owner);
        _;
    }

    constructor(address _cd3fi, address _factory) ERC721("Non Fungible Bond","NFB"){
        owner=msg.sender;
        CD3FiToken = _cd3fi;
        CD3FiContract= IBEP20(_cd3fi);
        factory = IPancakeFactory(_factory);
    }

    receive() external payable {}

    function transferAmount(address payable _to, uint256 amnt) public payable{
        (bool sent, bytes memory data) = _to.call{value: amnt}("");
        require (sent, "Failed to send amount");
    }

    function mintNFB() public onlyOwner{
        require(totalNFBSupply <= 500, "All NFBs minted");
        for(uint8 i= 1; i<=50; i++){
            _mint(msg.sender, totalNFBSupply+i);
        }
        currBatchToBeMinted += 1;
        totalNFBSupply += 50;
    }

    function buyNFBWithoutCD3d(uint256 tokenId) public payable{
        require(msg.value >= _bondPrice,"Insufficient funds");
        _transferNFB(owner, msg.sender, tokenId);
        uint256 remainingBal = msg.value.sub(_bondPrice);
        transferAmount(payable(msg.sender), remainingBal);
    }

    function buyNFBWithCD3d(uint256 tokenId) public payable{

    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal override {
        _transferNFB(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transferNFB(from, to, tokenId);
    }

    function _transferNFB(address from, address to, uint256 tokenId) private {
        require(balanceOf(to) < 5, "Can not buy more NFBs");
        if(from == owner){
             require(CD3FiContract.balanceOf(to) >= 1000, "Not enough CD3Fi on receiver");
        }
        else{
            require(CD3FiContract.balanceOf(from) >= 1000, "Not enough CD3Fi on sender");
            require(CD3FiContract.balanceOf(to) >= 1000, "Not enough CD3Fi on receiver");
        }
        _transfer(from, to, tokenId);
    }

    function getTokenPrice(address pairAddress, uint amount) private view returns(uint){
        IPancakePair pair = IPancakePair(pairAddress);
        IBEP20 token1 = IBEP20(pair.token1());
        (uint Res0, uint Res1,) = pair.getReserves();
        uint res0 = Res0*(10**token1.decimals());
        return((amount*res0)/Res1);
    }
}
