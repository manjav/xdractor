import haxe.Json;
import haxe.io.Bytes;
import sys.io.File;
import sys.FileSystem;
import haxe.zip.Entry;
import haxe.zip.Reader;
import haxe.Timer;

class Positions
{
	static var _source:String = "positions.xd";
	static var positions:Map<Int, Array<Int>>;
	static function main()
	{
		// receive args
		var args = Sys.args();
		for( i  in 0...args.length )
		{
			if( args[i].substring(0, 1) != "-" )
				continue;
			if( args[i] == "-src" ) _source				= args[i + 1];
			// if( args[i] == "-dst" ) _destination	= args[i + 1];
		}

		var now = Timer.stamp();
		positions = new Map<Int, Array<Int>>();

		// load xd file
		var input = sys.io.File.read(_source);
		var entries = new Reader(input).read();
		input.close();

		// manifest reaading
		for (e in entries)
		{
			if( e.fileName != "manifest" )
				continue;
			var data = Reader.unzip(e);
			var children:Array<Dynamic> = Json.parse(data.getString(0,data.length)).children;
			for (c in children)
			{
				if( c.name == "artwork" )
				{
					var artworks:Array<Dynamic> = c.children;
					for (a in artworks)
						if( a.name != "pasteboard" )
							setPosition(a.name, "artwork/" + a.path + "/graphics/graphicContent.agc", entries);
				}
			}
		}
		var p = positions;
		trace(p[0][0]+","+p[0][1]+","+p[45][0]+","+p[45][1]+","+p[90][0]+","+p[90][1]+","+p[135][0]+","+p[135][1]+","+p[180][0]+","+p[180][1] );
		// trace(Timer.stamp()*1000 - now*1000 + " ms.\nSource:" + positions);
	}

	static function setPosition(name:String, path:String, entries:List<Entry>):Void
	{
		for (e in entries)
		{
			if( e.fileName != path )
				continue;
			var data = Reader.unzip(e);
			var children:Array<Dynamic> = Json.parse(data.getString(0, data.length)).children[0].artboard.children;
			for (c in children)
				if( c.name == "point" )
					positions[Std.parseInt(name)] = [Math.floor(c.meta.ux.localTransform.tx) + c.shape.r, Math.floor(c.meta.ux.localTransform.ty) + c.shape.r];
		}
	}
}
