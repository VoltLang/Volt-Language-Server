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
	containerName: string;

	fn jsonString(uri: string) string
	{
		return format(`{ "name": "%s", "kind": %s, "location": %s %s }`,
			name, type, locationToJsonString(loc, uri),
			containerName.length > 0 ? format(`, "containerName": "%s"`, containerName) : "");
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

private:
	parents: string[];

public:
	override fn enter(func: ir.Function) Status
	{
		if (func.type.isProperty) {
			addSymbol(func, func.name, SYMBOL_PROPERTY);
		} else {
			addSymbol(func, func.name, func.kind == ir.Function.Kind.Member ? SYMBOL_METHOD : SYMBOL_FUNCTION);
		}
		return Status.Continue;
	}

	override fn enter(strct: ir.Struct) Status
	{
		addSymbol(strct, strct.name, SYMBOL_CLASS);
		parents ~= strct.name;
		return Status.Continue;
	}

	override fn leave(strct: ir.Struct) Status
	{
		assert(parents.length > 0);
		parents = parents[0 .. $-1];
		return Status.Continue;
	}

	override fn enter(clss: ir.Class) Status
	{
		addSymbol(clss, clss.name, SYMBOL_CLASS);
		parents ~= clss.name;
		return Status.Continue;
	}

	override fn leave(clss: ir.Class) Status
	{
		assert(parents.length > 0);
		parents = parents[0 .. $-1];
		return Status.Continue;
	}

private:
	fn addSymbol(node: ir.Node, name: string, type: i32)
	{
		sym: Symbol;
		sym.name = name;
		if (parents.length > 0) {
			sym.containerName = parents[$-1];
		}
		sym.loc = node.location;
		sym.type = type;
		symbols ~= sym;
	}
}
