pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import "./OpenOraclePriceData.sol";
import "./OpenOracleView.sol";

/**
 * @notice The DelFi Price Feed View
 * @author Compound Labs, Inc.
 */
contract DelFiPrice is OpenOracleView {
    /**
     * @notice The event emitted when a price is written to storage
     */
    event Price(string symbol, uint price);

    /**
     * @notice The mapping of medianized prices per symbol
     */
    mapping(string => uint) public _prices;
    mapping(uint => string) public inversePrices;
    mapping(uint => uint) public foundPrice;
    struct FuckingPrice {
        string symbol;
        uint price;
    }
    mapping(uint => FuckingPrice) public fPrices;

    constructor(OpenOraclePriceData data_, address[] memory sources_) public OpenOracleView(data_, sources_) {}
    uint public numb = 2;

    /**
     * @notice Primary entry point to post and recalculate prices
     * @dev We let anyone pay to post anything, but only sources count for prices.
     * @param messages The messages to post to the oracle
     * @param signatures The signatures for the corresponding messages
     */
    function postPrices(bytes[] calldata messages, bytes[] calldata signatures, string[] calldata symbols) external {
        require(messages.length == signatures.length, "messages and signatures must be 1:1");

        _prices["trick"] = 99;
        // Post the messages, whatever they are
        for (uint i = 0; i < messages.length; i++) {
            OpenOraclePriceData(address(data)).put(messages[i], signatures[i]);
            _prices["trock"] = 89;
        }

        // Recalculate the asset prices for the symbols to update
        for (uint i = 0; i < symbols.length; i++) {
            string memory symbol = symbols[i];

            _prices["truck"] = 79;
            // Calculate the median price, write to storage, and emit an event
            uint price = medianPrice(symbol, sources);
            _prices[symbol] = price;
            inversePrices[i] = symbol;
            foundPrice[i] = price;
            fPrices[i] = FuckingPrice(symbol, price);
            emit Price(symbol, price);
        }
    }

    /**
     * @notice Calculates the median price over any set of sources
     * @param symbol The symbol to calculate the median price of
     * @param sources_ The sources to use when calculating the median price
     * @return median The median price over the set of sources
     */
    function medianPrice(string memory symbol, address[] memory sources_) public view returns (uint median) {
        require(sources_.length > 0, "sources list must not be empty");

        uint N = sources_.length;
        uint[] memory postedPrices = new uint[](N);
        for (uint i = 0; i < N; i++) {
            postedPrices[i] = OpenOraclePriceData(address(data)).getPrice(sources_[i], symbol);
        }

        uint[] memory sortedPrices = sort(postedPrices);
        return sortedPrices[N / 2];
    }

    /**
     * @notice Helper to sort an array of uints
     * @param array Array of integers to sort
     * @return The sorted array of integers
     */
    function sort(uint[] memory array) private pure returns (uint[] memory) {
        uint N = array.length;
        for (uint i = 0; i < N; i++) {
            for (uint j = i + 1; j < N; j++) {
                if (array[i] > array[j]) {
                    uint tmp = array[i];
                    array[i] = array[j];
                    array[j] = tmp;
                }
            }
        }
        return array;
    }

    function prices(string memory source) public returns (uint) {
        /* return uint(3); */
        return _prices[source];
    }

    function fPrice(uint i) public returns (FuckingPrice memory ) {
        return fPrices[i];
    }
}
