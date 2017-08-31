/**
 * Handles inbound communication between the client (editor) and the server (us).
 */
module vls.lsp.inbound;

import core.exception : Exception;
import watt.io : input;
import watt.conv : toUlong;
import watt.text.utf : encode;
import watt.text.string : split, strip;
import watt.text.format : format;

import vls.lsp.constants;
import vls.lsp.message;

/**
 * Listen for request objects, dispatch appropriately.
 * Returns: true if we should continue to listen, false otherwise.
 */
fn listen(handle: dg(LspMessage) bool) bool
{
	if (input.eof()) {
		return STOP_LISTENING;
	}
	buf: char[];
	newline: bool;
	msg: LspMessage;
	while (true) {
		c := input.get();
		if (c == '\n') {
			if (newline) {
				// Beginning of content.
				if (msg.contentLength == 0) {
					throw new Exception("missing Content-Length header");
				} else {
					msg.content = readContent(msg.contentLength);
					return handle(msg);
				}
			} else if (buf.length != 0) {
				parseHeader(buf, ref msg);
			}
			newline = true;
		} else if (c != '\r') {
			encode(ref buf, c);
		}
	}
}

private:

/// Read a string from the next `length` bytes of stdin, or throw an Exception.
fn readContent(length: size_t) string
{
	buf: char[];
	i: size_t;
	while (i++ < length) {
		if (input.eof()) {
			throw new Exception("unexpected EOF");
		}
		c := input.get();
		encode(ref buf, c);
	}
	assert(buf.length == length);
	return cast(string)buf;
}

fn parseHeader(text: char[], ref msg: LspMessage)
{
	portions := split(cast(string)text, ':');
	if (portions.length != 2) {
		throw new Exception("headers are separated by a ':'");
	}
	switch (portions[0]) {
	case LENGTH_HEADER:
		msg.contentLength = cast(size_t)toUlong(strip(portions[1]));
		break;
	case TYPE_HEADER:
		// We honestly don't care. Just assume UTF-8, no implementation uses anything else.
		break;
	default:
		throw new Exception(format("unknown header '%s'", portions[0]));
	}
}
