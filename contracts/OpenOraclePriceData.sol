pragma solidity ^0.5.10;
pragma experimental ABIEncoderV2;

import "./OpenOracleData.sol";

/**
 * @title The Open Oracle Price Data Contract
 * @notice Values stored in this contract should represent a USD price with 6 decimals precision
 * @author Compound Labs, Inc.
 */
contract OpenOraclePriceData is OpenOracleData {
    /**
     * @notice The event emitted when a source writes to its storage
     */
    event Write(address indexed source, string key, uint timestamp, uint value);

    /**
     * @notice The fundamental unit of storage for a reporter source
     */
    struct Datum {
        uint timestamp;
        uint value;
    }

    /**
     * @notice The most recent authenticated data from all sources
     * @dev This is private because dynamic mapping keys preclude auto-generated getters.
     */
    mapping(address => mapping(string => Datum)) private data;

    string public lastType;
    uint public lastTimestamp;
    string public lastKey;
    uint public lastValue;

    /**
     * @notice Write a bunch of signed datum to the authenticated storage mapping
     * @param message The payload containing the timestamp, and (key, value) pairs
     * @param signature The cryptographic signature of the message payload, authorizing the source to write
     * @return The keys that were written
     */
    function put(bytes calldata message, bytes calldata signature) external returns (string memory) {
        // Recover the source address
        address source = source(message, signature);

        // Decode the message and check the kind
        (string memory kind, uint timestamp, string memory key, uint value) = abi.decode(message, (string, uint, string, uint));
        /* require(keccak256(abi.encodePacked(kind)) == keccak256(abi.encodePacked("prices")), "Kind of data must be 'prices'"); */
        lastType = kind;
        lastTimestamp = timestamp;
        lastKey = key;
        lastValue = value;

        // Only update if newer than stored, according to source
        Datum storage prior = data[source][key];
        if (prior.timestamp < timestamp) {
            data[source][key] = Datum(timestamp, value);
            emit Write(source, key, timestamp, value);
        }

        return key;
    }

    /**
     * @notice Read a single key from an authenticated source
     * @param source The verifiable author of the data
     * @param key The selector for the value to return
     * @return The claimed Unix timestamp for the data and the price value (defaults to (0, 0))
     */
    function get(address source, string calldata key) external view returns (uint, uint) {
        Datum storage datum = data[source][key];
        return (datum.timestamp, datum.value);
    }

    /**
     * @notice Read only the value for a single key from an authenticated source
     * @param source The verifiable author of the data
     * @param key The selector for the value to return
     * @return The price value (defaults to 0)
     */
    function getPrice(address source, string calldata key) external view returns (uint) {
        return data[source][key].value;
    }
}
