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
package jabber.remoting;

import haxe.remoting.Context;

/**
	haXe/XMPP remoting host.<br/>
	<a href="http://haxe.org/doc/remoting">haXe-remoting</a>
*/
class Host {

	/** Current/Last calling client JID */
	public var client(default,null) : String;
	public var ctx : Context;
	public var stream(default,null) : jabber.Stream;

	public function new( stream : jabber.Stream, ctx : Context ) {
		this.stream = stream;
		this.ctx = ctx;
		stream.features.add( xmpp.HXR.XMLNS );
		stream.collect( [cast new xmpp.filter.IQFilter( xmpp.HXR.XMLNS, null, xmpp.IQType.get )], handleIQ, true );
	}
	
	function handleIQ( iq : xmpp.IQ ) {
		client = iq.from;
		var request = xmpp.HXR.getData( iq.x.toXml() );
		var response = processRequest( request, ctx );
		var r = xmpp.IQ.createResult( iq );
		//TODO send empty result IQ (void)
		r.properties.push( xmpp.HXR.create( response ) );
		stream.sendPacket( r );
		/*
		//TODO check error settings
		var r = xmpp.IQ.createErrorResult( iq, [new xmpp.Error(xmpp.ErrorType.modify,null,xmpp.ErrorCondition.NOT_ACCEPTABLE)] );
		stream.sendPacket( r );
		*/
	}
	
	/**
	*/
	public static function processRequest( data : String, ctx : Context ) : String {
		try {
			var u = new haxe.Unserializer( data );
			var path = u.unserialize();
			//trace(path);
			var args = u.unserialize();
			//trace(args);
			var d = ctx.call( path, args );
			var s = new haxe.Serializer();
			s.serialize( d );
			return "hxr"+s.toString();
		} catch( e : Dynamic ) {
			var s = new haxe.Serializer();
			s.serializeException( e );
			return "hxr"+s.toString();
		}
	}
	
}
