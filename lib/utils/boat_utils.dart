String formatBoatCategory(String category) {
  switch (category.trim().toLowerCase()) {
    case 'lancha':
      return 'Lancha';
    case 'semirigida':
      return 'Semirrígida';
    case 'velero':
      return 'Velero';
    case 'yate':
      return 'Yate';
    case 'catamaran':
      return 'Catamarán';
    case 'jetski':
      return 'Jet Ski';
    default:
      return category.trim().isEmpty ? 'Sin categoría' : category.trim();
  }
}
