import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/supplier_result.dart';

/// Chat message model for the TradeLink Assistant.
class AssistantMessage {
  final String text;
  final bool isUser;
  final bool isTyping;
  final List<SupplierResult>? suppliers;
  final DateTime time;

  AssistantMessage({
    required this.text,
    required this.isUser,
    this.isTyping = false,
    this.suppliers,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

/// Serves the AI sourcing assistant.
///
/// Uses the free Google Gemini API (`gemini-1.5-flash`) when a key is
/// configured. Falls back to deterministic mock responses when no key is set,
/// so the UI works without credentials.
class AssistantService {
  AssistantService({String? apiKey})
      : _model = apiKey == null
            ? null
            : GenerativeModel(
                model: 'gemini-1.5-flash',
                apiKey: apiKey,
                generationConfig: GenerationConfig(temperature: 0.4),
              );

  static const String _apiKeyEnv = 'GEMINI_API_KEY';
  final GenerativeModel? _model;

  static const String _systemPrompt =
      'You are TradeLink Assistant, an AI sourcing assistant for shop owners. '
      'When users ask for a product, respond with a friendly short answer and '
      'a structured supplier list with price per kg, distance, and relative '
      'price difference compared to the lowest option. Keep answers under 2 sentences.';

  /// Resolve API key from the environment at runtime (web uses dart:js, but
  /// for simplicity we read from String.fromEnvironment compile-time const).
  static String? configuredApiKey() {
    const key = String.fromEnvironment(_apiKeyEnv);
    return key.isEmpty ? null : key;
  }

  /// Detect a product query from free text (mock NLU).
  static String _detectProduct(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('oil') || lower.contains('soybean')) {
      return 'Soybean Oil, 20L';
    }
    if (lower.contains('sugar')) return 'Sugar, 30kg';
    if (lower.contains('rice') || lower.contains('basmati')) {
      return 'Rice — Basmati, 50kg';
    }
    return 'Rice — Basmati, 50kg';
  }

  /// Generates a reply. Uses Gemini when available, otherwise mock.
  Future<AssistantMessage> generateReply(String userText) async {
    final product = _detectProduct(userText);
    final suppliers = SupplierResult.mockForProduct(product);

    if (_model != null) {
      try {
        final response = await _model.generateContent([
          Content.text(_systemPrompt),
          Content.text(
              'Shop owner asked: "$userText". Suggest a sourcing result for $product.'),
        ]);
        final text = response.text?.trim() ?? '';
        return AssistantMessage(text: text, isUser: false, suppliers: suppliers);
      } catch (e) {
        debugPrint('Gemini error: $e');
        return _mockReply(product, suppliers);
      }
    }
    return _mockReply(product, suppliers);
  }

  AssistantMessage _mockReply(String product, List<SupplierResult> suppliers) {
    final best = suppliers.first;
    return AssistantMessage(
      text:
          'Found ${suppliers.length} suppliers for "$product". '
          'Best price is ${best.priceLabel} at ${best.storeName}, '
          '${best.distance} away.',
      isUser: false,
      suppliers: suppliers,
    );
  }
}