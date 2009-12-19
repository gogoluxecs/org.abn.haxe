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
package jabber.stream;

import xmpp.PacketFilter;

/**
	Mind! packet timeouts dont't work for PHP!
*/
class PacketCollector {
	
	/** */
	public var filters(default,null) : FilterList;
	/** Callbacks to which collected packets get delivered to. */
	public var handlers : Array<xmpp.Packet->Void>;
	/** Indicates if the the collector should get removed from the stream after collecting. */
	public var permanent : Bool;
	/** Block remaining collectors */
	public var block : Bool; //TODO remove
	/** */
	public var timeout(default,setTimeout) : PacketTimeout;
	
	public function new( filters : Iterable<PacketFilter>,
						 handler : Dynamic->Void,
						 ?permanent : Bool = false,
						 ?timeout : PacketTimeout,
						 ?block : Bool = false ) {
		handlers = new Array();
		this.filters = new FilterList();
		for( f in filters )
			this.filters.push( f );
		if( handler != null )
			handlers.push( handler );
		this.permanent = permanent;
		this.block = block;
		this.setTimeout( timeout );
	}

	function setTimeout( t : PacketTimeout ) : PacketTimeout {
		if( timeout != null ) timeout.stop();
		timeout = null;
		if( t == null || permanent ) return null;
		timeout = t;
		timeout.collector = this;
		return timeout;
	}
	
	/**
		Returns Bool if the XMPP packet passes through all filters.
	*/
	public function accept( p : xmpp.Packet ) : Bool {
		for( f in filters ) {
			if( !f.accept( p ) )
				return false;
		}
		if( timeout != null )
			timeout.stop();
		return true;
	}
	
	/**
		Delivers the given packet to all registerd handlers.
	*/
	public function deliver( p : xmpp.Packet ) {
		for( h in handlers ) { h( p ); }
	}

}
