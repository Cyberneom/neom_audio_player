### 1.5.0 - Decoupling & Major Architectural Evolution
This release represents a monumental evolution and the complete un-forking of neom_audio_player. Two years ago, this project began as a fork of the VN0/BlackHole repository, but the codebase has since been so profoundly transformed and refactored that its architecture, vision, and functionalities no longer hold significant equivalence to the original project. Therefore, with this version, neom_audio_player is established as a fully autonomous module within the Open Neom ecosystem.

Key Architectural & Feature Improvements:

Independence from Original Codebase:

The project has been officially un-forked from its origin (VN0/BlackHole), marking its full autonomy. This strategic decision reflects the unique direction the module has taken, focusing on Open Neom and Tecnozenism principles.

Decoupling via Service Interfaces (DIP):

The player logic has been completely decoupled from the UI and other modules. The AudioPlayerController now implements the AudioPlayerService interface (defined in neom_core), allowing modules like neom_timeline or neom_itemlists to control playback without a direct dependency on the neom_audio_player implementation.

Centralized Logic:

All audio playback logic, queue management, background service handling, and data persistence are now centralized within this single module. This includes managing reactive states (GetX), audio sessions (AudioHandler), and data persistence with Hive.

Modular Translations:

AudioPlayerTranslationConstants has been created to encapsulate all translation constants specific to the module. This improves maintainability, scalability, and localization by organizing translation files by functionality.

Support for Diverse Content:

The mapping logic (MediaItemMapper) has been enhanced to robustly handle diverse data models such as audiobooks, podcasts, and local audio files, facilitating the dissemination of conscious content.

User Experience Enhancements:

A tracking system for listening sessions (CaseteSession) and a free trial manager (CaseteTrialUsageManager) have been added, enabling deeper integration with Cyberneom's business functionalities.

The management of media notifications, the mini-player, and background controls have been optimized for a smooth and consistent user experience.

Benefits of this Evolution:

Maximized Modularity: The new architecture promotes specialization, allowing each module to focus on a single responsibility.

Increased Testability and Maintainability: The use of dependency injection through interfaces makes the code easier to test and maintain long-term.

Solid Foundation for the Future: The project's independence and enhanced architecture provide a stable canvas for integrating advanced features like audio tag editing and lyrics services.

Fostered Open Collaboration: The clarity of the structure and the updated documentation invite the community to contribute more effectively to a well-defined project with a clear vision.