import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';

Future<void> openAsk(
  BuildContext context, {
  required String type,
  String? ref,
  String? quote,
  String? suggestedQuestion,
}) {
  return context.pushNamed(
    AppRouteNames.ask,
    queryParameters: {
      'contextType': type,
      if (ref != null && ref.trim().isNotEmpty) 'contextRef': ref,
      if (quote != null && quote.trim().isNotEmpty) 'contextQuote': quote,
      if (suggestedQuestion != null && suggestedQuestion.trim().isNotEmpty)
        'suggested': suggestedQuestion,
    },
  );
}
