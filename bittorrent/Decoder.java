/*
 * Decoder - Attempts to read a .torrent file and display some info.
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
import java.io.File;
import java.io.FileInputStream;
import java.util.Iterator;
import java.util.List;

public class Decoder {

	public static void main(String[] args) throws Exception {
		File f;
		FileInputStream fis;
		MetaInfo meta;
		
		// The filename of the torrent file is required
		if (args[0] == null) {
			fatal("The torrent file must be the first argument.");
		}
		
		f = new File(args[0]);
		fis = new FileInputStream(f);
		meta = new MetaInfo(fis);

		System.out.println("Name: " + meta.getName());
		System.out.println("Tracker: " + meta.getAnnounce());
		List files = meta.getFiles();
		System.out.println("Files: " + ((files == null) ? 1 : files.size()));
		System.out.println("Pieces: " + meta.getPieces());
		System.out.println("Piece size: " + meta.getPieceLength(0) / 1024 + " KB");
		System.out.println("Total size: " + meta.getTotalLength() / (1024 * 1024) + " MB");

		fis.close();
	}

	/*
		An unrecoverable error
	*/
	private static void fatal(String msg) {
		System.out.println(msg);
		System.exit(1);
	}

}