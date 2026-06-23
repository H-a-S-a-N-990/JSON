const JSON_C_TO_STRING_PLAIN = 0;
const JSON_C_TO_STRING_SPACED = 1;
const JSON_C_TO_STRING_PRETTY = 2;

local _JSON_ = {
    indentLevel = 0,
    indentChar = "    "
};

// String escaping for JSON
function _JSON_EscapeString(str) {
    local result = "\"";
    foreach (c in str) {
        switch (c) {
            case '\"': result += "\\\""; break;
            case '\\': result += "\\\\"; break;
            case '\n': result += "\\n"; break;
            case '\r': result += "\\r"; break;
            case '\t': result += "\\t"; break;
            case '\b': result += "\\b"; break;
            case '\f': result += "\\f"; break;
            default: result += c.tochar(); break;
        }
    }
    result += "\"";
    return result;
}

// Get current indentation
function _JSON_GetIndent() {
    local indent = "";
    for (local i = 0; i < _JSON_.indentLevel; i++) {
        indent += _JSON_.indentChar;
    }
    return indent;
}

// Serialize any value to JSON string
function _JSON_Serialize(val, format = JSON_C_TO_STRING_PLAIN) {
    local type = typeof val;
    
    switch (type) {
        case "null":
            return "null";
        
        case "bool":
            return val ? "true" : "false";
        
        case "integer":
        case "float":
            return val.tostring();
        
        case "string":
            return _JSON_EscapeString(val);
        
        case "array":
            if (val.len() == 0) return "[]";
            
            local result = "[";
            local useSpacing = (format >= JSON_C_TO_STRING_SPACED);
            local useNewlines = (format == JSON_C_TO_STRING_PRETTY);
            
            _JSON_.indentLevel++;
            local first = true;
            
            foreach (item in val) {
                if (!first) result += ",";
                if (useNewlines) result += "\n" + _JSON_GetIndent();
                else if (useSpacing && !first) result += " ";
                
                result += _JSON_Serialize(item, format);
                first = false;
            }
            
            _JSON_.indentLevel--;
            if (useNewlines) result += "\n" + _JSON_GetIndent();
            result += "]";
            return result;
        
        case "table":
        case "instance":
            if (val.len() == 0) return "{}";
            
            local result = "{";
            local useSpacing = (format >= JSON_C_TO_STRING_SPACED);
            local useNewlines = (format == JSON_C_TO_STRING_PRETTY);
            
            _JSON_.indentLevel++;
            local first = true;
            
            foreach (key, value in val) {
                // Skip functions/methods
                local valType = typeof value;
                if (valType == "function" || valType == "native function" || valType == "class") {
                    continue;
                }
                
                // Skip internal keys that cause problems
                if (key == "constructor" || key == "class" || key == "weakref") {
                    continue;
                }
                
                if (!first) result += ",";
                if (useNewlines) result += "\n" + _JSON_GetIndent();
                else if (useSpacing && !first) result += " ";
                
                result += _JSON_EscapeString(key) + ":";
                if (useSpacing) result += " ";
                result += _JSON_Serialize(value, format);
                first = false;
            }
            
            _JSON_.indentLevel--;
            if (useNewlines) result += "\n" + _JSON_GetIndent();
            result += "}";
            return result;
        
        default:
            if (type == "function" || type == "native function") {
                return "null";
            }
            // For unknown types, return null instead of throwing
            return "null";
    }
}

// Parser state (global to avoid class context)
_JSON_.tokens <- null;
_JSON_.pos <- 0;

// Tokenize JSON string
function _JSON_Tokenize(jsonStr) {
    _JSON_.tokens = [];
    _JSON_.pos = 0;
    local i = 0;
    local len = jsonStr.len();
    
    while (i < len) {
        local c = jsonStr[i];
        
        // Skip whitespace
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
            i++;
            continue;
        }
        
        // Single character tokens
        if (c == '{' || c == '}' || c == '[' || c == ']' || c == ':' || c == ',') {
            _JSON_.tokens.push(c.tochar());
            i++;
            continue;
        }
        
        // String literals
        if (c == '\"') {
            local str = "";
            i++; // Skip opening quote
            while (i < len) {
                c = jsonStr[i];
                if (c == '\"') {
                    i++;
                    break;
                }
                if (c == '\\') {
                    i++;
                    if (i >= len) throw "Unexpected end of string";
                    local esc = jsonStr[i];
                    switch (esc) {
                        case '\"': str += "\""; break;
                        case '\\': str += "\\"; break;
                        case '/': str += "/"; break;
                        case 'n': str += "\n"; break;
                        case 'r': str += "\r"; break;
                        case 't': str += "\t"; break;
                        case 'b': str += "\b"; break;
                        case 'f': str += "\f"; break;
                        default: str += "\\" + esc.tochar(); break;
                    }
                } else {
                    str += c.tochar();
                }
                i++;
            }
            _JSON_.tokens.push(str);
            continue;
        }
        
        // Numbers
        if ((c >= '0' && c <= '9') || c == '-' || c == '+' || c == '.') {
            local num = "";
            while (i < len && ((jsonStr[i] >= '0' && jsonStr[i] <= '9') || 
                   jsonStr[i] == '-' || jsonStr[i] == '+' || jsonStr[i] == '.' || 
                   jsonStr[i] == 'e' || jsonStr[i] == 'E')) {
                num += jsonStr[i].tochar();
                i++;
            }
            _JSON_.tokens.push(num);
            continue;
        }
        
        // Keywords: true, false, null
        if (c == 't' || c == 'f' || c == 'n') {
            local word = "";
            while (i < len && jsonStr[i] >= 'a' && jsonStr[i] <= 'z') {
                word += jsonStr[i].tochar();
                i++;
            }
            _JSON_.tokens.push(word);
            continue;
        }
        
        throw "Unexpected character: " + c;
    }
}

