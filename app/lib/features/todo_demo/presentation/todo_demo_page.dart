import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_error_localizer.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/app_config_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_view.dart';
import '../../../core/widgets/app_error_view.dart';
import '../../../core/widgets/app_loading_view.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../i18n/strings.g.dart';
import '../providers/todo_demo_providers.dart';

class TodoDemoPage extends ConsumerWidget {
  const TodoDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todo = ref.watch(demoTodoProvider);
    final config = ref.watch(appConfigProvider);
    final scenarioId = ref.watch(todoDemoScenarioProvider);
    final textTheme = Theme.of(context).textTheme;
    final t = context.t.todoDemo;

    return AppScaffold(
      title: t.title,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            config.useMockApi ? t.mockEnabled : t.mockDisabled,
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              AppButton(
                label: t.scenarioSuccess,
                variant: scenarioId == TodoDemoScenario.successId
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                onPressed: () => _setScenario(ref, TodoDemoScenario.successId),
              ),
              AppButton(
                label: t.scenarioEmpty,
                variant: scenarioId == TodoDemoScenario.emptyId
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                onPressed: () => _setScenario(ref, TodoDemoScenario.emptyId),
              ),
              AppButton(
                label: t.scenarioError,
                variant: scenarioId == TodoDemoScenario.errorId
                    ? AppButtonVariant.primary
                    : AppButtonVariant.secondary,
                onPressed: () => _setScenario(ref, TodoDemoScenario.errorId),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s24),
          todo.when(
            data: (todo) {
              if (todo == null) {
                return AppEmptyView(
                  title: t.emptyTitle,
                  message: t.emptyMessage,
                );
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.todoNumber(id: todo.id),
                    style: textTheme.headlineMedium,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(todo.title, style: textTheme.bodyLarge),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    t.completedLabel(
                      value: todo.completed ? t.completedYes : t.completedNo,
                    ),
                  ),
                ],
              );
            },
            error: (error, stackTrace) => _TodoErrorView(
              error: error,
              onRetry: () => ref.invalidate(demoTodoProvider),
            ),
            loading: () => AppLoadingView(message: t.loading),
          ),
        ],
      ),
    );
  }

  void _setScenario(WidgetRef ref, int scenarioId) {
    ref.read(todoDemoScenarioProvider.notifier).setScenario(scenarioId);
  }
}

class _TodoErrorView extends StatelessWidget {
  const _TodoErrorView({required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.t;
    final message = switch (error) {
      ApiException() => AppErrorLocalizer.messageFromCurrentLocale(error),
      _ => t.todoDemo.loadFailed,
    };

    return AppErrorView(
      title: t.common.somethingWentWrong,
      message: message,
      onRetry: onRetry,
    );
  }
}
