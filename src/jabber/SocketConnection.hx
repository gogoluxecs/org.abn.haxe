/*
 *	This file is part of HXMPP.
 *	Copyright (c)2009 http://www.disktree.net
 *	
 *	HXMPP is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  HXMPP is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *	See the GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with HXMPP. If not, see <http://www.gnu.org/licenses/>.
*/
package jabber;

#if flash9
import flash.net.Socket;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.events.ProgressEvent;
import flash.utils.ByteArray;
#elseif neko
import neko.net.Host;
import neko.net.Socket;
#elseif php
import php.net.Host;
import net.php.Socket;
#elseif cpp
import cpp.net.Host;
import cpp.net.Socket;
#end

/**
	TODO
	- php!
	- flash/js maxBufSize
	- split outgoing (big) packets ?
*/
class SocketConnection extends jabber.stream.Connection {
	
	#if (neko||php||cpp)
	public static var defaultBufSize = (1<<8); // 128
	#end
	
	public var port(default,null) : Int;
	public var socket(default,null) : Socket;
	public var secure(default,null) : Bool; //TODO move to jabber.socket.Connection
	public var timeout(default,null) : Int;
	public var maxBufSize(default,null) : Int;
	
	#if (neko||php||cpp)
	var reading : Bool;
	var buf : haxe.io.Bytes;
	var bufbytes : Int;
	#elseif (JABBER_SOCKETBRIDGE)
	var buf : String;
	#elseif flash
	var buf : ByteArray;
	#end
	
	public function new( host : String,
						 ?port : Int,
						 ?secure : Bool = false ,
						 ?timeout : Int = 10,
						 ?maxBufSize : Int = 131072 ) {
		if( port == null )
			port = 5222;
		super( host );
		this.port = port;
		#if (flash10||neko||php||cpp)
		this.timeout = timeout;
		#end
		this.secure = secure;
		this.maxBufSize = maxBufSize;
		
		socket = new Socket();
		
		#if flash9
		buf = new ByteArray();
		socket.addEventListener( Event.CONNECT, sockConnectHandler );
		socket.addEventListener( Event.CLOSE, sockDisconnectHandler );
		socket.addEventListener( IOErrorEvent.IO_ERROR, sockErrorHandler );
		socket.addEventListener( SecurityErrorEvent.SECURITY_ERROR, sockErrorHandler );
	
		#elseif (neko||cpp)
		socket = new Socket();
		buf = haxe.io.Bytes.alloc( defaultBufSize );
		bufbytes = 0;
		reading = false;
		
		#elseif php
		buf = haxe.io.Bytes.alloc( maxBufSize ); //TODO ! WTF !!!
		bufbytes = 0;
		reading = false;
		
		#elseif JABBER_SOCKETBRIDGE
		buf = "";
		socket.onConnect = sockConnectHandler;
		socket.onDisconnect = sockDisconnectHandler;
		socket.onError = sockErrorHandler;
		#end
	}
	
	/*
	function setTimeout( t : Int ) : Int {
		return timeout = ( t <= 0 ) ? 1 : t;
	}

	function setMaxBufSize( t : Int ) : Int {
		return timeout = ( t <= 0 ) ? 1 : t;
	}
	*/
	
	public override function connect() {
		#if (neko||cpp)
		socket.connect( new Host( host ), port );
		#end
		#if php
		if( secure ) socket.connectTLS( new Host( host ), port )
		else socket.connect( new Host( host ), port );
		#end
		#if (neko||php||cpp)
		connected = true;
		__onConnect();
		#else
		#if flash10
		socket.timeout = timeout*1000;
		#end
		socket.connect( host, port );
		#end
	}
	
	public override function disconnect() {
		if( !connected ) return;
		#if (neko||php||cpp) reading = false; #end
		connected = #if (neko||php||cpp) reading = #end false;
		socket.close();
	}
	
	public override function read( ?yes : Bool = true ) : Bool {
		if( yes ) {
			#if flash9
			socket.addEventListener( ProgressEvent.SOCKET_DATA, sockDataHandler );
			#elseif (neko||php||cpp)
			reading = true;
			while( reading  && connected ) {
				readData();
				processData();
			}
			#elseif JABBER_SOCKETBRIDGE
			socket.onData = sockDataHandler;
			#end
		} else {
			#if flash9
			socket.removeEventListener( ProgressEvent.SOCKET_DATA, sockDataHandler );
			#elseif (neko||php||cpp)
			reading = false;
			#elseif JABBER_SOCKETBRIDGE
			socket.onData = null;
			#end
		}
		return true;
	}
	
	public override function write( t : String ) : Bool {
		if( !connected || t == null || t.length == 0 )
			return false;
		#if flash9
		socket.writeUTFBytes( t ); 
		socket.flush();
		#elseif (neko||php||cpp)
		socket.output.writeString( t );
		socket.output.flush();
		#elseif JABBER_SOCKETBRIDGE
		socket.send( t );
		#end
		return true;
	}

	/*
	public function clearBuffer() {
		#if (neko||php)
		buf = haxe.io.Bytes.alloc( DEFAULT_BUFSIZE );
		bufbytes = 0;
		#end
	}
	*/


	#if (flash)

	function sockConnectHandler( e : Event ) {
		connected = true;
		onConnect();
	}

	function sockDisconnectHandler( e : Event ) {
		connected = false;
		onDisconnect();
	}
	
	function sockErrorHandler( e ) {
		connected = false;
		onError( e );
	}
	
