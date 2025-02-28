// Spotify API configuration
const clientId = '501a427e2c0041638cc6a46c156546ff'; // Your Spotify Client ID
// Fixed redirect URI - this MUST exactly match what you set in your Spotify Developer Dashboard
const redirectUri = 'https://danielaja.github.io/Playlist-DJ/';
const scope = 'user-read-private user-read-email playlist-modify-public playlist-modify-private streaming user-read-playback-state user-modify-playback-state';

// Application state
let accessToken = null;
let currentUser = null;
let selectedTrack = null;
let playlistTracks = [];
let audioContext = null;
let audioSource = null;
let gainNode = null;
let audioBuffer = null;
let currentPlayingIndex = -1;
let isPlaying = false;
let playbackTimer = null;
let typingTimer = null;
let suggestedTracks = [];

// DOM elements
const loginButton = document.getElementById('login-button');
const loginSection = document.getElementById('login-section');
const appSection = document.getElementById('app-section');
const searchInput = document.getElementById('search-input');
const searchButton = document.getElementById('search-button');
const searchResults = document.getElementById('search-results');
const suggestionPopup = document.getElementById('suggestion-popup');
const suggestionList = document.getElementById('suggestion-list');
const closeSuggestions = document.getElementById('close-suggestions');
const playlistName = document.getElementById('playlist-name');
const playlistTracksElement = document.getElementById('playlist-tracks');
const savePlaylistButton = document.getElementById('save-playlist');
const playPlaylistButton = document.getElementById('play-playlist');
const saveLocalButton = document.getElementById('save-local');
const playerContainer = document.getElementById('player-container');
const nowPlayingTitle = document.getElementById('now-playing-title');
const prevTrackButton = document.getElementById('prev-track');
const playPauseButton = document.getElementById('play-pause');
const nextTrackButton = document.getElementById('next-track');
const progressBar = document.getElementById('progress-bar');
const trackEditor = document.getElementById('track-editor');
const trackTitle = document.getElementById('track-title');
const trackArtist = document.getElementById('track-artist');
const startTimeSlider = document.getElementById('start-time');
const endTimeSlider = document.getElementById('end-time');
const startTimeDisplay = document.getElementById('start-time-display');
const endTimeDisplay = document.getElementById('end-time-display');
const fadeInSlider = document.getElementById('fade-in');
const fadeOutSlider = document.getElementById('fade-out');
const fadeInDisplay = document.getElementById('fade-in-display');
const fadeOutDisplay = document.getElementById('fade-out-display');
const previewPlayer = document.getElementById('preview-player');
const saveTrackButton = document.getElementById('save-track');
const cancelEditButton = document.getElementById('cancel-edit');

// Event listeners
document.addEventListener('DOMContentLoaded', initialize);
loginButton.addEventListener('click', handleLogin);
searchButton.addEventListener('click', handleSearch);
searchInput.addEventListener('input', handleSearchInput);
closeSuggestions.addEventListener('click', () => suggestionPopup.classList.add('hidden'));
startTimeSlider.addEventListener('input', updateTimeDisplay);
endTimeSlider.addEventListener('input', updateTimeDisplay);
fadeInSlider.addEventListener('input', updateFadeDisplay);
fadeOutSlider.addEventListener('input', updateFadeDisplay);
saveTrackButton.addEventListener('click', saveTrackEdits);
cancelEditButton.addEventListener('click', closeTrackEditor);
savePlaylistButton.addEventListener('click', savePlaylistToSpotify);
playPlaylistButton.addEventListener('click', playPlaylist);
saveLocalButton.addEventListener('click', savePlaylistLocally);
prevTrackButton.addEventListener('click', playPreviousTrack);
playPauseButton.addEventListener('click', togglePlayPause);
nextTrackButton.addEventListener('click', playNextTrack);

// Initialize the application
function initialize() {
  // Check if the URL contains the access token after Spotify authorization
  const params = new URLSearchParams(window.location.hash.substring(1));
  accessToken = params.get('access_token');
  
  if (accessToken) {
    // Remove the access token from the URL
    window.history.replaceState({}, document.title, window.location.pathname);
    
    // Initialize audio context
    try {
      audioContext = new (window.AudioContext || window.webkitAudioContext)();
    } catch (e) {
      console.error('Web Audio API is not supported in this browser', e);
    }
    
    // Show the application UI
    loginSection.classList.add('hidden');
    appSection.classList.remove('hidden');
    
    // Get user information
    getUserInfo();
  }
}

