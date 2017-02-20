module vls.server.voltlanguageserver;

import main : retval;
import watt.io;
import watt.io.file;
import watt.text.string;
import watt.text.json.rpc;

import parsec.arg;
import parsec.parser.base;
import parsec.parser.toplevel;
import parsec.parser.errors;
import parsec.parser.parser;
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

public:
	this()
	{
		logf = new OutputFileStream("log.txt");
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
				logf.writefln("SENDING ERROR");
				logf.flush();
				send(responseError(ro, err));
				return CONTINUE_LISTENING;
			}
			logf.writefln("RECEIVED: textDocument/documentSymbol %s", uri);
			logf.flush();
			mod := parse(uri);
			logf.writefln("Building response.");
			logf.flush();
			reply := responseSymbolInformation(ro, uri, mod);
			logf.writefln("Built response.");
			logf.flush();
			logf.writefln("Sending functions: %s", reply);
			logf.flush();
			send(reply);
			//logf.writefln("%s", responseSymbolInformation(ro, uri, mod));
			//logf.flush();
			return CONTINUE_LISTENING;
		default:
			// TODO: Return error
			logf.writefln("Unknown method: %s", ro.methodName);
			logf.flush();
			return CONTINUE_LISTENING;
		}
		assert(false);
	}

	fn parse(uri: string) ir.Module
	{
		// TEMPORARY
		filepath := uri["file:///".length .. $];
		filepath = filepath.replace("%3A", ":");
		log("<source>");
		src := new Source(cast(string)read(filepath), filepath);
		log("</source>");
		mod: ir.Module;
		log("<ps>");
		ps := new ParserStream(lex(src), settings);
		log("</ps>");
		ps.get();  // Skip begin
		logf.writefln("A");
		logf.flush();
		status := parseModule(ps, out mod);
		logf.writefln("B");
		logf.flush();
		if (status != ParseStatus.Succeeded) {
			// TODO: Make the parsec error function not throw, but just give the error string.
			foreach (err; ps.parserErrors) {
				logf.writefln("Failure %s @ line %s", cast(i32)err.kind, err.location.line);
				if (cast(i32)err.kind == 6) {
					expected := cast(ParserExpected)err;
					logf.writefln("Expected %s", expected.message);
				}
				logf.flush();
			}
		}
		logf.flush();
		return mod;
	}

	fn log(s: string)
	{
		logf.writefln(s);
		logf.flush();
	}
}
