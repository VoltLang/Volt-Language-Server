module main;

import core.exception;
import watt.io;
import watt.conv;
import watt.text.string;
import watt.text.json.rpc;

enum LENGTH_HDR = "Content-Length:";
enum TYPE_HDR   = "Content-Type:";

fn main(args: string[]) i32
{
	logf := new OutputFileStream("C:/Users/Bernard/Desktop/log.txt");
	scope (exit) logf.close();
	length: size_t;
	while (true) {
		logf.writeln("Hi. Now waiting.");
		inline := input.readln();
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
		remainder := inline[length .. $];
		inline = inline[0 .. length];
		logf.writefln("Received request object: %s (%s)", inline, inline.length);
		logf.flush();
		ro := new RequestObject(inline);
		logf.writefln("Overhang:'%s'", remainder);
		logf.flush();
	}
	return 0;
}
