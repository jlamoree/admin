/*
 * TrackerPeerList - Attempts to read a .torrent file, connect to the tracker,
 * and display a list of peers. This code was cobbled together after reading
 * through the Snark source.
 *
 * Copyright 2009 Joseph Lamoree <http://www.lamoree.com/>
 * Copyright 2003 Mark J. Wielaard
 * 
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation; either version 2, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 * 
 * You should have received a copy of the GNU General Public License along with
 * this program; if not, write to the Free Software Foundation, Inc., 59 Temple
 * Place - Suite 330, Boston, MA 02111-1307, USA.
 */

import org.klomp.snark.MetaInfo;
import org.klomp.snark.bencode.BDecoder;
import org.klomp.snark.bencode.BEValue;
import org.klomp.snark.bencode.InvalidBEncodingException;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.Iterator;
import java.util.List;
import java.util.Random;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.net.URL;
import java.net.URLConnection;
import java.net.HttpURLConnection;
import java.lang.Integer;
import java.lang.String;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

public class TrackerPeerList {

	public static void main(String[] args) throws Exception {

		// The filename of the torrent file is required
		if (args[0] == null) {
			fatal("The torrent file must be the first argument.");
		}

		// Open and parse the torrent file
		File f = new File(args[0]);
		FileInputStream fis = new FileInputStream(f);
		MetaInfo meta = new MetaInfo(fis);

		// Report some information
		System.out.println("Name: " + meta.getName());
		System.out.println("Info Hash: " + hexEncode(meta.getInfoHash()));

		// Create an announce URL
		URL u = new URL(createAnnounceURL(meta));
		System.out.println("Announce URL: " + u);

		// Connect to the tracker
		URLConnection uc = u.openConnection();
		uc.connect();
		InputStream is = uc.getInputStream();

		// Parse the response
		try {
			BDecoder decoder = new BDecoder(is);
			Map m = decoder.bdecodeMap().getMap();

			BEValue reason = (BEValue) m.get("failure reason");
			if (reason != null) {
				fatal("Error: " + reason.getString());
			} else {
				BEValue peers = (BEValue) m.get("peers");

				// Are peers expressed in dictionary model or binary model?
				byte[] peerData = null;
				List<BEValue> peerList = null;
				try {
					peerData = peers.getBytes();
					displayPeers(peerData);
				} catch(InvalidBEncodingException ie) {
					try {
						peerList = peers.getList();
						displayPeers(peerList);
					} catch(InvalidBEncodingException sie) {
						fatal("Error: Couldn't parse the peer data as binary or dictionary model.");
					}
				}
			}
		} catch(Exception e) {
			fatal("Error: " + e);
		}
		
		fis.close();
	}


	/*
		An unrecoverable error
	*/
	private static void fatal(String msg) {
		System.out.println(msg);
		System.exit(1);
	}

	/*
		Displays the list of peers as received in a binary byte array
	*/
	private static void displayPeers(byte[] peers) {
		byte[] ip = new byte[4];
		int port;
		for (int i = 0; i < peers.length; i += 6) {
			ip[0] = peers[i];
			ip[1] = peers[i + 1];
			ip[2] = peers[i + 2];
			ip[3] = peers[i + 3];
			
			int high = peers[i + 4] & 0xff;
			int low = peers[i + 5] & 0xff;
			port = (int) ( high << 8 | low );

			try {
				InetAddress ipAddr = InetAddress.getByAddress(ip);
				System.out.println("	" + ipAddr.getHostAddress() + ":" + port);
			} catch(UnknownHostException uhe) {
				System.out.println("Warning: Error parsing peer bytes.");
			}
		}
	}


	/*
		Displays the list of peers as received in a list of dictionary bencode values
	*/
	private static void displayPeers(List<BEValue> peers) {
		Iterator it = peers.iterator();
		while (it.hasNext()) {
			BEValue be = (BEValue) it.next();

			try {
				Map p = be.getMap();
				BEValue beIp = (BEValue) p.get("ip");
				String ip = new String(beIp.getBytes());
			
				BEValue bePort = (BEValue) p.get("port");
				int port = bePort.getInt();
				System.out.println("	" + ip + ":" + port);
			} catch(InvalidBEncodingException ie) {
				System.out.println("Warning: Could not decode peer.");	
			}
		}
	}


	/*
		A random 20-byte value
	*/
	private static byte[] createId() {
		byte[] id = new byte[20];

		// Create a new ID and fill it with something random. First nine
		// zeros bytes, then three bytes filled with snark and then
		// sixteen random bytes.
		Random random = new Random();
		int i;
		for (i = 0; i < 9; i++) {
			id[i] = 0;
		}
		id[i++] = snark;
		id[i++] = snark;
		id[i++] = snark;
		while (i < 20) {
			id[i++] = (byte)random.nextInt(256);
		}
		return id;
	}

	/*
		An announce URL with hard-coded values for the number of bytes already uploaded and downloaded
	*/
	private static String createAnnounceURL(MetaInfo meta) {
		String info_hash = urlEncode(meta.getInfoHash());
		String peerId = urlEncode(createId());

			String result = meta.getAnnounce() + "?info_hash=" + info_hash
				+ "&peer_id=" + peerId
				+ "&port=" + CLIENT_PORT
				+ "&uploaded=" + CLIENT_UPLOADED
				+ "&downloaded=" + CLIENT_DOWNLOADED
				+ "&left=" + meta.getTotalLength()
				+ "&numwant=" + CLIENT_PEERS_REQUESTED;
			return result;
	}

	private static String urlEncode(byte[] ba) {
		StringBuffer sb = new StringBuffer(ba.length * 3);
		for (byte b : ba) {
			int c = b & 0xFF;
			sb.append('%');
			if (c < 16) {
				sb.append('0');
			}
			sb.append(Integer.toHexString(c));
		}
		return sb.toString();
	}

	private static String hexEncode(byte[] ba) {
		StringBuffer sb = new StringBuffer(ba.length * 2);
		for (byte b : ba) {
			int c = b & 0xFF;
			if (c < 16) {
				sb.append('0');
			}
			sb.append(Integer.toHexString(c));
		}
		return sb.toString();
	}


	// See "The Beaver's Lesson - The Hunting of the Snark" by Lewis Carroll
	protected static final byte snark = (((3 + 7 + 10) * (1000 - 8)) / 992) - 17;

	protected static final int CLIENT_PEERS_REQUESTED = 50;
	protected static final int CLIENT_PORT = 6881;
	protected static final int CLIENT_UPLOADED = 0;
	protected static final int CLIENT_DOWNLOADED = 0;
}