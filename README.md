# Squirrel JSON Module

A pure Squirrel implementation for JSON serialization and deserialization.

## Functions

### `toJSON(variable, format = JSON_C_TO_STRING_PLAIN)`
Converts a Squirrel variable into a JSON-formatted string.

### `fromJSON(jsontext)`
Parses a JSON-formatted string and converts it into a Squirrel variable.

### `toJSONFile(filename, variable, format = JSON_C_TO_STRING_PLAIN)`
Writes a variable to a file in JSON format.

### `fromJSONFile(filename)`
Reads a JSON file and parses it into a variable.

## Formatting Constants

- `JSON_C_TO_STRING_PLAIN` (0) - Compact
- `JSON_C_TO_STRING_SPACED` (1) - Spaced
- `JSON_C_TO_STRING_PRETTY` (2) - Pretty printed

## Examples

### toJSON
```squirrel
local data = { name = "Player1", score = 100, admin = true };
local json = toJSON(data);
print(json);
// {"name":"Player1","score":100,"admin":true}

local pretty = toJSON(data, JSON_C_TO_STRING_PRETTY);
print(pretty);
// {
//     "name": "Player1",
//     "score": 100,
//     "admin": true
// }
```
###fromJSON
```squirrel
local jsonStr = "{\"name\":\"Player1\",\"items\":[\"sword\",\"shield\"]}";
local data = fromJSON(jsonStr);
print(data.name);    // Player1
print(data.items[0]); // sword
```
###toJSONFile
```squirrel
local config = {
    serverName = "My Server",
    maxPlayers = 50,
    password = false
};
toJSONFile("config.json", config, JSON_C_TO_STRING_PRETTY);
```
###fromJSONFile
```squirrel
local config = fromJSONFile("config.json");
print(config.serverName); // My Server
print(config.maxPlayers); // 50
```
###Arrays
```squirrel
local arr = [1, 2, 3, "hello", true, null];
local json = toJSON(arr);
print(json); // [1,2,3,"hello",true,null]

local parsed = fromJSON("[10, 20, 30]");
print(parsed[1]); // 20
```
###Nested Objects
```squirrel
local player = {
    name = "Player1",
    pos = { x = 10.5, y = 20.3, z = 5.0 },
    weapons = ["deagle", "ak47"]
};
local json = toJSON(player, JSON_C_TO_STRING_PRETTY);
print(json);
// {
//     "name": "Player1",
//     "pos": {
//         "x": 10.5,
//         "y": 20.3,
//         "z": 5.0
//     },
//     "weapons": [
//         "deagle",
//         "ak47"
//     ]
// }
```
###Error Handling
```squirrel
try {
    local data = fromJSON("invalid json");
} catch (e) {
    print("Parse error: " + e);
}

try {
    toJSONFile("data.json", myData);
} catch (e) {
    print("Save error: " + e);
}
```
