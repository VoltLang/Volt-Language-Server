module vls.lsp.outbound;

import vls.lsp.message;
import vls.lsp.constants;

import watt.io;

/**
 * Send `msg` to the client, with the appropriate headers.
 */
fn send(msg: string)
{
	output.writefln("%s:%s", LENGTH_HEADER, msg.length);
	output.writeln("");
	output.write(msg);
	output.flush();
}
