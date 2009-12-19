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

/**
	<a href="http://xmpp.org/extensions/xep-0115.html">XEP-0085: Entity Capabilities</a><br/>
*/
class Caps {
	
	public static inline var XMLNS = xmpp.NS.PROTOCOL+"/caps";
	
	/**
		The hashing algorithm used to generate the verification string, fe: sha-1.
	*/
	public var hash : String;
	/**
		A URI that uniquely identifies a software application, typically a URL at the website
		of the project or company that produces the software
	*/
	public var node : String;
	/**
		A string that is used to verify the identity and supported features of the entity
	*/
	public var ver : String;
	/**
		A set of nametokens specifying additional feature bundles.
		This attribute is deprecated!
	*/
	public var ext : String;
	
	public function new( hash : String, node : String, ver : String, ?ext : String ) {
		this.hash = hash;
		this.node = node;
		this.ver = ver;
		this.ext = ext;
	}
	
	public function toXml() : Xml {
		var x = Xml.createElement( "c" );
		x.set( "xmlns", XMLNS );
		x.set( "hash", hash );
		x.set( "node", node );
		x.set( "ver", ver );
		if( ext != null ) x.set( "ext", ext );
		return x;
	}
	
	/**
	*/
	public static function parse( x : Xml ) : xmpp.Caps {
		return new Caps( x.get( "hash" ), x.get( "node" ), x.get( "ver" ), x.get( "ext" ) );
	}
	
	/**
	*/
	public static function fromPresence( p : xmpp.Presence ) : xmpp.Caps {
		for( prop in p.properties )
			if( prop.nodeName == "c" && prop.get( "xmlns" ) == XMLNS )
				return parse( prop );
		return null;
	}
	
	/**
		<a href="http://xmpp.org/extensions/xep-0115.html#ver">Verification String</a><br/>
	*/
	public static function createVerfificationString( identities : Iterable<xmpp.disco.Identity>, features : Iterable<String>,
													  ?dataform : xmpp.DataForm ) : String {
		var b = new StringBuf();
		// sort/add identities
		var _i = Lambda.array( identities );
		_i.sort( sortIdentities );
		for( i in _i ) {
			b.add( i.category );
			b.add( "/" );
			b.add( i.type );
			b.add( "/" );
			// lang ??????
			b.add( i.name );
			b.add( "<" );
		}
		// sort/add features
		var _f = Lambda.array( features );
		_f.sort( sort );
		b.add( _f.join( "<" ) );
		b.add( "<" );
		// sort/add dataform
		if( dataform != null ) {
			//TODO xmpp.X FORM_TYPE
			dataform.fields.sort( sortDataFormFields );
			for( f in dataform.fields ) {
				b.add( f.variable );
				b.add( "<" );
				for( v in f.values ) {
					b.add( v );
					b.add( "<" );
				}
			}
		}
		return util.Base64.encode( crypt.SHA1.encode( b.toString() ) );
	}
	
	static function sortIdentities( a : xmpp.disco.Identity, b : xmpp.disco.Identity ) : Int {
		return if( a.category > b.category ) 1;
		else if( a.category < b.category ) -1;
		else {
			if( a.type > b.type ) 1;
			else if( a.type < b.type ) -1;
			else {
				//TODO lang ?
				0;
			}
		}
	}

	static function sortDataFormFields( a : xmpp.dataform.Field, b : xmpp.dataform.Field ) {
		return if( a.variable == b.variable ) 0 else if( a.variable > b.variable ) 1 else -1; 
	}
	
	static inline function sort( a : String, b : String ) : Int {
		return ( a == b ) ? 0 : ( a > b ) ? 1 : -1;
	}
	
}
