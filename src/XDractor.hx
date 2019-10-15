import haxe.Json;
import haxe.io.Bytes;
import sys.io.File;
import sys.FileSystem;
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

		// manifest reaading
		var resources = readManifest(entries);
		var exports = getExports(entries, resources);
		save(exports);
		
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
			var json = Json.parse(data.getString(0,data.length));
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

	static function getExports(entries:List<Entry>, resources:Map<String, String>):Map<String, Bytes>
	{
		var exports = new Map<String, Bytes>();
		for (key => value in resources)
		if( value.substr(value.lastIndexOf(".")) == ".agc" )
		for (e in entries)
		if( e.fileName == value )
		{
			var jx = {children:[{artboard:{children:[]}}]};
			var b:Bytes = Reader.unzip(e);
			var jring = b.getString(0, b.length);
			var json = Json.parse(jring);
			var children:Array<Dynamic> = json.children[0].artboard.children;
			for( c in children )
				loadChild(entries, exports, c, children);

			exports.set(key, Bytes.ofString(Json.stringify(json)));
		}
		return exports;
	}

	static function loadChild(entries:List<Entry>, exports:Map<String, Bytes>, c:Dynamic, childs:Array<Dynamic>)
	{
		if( c.meta.ux.markedForExport == null )
		{
			childs.remove(c);
			return;
		}

		if( c.type == "group" )
		{
			var children:Array<Dynamic> = c.group.children;
			for( c in children )
				loadChild(entries, exports, c, children);
			return;
		}
		if( c.style.fill.type == "pattern" )
			exports.set(c.style.fill.pattern.meta.ux.uid + ".png", getEntry(entries, "resources/" + c.style.fill.pattern.meta.ux.uid).data);
			// trace(c.name, c.style.fill.pattern.meta.ux.uid, c.meta.ux.markedForExport!=null?true:false);
	}

	static function getEntry(entries:List<Entry>, name:String):Entry
	{
		for( e in entries )
			if( e.fileName == name )
				return e;
		return null;
	}

	static function save (exports:Map<String, Bytes>):Void
	{
		// renew last exports
		deleteDirRecursively(_destination);
		FileSystem.createDirectory(_destination);

		for (key => value in exports)
		{
			var name:Array<String> = key.split(".");
			var folder:String = "/";
			if( name[1] == "png" || name[1] == "jpg" )
				folder = "/images/";

			// create images folder
			if( !FileSystem.exists(_destination + folder) )
				FileSystem.createDirectory(_destination + folder);
			File.saveBytes(_destination + folder + key, value);
		}
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
