import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/constants/env_keys.dart';
import '../core/exceptions/auth_exception.dart';
import '../models/job_model.dart';
import '../models/profile_model.dart';

/// Generates realistic, personalized job listings with Gemini instead of
/// calling a real job-board API. Listings are synthetic — titles, companies,
/// and links are AI-invented, not real postings.
class GeminiJobService {
  GeminiJobService()
      : _model = GenerativeModel(
          // This API key's project only has access to the 2.5 model family —
          // gemini-1.5-flash returns 404 "not found for API version v1beta"
          // and gemini-2.0-flash returns 429 (zero free-tier quota) on it.
          model: 'gemini-2.5-flash',
          apiKey: EnvKeys.geminiApiKey,
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            temperature: 0.9,
          ),
        );

  final GenerativeModel _model;

  Future<List<JobModel>> generateJobs({
    required ProfileModel? profile,
    required String tabContext,
    String? searchQuery,
    String? category,
    String? experienceLevel,
    double? minSalary,
    double? maxSalary,
    bool remoteOnly = false,
    String? employmentType,
    bool preferRecent = false,
    int count = 10,
  }) async {
    final prompt = _buildPrompt(
      profile: profile,
      tabContext: tabContext,
      searchQuery: searchQuery,
      category: category,
      experienceLevel: experienceLevel,
      minSalary: minSalary,
      maxSalary: maxSalary,
      remoteOnly: remoteOnly,
      employmentType: employmentType,
      preferRecent: preferRecent,
      count: count,
    );

    GenerateContentResponse response;
    try {
      response = await _model.generateContent([Content.text(prompt)]);
    } catch (e) {
      throw AuthException('Gemini request failed: $e');
    }

    final text = response.text;
    if (text == null || text.isEmpty) {
      final candidates = response.candidates.toList();
      final finishReason = candidates.isEmpty ? null : candidates.first.finishReason;
      throw AuthException('Gemini returned no content (finishReason: $finishReason).');
    }

    final Map<String, dynamic> parsed;
    try {
      final decoded = jsonDecode(_stripCodeFence(text));
      parsed = decoded is Map<String, dynamic> ? decoded : {'jobs': decoded};
    } catch (e) {
      throw AuthException('Gemini returned malformed JSON: $e');
    }

    final rawJobs = parsed['jobs'] as List<dynamic>? ?? [];
    return rawJobs
        .whereType<Map<String, dynamic>>()
        .toList()
        .asMap()
        .entries
        .map((e) => JobModel.fromGemini(e.value, index: e.key))
        .toList();
  }

  String _buildPrompt({
    required ProfileModel? profile,
    required String tabContext,
    String? searchQuery,
    String? category,
    String? experienceLevel,
    double? minSalary,
    double? maxSalary,
    required bool remoteOnly,
    String? employmentType,
    required bool preferRecent,
    required int count,
  }) {
    final skills = profile?.skills.join(', ');
    final education = profile?.education
        .map((e) => '${e.degree} from ${e.institution} (${e.year})')
        .join('; ');
    final experience = profile?.experience
        .map((e) => '${e.role} at ${e.company}')
        .join('; ');

    final constraints = <String>[];
    if (searchQuery != null && searchQuery.isNotEmpty) {
      constraints.add('Search intent: "$searchQuery"');
    }
    if (category != null && category.isNotEmpty) {
      constraints.add('Job category: $category');
    }
    if (experienceLevel != null && experienceLevel.isNotEmpty) {
      constraints.add('Experience level: $experienceLevel');
    }
    if (remoteOnly) constraints.add('All jobs must be fully remote.');
    if (employmentType != null) {
      constraints.add('All jobs must have job_type = "$employmentType".');
    }
    if (minSalary != null || maxSalary != null) {
      constraints.add(
        'Salary should fall roughly within \$${minSalary?.round() ?? 0} - '
        '\$${maxSalary?.round() ?? 250000} per year.',
      );
    }
    if (preferRecent) {
      constraints.add('All jobs should be very recently posted (posted_days_ago 0-3).');
    }

    return '''
You are a job recommendation engine inside a career app. Generate $count
realistic, plausible (but fictional) job listings for the "$tabContext" tab.

Candidate skills: ${skills?.isNotEmpty == true ? skills : 'none listed'}
Candidate education: ${education?.isNotEmpty == true ? education : 'none listed'}
Candidate experience: ${experience?.isNotEmpty == true ? experience : 'none listed'}

${constraints.isEmpty ? '' : 'Constraints:\n${constraints.map((c) => '- $c').join('\n')}'}

For each job, score how well it matches the candidate's profile (0-100) and
give a one-sentence reason. Vary companies, titles, and salaries realistically
for the tech/professional job market. Use plausible but fictional company
names (do not claim these are real open positions at real companies).

Return ONLY a JSON object of this exact shape, no markdown, no commentary:
{
  "jobs": [
    {
      "job_title": string,
      "company_name": string,
      "location": string,
      "is_remote": boolean,
      "job_type": "Full-Time" | "Part-Time" | "Internship" | "Contract",
      "salary_range": string (e.g. "\$90,000 - \$120,000/year"),
      "description": string (2-4 sentences),
      "required_skills": [string, ...] (3-6 items),
      "qualifications": [string, ...] (2-4 bullet points),
      "match_score": integer 0-100,
      "match_reason": string (one sentence),
      "posted_days_ago": integer 0-14,
      "application_deadline_days_from_now": integer 7-30
    }
  ]
}
''';
  }

  String _stripCodeFence(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('```')) {
      return trimmed
          .replaceFirst(RegExp(r'^```(json)?'), '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    }
    return trimmed;
  }
}