// Handle Spotify login
function handleLogin() {
  const authUrl = `https://accounts.spotify.com/authorize?client_id=${clientId}&response_type=token&redirect_uri=${encodeURIComponent(redirectUri)}&scope=${encodeURIComponent(scope)}`;
  window.location.href = authUrl;
}

// Get user information from Spotify
async function getUserInfo() {
  try {
    const response = await fetch('https://api.spotify.com/v1/me', {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });
    
    if (!response.ok) {
      throw new Error('Failed to fetch user data');
    }
    
    currentUser = await response.json();
    console.log('User info:', currentUser);
  } catch (error) {
    console.error('Error fetching user info:', error);
    alert('Failed to get user information. Please try logging in again.');
  }
}

// Handle search for tracks
async function handleSearch() {
  const query = searchInput.value.trim();
  
  if (!query) return;
  
  try {
    const response = await fetch(`https://api.spotify.com/v1/search?q=${encodeURIComponent(query)}&type=track&limit=10`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });
    
    if (!response.ok) {
      throw new Error('Failed to search tracks');
    }
    
    const data = await response.json();
    displaySearchResults(data.tracks.items);
  } catch (error) {
    console.error('Error searching tracks:', error);
    alert('Failed to search for tracks. Please try again.');
  }
}

// Display search results
function displaySearchResults(tracks) {
  searchResults.innerHTML = '';
  
  if (tracks.length === 0) {
    searchResults.innerHTML = '<p>No tracks found.</p>';
    return;
  }
  
  tracks.forEach(track => {
    const resultElement = document.createElement('div');
    resultElement.className = 'search-result';
    resultElement.innerHTML = `
      <img src="${track.album.images[2]?.url || ''}" alt="${track.album.name}">
      <div>
        <div class="track-title">${track.name}</div>
        <div class="track-artist">${track.artists.map(artist => artist.name).join(', ')}</div>
      </div>
    `;
    
    resultElement.addEventListener('click', () => {
      openTrackEditor(track);
    });
    
    searchResults.appendChild(resultElement);
  });
}

// Open track editor
async function openTrackEditor(track) {
  selectedTrack = track;
  
  // Display track information
  trackTitle.textContent = track.name;
  trackArtist.textContent = track.artists.map(artist => artist.name).join(', ');
  
  // Reset controls
  startTimeSlider.value = 0;
  endTimeSlider.value = 100;
  fadeInSlider.value = 0;
  fadeOutSlider.value = 0;
  
  // Update displays
  updateTimeDisplay();
  updateFadeDisplay();
  
  // Set up preview player
  if (track.preview_url) {
    previewPlayer.src = track.preview_url;
    
    // Load the audio for processing
    try {
      const response = await fetch(track.preview_url);
      const arrayBuffer = await response.arrayBuffer();
      audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
      
      // Update the max values for time sliders based on track duration
      const duration = audioBuffer.duration;
      startTimeSlider.max = duration;
      endTimeSlider.max = duration;
      endTimeSlider.value = duration;
      
      updateTimeDisplay();
    } catch (error) {
      console.error('Error loading audio:', error);
    }
  } else {
    previewPlayer.src = '';
    alert('Preview not available for this track.');
  }
  
  // Show the editor
  trackEditor.classList.remove('hidden');
}

// Update time display
function updateTimeDisplay() {
  const startTime = parseFloat(startTimeSlider.value);
  const endTime = parseFloat(endTimeSlider.value);
  
  // Make sure end time is always greater than start time
  if (endTime <= startTime) {
    endTimeSlider.value = startTime + 1;
  }
  
  startTimeDisplay.textContent = formatTime(startTime);
  endTimeDisplay.textContent = formatTime(parseFloat(endTimeSlider.value));
}

// Update fade display
function updateFadeDisplay() {
  fadeInDisplay.textContent = fadeInSlider.value;
  fadeOutDisplay.textContent = fadeOutSlider.value;
}

// Format time in MM:SS format
function formatTime(seconds) {
  const minutes = Math.floor(seconds / 60);
  const remainingSeconds = Math.floor(seconds % 60);
  return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
}

// Save track edits
function saveTrackEdits() {
  if (!selectedTrack) return;
  
  const customTrack = {
    spotifyTrack: selectedTrack,
    startTime: parseFloat(startTimeSlider.value),
    endTime: parseFloat(endTimeSlider.value),
    fadeIn: parseFloat(fadeInSlider.value),
    fadeOut: parseFloat(fadeOutSlider.value)
  };
  
  // Add to playlist tracks
  playlistTracks.push(customTrack);
  
  // Update playlist UI
  updatePlaylistUI();
  
  // Close editor
  closeTrackEditor();
}

