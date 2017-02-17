module vls.server.requests;

import watt.text.json;

import vls.server.error;

/**
 * Return the URI from a TextDocument parameter.
 * Params:
 *   param = the param value from the RequestObject.
 * Returns: null if no error, or an Error object otherwise.
 */
fn parseTextDocument(param: Value, out uri: string) Error
{
	if (param.type() != DomType.OBJECT) {
		return Error.invalidParams("param is not an object");
	}
	if (!param.hasObjectKey("textDocument")) {
		return Error.invalidParams("param does not have a textDocument key");
	}
	td := param.lookupObjectKey("textDocument");
	if (td.type() != DomType.OBJECT) {
		return Error.invalidParams("param.textDocument is not an object");
	}
	if (!td.hasObjectKey("uri")) {
		return Error.invalidParams("param.textDocument has no uri key");
	}
	uriVal := td.lookupObjectKey("uri");
	if (uriVal.type() != DomType.STRING) {
		return Error.invalidParams("textDocument.uri isn't a string");
	}
	uri = uriVal.str();
	return null;
}
