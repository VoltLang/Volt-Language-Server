module vls.server.voltlanguageserver;

import main : retval;
import watt.io;
import watt.text.json.rpc;

import vls.lsp;
import vls.server.responses;

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
		return handleRO(new RequestObject(msg.content));
	}

private:
	fn handleRO(ro: RequestObject) bool
	{
		switch (ro.methodName) {
		case "initialize":
			send(responseInitialized(ro));
			return CONTINUE_LISTENING;
		case "initialized":
			assert(ro.notification);
			return CONTINUE_LISTENING;
		case "shutdown":
			retval = 0;
			send(responseShutdown(ro));
			return CONTINUE_LISTENING;
		case "exit":
			return STOP_LISTENING;
		default:
			// TODO: Return error
			logf.writefln("Unknown method: %s", ro.methodName);
			logf.flush();
			return CONTINUE_LISTENING;
		}
		assert(false);
	}
}
