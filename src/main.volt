module main;

import lsp = vls.lsp;
import vls.server;

global retval: i32 = 1;

fn main(args: string[]) i32
{
	server := new VoltLanguageServer(args[0]);
	scope (exit) server.logf.close();
	while (lsp.listen(server.handle)) {
	}
	return retval;
}
