class Main
{
	static var _source:String = "map.xd";
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
		trace(args);
	}
}
