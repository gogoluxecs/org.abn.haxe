package net.php;

import php.net.Host;

/**
	Patched version of php.net.Socket to be able to specify 'tls' as transport.
*/
class Socket extends php.net.Socket {
	
	public function connectTLS( host : Host, port : Int ) {
		var errs = null;
		var errn = null;
		var r = untyped __call__('stream_socket_client', 'tls://'+host._ip+':'+port, errn, errs );
		checkError( r, errn, errs );
		__s = cast r;
		assignHandler();
	}
	
	private static function checkError(r : Bool, code : Int, msg : String) {
		if(!untyped __physeq__(r, false)) return;
		throw haxe.io.Error.Custom('Error ['+code+']: ' +msg);
	}
	
}
