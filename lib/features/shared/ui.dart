import 'package:flutter/material.dart';

import '../../core/design/app_tokens.dart';

/// Tarjeta base para que sombras, radios y superficies sean consistentes.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06191c1d),
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

/// Título reutilizable de una sección, con acción opcional a la derecha.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      ?trailing,
    ],
  );
}

/// Estado visual reutilizable para carga vacía, errores y falta de conexión.
class StateNotice extends StatelessWidget {
  const StateNotice({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Icon(icon, color: AppColors.navy, size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    ),
  );
}

/// Selector genérico que sirve para los filtros de Historial y Alertas.
class FilterPills<T> extends StatelessWidget {
  const FilterPills({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });
  final List<T> values;
  final T? selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 8,
    children: values.map((value) {
      final active = value == selected;
      return ChoiceChip(
        label: Text(label(value)),
        selected: active,
        showCheckmark: false,
        onSelected: (_) => onChanged(value),
        labelStyle: TextStyle(
          color: active ? Colors.white : AppColors.ink,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: AppColors.navy,
        backgroundColor: Colors.transparent,
        side: BorderSide(color: active ? AppColors.navy : AppColors.outline),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      );
    }).toList(),
  );
}

/// Estructura compartida: ancho legible, encabezado y un único scroll por página.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.actions = const [],
  });
  final String title, subtitle;
  final List<Widget> children, actions;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      return ListView(
        padding: EdgeInsets.all(compact ? 20 : 32),
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 16,
            children: [
              SizedBox(
                width: compact
                    ? constraints.maxWidth - 40
                    : (constraints.maxWidth - 64) * .62,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 26 : 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: -.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (actions.isNotEmpty)
                Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ),
          const SizedBox(height: 28),
          ...children,
          const SizedBox(height: 32),
        ],
      );
    },
  );
}

class AdaptivePanels extends StatelessWidget {
  const AdaptivePanels({
    super.key,
    required this.primary,
    required this.secondary,
    this.breakpoint = 900,
    this.primaryFlex = 3,
    this.secondaryFlex = 2,
  });
  final Widget primary, secondary;
  final double breakpoint;
  final int primaryFlex, secondaryFlex;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < breakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [primary, const SizedBox(height: 24), secondary],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: primaryFlex, child: primary),
          const SizedBox(width: 24),
          Expanded(flex: secondaryFlex, child: secondary),
        ],
      );
    },
  );
}

class AdaptiveCards extends StatelessWidget {
  const AdaptiveCards({
    super.key,
    required this.children,
    this.minimumWidth = 240,
    this.maxColumns = 3,
  });
  final List<Widget> children;
  final double minimumWidth;
  final int maxColumns;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = ((constraints.maxWidth + 16) / (minimumWidth + 16))
          .floor()
          .clamp(1, maxColumns);
      final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(
    this.label, {
    super.key,
    this.color = AppColors.muted,
    this.icon = Icons.info_outline,
  });
  final String label;
  final Color color;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget loadingPanel() => const AppCard(
  child: SizedBox(
    height: 200,
    child: Center(child: CircularProgressIndicator()),
  ),
);

String formatDate(DateTime date, {bool time = true, bool seconds = false}) {
  final local = date.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(local.day)}/${two(local.month)}/${local.year}${time ? ' · ${two(local.hour)}:${two(local.minute)}${seconds ? ':${two(local.second)}' : ''}' : ''}';
}