	function sockDataHandler( e : ProgressEvent ) {
		socket.readBytes( buf, buf.length, e.bytesLoaded);
		var b = haxe.io.Bytes.ofData( buf );
		if( b.length > maxBufSize )
			throw "Max buffer size reached ("+maxBufSize+")";
		if( onData(  b, 0, b.length ) > 0 )
			buf = new flash.utils.ByteArray();
	}
	
	#elseif (neko||php||cpp)
	
	function readData() {
		var buflen = buf.length;
		if( bufbytes == buflen ) { // eventually double the buffer size
			var nsize = buflen*2;
			if( nsize > maxBufSize ) {
				if( buflen == maxBufSize  )
					throw "Max buffer size reached ("+maxBufSize+")";
				nsize = maxBufSize;
			}
			var buf2 = haxe.io.Bytes.alloc( nsize );
			buf2.blit( 0, buf, 0, buflen );
			buflen = nsize;
			buf = buf2;
		}
			
		var nbytes = 0;
	//	try { 
			//trace(buf.length+"//"+buflen+"//"+bufbytes);
			nbytes = socket.input.readBytes( buf, bufbytes, buflen-bufbytes );
			//trace(nbytes);
	//	} catch(e:Dynamic){
	//		trace("ERRIR "+e);
	//		throw e;
	//	}
		bufbytes += nbytes;
	}
	
	function processData() {
		var pos = 0;
		while( bufbytes > 0 && reading ) {
			var nbytes = __onData( buf, pos, bufbytes ); //var nbytes = handleData( buffer, pos, bufbytes );
			if( nbytes == 0 ) {
				return;
			}
			/*
			if( nbytes == -1 ) {
				reading = false;
				disconnect();
				return;
			}
			*/
			pos += nbytes;
			bufbytes -= nbytes;
		}
		if( reading && pos > 0 )
			buf.blit( 0, buf, pos, bufbytes );
	}
	
	#elseif JABBER_SOCKETBRIDGE
	
	function sockConnectHandler() {
		connected = true;
		onConnect();
	}
	
	function sockDisconnectHandler() {
		connected = false;
		onDisconnect();
	}
	
	function sockErrorHandler( m : String ) {
		connected = false;
		onError( m );
	}
	
	function sockDataHandler( t : String ) {
		var i = buf + t;
		if( i.length > maxBufSize ) {
			#if JABBER_DEBUG trace( "Max socket buffer size reached ("+maxBufSize+")" ); #end
			throw "Max socket buffer size reached ("+maxBufSize+")";
		}
		buf = ( __onData( haxe.io.Bytes.ofString( i ), 0, i.length ) == 0 ) ? i : "";
	}
	
	#end
	
}


#if JABBER_SOCKETBRIDGE

/**
	Socket for socketbridge use.
*/
class Socket {
	
	public dynamic function onConnect() : Void;
	public dynamic function onDisconnect() : Void;
	public dynamic function onData( d : String ) : Void;
	public dynamic function onError( e : String ) : Void;
	
	public var id(default,null) : Int;
	//var timeout : Int;
	
	public function new() {
		var id : Int = SocketBridgeConnection.createSocket( this );
		if( id < 0 ) "Error creating socket";
		this.id = id;
	}
	
	public function connect( host : String, port : Int ) {
		untyped js.Lib.document.getElementById( SocketBridgeConnection.bridgeId ).connect( id, host, port );
	}
	
	public function close() {
		untyped js.Lib.document.getElementById( SocketBridgeConnection.bridgeId ).disconnect( id );
	}
	
	/*
	public function destroy() {
		var _s = untyped js.Lib.document.getElementById( SocketBridgeConnection.bridgeId ).destroy( id );
	}
	*/
	
	public function send( d : String ) {
		untyped js.Lib.document.getElementById( SocketBridgeConnection.bridgeId ).send( id, d );
	}
	
}

/**
*/
class SocketBridgeConnection {
	
	//public static var defaultBridgeId = "f9bridge";
	public static var defaultDelay = 300;
	public static var bridgeId(default,null) : String;
	
	static var sockets : IntHash<Socket>;
	static var initialized = false;
	
	public static function init( id : String ) {
		if( initialized )
			throw "Socketbridge already initialized";
		bridgeId = id;
		sockets = new IntHash();
		initialized = true;
	}
	
	public static function initDelayed( id : String, cb : Void->Void, ?delay : Int ) {
		if( delay == null || delay <= 0 ) delay = defaultDelay;
		init( id );
		haxe.Timer.delay( cb, delay );
	}
	
	
	public static function createSocket( s : Socket ) {
		var id : Int = untyped js.Lib.document.getElementById( bridgeId ).createSocket();
		sockets.set( id, s );
		return id;
	}
	
	/*
	public static function destroySocket( id : Int ) {
		var removed = untyped js.Lib.document.getElementById( bridgeId ).destroySocket( id );
		if( removed ) {
			var s =  sockets.get( id );
			sockets.remove( id );
			s = null;
		}
	}
	*/
	
	static function handleConnect( id : Int ) {
		var s = sockets.get( id );
		s.onConnect();
	}
	
	static function handleDisonnect( id : Int ) {
		var s = sockets.get( id );
		s.onDisconnect();
	}
	
	static function handleError( id : Int, e : String ) {
		var s = sockets.get( id );
		s.onError( e );
	}
	
	static function handleData( id : Int, d : String ) {
		var s = sockets.get( id );
		s.onData( d );
	}
	
}

#end // JABBER_SOCKETBRIDGE
