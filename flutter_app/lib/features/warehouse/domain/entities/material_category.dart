import 'package:flutter/foundation.dart';

/// A row of `material_categories` — the owner's exact 9-category list
/// (ЛДСП, МДФ, Фасад, Фурнитура, Столешница, Артқы қабырға, Профиль,
/// Шыны, Басқа), seeded in supabase/seed/seed.sql. Readable by any
/// active user regardless of `warehouse.read` (see
/// `material_categories_read_all_active` in
/// 20260713000012_rls_policies.sql) since a category name alone isn't
/// sensitive stock data.
@immutable
class MaterialCategory {
  const MaterialCategory({
    required this.id,
    required this.key,
    required this.nameKk,
  });

  final String id;
  final String key;
  final String nameKk;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
