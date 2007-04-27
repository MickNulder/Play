UPDATE 'streams' SET
		url = :url,
		
		date_added = :date_added,
		first_played_date = :first_played_date,
		last_played_date = :last_played_date,
		play_count = :play_count,
		skip_count = :skip_count,
		rating = :rating,		

		title = :title,
		album_title = :album_title,
		artist = :artist,
		album_artist = :album_artist,
		genre = :genre,
		composer = :composer,
		date = :date,
		compilation = :compilation,
		track_number = :track_number,
		track_total = :track_total,
		disc_number = :disc_number,
		disc_total = :disc_total,
		comment = :comment,
		isrc = :isrc,
		mcn = :mcn,
		
		file_type = :file_type,
		format_type = :format_type,
		bits_per_channel = :bits_per_channel,
		channels_per_frame = :channels_per_frame,
		sample_rate = :sample_rate,
		total_frames = :total_frames,
		duration = :duration,
		bitrate = :bitrate
		
	WHERE id == :id;