// Update playlist UI
function updatePlaylistUI() {
  playlistTracksElement.innerHTML = '';
  
  playlistTracks.forEach((customTrack, index) => {
    const track = customTrack.spotifyTrack;
    const trackElement = document.createElement('li');
    trackElement.className = 'playlist-track';
    trackElement.innerHTML = `
      <div class="track-details">
        <div class="track-title">${track.name}</div>
        <div class="track-artist">${track.artists.map(artist => artist.name).join(', ')}</div>
        <div class="track-times">
          ${formatTime(customTrack.startTime)} - ${formatTime(customTrack.endTime)} 
          | Fade in: ${customTrack.fadeIn}s | Fade out: ${customTrack.fadeOut}s
        </div>
      </div>
      <div class="track-actions">
        <button class="play-track" data-index="${index}">Play</button>
        <button class="edit-track" data-index="${index}">Edit</button>
        <button class="remove-track" data-index="${index}">Remove</button>
      </div>
    `;
    
    playlistTracksElement.appendChild(trackElement);
  });
  
  // Add event listeners to the new buttons
  document.querySelectorAll('.play-track').forEach(button => {
    button.addEventListener('click', event => {
      const index = parseInt(event.currentTarget.dataset.index);
      playCustomTrack(playlistTracks[index], index);
    });
  });
  
  document.querySelectorAll('.edit-track').forEach(button => {
    button.addEventListener('click', event => {
      const index = parseInt(event.currentTarget.dataset.index);
      editPlaylistTrack(index);
    });
  });
  
  document.querySelectorAll('.remove-track').forEach(button => {
    button.addEventListener('click', event => {
      const index = parseInt(event.currentTarget.dataset.index);
      removePlaylistTrack(index);
    });
  });
}

// Edit a track in the playlist
function editPlaylistTrack(index) {
  const customTrack = playlistTracks[index];
  selectedTrack = customTrack.spotifyTrack;
  
  // Populate editor with track data
  trackTitle.textContent = selectedTrack.name;
  trackArtist.textContent = selectedTrack.artists.map(artist => artist.name).join(', ');
  
  startTimeSlider.value = customTrack.startTime;
  endTimeSlider.value = customTrack.endTime;
  fadeInSlider.value = customTrack.fadeIn;
  fadeOutSlider.value = customTrack.fadeOut;
  
  // Update displays
  updateTimeDisplay();
  updateFadeDisplay();
  
  // Set up preview player
  if (selectedTrack.preview_url) {
    previewPlayer.src = selectedTrack.preview_url;
  }
  
  // Remove the track from the playlist
  playlistTracks.splice(index, 1);
  
  // Show the editor
  trackEditor.classList.remove('hidden');
}

// Remove a track from the playlist
function removePlaylistTrack(index) {
  playlistTracks.splice(index, 1);
  updatePlaylistUI();
}

// Close track editor
function closeTrackEditor() {
  trackEditor.classList.add('hidden');
  selectedTrack = null;
}

// Save playlist to Spotify
async function savePlaylistToSpotify() {
  if (playlistTracks.length === 0) {
    alert('Please add tracks to your playlist first.');
    return;
  }
  
  const name = playlistName.value.trim() || 'My Custom Playlist';
  
  try {
    // Create a new playlist
    const createResponse = await fetch(`https://api.spotify.com/v1/users/${currentUser.id}/playlists`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        name: name,
        description: 'Created with PlaylistDJ - Custom time sections and transitions'
      })
    });
    
    if (!createResponse.ok) {
      throw new Error('Failed to create playlist');
    }
    
    const playlist = await createResponse.json();
    
    // Add tracks to the playlist
    const trackUris = playlistTracks.map(customTrack => customTrack.spotifyTrack.uri);
    
    const addTracksResponse = await fetch(`https://api.spotify.com/v1/playlists/${playlist.id}/tracks`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        uris: trackUris
      })
    });
    
    if (!addTracksResponse.ok) {
      throw new Error('Failed to add tracks to playlist');
    }
    
    // Store custom track data in localStorage (since Spotify API doesn't support custom start/end times)
    const customData = {
      playlistId: playlist.id,
      tracks: playlistTracks.map(customTrack => ({
        uri: customTrack.spotifyTrack.uri,
        startTime: customTrack.startTime,
        endTime: customTrack.endTime,
        fadeIn: customTrack.fadeIn,
        fadeOut: customTrack.fadeOut
      }))
    };
    
    localStorage.setItem(`PlaylistDJ_playlist_${playlist.id}`, JSON.stringify(customData));
    
    alert(`Playlist "${name}" created successfully! Open the Spotify app to see it.`);
    
    // Note: Explain to user that the custom times and fades will only work in this app
    alert('Note: Custom start/end times and fades will only work when playing through this app, not in the Spotify app directly.');
  } catch (error) {
    console.error('Error saving playlist:', error);
    alert('Failed to save playlist to Spotify. Please try again.');
  }
}

