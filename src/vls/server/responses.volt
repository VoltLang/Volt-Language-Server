module vls.server.responses;

import watt.conv;
import watt.text.string;
import watt.text.format;
import watt.text.json.rpc;

import vls.lsp.constants;

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
							"includeText": false
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
					"documentSymbolProvider": false,
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

private:

fn compress(s: string) string
{
	return s.replace("\n", " ");
}