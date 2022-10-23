/*
 * Copyright (c) 2020, Marek Gocał
 * All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 */

import 'dart:async';

import 'package:gsheet_to_arb/src/arb/arb.dart';
import 'package:gsheet_to_arb/src/parser/_common_parser.dart';
import 'package:gsheet_to_arb/src/parser/_gender_parser.dart';
import 'package:gsheet_to_arb/src/parser/_plurals_parser.dart';
import 'package:gsheet_to_arb/src/translation_document.dart';
import 'package:gsheet_to_arb/src/utils/log.dart';
import 'package:recase/recase.dart';

class TranslationParser {
  final bool addContextPrefix;
  final String? caseType;

  TranslationParser({required this.addContextPrefix, this.caseType});

  Future<ArbBundle> parseDocument(TranslationsDocument document) async {
    final builders = <ArbDocumentBuilder>[];
    final genderParsers = <GendersParser>[];
    final pluralParsers = <PluralsParser>[];

    for (var langauge in document.languages) {
      final builder = ArbDocumentBuilder(langauge, document.lastModified);
      final genderParser = GendersParser(addContextPrefix, caseType);
      final pluralsParsers = PluralsParser(addContextPrefix, caseType);
      builders.add(builder);
      genderParsers.add(genderParser);
      pluralParsers.add(pluralsParsers);
    }

    // for each row
    for (var item in document.items) {
      // for each language
      for (var index in Iterable<int>.generate(document.languages.length)) {
        var itemValue;
        //incase value does not exist
        if (index < item.values.length) {
          itemValue = item.values[index];
        } else {
          itemValue = '';
        }

        if (itemValue == '') {
          Log.i('WARNING: empty string in lang: ' +
              document.languages[index] +
              ', key: ' +
              item.key);
          continue;
        }

        final itemPlaceholders = _findPlaceholders(itemValue);

        final builder = builders[index];

        // plural consume
        final pluralParser = pluralParsers[index];

        final pluralStatus = pluralParser.consume(ArbResource(
            item.key, itemValue,
            placeholders: itemPlaceholders,
            context: item.category,
            description: item.description));

        if (pluralStatus is Consumed) {
          continue;
        }

        if (pluralStatus is Completed) {
          builder.add(pluralStatus.resource);

          // next plural
          if (pluralStatus.consumed) {
            continue;
          }
        }

        // gender consume
        final genderParser = genderParsers[index];

        final genderStatus = genderParser.consume(ArbResource(
            item.key, itemValue,
            placeholders: itemPlaceholders,
            context: item.category,
            description: item.description));

        if (genderStatus is Consumed) {
          continue;
        }

        if (genderStatus is Completed) {
          builder.add(genderStatus.resource);

          // next gender
          if (genderStatus.consumed) {
            continue;
          }
        }

        final key = reCase(
            addContextPrefix && item.category.isNotEmpty
                ? item.category + '_' + item.key
                : item.key,
            caseType);

        // add resource
        builder.add(ArbResource(key, itemValue,
            context: item.category,
            description: item.description,
            placeholders: itemPlaceholders));
      }
    }

    // finalizer
    for (var index in Iterable<int>.generate(document.languages.length - 1)) {
      final builder = builders[index];
      final parser = genderParsers[index];
      final status = parser.complete();
      if (status is Completed) {
        builder.add(status.resource);
      }

      final genderParser = genderParsers[index];
      final genderStatus = genderParser.complete();
      if (genderStatus is Completed) {
        builder.add(genderStatus.resource);
      }
      final pluralParser = pluralParsers[index];
      final pluralStatus = pluralParser.complete();
      if (pluralStatus is Completed) {
        builder.add(pluralStatus.resource);
      }
    }

    // build all documents
    var documents = <ArbDocument>[];
    builders.forEach((builder) => documents.add(builder.build()));
    return ArbBundle(documents);
  }

  final _placeholderRegex = RegExp('\\{(.+?)\\}');

  List<ArbResourcePlaceholder> _findPlaceholders(String? text) {
    if (text == null || text.isEmpty) {
      return <ArbResourcePlaceholder>[];
    }

    var matches = _placeholderRegex.allMatches(text);
    var placeholders = <String, ArbResourcePlaceholder>{};
    matches.forEach((Match match) {
      var group = match.group(0);

      if (group != null) {
        var placeholderName = group.substring(1, group.length - 1);

        if (placeholders.containsKey(placeholderName)) {
          throw Exception('Placeholder $placeholderName already declared');
        }
        placeholders[placeholderName] =
            (ArbResourcePlaceholder(name: placeholderName, type: 'String'));
      }
    });
    return placeholders.values.toList();
  }

  static String reCase(String s, caseType) {
    switch (caseType ?? '') {
      case 'camelCase':
        return s.camelCase;
      default:
        return s;
    }
  }
}
