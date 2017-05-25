module vls.lsp.outbound;

import vls.lsp.message;
import vls.lsp.constants;

import watt.io;
import watt.io.streams;

/**
 * Send `msg` to the client, with the appropriate headers.
 */
fn send(msg: string, logf: OutputFileStream)
{
	if (logf !is null) {
		logf.writefln("SENDING: %s", msg);
		logf.flush();
	}
	version (Windows) {
		output.writefln("%s:%s", LENGTH_HEADER, msg.length);
		output.writeln("");
		output.write(msg);
		output.flush();
	} else {
		output.writef("%s:%s\r\n", LENGTH_HEADER, msg.length);
		output.write("\r\n");
		output.write(msg);
		output.flush();
	}
}
