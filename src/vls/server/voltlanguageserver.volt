module vls.server.voltlanguageserver;

import main : retval;
import watt.io;
import watt.io.streams;
import watt.path;
import watt.io.file;
import watt.text.string;
import watt.process.environment;

import parsec.arg;
import parsec.postparse;
import parsec.parser.base;
import parsec.parser.toplevel;
import parsec.parser.errors;
import parsec.parser.parser;
import parsec.lex.source;
import parsec.lex.lexer;
import ir = parsec.ir.ir;

import vls.lsp;
import vls.server.responses;

// version = VlsLog;

class VoltLanguageServer
{
public:
	logf: OutputFileStream;
	settings: Settings;

public:
	this(argZero: string)
	{
		settings = new Settings(argZero, getExecDir());
		settings.warningsEnabled = false;
		// TODO: Set internalD to true if the current file ends in .d.

		version (VlsLog) {
			version (Windows) {
				env := retrieveEnvironment();
				logf = new OutputFileStream(env.getOrNull("USERPROFILE") ~ "/Desktop/vlslog.txt");
			} else {
				logf = new OutputFileStream("/tmp/vlslog.txt");
			}
		} else {
			logf = null;
		}
	}

	/// LSP listen callback.
	fn handle(msg: LspMessage) bool
	{
		version (VlsLog) {
			logf.writefln("MESSAGE: \"%s\"\n", msg.content);
			logf.flush();
		}
		return handleRO(new RequestObject(msg.content));
	}

private:
	fn handleRO(ro: RequestObject) bool
	{
		switch (ro.methodName) {
		case "initialize":
			send(responseInitialized(ro), logf);
			return CONTINUE_LISTENING;
		case "initialized":
			assert(ro.notification);
			return CONTINUE_LISTENING;
		case "shutdown":
			retval = 0;
			send(responseShutdown(ro), logf);
			return CONTINUE_LISTENING;
		case "exit":
			return STOP_LISTENING;
		case "textDocument/documentLink":
		case "textDocument/codeLens":
			// For now, just parse the file so the client sees diagnostics.
			uri: string;
			handleTextDocument(ro, out uri);
			return CONTINUE_LISTENING;
		case "workspace/didChangeWatchedFiles":
			parseChangedFiles(ro);
			return CONTINUE_LISTENING;
		case "textDocument/documentSymbol":
			uri: string;
			mod := handleTextDocument(ro, out uri);
			if (mod is null) {
				return CONTINUE_LISTENING;
			}
			reply := responseSymbolInformation(ro, uri, mod);
			send(reply, logf);
			return CONTINUE_LISTENING;
		default:
			// TODO: Return error
			version (VlsLog) {
				logf.writefln("Unknown method: %s", ro.methodName);
				logf.flush();
			}
			return CONTINUE_LISTENING;
		}
		assert(false);
	}

	// Given a RequestObject with DidChangeWatchedFilesParams, parse any that weren't deleted.
	fn parseChangedFiles(ro: RequestObject)
	{
		uris: string[];
		parseDidChangeWatchedFiles(ro.params, out uris);
		foreach (uri; uris) {
			parse(uri);
		}
	}

	// Parse out a TextDocument from params, and run parse for the uri. Returns null on error.
	fn handleTextDocument(ro: RequestObject, out uri: string) ir.Module
	{
		err := parseTextDocument(ro.params, out uri);  // vls.lsp.requests
		if (err !is null) {
			version (VlsLog) {
				logf.writefln("SENDING ERROR");
				logf.flush();
			}
			send(responseError(ro, err), logf);
			return null;
		}
		return parse(uri);
	}

	fn parse(uri: string) ir.Module
	{
		// TEMPORARY
		version (Windows) {
			filepath := uri["file:///".length .. $];
			filepath = filepath.replace("%3A", ":");
		} else {
			filepath := uri["file://".length .. $];
		}
		src := new Source(cast(string)read(filepath), filepath);
		mod: ir.Module;
		ps := new ParserStream(lex(src), settings);
		ps.get();  // Skip begin
		status := parseModule(ps, out mod);
		if (status != ParseStatus.Succeeded && ps.parserErrors.length >= 1) {
			err := ps.parserErrors[0];
			send(notificationDiagnostic(uri, err.loc, err.errorMessage()), logf);
		} else {
			send(notificationNoDiagnostic(uri), logf);
		}
		version (VlsLog) logf.flush();
		postParse(mod);
		return mod;
	}

	fn log(s: string)
	{
		version (VlsLog) {
			logf.writefln(s);
			logf.flush();
		}
	}
}
