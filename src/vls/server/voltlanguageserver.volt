module vls.server.voltlanguageserver;

import main : retval;
import watt.io;
import watt.io.file;
import watt.text.string;
import watt.text.json.rpc;

import parsec.arg;
import parsec.parser.base;
import parsec.parser.toplevel;
import parsec.lex.source;
import parsec.lex.lexer;
import ir = parsec.ir.ir;

import vls.lsp;
import vls.server.responses;
import vls.server.requests;

class VoltLanguageServer
{
public:
	logf: OutputFileStream;
	settings: Settings;

private:
	mDatabase: ir.Module[string];

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
		case "textDocument/documentSymbol":
			uri: string;
			err := parseTextDocument(ro.params, out uri);
			if (err !is null) {
				send(responseError(ro, err));
				return CONTINUE_LISTENING;
			}
			parse(uri);
			return CONTINUE_LISTENING;
		default:
			// TODO: Return error
			logf.writefln("Unknown method: %s", ro.methodName);
			logf.flush();
			return CONTINUE_LISTENING;
		}
		assert(false);
	}

	fn parse(uri: string)
	{
		// TEMPORARY
		filepath := uri["file:///".length .. $];
		filepath = filepath.replace("%3A", ":");
		src := new Source(cast(string)read(filepath), filepath);
		mod: ir.Module;
		ps := new ParserStream(lex(src), settings);
		parseModule(ps, out mod);
		mDatabase[uri] = mod;
		logf.writefln("Parsed %s %s", filepath, mod !is null);
		logf.flush();
	}
}