// Function to play a custom track with time sections and fades
async function playCustomTrack(customTrack, index) {
  if (!audioContext) {
    audioContext = new (window.AudioContext || window.webkitAudioContext)();
  }
  
  // Stop any currently playing audio
  if (audioSource) {
    audioSource.stop();
  }
  
  // Get track audio - if it's just a preview URL, use that
  // otherwise fetch the full track audio if available through the Web Playback SDK
  const audioUrl = customTrack.spotifyTrack.preview_url;
  
  if (!audioUrl) {
    alert('Preview not available for this track.');
    return;
  }
  
  try {
    const response = await fetch(audioUrl);
    const arrayBuffer = await response.arrayBuffer();
    audioBuffer = await audioContext.decodeAudioData(arrayBuffer);
    
    // Create a buffer source
    audioSource = audioContext.createBufferSource();
    audioSource.buffer = audioBuffer;
    
    // Create a gain node for volume control (used for fades)
    gainNode = audioContext.createGain();
    
    // Connect the nodes
    audioSource.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    // Set up fade in
    const fadeInTime = customTrack.fadeIn;
    if (fadeInTime > 0) {
      gainNode.gain.setValueAtTime(0, audioContext.currentTime);
      gainNode.gain.linearRampToValueAtTime(1, audioContext.currentTime + fadeInTime);
    }
    
    // Set up fade out
    const fadeOutTime = customTrack.fadeOut;
    const startTime = customTrack.startTime;
    const endTime = customTrack.endTime;
    const duration = endTime - startTime;
    
    if (fadeOutTime > 0) {
      gainNode.gain.setValueAtTime(1, audioContext.currentTime + duration - fadeOutTime);
      gainNode.gain.linearRampToValueAtTime(0, audioContext.currentTime + duration);
    }
    
    // Update UI
    currentPlayingIndex = index;
    isPlaying = true;
    playPauseButton.textContent = 'Pause';
    nowPlayingTitle.textContent = `${customTrack.spotifyTrack.name} - ${customTrack.spotifyTrack.artists[0].name}`;
    playerContainer.classList.remove('hidden');
    
    // Start playing from the start time and stop at the end time
    audioSource.start(0, startTime, duration);
    
    // Set up progress bar updating
    if (playbackTimer) clearInterval(playbackTimer);
    
    const startTime_ms = startTime * 1000;
    const duration_ms = duration * 1000;
    let startPlayTime = Date.now();
    
    playbackTimer = setInterval(() => {
      const elapsedTime = Date.now() - startPlayTime;
      const progress = (elapsedTime / duration_ms) * 100;
      
      progressBar.style.width = `${Math.min(progress, 100)}%`;
      
      if (elapsedTime >= duration_ms) {
        clearInterval(playbackTimer);
        
        // Auto-play next track if this is part of playlist playback
        if (currentPlayingIndex !== -1) {
          setTimeout(() => playNextTrack(), 500);
        }
      }
    }, 100);
    
    // Set up event for when track ends
    audioSource.onended = () => {
      isPlaying = false;
      playPauseButton.textContent = 'Play';
      
      if (playbackTimer) {
        clearInterval(playbackTimer);
      }
    };
    
  } catch (error) {
    console.error('Error playing track:', error);
    alert('Failed to play this track. Please try another one.');
  }
}

// Initialize Spotify Web Playback SDK
window.onSpotifyWebPlaybackSDKReady = () => {
  // Note: Implement Spotify Playback SDK for full-track playback here
  // This would require a premium Spotify account
  console.log('Spotify Web Playback SDK ready');
};

// Handle search input for suggestions
function handleSearchInput(event) {
  const query = event.target.value.trim();
  
  // Clear previous timeout
  if (typingTimer) {
    clearTimeout(typingTimer);
  }
  
  // Hide suggestions if query is empty
  if (!query) {
    suggestionPopup.classList.add('hidden');
    return;
  }
  
  // Set a timer to fetch suggestions after user stops typing
  typingTimer = setTimeout(() => {
    fetchSuggestions(query);
  }, 500);
}

