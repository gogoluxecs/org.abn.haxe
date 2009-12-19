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
package xmpp.dataform;

class FieldOption {
	
	public var label : String;
	public var value : String;
	
	public function new( ?label : String, ?value: String ) {
		this.label = label;
		this.value = value;
	}
	
	public function toXml() : Xml {
		var x = Xml.createElement( "option" );
		if( label != null ) x.set( "label", label );
		if( value != null ) x.addChild( util.XmlUtil.createElement( "value", value ) );
		return x;
	}
	
	public static function parse( x : Xml ) : FieldOption {
		var option = new FieldOption( x.get( "label" ) );
		option.value = x.elements().next().firstChild().nodeValue;
		return option;
	}
}
