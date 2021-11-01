import 'package:gsheet_to_arb/src/parser/_common_parser.dart';

///
/// Plurals
///
enum PluralCase { zero, one, two, few, many, other }

class PluralsParser extends CommonParser<PluralCase> {
  PluralsParser(
    bool addContextPrefix,
    String? caseType,
  ) : super(
          addContextPrefix,
          caseType,
        );

  @override
  final keywords = {
    'zero': PluralCase.zero,
    'one': PluralCase.one,
    'two': PluralCase.two,
    'few': PluralCase.few,
    'many': PluralCase.many,
    'other': PluralCase.other
  };

  @override
  Map<PluralCase, String> get formatters => {
        PluralCase.zero: '=0',
        PluralCase.one: '=1',
        PluralCase.two: '=2',
        PluralCase.few: 'few',
        PluralCase.many: 'many',
        PluralCase.other: 'other'
      };

  @override
  String get description => 'plural count';

  @override
  String get placeholder => 'count';

  @override
  String get type => 'num';

  @override
  String get key => 'plural';
}