function _JSON_Peek() {
    if (_JSON_.pos < _JSON_.tokens.len()) return _JSON_.tokens[_JSON_.pos];
    return null;
}

function _JSON_Next() {
    if (_JSON_.pos < _JSON_.tokens.len()) return _JSON_.tokens[_JSON_.pos++];
    throw "Unexpected end of JSON input";
}

// Parse a JSON value
function _JSON_ParseValue() {
    local token = _JSON_Peek();
    
    if (token == null) throw "Unexpected end of JSON";
    
    if (token == "{") return _JSON_ParseObject();
    if (token == "[") return _JSON_ParseArray();
    if (token == "true") { _JSON_.pos++; return true; }
    if (token == "false") { _JSON_.pos++; return false; }
    if (token == "null") { _JSON_.pos++; return null; }
    if (typeof token == "string" && token != "true" && token != "false" && token != "null" && 
        token != "{" && token != "}" && token != "[" && token != "]" && token != ":" && token != ",") {
        return _JSON_Next();
    }
    
    return _JSON_ParseNumber();
}

// Parse JSON object
function _JSON_ParseObject() {
    local obj = {};
    _JSON_Next(); // Skip '{'
    
    local token = _JSON_Peek();
    if (token == "}") {
        _JSON_Next();
        return obj;
    }
    
    while (true) {
        local key = _JSON_Next();
        local colon = _JSON_Next();
        if (colon != ":") throw "Expected ':'";
        
        local value = _JSON_ParseValue();
        
        // Use rawset to avoid reserved keyword issues
        try {
            obj[key] <- value;
        } catch (e) {
            rawset(obj, key, value);
        }
        
        token = _JSON_Next();
        if (token == "}") break;
        if (token != ",") throw "Expected ',' or '}'";
    }
    
    return obj;
}

// Parse JSON array
function _JSON_ParseArray() {
    local arr = [];
    _JSON_Next(); // Skip '['
    
    local token = _JSON_Peek();
    if (token == "]") {
        _JSON_Next();
        return arr;
    }
    
    while (true) {
        local value = _JSON_ParseValue();
        arr.push(value);
        
        token = _JSON_Next();
        if (token == "]") break;
        if (token != ",") throw "Expected ',' or ']'";
    }
    
    return arr;
}

// Parse number
function _JSON_ParseNumber() {
    local numStr = _JSON_Next();
    if (numStr.find(".") != null || numStr.find("e") != null || numStr.find("E") != null) {
        return numStr.tofloat();
    }
    return numStr.tointeger();
}

// ==================== PUBLIC API ====================

function toJSON(variable, format = JSON_C_TO_STRING_PLAIN) {
    try {
        _JSON_.indentLevel = 0; // Reset indent level
        return _JSON_Serialize(variable, format);
    } catch (e) {
        throw "toJSON error: " + e;
    }
}

function fromJSON(jsontext) {
    try {
        _JSON_Tokenize(jsontext);
        local result = _JSON_ParseValue();
        return result;
    } catch (e) {
        throw "fromJSON error: " + e;
    }
}

function toJSONFile(filename, variable, format = JSON_C_TO_STRING_PLAIN) {
    try {
        _JSON_.indentLevel = 0;
        local jsonStr = _JSON_Serialize(variable, format);
        local f = file(filename, "w");
        f.writestring(jsonStr);
        f.close();
        return true;
    } catch (e) {
        throw "toJSONFile error: " + e;
    }
}

function fromJSONFile(filename) {
    try {
        local f = file(filename, "r");
        local content = f.readstring(1024 * 1024);
        f.close();
        return fromJSON(content);
    } catch (e) {
        throw "fromJSONFile error: " + e;
    }
}
