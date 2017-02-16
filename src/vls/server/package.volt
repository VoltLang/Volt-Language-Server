/**
 * Processes client messages, sends information back.
 */
module vls.server;

import watt.io;

import vls.lsp;

class VoltLanguageServer
{
public:
	logf: OutputFileStream;

public:
	this()
	{
		logf = new OutputFileStream("C:/Users/Bernard/Desktop/log.txt");
	}

	/// LSP listen callback.
	fn handle(msg: LspMessage) bool
	{
		logf.writefln("MESSAGE: \"%s\"\n", msg.content);
		logf.flush();
		return CONTINUE_LISTENING;
	}
}
