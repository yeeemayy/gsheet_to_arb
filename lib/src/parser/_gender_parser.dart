import 'package:gsheet_to_arb/src/parser/_common_parser.dart';

///
/// Genders
///
enum GenderCase { male, female, otherGender }

class GendersParser extends CommonParser<GenderCase> {
  GendersParser(
    bool addContextPrefix,
    String? caseType,
  ) : super(
          addContextPrefix,
          caseType,
        );

  @override
  final keywords = {
    'male': GenderCase.male,
    'female': GenderCase.female,
    'other_gender': GenderCase.otherGender
  };

  @override
  Map<GenderCase, String> get formatters => {
        GenderCase.male: 'male',
        GenderCase.female: 'female',
        GenderCase.otherGender: 'other'
      };

  @override
  String get description => 'Gender';

  @override
  String get placeholder => 'sex';

  @override
  String get type => 'sex';

  @override
  String get key => 'select';
}
