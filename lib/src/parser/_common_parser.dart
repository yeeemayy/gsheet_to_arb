import 'package:gsheet_to_arb/src/arb/arb.dart';
import 'package:gsheet_to_arb/src/parser/translation_parser.dart';

abstract class ParserStatus {}

class Skip extends ParserStatus {}

class Consumed extends ParserStatus {}

class Completed extends ParserStatus {
  final ArbResource resource;
  final bool consumed;

  Completed(this.resource, {this.consumed = false});
}

abstract class CommonParser<T> {
  final bool addContextPrefix;
  String? caseType;

  final _separator = '=';

  Map<String, T> get keywords;
  Map<T, String> get formatters;
  String get description;
  String get type;
  String get placeholder;
  String get key;

  String? _key;
  ArbResource? _resource;
  final _placeholders = <String, ArbResourcePlaceholder>{};
  final _values = <T, String>{};

  CommonParser(
    this.addContextPrefix,
    this.caseType,
  );

  ParserStatus consume(ArbResource resource) {
    final GenderCase = _getCase(resource.key);

    // normal item
    if (GenderCase == null) {
      if (_values.isNotEmpty) {
        final status = _getCompleted();
        _key = null;
        _resource = null;
        _placeholders.clear();
        _values.clear();
        return status;
      } else {
        _key = null;
        _resource = null;
        _placeholders.clear();
        return Skip();
      }
    }

    // Gender item
    final caseKey = _getCaseKey(resource.key);

    if (_key == caseKey) {
      // same Gender - another entry
      _values[GenderCase] = resource.value;
      return Consumed();
    } else if (_key == null) {
      // first Gender
      _key = caseKey;
      _resource = resource;
      _placeholders[placeholder] = ArbResourcePlaceholder(
        name: placeholder,
        description: description,
        type: type,
      );
      addPlaceholders(resource.placeholders);
      _values[GenderCase] = resource.value;
      return Consumed();
    } else {
      // another
      ParserStatus status;
      if (_values.isNotEmpty) {
        status = _getCompleted(consumed: true);
      } else {
        status = Consumed();
      }

      _key = caseKey;
      _resource = resource;
      _placeholders.clear();
      _placeholders[placeholder] = ArbResourcePlaceholder(
          name: placeholder, description: description, type: type);
      addPlaceholders(resource.placeholders);
      _values.clear();
      _values[GenderCase] = resource.value;

      return status;
    }
  }

  ParserStatus complete() {
    if (_values.isNotEmpty) {
      return _getCompleted();
    }
    return Skip();
  }

  T? _getCase(String key) {
    if (key.contains(_separator)) {
      for (var Gender in keywords.keys) {
        if (key.endsWith('$_separator$Gender')) {
          return keywords[Gender];
        }
      }
    }
    return null;
  }

  String _getCaseKey(String key) {
    return key.substring(0, key.lastIndexOf(_separator));
  }

  Completed _getCompleted({bool consumed = false}) {
    final resourceContext = _resource?.context;
    final key = (addContextPrefix &&
            resourceContext != null &&
            resourceContext.isNotEmpty)
        ? resourceContext + '_' + _key!
        : _key;

    final formattedKey = TranslationParser.reCase(
      key!,
      caseType,
    );

    return Completed(
        ArbResource(
          formattedKey,
          format(Map.from(_values)),
          placeholders: List.from(_placeholders.values),
          context: _resource?.context,
          description: _resource?.description,
        ),
        consumed: consumed);
  }

  void addPlaceholders(List<ArbResourcePlaceholder>? placeholders) {
    if (placeholders == null) {
      return;
    }
    for (var placeholder in placeholders) {
      if (!_placeholders.containsKey(placeholder.name)) {
        _placeholders[placeholder.name] = placeholder;
      }
    }
  }

  String format(Map<T, String?> Gender) {
    final builder = StringBuffer();
    builder.write('{$placeholder, $key,');
    Gender.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        builder.write(' ${formatters[key]} {$value}');
      }
    });
    builder.write('}');
    return builder.toString();
  }
}
