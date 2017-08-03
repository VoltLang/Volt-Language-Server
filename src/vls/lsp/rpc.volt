module vls.lsp.rpc;

import core.exception;
import watt.text.format;
import json = watt.json;

class RpcException : Exception
{
	this(msg: string)
	{
		super(msg);
	}
}

/**
 * A class to assist in the handling of a JSON RPC server,
 * as described by http://www.jsonrpc.org/specification.
 *
 * The JSON RPC specification is transport agnostic.
 * So while this is called a 'server', this only deals in
 * JSON objects from watt.text.json.dom directly. This needs
 * to be wrapped in whatever layer your application needs --
 * HTTP, etc.
 */
abstract class RpcServer
{
public:

private:

public:
	/**
	 * Handle a request object.
	 * Returns: The response object.
	 */
	fn request(requestObject: RequestObject) ResponseObject
	{
		return null;
	}

public:
}

class RequestObject
{
public:
	methodName: string;
	params: json.Value;  //< Optional.
	id: json.Value;  //< Optional. Check notification.
	notification: bool;  //< If true, id isn't present.

public:
	/**
	 * Given a request object as a string, construct a new RequestObject.
	 */
	this(requestText: string)
	{
		this(json.parse(requestText));
	}

	/**
	 * Given a request object as a json Value, construct a new RequestObject.
	 */
	this(requestValue: json.Value)
	{
		// Is this request value an object?
		checkType(requestValue, json.DomType.OBJECT, "rpc request value");
		// Does it have a valid jsonrpc?
		jsonrpc := checkKey(requestValue, "jsonrpc", "rpc request value");
		checkType(jsonrpc, json.DomType.STRING, "rpc request's jsonrpc");
		check(jsonrpc.str() == "2.0", "jsonrpc has wrong value");
		// Get the method name.
		method := checkKey(requestValue, "method", "rpc request value");
		checkType(method, json.DomType.STRING, "rpc request's method");
		methodName = method.str();
		// Get the parameters.
		if (requestValue.hasObjectKey("params")) {
			params = requestValue.lookupObjectKey("params");
		}
		if (requestValue.hasObjectKey("id")) {
			// Get the id.
			id = checkKey(requestValue, "id", "rpc request id");
			notification = false;
		} else {
			notification = true;
		}
	}
}

class ResponseObject
{
}

/**
 * If b is false, throw an RpcException with msg.
 */
private fn check(b: bool, msg: string)
{
	if (!b) {
		throw new RpcException(msg);
	}
}

/**
 * If val is not type, throw an RpcException, referencing name.
 */
private fn checkType(val: json.Value, type: json.DomType, name: string)
{
	if (val.type() == type) {
		return;
	}
	msg: string;
	final switch (type) with (json.DomType) {
	case NULL: msg = format("%s is not a null type", name); break;
	case BOOLEAN: msg = format("%s is not a boolean type"); break;
	case DOUBLE: msg = format("%s is not a double type"); break;
	case LONG: msg = format("%s is not a long type"); break;
	case ULONG: msg = format("%s is not a ulong type"); break;
	case STRING: msg = format("%s is not a string type"); break;
	case OBJECT: msg = format("%s is not an object type"); break;
	case ARRAY: msg = format("%s is not an array type"); break;
	}
	throw new RpcException(msg);
}

/**
 * Check that val has a given key, or throw an RpcException, referencing name.
 * Doesn't check that val is an object, use checkType.
 * Returns: The key, if it's present.
 */
private fn checkKey(val: json.Value, key: string, name: string) json.Value
{
	if (!val.hasObjectKey(key)) {
		throw new RpcException(format("%s does not have a key '%s'", name, key));
	}
	return val.lookupObjectKey(key);
}
