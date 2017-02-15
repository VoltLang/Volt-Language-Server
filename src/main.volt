module main;

import core.exception;
import core.stdc.stdio;
import watt.io;
import watt.conv;
import watt.text.string;
import watt.text.format;
import watt.text.json.rpc;

enum LENGTH_HDR = "Content-Length:";
enum TYPE_HDR   = "Content-Type:";

fn main(args: string[]) i32
{
	logf := new OutputFileStream("C:/Users/Bernard/Desktop/log.txt");  // This is obviously temporary.
	scope (exit) logf.close();
	length: size_t;
	remainder: string;
	while (true) {
		inline: string;
		if (remainder.length == 0) {
			inline = input.readln();
		} else {
			inline = remainder;
			remainder = "";
		}
		if (inline.startsWith(LENGTH_HDR)) {
			length = toUlong(strip(inline[LENGTH_HDR.length .. $]));
		}
		inline = input.readln();
		if (inline.startsWith(TYPE_HDR)) {
			// Just ignore it for now.
			inline = input.readln();
		}
		if (inline.length != 0) {
			throw new Exception("expected blank line");
		}
		inline = input.readln();
		if (inline.length < length) {
			throw new Exception("Received less bytes than expected");
		}
		remainder = inline[length .. $];
		inline = inline[0 .. length];
		logf.writefln("Received request object: %s (%s)", inline, inline.length);
		logf.flush();
		handleRequest(new RequestObject(inline));
	}
	return 0;
}

fn handleRequest(ro: RequestObject)
{
	switch (ro.methodName) {
	case "initialize":
		msg := format(`{"id":%s, "result":{"capabilities":{"textDocumentSync": {"openClose": "true", "change": 1}}}}`, ro.id.integer());
		output.writefln("Content-Length:%s\n", msg.length);
		output.writeln(msg);
		output.flush();
		break;
	default: break;
	}
}
