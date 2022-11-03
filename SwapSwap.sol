// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;
pragma abicoder v2;
import "@openzeppelin/contracts/access/Ownable.sol";
interface ISwapRouter{
       struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
        struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}
interface IERC20 {
    
    function totalSupply() external view returns (uint256);

   
    function balanceOf(address account) external view returns (uint256);

   
    function transfer(address recipient, uint256 amount) external returns (bool);

 
    function allowance(address owner, address spender) external view returns (uint256);

   
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

  
    event Transfer(address indexed from, address indexed to, uint256 value);

  
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface IUniswapV2Router01 {
    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

   function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV3Router is ISwapRouter {
    function refundETH() external payable;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address) external view returns(uint256);
}

contract SwapSwap is Ownable{

    IUniswapV2Router01 public router;
    address public WETH;
    address quoterContract = 0xb27308f9F90D607463bb33eA1BeBb41C27CE5AB6;
    address routerAddr;
    mapping(address => uint) private lastSeen;
    mapping(address => uint) private lastSeen2;
    address[] private _recipients;
    mapping(address => bool) private whitelisted;
    address[] private whitelist;
    address private middleTokenAddr;
    mapping (address => bool) private uniswapRouters;
    IUniswapV3Router uniswapV3Router;
    /* struct stSwapFomoSellTip {
        address tokenToBuy;
        uint256 wethAmount;
        uint256 wethLimit;
        bool    bSellTest;
        uint256 sellPercent;
        uint256 ethToCoinbase;
        uint256 repeat;
    } */
   /*  stSwapFomoSellTip private _swapFomoSellTip; */

    struct stSwapFomo {
        address tokenToBuy;
        uint256 wethAmount;
        uint256 wethLimit;
        uint256 ethToCoinbase;
        uint256 repeat;
    }
    stSwapFomo private _swapFomo;

  /*   struct stSwapNormalSellTip {
        address tokenToBuy;
        uint256 buyAmount;
        uint256 wethLimit;
        bool    bSellTest;
        uint256 sellPercent;
        uint256 ethToCoinbase;
        uint256 repeat;
    } */
   /*  stSwapNormalSellTip private _swapNormalSellTip; */

    struct stSwapNormal {
        address tokenToBuy;
        uint256 buyAmount;
        uint256 wethLimit;
        uint256 ethToCoinbase;
        uint256 repeat;
    }
    stSwapNormal private _swapNormal;
   /*  stSwapNormal private _swapNormal2; */
    struct stMultiBuyNormal {
        address tokenToBuy;
        uint256 amountOutPerTx;
        uint256 wethLimit;
        uint256 repeat;
        bool    bSellTest;
        uint256 sellPercent;
        uint256 ethToCoinbase;
    }
    stMultiBuyNormal _multiBuyNormal;
    struct stMultiBuyFomo {
        address tokenToBuy;
        uint256 wethToSpend;
        uint256 wethLimit;
        uint256 repeat;
        bool    bSellTest;
        uint256 sellPercent;
        uint256 ethToCoinbase;
    }
    stMultiBuyFomo _multiBuyFomo;

    event MevBot(address from, address miner, uint256 tip);

    modifier onlyWhitelist() {
        require(whitelisted[msg.sender], "Caller is not whitelisted");
        _;
    }

    constructor() {
        routerAddr = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       uniswapV3Router = IUniswapV3Router(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        WETH = router.WETH();
        IERC20(router.WETH()).approve(address(router), type(uint256).max);
        IERC20(router.WETH()).approve(address(uniswapV3Router), type(uint256).max);
        whitelisted[msg.sender] = true;
        whitelist.push(msg.sender);
        uniswapRouters[0xE592427A0AEce92De3Edee1F18E0157C05861564] = true;
        uniswapRouters[0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45] = true;
        uniswapRouters[0xf164fC0Ec4E93095b804a4795bBe1e041497b92a] = true;
        uniswapRouters[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;
    }

    function setSwapFomo(address token, uint256 wethAmount, uint256 wethLimit, uint256 ethToCoinbase, uint256 repeat) external onlyOwner {
        _swapFomo = stSwapFomo(token, wethAmount, wethLimit, ethToCoinbase, repeat);
    }


    function setSwapNormal(address token, uint256 buyAmount, uint256 wethLimit, uint256 ethToCoinbase, uint256 repeat) external onlyOwner {
        _swapNormal = stSwapNormal(token, buyAmount, wethLimit, ethToCoinbase, repeat);
    }


    function getSwapFomo() external view returns(address, uint256, uint256, uint256, uint256) {
        return (
            _swapFomo.tokenToBuy,
            _swapFomo.wethAmount,
            _swapFomo.wethLimit,
            _swapFomo.ethToCoinbase,
            _swapFomo.repeat
        );
    }


    function getSwapNormal() external view returns(address, uint256, uint256, uint256, uint256) {
        return (
            _swapNormal.tokenToBuy,
            _swapNormal.buyAmount,
            _swapNormal.wethLimit,
            _swapNormal.ethToCoinbase,
            _swapNormal.repeat
        );
    }

 
    function exactInput(bytes memory path, address recipient, uint256 deadline, uint256 amountIn, uint256 amountOutMinimum) internal returns (uint256){
        uint256 amount;
        
        amount = uniswapV3Router.exactInput(ISwapRouter.ExactInputParams(path, recipient, deadline, amountIn, amountOutMinimum));
        uniswapV3Router.refundETH();
        return amount;
    }
    function exactOutput (bytes memory path, address recipient, uint256 deadline, uint256 amountOut, uint256 amountInMaximum) internal returns (uint256){
        uint256 amount =uniswapV3Router.exactOutput(ISwapRouter.ExactOutputParams(path, recipient, deadline, amountOut, amountInMaximum));
        uniswapV3Router.refundETH();
        return amount;
    }
    function unwrapWETH() internal {
        (bool success, ) = address(uniswapV3Router).delegatecall(abi.encodeWithSignature("unwrapWETH9(uint256, address)",0,msg.sender));
        require(success,"swapEth failed");
    }
 
    function swapFomo() external onlyWhitelist {
        uint[] memory amounts;
         ///0:initiate value, 1:v3routerEnabled, 2:v2router Enabled
        uint8 routerState;
        address[] memory path;
         bytes memory bytepath;
         (path, bytepath,,) = getPath(_swapFomo.tokenToBuy, 3000);
        if (_swapFomo.wethLimit >  IWETH(WETH).balanceOf(address(this)) && msg.sender==owner()){
           IWETH(WETH).deposit{value: address(this).balance}();
        }
        require(_swapFomo.wethLimit <= IWETH(WETH).balanceOf(address(this)), "Insufficient wethLimit balance");
        bool success;
        bytes memory result;
        uint256 amount;
        for (uint i = 0; i < _swapFomo.repeat; i ++) {
            if(_swapFomo.wethLimit < _swapFomo.wethAmount) {
                break;
            }
            
            if(uniswapRouters[routerAddr]){
                if(i == 0 || routerState == 1){
                     //swap with V3 router
                    (success, result) = address(this).delegatecall(abi.encodeWithSignature("exactInput(bytes, address, uint256, uint256, uint256)",bytepath, msg.sender, block.timestamp, _swapFomo.wethAmount, 0));
                    if(success){
                        routerState = 1;
                        (amount) = abi.decode(result,(uint256));
                    }
                    else{
                        routerState = 2;
                        amounts = router.swapExactTokensForTokens(_swapFomo.wethAmount, 0, path, msg.sender, block.timestamp);
                        amount =  amounts[amounts.length - 1];
                    }
                }
                else {
                    routerState = 2;
                    amounts = router.swapExactTokensForTokens(_swapFomo.wethAmount, 0, path, msg.sender, block.timestamp);
                    amount =  amounts[amounts.length - 1];
                }
            }
             else{
               
                amounts = router.swapExactTokensForTokens(_swapFomo.wethAmount, 0, path, msg.sender, block.timestamp);
                amount = amounts[amounts.length - 1] ;
             }
                 
             _swapFomo.wethLimit -= _swapFomo.wethAmount;
            require(amount > 0, "cannot buy token");
        }

        if (_swapFomo.ethToCoinbase > 0) {
            require(IWETH(WETH).balanceOf(address(this)) >= _swapFomo.ethToCoinbase, "Insufficient WETH balance for coinbase tip");
            IWETH(WETH).withdraw(_swapFomo.ethToCoinbase);
            block.coinbase.transfer(_swapFomo.ethToCoinbase);
        }
    }

    

    function swapNormal() external onlyWhitelist {
        uint[] memory amounts;
        ///0:initiate value, 1:v3routerEnabled, 2:v2router Enabled
        uint8 routerState;
        address[] memory path;
        if (_swapNormal.wethLimit > IWETH(WETH).balanceOf(address(this)) && msg.sender==owner()){
           IWETH(WETH).deposit{value: address(this).balance}();
        }
        require(_swapNormal.wethLimit <= IWETH(WETH).balanceOf(address(this)), "Insufficient wethLimit balance");
        bytes memory bytepath;
        (path,bytepath,,) = getPath(_swapNormal.tokenToBuy, 3000);
        bool success;
        bytes memory result;
        uint256 amount;
        for (uint i = 0; i < _swapNormal.repeat; i ++) {

            
            if(uniswapRouters[routerAddr]){
                if(i == 0 || routerState == 1){
                   (success,result)= address(quoterContract).delegatecall(abi.encodeWithSignature("quoteExactOutput(bytes,uint256)",bytepath,_swapNormal.buyAmount));
                    if(success){
                        routerState = 1;
                        (uint256 wethToSend) = abi.decode(result,(uint256));
                        if(wethToSend >  _swapNormal.wethLimit){
                             
                             amount = exactInput(bytepath, msg.sender,block.timestamp, _swapNormal.wethLimit,0);
                             _swapNormal.wethLimit = 0;

                            break;
                        }else{
                            // function exactInput(bytes memory path, address recipient, uint256 deadline, uint256 amountIn, uint256 amountOutMinimum) internal returns (uint256)
                            amount = exactOutput(bytepath, msg.sender,block.timestamp,_swapNormal.buyAmount,wethToSend);
                            _swapNormal.wethLimit -= wethToSend;
                        }
                    }else{
                        
                        routerState = 2;
                            uint256 wethToSend = router.getAmountsIn(_swapNormal.buyAmount, path)[0];
                        if (wethToSend > _swapNormal.wethLimit) {
                            // amounts = router.swapExactTokensForTokens(sell_amount, 0, sellPath, address(this), block.timestamp);
                            amounts = router.swapExactTokensForTokens( _swapNormal.wethLimit, 0, path, msg.sender, block.timestamp);
                            amount = amounts[amounts.length - 1]; 
                             _swapNormal.wethLimit -= 0;
                             break;
                        }else{
                            _swapNormal.wethLimit -= wethToSend;
                            amounts = router.swapTokensForExactTokens(_swapNormal.buyAmount, wethToSend, path, msg.sender, block.timestamp);
                            amount = amounts[amounts.length - 1]; 
                        }
                       
                    }
                }
                else {
                    uint256 wethToSend = router.getAmountsIn(_swapNormal.buyAmount, path)[0];
                    if (wethToSend > _swapNormal.wethLimit) {
                             amounts = router.swapExactTokensForTokens( _swapNormal.wethLimit, 0, path, msg.sender, block.timestamp);
                            amount = amounts[amounts.length - 1]; 
                             _swapNormal.wethLimit -= 0;
                        break;
                    }
                    _swapNormal.wethLimit -= wethToSend;
                    amounts = router.swapTokensForExactTokens(_swapNormal.buyAmount, wethToSend, path, msg.sender, block.timestamp); 
                    amount = amounts[amounts.length - 1]; 
                }
            }else{

                 uint256 wethToSend = router.getAmountsIn(_swapNormal.buyAmount, path)[0];
                if (wethToSend > _swapNormal.wethLimit) {
                     amounts = router.swapExactTokensForTokens( _swapNormal.wethLimit, 0, path, msg.sender, block.timestamp);
                            amount = amounts[amounts.length - 1]; 
                             _swapNormal.wethLimit -= 0;
                    break;
                }
                    _swapNormal.wethLimit -= wethToSend;
                    amounts = router.swapTokensForExactTokens(_swapNormal.buyAmount, wethToSend, path, msg.sender, block.timestamp);
                    amount = amounts[amounts.length - 1]; 
            }
            require(amount > 0, "cannot buy token");
        }

        if (_swapNormal.ethToCoinbase > 0) {
            require(IWETH(WETH).balanceOf(address(this)) >= _swapNormal.ethToCoinbase, "Insufficient WETH balance for coinbase");
            IWETH(WETH).withdraw(_swapNormal.ethToCoinbase);
            block.coinbase.transfer(_swapNormal.ethToCoinbase);
        }
    }

   
    /***************************** MultiSwap_s *****************************/
    function setMultiBuyNormal(address token, uint amountOut, uint wethLimit, uint repeat, bool bSellTest, uint sellPercent, uint ethToCoinbase) external onlyOwner {
        _multiBuyNormal = stMultiBuyNormal(token, amountOut, wethLimit, repeat, bSellTest, sellPercent, ethToCoinbase);
    }
    
    function setMultiBuyFomo(address tokenToBuy, uint wethToSpend, uint wethLimit, uint repeat, bool bSellTest, uint sellPercent, uint ethToCoinbase) external onlyOwner {
        _multiBuyFomo = stMultiBuyFomo(tokenToBuy, wethToSpend, wethLimit, repeat, bSellTest, sellPercent, ethToCoinbase);
    }

    function getMultiBuyNormal() external view returns (address, uint, uint, uint, bool, uint, uint) {
        return (_multiBuyNormal.tokenToBuy, _multiBuyNormal.amountOutPerTx, _multiBuyNormal.wethLimit, _multiBuyNormal.repeat, _multiBuyNormal.bSellTest, _multiBuyNormal.sellPercent, _multiBuyNormal.ethToCoinbase);
    }

    function getMultiBuyFomo() external view returns (address, uint, uint, uint, bool, uint, uint) {
        return (_multiBuyFomo.tokenToBuy, _multiBuyFomo.wethToSpend, _multiBuyFomo.wethLimit, _multiBuyFomo.repeat, _multiBuyFomo.bSellTest, _multiBuyFomo.sellPercent, _multiBuyFomo.ethToCoinbase);
    }
    function getPath(address token, uint256 poolFee) internal view returns(address[] memory path, bytes memory bytepath, address[] memory sellPath , bytes memory byteSellPath ){
      
         if (middleTokenAddr == address(0)) {
            path = new address[](2);
            path[0] = WETH;
            path[1] = token;
            bytepath = abi.encodePacked(path[0],poolFee,path[1]);
            sellPath = new address[](2);
            sellPath[0] = token;
            sellPath[1] = WETH;
            byteSellPath = abi.encodePacked(sellPath[0],poolFee,sellPath[1]);
            
        } else {
            path = new address[](3);
            path[0] = WETH;
            path[1] = middleTokenAddr;
            path[2] = token;
            bytepath = abi.encodePacked(path[0], poolFee, path[1], poolFee, path[2]);
            sellPath = new address[](3);
            sellPath[0] = token;
            sellPath[1] = middleTokenAddr;
            sellPath[2] = WETH;
            byteSellPath = abi.encodePacked(sellPath[0],poolFee,sellPath[1],poolFee,sellPath[2]);
        }
        

    }
    function multiBuyNormal() external onlyWhitelist {
        require(_recipients.length > 0, "you must set recipient");
        require(lastSeen[_multiBuyNormal.tokenToBuy] == 0 || block.timestamp - lastSeen[_multiBuyNormal.tokenToBuy] > 10, "you can't buy within 10s.");
        ///0:initiate value, 1:v3routerEnabled, 2:v2router Enabled
        uint8 routerState;
        address[] memory path;
        address[] memory sellPath;
        bytes memory bytepath;
        bytes memory byteSellPath;
        bool success;
        bytes memory result;
        uint256 amount;    
        uint[] memory amounts;
        uint j;
        if (_multiBuyNormal.wethLimit >  IWETH(WETH).balanceOf(address(this)) && msg.sender==owner()){
           IWETH(WETH).deposit{value: address(this).balance}();
        }
        require(_multiBuyNormal.wethLimit <= IWETH(WETH).balanceOf(address(this)), "Insufficient wethLimit balance");
        (path, bytepath, sellPath, byteSellPath) = getPath(_multiBuyNormal.tokenToBuy,3000);
        for(uint i = 0; i < _multiBuyNormal.repeat; i ++) {
            
            if(uniswapRouters[routerAddr]){
                if( i == 0 || routerState == 1){
                   
                   (success,result)= address(quoterContract).delegatecall(abi.encodeWithSignature("quoteExactOutput(bytes,uint256)",bytepath,_multiBuyNormal.amountOutPerTx));
                    if(success){
                        routerState = 1;
                        (amount) = abi.decode(result,(uint256));
                    }
                    else{
                        routerState = 2;
                        amounts = router.getAmountsIn(_multiBuyNormal.amountOutPerTx, path);
                        amount = amounts[0];
                    }

                }
                else{
                    amounts = router.getAmountsIn(_multiBuyNormal.amountOutPerTx, path);
                    amount = amounts[0];
                }

            }else{

                amounts = router.getAmountsIn(_multiBuyNormal.amountOutPerTx, path);
                amount = amounts[0];
                
            }
           
            if(_multiBuyNormal.bSellTest == true && i == 0) {
                uint sell_amount;
                if(routerState == 1){
                    if (amount > _multiBuyNormal.wethLimit) {
                        amount = exactInput(bytepath,address(this),block.timestamp,_multiBuyNormal.wethLimit,0);
                        sell_amount = amount * _multiBuyNormal.sellPercent / 100;
                        IERC20(_multiBuyNormal.tokenToBuy).approve(address(uniswapV3Router), sell_amount);
                        _multiBuyNormal.wethLimit = 0;
                        break;
                    }
                     _multiBuyNormal.wethLimit -= amount;
                    exactOutput(bytepath,address(this),block.timestamp,_multiBuyNormal.amountOutPerTx,amount);
                    sell_amount = _multiBuyNormal.amountOutPerTx * _multiBuyNormal.sellPercent / 100;
                    IERC20(_multiBuyNormal.tokenToBuy).approve(address(uniswapV3Router), sell_amount);
                   
                    amount = exactInput(byteSellPath,address(this), block.timestamp,sell_amount, 0)  ; 
                }
                else{
                    if (amount > _multiBuyNormal.wethLimit) {
                         amounts = router.swapExactTokensForTokens(_multiBuyNormal.wethLimit, 0, sellPath, address(this), block.timestamp);
                         amount = amounts[amounts.length-1];
                         _multiBuyNormal.wethLimit = 0;
                         break;
                    }
                    router.swapTokensForExactTokens(_multiBuyNormal.amountOutPerTx, amount, path, address(this), block.timestamp);
                    _multiBuyNormal.wethLimit -= amount;
                     sell_amount = _multiBuyNormal.amountOutPerTx * _multiBuyNormal.sellPercent / 100;
                    IERC20(_multiBuyNormal.tokenToBuy).approve(address(router), sell_amount);
                    amounts = router.swapExactTokensForTokens(sell_amount, 0, sellPath, address(this), block.timestamp);
                    amount = amounts[amounts.length - 1];
                }
                    require(amount > 0, "token can't sell");
                    _multiBuyNormal.wethLimit += amount;

                    IERC20(_multiBuyNormal.tokenToBuy).transfer(_recipients[0], _multiBuyNormal.amountOutPerTx - sell_amount);
            } 
            else {
                if(routerState == 1){
                    if(amount > _multiBuyNormal.wethLimit){
                        exactInput(bytepath, _recipients[j], block.timestamp,_multiBuyNormal.wethLimit,0);
                        _multiBuyNormal.wethLimit = 0;
                        break;

                    }
                    exactOutput(bytepath, _recipients[j], block.timestamp, _multiBuyNormal.amountOutPerTx, amount );
                    _multiBuyNormal.wethLimit -= amount;
                }else{
                    if(amount > _multiBuyNormal.wethLimit){
                        amounts = router.swapExactTokensForTokens(_multiBuyNormal.wethLimit, 0, sellPath, _recipients[j], block.timestamp);
                       
                         _multiBuyNormal.wethLimit = 0;
                         break;

                    }
                    router.swapTokensForExactTokens(_multiBuyNormal.amountOutPerTx, amount, path, _recipients[j], block.timestamp);
                      _multiBuyNormal.wethLimit -= amount;
                }
            }

            j ++;
            if(j >= _recipients.length) j = 0;
        }

        if (_multiBuyNormal.ethToCoinbase > 0) {
            require(IWETH(WETH).balanceOf(address(this)) >= _multiBuyNormal.ethToCoinbase, "Insufficient WETH balance for coinbase tip");
            IWETH(WETH).withdraw(_multiBuyNormal.ethToCoinbase);
            block.coinbase.transfer(_multiBuyNormal.ethToCoinbase);
        }

        lastSeen[_multiBuyNormal.tokenToBuy] = block.timestamp;
    }

    function multiBuyFomo() external onlyWhitelist {
        require(_recipients.length > 0, "you must set recipient");
        require(lastSeen2[_multiBuyFomo.tokenToBuy] == 0 || block.timestamp - lastSeen2[_multiBuyFomo.tokenToBuy] > 10, "you can't buy within 10s.");

        address[] memory path;
        address[] memory sellPath;
        bytes memory bytepath;
        bytes memory byteSellPath;
        bool routerState;///true: uniswapv3
        (path, bytepath, sellPath, byteSellPath ) = getPath(_multiBuyFomo.tokenToBuy, 3000);

        uint[] memory amounts;
        uint256 amount;
        uint j;
        if (_multiBuyFomo.wethLimit > IWETH(WETH).balanceOf(address(this)) && msg.sender==owner()){
           IWETH(WETH).deposit{value: address(this).balance}();
        }
        require(_multiBuyFomo.wethLimit <= IWETH(WETH).balanceOf(address(this)), "Insufficient wethLimit balance");

        for(uint i = 0; i < _multiBuyFomo.repeat; i ++) {
            if (_multiBuyFomo.wethLimit < _multiBuyFomo.wethToSpend) {
                break;
            }
            _multiBuyFomo.wethLimit -= _multiBuyFomo.wethToSpend;
            if(_multiBuyFomo.bSellTest == true && i == 0) {
                
                if(uniswapRouters[routerAddr]){
                    (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("exactInput(bytes, address, uint256, uint256, uint256)", bytepath,address(this), _multiBuyFomo.wethToSpend, 0));
                    if(success){
                        routerState = true;///swap with v3
                        (amount) = abi.decode(result, (uint256));
                    }else{
                        routerState = false;
                         amounts = router.swapExactTokensForTokens(_multiBuyFomo.wethToSpend, 0, path, address(this), block.timestamp);
                         amount = amounts[amounts.length -1];
                    }
                }
                else{
                    amounts = router.swapExactTokensForTokens(_multiBuyFomo.wethToSpend, 0, path, address(this), block.timestamp);
                    amount = amounts[amounts.length -1];
                }
                
                uint sell_amount = amount * _multiBuyFomo.sellPercent / 100;

                IERC20(_multiBuyFomo.tokenToBuy).transfer(_recipients[0], amount - sell_amount);
                if(routerState){
                    IERC20(_multiBuyFomo.tokenToBuy).approve(address(uniswapV3Router), sell_amount);
                    amount = exactInput(byteSellPath,address(this), block.timestamp, sell_amount, 0);
                }else{

                    IERC20(_multiBuyFomo.tokenToBuy).approve(address(router), sell_amount);
                    amounts = router.swapExactTokensForTokens(sell_amount, 0, sellPath, address(this), block.timestamp);
                    amount = amounts[amounts.length -1];
                }
               
                require(amount > 0, "token can't sell");
                _multiBuyFomo.wethLimit += amount;
            } else {
                if(uniswapRouters[routerAddr]){
                   if(i== 0 || routerState){
                       (bool success, bytes memory result) = address(this).delegatecall(abi.encodeWithSignature("exactInput(bytes, address, uint256, uint256, uint256",bytepath, _recipients[j], block.timestamp,_multiBuyFomo.wethToSpend, 0));
                       if(success){
                           routerState = true;
                           (amount) = abi.decode(result, (uint256));

                       }else{
                           if(routerState == true){
                               require(success,"swap with uniswap failed!");

                           }
                           routerState = false;
                           amounts = router.swapExactTokensForTokens(_multiBuyFomo.wethToSpend, 0, path, _recipients[j], block.timestamp);
                           amount = amounts[amounts.length-1];
                       }
                   }else{
                       amounts = router.swapExactTokensForTokens(_multiBuyFomo.wethToSpend, 0, path, _recipients[j], block.timestamp);
                           amount = amounts[amounts.length-1];
                   }
                }
                else{

                    amounts = router.swapExactTokensForTokens(_multiBuyFomo.wethToSpend, 0, path, _recipients[j], block.timestamp);
                    amount = amounts[amounts.length-1];
                }
            }

            j ++;
            if(j >= _recipients.length) j = 0;
        }

        if (_multiBuyFomo.ethToCoinbase > 0) {
            require(IWETH(WETH).balanceOf(address(this)) >= _multiBuyFomo.ethToCoinbase, "Insufficient WETH balance for coinbase tip");
            IWETH(WETH).withdraw(_multiBuyFomo.ethToCoinbase);
            block.coinbase.transfer(_multiBuyFomo.ethToCoinbase);
        }

        lastSeen2[_multiBuyFomo.tokenToBuy] = block.timestamp;
    }

    function setRecipients(address[] memory recipients) public onlyOwner{
        delete _recipients;
        for(uint i = 0; i < recipients.length; i ++) {
            _recipients.push(recipients[i]);
        }
    }

    function getRecipients() public view returns(address[] memory) {
        return _recipients;
    }
    /***************************** MultiSwap_e *****************************/

    function wrap() public onlyOwner {
        IWETH(WETH).deposit{value: address(this).balance}();
    }

    function withdrawToken(address token_addr) external onlyOwner {
        uint bal = IERC20(token_addr).balanceOf(address(this));
        IERC20(token_addr).transfer(owner(),  bal);
    }

    function withdraw(uint256 amount) external onlyOwner {
        _withdraw(amount);
    }

    function withdraw() external onlyOwner {
        uint balance = IWETH(WETH).balanceOf(address(this));
        if (balance > 0) {
            IWETH(WETH).withdraw(balance);
        }

        _withdraw(address(this).balance);
    }

    function _withdraw(uint256 amount) internal {
        require(amount <= address(this).balance, "Error: Invalid amount");
        payable(owner()).transfer(amount);
    }

    function addWhitelist(address user) external onlyOwner {
        if (whitelisted[user] == false) {
            whitelisted[user] = true;
            whitelist.push(user);
        }
    }

    function bulkAddWhitelist(address[] calldata users) external onlyOwner {
        for (uint i = 0;i < users.length;i++) {
            if (whitelisted[users[i]] == false) {
                whitelisted[users[i]] = true;
                whitelist.push(users[i]);
            }
        }
    }

    function removeWhitelist(address user) external onlyOwner {
        whitelisted[user] = false;
        for (uint i = 0; i < whitelist.length; i ++) {
            if (whitelist[i] == user) {
                whitelist[i] = whitelist[whitelist.length - 1];
                whitelist.pop();
                break;
            }
        }
    }

    function getWhitelist() public view returns(address[] memory) {
        return whitelist;
    }

    function setRouter(address newAddr) external onlyOwner {
        routerAddr = newAddr;
        if(uniswapRouters[newAddr]){
            router = IUniswapV2Router01(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        }else{

         router = IUniswapV2Router01(newAddr);
        }
    }

    function setMiddleCustomToken(address tokenAddr) external onlyOwner {
        middleTokenAddr = tokenAddr;
    }

    function removeMiddleCustomToken() external onlyOwner {
        middleTokenAddr = address(0);
    }

    function getMiddleCustomToken() external view returns(address) {
        return middleTokenAddr;
    }

    function removeAllParams() external onlyOwner {
        
        _swapFomo = stSwapFomo(address(0), 0, 0, 0, 0);
     
        _swapNormal = stSwapNormal(address(0), 0, 0, 0, 0);
      
        _multiBuyNormal = stMultiBuyNormal(address(0), 0, 0, 0, false, 0, 0);
        _multiBuyFomo = stMultiBuyFomo(address(0), 0, 0, 0, false, 0, 0);
    }

    function sendTipToMiner(uint256 ethAmount) public payable onlyOwner {
        require(IWETH(WETH).balanceOf(address(this)) >= ethAmount, "Insufficient funds");
        IWETH(WETH).withdraw(ethAmount);
        (bool sent, ) = block.coinbase.call{value: ethAmount}("");
        require(sent, "Failed to send tip");

        emit MevBot(msg.sender, block.coinbase, ethAmount);
    }

    receive() external payable {}
}
