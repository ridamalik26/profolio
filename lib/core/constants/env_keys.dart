import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvKeys {
  EnvKeys._();

  static String get geminiApiKey => dotenv.get('GEMINI_API_KEY');
}
