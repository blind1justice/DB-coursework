CREATE TYPE user_role AS ENUM ('user', 'moderator', 'admin');
CREATE TYPE video_status AS ENUM ('processing', 'processed', 'failed', 'deleted');
CREATE TYPE reaction_type AS ENUM ('like', 'dislike');
CREATE TYPE report_status AS ENUM ('pending', 'resolved', 'rejected');

CREATE TABLE Users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(255),
    role user_role NOT NULL DEFAULT 'user',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE Channels (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    description TEXT,
    country VARCHAR(50),
    language VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE Subscriptions (
    id SERIAL PRIMARY KEY,
    subscriber_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    channel_id INTEGER NOT NULL REFERENCES Channels(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(subscriber_id, channel_id)
);

CREATE TABLE Videos (
    id SERIAL PRIMARY KEY,
    channel_id INTEGER NOT NULL REFERENCES Channels(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status video_status DEFAULT 'processing',
    duration INTEGER,
    storage_key VARCHAR(500),
    original_format VARCHAR(10),
    width INTEGER,
    height INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE VideoFormats (
    id SERIAL PRIMARY KEY,
    video_id INTEGER NOT NULL REFERENCES Videos(id) ON DELETE CASCADE,
    format VARCHAR(10) NOT NULL,
    bitrate INTEGER,
    resolution VARCHAR(20) NOT NULL,
    storage_key VARCHAR(500) NOT NULL,
    file_size BIGINT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE Subtitles (
    id SERIAL PRIMARY KEY,
    video_id INTEGER NOT NULL REFERENCES Videos(id) ON DELETE CASCADE,
    language VARCHAR(20) NOT NULL,
    storage_key VARCHAR(500) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE Comments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    video_id INTEGER NOT NULL REFERENCES Videos(id) ON DELETE CASCADE,
    parent_id INTEGER REFERENCES Comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_edited BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE Reactions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    video_id INTEGER REFERENCES Videos(id) ON DELETE CASCADE,
    comment_id INTEGER REFERENCES Comments(id) ON DELETE CASCADE,
    type reaction_type NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CHECK (
        (video_id IS NOT NULL AND comment_id IS NULL) OR 
        (video_id IS NULL AND comment_id IS NOT NULL)
    ),
    UNIQUE(user_id, video_id, comment_id)
);

CREATE TABLE Playlists (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE PlaylistsVideos (
    id SERIAL PRIMARY KEY,
    playlist_id INTEGER NOT NULL REFERENCES Playlists(id) ON DELETE CASCADE,
    video_id INTEGER NOT NULL REFERENCES Videos(id) ON DELETE CASCADE,
    position INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(playlist_id, video_id)
);

CREATE TABLE Notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE Reports (
    id SERIAL PRIMARY KEY,
    reporter_id INTEGER NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    video_id INTEGER REFERENCES Videos(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status report_status DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE UserPreferences (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES Users(id) ON DELETE CASCADE,
    language VARCHAR(10) DEFAULT 'en',
    autoplay BOOLEAN DEFAULT TRUE,
    quality VARCHAR(20) DEFAULT 'auto',
    notifications_enabled BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);


CREATE INDEX idx_users_email ON Users(email);
CREATE INDEX idx_users_username ON Users(username);

CREATE INDEX idx_videos_user_id ON Videos(user_id);
CREATE INDEX idx_videos_status ON Videos(status);
CREATE INDEX idx_videos_created_at ON Videos(created_at);

CREATE INDEX idx_videoformats_video_id ON VideoFormats(video_id);

CREATE INDEX idx_subtitles_video_id ON Subtitles(video_id);

CREATE INDEX idx_comments_user_id ON Comments(user_id);
CREATE INDEX idx_comments_video_id ON Comments(video_id);
CREATE INDEX idx_comments_parent_id ON Comments(parent_id);
CREATE INDEX idx_comments_created_at ON Comments(created_at);

CREATE INDEX idx_reactions_user_id ON Reactions(user_id);
CREATE INDEX idx_reactions_video_id ON Reactions(video_id);
CREATE INDEX idx_reactions_comment_id ON Reactions(comment_id);

CREATE INDEX idx_playlists_user_id ON Playlists(user_id);

CREATE INDEX idx_playlistsvideos_playlist_id ON PlaylistsVideos(playlist_id);
CREATE INDEX idx_playlistsvideos_video_id ON PlaylistsVideos(video_id);

CREATE INDEX idx_subscriptions_subscriber_id ON Subscriptions(subscriber_id);
CREATE INDEX idx_subscriptions_channel_id ON Subscriptions(channel_id);

CREATE INDEX idx_notifications_user_id ON Notifications(user_id);
CREATE INDEX idx_notifications_is_read ON Notifications(is_read);

CREATE INDEX idx_reports_reporter_id ON Reports(reporter_id);
CREATE INDEX idx_reports_video_id ON Reports(video_id);
CREATE INDEX idx_reports_status ON Reports(status);
