class AppConstants {
  static const String appName = 'PlanMyTrip';

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String tripsCollection = 'trips';
  static const String destinationsCollection = 'destinations';
  static const String savedPlacesCollection = 'saved_places';
  static const String notificationsCollection = 'notifications';
  static const String aiRequestsCollection = 'ai_requests';
  static const String reviewsCollection = 'reviews';

  // Storage Paths
  static const String profilePicturesPath = 'profile_pictures';
  static const String tripImagesPath = 'trip_images';

  // AI Webhook Config
  static const String n8nWebhookUrl = 'https://shreyas0306.app.n8n.cloud/webhook/8e40a019-fbda-4ac0-84b1-94bbea2d5f78/chat';

  // Default Assets / Fallbacks
  static const String defaultUserPhoto = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=400&q=80';
}
