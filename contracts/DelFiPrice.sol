pragma solidity ^0.5.12;
pragma experimental ABIEncoderV2;

import "./OpenOraclePriceData.sol";
import "./OpenOracleView.sol";
import "./SafeMath.sol";

/**
 * @notice The DelFi Price Feed View
 * @author Compound Labs, Inc.
 */
contract DelFiPrice is OpenOracleView {
    using SafeMath for *;

    /**
     * @notice The event emitted when a price is written to storage
     */
    event Price(string symbol, uint64 price);

    address anchor;
    uint anchorMantissa;

    /**
     * @notice The mapping of medianized prices per symbol
     */
    mapping(string => uint64) public prices;

    constructor(OpenOraclePriceData data_, address[] memory sources_, address anchor_, uint anchorMantissa_) public OpenOracleView(data_, sources_) {
        anchor = anchor_;
        anchorMantissa_ = anchorMantissa;
    }

    /**
     * @notice Primary entry point to post and recalculate prices
     * @dev We let anyone pay to post anything, but only sources count for prices.
     * @param messages The messages to post to the oracle
     * @param signatures The signatures for the corresponding messages
     */
    function postPrices(bytes[] calldata messages, bytes[] calldata signatures, string[] calldata symbols) external {
        require(messages.length == signatures.length, "messages and signatures must be 1:1");
        require(messages.length == symbols.length, "messages and symbols must be 1:1");

        for (uint i = 0; i < messages.length; i++) {
            // Post the data
            OpenOraclePriceData(address(data)).put(messages[i], signatures[i]);

            string memory symbol = symbols[i];
            uint64 medianPrice = medianPrice(symbol, sources);
            uint64 anchorPrice = OpenOraclePriceData(address(data)).getPrice(anchor, symbol);
            uint anchorRatio = medianPrice.mul(10e18).div(anchorPrice);

            // Only update the view's price if the median of the sources is within a bound
            if (anchorRatio < anchorMantissa.add(10e18) || anchorRatio > anchorMantissa.sub(10e18)) {
                prices[symbol] = medianPrice;
                emit Price(symbol, medianPrice);
            }
        }
    }

    /**
     * @notice Calculates the median price over any set of sources
     * @param symbol The symbol to calculate the median price of
     * @param sources_ The sources to use when calculating the median price
     * @return median The median price over the set of sources
     */
    function medianPrice(string memory symbol, address[] memory sources_) public view returns (uint64 median) {
        require(sources_.length > 0, "sources list must not be empty");

        uint N = sources_.length;
        uint64[] memory postedPrices = new uint64[](N);
        for (uint i = 0; i < N; i++) {
            postedPrices[i] = OpenOraclePriceData(address(data)).getPrice(sources_[i], symbol);
        }

        uint64[] memory sortedPrices = sort(postedPrices);
        return sortedPrices[N / 2];
    }

    /**
     * @notice Helper to sort an array of uints
     * @param array Array of integers to sort
     * @return The sorted array of integers
     */
    function sort(uint64[] memory array) private pure returns (uint64[] memory) {
        uint N = array.length;
        for (uint i = 0; i < N; i++) {
            for (uint j = i + 1; j < N; j++) {
                if (array[i] > array[j]) {
                    uint64 tmp = array[i];
                    array[i] = array[j];
                    array[j] = tmp;
                }
            }
        }
        return array;
    }
}
