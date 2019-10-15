import haxe.io.Bytes;
import sys.io.File;
import sys.FileSystem;
import haxe.format.JsonParser;
import haxe.zip.Entry;
import haxe.zip.Reader;
import haxe.Timer;

class XDractor
{
	static var _source:String = "test.xd";
	static var _destination:String = null;
	static function main()
	{
		// receive args
		var args = Sys.args();
		for( i  in 0...args.length )
		{
			if( args[i].substring(0, 1) != "-" )
				continue;
			if( args[i] == "-src" ) _source				= args[i + 1];
			if( args[i] == "-dst" ) _destination	= args[i + 1];
		}
		if( _destination == null )
			_destination = _source.split(".")[0];

		var now = Timer.stamp();

		// load xd file
		var input = sys.io.File.read(_source);
		var entries = new Reader(input).read();
		input.close();

		// remove last exports
		deleteDirRecursively(_destination);
		FileSystem.createDirectory(_destination);

		// manifest reaading
		var files = readManifest(entries);
		var exports = getExports(entries, files);
		for (key => value in files)
			for (e in entries)
				if( e.fileName == value )
						save(e, key, exports);
		
		trace(Timer.stamp()*1000 - now*1000 + " ms.\nSource:" + _source  + " Destination:" + _destination );
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
							ret.set(a.name + ".json", "artwork/" + a.path + "/graphics/graphicContent.agc");
				}
				else if( c.name == "resources" )
				{
					var resources:Array<Dynamic> = c.components;
					for (r in resources)
						if( r.type == "image/png" )
							ret.set( r.path + ".png", "resources/" + r.path);
				}
			}
		}
		return ret;
	}

	static function getExports(entries:List<Entry>, files:Map<String, String>):Map<String, Bool>
	{
		var exports = new Map<String, Bool>();
		for (key => value in files)
		if( value.substr(value.lastIndexOf(".")) == ".agc" )
		for (e in entries)
		if( e.fileName == value )
		{
			var b:Bytes = Reader.unzip(e);
			var json = JsonParser.parse(b.getString(0, b.length));
			var children:Array<Dynamic> = json.children[0].artboard.children;
			for( c in children )
				loadChild(exports, c);
		}
		return exports;
	}

	static function loadChild(exports:Map<String, Bool>, c:Dynamic)
	{
		if( c.type == "group" )
		{
			var children:Array<Dynamic> = c.group.children;
			for( c in children )
				loadChild(exports, c);
			return;
		}
		if( c.style.fill.type == "pattern" )
			exports.set(c.style.fill.pattern.meta.ux.uid, c.meta.ux.markedForExport!=null?true:false);
			// trace(c.name, c.style.fill.pattern.meta.ux.uid, c.meta.ux.markedForExport!=null?true:false);
	}

	static function save (e:Entry, path:String, exports:Map<String, Bool>):Void
	{
		// decompress compressed files
		var data = e.compressed ? Reader.unzip(e) : e.data;
		// create images folder
		var name:Array<String> = path.split(".");
		var folder:String = "/";
		if( name[1] == "png" || name[1] == "jpg" )
		{
			folder = "/images/";
			// trace(name, exports.exists(name[0]));
			if( !exports.exists(name[0]) || !exports.get(name[0]) )
				return;
		}
		if( !FileSystem.exists(_destination + folder) )
			FileSystem.createDirectory(_destination + folder);
		File.saveBytes(_destination + folder + path, data);
	}

	static function deleteDirRecursively(path:String) : Void
	{
		if( sys.FileSystem.exists(path) && sys.FileSystem.isDirectory(path) )
		{
			var entries = sys.FileSystem.readDirectory(path);
			for( entry in entries )
			{
				if( sys.FileSystem.isDirectory(path + '/' + entry) )
				{
					deleteDirRecursively(path + '/' + entry);
					sys.FileSystem.deleteDirectory(path + '/' + entry);
				}
				else
				{
					sys.FileSystem.deleteFile(path + '/' + entry);
				}
			}
		}
	}
}
