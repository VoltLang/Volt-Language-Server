module vls.server.responses;

import watt.conv;
import watt.text.string;
import watt.text.format;
import watt.text.json.rpc;

import parsec.lex.location;
import ir = parsec.ir.ir;
import parsec.visitor.visitor : accept;

import vls.lsp;
import vls.server.symbolgatherervisitor;

fn responseInitialized(ro: RequestObject) string
{
	msg := format(`
		{
			"id": %s,
			"result": {
				"capabilities": {
					"textDocumentSync": {
						"openClose": true,
						"change": 1,
						"willSave": false,
						"willSaveWaitUntil": false,
						"save": {
							"includeText": true
						}
					},
					"hoverProvider": false,
					"completionProvider": {
						"resolveProvider": false,
						"triggerCharacters": []
					},
					"signatureHelpProvider": {
						"triggerCharacters": []
					},
					"definitionProvider": false,
					"referencesProvider": false,
					"documentHighlightProvider": false,
					"documentSymbolProvider": true,
					"workspaceSymbolProvider": false,
					"codeActionProvider": false,
					"codeLensProvider": {
						"resolveProvider": false
					},
					"documentFormattingProvider": false,
					"documentRangeFormattingProvider": false,
					"documentOnTypeFormattingProvider": {
						"firstTriggerCharacter": "",
						"moreTriggerCharacters": []
					},
					"renameProvider": false,
					"documentLinkProvider": {
						"resolveProvider": false
					},
					"executeCommandProvider": {
						"commands": []
					}
				}
			}
		}
	`, toString(ro.id.integer()));
	return compress(msg);
}

fn responseError(ro: RequestObject, err: Error) string
{
	msg := format(`
		{
			"id": %s,
			"error": {
				"code": %s,
				"message": %s
			}
		}
	`, toString(ro.id.integer()), err.code, err.message);
	return compress(msg);
}

fn responseShutdown(ro: RequestObject) string
{
	msg := format(`
		{
			"id":%s,
			"result": {
			}
		}
	`, toString(ro.id.integer()));
	return compress(msg);
}

fn responseSymbolInformation(ro: RequestObject, uri: string, mod: ir.Module) string
{
	sgv := new SymbolGathererVisitor();
	msg := format(`{ "id":%s, "result": [`, toString(ro.id.integer()));
	accept(mod, sgv);
	foreach (i, symbol; sgv.symbols) {
		msg ~= symbol.jsonString(uri);
		if (i < sgv.symbols.length - 1) {
			msg ~= ", ";
		}
	}
	msg ~= "]}";
	return msg;
}

fn notificationDiagnostic(uri: string, loc: Location, errmsg: string) string
{
	msg := format(`{
		"jsonrpc": "2.0",
		"method": "textDocument/publishDiagnostics",
		"params": {
			"uri": "%s",
			"diagnostics": [{
				"range": %s,
				"severity": %s,
				"message": "%s"
			}]
		}
	}`, uri, locationToRange(loc), DIAGNOSTIC_ERROR, errmsg);
	return compress(msg);
}

fn notificationNoDiagnostic(uri: string) string
{
		msg := format(`{
		"jsonrpc": "2.0",
		"method": "textDocument/publishDiagnostics",
		"params": {
			"uri": "%s",
			"diagnostics": []
		}
	}`, uri);
	return compress(msg);
}

private:

fn compress(s: string) string
{
	return s.replace("\n", " ");
}