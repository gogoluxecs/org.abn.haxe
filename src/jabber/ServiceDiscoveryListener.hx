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

import jabber.stream.PacketCollector;
import xmpp.filter.IQFilter;

/**
	Listens/Answers incoming service discovery requests.
	<a href="http://www.xmpp.org/extensions/xep-0030.html">XEP 30 - ServiceDiscovery</a>
*/
class ServiceDiscoveryListener {
	
	public var stream(default,null) : Stream;
	public var identities : Array<xmpp.disco.Identity>;
	
	public function new( stream : Stream,  ?identities : Array<xmpp.disco.Identity> ) {
		if( !stream.features.add( xmpp.disco.Info.XMLNS ) ||
			!stream.features.add( xmpp.disco.Items.XMLNS ) )
			throw "ServiceDiscovery listeners already added";
		this.stream = stream;
		this.identities = identities;
		stream.collect( [cast new IQFilter( xmpp.disco.Info.XMLNS, null, xmpp.IQType.get )], handleInfoQuery, true );
		stream.collect( [cast new IQFilter( xmpp.disco.Items.XMLNS, null, xmpp.IQType.get )], handleItemsQuery, true );
	}

	function handleInfoQuery( iq : xmpp.IQ ) { // return identities and stream features
		var r = new xmpp.IQ( xmpp.IQType.result, iq.id, iq.from, stream.jidstr );
		r.x = new xmpp.disco.Info( identities, Lambda.array( stream.features ) );
		stream.sendData( r.toString() );
	}
	
	function handleItemsQuery( iq : xmpp.IQ ) {
		var r : xmpp.IQ;
		// HACK
		if( Reflect.hasField( stream, "items" ) ) { // component stream .. return local stream items
			r = new xmpp.IQ( xmpp.IQType.result, iq.id, iq.from, Reflect.field( stream, "serviceName" ) );
			r.x = Reflect.field( stream, "items" );
		} else { // client streams do not have items .. return a feature-not-implemented error
			//???
			r = new xmpp.IQ( xmpp.IQType.error, iq.id, iq.from );
			r.errors.push( new xmpp.Error( xmpp.ErrorType.cancel, -1, xmpp.ErrorCondition.FEATURE_NOT_IMPLEMENTED ) );
		}
		r.from = stream.jidstr;
		stream.sendPacket( r );
	}
	
}
