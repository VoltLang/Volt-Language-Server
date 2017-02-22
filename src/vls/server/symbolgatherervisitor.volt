module vls.server.symbolgatherervisitor;

import watt.text.format;

import ir = parsec.ir.ir;

import parsec.visitor.visitor;
import parsec.lex.location;

import vls.lsp.constants;

struct Symbol
{
	name: string;
	loc: Location;
	type: i32;  //< See the SYMBOL_ enums in vls.lsp.constants.

	fn jsonString(uri: string) string
	{
		return format(`{ "name": "%s", "kind": %s, "location": %s }`,
			name, type, locationToJsonString(loc, uri));
	}
}

fn locationToJsonString(loc: Location, uri: string) string
{
	return format(`{ "uri": "%s", "range": %s }`, uri, locationToRange(loc));
}

fn locationToRange(loc: Location) string
{
	endLoc := loc;
	endLoc.column += loc.length;
	return format(`{ "start": %s, "end": %s }`, locationToPosition(loc), locationToPosition(endLoc));
}

fn locationToPosition(loc: Location) string
{
	return format(`{ "line": %s, "character": %s }`, loc.line - 1, loc.column - 1);
}

class SymbolGathererVisitor : NullVisitor
{
public:
	symbols: Symbol[];

public:
	override fn enter(func: ir.Function) Status
	{
		sym: Symbol;
		sym.name = func.name;
		sym.loc = func.location;
		sym.type = SYMBOL_FUNCTION;
		symbols ~= sym;
		return Status.Continue;
	}
}
