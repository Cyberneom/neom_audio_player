# neom_audio_player
neom_audio_player is a fundamental module within the Open Neom ecosystem,
dedicated to centralizing and providing robust audio playback functionalities.
Its primary role is to serve as a versatile media player for disseminating audio
content such as audiobooks, podcasts, and music. By being a specialized module,
it enables other parts of the application (like neom_timeline or neom_itemlists)
to offer high-quality audio experiences without handling the complexities of playback.

This module aligns with Open Neom's vision of democratizing technology by making audio
content consumption accessible and conscious. It adheres to Clean Architecture principles,
ensuring its logic is robust, testable, and decoupled from the UI. By seamlessly integrating
with neom_core for services and data models, and with neom_commons for shared UI components,
it provides a coherent and unified audio experience.

Module Structure
The organization of neom_audio_player follows Clean Architecture principles, dividing responsibilities into clear layers:
•	lib/data: Contains the implementation of repositories and controllers for data persistence and management.
    o	firestore: Manages interaction with Firestore (e.g., casete_session_firestore).
    o	implementations: Implements local storage logic with Hive (e.g., player_hive_controller).
    o	providers: Provides the AudioHandler initialization (neom_audio_provider).
•	lib/domain: Contains the module's business rules, independent of any technology.
    o	models: Defines the module's entities (e.g., casete_session, media_lyrics).
    o	use_cases: Establishes service contracts (interfaces) that define the module's operations (e.g., audio_handler_service).
•	lib/ui: Contains all UI logic and widgets.
    o	drawer: Widgets for the side drawer (e.g., recently_played_page, audio_player_settings_page).
    o	home: Contains the logic and widgets for the player's home screen (e.g., audio_player_home_content).
    o	library: Components of the media library (e.g., playlist_player_page).
    o	player: Widgets for the main player and mini-player (e.g., audio_player_page, miniplayer).
•	lib/utils: Contains transversal utilities that are not part of the core business but are essential for the module's operation.
    o	constants: Constant and translation files (e.g., audio_player_translation_constants).
    o	mappers: Logic for mapping between project models and external library models (e.g., media_item_mapper).
•	neom_audio_handler: The implementation of the BaseAudioHandler.

🌟 Features & Responsibilities
neom_audio_player offers a comprehensive set of functionalities for audio playback:
•	Advanced Audio Player: Implements a robust player using libraries like just_audio and audio_service
    to handle playback for a single item or an entire playlist queue.
•	Queue Management: Allows users to manage the playback queue, including shuffling, repeating,
    and skipping between songs/tracks.
•	Mini-Player and Background Control: Provides a persistent mini-player and manages background audio playback
    (foreground service), ensuring a seamless user experience even when the app is not in the foreground.
•	Caching and Offline Access: Uses Hive for local caching of playlists and last session data, enabling playback
    resumption and offline access. It also contains logic for downloading and playing local audio files.
•	Specialized Playback Logic: Handles custom logic such as tracking listening session duration for content (CaseteSession),
    managing free trial periods, and adapting streaming quality.
•	State Synchronization: Synchronizes the playback state, position, volume, and speed, ensuring a consistent user experience.
•	Lyrics Integration: Includes functionality to display synchronized lyrics for tracks, fetched from various online sources.
•	User Preferences: Offers a suite of settings for users to customize their playback experience, such as streaming quality,
    repeat behavior, and mini-player buttons.

🛠 Technical Highlights / Why it Matters (for developers)
For developers, neom_audio_player is an excellent case study for:
•	Complex Library Integration: Demonstrates the integration and orchestration of advanced libraries like audio_service and just_audio
    for comprehensive audio playback management, including background service management.
•	AudioHandler Architecture: Shows how to implement a BaseAudioHandler to effectively manage communication between the application's
    UI and the background audio service, following Flutter's best practices.
•	GetX for Global State: Utilizes GetX to manage playback state reactively, ensuring all widgets that interact with audio remain synchronized.
•	Data Persistence (Hive): Provides practical examples of using Hive for local caching of queue information, user statistics, and settings,
    improving performance and offline experience.
•	Complex Data Mapping: Contains logic to map between project data models (AppMediaItem) and external library models (MediaItem),
    showcasing a solid implementation of dependency injection.
•	Modular Strategy (Service-Oriented): Exposes an AudioPlayerService interface that allows other modules to control audio playback
    without direct dependency on neom_audio_player, fostering decoupling within the ecosystem.

How it Supports the Open Neom Initiative
neom_audio_player is vital to the Open Neom ecosystem and the Tecnozenism philosophy because:
•	Fosters Dissemination of Conscious Content: Provides a robust platform for distributing audiobooks, podcasts,
    and other content that contributes to well-being, research, and education.
•	Enhances User Experience: By offering fluid, optimized, and controllable audio playback, it enriches the user experience
    and keeps them engaged with the content.
•	Showcases Project Scalability: As a complete module for a complex functionality, it proves that Open Neom can house
    and manage advanced features independently, inviting specialized contributions.
•	Supports Research: The ability to track listening sessions can be fundamental for research into consumption patterns
    and the impact of content on well-being.

🚀 Usage
This module provides the controllers (AudioPlayerController, MiniPlayerController) that implement AudioPlayerService,
and the UI widgets (AudioPlayerPage, MiniPlayer) for audio playback. Other modules consume AudioPlayerService
to control playback and access player state.

📦 Dependencies
neom_audio_player relies on neom_core and neom_commons for shared services, models, and components.
It also directly depends on audio_service and just_audio for its core audio playback functionalities.

🤝 Contributing
We welcome contributions to the neom_audio_player module! If you are passionate about media playback,
background audio management, or integrating new audio sources, your contributions
can significantly strengthen the ecosystem.

To understand the broader architectural context of Open Neom and how neom_audio_player fits into the vision of Tecnozenism,
please refer to the main project's MANIFEST.md.

For guidance on how to contribute to Open Neom and to understand the various levels of learning and engagement
possible within the project, consult our comprehensive guide: Learning Flutter Through Open Neom: A Comprehensive Path.

📄 License
This project is licensed under the Apache License, Version 2.0, January 2004. See the LICENSE file for details.
 