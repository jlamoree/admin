/*
 * TrackerScraper - Attempts to read a .torrent file and use the scrape URL
 * on the tracker to display stats on a torrent.
 * This code was cobbled together after reading through the Snark source.
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
import java.net.URL;
import java.net.URLConnection;
import java.net.HttpURLConnection;
import java.util.Iterator;
import java.util.Map;

public class TrackerScraper {

	public static void main(String[] args) throws Exception {

		// The filename of the torrent file is required
		if (args[0] == null) {
			fatal("The torrent file must be the first argument.");
		}

		// Open and parse the torrent file
		File f = new File(args[0]);
		FileInputStream fis = new FileInputStream(f);
		MetaInfo meta = new MetaInfo(fis);
		fis.close();

		// Create a scrape URL
		URL u = new URL(createScrapeURL(meta));
		System.out.println("Scrape URL: " + u);

		// Connect to the tracker
		URLConnection uc = u.openConnection();
		uc.connect();
		InputStream is = uc.getInputStream();

		// Parse the response
		try {
			BDecoder decoder = new BDecoder(is);
			Map root = decoder.bdecodeMap().getMap();
			BEValue files = (BEValue) root.get("files");
			Map fm = files.getMap();
			Iterator it = fm.keySet().iterator();

			while (it.hasNext()) {
				String infohash = (String) it.next();
				BEValue file = (BEValue) fm.get(infohash);
				Map m = file.getMap();
				BEValue complete = (BEValue) m.get("complete");
				System.out.println("Seeders: " + complete.getInt());
				BEValue incomplete = (BEValue) m.get("incomplete");
				System.out.println("Leechers: " + incomplete.getInt());
				BEValue downloaded = (BEValue) m.get("downloaded");
				System.out.println("Downloaded: " + downloaded.getInt());
			}
		} catch(Exception e) {
			fatal("Error: " + e);
		}
	}


	/*
		An unrecoverable error
	*/
	private static void fatal(String msg) {
		System.out.println(msg);
		System.exit(1);
	}


	/*
		An scrape URL using the announce URL in the metadata
	*/
	private static String createScrapeURL(MetaInfo meta) {
		String u = meta.getAnnounce().replaceAll("announce", "scrape");
		String info_hash = urlEncode(meta.getInfoHash());
		return u + "?info_hash=" + info_hash;
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

}