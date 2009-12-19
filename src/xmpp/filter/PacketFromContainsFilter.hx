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
package xmpp.filter;

/**
	Filters XMPP packets where the from attribute contains the given string.
*/
class PacketFromContainsFilter {
	
	public var contains(default,setContains) : String;
	
	var ereg : EReg;
	
	public function new( contains : String ) {
		setContains( contains );
	}
	
	function setContains( t : String ) : String {
		ereg = new EReg( t, "" );
		return this.contains = t;
	}
	
	public function accept( p : xmpp.Packet ) : Bool {
		if( p.from == null )
			return false;
		try {
			return ereg.match( p.from );
		} catch( e : Dynamic ) {
			return false;
		}
	}
	
}
