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

		var input = sys.io.File.read(_source);
		var entries = new Reader(input).read();
		input.close();

		var files = readManifest(entries);
		
		trace(Timer.stamp() - now, files);
	}
	static function readManifest(entries:List<Entry>):Map<String, String>
	{
		var ret = new Map<String, String>();
		for (e in entries)
		{
			if( e.fileName == "manifest" )
			{
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
		}
		return ret;
	}
}
