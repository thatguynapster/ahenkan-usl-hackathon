/// Enum representing supported languages in the application
enum Language { english, akan, ga, ewe }

/// Extension to provide display names and language codes for Language enum
extension LanguageExtension on Language {
  /// Returns the human-readable display name for the language
  String get displayName {
    switch (this) {
      case Language.english:
        return 'English';
      case Language.akan:
        return 'Akan';
      case Language.ga:
        return 'Ga';
      case Language.ewe:
        return 'Ewe';
    }
  }

  /// Returns the ISO language code for the language
  String get code {
    switch (this) {
      case Language.english:
        return 'en';
      case Language.akan:
        return 'ak';
      case Language.ga:
        return 'gaa';
      case Language.ewe:
        return 'ee';
    }
  }
}

/// Enum representing the type of message in communication
enum MessageType { signToText, textToSign }

/// Extension to provide display information for MessageType enum
extension MessageTypeExtension on MessageType {
  /// Returns the human-readable display name for the message type
  String get displayName {
    switch (this) {
      case MessageType.signToText:
        return 'Sign to Text';
      case MessageType.textToSign:
        return 'Text to Sign';
    }
  }
}

/// Enum representing different types of errors in the application
enum ErrorType {
  camera,
  interpretation,
  generation,
  speech,
  storage,
  network,
  permission,
}
