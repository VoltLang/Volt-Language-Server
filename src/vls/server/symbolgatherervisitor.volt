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
	override fn enter(mod: ir.Module) Status
	{
		addSymbol(mod, mod.name.toString(), SYMBOL_MODULE);
		return Status.Continue;
	}

	override fn enter(func: ir.Function) Status
	{
		kind: i32;
		name := func.name;
		switch (func.kind) with (ir.Function.Kind) {
		case Member:
			kind = SYMBOL_METHOD;
			break;
		case Constructor:
			kind = SYMBOL_CONSTRUCTOR;
			name = "this";
			break;
		case Destructor:
			name = "~this";
			kind = SYMBOL_FUNCTION;
			break;
		default:
			if (func.type.isProperty) {
				kind = SYMBOL_PROPERTY;
			} else {
				kind = SYMBOL_FUNCTION;
			}
			break;
		}
		addSymbol(func, name, kind);
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

	override fn enter(intrfc: ir._Interface) Status
	{
		addSymbol(intrfc, intrfc.name, SYMBOL_INTERFACE);
		parents ~= intrfc.name;
		return Status.Continue;
	}

	override fn leave(intrfc: ir._Interface) Status
	{
		assert(parents.length > 0);
		parents = parents[0 .. $-1];
		return Status.Continue;
	}

	override fn enter(var: ir.Variable) Status
	{
		kind: i32;
		switch (var.storage) with (ir.Variable.Storage) {
		case Field:
			kind = SYMBOL_FIELD;
			break;
		case Global:
		case Local:
			kind = SYMBOL_VARIABLE;
			break;
		default:
			return Status.Continue;
		}
		addSymbol(var, var.name, kind);
		return Status.Continue;
	}

	override fn enter(enm: ir.EnumDeclaration) Status
	{
		addSymbol(enm, enm.name, SYMBOL_ENUM);
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
