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
package jabber.client;

import jabber.stream.PacketCollector;
import xmpp.IQ;
import xmpp.IQType;
import xmpp.filter.PacketNameFilter;
import xmpp.filter.FilterGroup;

/**
	Responsible for authenticating a client account using SASL,
	binding the resource to the connection and establishing a session with the server.<br>
	<a href="http://xmpp.org/rfcs/rfc3920.html#sasl">RFC3920-SASL</a><br/>
	<a href="http://xmpp.org/rfcs/rfc3920.html#bind">RFC3920-BIND</a><br/>
	http://www.ietf.org/mail-archive/web/isms/current/msg00063.html
*/
class SASLAuthentication extends Authentication {

	public dynamic function onNegotiated() : Void;
	
	/** Used SASL method */
	public var handshake(default,null) : net.sasl.Handshake;
	/** Available mechanisms ids (from server) */
	public var mechanisms(default,null) : Array<String>;
	//public var negotiated(default,null) : Bool;
	
	var onStreamOpenHandler : Void->Void;
	var c_challenge : PacketCollector;
	var c_fail : PacketCollector;
	var c_success : PacketCollector;
	
	public function new( stream : Stream, mechanisms : Iterable<net.sasl.Mechanism> ) {
		var x = stream.server.features.get( "mechanisms" );
		if( x == null )
			throw "Server does't support SASL";
		if( mechanisms == null || Lambda.count( mechanisms ) == 0 )
			throw "No SASL mechanisms given";
		super( stream );
		this.mechanisms = xmpp.SASL.parseMechanisms( x );
		handshake = new net.sasl.Handshake();
		for( m in mechanisms )
			handshake.mechanisms.push( m );
	}
	
	/**
		Inits SASL authentication.
		Returns false if no compatible SASL mechanism was found.
	*/
	public override function authenticate( password : String, ?resource : String ) : Bool {
		this.resource = resource;
		// update stream jid resource
		if( stream.jid != null && resource != null )
			stream.jid.resource = resource;
		// locate mechanism to use.
		if( handshake.mechanism == null ) {
			for( amechs in mechanisms ) {
				for( m in handshake.mechanisms ) {
					if( m.id != amechs )
						continue;
					handshake.mechanism = m;
					break;
				}
				if( handshake.mechanism != null )
					break;
			}
		}
		if( handshake.mechanism == null ) {
			#if JABBER_DEBUG
			trace( "No matching SASL mechanism found.", "warn" );
			#end
			return false;
		}
		// collect failures
		var f = new FilterGroup();
		f.add( new PacketNameFilter( ~/failure/ ) ); //?
		f.add( new PacketNameFilter( ~/not-authorized/ ) );
		f.add( new PacketNameFilter( ~/aborted/ ) );
		f.add( new PacketNameFilter( ~/incorrect-encoding/ ) );
		f.add( new PacketNameFilter( ~/invalid-authzid/ ) );
		f.add( new PacketNameFilter( ~/invalid-mechanism/ ) );
		f.add( new PacketNameFilter( ~/mechanism-too-weak/ ) );
		f.add( new PacketNameFilter( ~/temporary-auth-failure/ ) );
		c_fail = new PacketCollector( [cast f], handleSASLFailed );
		stream.addCollector( c_fail );
		// collect success
		c_success = new PacketCollector( [cast new PacketNameFilter( ~/success/ )], handleSASLSuccess );
		stream.addCollector( c_success );
		// collect challenge
		c_challenge = new PacketCollector( [cast new PacketNameFilter( ~/challenge/ )], handleSASLChallenge, true );
		stream.addCollector( c_challenge );
		// send init auth
		//trace("############## "+stream.jid );
		var t = handshake.mechanism.createAuthenticationText( stream.jid.node, stream.jid.domain, password );
		if( t != null ) t = util.Base64.encode( t );
		return stream.sendData( xmpp.SASL.createAuthXml( handshake.mechanism.id, t ).toString() ) != null;
	}
	
	function handleSASLFailed( p : xmpp.Packet ) {
		removeSASLCollectors();
		onFail();
	}
	
	function handleSASLChallenge( p : xmpp.Packet ) {
		// create/send challenge response
		var c = p.toXml().firstChild().nodeValue;
		var r = util.Base64.encode( handshake.getChallengeResponse( c ) );
		stream.sendData( xmpp.SASL.createResponseXml( r ).toString() );
	}
	
	function handleSASLSuccess( p : xmpp.Packet ) {
		removeSASLCollectors(); // remove the challenge collector
		onStreamOpenHandler = stream.onOpen; // relay the stream open event
		stream.onOpen = handleStreamOpen;
		onNegotiated();
		//stream.version = false;
		stream.open(); // re-open XMPP stream
		//return p.toString().length;
	}
	
	function handleStreamOpen() {
		stream.onOpen = onStreamOpenHandler;
		//onStreamOpenHandler = null;
		if( stream.server.features.exists( "bind" ) ) { // bind the resource
			var iq = new IQ( IQType.set );
			iq.x = new xmpp.Bind( ( handshake.mechanism.id == "ANONYMOUS" ) ? null : resource );
			stream.sendIQ( iq, handleBind );
		} else {
			onSuccess(); // TODO ?
		}
	}
	
	function handleBind( iq : IQ ) {
		switch( iq.type ) {
		case IQType.result :
			/*
			// TODO required ?
			var b = xmpp.Bind.parse( iq.x.toXml() );
			if( jabber.util.JIDUtil.parseResource( b.jid ) != resource ) {
				throw "Unexpected resource bound ?";
			}
			*/
			//onBind();
			var b = xmpp.Bind.parse( iq.x.toXml() );
			var jid = new jabber.JID( b.jid );
			stream.jid.node = jid.node;
			stream.jid.resource = jid.resource;
			if( stream.server.features.exists( "session" ) ) {
				// init session
				var iq = new IQ( IQType.set );
				iq.x = new xmpp.PlainPacket( Xml.parse( '<session xmlns="urn:ietf:params:xml:ns:xmpp-session"/>' ) );
				stream.sendIQ( iq, handleSession );
			} else
				onSuccess(); //?
		case IQType.error :
			onFail( new jabber.XMPPError( this, iq ) );
		}
	}
	
	function handleSession( iq : IQ ) {
		switch( iq.type ) {
		case result :
			////onSession();
			onSuccess();
		case error :
			onFail( new jabber.XMPPError( this, iq ) );
		default : //#
		}
	}
	
	function removeSASLCollectors() {
		stream.removeCollector( c_challenge );
		c_challenge = null;
		stream.removeCollector( c_fail );
		c_fail = null;
		stream.removeCollector( c_success );
		c_success = null;
	}
	
}
