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
package xmpp;

class MUCOwner {
	
	public static var XMLNS = xmpp.MUC.XMLNS+"#owner";
	
	public var items : List<xmpp.muc.Item>;
	//public var destroy : xmpp.muc.Destroy;
	//public var empty : String;
	
	public function new() {
		items = new List();
	}
	
	public function toXml() : Xml {
		var x = xmpp.IQ.createQueryXml( XMLNS );
		for( item in items ) {
			x.addChild( item.toXml() );
		}
		//if( destroy != null ) x.addChild( destroy.toXml() );
		//empty
		return x;
	}
	
	public inline function toString() : String {
		return toXml().toString();
	}
	
}
