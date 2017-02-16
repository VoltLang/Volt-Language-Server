module main;

import lsp = vls.lsp;
import vls.server;

fn main(args: string[]) i32
{
	server := new VoltLanguageServer();
	scope (exit) server.logf.close();
	while (lsp.listen(server.handle)) {
	}
	return 0;
}
