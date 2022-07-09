// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

interface IERC20{
    function balanceOf(address _owner) external view returns (uint256);
    function decimals() external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

interface IPancakeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IPancakeRouter {
    function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
    ) external returns (uint[] memory amounts);
}

contract NFB is ERC721,ERC721URIStorage{
    using SafeMath for uint256;
    address owner;
    uint8 public currBatchToBeMinted = 1;
    uint16 totalNFBSupply = 1;
    uint256 public _bondPrice;
    address CD3FiBUSDPairAddress;
    address CD3FiToken;
    IERC20 CD3FiContract;
    IPancakeFactory factory;
    IPancakeRouter router = IPancakeRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
    uint256 epochOfDeployment;
    address payable sponsor;
    address payable GuarenteeFund;
    address payable CinemaDraft;
    mapping (uint256 => uint256) nfbPriceInCd3Fi; //dont forget to divide the price by 100
    IERC20 BUSDContract = IERC20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);

    modifier onlyOwner{
        require (msg.sender == owner);
        _;
    }

    constructor(address _cd3fi, address _factory, address _cd3fiBUSDPair) ERC721("Non Fungible Bond","NFB"){
        owner=msg.sender;
        CD3FiToken = _cd3fi;
        CD3FiContract= IERC20(_cd3fi);
        factory = IPancakeFactory(_factory);
        CD3FiBUSDPairAddress = _cd3fiBUSDPair;
        epochOfDeployment = block.timestamp;
        nfbPriceInCd3Fi[1] = 100000;
        _mint(msg.sender, 1);
    }

    receive() external payable {}

    function transferBNB(address payable _to, uint256 amnt) public payable{
        (bool sent, bytes memory data) = _to.call{value: amnt}("");
        require (sent, "Failed to send amount");
    }

    function changePairAddress(address _pairAddress) public onlyOwner{
        CD3FiBUSDPairAddress = _pairAddress;
    }

    function mintNFB() public onlyOwner{
        require(totalNFBSupply <= 500, "All NFBs minted");
        uint256 startId = (currBatchToBeMinted-1)*50+1;
        uint256 incrementPercentage = 10000 + (startId - 1);

        if(totalNFBSupply > 450){
            for(uint8 i= 1; i<=50; i++){
                _mint(sponsor, totalNFBSupply+i);
                nfbPriceInCd3Fi[i] = incrementPercentage.mul(nfbPriceInCd3Fi[i-1]).div(10000);
                incrementPercentage.add(1);
            }
        }
        else{
            for(uint8 i= 1; i<=50; i++){
                _mint(msg.sender, totalNFBSupply+i);
                nfbPriceInCd3Fi[i] = incrementPercentage.mul(nfbPriceInCd3Fi[i-1]).div(10000);
                incrementPercentage.add(1);
            }
        }
        currBatchToBeMinted += 1;
        totalNFBSupply += 50;
    }

    function handlePrimarySale(address to, uint256 tokenId) public payable{
        CD3FiContract.transferFrom(to, address(this), nfbPriceInCd3Fi[tokenId]);
        CD3FiContract.approve(address(router), nfbPriceInCd3Fi[tokenId]);
        address[] memory path = new address[](2);
        path[0] = address(BUSDContract);
        path[1] = address(CD3FiContract);
        uint[] memory amounts = router.swapExactTokensForTokens(nfbPriceInCd3Fi[tokenId],0,path,address(this),block.timestamp.add(10 minutes));
        uint256 sponsorAmnt = amounts[1].mul(50).div(100);
        uint256 guarenteeFundAmnt = amounts[1].mul(40).div(100);
        uint256 cinemaDraftAmnt = amounts[1].mul(10).div(100);
        BUSDContract.transfer(CinemaDraft, cinemaDraftAmnt);
        BUSDContract.transfer(GuarenteeFund, guarenteeFundAmnt);
        BUSDContract.transfer(sponsor, sponsorAmnt);
    }

    function handleSecondarySale(address from, address to, uint256 tokenId) public payable{
        uint256 cd3FiDeduction = nfbPriceInCd3Fi[tokenId].mul(15).div(100);
        CD3FiContract.transferFrom(to, address(this) , cd3FiDeduction);
        CD3FiContract.transferFrom(to, from, nfbPriceInCd3Fi[tokenId].sub(cd3FiDeduction));
        CD3FiContract.approve(address(router), cd3FiDeduction);
        address [] memory path = new address[](2);
        path[0] = address(BUSDContract);
        path[1] = address(CD3FiContract);
        uint[] memory amounts = router.swapExactTokensForTokens(cd3FiDeduction,0,path,address(this),block.timestamp.add(10 minutes));
        uint256 sponsorAmnt = amounts[1].mul(8).div(100);
        uint256 guarenteeFundAmnt = amounts[1].mul(6).div(100);
        uint256 cinemaDraftAmnt = amounts[1].mul(1).div(100);
        BUSDContract.transfer(CinemaDraft, cinemaDraftAmnt);
        BUSDContract.transfer(GuarenteeFund, guarenteeFundAmnt);
        BUSDContract.transfer(sponsor, sponsorAmnt);
    }

    function _transfer(address from, address to, uint256 tokenId) internal override {
        if(tokenId >= 451){
            require(block.timestamp >= epochOfDeployment.add(1825 days),"Sponsor bond not matured");
        }
        require(balanceOf(to) < 5, "Can not buy more NFBs");
        if(from == owner){
             require(CD3FiContract.balanceOf(to) >= 1000, "Not enough CD3Fi on receiver");
        }
        else{
            require(CD3FiContract.balanceOf(from) >= 1000, "Not enough CD3Fi on sender");
            require(CD3FiContract.balanceOf(to) >= 1000, "Not enough CD3Fi on receiver");
        }

        if(from == owner){
            handlePrimarySale(to, tokenId);
        }
        else{
            handleSecondarySale(from, to, tokenId);
        }
        super._transfer(from, to, tokenId);
    }


    function _burn(uint256 tokenId) internal override(ERC721URIStorage, ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage,ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
