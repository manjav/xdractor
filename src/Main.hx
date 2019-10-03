import sys.io.File;
import sys.FileSystem;
import haxe.format.JsonParser;
import haxe.zip.Entry;
import haxe.zip.Reader;
import haxe.Timer;

class Main
{
	static var _source:String = "test.xd";
	static var _destination:String = "export";
	static function main()
	{
		// receive args
		var args = Sys.args();
		for( i  in 0...args.length )
		{
			if( args[i].substring(0, 1) != "-" )
				continue;
			switch( args[i] )
			{
				case "-src":	_source = args[i + 1];			break;
				case "-dst":  _destination = args[i + 1];	break;
			}
		}

		var now = Timer.stamp();

		// load xd file
		var input = sys.io.File.read(_source);
		var entries = new Reader(input).read();
		input.close();

		// manifest reaading
		var files = readManifest(entries);
		for (key => value in files)
			for (e in entries)
				if( e.fileName == value )
						save(e, key);
		
		trace(Timer.stamp() - now);
	}
	static function readManifest(entries:List<Entry>):Map<String, String>
	{
		var ret = new Map<String, String>();
		for (e in entries)
		{
			if( e.fileName != "manifest" )
				continue;
			var data = Reader.unzip(e);
			var json = JsonParser.parse(data.getString(0,data.length));
			var children:Array<Dynamic> = json.children;
			for (c in children)
			{
				if( c.name == "artwork" )
				{
					var artworks:Array<Dynamic> = c.children;
					for (a in artworks)
						if( a.name != "pasteboard" )
							ret.set(_destination + "/" + a.name + ".json", "artwork/" + a.path + "/graphics/graphicContent.agc");
				}
				else if( c.name == "resources" )
				{
					var resources:Array<Dynamic> = c.components;
					for (r in resources)
						if( r.type == "image/png" )
							ret.set( _destination + "/images/" + r.path + ".png", "resources/" + r.path);
				}
			}
		}
		return ret;
	}

	static function save (e:Entry, path:String):Void
	{
		// decompress compressed files
		var data = e.compressed ? Reader.unzip(e) : e.data;
		
		// create folders
		if( !FileSystem.exists(_destination) )
			FileSystem.createDirectory(_destination);
		if( path.indexOf("images/") > -1 && !FileSystem.exists(_destination + "/images") )
			FileSystem.createDirectory(_destination +  "/images");
		File.saveBytes(path, data);
	}
}