// Fetch song suggestions
async function fetchSuggestions(query) {
  if (!query || query.length < 3) return;
  
  try {
    const response = await fetch(`https://api.spotify.com/v1/search?q=${encodeURIComponent(query)}&type=track&limit=5`, {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });
    
    if (!response.ok) {
      throw new Error('Failed to fetch suggestions');
    }
    
    const data = await response.json();
    displaySuggestions(data.tracks.items);
  } catch (error) {
    console.error('Error fetching suggestions:', error);
  }
}

// Display suggestions
function displaySuggestions(tracks) {
  if (!tracks || tracks.length === 0) {
    suggestionPopup.classList.add('hidden');
    return;
  }
  
  suggestedTracks = tracks;
  suggestionList.innerHTML = '';
  
  tracks.forEach((track, index) => {
    const item = document.createElement('div');
    item.className = 'suggestion-item';
    item.innerHTML = `
      <img src="${track.album.images[2]?.url || ''}" alt="${track.album.name}">
      <div>
        <div class="track-title">${track.name}</div>
        <div class="track-artist">${track.artists.map(artist => artist.name).join(', ')}</div>
      </div>
    `;
    
    item.addEventListener('click', () => {
      openTrackEditor(track);
      suggestionPopup.classList.add('hidden');
    });
    
    suggestionList.appendChild(item);
  });
  
  suggestionPopup.classList.remove('hidden');
}

// Play the playlist
function playPlaylist() {
  if (playlistTracks.length === 0) {
    alert('Your playlist is empty. Add some tracks first!');
    return;
  }
  
  currentPlayingIndex = 0;
  playCustomTrack(playlistTracks[currentPlayingIndex], currentPlayingIndex);
}

// Toggle play/pause
function togglePlayPause() {
  if (!audioContext || currentPlayingIndex === -1) {
    // Start playing if nothing is playing
    playPlaylist();
    return;
  }
  
  if (isPlaying) {
    // Pause
    audioSource.stop();
    isPlaying = false;
    playPauseButton.textContent = 'Play';
    if (playbackTimer) {
      clearInterval(playbackTimer);
    }
  } else {
    // Resume or start new playback
    playCustomTrack(playlistTracks[currentPlayingIndex], currentPlayingIndex);
  }
}

// Play next track
function playNextTrack() {
  if (playlistTracks.length === 0) return;
  
  // Stop current audio
  if (audioSource) {
    audioSource.stop();
  }
  
  // Increment index and wrap around
  currentPlayingIndex = (currentPlayingIndex + 1) % playlistTracks.length;
  
  // Play the next track
  playCustomTrack(playlistTracks[currentPlayingIndex], currentPlayingIndex);
}

// Play previous track
function playPreviousTrack() {
  if (playlistTracks.length === 0) return;
  
  // Stop current audio
  if (audioSource) {
    audioSource.stop();
  }
  
  // Decrement index and wrap around
  currentPlayingIndex = (currentPlayingIndex - 1 + playlistTracks.length) % playlistTracks.length;
  
  // Play the previous track
  playCustomTrack(playlistTracks[currentPlayingIndex], currentPlayingIndex);
}

// Save playlist locally
function savePlaylistLocally() {
  if (playlistTracks.length === 0) {
    alert('Your playlist is empty. Add some tracks first!');
    return;
  }
  
  const playlistData = {
    name: playlistName.value.trim() || 'My Custom Playlist',
    createdAt: new Date().toISOString(),
    tracks: playlistTracks.map(track => ({
      title: track.spotifyTrack.name,
      artist: track.spotifyTrack.artists.map(a => a.name).join(', '),
      uri: track.spotifyTrack.uri,
      previewUrl: track.spotifyTrack.preview_url,
      startTime: track.startTime,
      endTime: track.endTime,
      fadeIn: track.fadeIn,
      fadeOut: track.fadeOut,
      albumArt: track.spotifyTrack.album.images[0]?.url
    }))
  };
  
  // Convert to JSON string
  const jsonData = JSON.stringify(playlistData);
  
  // Create a blob of the data
  const blob = new Blob([jsonData], {type: 'application/json'});
  
  // Create an object URL for the blob
  const url = URL.createObjectURL(blob);
  
  // Create a download link and click it
  const a = document.createElement('a');
  a.href = url;
  a.download = `${playlistData.name.replace(/\s+/g, '_')}_playlist.json`;
  document.body.appendChild(a);
  a.click();
  
  // Clean up by removing the link and revoking the URL
  setTimeout(() => {
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  }, 100);
  
  alert('Playlist saved to your device!');
}